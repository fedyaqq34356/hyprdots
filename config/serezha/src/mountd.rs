use std::process::{Command, Stdio};

const AF_NETLINK: i32 = 16;
const SOCK_DGRAM: i32 = 2;
const SOCK_CLOEXEC: i32 = 0o2000000;
const NETLINK_KOBJECT_UEVENT: i32 = 15;
const UDEV_GROUP: u32 = 2;

#[repr(C)]
struct SockaddrNl {
    family: u16,
    pad: u16,
    pid: u32,
    groups: u32,
}

extern "C" {
    fn socket(domain: i32, ty: i32, proto: i32) -> i32;
    fn bind(fd: i32, addr: *const SockaddrNl, len: u32) -> i32;
    fn recv(fd: i32, buf: *mut u8, len: usize, flags: i32) -> isize;
}

fn have(cmd: &str) -> bool {
    std::env::var_os("PATH").is_some_and(|p| std::env::split_paths(&p).any(|d| d.join(cmd).is_file()))
}

fn notify(title: &str, body: &str) {
    if !have("notify-send") {
        return;
    }
    let _ = Command::new("notify-send")
        .args(["-a", "носитель", "-u", "low", title, body])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

fn lsblk(args: &[&str]) -> String {
    Command::new("lsblk")
        .args(args)
        .stderr(Stdio::null())
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).into_owned())
        .unwrap_or_default()
}

fn field<'a>(line: &'a str, key: &str) -> &'a str {
    let pat = format!("{key}=\"");
    line.find(&pat)
        .map(|i| &line[i + pat.len()..])
        .and_then(|r| r.split_once('"').map(|(v, _)| v))
        .unwrap_or("")
}

fn suitable(dev: &str) -> bool {
    let out = lsblk(&["-ndPo", "HOTPLUG,FSTYPE,MOUNTPOINT,TYPE", dev]);
    let Some(line) = out.lines().next() else { return false };
    let fstype = field(line, "FSTYPE");
    field(line, "HOTPLUG") == "1"
        && matches!(field(line, "TYPE"), "part" | "disk")
        && !fstype.is_empty()
        && fstype != "swap"
        && field(line, "MOUNTPOINT").is_empty()
}

fn mount_dev(dev: &str) {
    if !suitable(dev) {
        return;
    }
    let out = Command::new("udisksctl")
        .args(["mount", "--no-user-interaction", "-b", dev])
        .output()
        .map(|o| format!("{}{}", String::from_utf8_lossy(&o.stdout), String::from_utf8_lossy(&o.stderr)))
        .unwrap_or_default();
    let out = out.trim();
    if let Some(i) = out.find("Mounted ") {
        let at = out[i..].rsplit_once(" at ").map_or("", |(_, p)| p);
        notify("смонтировано", at);
    } else if !out.contains("already mounted") {
        notify("не смонтировано", dev.rsplit('/').next().unwrap_or(dev));
    }
}

fn scan_all() {
    for dev in lsblk(&["-pnro", "NAME"]).lines() {
        if std::fs::metadata(dev).is_ok() {
            mount_dev(dev);
        }
    }
}

fn props(msg: &[u8]) -> Option<&[u8]> {
    if !msg.starts_with(b"libudev\0") || msg.len() < 24 {
        return None;
    }
    let u = |o: usize| u32::from_ne_bytes(msg[o..o + 4].try_into().unwrap()) as usize;
    let (off, len) = (u(16), u(20));
    msg.get(off..off.checked_add(len)?)
}

fn main() {
    if !have("udisksctl") {
        eprintln!("serezha-automount: нет udisksctl");
        std::process::exit(1);
    }
    if std::env::args().nth(1).as_deref() == Some("--once") {
        scan_all();
        return;
    }

    let fd = unsafe { socket(AF_NETLINK, SOCK_DGRAM | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT) };
    let addr = SockaddrNl { family: AF_NETLINK as u16, pad: 0, pid: 0, groups: UDEV_GROUP };
    if fd < 0 || unsafe { bind(fd, &addr, std::mem::size_of::<SockaddrNl>() as u32) } < 0 {
        eprintln!("serezha-automount: netlink недоступен");
        std::process::exit(1);
    }

    scan_all();

    let mut buf = vec![0u8; 8192];
    loop {
        let n = unsafe { recv(fd, buf.as_mut_ptr(), buf.len(), 0) };
        if n <= 0 {
            continue;
        }
        let Some(p) = props(&buf[..n as usize]) else { continue };
        let (mut add, mut block, mut devname) = (false, false, None);
        for kv in p.split(|b| *b == 0) {
            match kv {
                b"ACTION=add" => add = true,
                b"SUBSYSTEM=block" => block = true,
                _ => {
                    if let Some(v) = kv.strip_prefix(b"DEVNAME=") {
                        devname = Some(String::from_utf8_lossy(v).into_owned());
                    }
                }
            }
        }
        if let (true, true, Some(d)) = (add, block, devname) {
            let d = if d.starts_with('/') { d } else { format!("/dev/{d}") };
            mount_dev(&d);
        }
    }
}
