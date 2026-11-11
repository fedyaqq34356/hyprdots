use crate::util::notify;
use dbus::arg::{PropMap, RefArg, Variant};
use dbus::blocking::stdintf::org_freedesktop_dbus::ObjectManager;
use dbus::blocking::Connection;
use dbus::Path;
use std::collections::{HashMap, HashSet};
use std::time::{Duration, Instant};

const UD: &str = "org.freedesktop.UDisks2";
const BLOCK: &str = "org.freedesktop.UDisks2.Block";
const FS: &str = "org.freedesktop.UDisks2.Filesystem";
const CRYPT: &str = "org.freedesktop.UDisks2.Encrypted";

fn flag(m: &PropMap, k: &str) -> bool {
    m.get(k).and_then(|v| v.0.as_u64()).is_some_and(|x| x != 0)
}

fn text(m: &PropMap, k: &str) -> String {
    m.get(k).and_then(|v| v.0.as_str()).unwrap_or("").to_string()
}

fn bytes(a: &dyn RefArg) -> String {
    let v: Vec<u8> = a.as_iter().map(|it| it.filter_map(|b| b.as_u64()).map(|b| b as u8).collect()).unwrap_or_default();
    String::from_utf8_lossy(v.split(|b| *b == 0).next().unwrap_or(&[])).into_owned()
}

fn mounts(m: &PropMap) -> Vec<String> {
    m.get("MountPoints")
        .and_then(|v| v.0.as_iter().map(|it| it.map(bytes).filter(|s| !s.is_empty()).collect()))
        .unwrap_or_default()
}

fn human(n: u64) -> String {
    let mut x = n as f64;
    for u in ["Б", "КБ", "МБ", "ГБ", "ТБ"] {
        if x < 1000.0 {
            return if u == "Б" { format!("{x:.0} {u}") } else { format!("{x:.1} {u}") };
        }
        x /= 1000.0;
    }
    format!("{x:.1} ПБ")
}

#[derive(Clone)]
struct Dev {
    label: String,
    mounts: Vec<String>,
}

struct Mounter<'a> {
    c: &'a Connection,
    known: HashMap<Path<'static>, Dev>,
    locked: HashSet<Path<'static>>,
    first: bool,
}

impl Mounter<'_> {
    fn say(&self, title: &str, body: &str) {
        notify(&["-a", "носитель", "-u", "low", title, body]);
    }

    fn mount(&self, path: &Path<'static>, d: &Dev) {
        let mut opts = PropMap::new();
        opts.insert("auth.no_user_interaction".into(), Variant(Box::new(true)));
        let p = self.c.with_proxy(UD, path.clone(), Duration::from_secs(60));
        let r: Result<(String,), dbus::Error> = p.method_call(FS, "Mount", (opts,));
        match r {
            Ok((at,)) => self.say("смонтировано", &at),
            Err(e) if e.name() == Some("org.freedesktop.UDisks2.Error.AlreadyMounted") => {}
            Err(e) => self.say("не смонтировано", &format!("{}: {}", d.label, e.message().unwrap_or(""))),
        }
    }

    fn scan(&mut self) -> bool {
        let p = self.c.with_proxy(UD, "/org/freedesktop/UDisks2", Duration::from_secs(5));
        let Ok(objs) = p.get_managed_objects() else { return false };
        let mut now: HashMap<Path<'static>, Dev> = HashMap::new();
        let mut todo: Vec<(Path<'static>, Dev)> = vec![];
        let mut locked = HashSet::new();

        for (path, ifs) in objs {
            let Some(b) = ifs.get(BLOCK) else { continue };
            if flag(b, "HintIgnore") || !flag(b, "HintAuto") {
                continue;
            }
            let dev = b.get("PreferredDevice").or(b.get("Device")).map(|v| bytes(&*v.0)).unwrap_or_default();
            let name = dev.rsplit('/').next().unwrap_or(&dev).to_string();
            let label = match text(b, "IdLabel") {
                l if l.is_empty() => name,
                l => l,
            };
            let size = b.get("Size").and_then(|v| v.0.as_u64()).unwrap_or(0);
            let label = if size > 0 { format!("{label} · {}", human(size)) } else { label };

            if ifs.contains_key(CRYPT) {
                let open = ifs.get(CRYPT).is_some_and(|c| {
                    c.get("CleartextDevice").and_then(|v| v.0.as_str()).is_some_and(|s| s != "/")
                });
                if !open {
                    if !self.locked.contains(&path) && !self.first {
                        self.say("зашифрованный носитель", &format!("{label}: открой вручную"));
                    }
                    locked.insert(path.clone());
                }
                continue;
            }
            let Some(f) = ifs.get(FS) else { continue };
            let d = Dev { label, mounts: mounts(f) };
            match self.known.get(&path) {
                None => {
                    if d.mounts.is_empty() {
                        todo.push((path.clone(), d.clone()));
                    }
                }
                Some(old) => {
                    if !old.mounts.is_empty() && d.mounts.is_empty() {
                        self.say("отмонтировано", &d.label);
                    }
                }
            }
            now.insert(path, d);
        }

        for (path, old) in &self.known {
            if !now.contains_key(path) && !old.mounts.is_empty() {
                self.say("извлечено", &old.label);
            }
        }
        self.known = now;
        self.locked = locked;
        self.first = false;
        for (path, d) in todo {
            self.mount(&path, &d);
        }
        true
    }
}

pub fn run() {
    let Ok(conn) = Connection::new_system() else { std::process::exit(1) };
    let rules = [
        format!("type='signal',sender='{UD}'"),
        format!("type='signal',sender='org.freedesktop.DBus',member='NameOwnerChanged',arg0='{UD}'"),
    ];
    for r in &rules {
        if conn.add_match_no_cb(r).is_err() {
            std::process::exit(1);
        }
    }
    let mut m = Mounter { c: &conn, known: HashMap::new(), locked: HashSet::new(), first: true };
    let mut stale = !m.scan();
    loop {
        let ch = conn.channel();
        let wait = if stale { Duration::from_secs(10) } else { Duration::from_secs(3600) };
        match ch.blocking_pop_message(wait) {
            Ok(Some(_)) => {
                let until = Instant::now() + Duration::from_millis(300);
                loop {
                    let left = until.saturating_duration_since(Instant::now());
                    if left.is_zero() {
                        break;
                    }
                    if ch.blocking_pop_message(left).is_err() {
                        std::process::exit(1);
                    }
                }
            }
            Ok(None) if !stale => continue,
            Ok(None) => {}
            Err(_) => std::process::exit(1),
        }
        stale = !m.scan();
    }
}
