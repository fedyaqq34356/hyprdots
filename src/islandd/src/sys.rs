use crate::util::{emit, hwmon_by_name, monotonic, read_i64, read_str, round_to, sorted_dir};
use serde_json::{json, Map, Value};
use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

const INTERVAL: Duration = Duration::from_secs(1);
const REST_W: f64 = 25.0;
const PSU_EFF: f64 = 0.87;

fn cpu_lines() -> Vec<(String, u64, u64)> {
    let Ok(text) = fs::read_to_string("/proc/stat") else {
        return vec![];
    };
    text.lines()
        .filter(|l| l.starts_with("cpu"))
        .filter_map(|l| {
            let mut it = l.split_whitespace();
            let name = it.next()?.to_string();
            let vals: Vec<u64> = it.filter_map(|v| v.parse().ok()).collect();
            if vals.len() < 4 {
                return None;
            }
            let idle = vals[3] + vals.get(4).copied().unwrap_or(0);
            Some((name, idle, vals.iter().sum()))
        })
        .collect()
}

fn memory() -> Option<(f64, String, f64)> {
    let text = fs::read_to_string("/proc/meminfo").ok()?;
    let (mut total, mut avail) = (None, None);
    for line in text.lines() {
        let (k, rest) = line.split_once(':')?;
        let v: Option<f64> = rest.split_whitespace().next().and_then(|x| x.parse().ok());
        match k {
            "MemTotal" => total = v,
            "MemAvailable" => avail = v,
            _ => {}
        }
        if total.is_some() && avail.is_some() {
            break;
        }
    }
    let (total, avail) = (total.filter(|t| *t > 0.0)?, avail?);
    let used = total - avail;
    Some((used / total, format!("{:.1}G", used / 1024.0 / 1024.0), total / 1024.0 / 1024.0))
}

fn temp_candidates() -> Vec<PathBuf> {
    let mut out = vec![];
    for chip in sorted_dir(Path::new("/sys/class/hwmon"), "") {
        let Some(name) = read_str(&chip.join("name")) else { continue };
        if !matches!(name.as_str(), "coretemp" | "k10temp" | "zenpower") {
            continue;
        }
        let inputs: Vec<PathBuf> = sorted_dir(&chip, "temp")
            .into_iter()
            .filter(|p| p.to_string_lossy().ends_with("_input"))
            .collect();
        let preferred = |p: &PathBuf| {
            let label = PathBuf::from(p.to_string_lossy().replace("_input", "_label"));
            matches!(read_str(&label).as_deref(), Some("Tctl" | "Tdie" | "Package id 0"))
        };
        out.extend(inputs.iter().filter(|p| preferred(p)).cloned());
        out.extend(inputs.iter().filter(|p| !preferred(p)).cloned());
    }
    if out.is_empty() {
        out = sorted_dir(Path::new("/sys/class/thermal"), "thermal_zone")
            .into_iter()
            .map(|z| z.join("temp"))
            .collect();
    }
    out
}

fn cpu_temperature(cands: &[PathBuf]) -> Option<(f64, String, f64)> {
    for p in cands {
        let Some(milli) = read_i64(p) else { continue };
        let c = milli as f64 / 1000.0;
        if c > 0.0 && c < 150.0 {
            let frac = ((c - 30.0) / (95.0 - 30.0)).clamp(0.0, 1.0);
            return Some((frac, format!("{c:.0}°"), c));
        }
    }
    None
}

fn blank_gpu() -> Map<String, Value> {
    let mut m = Map::new();
    for k in ["gpu", "vram", "gputemp"] {
        m.insert(k.into(), Value::Null);
        m.insert(format!("{k}_label"), json!(""));
    }
    m
}

fn amdgpu_device() -> Option<PathBuf> {
    let mut best: Option<(i64, PathBuf)> = None;
    for card in sorted_dir(Path::new("/sys/class/drm"), "card") {
        let n = card.file_name().unwrap().to_string_lossy().to_string();
        let digits = n.strip_prefix("card").unwrap_or("");
        if digits.is_empty() || !digits.chars().all(|c| c.is_ascii_digit()) {
            continue;
        }
        let dev = card.join("device");
        if !dev.join("gpu_busy_percent").exists() {
            continue;
        }
        let total = read_i64(&dev.join("mem_info_vram_total")).unwrap_or(0);
        if best.as_ref().map_or(true, |b| total > b.0) {
            best = Some((total, dev));
        }
    }
    best.map(|b| b.1)
}

fn amdgpu(dev: &Path) -> Map<String, Value> {
    let mut out = blank_gpu();
    if let Some(util) = read_i64(&dev.join("gpu_busy_percent")) {
        out.insert("gpu".into(), json!(util as f64 / 100.0));
        out.insert("gpu_label".into(), json!(format!("{util}%")));
    }
    let used = read_i64(&dev.join("mem_info_vram_used"));
    let total = read_i64(&dev.join("mem_info_vram_total"));
    if let (Some(u), Some(t)) = (used, total.filter(|t| *t != 0)) {
        let g = 1024f64.powi(3);
        out.insert("vram".into(), json!(u as f64 / t as f64));
        out.insert("vram_label".into(), json!(format!("{:.1}G", u as f64 / g)));
        out.insert("vram_total".into(), json!(t as f64 / g));
    }
    for hw in sorted_dir(&dev.join("hwmon"), "hwmon") {
        let mut temps: Vec<(String, Option<i64>)> = vec![];
        for f in sorted_dir(&hw, "temp") {
            let fname = f.file_name().unwrap().to_string_lossy().to_string();
            if !fname.ends_with("_input") {
                continue;
            }
            let label = hw.join(fname.replace("_input", "_label"));
            let name = read_str(&label).unwrap_or(fname);
            temps.push((name, read_i64(&f)));
        }
        let get = |k: &str| temps.iter().find(|t| t.0 == k).and_then(|t| t.1).filter(|v| *v != 0);
        let milli = get("junction")
            .or_else(|| get("edge"))
            .or_else(|| temps.iter().filter_map(|t| t.1).find(|v| *v != 0));
        if let Some(m) = milli {
            let t = m as f64 / 1000.0;
            out.insert("gputemp".into(), json!(((t - 30.0) / 70.0).clamp(0.0, 1.0)));
            out.insert("gputemp_label".into(), json!(format!("{t:.0}°")));
            out.insert("gputemp_c".into(), json!(t));
            break;
        }
    }
    out
}

fn nvidia() -> Map<String, Value> {
    let blank = blank_gpu();
    let Ok(res) = std::process::Command::new("nvidia-smi")
        .args([
            "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
            "--format=csv,noheader,nounits",
        ])
        .output()
    else {
        return blank;
    };
    let text = String::from_utf8_lossy(&res.stdout);
    let Some(line) = text.lines().next().filter(|_| res.status.success()) else {
        return blank;
    };
    let v: Vec<f64> = line.split(',').filter_map(|x| x.trim().parse().ok()).collect();
    let [util, used, total, temp] = v[..] else { return blank };
    let mut m = Map::new();
    m.insert("gpu".into(), json!(util / 100.0));
    m.insert("gpu_label".into(), json!(format!("{util:.0}%")));
    m.insert("vram".into(), if total != 0.0 { json!(used / total) } else { Value::Null });
    m.insert("vram_label".into(), json!(format!("{:.1}G", used / 1024.0)));
    m.insert("gputemp".into(), json!(((temp - 30.0) / 60.0).clamp(0.0, 1.0)));
    m.insert("gputemp_label".into(), json!(format!("{temp:.0}°")));
    m.insert("gputemp_c".into(), json!(temp));
    m.insert("vram_total".into(), json!(total / 1024.0));
    m
}

enum Gpu {
    Amd(PathBuf),
    Nvidia,
    None,
}

impl Gpu {
    fn detect() -> Gpu {
        if let Some(d) = amdgpu_device() {
            return Gpu::Amd(d);
        }
        let has_smi = std::env::var_os("PATH").is_some_and(|p| {
            std::env::split_paths(&p).any(|d| d.join("nvidia-smi").is_file())
        });
        if has_smi { Gpu::Nvidia } else { Gpu::None }
    }

    fn sample(&self) -> Map<String, Value> {
        match self {
            Gpu::Amd(d) => amdgpu(d),
            Gpu::Nvidia => nvidia(),
            Gpu::None => blank_gpu(),
        }
    }
}

fn unescape_mount(s: &str) -> String {
    let b = s.as_bytes();
    let mut out = Vec::with_capacity(b.len());
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'\\' && i + 3 < b.len() {
            if let Ok(v) = u8::from_str_radix(&s[i + 1..i + 4], 8) {
                out.push(v);
                i += 4;
                continue;
            }
        }
        out.push(b[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn disk_device() -> Option<String> {
    let info = fs::read_to_string("/proc/self/mountinfo").ok()?;
    let mut src = None;
    for line in info.lines() {
        let f: Vec<&str> = line.split(' ').collect();
        if f.len() < 5 || f[4] != "/" {
            continue;
        }
        let dash = f.iter().position(|x| *x == "-")?;
        src = f.get(dash + 2).map(|s| unescape_mount(s));
    }
    let src = src?;
    let name = fs::canonicalize(&src).ok()?.file_name()?.to_string_lossy().to_string();
    let parent = fs::canonicalize(format!("/sys/class/block/{name}/.."))
        .ok()
        .and_then(|p| p.file_name().map(|n| n.to_string_lossy().to_string()))?;
    Some(if Path::new(&format!("/sys/block/{parent}")).exists() { parent } else { name })
}

fn disk_sectors(dev: &Option<String>) -> Option<u64> {
    let text = fs::read_to_string(format!("/sys/block/{}/stat", dev.as_ref()?)).ok()?;
    let f: Vec<&str> = text.split_whitespace().collect();
    Some(f.get(2)?.parse::<u64>().ok()? + f.get(6)?.parse::<u64>().ok()?)
}

fn disk_usage() -> Option<(f64, f64)> {
    let mut st: libc::statvfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statvfs(c"/".as_ptr(), &mut st) } != 0 {
        return None;
    }
    let frsize = st.f_frsize as f64;
    let total = st.f_blocks as f64 * frsize;
    let used = (st.f_blocks - st.f_bfree) as f64 * frsize;
    (total > 0.0).then_some((used / total, total))
}

fn rapl_zone() -> Option<PathBuf> {
    sorted_dir(Path::new("/sys/class/powercap"), "intel-rapl:")
        .into_iter()
        .find(|z| read_str(&z.join("name")).is_some_and(|n| n.starts_with("package")))
}

struct Power {
    zone: Option<PathBuf>,
    wrap: Option<i64>,
    prev: Option<(i64, f64)>,
    gpu_hw: Option<PathBuf>,
    board: Option<PathBuf>,
    board_zen: bool,
}

impl Power {
    fn new(gpu: &Gpu) -> Power {
        let zone = rapl_zone();
        let wrap = zone.as_ref().and_then(|z| read_i64(&z.join("max_energy_range_uj")));
        let gpu_hw = match gpu {
            Gpu::Amd(d) => sorted_dir(&d.join("hwmon"), "hwmon").into_iter().next(),
            _ => None,
        };
        let names = [
            "nct6775", "nct6779", "nct6791", "nct6792", "nct6793", "nct6795", "nct6796",
            "nct6797", "nct6798", "nct6799", "it87", "it8686", "it8688", "asus_wmi_sensors",
            "zenpower",
        ];
        let (mut board, mut board_zen) = (None, false);
        for n in names {
            if let Some(h) = hwmon_by_name(n) {
                board = Some(h);
                board_zen = n == "zenpower";
                break;
            }
        }
        Power { zone, wrap, prev: None, gpu_hw, board, board_zen }
    }

    fn cpu_watts(&mut self, load: Option<f64>) -> (Option<f64>, bool) {
        if let Some(z) = &self.zone {
            if let Some(uj) = read_i64(&z.join("energy_uj")) {
                let now = monotonic();
                let prev = self.prev.replace((uj, now));
                if let Some((puj, pt)) = prev {
                    if now > pt {
                        let mut d = uj - puj;
                        if d < 0 {
                            if let Some(w) = self.wrap {
                                d += w;
                            }
                        }
                        if d >= 0 {
                            return (Some(d as f64 / 1e6 / (now - pt)), true);
                        }
                    }
                }
                return (None, true);
            }
        }
        match load {
            Some(l) => (Some(18.0 + 50.0 * l), false),
            None => (None, false),
        }
    }

    fn sample(&mut self, load: Option<f64>, out: &mut Map<String, Value>) {
        let (cpu_w, exact) = self.cpu_watts(load);
        out.insert("cpu_w".into(), json!(cpu_w.map(|w| round_to(w, 1))));
        out.insert("cpu_w_exact".into(), json!(exact));
        let mut gpu_w = None;
        if let Some(hw) = &self.gpu_hw {
            let uw = read_i64(&hw.join("power1_average")).filter(|v| *v != 0)
                .or_else(|| read_i64(&hw.join("power1_input")));
            gpu_w = uw.map(|v| v as f64 / 1e6);
            out.insert("gpu_v".into(), json!(read_i64(&hw.join("in0_input")).map(|m| m as f64 / 1000.0)));
        }
        out.insert("gpu_w".into(), json!(gpu_w.map(|w| round_to(w, 1))));
        if let Some(b) = self.board.as_ref().filter(|_| !self.board_zen) {
            out.insert("vcore".into(), json!(read_i64(&b.join("in0_input")).map(|m| m as f64 / 1000.0)));
        }
        if let Some(c) = cpu_w {
            out.insert("total_w".into(), json!(((c + gpu_w.unwrap_or(0.0) + REST_W) / PSU_EFF).round() as i64));
        }
    }
}

pub fn run() {
    let temps = temp_candidates();
    let gpu = Gpu::detect();
    let mut power = Power::new(&gpu);
    let dev = disk_device();
    let nvme = hwmon_by_name("nvme");

    let mut prev = cpu_lines();
    let mut gpu_cache = gpu.sample();
    let mut prev_sec = disk_sectors(&dev);
    let mut prev_t = monotonic();
    let mut tick: u64 = 0;

    loop {
        std::thread::sleep(INTERVAL);
        tick += 1;
        let mut s = Map::new();
        s.insert("cpu".into(), Value::Null);
        s.insert("cpu_label".into(), json!(""));

        let cur = cpu_lines();
        let load = |(_, i1, t1): &(String, u64, u64), (_, i0, t0): &(String, u64, u64)| {
            let span = t1.saturating_sub(*t0);
            (span > 0).then(|| (1.0 - (i1.saturating_sub(*i0)) as f64 / span as f64).clamp(0.0, 1.0))
        };
        let mut cpu = None;
        if let (Some(c), Some(p)) = (cur.first(), prev.first()) {
            if c.0 == "cpu" && p.0 == "cpu" {
                cpu = load(c, p);
            }
        }
        if let Some(b) = cpu {
            s.insert("cpu".into(), json!(b));
            s.insert("cpu_label".into(), json!(format!("{:.0}%", b * 100.0)));
        }
        if cur.len() == prev.len() && cur.len() > 1 {
            let cores: Vec<f64> = cur[1..]
                .iter()
                .zip(&prev[1..])
                .map(|(c, p)| load(c, p).map_or(0.0, |v| round_to(v, 3)))
                .collect();
            s.insert("cores".into(), json!(cores));
        }
        prev = cur;

        let mem = memory();
        s.insert("mem".into(), json!(mem.as_ref().map(|m| m.0)));
        s.insert("mem_label".into(), json!(mem.as_ref().map_or(String::new(), |m| m.1.clone())));
        s.insert("mem_total".into(), json!(mem.as_ref().map(|m| m.2)));

        let t = cpu_temperature(&temps);
        s.insert("temp".into(), json!(t.as_ref().map(|t| t.0)));
        s.insert("temp_label".into(), json!(t.as_ref().map_or(String::new(), |t| t.1.clone())));
        s.insert("temp_c".into(), json!(t.as_ref().map(|t| t.2)));

        match disk_usage() {
            Some((frac, total)) => {
                s.insert("disk".into(), json!(frac));
                s.insert("disk_total".into(), json!(total / 1024f64.powi(3)));
            }
            None => {
                s.insert("disk".into(), Value::Null);
            }
        }
        let (now_sec, now_t) = (disk_sectors(&dev), monotonic());
        if let (Some(n), Some(p)) = (now_sec, prev_sec) {
            if now_t > prev_t {
                let mbs = n.saturating_sub(p) as f64 * 512.0 / 1e6 / (now_t - prev_t);
                s.insert("disk_io".into(), json!(round_to((mbs / 400.0).clamp(0.0, 1.0), 3)));
                s.insert("disk_mbs".into(), json!(round_to(mbs, 1)));
            }
        }
        (prev_sec, prev_t) = (now_sec, now_t);
        let disk_temp = nvme.as_ref().and_then(|h| read_i64(&h.join("temp1_input")));
        s.insert("disk_temp_c".into(), json!(disk_temp.map(|m| m as f64 / 1000.0)));

        power.sample(cpu, &mut s);

        if tick % 2 == 0 {
            gpu_cache = gpu.sample();
        }
        for (k, v) in &gpu_cache {
            s.insert(k.clone(), v.clone());
        }
        emit(&Value::Object(s));
    }
}
