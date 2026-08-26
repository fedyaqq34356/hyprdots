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
    return used / total, f"{used / 1024 / 1024:.1f}G"

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
                candidates.extend(sorted(chip.glob("temp*_input")))

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
            return max(0.0, min(1.0, fraction)), f"{celsius:.0f}°"
    return None

def gpu() -> dict:
    blank = {"gpu": None, "gpu_label": "", "vram": None, "vram_label": "",
             "gputemp": None, "gputemp_label": ""}
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
    }

def main() -> int:
    previous = read_cpu_times()
    gpu_cache = gpu()
    tick = 0

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

        mem = memory()
        sample["mem"] = mem[0] if mem else None
        sample["mem_label"] = mem[1] if mem else ""

        temp = cpu_temperature()
        sample["temp"] = temp[0] if temp else None
        sample["temp_label"] = temp[1] if temp else ""

        if tick % 2 == 0:
            gpu_cache = gpu()
        sample.update(gpu_cache)

        print(json.dumps(sample), flush=True)

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
