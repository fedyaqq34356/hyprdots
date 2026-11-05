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
