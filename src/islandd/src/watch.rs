use crate::util::{emit, home, read_str};
use serde_json::{json, Value};
use std::collections::{HashMap, HashSet};
use std::fs;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};
use std::os::unix::ffi::OsStrExt;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, SystemTime};

const VPN_EVERY: Duration = Duration::from_secs(2);
const OUT_EVERY: Duration = Duration::from_secs(3);
const VPN_PREFIXES: [&str; 5] = ["wg", "tun", "tailscale", "proton", "nordlynx"];
const PARTIAL: [&str; 2] = [".part", ".crdownload"];

struct Downloads {
    dir: PathBuf,
    fd: i32,
    count: Option<usize>,
}

impl Downloads {
    fn new() -> Downloads {
        let dir = home().join("Downloads");
        let fd = unsafe { libc::inotify_init1(libc::IN_NONBLOCK | libc::IN_CLOEXEC) };
        if fd >= 0 {
            let mut c = dir.as_os_str().as_bytes().to_vec();
            c.push(0);
            let mask = libc::IN_CREATE | libc::IN_DELETE | libc::IN_MOVED_FROM | libc::IN_MOVED_TO;
            unsafe { libc::inotify_add_watch(fd, c.as_ptr().cast(), mask) };
        }
        Downloads { dir, fd, count: None }
    }

    fn drain(&self) {
        let mut buf = [0u8; 4096];
        while unsafe { libc::read(self.fd, buf.as_mut_ptr().cast(), buf.len()) } > 0 {}
    }

    fn partials(&self) -> usize {
        fs::read_dir(&self.dir)
            .map(|rd| {
                rd.flatten()
                    .filter(|e| {
                        let n = e.file_name();
                        let n = n.to_string_lossy();
                        PARTIAL.iter().any(|s| n.ends_with(s)) && e.file_type().is_ok_and(|t| t.is_file())
                    })
                    .count()
            })
            .unwrap_or(0)
    }

    fn newest_done(&self) -> String {
        let cutoff = SystemTime::now() - Duration::from_secs(20);
        let mut best: Option<(SystemTime, PathBuf)> = None;
        for e in fs::read_dir(&self.dir).into_iter().flatten().flatten() {
            let n = e.file_name();
            if PARTIAL.iter().any(|s| n.to_string_lossy().ends_with(s)) {
                continue;
            }
            let Ok(m) = e.metadata() else { continue };
            let Ok(t) = m.modified() else { continue };
            if m.is_file() && t > cutoff && best.as_ref().map_or(true, |b| t > b.0) {
                best = Some((t, e.path()));
            }
        }
        best.map(|b| b.1.to_string_lossy().into_owned()).unwrap_or_default()
    }

    fn check(&mut self) {
        let n = self.partials();
        let was = self.count;
        if was == Some(n) {
            return;
        }
        self.count = Some(n);
        let mut ev = json!({"t": "dl", "n": n});
        if n == 0 && was.is_some_and(|w| w > 0) {
            ev["done"] = json!(self.newest_done());
        }
        emit(&ev);
    }
}

fn vpn_iface() -> String {
    let mut names: Vec<String> = fs::read_dir("/sys/class/net")
        .map(|rd| rd.flatten().map(|e| e.file_name().to_string_lossy().into_owned()).collect())
        .unwrap_or_default();
    names.sort();
    for n in names {
        if !VPN_PREFIXES.iter().any(|p| n.starts_with(p)) {
            continue;
        }
        let flags = read_str(&Path::new("/sys/class/net").join(&n).join("flags"))
            .and_then(|f| u32::from_str_radix(f.trim_start_matches("0x"), 16).ok())
            .unwrap_or(0);
        if flags & libc::IFF_UP as u32 != 0 {
            return n;
        }
    }
    String::new()
}

fn decode_addr(hex: &str) -> Option<IpAddr> {
    match hex.len() {
        8 => Some(IpAddr::V4(Ipv4Addr::from(u32::from_str_radix(hex, 16).ok()?.to_ne_bytes()))),
        32 => {
            let mut b = [0u8; 16];
            for i in 0..4 {
                let w = u32::from_str_radix(&hex[i * 8..i * 8 + 8], 16).ok()?;
                b[i * 4..i * 4 + 4].copy_from_slice(&w.to_ne_bytes());
            }
            let v6 = Ipv6Addr::from(b);
            Some(v6.to_ipv4_mapped().map_or(IpAddr::V6(v6), IpAddr::V4))
        }
        _ => None,
    }
}

fn private(ip: &IpAddr) -> bool {
    match ip {
        IpAddr::V4(v) => v.is_loopback() || v.is_private() || v.is_unspecified(),
        IpAddr::V6(v) => v.is_loopback() || v.is_unspecified(),
    }
}

struct Outbound {
    names: HashMap<u64, String>,
    unknown: HashSet<u64>,
    ignore_path: PathBuf,
    ignore_mtime: Option<SystemTime>,
    ignore: HashSet<String>,
    last: Option<Vec<(String, String, u16)>>,
}

impl Outbound {
    fn new() -> Outbound {
        Outbound {
            names: HashMap::new(),
            unknown: HashSet::new(),
            ignore_path: home().join(".config/hypr/outbound-ignore.list"),
            ignore_mtime: None,
            ignore: HashSet::new(),
            last: None,
        }
    }

    fn reload_ignore(&mut self) {
        let mtime = fs::metadata(&self.ignore_path).and_then(|m| m.modified()).ok();
        if mtime == self.ignore_mtime {
            return;
        }
        self.ignore_mtime = mtime;
        self.ignore = fs::read_to_string(&self.ignore_path)
            .unwrap_or_default()
            .lines()
            .map(|l| l.split('#').next().unwrap_or("").trim().to_string())
            .filter(|l| !l.is_empty())
            .collect();
    }

    fn sockets() -> Vec<(u64, IpAddr, u16)> {
        let mut out = vec![];
        for f in ["tcp", "tcp6", "udp", "udp6"] {
            let Ok(text) = fs::read_to_string(format!("/proc/net/{f}")) else { continue };
            for line in text.lines().skip(1) {
                let c: Vec<&str> = line.split_whitespace().collect();
                if c.len() < 10 || c[3] != "01" {
                    continue;
                }
                let Some((addr, port)) = c[2].split_once(':') else { continue };
                let (Some(ip), Ok(port), Ok(inode)) =
                    (decode_addr(addr), u16::from_str_radix(port, 16), c[9].parse::<u64>())
                else {
                    continue;
                };
                if inode != 0 && !private(&ip) {
                    out.push((inode, ip, port));
                }
            }
        }
        out
    }

    fn rescan(&mut self) {
        self.names.clear();
        let Ok(procs) = fs::read_dir("/proc") else { return };
        for p in procs.flatten() {
            let pid = p.file_name();
            if !pid.as_bytes().iter().all(u8::is_ascii_digit) {
                continue;
            }
            let Ok(fds) = fs::read_dir(p.path().join("fd")) else { continue };
            let mut comm: Option<String> = None;
            for fd in fds.flatten() {
                let Ok(link) = fs::read_link(fd.path()) else { continue };
                let link = link.as_os_str().as_bytes();
                let Some(num) = link.strip_prefix(b"socket:[").and_then(|r| r.strip_suffix(b"]")) else {
                    continue;
                };
                let Some(inode) = std::str::from_utf8(num).ok().and_then(|s| s.parse::<u64>().ok()) else {
                    continue;
                };
                let name = comm.get_or_insert_with(|| read_str(&p.path().join("comm")).unwrap_or_default());
                self.names.entry(inode).or_insert_with(|| name.clone());
            }
        }
    }

    fn check(&mut self) {
        self.reload_ignore();
        let socks = Self::sockets();
        let live: HashSet<u64> = socks.iter().map(|s| s.0).collect();
        self.unknown.retain(|i| live.contains(i));
        if socks.iter().any(|s| !self.names.contains_key(&s.0) && !self.unknown.contains(&s.0)) {
            self.rescan();
            for s in &socks {
                if !self.names.contains_key(&s.0) {
                    self.unknown.insert(s.0);
                }
            }
        }
        self.names.retain(|i, _| live.contains(i));

        let mut conns: Vec<(String, String, u16)> = socks
            .iter()
            .filter_map(|(inode, ip, port)| {
                let name = self.names.get(inode)?;
                (!name.is_empty() && !self.ignore.contains(name)).then(|| (name.clone(), ip.to_string(), *port))
            })
            .collect();
        conns.sort();
        conns.dedup();
        if self.last.as_ref() == Some(&conns) {
            return;
        }
        let list: Vec<Value> = conns.iter().map(|(p, h, port)| json!([p, h, port.to_string()])).collect();
        emit(&json!({"t": "out", "conns": list}));
        self.last = Some(conns);
    }
}

pub fn run() {
    let mut dl = Downloads::new();
    let mut out = Outbound::new();
    let mut vpn: Option<String> = None;
    let (mut next_vpn, mut next_out) = (Instant::now(), Instant::now());
    dl.check();

    loop {
        let now = Instant::now();
        if now >= next_vpn {
            let v = vpn_iface();
            if vpn.as_ref() != Some(&v) {
                emit(&json!({"t": "vpn", "iface": v}));
                vpn = Some(v);
            }
            next_vpn = now + VPN_EVERY;
        }
        if now >= next_out {
            out.check();
            next_out = now + OUT_EVERY;
        }

        let wait = next_vpn.min(next_out).saturating_duration_since(Instant::now());
        let mut p = libc::pollfd { fd: dl.fd, events: libc::POLLIN, revents: 0 };
        let r = unsafe { libc::poll(&mut p, 1, wait.as_millis() as i32 + 1) };
        if r > 0 && p.revents & libc::POLLIN != 0 {
            dl.drain();
            std::thread::sleep(Duration::from_millis(50));
            dl.drain();
            dl.check();
        }
    }
}
