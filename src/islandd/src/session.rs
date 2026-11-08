use crate::util::{home, hypr_request, notify, read_str};
use std::fs::{self, OpenOptions};
use std::os::fd::AsRawFd;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

fn runtime() -> PathBuf {
    PathBuf::from(std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into()))
}

pub fn notif_missed() {
    use dbus::blocking::Connection;
    let flag = runtime().join("session-locked");
    let count = runtime().join("missed-notifications");
    if !count.exists() {
        let _ = fs::write(&count, "0\n");
    }
    let Ok(conn) = Connection::new_session() else { std::process::exit(1) };
    let rules = vec!["type='method_call',interface='org.freedesktop.Notifications',member='Notify'"];
    let proxy = conn.with_proxy("org.freedesktop.DBus", "/org/freedesktop/DBus", Duration::from_secs(5));
    let r: Result<(), dbus::Error> = proxy.method_call("org.freedesktop.DBus.Monitoring", "BecomeMonitor", (rules, 0u32));
    if r.is_err() {
        std::process::exit(1);
    }
    loop {
        let msg = match conn.channel().blocking_pop_message(Duration::from_secs(3600)) {
            Ok(Some(m)) => m,
            Ok(None) => continue,
            Err(_) => std::process::exit(1),
        };
        if msg.member().as_deref() != Some("Notify") {
            continue;
        }
        if read_str(&flag).as_deref() != Some("1") {
            continue;
        }
        let n: u64 = read_str(&count).and_then(|s| s.parse().ok()).unwrap_or(0);
        let _ = fs::write(&count, format!("{}\n", n + 1));
    }
}

fn class_is_game(class: &str) -> bool {
    let c = class.to_lowercase();
    if let Some(n) = c.strip_prefix("steam_app_") {
        if !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit()) {
            return true;
        }
    }
    if c.len() > 4 && c.ends_with(".exe") {
        return true;
    }
    matches!(c.as_str(), "arma3" | "arma3_x64" | "gamescope" | "hoi4" | "cities2")
}

pub fn is_gaming() -> bool {
    let Some(text) = hypr_request("j/clients") else { return false };
    let Ok(serde_json::Value::Array(list)) = serde_json::from_str::<serde_json::Value>(&text) else { return false };
    list.iter().any(|c| {
        let full = c.get("fullscreen").and_then(|v| v.as_i64()).unwrap_or(0) != 0;
        let hidden = c.get("hidden").and_then(|v| v.as_bool()).unwrap_or(false);
        let game = c.get("contentType").and_then(|v| v.as_str()) == Some("game");
        let class = c.get("class").and_then(|v| v.as_str()).unwrap_or("");
        full && !hidden && (game || class_is_game(class))
    })
}

fn random_index(n: usize) -> usize {
    let mut b = [0u8; 8];
    if fs::File::open("/dev/urandom").and_then(|mut f| std::io::Read::read_exact(&mut f, &mut b)).is_err() {
        b = (Instant::now().elapsed().as_nanos() as u64 ^ std::process::id() as u64).to_ne_bytes();
    }
    (u64::from_ne_bytes(b) % n as u64) as usize
}

pub fn wallpaper_rotate() {
    let dir = home().join("Pictures/Wallpapers");
    let setter = home().join(".config/hypr/scripts/wallpaper/set-wallpaper.sh");
    let interval: u64 = std::env::var("WALLPAPER_INTERVAL").ok().and_then(|v| v.parse().ok()).unwrap_or(10800);
    loop {
        std::thread::sleep(Duration::from_secs(interval));
        while is_gaming() {
            std::thread::sleep(Duration::from_secs(60));
        }
        let files: Vec<PathBuf> = fs::read_dir(&dir)
            .into_iter()
            .flatten()
            .flatten()
            .filter(|e| e.file_type().is_ok_and(|t| t.is_file()))
            .map(|e| e.path())
            .filter(|p| {
                p.extension()
                    .map(|x| x.to_string_lossy().to_lowercase())
                    .is_some_and(|x| matches!(x.as_str(), "jpg" | "jpeg" | "png" | "webp"))
            })
            .collect();
        if files.is_empty() {
            continue;
        }
        let pick = &files[random_index(files.len())];
        let _ = Command::new(&setter).arg(pick).stdin(Stdio::null()).status();
    }
}

fn shell_pids() -> Vec<i32> {
    let names = std::env::var("ISLANDD_WATCHDOG_COMM").unwrap_or_else(|_| "quickshell qs".into());
    let names: Vec<&str> = names.split_whitespace().collect();
    let mut out = vec![];
    for e in fs::read_dir("/proc").into_iter().flatten().flatten() {
        let name = e.file_name();
        let Some(pid) = name.to_str().and_then(|s| s.parse::<i32>().ok()) else { continue };
        if read_str(&e.path().join("comm")).is_some_and(|c| names.contains(&c.as_str())) {
            out.push(pid);
        }
    }
    out
}

fn wait_pid(pid: i32) -> bool {
    let fd = unsafe { libc::syscall(libc::SYS_pidfd_open, pid, 0) } as i32;
    if fd < 0 {
        return false;
    }
    loop {
        let mut p = libc::pollfd { fd, events: libc::POLLIN, revents: 0 };
        let r = unsafe { libc::poll(&mut p, 1, -1) };
        if r > 0 || (r < 0 && std::io::Error::last_os_error().raw_os_error() != Some(libc::EINTR)) {
            break;
        }
    }
    unsafe { libc::close(fd) };
    true
}

fn start_qs() {
    let _ = Command::new("setsid")
        .args(["-f", "quickshell", "-n", "-c", "f"])
        .env("QS_NO_RELOAD_POPUP", "1")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

fn raise_nofile() {
    let mut r = libc::rlimit { rlim_cur: 0, rlim_max: 0 };
    unsafe {
        if libc::getrlimit(libc::RLIMIT_NOFILE, &mut r) == 0 {
            r.rlim_cur = r.rlim_max;
            libc::setrlimit(libc::RLIMIT_NOFILE, &r);
        }
    }
}

fn take_lock(p: &Path) -> Option<fs::File> {
    let _ = fs::create_dir_all(p.parent()?);
    let f = OpenOptions::new().create(true).truncate(false).write(true).open(p).ok()?;
    (unsafe { libc::flock(f.as_raw_fd(), libc::LOCK_EX | libc::LOCK_NB) } == 0).then_some(f)
}

pub fn watchdog() {
    let Some(_lock) = take_lock(&home().join(".cache/shell-watchdog.lock")) else { return };
    raise_nofile();
    const CHECK: Duration = Duration::from_secs(5);
    const FAIL_LIMIT: u32 = 3;
    const FAIL_WINDOW: Duration = Duration::from_secs(120);
    let (mut fails, mut misses, mut gave_up) = (0u32, 0u32, false);
    let mut last_fail: Option<Instant> = None;
    loop {
        std::thread::sleep(CHECK);
        let pids = shell_pids();
        if !pids.is_empty() {
            fails = 0;
            misses = 0;
            gave_up = false;
            for pid in pids {
                if wait_pid(pid) {
                    break;
                }
            }
            continue;
        }
        if gave_up {
            continue;
        }
        misses += 1;
        if misses < 2 {
            continue;
        }
        misses = 0;
        let now = Instant::now();
        if last_fail.is_none_or(|t| now.duration_since(t) > FAIL_WINDOW) {
            fails = 0;
        }
        last_fail = Some(now);
        fails += 1;
        if fails >= FAIL_LIMIT {
            gave_up = true;
            notify(&[
                "-a",
                "shell",
                "-u",
                "critical",
                "Shell",
                &format!("quickshell упал {fails} раза подряд, перезапуск остановлен. Руками: shell-switch qs"),
            ]);
            fails = 0;
            continue;
        }
        notify(&["-a", "shell", "Shell", &format!("quickshell упал, перезапускаю (попытка {fails})")]);
        start_qs();
    }
}
