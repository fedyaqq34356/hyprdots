#!/usr/bin/env python3
"""Лечит фиолетовые артефакты и мерцание eDP-1.

Делает то, что раньше делалось руками:

    hyprctl dispatch dpms off eDP-1 && sleep 1 && hyprctl dispatch dpms on eDP-1

Два повода:

1. Старт сессии. Hyprland забирает у консоли CRTC панели как есть, первый
   коммит гонится с page-flip ("Cannot commit when a page-flip is awaiting"),
   а следом драйвер NVIDIA делает modeset второго выхода. Панель остаётся
   недоинициализированной — фиолетовый мусор. Поэтому панель гасится сразу
   при запуске скрипта и включается, когда набор мониторов перестал
   меняться: мусор не успевает показаться, вместо него короткий чёрный.
2. Подключение/отключение внешнего монитора (события socket2).
3. Пробуждение после сна: панель снова проходит modeset с той же гонкой.
   Сон виден как разрыв между CLOCK_BOOTTIME (идёт во сне) и
   CLOCK_MONOTONIC (стоит).

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

def dark_until_stable(limit):
    """Гасит панель сразу и включает, когда выходы перестали меняться.

    «Устоялся» = одинаковый ответ hyprctl monitors 1.5 с подряд, но панель
    тёмная не меньше DARK. Потолок limit: на медленном старте всё равно
    включаем.
    """
    hyprctl("dispatch", "dpms", "off", PANEL)
    start = time.monotonic()
    deadline = start + limit
    last, since = None, start
    while time.monotonic() < deadline:
        cur = monitor_set()
        if cur and cur != last:
            last, since = cur, time.monotonic()
        elif cur and time.monotonic() - since >= 1.5 and time.monotonic() - start >= DARK:
            break
        time.sleep(0.25)
    hyprctl("dispatch", "dpms", "on", PANEL)

def monitor_set():
    try:
        return sorted(
            (m.get("name"), m.get("width"), m.get("height"), m.get("refreshRate"))
            for m in json.loads(hyprctl("monitors", "-j"))
        )
    except Exception:
        return None

def startup_cycle():
    dark_until_stable(20)

def watch_resume():
    """Цикл панели после каждого пробуждения."""
    gap = time.clock_gettime(time.CLOCK_BOOTTIME) - time.monotonic()
    while True:
        time.sleep(0.3)
        now = time.clock_gettime(time.CLOCK_BOOTTIME) - time.monotonic()
        if now - gap > 1:
            if panel_present():
                dark_until_stable(8)
        gap = now

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

    startup_cycle()
    threading.Thread(target=watch_resume, daemon=True).start()

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
