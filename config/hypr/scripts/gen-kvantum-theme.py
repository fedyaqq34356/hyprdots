#!/usr/bin/env python3
"""Build a Kvantum theme that follows the wallpaper.

Kvantum draws its widgets from an SVG, so a theme cannot be recoloured through
its config alone — the artwork carries the colour. KvDark happens to be drawn
entirely in greys, which makes it the one stock theme that can be retinted
without destroying its shading: every fill is remapped to the same lightness it
already had, wearing the wallpaper's hue instead of neutral grey. Highlights,
text and selection come from the config, where they can be named outright.

Corner radius stays whatever KvDark's artwork is. It lives in path geometry, not
in a number, so it is not something this script can dial to match Shape.chip.

Run by matugen's post_hook; reads the JSON that matugen just wrote.
"""

import colorsys
import json
import os
import re
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
SOURCE = os.path.join(HOME, ".config/matugen/out/kvantum-source.json")
STOCK = "/usr/share/Kvantum/KvDark"
OUT_DIR = os.path.join(HOME, ".config/Kvantum/Matugen")
THEME = "Matugen"

TINT = 0.62
SAT_CAP = 0.20

def hex_to_rgb(value):
    value = value.strip().lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return "#" + "".join("%02x" % max(0, min(255, round(c * 255))) for c in rgb)

def load_colors():
    with open(SOURCE) as fh:
        return json.load(fh)

def tint_grey(match, hue, sat):
    """Keep the fill's lightness, give it the palette's hue."""
    r, g, b = hex_to_rgb(match.group(0))
    h0, l0, s0 = colorsys.rgb_to_hls(r, g, b)

    if s0 > 0.25:
        return match.group(0)

    s = min(SAT_CAP, sat * TINT)
    return rgb_to_hex(colorsys.hls_to_rgb(hue, l0, s))

def build_svg(colors):
    with open(os.path.join(STOCK, "KvDark.svg")) as fh:
        svg = fh.read()

    r, g, b = hex_to_rgb(colors["primary"])
    hue, _, sat = colorsys.rgb_to_hls(r, g, b)

    svg = re.sub(r"#[0-9a-fA-F]{6}", lambda m: tint_grey(m, hue, sat), svg)

    with open(os.path.join(OUT_DIR, THEME + ".svg"), "w") as fh:
        fh.write(svg)

GENERAL_COLORS = """[GeneralColors]
window.color={surfaceContainer}
base.color={surface}
alt.base.color={surfaceLow}
button.color={surfaceHigh}
light.color={surfaceHighest}
mid.light.color={surfaceVariant}
dark.color={surfaceLowest}
mid.color={surfaceContainer}
highlight.color={primary}
inactive.highlight.color={secondary}
text.color={onSurface}
window.text.color={onSurface}
button.text.color={onSurface}
disabled.text.color={outline}
tooltip.text.color={onSurface}
highlight.text.color={onPrimary}
link.color={tertiary}
link.visited.color={secondary}
progress.indicator.text.color={onPrimary}
"""

def build_config(colors):
    with open(os.path.join(STOCK, "KvDark.kvconfig")) as fh:
        lines = fh.read().splitlines()

    out = []
    skipping = False
    for line in lines:
        if line.strip() == "[GeneralColors]":
            out.append(GENERAL_COLORS.format(**colors).rstrip("\n"))
            skipping = True
            continue
        if skipping:
            if line.startswith("["):
                skipping = False
            else:
                continue

        if ".color=" in line and "text" in line.split("=")[0]:
            key, _, value = line.partition("=")
            if value.strip() == "white":
                line = key + "=" + colors["onSurface"]
            elif value.strip() == "black":
                line = key + "=" + colors["onPrimary"]

        if line.startswith("comment="):
            line = "comment=Wallpaper colours, KvDark geometry (generated)"
        if line.startswith("author="):
            line = "author=Tsu Jan, retinted by matugen"

        out.append(line)

    with open(os.path.join(OUT_DIR, THEME + ".kvconfig"), "w") as fh:
        fh.write("\n".join(out) + "\n")

def select_theme():
    """Point Kvantum at the generated theme, leaving other settings alone."""
    path = os.path.join(HOME, ".config/Kvantum/kvantum.kvconfig")
    lines = []
    if os.path.exists(path):
        with open(path) as fh:
            lines = fh.read().splitlines()

    if not any(l.strip() == "[General]" for l in lines):
        lines = ["[General]"] + lines

    done = False
    for i, line in enumerate(lines):
        if line.startswith("theme="):
            lines[i] = "theme=" + THEME
            done = True
    if not done:
        lines.insert(lines.index("[General]") + 1, "theme=" + THEME)

    with open(path, "w") as fh:
        fh.write("\n".join(lines) + "\n")

def main():
    if not os.path.isdir(STOCK):
        print("KvDark not installed, nothing to fork", file=sys.stderr)
        return 1
    if not os.path.exists(SOURCE):
        print("no matugen source at " + SOURCE, file=sys.stderr)
        return 1

    os.makedirs(OUT_DIR, exist_ok=True)
    colors = load_colors()

    build_svg(colors)
    build_config(colors)
    select_theme()

    if "--reload" in sys.argv and shutil.which("kvantummanager"):
        subprocess.run(["kvantummanager", "--set", THEME],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    return 0

if __name__ == "__main__":
    sys.exit(main())
