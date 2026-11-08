use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

pub fn read_str(p: &Path) -> Option<String> {
    fs::read_to_string(p).ok().map(|s| s.trim().to_string())
}

pub fn read_i64(p: &Path) -> Option<i64> {
    read_str(p)?.parse().ok()
}

pub fn sorted_dir(dir: &Path, prefix: &str) -> Vec<PathBuf> {
    let mut v: Vec<PathBuf> = fs::read_dir(dir)
        .map(|rd| {
            rd.flatten()
                .filter(|e| e.file_name().to_string_lossy().starts_with(prefix))
                .map(|e| e.path())
                .collect()
        })
        .unwrap_or_default();
    v.sort();
    v
}

pub fn hwmon_by_name(name: &str) -> Option<PathBuf> {
    sorted_dir(Path::new("/sys/class/hwmon"), "hwmon")
        .into_iter()
        .find(|h| read_str(&h.join("name")).as_deref() == Some(name))
}

pub fn round_to(x: f64, digits: i32) -> f64 {
    let m = 10f64.powi(digits);
    (x * m).round() / m
}

pub fn emit(v: &serde_json::Value) {
    let mut out = std::io::stdout().lock();
    if writeln!(out, "{v}").and_then(|_| out.flush()).is_err() {
        std::process::exit(0);
    }
}

pub fn monotonic() -> f64 {
    let mut ts = libc::timespec { tv_sec: 0, tv_nsec: 0 };
    unsafe { libc::clock_gettime(libc::CLOCK_MONOTONIC, &mut ts) };
    ts.tv_sec as f64 + ts.tv_nsec as f64 / 1e9
}

pub fn home() -> PathBuf {
    PathBuf::from(std::env::var_os("HOME").unwrap_or_else(|| "/".into()))
}

pub fn parent_gone(parent: libc::pid_t) -> bool {
    unsafe { libc::getppid() != parent }
}

pub fn hypr_request(cmd: &str) -> Option<String> {
    use std::io::Read;
    let sig = std::env::var("HYPRLAND_INSTANCE_SIGNATURE").ok()?;
    let run = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
    let mut s = std::os::unix::net::UnixStream::connect(format!("{run}/hypr/{sig}/.socket.sock")).ok()?;
    s.set_read_timeout(Some(std::time::Duration::from_secs(2))).ok()?;
    s.write_all(cmd.as_bytes()).ok()?;
    let mut out = String::new();
    s.read_to_string(&mut out).ok()?;
    Some(out)
}

pub fn notify(args: &[&str]) {
    let child = std::process::Command::new("timeout")
        .arg("5")
        .arg("notify-send")
        .args(args)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn();
    if let Ok(mut c) = child {
        std::thread::spawn(move || {
            let _ = c.wait();
        });
    }
}

pub fn local_time(fmt: &str) -> String {
    let t = unsafe { libc::time(std::ptr::null_mut()) };
    let mut tm: libc::tm = unsafe { std::mem::zeroed() };
    unsafe { libc::localtime_r(&t, &mut tm) };
    let mut buf = [0u8; 128];
    let mut f = fmt.as_bytes().to_vec();
    f.push(0);
    let n = unsafe { libc::strftime(buf.as_mut_ptr().cast(), buf.len(), f.as_ptr().cast(), &tm) };
    String::from_utf8_lossy(&buf[..n]).into_owned()
}
