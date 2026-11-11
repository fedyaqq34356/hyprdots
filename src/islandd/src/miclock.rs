use crate::util::home;
use libpulse_binding as pa;
use pa::callbacks::ListResult;
use pa::context::subscribe::{Facility, InterestMaskSet, Operation};
use pa::context::{Context, FlagSet, State};
use pa::mainloop::standard::{IterateResult, Mainloop};
use pa::volume::{ChannelVolumes, Volume};
use std::cell::Cell;
use std::fs;
use std::path::PathBuf;
use std::rc::Rc;
use std::time::Duration;

const NORM: u64 = Volume::NORMAL.0 as u64;

fn level(s: Option<String>) -> Option<u32> {
    let s = s?;
    let t = s.trim();
    if t.is_empty() || !t.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    t.parse().ok()
}

fn pct(v: Volume) -> u32 {
    ((v.0 as u64 * 100 + NORM / 2) / NORM) as u32
}

fn raw(p: u32) -> Volume {
    Volume((p as f64 * NORM as f64 / 100.0).round() as u32)
}

struct Target {
    file: PathBuf,
    default: u32,
}

impl Target {
    fn get(&self) -> u32 {
        level(fs::read_to_string(&self.file).ok()).unwrap_or(self.default)
    }
}

fn session(t: &Target, src: &str) {
    let Some(mut ml) = Mainloop::new() else { return };
    let Some(mut ctx) = Context::new(&ml, "islandd-mic-lock") else { return };
    if ctx.connect(None, FlagSet::NOFLAGS, None).is_err() {
        return;
    }
    loop {
        if !matches!(ml.iterate(true), IterateResult::Success(_)) {
            return;
        }
        match ctx.get_state() {
            State::Ready => break,
            State::Failed | State::Terminated => return,
            _ => {}
        }
    }

    let dirty = Rc::new(Cell::new(true));
    let busy = Rc::new(Cell::new(false));
    let found: Rc<Cell<Option<(u8, bool, u32)>>> = Rc::new(Cell::new(None));

    let d = dirty.clone();
    ctx.set_subscribe_callback(Some(Box::new(move |fac, op, _| {
        let source_change = fac == Some(Facility::Source) && op == Some(Operation::Changed);
        if source_change || fac == Some(Facility::Server) {
            d.set(true);
        }
    })));
    ctx.subscribe(InterestMaskSet::SOURCE | InterestMaskSet::SERVER, |_| {});

    let mut intro = ctx.introspect();
    let mut first = true;
    loop {
        if dirty.get() && !busy.get() {
            dirty.set(false);
            busy.set(true);
            let want = t.get();
            let (f, b) = (found.clone(), busy.clone());
            intro.get_source_info_by_name(src, move |r| match r {
                ListResult::Item(i) => {
                    let ok = i.volume.get().iter().all(|v| pct(*v) == want);
                    f.set(Some((i.volume.len(), ok, want)));
                }
                _ => b.set(false),
            });
        }
        if let Some((ch, ok, want)) = found.take() {
            if ch > 0 && (!ok || first) {
                let mut cv = ChannelVolumes::default();
                cv.set(ch, raw(want));
                intro.set_source_volume_by_name(src, &cv, None);
            }
            if first {
                intro.set_source_mute_by_name(src, false, None);
                first = false;
            }
        }
        if !matches!(ml.iterate(true), IterateResult::Success(_)) {
            return;
        }
        if matches!(ctx.get_state(), State::Failed | State::Terminated) {
            return;
        }
    }
}

pub fn run() {
    let run = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| format!("/run/user/{}", unsafe { libc::getuid() }));
    let file = PathBuf::from(run).join("mic-lock.target");
    let saved = level(fs::read_to_string(home().join(".local/state/hypr/mic-level")).ok()).unwrap_or(100);
    let default = level(std::env::var("MIC_LOCK_LEVEL").ok()).unwrap_or(saved);
    if !file.exists() {
        let _ = fs::write(&file, default.to_string());
    }
    let t = Target { file, default };
    let src = std::env::var("MIC_LOCK_SOURCE").unwrap_or_else(|_| "@DEFAULT_SOURCE@".into());
    loop {
        session(&t, &src);
        std::thread::sleep(Duration::from_secs(2));
    }
}
