#!/usr/bin/env python3
"""Generate a hyprcursor theme coloured from the current matugen palette.

Reads the accent/background colours matugen already wrote into the Hyprland
colour file, draws the cursor shapes as SVG, and builds them into a hyprcursor
theme installed at ~/.local/share/icons/<NAME>.

Called from matugen's post_hook, so the pointer re-colours with the wallpaper.
Run it by hand to rebuild:  gen-cursor-theme.py [--reload]
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

THEME_NAME = "Matugen-Cursor"
COLORS_CONF = Path.home() / ".config/hypr/config/colors.conf"
BUILD_DIR = Path.home() / ".cache/cursor-build"
INSTALL_DIR = Path.home() / ".local/share/icons"

# Fallbacks if the palette file is missing or unparseable.
DEFAULT_FILL = "#feb879"
DEFAULT_EDGE = "#18120e"


def read_palette() -> tuple[str, str]:
    """Pull the accent and background hex out of the matugen Hyprland colours.

    Hyprland colour vars look like `$accent = rgb(feb879)` or `rgba(feb879ff)`.
    """
    if not COLORS_CONF.is_file():
        return DEFAULT_FILL, DEFAULT_EDGE

    text = COLORS_CONF.read_text()
    found: dict[str, str] = {}
    pattern = re.compile(
        r"^\s*\$(\w+)\s*=\s*rgba?\(\s*([0-9a-fA-F]{6})[0-9a-fA-F]{0,2}\s*\)",
        re.MULTILINE,
    )
    for name, hexval in pattern.findall(text):
        found[name.lower()] = "#" + hexval.lower()

    def pick(names: list[str], fallback: str) -> str:
        for n in names:
            if n in found:
                return found[n]
        return fallback

    fill = pick(["accent", "primary", "active_border_1", "color_primary"],
                DEFAULT_FILL)
    edge = pick(["background", "bg", "surface", "shadow", "color_background"],
                DEFAULT_EDGE)
    return fill, edge


# --- shape drawing -------------------------------------------------------
#
# Every shape is drawn on a 24x24 grid, then scaled by hyprcursor. Each has a
# thick edge stroke under a fill, which is what keeps the pointer readable on
# both a white document and a dark terminal.

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
        'viewBox="0 0 24 24">')


def stroked(path: str, fill: str, edge: str, width: float = 1.6) -> str:
    """A path drawn twice: fat edge underneath, fill on top."""
    return (
        f'<path d="{path}" fill="none" stroke="{edge}" stroke-width="{width * 2}" '
        f'stroke-linejoin="round" stroke-linecap="round"/>'
        f'<path d="{path}" fill="{fill}" stroke="{edge}" stroke-width="{width * 0.4}" '
        f'stroke-linejoin="round" stroke-linecap="round"/>'
    )


ARROW = "M3 2 L3 18.2 L7.1 14.4 L9.7 20.4 L12.6 19.1 L10 13.3 L15.6 13.1 Z"
HAND = ("M9 13 L9 4.6 A1.5 1.5 0 0 1 12 4.6 L12 10.5 L12 8.8 "
        "A1.4 1.4 0 0 1 14.8 8.8 L14.8 10.6 A1.4 1.4 0 0 1 17.6 10.6 "
        "L17.6 12.2 A1.4 1.4 0 0 1 20.4 12.2 L20.4 17 "
        "A4 4 0 0 1 16.4 21 L13.4 21 A4 4 0 0 1 9.7 18.6 L7.2 14.4 "
        "A1.5 1.5 0 0 1 9 12.6 Z")
BEAM = "M9 3 L15 3 M12 3 L12 21 M9 21 L15 21"
CROSS = "M12 2 L12 9.5 M12 14.5 L12 22 M2 12 L9.5 12 M14.5 12 L22 12"
NS = "M12 2 L8 7 L11 7 L11 17 L8 17 L12 22 L16 17 L13 17 L13 7 L16 7 Z"
EW = "M2 12 L7 8 L7 11 L17 11 L17 8 L22 12 L17 16 L17 13 L7 13 L7 16 Z"
NWSE = "M3 3 L11 3 L8.2 5.8 L18.2 15.8 L21 13 L21 21 L13 21 L15.8 18.2 L5.8 8.2 L3 11 Z"
NESW = "M21 3 L21 11 L18.2 8.2 L8.2 18.2 L11 21 L3 21 L3 13 L5.8 15.8 L15.8 5.8 L13 3 Z"
MOVE = ("M12 1 L15 5 L13 5 L13 11 L19 11 L19 9 L23 12 L19 15 L19 13 L13 13 "
        "L13 19 L15 19 L12 23 L9 19 L11 19 L11 13 L5 13 L5 15 L1 12 L5 9 "
        "L5 11 L11 11 L11 5 L9 5 Z")


def ring(fill: str, edge: str, dash: bool = False) -> str:
    """Busy indicator: a ring with a bright arc riding on it."""
    dashes = ' stroke-dasharray="9 5"' if dash else ""
    return (
        f'<circle cx="12" cy="12" r="8" fill="none" stroke="{edge}" stroke-width="5"/>'
        f'<circle cx="12" cy="12" r="8" fill="none" stroke="{fill}" '
        f'stroke-width="3" opacity="0.35"/>'
        f'<path d="M12 4 A8 8 0 0 1 20 12" fill="none" stroke="{fill}" '
        f'stroke-width="3.4" stroke-linecap="round"{dashes}/>'
    )


def no_drop(fill: str, edge: str) -> str:
    return (
        f'<circle cx="12" cy="12" r="8.5" fill="none" stroke="{edge}" stroke-width="6"/>'
        f'<circle cx="12" cy="12" r="8.5" fill="none" stroke="{fill}" stroke-width="3.2"/>'
        f'<path d="M6.4 6.4 L17.6 17.6" stroke="{edge}" stroke-width="6" '
        f'stroke-linecap="round"/>'
        f'<path d="M6.4 6.4 L17.6 17.6" stroke="{fill}" stroke-width="3.2" '
        f'stroke-linecap="round"/>'
    )


def line_shape(path: str, fill: str, edge: str) -> str:
    return (
        f'<path d="{path}" fill="none" stroke="{edge}" stroke-width="5.2" '
        f'stroke-linecap="round"/>'
        f'<path d="{path}" fill="none" stroke="{fill}" stroke-width="2.2" '
        f'stroke-linecap="round"/>'
    )


def build_shapes(fill: str, edge: str) -> dict:
    """shape name -> (svg source, hotspot_x, hotspot_y, [x11 aliases])."""
    arrow = HEAD + stroked(ARROW, fill, edge) + "</svg>"

    return {
        "default": (
            arrow, 0.13, 0.09,
            ["left_ptr", "arrow", "top_left_arrow", "default"],
        ),
        "pointer": (
            HEAD + stroked(HAND, fill, edge) + "</svg>", 0.42, 0.19,
            ["hand", "hand1", "hand2", "pointing_hand", "pointer",
             "e29285e634086352946a0e7090d73106"],
        ),
        "text": (
            HEAD + line_shape(BEAM, fill, edge) + "</svg>", 0.5, 0.5,
            ["xterm", "ibeam", "text"],
        ),
        "wait": (
            HEAD + ring(fill, edge) + "</svg>", 0.5, 0.5,
            ["watch", "wait", "0426c94ea35c87780ff01dc239897213"],
        ),
        "progress": (
            HEAD + stroked(ARROW, fill, edge)
            + f'<circle cx="17" cy="6.5" r="4.6" fill="none" stroke="{edge}" '
              f'stroke-width="4"/>'
            + f'<path d="M17 1.9 A4.6 4.6 0 0 1 21.6 6.5" fill="none" '
              f'stroke="{fill}" stroke-width="2.6" stroke-linecap="round"/>'
            + "</svg>",
            0.13, 0.09,
            ["half-busy", "left_ptr_watch", "progress",
             "00000000000000020006000e7e9ffc3f"],
        ),
        "crosshair": (
            HEAD + line_shape(CROSS, fill, edge) + "</svg>", 0.5, 0.5,
            ["cross", "crosshair", "tcross", "cell"],
        ),
        "not-allowed": (
            HEAD + no_drop(fill, edge) + "</svg>", 0.5, 0.5,
            ["forbidden", "no-drop", "not-allowed", "circle",
             "03b6e0fcb3499374a867c041f52298f0"],
        ),
        "ns-resize": (
            HEAD + stroked(NS, fill, edge, 1.3) + "</svg>", 0.5, 0.5,
            ["n-resize", "s-resize", "sb_v_double_arrow", "v_double_arrow",
             "double_arrow", "top_side", "bottom_side", "row-resize",
             "size_ver"],
        ),
        "ew-resize": (
            HEAD + stroked(EW, fill, edge, 1.3) + "</svg>", 0.5, 0.5,
            ["e-resize", "w-resize", "sb_h_double_arrow", "h_double_arrow",
             "left_side", "right_side", "col-resize", "size_hor"],
        ),
        "nwse-resize": (
            HEAD + stroked(NWSE, fill, edge, 1.3) + "</svg>", 0.5, 0.5,
            ["nw-resize", "se-resize", "bd_double_arrow", "size_fdiag",
             "top_left_corner", "bottom_right_corner"],
        ),
        "nesw-resize": (
            HEAD + stroked(NESW, fill, edge, 1.3) + "</svg>", 0.5, 0.5,
            ["ne-resize", "sw-resize", "fd_double_arrow", "size_bdiag",
             "top_right_corner", "bottom_left_corner"],
        ),
        "all-scroll": (
            HEAD + stroked(MOVE, fill, edge, 1.2) + "</svg>", 0.5, 0.5,
            ["fleur", "move", "all-scroll", "size_all", "grabbing",
             "closedhand", "dnd-move"],
        ),
    }


# --- theme assembly ------------------------------------------------------

def write_theme(shapes: dict) -> Path:
    src = BUILD_DIR / "src"
    if src.exists():
        shutil.rmtree(src)
    (src / "hyprcursors").mkdir(parents=True)

    (src / "manifest.hl").write_text(
        f'name = {THEME_NAME}\n'
        f'description = Cursor theme generated from the current matugen palette\n'
        f'version = 1.0\n'
        f'cursors_directory = hyprcursors\n'
    )

    for name, (svg, hx, hy, aliases) in shapes.items():
        d = src / "hyprcursors" / name
        d.mkdir(parents=True)
        (d / f"{name}.svg").write_text(svg + "\n")

        overrides = "".join(
            f"define_override = {a}\n" for a in aliases if a != name
        )
        (d / "meta.hl").write_text(
            f"resize_algorithm = none\n"
            f"hotspot_x = {hx}\n"
            f"hotspot_y = {hy}\n"
            f"define_size = 0, {name}.svg\n"
            f"{overrides}"
        )
    return src


def compile_theme(src: Path) -> Path:
    out = BUILD_DIR / "out"
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    subprocess.run(
        ["hyprcursor-util", "--create", str(src), "-o", str(out)],
        check=True, capture_output=True, text=True,
    )

    # hyprcursor-util writes theme_<name>/ inside the output directory.
    built = [p for p in out.iterdir() if p.is_dir()]
    if not built:
        raise RuntimeError(f"hyprcursor-util produced nothing in {out}")
    return built[0]


def install(built: Path) -> Path:
    dest = INSTALL_DIR / THEME_NAME
    if dest.exists():
        shutil.rmtree(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(built, dest)
    return dest


def reload_hyprland() -> None:
    if not shutil.which("hyprctl"):
        return
    # setcursor makes running clients pick the theme up without a restart.
    subprocess.run(["hyprctl", "setcursor", THEME_NAME, "24"],
                   capture_output=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--reload", action="store_true",
                    help="apply the theme to the running Hyprland session")
    args = ap.parse_args()

    if not shutil.which("hyprcursor-util"):
        print("hyprcursor-util not found (pacman -S hyprcursor)",
              file=sys.stderr)
        return 1

    fill, edge = read_palette()
    print(f"palette: fill={fill} edge={edge}")

    src = write_theme(build_shapes(fill, edge))
    built = compile_theme(src)
    dest = install(built)
    print(f"installed: {dest}")

    if args.reload:
        reload_hyprland()
        print(f"applied: {THEME_NAME}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        print(exc.stderr or exc, file=sys.stderr)
        sys.exit(1)
