#!/usr/bin/env python3
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
SOURCE_THEME = "Papirus-Dark"
THEME_NAME = "Papirus-Matugen"
SYSTEM = Path("/usr/share/icons")
TARGET = HOME / ".local/share/icons" / THEME_NAME
GTK_CSS = HOME / ".config/gtk-3.0/gtk.css"

IGNORE = {"#ffffff", "#e4e4e4", "#000000"}

SKIP = {"adwaita", "breeze", "nordic", "yaru"}

def accent() -> str:
    try:
        text = GTK_CSS.read_text(encoding="utf-8")
    except OSError:
        return "#5294e2"
    m = re.search(r"@define-color\s+accent_color\s+(#[0-9a-fA-F]{6})", text)
    return m.group(1).lower() if m else "#5294e2"

def rgb(hex_colour: str):
    h = hex_colour.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))

def lab(hex_colour: str):
    def linear(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (linear(c) for c in rgb(hex_colour))
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 1.00000
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116

    fx, fy, fz = f(x), f(y), f(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)

def distance(a: str, b: str) -> float:
    la, aa, ba = lab(a)
    lb, ab, bb = lab(b)
    return (0.4 * (la - lb)) ** 2 + (aa - ab) ** 2 + (ba - bb) ** 2

def palette():
    places = SYSTEM / "Papirus" / "64x64" / "places"
    out = {}
    for svg in sorted(places.glob("folder-*.svg")):
        name = svg.stem[len("folder-"):]
        if "-" in name or name in SKIP:
            continue
        if not (places / f"folder-{name}-download.svg").exists():
            continue
        found = [c.lower() for c in re.findall(r"fill:(#[0-9a-fA-F]{6})", svg.read_text())]
        found = [c for c in found if c not in IGNORE]
        if found:
            out[name] = found[-1]
    return out

def build(colour: str) -> int:
    if TARGET.exists():
        shutil.rmtree(TARGET)
    TARGET.mkdir(parents=True)

    (TARGET / "index.theme").write_text(
        "[Icon Theme]\n"
        f"Name={THEME_NAME}\n"
        f"Comment=Papirus with folders tinted to the wallpaper accent\n"
        f"Inherits={SOURCE_THEME},Papirus,hicolor\n"
        "Directories=\n",
        encoding="utf-8",
    )

    linked = 0
    base = SYSTEM / SOURCE_THEME
    for places in sorted(base.glob("*/places")):
        size = places.parent.name
        dest = TARGET / size / "places"
        dest.mkdir(parents=True, exist_ok=True)
        real = places.resolve()
        for svg in real.glob(f"folder-{colour}*.svg"):
            plain = "folder" + svg.name[len(f"folder-{colour}"):]
            link = dest / plain
            if link.exists() or link.is_symlink():
                link.unlink()
            link.symlink_to(svg)
            linked += 1
    return linked

def use_theme():
    for ini in (HOME / ".config/gtk-3.0/settings.ini",
                HOME / ".config/gtk-4.0/settings.ini"):
        if not ini.exists():
            continue
        text = ini.read_text(encoding="utf-8")
        new = re.sub(r"gtk-icon-theme-name=.*", f"gtk-icon-theme-name={THEME_NAME}", text)
        if new != text:
            ini.write_text(new, encoding="utf-8")

    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", THEME_NAME],
        stderr=subprocess.DEVNULL, check=False,
    )

def main():
    want = accent()
    colours = palette()
    if not colours:
        print("no Papirus folder variants found", file=sys.stderr)
        return 1

    pick = min(colours, key=lambda name: distance(want, colours[name]))
    count = build(pick)
    use_theme()
    print(f"accent {want} -> folder-{pick} ({colours[pick]}), {count} icons linked")
    return 0

if __name__ == "__main__":
    sys.exit(main())
