//! Reminders: Jarvis stores them with `islandd jarvis remind add`, the always-running
//! `islandd watch` fires them, so nothing has to stay awake for it.
//!
//! ~/.local/share/jarvis/reminders.json   [{"id": 3, "at": unix, "text": "..."}]
//! $XDG_RUNTIME_DIR/jarvis/remind/<id>    due text for a running Jarvis to say in its own voice
//!
//! When due: a notification on the island always; a voice only when no game and no call.
use crate::util::home;
use serde_json::{json, Value};
use std::fs;
use std::io::Write;
use std::os::unix::io::AsRawFd;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

const CHECK_EVERY: Duration = Duration::from_secs(5);
/// Due longer ago than this when `watch` started: missed while the PC was off.
const MISSED_AFTER: i64 = 90;
/// A spool file older than this is not spoken any more (Jarvis was asleep).
const SPOOL_TTL: i64 = 300;

/// Apps whose open microphone means a call (lowercase substrings of app name or binary).
const CALL_APPS: &[&str] = &[
    "chromium", "chrome", "librewolf", "firefox", "zoom", "discord", "vesktop", "equibop", "telegram", "teams",
    "skype", "slack",
];

fn store() -> PathBuf {
    home().join(".local/share/jarvis/reminders.json")
}

fn spool() -> PathBuf {
    let run = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
    PathBuf::from(run).join("jarvis/remind")
}

fn now() -> i64 {
    unsafe { libc::time(std::ptr::null_mut()) as i64 }
}

pub fn fmt_time(t: i64, fmt: &str) -> String {
    let t = t as libc::time_t;
    let mut tm: libc::tm = unsafe { std::mem::zeroed() };
    unsafe { libc::localtime_r(&t, &mut tm) };
    let mut buf = [0u8; 128];
    let mut f = fmt.as_bytes().to_vec();
    f.push(0);
    let n = unsafe { libc::strftime(buf.as_mut_ptr().cast(), buf.len(), f.as_ptr().cast(), &tm) };
    String::from_utf8_lossy(&buf[..n]).into_owned()
}

/// Exclusive lock on the store for one read-modify-write.
struct Locked {
    _f: fs::File,
    items: Vec<Value>,
}

impl Locked {
    fn open() -> Option<Locked> {
        let p = store();
        fs::create_dir_all(p.parent()?).ok()?;
        let f = fs::OpenOptions::new().create(true).truncate(false).write(true).open(p.with_extension("lock")).ok()?;
        unsafe { libc::flock(f.as_raw_fd(), libc::LOCK_EX) };
        let items = fs::read_to_string(&p)
            .ok()
            .and_then(|s| serde_json::from_str::<Value>(&s).ok())
            .and_then(|v| v.as_array().cloned())
            .unwrap_or_default();
        Some(Locked { _f: f, items })
    }

    fn save(&self) -> bool {
        let p = store();
        let tmp = p.with_extension("json.tmp");
        let ok = fs::File::create(&tmp)
            .and_then(|mut f| {
                f.write_all(Value::Array(self.items.clone()).to_string().as_bytes())?;
                f.sync_all()
            })
            .is_ok();
        ok && fs::rename(&tmp, &p).is_ok()
    }
}

fn at_of(v: &Value) -> i64 {
    v["at"].as_i64().unwrap_or(0)
}

/// Unix seconds, or anything GNU `date -d` understands in local time
/// ("2026-11-10 20:00", "2026-11-10T20:00", "tomorrow 08:00", "+90 minutes").
fn parse_time(s: &str) -> Option<i64> {
    let s = s.trim();
    if !s.is_empty() && s.chars().all(|c| c.is_ascii_digit()) {
        return s.parse().ok();
    }
    let o = Command::new("date").args(["-d", s, "+%s"]).stderr(Stdio::null()).output().ok()?;
    if !o.status.success() {
        return None;
    }
    String::from_utf8_lossy(&o.stdout).trim().parse().ok()
}

fn usage() -> i32 {
    eprintln!("usage: islandd jarvis remind <add TIME TEXT... | list | rm ID|all>");
    2
}

/// `islandd jarvis remind ...`
pub fn cli(args: &[String]) -> i32 {
    match args.first().map(String::as_str) {
        Some("add") => {
            let (Some(when), text) = (args.get(1), args.get(2..).map(|a| a.join(" ")).unwrap_or_default()) else {
                return usage();
            };
            let text = text.trim().to_string();
            if text.is_empty() {
                return usage();
            }
            let Some(at) = parse_time(when) else {
                println!("Не понял время «{when}». Нужно ГГГГ-ММ-ДД ЧЧ:ММ или unix-время.");
                return 1;
            };
            if at < now() - 60 {
                println!("Время {} уже прошло, напоминание не поставлено.", fmt_time(at, "%Y-%m-%d %H:%M"));
                return 1;
            }
            let Some(mut l) = Locked::open() else {
                println!("Не удалось открыть файл напоминаний.");
                return 1;
            };
            let id = l.items.iter().filter_map(|v| v["id"].as_i64()).max().unwrap_or(0) + 1;
            l.items.push(json!({ "id": id, "at": at, "text": text, "created": now() }));
            l.items.sort_by_key(at_of);
            if !l.save() {
                println!("Не удалось сохранить напоминание.");
                return 1;
            }
            println!("Напоминание {id} поставлено на {}: {text}", fmt_time(at, "%a %d.%m %H:%M"));
            0
        }
        Some("list") => {
            let Some(l) = Locked::open() else { return 1 };
            if l.items.is_empty() {
                println!("Напоминаний нет.");
            }
            for v in &l.items {
                println!(
                    "{}\t{}\t{}",
                    v["id"].as_i64().unwrap_or(0),
                    fmt_time(at_of(v), "%a %Y-%m-%d %H:%M"),
                    v["text"].as_str().unwrap_or("")
                );
            }
            0
        }
        Some("rm") => {
            let Some(which) = args.get(1) else { return usage() };
            let Some(mut l) = Locked::open() else { return 1 };
            let before = l.items.len();
            if which == "all" {
                l.items.clear();
            } else {
                let Ok(id) = which.parse::<i64>() else { return usage() };
                l.items.retain(|v| v["id"].as_i64() != Some(id));
            }
            let n = before - l.items.len();
            if n == 0 {
                println!("Такого напоминания нет.");
                return 1;
            }
            if !l.save() {
                println!("Не удалось сохранить.");
                return 1;
            }
            println!("Удалено напоминаний: {n}.");
            0
        }
        _ => usage(),
    }
}

/// A call is on: a call-capable app holds the microphone, or a Meet/Zoom window is open.
pub fn in_call() -> bool {
    let mic = Command::new("pactl")
        .args(["-f", "json", "list", "source-outputs"])
        .stderr(Stdio::null())
        .output()
        .ok()
        .and_then(|o| serde_json::from_slice::<Value>(&o.stdout).ok())
        .and_then(|v| v.as_array().cloned())
        .unwrap_or_default();
    let mic_call = mic.iter().any(|s| {
        let p = &s["properties"];
        let name = format!(
            "{} {}",
            p["application.name"].as_str().unwrap_or(""),
            p["application.process.binary"].as_str().unwrap_or("")
        )
        .to_lowercase();
        CALL_APPS.iter().any(|a| name.contains(a))
    });
    if mic_call {
        return true;
    }
    let Some(text) = crate::util::hypr_request("j/clients") else { return false };
    let Ok(Value::Array(list)) = serde_json::from_str::<Value>(&text) else { return false };
    list.iter().any(|c| {
        let t = c["title"].as_str().unwrap_or("");
        t.starts_with("Meet – ") || t.starts_with("Meet - ") || t.contains("Zoom Meeting")
    })
}

fn jarvis_running() -> bool {
    let run = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/tmp".into());
    let Some(pid) = crate::util::read_str(&PathBuf::from(run).join("jarvis/pid")) else { return false };
    std::fs::read_to_string(format!("/proc/{pid}/cmdline"))
        .is_ok_and(|c| c.contains("islandd") && c.contains("jarvis") && c.contains("run"))
}

pub(crate) fn speak(text: &str) {
    // A listening Jarvis must say it itself: its mic would take a second voice for the user's.
    if jarvis_running() {
        let d = spool();
        if fs::create_dir_all(&d).is_ok() {
            let _ = fs::write(d.join(format!("{}-{}", now(), std::process::id())), text);
            return;
        }
    }
    let exe = std::env::current_exe().unwrap_or_else(|_| "islandd".into());
    let child = Command::new(exe)
        .args(["jarvis", "say", text])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn();
    if let Ok(mut c) = child {
        std::thread::spawn(move || {
            let _ = c.wait();
        });
    }
}

/// For a running Jarvis: the oldest fresh reminder to say. Stale ones are dropped.
pub fn take_spoken() -> Option<String> {
    let mut fs_: Vec<PathBuf> = fs::read_dir(spool()).ok()?.flatten().map(|e| e.path()).collect();
    fs_.sort();
    for p in fs_ {
        let born: i64 = p.file_name()?.to_string_lossy().split('-').next()?.parse().unwrap_or(0);
        let text = fs::read_to_string(&p).unwrap_or_default();
        let _ = fs::remove_file(&p);
        if now() - born <= SPOOL_TTL && !text.trim().is_empty() {
            return Some(text);
        }
    }
    None
}

fn sentence(t: &str) -> String {
    let t = t.trim().trim_end_matches(['.', '!']);
    format!("{t}.")
}

/// Fires due reminders; driven by the `watch` loop.
pub struct Watcher {
    started: i64,
    pub next: Instant,
}

impl Watcher {
    pub fn new() -> Watcher {
        Watcher { started: now(), next: Instant::now() }
    }

    pub fn check(&mut self) {
        self.next = Instant::now() + CHECK_EVERY;
        if !store().exists() {
            return;
        }
        let Some(mut l) = Locked::open() else { return };
        let t = now();
        let (due, rest): (Vec<Value>, Vec<Value>) = l.items.drain(..).partition(|v| at_of(v) <= t);
        l.items = rest;
        if due.is_empty() || !l.save() {
            return;
        }
        drop(l);
        let mut spoken = Vec::new();
        let mut missed = Vec::new();
        for v in &due {
            let text = v["text"].as_str().unwrap_or("").to_string();
            let at = at_of(v);
            if at < self.started - MISSED_AFTER {
                crate::util::notify(&[
                    "-a",
                    "Jarvis",
                    "-u",
                    "critical",
                    &format!("Пропущенное напоминание ({})", fmt_time(at, "%d.%m %H:%M")),
                    &text,
                ]);
                missed.push(text);
            } else {
                crate::util::notify(&["-a", "Jarvis", "-u", "critical", "Напоминание", &text]);
                spoken.push(text);
            }
        }
        if crate::session::is_gaming() || in_call() {
            return;
        }
        let mut say = String::new();
        if !spoken.is_empty() {
            say += &format!("Сэр, напоминаю: {}", sentence(&spoken.join(". ")));
        }
        if !missed.is_empty() {
            if !say.is_empty() {
                say.push(' ');
            }
            let head = if missed.len() == 1 {
                "Пока компьютер был выключен, прошло напоминание"
            } else {
                "Пока компьютер был выключен, прошли напоминания"
            };
            let lead = if spoken.is_empty() { format!("Сэр, {}", head.to_lowercase()) } else { head.to_string() };
            say += &format!("{lead}: {}", sentence(&missed.join(". ")));
        }
        speak(&say);
    }
}
