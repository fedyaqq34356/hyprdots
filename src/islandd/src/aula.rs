use crate::util::{monotonic, read_str, sorted_dir};
use serde_json::{json, Map, Value};
use std::collections::HashMap;
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Write};
use std::os::fd::AsRawFd;
use std::os::unix::fs::OpenOptionsExt;
use std::path::{Path, PathBuf};
use std::time::Duration;

const VERSION: &str = "1.0";

const WIRED: (u32, u32) = (0x258A, 0x010C);
const DONGLE: (u32, u32) = (0x3554, 0xFA09);

const REPORT_LEN: usize = 520;
const CFG_LEN: usize = 128;
const MATRIX_LEN: usize = 384;
const LEDS: usize = 126;
const LIVE_LEN: usize = LEDS * 3;
const GAP: f64 = 0.05;
const MODEL_F75: [u8; 6] = [3, 0, 0, 0, 0, 0xCD];

const OFF_CUSTOM: usize = 0x09;
const OFF_EFFECT: usize = 0x0A;
const OFF_INDICATOR: usize = 0x12;
const OFF_SLEEP: usize = 0x18;
const OFF_SLOTS: usize = 0x3A;
const SIG: [u8; 2] = [0x5A, 0xA5];

const D_RID: u8 = 0x13;
const D_CHUNK: usize = 14;
const D_ONLINE: u8 = 0x07;
const D_STATUS: u8 = 0x4A;
const D_EVENT: u8 = 0x0A;
const D_REALTIME: u8 = 0x88;
const D_RT_MAX: usize = 200;

fn d_block(name: &str) -> (u8, u8, u8) {
    match name {
        "config" => (0x44, 0x04, 0),
        "colors" | "matrix" => (0x42, 0x02, 0),
        _ => (0x49, 0x09, 0),
    }
}

struct Effect {
    id: u8,
    name: &'static str,
    speed: bool,
    palette: bool,
    works: bool,
}

const fn fx(id: u8, name: &'static str, speed: bool, palette: bool, works: bool) -> Effect {
    Effect { id, name, speed, palette, works }
}

const EFFECTS: [Effect; 20] = [
    fx(0, "off", false, false, true),
    fx(1, "static", false, true, true),
    fx(2, "breathe", true, true, true),
    fx(3, "rainbow", true, false, true),
    fx(4, "flash_away", true, true, true),
    fx(5, "raindrops", true, true, true),
    fx(6, "rainbow_wheel", true, true, true),
    fx(7, "ripples", true, true, true),
    fx(8, "stars", true, true, true),
    fx(9, "shadow", true, true, false),
    fx(10, "snake", true, true, true),
    fx(11, "neon", true, true, true),
    fx(12, "reactive", true, true, true),
    fx(13, "sine_wave", true, true, true),
    fx(14, "scanner", true, true, false),
    fx(15, "windmill", true, false, true),
    fx(16, "waterfall", true, false, true),
    fx(17, "blossom", true, false, true),
    fx(18, "storm", true, true, false),
    fx(21, "custom", false, false, true),
];

const ALIASES: [(&str, u8); 21] = [
    ("fixed", 1), ("fixed_on", 1), ("solid", 1), ("respire", 2), ("breathing", 2),
    ("flash", 4), ("rain", 5), ("wheel", 6), ("ripple", 7), ("stars_twinkle", 8),
    ("twinkle", 8), ("shadow_fade", 9), ("retro_snake", 10), ("neon_stream", 11),
    ("reaction", 12), ("sine", 13), ("wave", 13), ("blossoming", 17),
    ("self_defined", 21), ("per_key", 21), ("perkey", 21),
];

const PALETTE: [&str; 8] = ["red", "green", "blue", "yellow", "magenta", "cyan", "white", "random"];
const INDICATOR: [&str; 4] = ["off", "blink", "slow_blink", "on"];
const SLEEP: [(u32, u8); 9] = [(60, 2), (90, 3), (120, 4), (180, 6), (240, 8), (300, 10), (600, 20), (900, 30), (1200, 40)];

fn effect(id: u8) -> Option<&'static Effect> {
    EFFECTS.iter().find(|e| e.id == id)
}

fn slot_of(eid: u8) -> Option<usize> {
    match eid {
        1..=18 => Some(eid as usize - 1),
        21 => Some(18),
        0 => Some(19),
        _ => None,
    }
}

type Key = (&'static str, u16, u16, u16, u16, usize);

const LAYOUT: [Key; 80] = [
    ("esc", 30, 30, 25, 27, 0), ("f1", 107, 30, 25, 27, 12),
    ("f2", 144, 30, 25, 27, 18), ("f3", 183, 30, 25, 27, 24),
    ("f4", 222, 30, 25, 27, 30), ("f5", 269, 30, 25, 27, 36),
    ("f6", 305, 30, 25, 27, 42), ("f7", 343, 30, 25, 27, 48),
    ("f8", 388, 30, 25, 27, 54), ("f9", 439, 30, 25, 27, 60),
    ("f10", 477, 30, 25, 27, 66), ("f11", 516, 30, 25, 27, 72),
    ("f12", 555, 30, 25, 27, 78),
    ("grave", 31, 81, 25, 27, 1), ("1", 70, 81, 25, 27, 7),
    ("2", 108, 81, 25, 27, 13), ("3", 147, 81, 25, 27, 19),
    ("4", 184, 81, 25, 27, 25), ("5", 223, 81, 25, 27, 31),
    ("6", 262, 81, 25, 27, 37), ("7", 300, 81, 25, 27, 43),
    ("8", 338, 81, 25, 27, 49), ("9", 377, 81, 25, 27, 55),
    ("0", 416, 81, 25, 27, 61), ("minus", 453, 81, 25, 27, 67),
    ("equal", 491, 81, 25, 27, 73), ("backspace", 531, 81, 60, 27, 79),
    ("delete", 604, 81, 25, 27, 85),
    ("tab", 34, 120, 44, 27, 2), ("q", 89, 120, 25, 27, 8),
    ("w", 127, 120, 25, 27, 14), ("e", 165, 120, 25, 27, 20),
    ("r", 204, 120, 25, 27, 26), ("t", 242, 120, 25, 27, 32),
    ("y", 280, 120, 25, 27, 38), ("u", 318, 120, 25, 27, 44),
    ("i", 356, 120, 25, 27, 50), ("o", 395, 120, 25, 27, 56),
    ("p", 433, 120, 25, 27, 62), ("lbracket", 471, 120, 25, 27, 68),
    ("rbracket", 509, 120, 25, 27, 74), ("backslash", 549, 120, 44, 27, 80),
    ("pgup", 605, 120, 25, 27, 86),
    ("caps", 33, 158, 52, 27, 3), ("a", 98, 158, 25, 27, 9),
    ("s", 136, 158, 25, 27, 15), ("d", 174, 158, 25, 27, 21),
    ("f", 213, 158, 25, 27, 27), ("g", 252, 158, 25, 27, 33),
    ("h", 290, 158, 25, 27, 39), ("j", 327, 158, 25, 27, 45),
    ("k", 366, 158, 25, 27, 51), ("l", 405, 158, 25, 27, 57),
    ("semicolon", 443, 158, 25, 27, 63), ("quote", 481, 158, 25, 27, 69),
    ("enter", 521, 158, 70, 27, 81), ("pgdn", 604, 158, 25, 27, 87),
    ("lshift", 33, 195, 72, 27, 4), ("z", 116, 195, 25, 27, 10),
    ("x", 155, 195, 25, 27, 16), ("c", 193, 195, 25, 27, 22),
    ("v", 232, 195, 25, 27, 28), ("b", 270, 195, 25, 27, 34),
    ("n", 309, 195, 25, 27, 40), ("m", 347, 195, 25, 27, 46),
    ("comma", 384, 195, 25, 27, 52), ("dot", 424, 195, 25, 27, 58),
    ("slash", 463, 195, 25, 27, 64), ("rshift", 502, 195, 56, 27, 70),
    ("up", 567, 195, 25, 27, 82), ("end", 605, 195, 25, 27, 88),
    ("lctrl", 34, 234, 35, 27, 5), ("lwin", 79, 234, 35, 27, 11),
    ("lalt", 122, 234, 35, 27, 17), ("space", 174, 234, 226, 27, 35),
    ("fn", 414, 234, 35, 27, 53), ("rctrl", 463, 234, 34, 27, 59),
    ("left", 529, 234, 25, 27, 77), ("down", 568, 234, 25, 27, 83),
    ("right", 605, 234, 25, 27, 89),
];

const LABELS: [(&str, &str); 32] = [
    ("esc", "Esc"), ("grave", "`"), ("minus", "-"), ("equal", "="),
    ("backspace", "⌫"), ("delete", "Del"), ("tab", "Tab"), ("lbracket", "["),
    ("rbracket", "]"), ("backslash", "\\"), ("pgup", "PgUp"), ("caps", "Caps"),
    ("semicolon", ";"), ("quote", "'"), ("enter", "Enter"), ("pgdn", "PgDn"),
    ("lshift", "Shift"), ("comma", ","), ("dot", "."), ("slash", "/"),
    ("rshift", "Shift"), ("up", "↑"), ("end", "End"), ("lctrl", "Ctrl"),
    ("lwin", "Win"), ("lalt", "Alt"), ("space", ""), ("fn", "Fn"), ("rctrl", "Ctrl"),
    ("left", "←"), ("down", "↓"), ("right", "→"),
];

const KNOB: [u16; 4] = [600, 27, 34, 34];

const KEY_ALIASES: [(&str, &str); 24] = [
    ("escape", "esc"), ("`", "grave"), ("~", "grave"), ("-", "minus"), ("=", "equal"),
    ("bksp", "backspace"), ("del", "delete"), ("[", "lbracket"), ("]", "rbracket"),
    ("\\", "backslash"), ("capslock", "caps"), (";", "semicolon"), ("'", "quote"),
    ("return", "enter"), ("shift", "lshift"), (",", "comma"), (".", "dot"),
    ("/", "slash"), ("ctrl", "lctrl"), ("win", "lwin"), ("super", "lwin"),
    ("alt", "lalt"), ("pageup", "pgup"), ("pagedown", "pgdn"),
];

fn led_by_name(n: &str) -> Option<usize> {
    LAYOUT.iter().find(|k| k.0 == n).map(|k| k.5)
}

pub struct AErr {
    code: &'static str,
    message: String,
}

type R<T> = Result<T, AErr>;

fn err<T>(code: &'static str, message: impl Into<String>) -> R<T> {
    Err(AErr { code, message: message.into() })
}

fn exit_code(code: &str) -> i32 {
    match code {
        "usage" => 1,
        "not_found" => 2,
        "permission" => 3,
        "protocol" => 4,
        "asleep" => 5,
        "unsupported" => 6,
        "busy" => 7,
        "io" => 8,
        _ => 1,
    }
}

fn is_digits(s: &str) -> bool {
    !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit())
}

fn resolve_key(name: &str) -> R<usize> {
    let s = name.trim().to_lowercase();
    if is_digits(&s) && led_by_name(&s).is_none() {
        if let Ok(v) = s.parse::<usize>() {
            if v < LEDS {
                return Ok(v);
            }
        }
    }
    let s = KEY_ALIASES.iter().find(|a| a.0 == s).map_or(s.as_str(), |a| a.1);
    led_by_name(s).map_or_else(|| err("usage", format!("неизвестная клавиша: '{name}'")), Ok)
}

type Rgb = [u8; 3];

fn parse_color(s: &str) -> R<Rgb> {
    let mut h: String = s.trim().trim_start_matches('#').to_string();
    if h.chars().count() == 3 {
        h = h.chars().flat_map(|c| [c, c]).collect();
    }
    if h.len() != 6 || !h.bytes().all(|b| b.is_ascii_hexdigit()) {
        return err("usage", format!("цвет должен быть #rrggbb, а не '{s}'"));
    }
    let p = |i: usize| u8::from_str_radix(&h[i..i + 2], 16).unwrap_or(0);
    Ok([p(0), p(2), p(4)])
}

fn hexc(c: &Rgb) -> String {
    format!("#{:02x}{:02x}{:02x}", c[0], c[1], c[2])
}

fn hexdump(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect::<Vec<_>>().join(" ")
}

fn hex_encode(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

fn hex_decode(s: &str) -> R<Vec<u8>> {
    let s: String = s.split_whitespace().collect();
    if s.len() % 2 != 0 {
        return err("usage", "битый hex в копии");
    }
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).or_else(|_| err("usage", "битый hex в копии")))
        .collect()
}

#[derive(Clone)]
struct Cand {
    kind: &'static str,
    path: String,
    name: String,
    iface: Option<i64>,
    feature6: bool,
    vendor13: bool,
    access: bool,
}

impl Cand {
    fn to_json(&self) -> Value {
        json!({"kind": self.kind, "path": self.path, "name": self.name, "iface": self.iface,
               "feature6": self.feature6, "vendor13": self.vendor13, "access": self.access})
    }
}

fn contains(hay: &[u8], needle: &[u8]) -> bool {
    hay.windows(needle.len()).any(|w| w == needle)
}

fn can_rw(path: &str) -> bool {
    let mut c = path.as_bytes().to_vec();
    c.push(0);
    unsafe { libc::access(c.as_ptr().cast(), libc::R_OK | libc::W_OK) == 0 }
}

fn scan() -> Vec<Cand> {
    let mut out = vec![];
    for node in sorted_dir(Path::new("/sys/class/hidraw"), "hidraw") {
        let ue = fs::read_to_string(node.join("device/uevent")).unwrap_or_default();
        let info: HashMap<&str, &str> = ue.lines().filter_map(|l| l.split_once('=')).collect();
        let hid: Vec<&str> = info.get("HID_ID").copied().unwrap_or("").split(':').collect();
        if hid.len() != 3 {
            continue;
        }
        let (Ok(bus), Ok(vid), Ok(pid)) =
            (u32::from_str_radix(hid[0], 16), u32::from_str_radix(hid[1], 16), u32::from_str_radix(hid[2], 16))
        else {
            continue;
        };
        let name = info.get("HID_NAME").copied().unwrap_or("").to_string();
        let low = name.to_lowercase();
        let kind = if bus == 3 && (vid, pid) == WIRED {
            "wired"
        } else if bus == 3 && (vid, pid) == DONGLE {
            "dongle"
        } else if bus == 5 && (low.contains("aula") || low.contains("f75")) {
            "bt"
        } else {
            continue;
        };
        let mut iface = None;
        if let Ok(real) = fs::canonicalize(node.join("device")) {
            if let Some(parent) = real.parent().and_then(|p| p.file_name()).map(|n| n.to_string_lossy().into_owned()) {
                if parent.contains(':') && parent.contains('.') {
                    iface = parent.rsplit_once('.').and_then(|(_, n)| n.parse::<i64>().ok());
                }
            }
        }
        let desc = fs::read(node.join("device/report_descriptor")).unwrap_or_default();
        let dev = format!("/dev/{}", node.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default());
        out.push(Cand {
            kind,
            access: can_rw(&dev),
            path: dev,
            name,
            iface,
            feature6: contains(&desc, b"\x85\x06"),
            vendor13: contains(&desc, b"\x06\x02\xff") && contains(&desc, b"\x85\x13"),
        });
    }
    out
}

fn pick(cands: &[Cand], want: &str) -> Option<Cand> {
    let wired: Vec<&Cand> = cands.iter().filter(|c| c.kind == "wired" && c.iface == Some(1) && c.feature6).collect();
    let mut dongle: Vec<&Cand> = cands.iter().filter(|c| c.kind == "dongle" && c.vendor13).collect();
    if dongle.is_empty() {
        dongle = cands.iter().filter(|c| c.kind == "dongle" && c.iface == Some(1)).collect();
    }
    let order: Vec<&Cand> = match want {
        "wired" => wired,
        "dongle" => dongle,
        _ => wired.into_iter().chain(dongle).collect(),
    };
    order.first().map(|c| (*c).clone())
}

fn connection(cands: &[Cand]) -> &'static str {
    for k in ["wired", "dongle", "bt"] {
        if cands.iter().any(|c| c.kind == k) {
            return k;
        }
    }
    "none"
}

fn sleep_s(s: f64) {
    if s > 0.0 {
        std::thread::sleep(Duration::from_secs_f64(s));
    }
}

fn runtime_dir() -> PathBuf {
    std::env::var_os("XDG_RUNTIME_DIR").filter(|v| !v.is_empty()).map_or_else(|| PathBuf::from("/tmp"), PathBuf::from)
}

enum LockErr {
    Yield,
    Fail(AErr),
}

impl From<AErr> for LockErr {
    fn from(e: AErr) -> Self {
        LockErr::Fail(e)
    }
}

struct Lock {
    _main: File,
    _prio: Option<File>,
}

fn lock_file(p: &Path) -> R<File> {
    OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .mode(0o600)
        .open(p)
        .or_else(|e| err("io", format!("лок {}: {e}", p.display())))
}

fn flock_nb(f: &File, op: i32) -> bool {
    unsafe { libc::flock(f.as_raw_fd(), op | libc::LOCK_NB) == 0 }
}

fn take(f: &File, end: f64) -> bool {
    loop {
        if flock_nb(f, libc::LOCK_EX) {
            return true;
        }
        if monotonic() > end {
            return false;
        }
        sleep_s(0.01);
    }
}

fn busy<T>() -> R<T> {
    err("busy", "клавиатура занята другим вызовом aulactl")
}

impl Lock {
    fn get(wait: f64) -> R<Lock> {
        match Self::acquire(wait, false) {
            Ok(l) => Ok(l),
            Err(LockErr::Fail(e)) => Err(e),
            Err(LockErr::Yield) => busy(),
        }
    }

    fn acquire(wait: f64, live: bool) -> Result<Lock, LockErr> {
        let d = runtime_dir();
        let end = monotonic() + wait;
        let pfd = lock_file(&d.join("aulactl.prio"))?;
        let prio = if live {
            if !flock_nb(&pfd, libc::LOCK_SH) {
                return Err(LockErr::Yield);
            }
            drop(pfd);
            None
        } else {
            if !take(&pfd, end) {
                return Err(LockErr::Fail(busy::<()>().unwrap_err()));
            }
            Some(pfd)
        };
        let main = lock_file(&d.join("aulactl.lock"))?;
        if !take(&main, end) {
            return Err(LockErr::Fail(busy::<()>().unwrap_err()));
        }
        Ok(Lock { _main: main, _prio: prio })
    }
}

fn open_dev(path: &str) -> R<File> {
    match OpenOptions::new().read(true).write(true).open(path) {
        Ok(f) => Ok(f),
        Err(e) if e.kind() == std::io::ErrorKind::PermissionDenied => err(
            "permission",
            format!("нет доступа к {path}: поставь udev-правило 70-aula-f75.rules и переподключи клавиатуру"),
        ),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => err("not_found", "клавиатура отключилась"),
        Err(e) => err("io", format!("{path}: {e}")),
    }
}

const fn ioc(nr: u64, size: u64) -> u64 {
    (3 << 30) | (size << 16) | ((b'H' as u64) << 8) | nr
}

const HIDIOCSFEATURE: u64 = ioc(0x06, REPORT_LEN as u64);
const HIDIOCGFEATURE: u64 = ioc(0x07, REPORT_LEN as u64);

fn w_header(cmd: u8, length: usize, b2: u8) -> [u8; 8] {
    [6, cmd, b2, 0, 1, 0, (length & 0xFF) as u8, (length >> 8) as u8]
}

fn w_packet(header: &[u8; 8], payload: &[u8]) -> Vec<u8> {
    let mut p = vec![0u8; REPORT_LEN];
    p[..8].copy_from_slice(header);
    p[8..8 + payload.len()].copy_from_slice(payload);
    p
}

fn safe(p: &[u8]) -> R<()> {
    if p.len() == REPORT_LEN && p[0] == 6 && [0x84, 0x86, 0x82, 0x04, 0x06, 0x08].contains(&p[1]) {
        return Ok(());
    }
    if p.len() == 20 && p[0] == D_RID && [0x44, 0x42, 0x49, 0x04, 0x02, 0x09, D_ONLINE, D_STATUS, D_REALTIME].contains(&p[1]) {
        return Ok(());
    }
    err("protocol", "отказ: пакет вне белого списка")
}

fn errno() -> i32 {
    std::io::Error::last_os_error().raw_os_error().unwrap_or(0)
}

fn strerror(e: i32) -> String {
    std::io::Error::from_raw_os_error(e).to_string().split(" (os error").next().unwrap_or("").to_string()
}

enum Dev {
    Wired(Wired),
    Dongle(Dongle),
}

struct Wired {
    path: String,
    f: File,
    last: f64,
}

impl Wired {
    fn new(path: &str) -> R<Wired> {
        Ok(Wired { path: path.into(), f: open_dev(path)?, last: 0.0 })
    }

    fn pace(&mut self) {
        sleep_s(GAP - (monotonic() - self.last));
        self.last = monotonic();
    }

    fn set(&mut self, p: &[u8]) -> R<()> {
        safe(p)?;
        self.pace();
        let mut buf = p.to_vec();
        if unsafe { libc::ioctl(self.f.as_raw_fd(), HIDIOCSFEATURE as _, buf.as_mut_ptr()) } < 0 {
            let e = errno();
            if e == libc::ENODEV || e == libc::ENOENT {
                return err("not_found", "клавиатура отключилась");
            }
            return err("io", format!("запись в {}: {}", self.path, strerror(e)));
        }
        Ok(())
    }

    fn get(&mut self) -> R<Vec<u8>> {
        self.pace();
        let mut buf = vec![0u8; REPORT_LEN];
        buf[0] = 6;
        let n = unsafe { libc::ioctl(self.f.as_raw_fd(), HIDIOCGFEATURE as _, buf.as_mut_ptr()) };
        if n < 0 {
            return err("io", format!("чтение из {}: {}", self.path, strerror(errno())));
        }
        let n = n as usize;
        if n > 0 && n <= REPORT_LEN {
            buf.truncate(n);
        }
        Ok(buf)
    }

    fn request(&mut self, header: [u8; 8], size: usize) -> R<Vec<u8>> {
        self.set(&w_packet(&header, &[]))?;
        let r = self.get()?;
        if r.len() < 8 + size || r[..8] != header {
            return err("protocol", format!("неожиданный ответ клавиатуры: {}", hexdump(&r[..r.len().min(8)])));
        }
        Ok(r[8..8 + size].to_vec())
    }

    fn live(&mut self, frame: &[Rgb]) -> R<()> {
        let mut payload = vec![0u8; LIVE_LEN];
        for (i, c) in frame.iter().take(LEDS).enumerate() {
            payload[i * 3..i * 3 + 3].copy_from_slice(c);
        }
        let mut buf = w_packet(&w_header(0x08, LIVE_LEN, 0), &payload);
        safe(&buf)?;
        for attempt in 0..4 {
            if unsafe { libc::ioctl(self.f.as_raw_fd(), HIDIOCSFEATURE as _, buf.as_mut_ptr()) } >= 0 {
                return Ok(());
            }
            let e = errno();
            if e == libc::ENODEV || e == libc::ENOENT {
                return err("not_found", "клавиатура отключилась");
            }
            sleep_s(0.02 * (attempt + 1) as f64);
        }
        err("io", "живой кадр не прошёл")
    }
}

fn d_packet(cmd: u8, total: usize, idx: usize, sub_len: u8, data: &[u8]) -> [u8; 20] {
    let mut p = [0u8; 20];
    p[0] = D_RID;
    p[1] = cmd;
    p[2] = total as u8;
    p[3] = idx as u8;
    p[4] = sub_len;
    let d = &data[..data.len().min(D_CHUNK)];
    p[5..5 + d.len()].copy_from_slice(d);
    p[19] = p[..19].iter().fold(0u8, |a, b| a.wrapping_add(*b));
    p
}

fn sum19(b: &[u8]) -> u8 {
    b[..19].iter().fold(0u8, |a, x| a.wrapping_add(*x))
}

struct Dongle {
    path: String,
    f: File,
    queue: Vec<[u8; 20]>,
}

impl Dongle {
    fn new(path: &str) -> R<Dongle> {
        let mut d = Dongle { path: path.into(), f: open_dev(path)?, queue: vec![] };
        let on = d.read_all(D_ONLINE, 0, 2)?;
        if on.first() != Some(&1) {
            return err("asleep", "клавиатура спит — нажми любую клавишу");
        }
        Ok(d)
    }

    fn send(&mut self, p: &[u8]) -> R<()> {
        safe(p)?;
        if let Err(e) = (&self.f).write(p) {
            let c = e.raw_os_error().unwrap_or(0);
            if c == libc::ENODEV || c == libc::ENOENT {
                return err("not_found", "донгл отключился");
            }
            return err("io", format!("запись в {}: {}", self.path, strerror(c)));
        }
        Ok(())
    }

    fn frame(&mut self, timeout: f64) -> R<Option<[u8; 20]>> {
        let mut p = libc::pollfd { fd: self.f.as_raw_fd(), events: libc::POLLIN, revents: 0 };
        let ms = (timeout * 1000.0).ceil().max(0.0) as i32;
        if unsafe { libc::poll(&mut p, 1, ms) } <= 0 {
            return Ok(None);
        }
        let mut b = [0u8; 64];
        let n = match (&self.f).read(&mut b) {
            Ok(n) => n,
            Err(e) => {
                let c = e.raw_os_error().unwrap_or(0);
                if c == libc::ENODEV || c == libc::ENOENT {
                    return err("not_found", "донгл отключился");
                }
                return err("io", format!("чтение из {}: {}", self.path, strerror(c)));
            }
        };
        let mut v: Vec<u8> = b[..n].to_vec();
        if v.len() == 19 {
            v.insert(0, D_RID);
        }
        if v.len() != 20 || v[0] != D_RID || sum19(&v) != v[19] {
            return Ok(None);
        }
        if v[1] == D_EVENT || (v[1] & 0x7F) == (D_REALTIME & 0x7F) {
            return Ok(None);
        }
        let mut out = [0u8; 20];
        out.copy_from_slice(&v);
        Ok(Some(out))
    }

    fn recv(&mut self, cmd: u8, timeout: f64) -> R<Option<[u8; 20]>> {
        let end = monotonic() + timeout;
        loop {
            if let Some(i) = self.queue.iter().position(|r| (r[1] & 0x7F) == (cmd & 0x7F)) {
                return Ok(Some(self.queue.remove(i)));
            }
            let left = end - monotonic();
            if left <= 0.0 {
                return Ok(None);
            }
            if let Some(r) = self.frame(left.min(0.1))? {
                self.queue.push(r);
            }
        }
    }

    fn read_all(&mut self, cmd: u8, sub: u8, tries: usize) -> R<Vec<u8>> {
        for _ in 0..tries {
            self.queue.clear();
            self.send(&d_packet(cmd, 1, 0, sub << 4, &[]))?;
            let mut parts: HashMap<u8, Vec<u8>> = HashMap::new();
            loop {
                let Some(r) = self.recv(cmd, 1.0)? else { break };
                if r[1] & 0x80 != 0 || r[2] & 0x80 != 0 {
                    break;
                }
                let total = (r[2] & 0x7F) as usize;
                let idx = r[3];
                let len = ((r[4] & 0x0F) as usize).min(D_CHUNK);
                parts.insert(idx, r[5..5 + len].to_vec());
                if idx as usize + 1 >= total {
                    if parts.len() == total && (0..total).all(|k| parts.contains_key(&(k as u8))) {
                        return Ok((0..total).flat_map(|k| parts[&(k as u8)].clone()).collect());
                    }
                    break;
                }
            }
            sleep_s(0.1);
        }
        err("protocol", format!("донгл не ответил на 0x{cmd:02x}"))
    }

    fn write_cmd(&mut self, cmd: u8, data: &[u8], sub: u8) -> R<()> {
        let total = data.len().div_ceil(D_CHUNK).max(1);
        self.queue.clear();
        for idx in 0..total {
            let chunk = &data[(idx * D_CHUNK).min(data.len())..((idx + 1) * D_CHUNK).min(data.len())];
            let p = d_packet(cmd, total, idx, (sub << 4) | chunk.len() as u8, chunk);
            let mut ok = false;
            for _ in 0..5 {
                self.send(&p)?;
                if let Some(r) = self.recv(cmd, 1.0)? {
                    if r[2] & 0x80 == 0 && r[3] as usize == idx {
                        ok = true;
                        break;
                    }
                }
                sleep_s(0.1);
            }
            if !ok {
                return err("protocol", format!("донгл не принял 0x{cmd:02x} #{idx}"));
            }
            sleep_s(0.015);
        }
        Ok(())
    }

    fn block(&mut self, name: &str) -> R<Vec<u8>> {
        let (g, _, sub) = d_block(name);
        self.read_all(g, sub, 3)
    }

    fn put(&mut self, name: &str, data: &[u8]) -> R<()> {
        let (_, p, sub) = d_block(name);
        self.write_cmd(p, data, sub)
    }

    fn battery(&mut self) -> Option<u8> {
        match self.read_all(D_STATUS, 0, 1) {
            Ok(st) => st.first().copied().filter(|b| *b <= 100),
            Err(_) => None,
        }
    }

    fn live(&mut self, frame: &[Rgb]) -> R<()> {
        let frame = &frame[..frame.len().min(LEDS)];
        if let Some(first) = frame.first() {
            if frame.iter().all(|c| c == first) {
                return self.rt(2, first);
            }
        }
        match encode_groups(frame) {
            Some(enc) => self.rt(1, &enc),
            None => self.rt(2, &[0, 0, 0]),
        }
    }

    fn rt(&mut self, sub: u8, data: &[u8]) -> R<()> {
        let total = data.len().div_ceil(D_CHUNK).max(1);
        for idx in 0..total {
            sleep_s(0.010);
            let chunk = &data[(idx * D_CHUNK).min(data.len())..((idx + 1) * D_CHUNK).min(data.len())];
            self.send(&d_packet(D_REALTIME, total, idx, (sub << 4) | chunk.len() as u8, chunk))?;
        }
        Ok(())
    }
}

fn encode_groups(frame: &[Rgb]) -> Option<Vec<u8>> {
    for q in [1u32, 8, 16, 24, 32, 48, 64, 85, 128] {
        let mut groups: Vec<(Rgb, Vec<u8>)> = vec![];
        for (led, c) in frame.iter().enumerate() {
            let qc: Rgb = if q > 1 {
                c.map(|v| ((v as f64 / q as f64).round_ties_even() * q as f64).clamp(0.0, 255.0) as u8)
            } else {
                *c
            };
            if qc.iter().all(|v| *v < 3) {
                continue;
            }
            match groups.iter_mut().find(|g| g.0 == qc) {
                Some(g) => g.1.push(led as u8),
                None => groups.push((qc, vec![led as u8])),
            }
        }
        let size: usize = groups.iter().map(|g| 4 + g.1.len()).sum();
        if size > D_RT_MAX {
            continue;
        }
        let mut out = vec![];
        for (c, leds) in groups {
            out.extend_from_slice(&c);
            out.push(leds.len() as u8);
            out.extend_from_slice(&leds);
        }
        return Some(out);
    }
    None
}

impl Dev {
    fn kind(&self) -> &'static str {
        match self {
            Dev::Wired(_) => "wired",
            Dev::Dongle(_) => "dongle",
        }
    }

    fn path(&self) -> &str {
        match self {
            Dev::Wired(w) => &w.path,
            Dev::Dongle(d) => &d.path,
        }
    }

    fn open(c: &Cand) -> R<Dev> {
        Ok(if c.kind == "wired" { Dev::Wired(Wired::new(&c.path)?) } else { Dev::Dongle(Dongle::new(&c.path)?) })
    }

    fn model(&mut self) -> R<Vec<u8>> {
        match self {
            Dev::Wired(w) => w.request(w_header(0x82, 6, 1), 6),
            Dev::Dongle(_) => Ok(MODEL_F75.to_vec()),
        }
    }

    fn read_config(&mut self) -> R<Vec<u8>> {
        match self {
            Dev::Wired(w) => w.request(w_header(0x84, CFG_LEN, 0), CFG_LEN),
            Dev::Dongle(d) => Ok(d.block("config")?.into_iter().take(CFG_LEN).collect()),
        }
    }

    fn read_matrix(&mut self) -> R<Vec<u8>> {
        match self {
            Dev::Wired(w) => w.request(w_header(0x86, MATRIX_LEN, 0), MATRIX_LEN),
            Dev::Dongle(d) => d.block("colors"),
        }
    }

    fn write(&mut self, name: &str, data: &[u8]) -> R<()> {
        match self {
            Dev::Wired(w) => match name {
                "config" => w.set(&w_packet(&w_header(0x04, CFG_LEN, 0), data)),
                "matrix" => w.set(&w_packet(&w_header(0x06, MATRIX_LEN, 0), data)),
                _ => err("unsupported", "палитры по проводу не разобраны"),
            },
            Dev::Dongle(d) => d.put(name, data),
        }
    }

    fn battery(&mut self) -> Option<u8> {
        match self {
            Dev::Wired(_) => None,
            Dev::Dongle(d) => d.battery(),
        }
    }

    fn live(&mut self, frame: &[Rgb]) -> R<()> {
        match self {
            Dev::Wired(w) => w.live(frame),
            Dev::Dongle(d) => d.live(frame),
        }
    }
}

fn check_cfg(cfg: &[u8]) -> R<()> {
    if cfg.len() < CFG_LEN || cfg[126..128] != SIG {
        return err("protocol", "конфиг без подписи 5a a5 — запись запрещена");
    }
    if cfg[OFF_CUSTOM] > 1 {
        return err("protocol", "неизвестный режим в конфиге — запись запрещена");
    }
    Ok(())
}

fn active_id(cfg: &[u8]) -> u8 {
    if cfg[OFF_CUSTOM] == 1 {
        21
    } else {
        cfg[OFF_EFFECT]
    }
}

fn decode(cfg: &[u8], out: &mut Map<String, Value>) {
    let eid = active_id(cfg);
    let meta = effect(eid);
    let name = meta.map_or_else(|| format!("mode{eid}"), |m| m.name.to_string());
    out.insert("effect".into(), json!({"id": eid, "name": name}));
    let (mut br, mut sp, mut pal) = (Value::Null, Value::Null, Value::Null);
    if let (Some(s), true) = (slot_of(eid), eid != 0) {
        let o = OFF_SLOTS + 2 * s;
        if cfg[o] <= 9 {
            br = json!(cfg[o]);
        }
        if meta.is_some_and(|m| m.speed) && cfg[o + 1] >> 4 <= 4 {
            sp = json!(cfg[o + 1] >> 4);
        }
        if meta.is_some_and(|m| m.palette) {
            let p = (cfg[o + 1] & 0x0F) as usize;
            if p <= 7 {
                pal = json!({"index": p, "name": PALETTE[p]});
            }
        }
    }
    out.insert("brightness".into(), br);
    out.insert("speed".into(), sp);
    out.insert("palette".into(), pal);
    let ind = cfg[OFF_INDICATOR] as usize;
    out.insert("indicator".into(), INDICATOR.get(ind).map_or(Value::Null, |s| json!(s)));
    let hw = cfg[OFF_SLEEP];
    out.insert("sleep".into(), SLEEP.iter().find(|s| s.1 == hw).map_or(Value::Null, |s| json!(s.0)));
    out.insert("stored_effect".into(), json!(cfg[OFF_EFFECT]));
}

fn template_cfg() -> Vec<u8> {
    let mut c = vec![0u8; CFG_LEN];
    c[OFF_EFFECT] = 1;
    for s in 0..20 {
        c[OFF_SLOTS + 2 * s] = 9;
        c[OFF_SLOTS + 2 * s + 1] = 0x20;
    }
    c[126..128].copy_from_slice(&SIG);
    c
}

fn matrix_get(m: &[u8], n: usize) -> Vec<Rgb> {
    (0..n).map(|i| [*m.get(i).unwrap_or(&0), *m.get(n + i).unwrap_or(&0), *m.get(2 * n + i).unwrap_or(&0)]).collect()
}

fn matrix_set(m: &[u8], colors: &[Rgb], n: usize) -> Vec<u8> {
    let mut m = m.to_vec();
    if m.len() < 3 * n {
        m.resize(3 * n, 0);
    }
    for (i, c) in colors.iter().take(n).enumerate() {
        m[i] = c[0];
        m[n + i] = c[1];
        m[2 * n + i] = c[2];
    }
    m
}

fn dominant(colors: &[Rgb]) -> Value {
    let mut count: Vec<(Rgb, usize)> = vec![];
    for (i, c) in colors.iter().enumerate() {
        if !LAYOUT.iter().any(|k| k.5 == i) {
            continue;
        }
        match count.iter_mut().find(|e| e.0 == *c) {
            Some(e) => e.1 += 1,
            None => count.push((*c, 1)),
        }
    }
    let mut best: Option<&(Rgb, usize)> = None;
    for e in &count {
        if best.is_none_or(|b| e.1 > b.1) {
            best = Some(e);
        }
    }
    best.map_or(Value::Null, |b| json!(hexc(&b.0)))
}

fn state_dir() -> PathBuf {
    let base = std::env::var_os("XDG_STATE_HOME")
        .filter(|v| !v.is_empty())
        .map_or_else(|| crate::util::home().join(".local/state"), PathBuf::from);
    let d = base.join("aulactl");
    let _ = fs::create_dir_all(&d);
    d
}

fn now_secs() -> i64 {
    std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map_or(0, |d| d.as_secs() as i64)
}

fn snap_json(kind: &str, cfg: &[u8], matrix: &[u8]) -> String {
    json!({"transport": kind, "time": now_secs(), "config": hex_encode(cfg), "matrix": hex_encode(matrix)}).to_string()
}

fn write_file(p: &Path, s: &str) -> R<()> {
    fs::write(p, s).or_else(|e| err("io", format!("{}: {e}", p.display())))
}

fn backup(kind: &str, cfg: &[u8], matrix: &[u8]) -> R<()> {
    let d = state_dir();
    let data = snap_json(kind, cfg, matrix);
    let first = d.join(format!("original-{kind}.json"));
    if !first.exists() {
        write_file(&first, &data)?;
    }
    write_file(&d.join(format!("last-{kind}.json")), &data)
}

fn remember_on(eid: u8) {
    let _ = fs::write(state_dir().join("last-effect"), eid.to_string());
}

fn recall_on() -> u8 {
    read_str(&state_dir().join("last-effect"))
        .and_then(|s| s.parse::<u8>().ok())
        .filter(|v| effect(*v).is_some() && *v != 0)
        .unwrap_or(1)
}

#[derive(Default)]
struct Args {
    cmd: String,
    pos: Vec<String>,
    json: bool,
    dry_run: bool,
    from_file: Option<String>,
    transport: String,
    force: bool,
    quick: bool,
    keys: bool,
    brightness: Option<i64>,
    speed: Option<i64>,
    palette: Option<String>,
    interval: f64,
}

struct Session<'a> {
    a: &'a Args,
    dev: Option<Dev>,
    kind: &'static str,
    cfg: Vec<u8>,
    matrix: Vec<u8>,
    log: Vec<String>,
}

fn read_snap(path: &str) -> R<Value> {
    let s = fs::read_to_string(path).or_else(|e| err("io", format!("{path}: {e}")))?;
    serde_json::from_str(&s).or_else(|e| err("usage", format!("JSON: {e}")))
}

fn snap_bytes(v: &Value, k: &str) -> R<Vec<u8>> {
    hex_decode(v.get(k).and_then(Value::as_str).unwrap_or(""))
}

impl<'a> Session<'a> {
    fn new(a: &'a Args) -> R<Session<'a>> {
        if a.dry_run {
            let (cfg, matrix) = match &a.from_file {
                Some(f) => {
                    let snap = read_snap(f)?;
                    (snap_bytes(&snap, "config")?, snap_bytes(&snap, "matrix")?)
                }
                None => (template_cfg(), vec![0u8; MATRIX_LEN]),
            };
            return Ok(Session { a, dev: None, kind: "dry-run", cfg, matrix, log: vec![] });
        }
        let cands = scan();
        let Some(c) = pick(&cands, &a.transport) else {
            if cands.iter().any(|x| x.kind == "bt") {
                return err(
                    "unsupported",
                    "клавиатура на Bluetooth — подсветкой по BT управлять нельзя, подключи проводом или донглом",
                );
            }
            return err("not_found", "AULA F75 не найдена — подключи проводом (USB-C) или донглом");
        };
        let mut dev = Dev::open(&c)?;
        let kind = dev.kind();
        if kind == "wired" {
            let model = dev.model()?;
            if model != MODEL_F75 && !a.force {
                return err("unsupported", format!("ответ модели не F75 ({}) — запись не отправлена", hexdump(&model)));
            }
        }
        let cfg = dev.read_config()?;
        let matrix = dev.read_matrix()?;
        Ok(Session { a, dev: Some(dev), kind, cfg, matrix, log: vec![] })
    }

    fn n(&self) -> usize {
        if self.kind != "dongle" {
            LEDS
        } else {
            self.matrix.len() / 3
        }
    }

    fn commit(&mut self, cfg: Option<Vec<u8>>, matrix: Option<Vec<u8>>, palette: Option<Vec<u8>>) -> R<bool> {
        let cfg = cfg.unwrap_or_else(|| self.cfg.clone());
        check_cfg(&cfg)?;
        let mut writes: Vec<(&str, Vec<u8>)> = vec![];
        if let Some(m) = &matrix {
            if *m != self.matrix {
                writes.push(("matrix", m.clone()));
            }
        }
        if let Some(p) = palette {
            writes.push(("palette", p));
        }
        if cfg != self.cfg || !writes.is_empty() {
            writes.push(("config", cfg.clone()));
        }
        if writes.is_empty() {
            self.log.push("без изменений — ничего не отправлено".into());
            return Ok(false);
        }
        let Some(dev) = self.dev.as_mut() else {
            for (name, data) in &writes {
                let d = self.describe(name, data)?;
                self.log.push(d);
            }
            return Ok(true);
        };
        backup(self.kind, &self.cfg, &self.matrix)?;
        for (name, data) in &writes {
            dev.write(name, data)?;
        }
        let back = dev.read_config()?;
        if back.len() < 126 || back[..126] != cfg[..126] {
            return err("protocol", "клавиатура вернула не то, что записано (конфиг)");
        }
        if writes.iter().any(|w| w.0 == "matrix") {
            let bm = dev.read_matrix()?;
            let m = matrix.as_deref().unwrap_or(&[]);
            let k = LEDS * 3;
            if bm[..bm.len().min(k)] != m[..m.len().min(k)] {
                return err("protocol", "клавиатура вернула не то, что записано (матрица)");
            }
        }
        self.cfg = back;
        if let Some(m) = matrix {
            self.matrix = m;
        }
        Ok(true)
    }

    fn describe(&self, name: &str, data: &[u8]) -> R<String> {
        if self.kind == "dongle" || (self.a.dry_run && self.a.transport == "dongle") {
            let (_, put, sub) = d_block(name);
            let total = data.len().div_ceil(D_CHUNK).max(1);
            let mut lines = vec![format!("[донгл] {name}: {total} пакетов по 20 байт")];
            for i in 0..total {
                let ch = &data[(i * D_CHUNK).min(data.len())..((i + 1) * D_CHUNK).min(data.len())];
                lines.push(format!("  {}", hexdump(&d_packet(put, total, i, (sub << 4) | ch.len() as u8, ch))));
            }
            return Ok(lines.join("\n"));
        }
        if name == "palette" {
            return err("unsupported", "палитры по проводу не разобраны");
        }
        let cfgw = name == "config";
        let p = w_packet(&w_header(if cfgw { 0x04 } else { 0x06 }, if cfgw { CFG_LEN } else { MATRIX_LEN }, 0), data);
        safe(&p)?;
        let old = if cfgw { &self.cfg } else { &self.matrix };
        let diff: Vec<String> = (0..old.len().min(data.len()))
            .filter(|i| old[*i] != data[*i])
            .map(|i| format!("{i}:{:02x}→{:02x}", old[i], data[i]))
            .collect();
        let body = data.len() + 8;
        let more = if diff.len() > 12 { format!(" … ещё {}", diff.len() - 12) } else { String::new() };
        let shown = if diff.is_empty() { "—".to_string() } else { diff[..diff.len().min(12)].join(", ") };
        Ok(format!(
            "[провод] {name}: report 6, {REPORT_LEN} байт\n  {}\n  изменено ({}): {shown}{more}",
            hexdump(&p[..body]),
            diff.len()
        ))
    }
}

fn effect_id(ident: &str, force: bool) -> R<u8> {
    let s = ident.trim().to_lowercase().replace(['-', ' '], "_");
    let eid = if is_digits(&s) {
        s.parse::<u8>().ok()
    } else {
        ALIASES.iter().find(|a| a.0 == s).map(|a| a.1).or_else(|| EFFECTS.iter().find(|e| e.name == s).map(|e| e.id))
    };
    let Some(e) = eid.and_then(effect) else {
        return err("usage", format!("неизвестный эффект '{ident}' — см. aulactl effects"));
    };
    if !e.works && !force {
        return err("unsupported", format!("{} на F75 не рисуется (нужен --force)", e.name));
    }
    Ok(e.id)
}

fn palette_index(v: &str) -> R<u8> {
    let s = v.trim().to_lowercase();
    if is_digits(&s) {
        if let Ok(n) = s.parse::<u8>() {
            if n <= 7 {
                return Ok(n);
            }
        }
    }
    if let Some(i) = PALETTE.iter().position(|p| *p == s) {
        return Ok(i as u8);
    }
    if s == "multi" || s == "rainbow" {
        return Ok(7);
    }
    err("usage", format!("палитра: 0-7 или {}", PALETTE.join(", ")))
}

fn rng(name: &str, v: Option<i64>, lo: i64, hi: i64) -> R<Option<u8>> {
    match v {
        None => Ok(None),
        Some(x) if (lo..=hi).contains(&x) => Ok(Some(x as u8)),
        Some(_) => err("usage", format!("{name}: {lo}-{hi}")),
    }
}

fn apply_params(cfg: &mut [u8], eid: u8, brightness: Option<u8>, speed: Option<u8>, palette: Option<u8>) -> R<()> {
    let Some(s) = slot_of(eid) else { return err("usage", "нет слота эффекта") };
    let Some(meta) = effect(eid) else { return err("usage", "нет эффекта") };
    let o = OFF_SLOTS + 2 * s;
    if let Some(b) = brightness {
        if eid != 0 {
            cfg[o] = b;
        }
    }
    if let Some(sp) = speed {
        if !meta.speed {
            return err("unsupported", format!("у {} нет скорости", meta.name));
        }
        cfg[o + 1] = (sp << 4) | (cfg[o + 1] & 0x0F);
    }
    if let Some(p) = palette {
        if !meta.palette {
            return err("unsupported", format!("у {} нет палитры", meta.name));
        }
        cfg[o + 1] = (cfg[o + 1] & 0xF0) | p;
    }
    Ok(())
}

fn select_effect(cfg: &mut [u8], eid: u8) {
    if eid == 21 {
        cfg[OFF_CUSTOM] = 1;
        cfg[OFF_EFFECT] = 21;
    } else {
        cfg[OFF_CUSTOM] = 0;
        cfg[OFF_EFFECT] = eid;
    }
}

fn scaled(c: Rgb, level: Option<u8>) -> Rgb {
    match level {
        Some(l) if l < 9 => {
            let k = (l as f64 / 9.0).powf(2.2);
            c.map(|v| (v as f64 * k).round_ties_even() as u8)
        }
        _ => c,
    }
}

fn status_payload(sess: &mut Session, cands: Option<&[Cand]>, with_matrix: bool) -> Map<String, Value> {
    let mut out = Map::new();
    out.insert("ok".into(), json!(true));
    out.insert("found".into(), json!(true));
    out.insert("transport".into(), json!(sess.kind));
    out.insert("connection".into(), json!(cands.map_or(sess.kind, connection)));
    out.insert("path".into(), sess.dev.as_ref().map_or(Value::Null, |d| json!(d.path())));
    out.insert("access".into(), json!(true));
    decode(&sess.cfg, &mut out);
    let colors = matrix_get(&sess.matrix, sess.n());
    out.insert("color".into(), dominant(&colors));
    out.insert("battery".into(), sess.dev.as_mut().and_then(Dev::battery).map_or(Value::Null, |b| json!(b)));
    out.insert(
        "backup".into(),
        json!(state_dir().join(format!("original-{}.json", sess.kind)).to_string_lossy()),
    );
    if with_matrix {
        let mut keys = Map::new();
        for k in LAYOUT.iter().filter(|k| k.5 < colors.len()) {
            keys.insert(k.0.into(), json!(hexc(&colors[k.5])));
        }
        out.insert("keys".into(), Value::Object(keys));
    }
    out
}

fn obj(v: Value) -> Map<String, Value> {
    match v {
        Value::Object(m) => m,
        _ => Map::new(),
    }
}

fn cmd_status(a: &Args) -> R<Map<String, Value>> {
    if a.quick {
        let cands = scan();
        let c = pick(&cands, "auto");
        return Ok(obj(json!({"ok": true, "found": !cands.is_empty(), "connection": connection(&cands),
            "path": c.as_ref().map(|c| c.path.clone()),
            "access": c.as_ref().is_some_and(|c| c.access), "controllable": c.is_some()})));
    }
    let cands = if a.dry_run { None } else { Some(scan()) };
    if let Some(cs) = &cands {
        if cs.is_empty() {
            return Ok(obj(json!({"ok": true, "found": false, "connection": "none"})));
        }
        match pick(cs, &a.transport) {
            Some(c) if !c.access => {
                return Ok(obj(json!({"ok": true, "found": true, "connection": connection(cs), "path": c.path,
                    "access": false, "controllable": true, "error": "permission"})))
            }
            None => {
                return Ok(obj(json!({"ok": true, "found": true, "connection": connection(cs),
                    "access": false, "controllable": false})))
            }
            _ => {}
        }
    }
    let _l = Lock::get(3.0)?;
    let mut sess = Session::new(a)?;
    let mut out = status_payload(&mut sess, cands.as_deref(), a.keys);
    out.insert("controllable".into(), json!(true));
    Ok(out)
}

fn run_write(a: &Args, f: impl FnOnce(&mut Session) -> R<bool>) -> R<Map<String, Value>> {
    let _l = Lock::get(3.0)?;
    let mut sess = Session::new(a)?;
    check_cfg(&sess.cfg)?;
    let changed = f(&mut sess)?;
    let mut out = Map::new();
    out.insert("ok".into(), json!(true));
    out.insert("changed".into(), json!(changed));
    out.insert("transport".into(), json!(sess.kind));
    if a.dry_run {
        out.insert("dry_run".into(), json!(sess.log));
    } else {
        decode(&sess.cfg, &mut out);
        out.insert("color".into(), dominant(&matrix_get(&sess.matrix, sess.n())));
    }
    Ok(out)
}

fn need_pos(a: &Args, i: usize, what: &str) -> R<String> {
    a.pos.get(i).cloned().map_or_else(|| err("usage", format!("{}: нужен аргумент {what}", a.cmd)), Ok)
}

fn need_int(a: &Args, i: usize, what: &str) -> R<i64> {
    let s = need_pos(a, i, what)?;
    s.trim().parse::<i64>().or_else(|_| err("usage", format!("{what}: нужно целое, а не '{s}'")))
}

fn cmd_mode(a: &Args) -> R<Map<String, Value>> {
    let eid = effect_id(&need_pos(a, 0, "effect")?, a.force)?;
    let b = rng("яркость", a.brightness, 0, 9)?;
    let sp = rng("скорость", a.speed, 0, 4)?;
    let pal = a.palette.as_deref().map(palette_index).transpose()?;
    run_write(a, |s| {
        let mut cfg = s.cfg.clone();
        select_effect(&mut cfg, eid);
        if eid != 0 {
            if !s.a.dry_run {
                remember_on(eid);
            }
            apply_params(&mut cfg, eid, b, sp, pal)?;
        }
        s.commit(Some(cfg), None, None)
    })
}

fn cmd_param(a: &Args, what: &str) -> R<Map<String, Value>> {
    let raw = need_pos(a, 0, "value")?;
    let val = if what == "palette" { None } else { Some(need_int(a, 0, "value")?) };
    run_write(a, |s| {
        let mut cfg = s.cfg.clone();
        let eid = active_id(&cfg);
        if eid == 0 {
            return err("unsupported", "подсветка выключена — сначала aulactl on");
        }
        match what {
            "brightness" => apply_params(&mut cfg, eid, rng("яркость", val, 0, 9)?, None, None)?,
            "speed" => apply_params(&mut cfg, eid, None, rng("скорость", val, 0, 4)?, None)?,
            _ => apply_params(&mut cfg, eid, None, None, Some(palette_index(&raw)?))?,
        }
        s.commit(Some(cfg), None, None)
    })
}

fn cmd_off(a: &Args) -> R<Map<String, Value>> {
    run_write(a, |s| {
        let mut cfg = s.cfg.clone();
        let cur = active_id(&cfg);
        if cur != 0 && !s.a.dry_run {
            remember_on(cur);
        }
        select_effect(&mut cfg, 0);
        s.commit(Some(cfg), None, None)
    })
}

fn cmd_on(a: &Args) -> R<Map<String, Value>> {
    run_write(a, |s| {
        let mut cfg = s.cfg.clone();
        if active_id(&cfg) == 0 {
            select_effect(&mut cfg, recall_on());
        }
        s.commit(Some(cfg), None, None)
    })
}

fn build_colors(base: Rgb, keys: &[(String, String)], b: Option<u8>, n: usize) -> R<Vec<Rgb>> {
    let mut colors = vec![scaled(base, b); n];
    for (name, col) in keys {
        let led = resolve_key(name)?;
        if led < n {
            colors[led] = scaled(parse_color(col)?, b);
        }
    }
    Ok(colors)
}

fn write_custom(s: &mut Session, colors: &[Rgb]) -> R<bool> {
    let m = matrix_set(&s.matrix, colors, s.n());
    let mut cfg = s.cfg.clone();
    select_effect(&mut cfg, 21);
    apply_params(&mut cfg, 21, Some(9), None, None)?;
    s.commit(Some(cfg), Some(m), None)
}

fn cmd_color(a: &Args) -> R<Map<String, Value>> {
    let rgb = parse_color(&need_pos(a, 0, "color")?)?;
    let b = rng("яркость", a.brightness, 0, 9)?;
    run_write(a, |s| {
        let colors = build_colors(rgb, &[], b, s.n())?;
        write_custom(s, &colors)
    })
}

fn val_str(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        other => other.to_string(),
    }
}

fn cmd_keys(a: &Args) -> R<Map<String, Value>> {
    let file = need_pos(a, 0, "file")?;
    let mut src = String::new();
    if file == "-" {
        std::io::stdin().read_to_string(&mut src).or_else(|e| err("io", format!("stdin: {e}")))?;
    } else {
        src = fs::read_to_string(&file).or_else(|e| err("io", format!("{file}: {e}")))?;
    }
    let spec: Value = serde_json::from_str(&src).or_else(|e| err("usage", format!("JSON: {e}")))?;
    let base = parse_color(&spec.get("base").map_or("#000000".into(), val_str))?;
    let keys: Vec<(String, String)> = spec
        .get("keys")
        .and_then(Value::as_object)
        .map(|m| m.iter().map(|(k, v)| (k.clone(), val_str(v))).collect())
        .unwrap_or_default();
    let braw = match spec.get("brightness") {
        Some(Value::Null) => None,
        Some(v) => Some(v.as_i64().map_or_else(|| err("usage", "яркость: 0-9"), Ok)?),
        None => a.brightness,
    };
    let b = rng("яркость", braw, 0, 9)?;
    run_write(a, |s| {
        let colors = build_colors(base, &keys, b, s.n())?;
        write_custom(s, &colors)
    })
}

fn cmd_palette_color(a: &Args) -> R<Map<String, Value>> {
    let eid = effect_id(&need_pos(a, 0, "effect")?, false)?;
    let j = palette_index(&need_pos(a, 1, "index")?)?;
    let rgb = parse_color(&need_pos(a, 2, "color")?)?;
    if j > 6 {
        return err("usage", "менять можно цвета 0-6");
    }
    run_write(a, |s| {
        if s.kind == "wired" || (s.a.dry_run && s.a.transport != "dongle") {
            return err(
                "unsupported",
                "свои цвета для родных эффектов есть только через донгл; по проводу — 7 цветов палитры или живой режим",
            );
        }
        let mut tab = match s.dev.as_mut() {
            Some(Dev::Dongle(d)) => d.block("palette")?,
            _ => vec![0u8; 21 * 20],
        };
        let o = (slot_of(eid).unwrap_or(0) + 1) * 21 + j as usize * 3;
        if tab.len() < o + 3 {
            return err("protocol", "короткая таблица палитр");
        }
        tab[o..o + 3].copy_from_slice(&rgb);
        s.commit(None, None, Some(tab))
    })
}

fn cmd_indicator(a: &Args) -> R<Map<String, Value>> {
    let m = need_pos(a, 0, "mode")?;
    let Some(i) = INDICATOR.iter().position(|x| *x == m) else {
        return err("usage", format!("индикатор: {}", INDICATOR.join(", ")));
    };
    run_write(a, |s| {
        let mut cfg = s.cfg.clone();
        cfg[OFF_INDICATOR] = i as u8;
        s.commit(Some(cfg), None, None)
    })
}

fn cmd_sleep(a: &Args) -> R<Map<String, Value>> {
    let secs = need_int(a, 0, "seconds")?;
    let Some(hw) = SLEEP.iter().find(|s| s.0 as i64 == secs).map(|s| s.1) else {
        let all: Vec<String> = SLEEP.iter().map(|s| s.0.to_string()).collect();
        return err("usage", format!("сон, секунд: {}", all.join(", ")));
    };
    run_write(a, |s| {
        let mut cfg = s.cfg.clone();
        cfg[OFF_SLEEP] = hw;
        s.commit(Some(cfg), None, None)
    })
}

fn cmd_restore(a: &Args) -> R<Map<String, Value>> {
    let snap = read_snap(&need_pos(a, 0, "file")?)?;
    let cfg = snap_bytes(&snap, "config")?;
    let m = snap_bytes(&snap, "matrix")?;
    let tr = snap.get("transport").and_then(Value::as_str).map(str::to_string);
    run_write(a, |s| {
        if tr.as_deref().is_some_and(|t| t != s.kind) && !s.a.dry_run {
            return err("usage", "копия снята через другое подключение");
        }
        s.commit(Some(cfg), Some(m), None)
    })
}

fn strftime(fmt: &str) -> String {
    crate::util::local_time(fmt)
}

fn cmd_snapshot(a: &Args) -> R<Map<String, Value>> {
    let _l = Lock::get(3.0)?;
    let sess = Session::new(a)?;
    let path = a
        .pos
        .first()
        .map(PathBuf::from)
        .unwrap_or_else(|| state_dir().join(strftime("snapshot-%Y%m%d-%H%M%S.json")));
    write_file(&path, &snap_json(sess.kind, &sess.cfg, &sess.matrix))?;
    Ok(obj(json!({"ok": true, "file": path.to_string_lossy()})))
}

fn cmd_effects() -> Map<String, Value> {
    let list: Vec<Value> = EFFECTS
        .iter()
        .map(|e| json!({"id": e.id, "name": e.name, "speed": e.speed, "palette": e.palette, "works": e.works}))
        .collect();
    let sleep: Vec<u32> = SLEEP.iter().map(|s| s.0).collect();
    obj(json!({"ok": true, "effects": list, "palette": PALETTE, "indicator": INDICATOR, "sleep": sleep}))
}

fn cmd_layout() -> Map<String, Value> {
    let keys: Vec<Value> = LAYOUT
        .iter()
        .map(|k| {
            let label = LABELS
                .iter()
                .find(|l| l.0 == k.0)
                .map_or_else(|| k.0.to_uppercase(), |l| l.1.to_string());
            json!({"name": k.0, "label": label, "x": k.1, "y": k.2, "w": k.3, "h": k.4, "led": k.5})
        })
        .collect();
    obj(json!({"ok": true, "width": 640, "height": 270, "knob": KNOB, "keys": keys}))
}

fn emit(v: &Value) {
    crate::util::emit(v);
}

fn die_with_parent() -> libc::pid_t {
    unsafe {
        libc::prctl(libc::PR_SET_PDEATHSIG, libc::SIGTERM);
        libc::getppid()
    }
}

fn parse_frame(line: &str) -> Option<Vec<Rgb>> {
    if line.starts_with('#') {
        return parse_color(line).ok().map(|c| vec![c; LEDS]);
    }
    let h = line.strip_prefix("F ")?.trim();
    if !h.is_ascii() {
        return None;
    }
    let lim = h.len().min(LEDS * 6);
    let mut frame = vec![];
    let mut i = 0;
    while i < lim {
        let mut c = [0u8; 3];
        for (k, j) in [0usize, 2, 4].iter().enumerate() {
            let s = h.get(i + j..(i + j + 2).min(h.len()))?;
            c[k] = u8::from_str_radix(s, 16).ok()?;
        }
        frame.push(c);
        i += 6;
    }
    frame.resize(LEDS, [0, 0, 0]);
    Some(frame)
}

fn cmd_live(a: &Args) {
    die_with_parent();
    let mut dev: Option<Dev> = None;
    let mut frame: Option<Vec<Rgb>> = None;
    let mut last = 0.0f64;
    let keep = 0.4;
    let mut buf: Vec<u8> = vec![];
    unsafe {
        let fl = libc::fcntl(0, libc::F_GETFL);
        libc::fcntl(0, libc::F_SETFL, fl | libc::O_NONBLOCK);
    }

    let send = |dev: &mut Option<Dev>, frame: &Option<Vec<Rgb>>, last: &mut f64| {
        let Some(fr) = frame else {
            *last = monotonic();
            return;
        };
        if a.dry_run {
            *last = monotonic();
            return;
        }
        let res: Result<(), LockErr> = (|| {
            let _l = Lock::acquire(0.2, true)?;
            if dev.is_none() {
                if let Some(c) = pick(&scan(), &a.transport) {
                    if let Ok(d) = Dev::open(&c) {
                        if a.json {
                            emit(&json!({"event": "live", "transport": d.kind()}));
                        }
                        *dev = Some(d);
                    }
                }
            }
            if let Some(d) = dev.as_mut() {
                d.live(fr)?;
            }
            Ok(())
        })();
        if let Err(LockErr::Fail(e)) = res {
            if a.json {
                emit(&json!({"event": "error", "error": e.code, "message": e.message}));
            }
            *dev = None;
        }
        *last = monotonic();
    };

    loop {
        let timeout_ms = match frame {
            Some(_) => ((keep - (monotonic() - last)).max(0.0) * 1000.0).ceil() as i32,
            None => -1,
        };
        let mut p = libc::pollfd { fd: 0, events: libc::POLLIN, revents: 0 };
        let r = unsafe { libc::poll(&mut p, 1, timeout_ms) };
        if r < 0 {
            if errno() == libc::EINTR {
                continue;
            }
            break;
        }
        if r > 0 {
            let mut chunk = [0u8; 65536];
            let n = unsafe { libc::read(0, chunk.as_mut_ptr().cast(), chunk.len()) };
            if n == 0 {
                break;
            }
            if n < 0 {
                if errno() == libc::EAGAIN || errno() == libc::EINTR {
                    continue;
                }
                break;
            }
            buf.extend_from_slice(&chunk[..n as usize]);
            let Some(cut) = buf.iter().rposition(|b| *b == b'\n') else { continue };
            let lines: Vec<u8> = buf.drain(..=cut).collect();
            let mut newest: Option<String> = None;
            for raw in lines.split(|b| *b == b'\n') {
                let line = String::from_utf8_lossy(raw).trim().to_string();
                if line.is_empty() {
                    continue;
                }
                if line == "stop" {
                    frame = None;
                    newest = None;
                    continue;
                }
                newest = Some(line);
            }
            if let Some(nl) = newest {
                let framed = nl.starts_with('#') || nl.starts_with("F ");
                match parse_frame(&nl) {
                    Some(f) => frame = Some(f),
                    None if framed => continue,
                    None => {}
                }
                if a.dry_run && framed {
                    if let Some(f) = &frame {
                        println!("[live] {} {} …", hexdump(&w_header(0x08, LIVE_LEN, 0)), hexdump(&f[0]));
                    }
                }
                send(&mut dev, &frame, &mut last);
            }
        } else if frame.is_some() {
            send(&mut dev, &frame, &mut last);
        }
    }
}

fn cmd_watch(a: &Args) {
    let parent = die_with_parent();
    let mut prev: Option<(&'static str, Option<String>, bool)> = None;
    let mut bat_at = 0.0f64;
    let mut battery: Option<u8> = None;
    loop {
        let cands = scan();
        let c = pick(&cands, "auto");
        let key = (connection(&cands), c.as_ref().map(|c| c.path.clone()), c.as_ref().is_some_and(|c| c.access));
        let now = monotonic();
        if prev.as_ref() != Some(&key) {
            prev = Some(key.clone());
            bat_at = 0.0;
            let mut ev = obj(json!({"event": "device", "connection": key.0, "path": key.1,
                "access": key.2, "controllable": c.is_some(), "found": !cands.is_empty()}));
            if key.2 {
                let r: R<Map<String, Value>> = (|| {
                    let _l = Lock::get(3.0)?;
                    let da = Args { transport: "auto".into(), keys: true, ..Default::default() };
                    let mut sess = Session::new(&da)?;
                    Ok(status_payload(&mut sess, Some(&cands), true))
                })();
                match r {
                    Ok(p) => {
                        battery = p.get("battery").and_then(Value::as_u64).map(|b| b as u8);
                        ev.extend(p);
                        bat_at = now;
                    }
                    Err(e) => {
                        ev.insert("error".into(), json!(e.code));
                        ev.insert("message".into(), json!(e.message));
                    }
                }
            }
            emit(&Value::Object(ev));
        } else if let Some(c) = c.as_ref().filter(|c| c.kind == "dongle" && c.access && now - bat_at > 120.0) {
            bat_at = now;
            let r: R<Option<u8>> = (|| {
                let _l = Lock::get(0.5)?;
                let mut d = Dongle::new(&c.path)?;
                Ok(d.battery())
            })();
            if let Ok(b) = r {
                if b != battery {
                    battery = b;
                    emit(&json!({"event": "battery", "battery": b}));
                }
            }
        }
        if crate::util::parent_gone(parent) {
            return;
        }
        sleep_s(a.interval);
    }
}

fn cmd_selftest() -> Map<String, Value> {
    let mut checks: Vec<Value> = vec![];
    let mut ok = |name: &str, cond: bool| checks.push(json!({"check": name, "ok": cond}));

    ok("чтение конфига = 06 84 00 00 01 00 80 00 (Vantesh, br0k3nb, lukatasev)",
       w_header(0x84, CFG_LEN, 0) == [6, 0x84, 0, 0, 1, 0, 0x80, 0]);
    ok("чтение матрицы = 06 86 00 00 01 00 80 01 (Vantesh)",
       w_header(0x86, MATRIX_LEN, 0) == [6, 0x86, 0, 0, 1, 0, 0x80, 1]);
    ok("модель = 06 82 01 00 01 00 06 00 (Vantesh)", w_header(0x82, 6, 1) == [6, 0x82, 1, 0, 1, 0, 6, 0]);
    ok("живой кадр = 06 08 00 00 01 00 7a 01 (OpenRGB, kveld9, lukatasev)",
       w_header(0x08, LIVE_LEN, 0) == [6, 8, 0, 0, 1, 0, 0x7A, 1]);
    ok("запись конфига = 06 04 00 00 01 00 80 00", w_header(0x04, CFG_LEN, 0) == [6, 4, 0, 0, 1, 0, 0x80, 0]);
    ok("запись матрицы = 06 06 00 00 01 00 80 01", w_header(0x06, MATRIX_LEN, 0) == [6, 6, 0, 0, 1, 0, 0x80, 1]);
    let mut c = template_cfg();
    select_effect(&mut c, 1);
    let _ = apply_params(&mut c, 1, Some(4), None, None);
    let p = w_packet(&w_header(0x04, CFG_LEN, 0), &c);
    ok("static: report[17]=0 [18]=1 [66]=4 (lukatasev selftest)", p[17] == 0 && p[18] == 1 && p[66] == 4);
    let mut c = template_cfg();
    select_effect(&mut c, 21);
    let _ = apply_params(&mut c, 21, Some(7), None, None);
    ok("self-defined: cfg[9]=1 cfg[10]=21 яркость @0x5e (Vantesh)", c[9] == 1 && c[10] == 21 && c[0x5E] == 7);
    ok("слоты: fixed_on@58, storm@92 (Vantesh)",
       slot_of(1).is_some_and(|s| OFF_SLOTS + 2 * s == 58) && slot_of(18).is_some_and(|s| OFF_SLOTS + 2 * s == 92));
    let mut c = template_cfg();
    select_effect(&mut c, 2);
    c[OFF_SLOTS + 3] = 0x35;
    let _ = apply_params(&mut c, 2, None, Some(1), None);
    ok("скорость не трогает палитру", c[OFF_SLOTS + 3] == 0x15);
    let _ = apply_params(&mut c, 2, None, None, Some(6));
    ok("палитра не трогает скорость", c[OFF_SLOTS + 3] == 0x16);
    let mut fr = vec![[0u8; 3]; LEDS];
    fr[0] = [1, 2, 3];
    let m = matrix_set(&vec![0u8; MATRIX_LEN], &fr, LEDS);
    ok("матрица планарная", m[0] == 1 && m[126] == 2 && m[252] == 3);
    fr[10] = [4, 5, 6];
    let mut payload = vec![0u8; LIVE_LEN];
    for (i, rgb) in fr.iter().enumerate() {
        payload[i * 3..i * 3 + 3].copy_from_slice(rgb);
    }
    let lp = w_packet(&w_header(0x08, LIVE_LEN, 0), &payload);
    ok("живой кадр: led0 @8, led10 @38", lp[8..11] == [1, 2, 3] && lp[38..41] == [4, 5, 6]);
    let dp = d_packet(0x44, 1, 0, 0, &[]);
    ok("донгл: 13 44 01 00 00 … сумма", dp[..5] == [0x13, 0x44, 1, 0, 0] && dp[19] == 0x13u8.wrapping_add(0x44).wrapping_add(1));
    let mut leds: Vec<usize> = LAYOUT.iter().map(|k| k.5).collect();
    leds.sort();
    leds.dedup();
    ok("раскладка: 80 клавиш, led уникальны", LAYOUT.len() == 80 && leds.len() == 80);
    let l = |n: &str| led_by_name(n).unwrap_or(999);
    ok("led: esc0 f1=12 del85 pgup86 pgdn87 end88 right89 fn53 space35",
       l("esc") == 0 && l("f1") == 12 && l("delete") == 85 && l("pgup") == 86 && l("pgdn") == 87
       && l("end") == 88 && l("right") == 89 && l("fn") == 53 && l("space") == 35);
    let mut bad = vec![0u8; REPORT_LEN];
    bad[0] = 5;
    ok("report 5 запрещён", safe(&bad).is_err());
    ok("без подписи 5a a5 запись запрещена", check_cfg(&[0u8; CFG_LEN]).is_err());
    ok("ioctl: HIDIOCSFEATURE(520) = 0xc2084806", HIDIOCSFEATURE == 0xC208_4806);
    drop(ok);
    let allok = checks.iter().all(|c| c["ok"] == json!(true));
    obj(json!({"ok": allok, "checks": checks}))
}

fn py_repr(v: &Value) -> String {
    match v {
        Value::Null => "None".into(),
        Value::Bool(b) => if *b { "True" } else { "False" }.into(),
        Value::String(s) => s.clone(),
        Value::Object(m) => m.get("name").map_or_else(|| v.to_string(), py_repr),
        other => other.to_string(),
    }
}

fn human(cmd: &str, out: &Map<String, Value>) {
    if let Some(Value::Array(l)) = out.get("dry_run") {
        for x in l {
            println!("{}", py_repr(x));
        }
        return;
    }
    if cmd == "selftest" {
        let mut all = true;
        for c in out.get("checks").and_then(Value::as_array).into_iter().flatten() {
            let good = c["ok"] == json!(true);
            all &= good;
            println!("{}{}", if good { "ok   " } else { "FAIL " }, py_repr(&c["check"]));
        }
        println!("{}", if all { "всё сходится" } else { "ЕСТЬ РАСХОЖДЕНИЯ" });
        return;
    }
    if cmd == "status" && out.get("found") != Some(&json!(true)) {
        println!("клавиатура не найдена");
        return;
    }
    let skip: &[&str] = if cmd == "effects" {
        &["ok", "keys", "devices", "effects", "checks", "palette", "indicator", "sleep"]
    } else {
        &["ok", "keys", "devices", "checks"]
    };
    for (k, v) in out {
        if !skip.contains(&k.as_str()) {
            println!("{k}: {}", py_repr(v));
        }
    }
    if cmd == "effects" {
        for e in out.get("effects").and_then(Value::as_array).into_iter().flatten() {
            let mut flags = String::new();
            if e["speed"] == json!(true) {
                flags += "скорость ";
            }
            if e["palette"] == json!(true) {
                flags += "палитра";
            }
            let works = if e["works"] == json!(true) { "" } else { "  (не работает на F75)" };
            println!("{:>2}  {:<14} {flags}{works}", e["id"], py_repr(&e["name"]));
        }
    }
    if cmd == "devices" {
        for d in out.get("devices").and_then(Value::as_array).into_iter().flatten() {
            println!("{d}");
        }
    }
}

const CMDS: [&str; 20] = [
    "status", "mode", "brightness", "speed", "palette", "color", "keys", "palette-color", "off", "on",
    "indicator", "sleep", "snapshot", "restore", "effects", "layout", "devices", "live", "watch", "selftest",
];

fn usage_exit(msg: &str) -> ! {
    eprintln!("usage: aulactl [--json] [--dry-run] [--from SNAPSHOT] [--transport auto|wired|dongle] [--force] <{}> ...", CMDS.join("|"));
    eprintln!("aulactl: error: {msg}");
    std::process::exit(2);
}

fn parse(argv: &[String]) -> Args {
    let mut a = Args { transport: "auto".into(), interval: 2.0, ..Default::default() };
    let mut it = argv.iter().peekable();
    let mut rest_pos = false;
    while let Some(raw) = it.next() {
        let (flag, inline) = match raw.split_once('=') {
            Some((f, v)) if raw.starts_with("--") => (f.to_string(), Some(v.to_string())),
            _ => (raw.clone(), None),
        };
        let mut val = |name: &str| -> String {
            inline.clone().or_else(|| it.next().cloned()).unwrap_or_else(|| usage_exit(&format!("{name}: нужен аргумент")))
        };
        let int = |name: &str, s: String| -> i64 {
            s.trim().parse().unwrap_or_else(|_| usage_exit(&format!("{name}: invalid int value: '{s}'")))
        };
        if rest_pos || !flag.starts_with('-') || flag == "-" || (flag.len() > 1 && flag[1..].parse::<f64>().is_ok()) {
            if a.cmd.is_empty() {
                if !CMDS.contains(&raw.as_str()) {
                    usage_exit(&format!("invalid choice: '{raw}'"));
                }
                a.cmd = raw.clone();
            } else {
                a.pos.push(raw.clone());
            }
            continue;
        }
        match flag.as_str() {
            "--" => rest_pos = true,
            "--json" => a.json = true,
            "--dry-run" => a.dry_run = true,
            "--force" => a.force = true,
            "--quick" => a.quick = true,
            "--keys" => a.keys = true,
            "--version" => {
                println!("{VERSION}");
                std::process::exit(0);
            }
            "-h" | "--help" => {
                println!("aulactl {VERSION} — подсветка AULA F75. Команды: {}", CMDS.join(", "));
                std::process::exit(0);
            }
            "--from" => a.from_file = Some(val("--from")),
            "--transport" => {
                let v = val("--transport");
                if !["auto", "wired", "dongle"].contains(&v.as_str()) {
                    usage_exit(&format!("--transport: invalid choice: '{v}'"));
                }
                a.transport = v;
            }
            "-b" | "--brightness" => {
                let v = val("-b");
                a.brightness = Some(int("-b", v));
            }
            "-s" | "--speed" => {
                let v = val("-s");
                a.speed = Some(int("-s", v));
            }
            "-p" | "--palette" => a.palette = Some(val("-p")),
            "--interval" => {
                let v = val("--interval");
                a.interval = v.trim().parse().unwrap_or_else(|_| usage_exit(&format!("--interval: '{v}'")));
            }
            _ => usage_exit(&format!("unrecognized arguments: {raw}")),
        }
    }
    if a.cmd.is_empty() {
        usage_exit("the following arguments are required: cmd");
    }
    a
}

pub fn main(argv: &[String]) -> i32 {
    let a = parse(argv);
    let res: R<Map<String, Value>> = match a.cmd.as_str() {
        "status" => cmd_status(&a),
        "mode" => cmd_mode(&a),
        "color" => cmd_color(&a),
        "keys" => cmd_keys(&a),
        "off" => cmd_off(&a),
        "on" => cmd_on(&a),
        "brightness" | "speed" | "palette" => cmd_param(&a, &a.cmd.clone()),
        "palette-color" => cmd_palette_color(&a),
        "indicator" => cmd_indicator(&a),
        "sleep" => cmd_sleep(&a),
        "snapshot" => cmd_snapshot(&a),
        "restore" => cmd_restore(&a),
        "effects" => Ok(cmd_effects()),
        "layout" => Ok(cmd_layout()),
        "devices" => {
            let d: Vec<Value> = scan().iter().map(Cand::to_json).collect();
            Ok(obj(json!({"ok": true, "devices": d})))
        }
        "live" => {
            cmd_live(&a);
            return 0;
        }
        "watch" => {
            cmd_watch(&a);
            return 0;
        }
        _ => Ok(cmd_selftest()),
    };
    match res {
        Ok(out) => {
            let good = out.get("ok").is_none_or(|v| v == &json!(true));
            if a.json {
                emit(&Value::Object(out));
            } else {
                human(&a.cmd, &out);
            }
            if good {
                0
            } else {
                1
            }
        }
        Err(e) => {
            if a.json {
                emit(&json!({"ok": false, "error": e.code, "message": e.message}));
            } else {
                eprintln!("aulactl: {}", e.message);
            }
            exit_code(e.code)
        }
    }
}
