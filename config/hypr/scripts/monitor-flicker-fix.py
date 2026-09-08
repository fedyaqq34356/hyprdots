#!/usr/bin/env python3
"""Лечит мерцание eDP-1 после подключения/отключения внешнего монитора.

Слушает socket2 Hyprland и на события monitoradded/monitorremoved делает то,
что раньше делалось руками:

    hyprctl dispatch dpms off eDP-1 && sleep 1 && hyprctl dispatch dpms on eDP-1

Запускается один раз из startup.conf.
"""

import json
import os
import socket
import subprocess
import sys
import threading
import time

PANEL = os.environ.get("FLICKER_PANEL", "eDP-1")
DEBOUNCE = 1.5   # события подключения приходят пачкой
DARK = 1.0       # сколько держать панель выключенной

EVENTS = ("monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2")

def hyprctl(*args):
    return subprocess.run(
        ["hyprctl", *args], capture_output=True, text=True, timeout=5
    ).stdout

def panel_present():
    try:
        return any(m.get("name") == PANEL for m in json.loads(hyprctl("monitors", "-j")))
    except Exception:
        return False

def cycle():
    if not panel_present():
        return
    hyprctl("dispatch", "dpms", "off", PANEL)
    threading.Timer(DARK, lambda: hyprctl("dispatch", "dpms", "on", PANEL)).start()

def listen(path):
    """Один сеанс чтения socket2. Возвращается, когда сокет закрылся."""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)

    timer = None
    buf = b""
    try:
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                return
            buf += chunk
            *lines, buf = buf.split(b"\n")
            for line in lines:
                name = line.decode("utf-8", "replace").split(">>", 1)[0]
                if name in EVENTS:
                    if timer is not None:
                        timer.cancel()
                    timer = threading.Timer(DEBOUNCE, cycle)
                    timer.start()
    finally:
        sock.close()

def main():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not sig or not runtime:
        sys.exit(0)

    path = f"{runtime}/hypr/{sig}/.socket2.sock"

    while True:
        try:
            listen(path)
        except (FileNotFoundError, ConnectionError, OSError):
            pass
        if not os.path.exists(path):
            return
        time.sleep(2)

if __name__ == "__main__":
    main()
