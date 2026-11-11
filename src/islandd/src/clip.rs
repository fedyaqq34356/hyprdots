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

fn paste(args: &[&str], secs: &str) -> Option<Vec<u8>> {
    let out = Command::new("timeout")
        .arg(secs)
        .arg("wl-paste")
        .args(args)
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    out.status.success().then_some(out.stdout)
}

fn list_types() -> Vec<String> {
    paste(&["--list-types"], "2")
        .map(|b| String::from_utf8_lossy(&b).lines().map(|l| l.trim().to_string()).filter(|l| !l.is_empty()).collect())
        .unwrap_or_default()
}

fn is_image(b: &[u8]) -> bool {
    b.starts_with(b"\x89PNG")
        || b.starts_with(b"\xff\xd8\xff")
        || b.starts_with(b"GIF8")
        || (b.len() > 12 && &b[..4] == b"RIFF" && &b[8..12] == b"WEBP")
        || b.starts_with(b"BM")
        || b.starts_with(b"<svg")
        || (b.len() > 12 && &b[4..8] == b"ftyp")
}

fn store_history(data: &[u8]) {
    if data.is_empty() {
        return;
    }
    let child = Command::new("cliphist")
        .args(["-max-items", "150", "store"])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
    if let Ok(mut c) = child {
        if let Some(mut i) = c.stdin.take() {
            let _ = i.write_all(data);
        }
        let _ = c.wait();
    }
}

fn island_dir() -> std::path::PathBuf {
    let d = std::path::PathBuf::from(std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into())).join("qs-clip");
    let _ = fs::create_dir_all(&d);
    let _ = fs::set_permissions(&d, fs::Permissions::from_mode(0o700));
    d
}

fn island_emit(dir: &Path, line: &str) {
    let tmp = dir.join(".event.tmp");
    let ok = OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .mode(0o600)
        .open(&tmp)
        .and_then(|mut f| f.write_all(format!("{line}\n").as_bytes()));
    if ok.is_ok() {
        let _ = fs::rename(&tmp, dir.join("event"));
    }
}

fn island_image(dir: &Path, sig: &str, mime: &str, bytes: &[u8]) -> Option<String> {
    let ext: String = mime.trim_start_matches("image/").chars().take_while(|c| c.is_ascii_alphanumeric() || *c == '+').collect();
    let out = dir.join(format!("{sig}.{ext}"));
    if !out.exists() {
        for e in fs::read_dir(dir).into_iter().flatten().flatten() {
            let n = e.file_name();
            let n = n.to_string_lossy();
            if !n.starts_with('.') && n != "event" && e.file_type().is_ok_and(|t| t.is_file()) {
                let _ = fs::remove_file(e.path());
            }
        }
        let tmp = dir.join(".incoming");
        fs::write(&tmp, bytes).ok()?;
        fs::rename(&tmp, &out).ok()?;
    }
    Some(out.to_string_lossy().into_owned())
}

fn flat_preview(s: &str) -> String {
    let mut out = String::with_capacity(600);
    let mut space = false;
    for c in s.chars().take(600) {
        let c = if matches!(c, '\n' | '\t' | '\r') { ' ' } else { c };
        if c == ' ' {
            if space {
                continue;
            }
            space = true;
        } else {
            space = false;
        }
        out.push(c);
    }
    out
}

fn uri_summary(list: &str) -> (usize, String) {
    let items: Vec<&str> = list.lines().map(|l| l.trim_end_matches('\r')).filter(|l| !l.is_empty() && !l.starts_with('#')).collect();
    let first = items.first().map(|f| f.trim_start_matches("file://").trim_end_matches('/')).unwrap_or("");
    let base = first.rsplit('/').next().unwrap_or(first).to_string();
    (items.len(), base)
}

const IMG_CAP: u64 = 64 << 20;

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
    let _ = stdin.by_ref().take(IMG_CAP).read_to_end(&mut raw);
    let _ = std::io::copy(&mut stdin, &mut std::io::sink());
    drop(stdin);

    let cstate = std::env::var("CLIPBOARD_STATE").unwrap_or_default();
    if cstate == "clear" || (raw.is_empty() && cstate != "sensitive") {
        return;
    }
    let types = list_types();
    let pm = cstate == "sensitive" || types.iter().any(|t| t.to_ascii_lowercase().contains("x-kde-passwordmanagerhint"));
    let img_type = types.iter().find(|t| t.starts_with("image/")).cloned();
    let uri = types.iter().any(|t| t == "text/uri-list");

    let head = &raw[..raw.len().min(CAP)];
    let text = !is_image(head)
        && !head.contains(&0)
        && match std::str::from_utf8(head) {
            Ok(_) => true,
            Err(e) => e.error_len().is_none() && raw.len() >= CAP,
        };
    let data = if text { String::from_utf8_lossy(head).trim_end_matches('\n').to_string() } else { String::new() };
    let kind = if text { "text" } else { "binary" };
    let len = data.chars().count();

    let mark = state.join("clipboard-guard.last");
    let sig = fnv(&raw);
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

    let secret = text && looks_secret(&data);
    let isle = island_dir();
    let short = &sig[..12];

    if pm {
        island_emit(&isle, "secret\tpm");
    } else if let Some(mime) = img_type.as_deref() {
        let fetched;
        let bytes: &[u8] = if is_image(&raw) {
            &raw
        } else {
            fetched = paste(&["--type", mime], "3").unwrap_or_default();
            &fetched
        };
        if !bytes.is_empty() {
            let isig = fnv(bytes);
            if let Some(path) = island_image(&isle, &isig[..12], mime, bytes) {
                island_emit(&isle, &format!("img\t{}\t{path}", &isig[..12]));
            }
            store_history(bytes);
        }
    } else if uri {
        let list = if data.lines().any(|l| l.starts_with("file://")) {
            data.clone()
        } else {
            paste(&["--type", "text/uri-list"], "2").map(|b| String::from_utf8_lossy(&b).into_owned()).unwrap_or_default()
        };
        let (n, first) = uri_summary(&list);
        if n > 0 {
            island_emit(&isle, &format!("files\t{}\t{n}\t{first}", &fnv(list.as_bytes())[..12]));
        }
        store_history(&raw);
    } else if secret {
        island_emit(&isle, &format!("secret\t{short}"));
    } else if text && !data.is_empty() {
        island_emit(&isle, &format!("txt\t{short}\t{}", flat_preview(&data)));
        store_history(&raw);
    }

    let who = owner();
    if pm {
        log(&logp, &format!("SECRET  length={len}  types=password-manager  from: {who}"));
    } else if secret {
        log(&logp, &format!("SECRET  length={len}  types={kind}  from: {who}"));
        clear_later(data, ttl, &logp);
        notify(&["-a", "clipboard", "-u", "critical", "Clipboard", &format!("Looks like a secret — clearing in {ttl}s")]);
    } else {
        log(&logp, &format!("entry   length={len}  types={kind}  from: {who}"));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preview_and_uris() {
        assert_eq!(flat_preview("a\n\n\tb  c"), "a b c");
        assert_eq!(uri_summary("# c\nfile:///home/f/x%20y.png\r\nfile:///tmp/dir/\n"), (2, "x%20y.png".into()));
        assert!(is_image(b"\x89PNG\r\n\x1a\n...."));
        assert!(!is_image(b"hello"));
        assert!(looks_secret("token sk-ant-abcdefghijklmnopqrstuvwxyz"));
    }
}
