#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

INTERVAL = 1.0

def read_cpu_times() -> tuple[int, int] | None:
    try:
        line = Path("/proc/stat").read_text().split("\n", 1)[0]
    except OSError:
        return None
    parts = line.split()
    if parts[0] != "cpu":
        return None
    values = [int(v) for v in parts[1:]]
    idle = values[3] + (values[4] if len(values) > 4 else 0)
    return idle, sum(values)

def read_core_times() -> list[tuple[int, int]]:
    try:
        lines = Path("/proc/stat").read_text().splitlines()
    except OSError:
        return []
    out = []
    for line in lines:
        parts = line.split()
        if not parts or not parts[0].startswith("cpu") or parts[0] == "cpu":
            continue
        values = [int(v) for v in parts[1:]]
        out.append((values[3] + (values[4] if len(values) > 4 else 0), sum(values)))
    return out

def memory() -> tuple[float, str] | None:
    try:
        text = Path("/proc/meminfo").read_text()
    except OSError:
        return None

    fields = {}
    for line in text.splitlines():
        key, _, rest = line.partition(":")
        fields[key] = int(rest.strip().split()[0])  # kB

    total = fields.get("MemTotal")
    available = fields.get("MemAvailable")
    if not total or available is None:
        return None

    used = total - available
    return used / total, f"{used / 1024 / 1024:.1f}G", total / 1024 / 1024

def cpu_temperature() -> tuple[float, str] | None:
    candidates: list[Path] = []
    hwmon = Path("/sys/class/hwmon")
    if hwmon.is_dir():
        for chip in hwmon.iterdir():
            name_file = chip / "name"
            if not name_file.exists():
                continue
            name = name_file.read_text().strip()
            if name in ("coretemp", "k10temp", "zenpower"):
                inputs = sorted(chip.glob("temp*_input"))
                preferred = [p for p in inputs
                             if (chip / p.name.replace("_input", "_label")).exists()
                             and (chip / p.name.replace("_input", "_label")).read_text().strip()
                             in ("Tctl", "Tdie", "Package id 0")]
                candidates.extend(preferred + [p for p in inputs if p not in preferred])

    if not candidates:
        candidates = sorted(Path("/sys/class/thermal").glob("thermal_zone*/temp"))

    for path in candidates:
        try:
            millidegrees = int(path.read_text().strip())
        except (OSError, ValueError):
            continue
        celsius = millidegrees / 1000
        if 0 < celsius < 150:
            fraction = (celsius - 30) / (95 - 30)
            return max(0.0, min(1.0, fraction)), f"{celsius:.0f}°", celsius
    return None

BLANK = {"gpu": None, "gpu_label": "", "vram": None, "vram_label": "",
         "gputemp": None, "gputemp_label": ""}

def read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None

def amdgpu_device() -> Path | None:
    best = None
    for card in sorted(Path("/sys/class/drm").glob("card[0-9]*")):
        dev = card / "device"
        if not (dev / "gpu_busy_percent").exists():
            continue
        total = read_int(dev / "mem_info_vram_total") or 0
        if best is None or total > best[0]:
            best = (total, dev)
    return best[1] if best else None

def amdgpu(dev: Path) -> dict:
    out = dict(BLANK)
    util = read_int(dev / "gpu_busy_percent")
    if util is not None:
        out["gpu"] = util / 100
        out["gpu_label"] = f"{util}%"
    used = read_int(dev / "mem_info_vram_used")
    total = read_int(dev / "mem_info_vram_total")
    if used is not None and total:
        out["vram"] = used / total
        out["vram_label"] = f"{used / 1024 ** 3:.1f}G"
        out["vram_total"] = total / 1024 ** 3
    for hw in sorted((dev / "hwmon").glob("hwmon*")):
        temps = {}
        for f in hw.glob("temp*_input"):
            label = (hw / f.name.replace("_input", "_label"))
            name = label.read_text().strip() if label.exists() else f.name
            temps[name] = read_int(f)
        milli = temps.get("junction") or temps.get("edge") or next(
            (t for t in temps.values() if t), None)
        if milli:
            temp = milli / 1000
            out["gputemp"] = max(0.0, min(1.0, (temp - 30) / 70))
            out["gputemp_label"] = f"{temp:.0f}°"
            out["gputemp_c"] = temp
            break
    return out

def gpu() -> dict:
    blank = dict(BLANK)
    dev = amdgpu_device()
    if dev is not None:
        return amdgpu(dev)
    if not shutil.which("nvidia-smi"):
        return blank

    try:
        result = subprocess.run(
            ["nvidia-smi",
             "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=4,
        )
    except (OSError, subprocess.SubprocessError):
        return blank
    if result.returncode != 0 or not result.stdout.strip():
        return blank

    try:
        util, used, total, temp = [
            float(v.strip()) for v in result.stdout.strip().splitlines()[0].split(",")
        ]
    except (ValueError, IndexError):
        return blank

    return {
        "gpu": util / 100,
        "gpu_label": f"{util:.0f}%",
        "vram": used / total if total else None,
        "vram_label": f"{used / 1024:.1f}G",
        "gputemp": max(0.0, min(1.0, (temp - 30) / 60)),
        "gputemp_label": f"{temp:.0f}°",
        "gputemp_c": temp,
        "vram_total": total / 1024,
    }

def disk_device() -> str | None:
    try:
        src = subprocess.run(["findmnt", "-no", "SOURCE", "/"], capture_output=True,
                             text=True, timeout=2).stdout.strip().split("[")[0]
        name = Path(src).resolve().name
        parent = Path(f"/sys/class/block/{name}/..").resolve().name
        return parent if Path(f"/sys/block/{parent}").exists() else name
    except (OSError, subprocess.SubprocessError):
        return None

def disk_sectors(dev: str | None) -> int | None:
    if not dev:
        return None
    try:
        f = Path(f"/sys/block/{dev}/stat").read_text().split()
        return int(f[2]) + int(f[6])
    except (OSError, IndexError, ValueError):
        return None

def disk_temperature() -> float | None:
    for h in Path("/sys/class/hwmon").glob("hwmon*"):
        try:
            if (h / "name").read_text().strip() == "nvme":
                return int((h / "temp1_input").read_text()) / 1000
        except (OSError, ValueError):
            continue
    return None

REST_W = 25.0
PSU_EFF = 0.87

def hwmon_by_name(name: str) -> Path | None:
    for h in sorted(Path("/sys/class/hwmon").glob("hwmon*")):
        try:
            if (h / "name").read_text().strip() == name:
                return h
        except OSError:
            continue
    return None

def rapl_zone() -> Path | None:
    for z in sorted(Path("/sys/class/powercap").glob("intel-rapl:*")):
        try:
            if (z / "name").read_text().strip().startswith("package"):
                return z
        except OSError:
            continue
    return None

class Power:
    def __init__(self) -> None:
        self.zone = rapl_zone()
        self.wrap = read_int(self.zone / "max_energy_range_uj") if self.zone else None
        self.prev: tuple[int, float] | None = None
        dev = amdgpu_device()
        self.gpu_hw = next(iter(sorted((dev / "hwmon").glob("hwmon*"))), None) if dev else None
        self.board = None
        for name in ("nct6775", "nct6779", "nct6791", "nct6792", "nct6793", "nct6795",
                     "nct6796", "nct6797", "nct6798", "nct6799", "it87", "it8686",
                     "it8688", "asus_wmi_sensors", "zenpower"):
            self.board = hwmon_by_name(name)
            if self.board:
                break

    def cpu_watts(self, load: float | None) -> tuple[float | None, bool]:
        if self.zone:
            uj = read_int(self.zone / "energy_uj")
            now = time.monotonic()
            if uj is not None:
                prev, self.prev = self.prev, (uj, now)
                if prev and now > prev[1]:
                    d = uj - prev[0]
                    if d < 0 and self.wrap:
                        d += self.wrap
                    if d >= 0:
                        return d / 1e6 / (now - prev[1]), True
                return None, True
        if load is None:
            return None, False
        return 18 + 50 * load, False

    def sample(self, load: float | None) -> dict:
        out: dict = {}
        cpu_w, exact = self.cpu_watts(load)
        out["cpu_w"] = round(cpu_w, 1) if cpu_w is not None else None
        out["cpu_w_exact"] = exact
        gpu_w = None
        if self.gpu_hw:
            uw = read_int(self.gpu_hw / "power1_average") or read_int(self.gpu_hw / "power1_input")
            gpu_w = uw / 1e6 if uw is not None else None
            mv = read_int(self.gpu_hw / "in0_input")
            out["gpu_v"] = mv / 1000 if mv is not None else None
        out["gpu_w"] = round(gpu_w, 1) if gpu_w is not None else None
        if self.board and self.board.name != "zenpower":
            mv = read_int(self.board / "in0_input")
            out["vcore"] = mv / 1000 if mv is not None else None
        if cpu_w is not None:
            out["total_w"] = round((cpu_w + (gpu_w or 0) + REST_W) / PSU_EFF)
        return out

def main() -> int:
    previous = read_cpu_times()
    previous_cores = read_core_times()
    gpu_cache = gpu()
    tick = 0
    dev = disk_device()
    prev_sec = disk_sectors(dev)
    prev_t = time.monotonic()
    power = Power()

    while True:
        time.sleep(INTERVAL)
        tick += 1

        sample: dict = {"cpu": None, "cpu_label": ""}

        current = read_cpu_times()
        if previous and current:
            idle_delta = current[0] - previous[0]
            total_delta = current[1] - previous[1]
            if total_delta > 0:
                busy = 1 - idle_delta / total_delta
                sample["cpu"] = max(0.0, min(1.0, busy))
                sample["cpu_label"] = f"{busy * 100:.0f}%"
        previous = current

        cores = read_core_times()
        if len(cores) == len(previous_cores):
            loads = []
            for (idle_now, total_now), (idle_was, total_was) in zip(cores, previous_cores):
                span = total_now - total_was
                loads.append(round(max(0.0, min(1.0, 1 - (idle_now - idle_was) / span)), 3)
                             if span > 0 else 0.0)
            sample["cores"] = loads
        previous_cores = cores

        mem = memory()
        sample["mem"] = mem[0] if mem else None
        sample["mem_label"] = mem[1] if mem else ""
        sample["mem_total"] = mem[2] if mem else None

        temp = cpu_temperature()
        sample["temp"] = temp[0] if temp else None
        sample["temp_label"] = temp[1] if temp else ""
        sample["temp_c"] = temp[2] if temp else None

        try:
            du = shutil.disk_usage("/")
            sample["disk"] = du.used / du.total
            sample["disk_total"] = du.total / 1024 ** 3
        except OSError:
            sample["disk"] = None
        now_sec, now_t = disk_sectors(dev), time.monotonic()
        if now_sec is not None and prev_sec is not None and now_t > prev_t:
            mbs = (now_sec - prev_sec) * 512 / 1e6 / (now_t - prev_t)
            sample["disk_io"] = round(max(0.0, min(1.0, mbs / 400)), 3)
            sample["disk_mbs"] = round(mbs, 1)
        prev_sec, prev_t = now_sec, now_t
        sample["disk_temp_c"] = disk_temperature()

        sample.update(power.sample(sample.get("cpu")))

        if tick % 2 == 0:
            gpu_cache = gpu()
        sample.update(gpu_cache)

        print(json.dumps(sample), flush=True)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
