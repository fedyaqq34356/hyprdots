use crate::util::{home, hypr_request, local_time, notify};
use std::fs::{self, OpenOptions};
use std::io::{Read, Write};
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
use std::path::Path;
use std::process::{Command, Stdio};
use std::time::Duration;

const CAP: usize = 65536;

fn run_of(b: &[u8], from: usize, ok: impl Fn(u8) -> bool) -> usize {
    b[from.min(b.len())..].iter().take_while(|c| ok(**c)).count()
}

fn alnum(c: u8) -> bool {
    c.is_ascii_lowercase() || c.is_ascii_digit()
}

fn token(c: u8) -> bool {
    alnum(c) || c == b'_' || c == b'-'
}

fn find_all<'a>(hay: &'a [u8], needle: &'a [u8]) -> impl Iterator<Item = usize> + 'a {
    hay.windows(needle.len()).enumerate().filter(move |(_, w)| *w == needle).map(|(i, _)| i)
}

pub fn looks_secret(text: &str) -> bool {
    let low = text.to_ascii_lowercase();
    let b = low.as_bytes();
    if find_all(b, b"sk-ant-").any(|i| run_of(b, i + 7, token) >= 20) {
        return true;
    }
    if find_all(b, b"ghp_").any(|i| run_of(b, i + 4, alnum) >= 30) {
        return true;
    }
    if low.contains("github_pat_") {
        return true;
    }
    if find_all(b, b"xox").any(|i| b.len() > i + 4 && b"baprs".contains(&b[i + 3]) && b[i + 4] == b'-') {
        return true;
    }
    if find_all(b, b"akia").any(|i| run_of(b, i + 4, alnum) >= 16) {
        return true;
    }
    for i in find_all(b, b"-----begin ") {
        let s = i + 11;
        let n = run_of(b, s, |c| c.is_ascii_lowercase() || c == b' ');
        if b[s..s + n].ends_with(b"private key") && b[s + n..].starts_with(b"-----") {
            return true;
        }
    }
    for i in find_all(b, b":aa") {
        let digits = b[..i].iter().rev().take_while(|c| c.is_ascii_digit()).count();
        if digits >= 8 && run_of(b, i + 3, token) >= 33 {
            return true;
        }
    }
    false
}

fn fnv(data: &[u8]) -> String {
    let mut h: u64 = 0xcbf29ce484222325;
    for x in data {
        h ^= *x as u64;
        h = h.wrapping_mul(0x100000001b3);
    }
    format!("{h:016x}")
}

fn owner() -> String {
    let Some(text) = hypr_request("j/activewindow") else { return "?".into() };
    let Ok(v) = serde_json::from_str::<serde_json::Value>(&text) else { return "?".into() };
    match v.get("class").and_then(|c| c.as_str()).filter(|c| !c.is_empty()) {
        Some(class) => {
            let title: String = v.get("title").and_then(|t| t.as_str()).unwrap_or("").chars().take(60).collect();
            format!("{class}  ·  {title}")
        }
        None => "?".into(),
    }
}

fn log(path: &Path, msg: &str) {
    if let Ok(mut f) = OpenOptions::new().create(true).append(true).mode(0o600).open(path) {
        let _ = writeln!(f, "{}\t{msg}", local_time("%F %T"));
    }
}

fn current_text() -> Option<String> {
    let out = Command::new("timeout")
        .args(["2", "wl-paste", "--no-newline", "--type", "text"])
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    Some(String::from_utf8_lossy(&out.stdout).into_owned())
}

fn clear_later(data: String, ttl: u64, logp: &Path) {
    let pid = unsafe { libc::fork() };
    if pid != 0 {
        return;
    }
    unsafe {
        libc::setsid();
        let null = libc::open(c"/dev/null".as_ptr(), libc::O_RDWR);
        if null >= 0 {
            libc::dup2(null, 0);
            libc::dup2(null, 1);
            libc::dup2(null, 2);
        }
    }
    std::thread::sleep(Duration::from_secs(ttl));
    if current_text().as_deref() == Some(data.as_str()) {
        let _ = Command::new("wl-copy").arg("--clear").status();
        log(logp, "cleared on a timer");
        let _ = Command::new("notify-send").args(["-a", "clipboard", "Clipboard", "Secret cleared"]).status();
    }
    std::process::exit(0);
}

pub fn run(_args: &[String]) {
    let state = home().join(".local/state");
    let _ = fs::create_dir_all(&state);
    let logp = state.join("clipboard-guard.log");
    if let Ok(f) = OpenOptions::new().create(true).append(true).mode(0o600).open(&logp) {
        let _ = f.set_permissions(fs::Permissions::from_mode(0o600));
    }
    let ttl: u64 = std::env::var("CLIPBOARD_SECRET_TTL").ok().and_then(|v| v.parse().ok()).unwrap_or(45);

    let mut raw = Vec::with_capacity(4096);
    let mut stdin = std::io::stdin().lock();
    let _ = stdin.by_ref().take(CAP as u64).read_to_end(&mut raw);
    let _ = std::io::copy(&mut stdin, &mut std::io::sink());
    drop(stdin);

    let text = !raw.contains(&0)
        && match std::str::from_utf8(&raw) {
            Ok(_) => true,
            Err(e) => e.error_len().is_none() && raw.len() >= CAP,
        };
    let data = if text { String::from_utf8_lossy(&raw).trim_end_matches('\n').to_string() } else { String::new() };
    let kind = if text { "text" } else { "binary" };
    let len = data.chars().count();

    let mark = state.join("clipboard-guard.last");
    let sig = fnv(data.as_bytes());
    let now = unsafe { libc::time(std::ptr::null_mut()) } as i64;
    if let Ok(prev) = fs::read_to_string(&mark) {
        let mut it = prev.split_whitespace();
        let (ps, pt) = (it.next().unwrap_or(""), it.next().and_then(|t| t.parse::<i64>().ok()).unwrap_or(0));
        if ps == sig && now - pt < 5 {
            return;
        }
    }
    if let Ok(mut f) = OpenOptions::new().create(true).write(true).truncate(true).mode(0o600).open(&mark) {
        let _ = writeln!(f, "{sig} {now}");
    }

    let who = owner();
    if text && looks_secret(&data) {
        log(&logp, &format!("SECRET  length={len}  types={kind}  from: {who}"));
        clear_later(data, ttl, &logp);
        notify(&["-a", "clipboard", "-u", "critical", "Clipboard", &format!("Looks like a secret — clearing in {ttl}s")]);
    } else {
        log(&logp, &format!("entry   length={len}  types={kind}  from: {who}"));
    }
}
