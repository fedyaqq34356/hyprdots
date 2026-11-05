use std::env;
use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;

fn sock_dir() -> Option<PathBuf> {
    let sig = env::var("HYPRLAND_INSTANCE_SIGNATURE").ok()?;
    let run = env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| format!("/run/user/{}", unsafe { getuid() }));
    Some(PathBuf::from(run).join("hypr").join(sig))
}

extern "C" {
    fn getuid() -> u32;
}

fn ask(dir: &PathBuf, req: &str) -> String {
    let mut out = String::new();
    if let Ok(mut s) = UnixStream::connect(dir.join(".socket.sock")) {
        if s.write_all(req.as_bytes()).is_ok() {
            let _ = s.read_to_string(&mut out);
        }
    }
    out
}

fn ws_id(line: &str) -> Option<i64> {
    let rest = line.strip_prefix("workspace ")?;
    let rest = rest.strip_prefix("ID ").unwrap_or(rest);
    rest.split_whitespace().next()?.parse().ok()
}

fn load_ws(dir: &PathBuf, ws: &mut [&'static str; 10]) {
    let active = ask(dir, "activeworkspace").lines().next().and_then(ws_id);
    let all: Vec<i64> = ask(dir, "workspaces").lines().filter_map(ws_id).collect();
    for i in 1..=9i64 {
        ws[i as usize] = if Some(i) == active {
            "a"
        } else if all.contains(&i) {
            "o"
        } else {
            ""
        };
    }
}

fn first_title(dir: &PathBuf) -> String {
    let text = ask(dir, "activewindow");
    let line = text.lines().next().unwrap_or("");
    match line.strip_prefix("Window ").and_then(|r| r.split_once(" -> ")) {
        Some((_, rest)) => rest.strip_suffix(':').unwrap_or(rest).to_string(),
        None => String::new(),
    }
}

fn emit(ws: &[&str; 10], title: &str) {
    let mut out = String::with_capacity(256);
    for i in 1..=9 {
        out.push_str(&format!("w{}|string|{}\n", i, ws[i]));
    }
    out.push_str(&format!("title|string|{}\n\n", title.replace('\n', " ")));
    let mut so = std::io::stdout().lock();
    if so.write_all(out.as_bytes()).and_then(|_| so.flush()).is_err() {
        std::process::exit(0);
    }
}

fn main() {
    let Some(dir) = sock_dir() else { std::process::exit(1) };
    let Ok(events) = UnixStream::connect(dir.join(".socket2.sock")) else { std::process::exit(1) };

    let mut ws = [""; 10];
    let mut title = first_title(&dir);
    load_ws(&dir, &mut ws);
    emit(&ws, &title);

    let mut reader = BufReader::new(events);
    let mut buf = Vec::with_capacity(512);
    loop {
        buf.clear();
        match reader.read_until(b'\n', &mut buf) {
            Ok(0) | Err(_) => break,
            Ok(_) => {}
        }
        let line = String::from_utf8_lossy(&buf);
        let line = line.trim_end_matches('\n');
        let Some((name, data)) = line.split_once(">>") else { continue };
        match name {
            "activewindow" => {
                title = data.split_once(',').map(|(_, t)| t.to_string()).unwrap_or_default();
                emit(&ws, &title);
            }
            "workspace" | "createworkspace" | "destroyworkspace" | "focusedmon" | "moveworkspace"
            | "renameworkspace" => {
                load_ws(&dir, &mut ws);
                emit(&ws, &title);
            }
            _ => {}
        }
    }
}
