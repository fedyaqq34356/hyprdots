#!/usr/bin/env python3
import json
import os
import signal
import subprocess
import sys
import time

INTERVAL = 1.5
TOP = 40
CLK = os.sysconf("SC_CLK_TCK")
NCPU = os.cpu_count() or 1
ME = os.getuid()
SELF = os.getpid()

PROTECTED = {
    "quickshell", "qs", "hyprland", "xwayland", "pipewire", "pipewire-pulse",
    "wireplumber", "dbus-daemon", "dbus-broker", "dbus-launch", "gnome-keyring-daemon",
    "xdg-desktop-portal", "xdg-desktop-portal-hyprland", "xdg-desktop-portal-gtk",
    "xdg-document-portal", "xdg-permission-store", "at-spi-bus-launcher",
    "at-spi2-registryd", "polkit-agent", "procs.py", "sysmon.py", "openrc",
    "supervise-daemon", "elogind", "seatd", "login", "agetty", "sddm",
    "sddm-helper", "startplasma", "hyprland-session", "uwsm",
}
INTERP = {"python", "python3", "node", "bash", "sh", "zsh", "perl", "ruby", "java", "lua", "luajit", "bun", "deno"}
SHELLS = {"bash", "sh", "zsh", "fish"}

def boot_time():
    with open("/proc/stat") as f:
        for line in f:
            if line.startswith("btime"):
                return int(line.split()[1])
    return int(time.time())

BOOT = boot_time()

def read(path):
    try:
        with open(path, "rb") as f:
            return f.read()
    except OSError:
        return None

def app_name(pid, comm):
    raw = read(f"/proc/{pid}/cmdline")
    if not raw:
        return None
    argv = [a.decode(errors="replace") for a in raw.split(b"\0") if a]
    if not argv:
        return None
    exe = os.path.basename(argv[0].split(" ")[0]).rstrip(":")
    base = exe.rstrip("0123456789.") or exe
    if base in INTERP and base not in SHELLS:
        for a in argv[1:]:
            if a.startswith("-"):
                continue
            name = os.path.basename(a)
            for ext in (".py", ".js", ".mjs", ".rb", ".pl", ".jar", ".lua"):
                if name.endswith(ext):
                    name = name[: -len(ext)]
            return name or exe
        return exe
    if base in SHELLS:
        return base
    return exe or comm

def scan():
    out = {}
    for d in os.listdir("/proc"):
        if not d.isdigit():
            continue
        pid = int(d)
        if pid == SELF:
            continue
        try:
            st = os.stat(f"/proc/{pid}")
        except OSError:
            continue
        if st.st_uid != ME:
            continue
        stat = read(f"/proc/{pid}/stat")
        if not stat:
            continue
        s = stat.decode(errors="replace")
        lp, rp = s.find("("), s.rfind(")")
        comm = s[lp + 1:rp]
        rest = s[rp + 2:].split()
        ppid = int(rest[1])
        ticks = int(rest[11]) + int(rest[12])
        start = int(rest[19])
        rss = int(rest[21]) * 4096
        name = app_name(pid, comm)
        if not name:
            continue
        out[pid] = (name, ppid, ticks, start, rss)
    return out

def pss(pid):
    raw = read(f"/proc/{pid}/smaps_rollup")
    if not raw:
        return None
    for line in raw.decode(errors="replace").splitlines():
        if line.startswith("Pss:"):
            return int(line.split()[1]) * 1024
    return None

def windows():
    try:
        res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, timeout=2)
        data = json.loads(res.stdout or b"[]")
    except Exception:
        return {}
    return {c.get("pid"): (c.get("class") or "", c.get("title") or "") for c in data if c.get("pid")}

def is_protected(name):
    n = name.lower()
    return n in PROTECTED or n.startswith("xdg-desktop-portal")

def stream():
    prev = {pid: (v[2], v[3]) for pid, v in scan().items()}
    last = time.monotonic()
    time.sleep(0.3)
    wins = {}
    tick = 0
    while True:
        procs = scan()
        now = time.monotonic()
        dt = max(0.05, now - last)
        last = now
        if tick % 2 == 0:
            wins = windows()
        tick += 1

        groups = {}
        for pid, (name, ppid, ticks, start, rss) in procs.items():
            p = prev.get(pid)
            used = ticks - p[0] if p and p[1] == start else 0
            g = groups.setdefault(name, {"key": name, "cpu": 0.0, "mem": 0, "n": 0,
                                         "start": start, "cls": "", "title": "", "pids": []})
            g["cpu"] += used / CLK / dt / NCPU * 100
            g["mem"] += pss(pid) or rss
            g["n"] += 1
            g["start"] = min(g["start"], start)
            g["pids"].append(pid)
            w = wins.get(pid)
            if w and not g["cls"]:
                g["cls"], g["title"] = w
        prev = {pid: (v[2], v[3]) for pid, v in procs.items()}

        for g in groups.values():
            if not g["cls"]:
                for pid in g["pids"]:
                    ppid = procs[pid][1]
                    if ppid in wins and procs.get(ppid, ("",))[0] == g["key"]:
                        g["cls"], g["title"] = wins[ppid]
                        break

        total = mem_total()
        ranked = sorted(groups.values(),
                        key=lambda g: g["cpu"] + g["mem"] / total * 100 * 0.6,
                        reverse=True)[:TOP]
        res = []
        for g in ranked:
            res.append({
                "key": g["key"],
                "cpu": round(g["cpu"], 1),
                "mem": g["mem"],
                "n": g["n"],
                "age": int(time.time() - (BOOT + g["start"] / CLK)),
                "cls": g["cls"],
                "title": g["title"],
                "prot": is_protected(g["key"]),
            })
        print(json.dumps({"groups": res, "memTotal": total}), flush=True)
        time.sleep(INTERVAL)

def mem_total():
    raw = read("/proc/meminfo") or b""
    for line in raw.decode().splitlines():
        if line.startswith("MemTotal:"):
            return int(line.split()[1]) * 1024
    return 1

def kill(key):
    if is_protected(key):
        print(json.dumps({"key": key, "error": "protected"}), flush=True)
        return
    targets = {pid: v[3] for pid, v in scan().items() if v[0] == key}
    if not targets:
        print(json.dumps({"key": key, "gone": 0, "forced": 0, "left": 0}), flush=True)
        return

    def alive(pid, start):
        stat = read(f"/proc/{pid}/stat")
        if not stat:
            return False
        s = stat.decode(errors="replace")
        rest = s[s.rfind(")") + 2:].split()
        return int(rest[19]) == start and rest[0] != "Z"

    for pid, start in targets.items():
        if alive(pid, start):
            try:
                os.kill(pid, signal.SIGTERM)
            except OSError:
                pass

    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        if not any(alive(p, s) for p, s in targets.items()):
            break
        time.sleep(0.1)

    forced = 0
    for pid, start in targets.items():
        if alive(pid, start):
            try:
                os.kill(pid, signal.SIGKILL)
                forced += 1
            except OSError:
                pass
    time.sleep(0.2)
    left = sum(1 for p, s in targets.items() if alive(p, s))
    print(json.dumps({"key": key, "gone": len(targets) - left, "forced": forced, "left": left}), flush=True)

if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "kill":
        kill(sys.argv[2])
    else:
        try:
            stream()
        except (BrokenPipeError, KeyboardInterrupt):
            pass
