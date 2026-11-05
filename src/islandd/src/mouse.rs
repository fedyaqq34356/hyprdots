use crate::util::{emit, parent_gone};
use serde_json::{json, Map, Value};
use std::fs;
use std::io::{Read, Write};
use std::os::fd::AsRawFd;
use std::path::Path;
use std::time::{Duration, Instant};

const VID: &str = "046D";
const RECEIVERS: [&str; 7] = ["C53F", "C539", "C547", "C52B", "C534", "C548", "C545"];
const SWID: u8 = 0x0A;

const F_NAME: u16 = 0x0005;
const F_BATTERY_STATUS: u16 = 0x1000;
const F_VOLTAGE: u16 = 0x1001;
const F_UNIFIED: u16 = 0x1004;

const AA_CURVE: [(i64, i64); 12] = [
    (1550, 100), (1480, 90), (1420, 80), (1380, 70), (1350, 60), (1320, 50),
    (1290, 40), (1260, 30), (1230, 20), (1200, 10), (1170, 5), (1150, 0),
];
const LIPO_CURVE: [(i64, i64); 13] = [
    (4186, 100), (4067, 90), (3989, 80), (3922, 70), (3859, 60), (3811, 50),
    (3778, 40), (3751, 30), (3717, 20), (3671, 10), (3646, 5), (3579, 2), (3500, 0),
];

struct Err {
    code: &'static str,
    message: String,
}

fn err(code: &'static str, message: impl Into<String>) -> Err {
    Err { code, message: message.into() }
}

fn interp(curve: &[(i64, i64)], mv: i64) -> i64 {
    if mv >= curve[0].0 {
        return 100;
    }
    for w in curve.windows(2) {
        let ((v1, p1), (v2, p2)) = (w[0], w[1]);
        if mv >= v2 {
            return (p2 as f64 + (p1 - p2) as f64 * (mv - v2) as f64 / (v1 - v2) as f64).round() as i64;
        }
    }
    0
}

fn receivers() -> Vec<String> {
    let base = Path::new("/sys/class/hidraw");
    let mut names: Vec<String> = fs::read_dir(base)
        .map(|rd| rd.flatten().map(|e| e.file_name().to_string_lossy().into_owned()).collect())
        .unwrap_or_default();
    names.sort();
    let mut out = vec![];
    for name in names {
        let dev = base.join(&name).join("device");
        let Ok(uevent) = fs::read_to_string(dev.join("uevent")) else { continue };
        let Ok(real) = fs::canonicalize(&dev) else { continue };
        let hid = uevent
            .lines()
            .find_map(|l| l.strip_prefix("HID_ID="))
            .unwrap_or("")
            .to_uppercase();
        let parts: Vec<&str> = hid.split(':').collect();
        let tail = |s: &str| s[s.len().saturating_sub(4)..].to_string();
        if parts.len() != 3 || tail(parts[1]) != VID || !RECEIVERS.contains(&tail(parts[2]).as_str()) {
            continue;
        }
        let parent = real.parent().and_then(|p| p.file_name()).map(|n| n.to_string_lossy().into_owned());
        if !parent.is_some_and(|p| p.ends_with(":1.2")) {
            continue;
        }
        out.push(format!("/dev/{name}"));
    }
    out
}

struct Receiver {
    f: fs::File,
}

fn readable(fd: i32, timeout: Duration) -> bool {
    let mut p = libc::pollfd { fd, events: libc::POLLIN, revents: 0 };
    let ms = timeout.as_millis().min(i32::MAX as u128) as i32;
    unsafe { libc::poll(&mut p, 1, ms) > 0 && p.revents & libc::POLLIN != 0 }
}

impl Receiver {
    fn open(path: &str) -> Result<Receiver, Err> {
        use std::os::unix::fs::OpenOptionsExt;
        fs::OpenOptions::new()
            .read(true)
            .write(true)
            .custom_flags(libc::O_NONBLOCK)
            .open(path)
            .map(|f| Receiver { f })
            .map_err(|e| match e.raw_os_error() {
                Some(libc::EACCES | libc::EPERM) => err("permission", format!("нет доступа к {path}")),
                _ => err("not_found", e.to_string()),
            })
    }

    fn request(&mut self, dev: u8, feat: u8, func: u8, params: &[u8], timeout: f64) -> Result<Vec<u8>, Err> {
        let fd = self.f.as_raw_fd();
        let mut buf = [0u8; 64];
        while readable(fd, Duration::ZERO) {
            if self.f.read(&mut buf).is_err() {
                break;
            }
        }
        let mut msg = [0u8; 7];
        msg[..4].copy_from_slice(&[0x10, dev, feat, (func << 4) | SWID]);
        for (i, b) in params.iter().take(3).enumerate() {
            msg[4 + i] = *b;
        }
        self.f.write_all(&msg).map_err(|e| err("io", e.to_string()))?;
        let end = Instant::now() + Duration::from_secs_f64(timeout);
        loop {
            let now = Instant::now();
            if now >= end || !readable(fd, end - now) {
                break;
            }
            let n = match self.f.read(&mut buf) {
                Ok(n) => n,
                Err(_) => continue,
            };
            let d = &buf[..n];
            if d.len() < 4 || !matches!(d[0], 0x10 | 0x11) || d[1] != dev {
                continue;
            }
            if d[2] == 0xFF && d.len() >= 6 && d[3] == feat {
                return Err(err("hidpp", format!("HID++ ошибка 0x{:02x}", d[5])));
            }
            if d[2] == 0x8F && d[3] == feat {
                return Err(err("offline", "мышь спит или выключена"));
            }
            if d[2] == feat && d[3] == (func << 4) | SWID {
                return Ok(d[4..].to_vec());
            }
        }
        Err(err("timeout", "мышь не ответила"))
    }

    fn feature(&mut self, dev: u8, fid: u16) -> Result<Option<u8>, Err> {
        let r = self.request(dev, 0, 0, &[(fid >> 8) as u8, fid as u8], 0.6)?;
        Ok(r.first().copied().filter(|v| *v != 0))
    }
}

fn byte(r: &[u8], i: usize) -> u8 {
    r.get(i).copied().unwrap_or(0)
}

fn name_of(rx: &mut Receiver, dev: u8) -> Result<Option<String>, Err> {
    let Some(idx) = rx.feature(dev, F_NAME)? else { return Ok(None) };
    let n = byte(&rx.request(dev, idx, 0, &[], 0.6)?, 0) as usize;
    let mut out: Vec<u8> = vec![];
    while out.len() < n {
        let chunk = rx.request(dev, idx, 1, &[out.len() as u8], 0.6)?;
        let take = chunk.len().min(n - out.len());
        out.extend_from_slice(&chunk[..take]);
        if chunk.iter().all(|b| *b == 0) {
            break;
        }
    }
    while out.last() == Some(&0) {
        out.pop();
    }
    Ok(Some(String::from_utf8_lossy(&out).into_owned()))
}

fn battery(rx: &mut Receiver, dev: u8) -> Result<Option<Map<String, Value>>, Err> {
    let mut m = Map::new();
    if let Some(idx) = rx.feature(dev, F_UNIFIED)? {
        let r = rx.request(dev, idx, 1, &[], 0.6)?;
        let (pct, lvl, chg) = (byte(&r, 0), byte(&r, 1), byte(&r, 2));
        let percent = if pct != 0 {
            json!(pct)
        } else {
            match lvl { 8 => json!(90), 4 => json!(50), 2 => json!(20), 1 => json!(5), _ => Value::Null }
        };
        m.insert("percent".into(), percent);
        m.insert("charging".into(), json!(matches!(chg, 1 | 2)));
        m.insert("full".into(), json!(chg == 3));
        m.insert("source".into(), json!("unified"));
        return Ok(Some(m));
    }
    if let Some(idx) = rx.feature(dev, F_VOLTAGE)? {
        let r = rx.request(dev, idx, 0, &[], 0.6)?;
        let mv = ((byte(&r, 0) as i64) << 8) | byte(&r, 1) as i64;
        let flags = byte(&r, 2);
        let charging = flags & 0x80 != 0;
        let lipo = mv > 2500;
        m.insert("percent".into(), json!(interp(if lipo { &LIPO_CURVE } else { &AA_CURVE }, mv)));
        m.insert("voltage".into(), json!(mv));
        m.insert("charging".into(), json!(charging));
        m.insert("full".into(), json!(charging && flags & 0x07 == 1));
        m.insert("cell".into(), json!(if lipo { "lipo" } else { "aa" }));
        m.insert("source".into(), json!("voltage"));
        return Ok(Some(m));
    }
    if let Some(idx) = rx.feature(dev, F_BATTERY_STATUS)? {
        let r = rx.request(dev, idx, 0, &[], 0.6)?;
        m.insert("percent".into(), json!(byte(&r, 0)));
        m.insert("charging".into(), json!(matches!(byte(&r, 2), 1 | 2)));
        m.insert("full".into(), json!(byte(&r, 2) == 3));
        m.insert("source".into(), json!("status"));
        return Ok(Some(m));
    }
    Ok(None)
}

fn status() -> Result<Map<String, Value>, Err> {
    let paths = receivers();
    let mut out = Map::new();
    out.insert("ok".into(), json!(true));
    out.insert("found".into(), json!(!paths.is_empty()));
    if paths.is_empty() {
        return Ok(out);
    }
    for path in paths {
        let mut rx = Receiver::open(&path)?;
        for dev in 1u8..7 {
            if rx.request(dev, 0, 1, &[], 0.3).is_err() {
                continue;
            }
            let b = match battery(&mut rx, dev) {
                Ok(Some(b)) => b,
                Ok(None) => continue,
                Err(e) => {
                    let mut o = Map::new();
                    o.insert("ok".into(), json!(false));
                    o.insert("found".into(), json!(true));
                    o.insert("online".into(), json!(true));
                    o.insert("error".into(), json!(e.code));
                    o.insert("message".into(), json!(e.message));
                    return Ok(o);
                }
            };
            out.insert("online".into(), json!(true));
            out.insert("index".into(), json!(dev));
            out.insert("name".into(), json!(name_of(&mut rx, dev).ok().flatten()));
            out.extend(b);
            return Ok(out);
        }
    }
    out.insert("online".into(), json!(false));
    Ok(out)
}

fn safe_status() -> Map<String, Value> {
    status().unwrap_or_else(|e| {
        let mut o = Map::new();
        o.insert("ok".into(), json!(false));
        o.insert("found".into(), json!(true));
        o.insert("error".into(), json!(e.code));
        o.insert("message".into(), json!(e.message));
        o
    })
}

pub fn run(args: &[String]) {
    match args.first().map(String::as_str) {
        Some("status") | None => emit(&Value::Object(safe_status())),
        Some("watch") => {
            let mut interval = 120.0;
            if let Some(i) = args.iter().position(|a| a == "-i" || a == "--interval") {
                interval = args.get(i + 1).and_then(|v| v.parse().ok()).unwrap_or(interval);
            }
            watch(interval);
        }
        Some(other) => {
            eprintln!("mouse: unknown command {other}");
            std::process::exit(2);
        }
    }
}

fn watch(interval: f64) {
    let parent = unsafe { libc::getppid() };
    let mut prev = String::new();
    let mut shown: Option<i64> = None;
    while !parent_gone(parent) {
        let mut st = safe_status();
        let pct = st.get("percent").and_then(Value::as_i64);
        if let (Some(p), Some("voltage")) = (pct, st.get("source").and_then(Value::as_str)) {
            let charging = st.get("charging").and_then(Value::as_bool).unwrap_or(false);
            if shown.map_or(true, |s| p < s || p > s + 8) || charging {
                shown = Some(p);
            }
            st.insert("percent".into(), json!(shown));
        }
        let key: Vec<Value> = ["found", "online", "percent", "charging", "error"]
            .iter()
            .map(|k| st.get(*k).cloned().unwrap_or(Value::Null))
            .collect();
        let key = Value::Array(key).to_string();
        let online = st.get("online").and_then(Value::as_bool).unwrap_or(false);
        if key != prev {
            prev = key;
            st.insert("event".into(), json!("mouse"));
            emit(&Value::Object(st));
        }
        std::thread::sleep(Duration::from_secs_f64(if online { interval } else { 30.0 }));
    }
}
