#!/usr/bin/env python3
"""Тема Chromium из текущей палитры matugen.

Chromium был единственным крупным приложением мимо палитры: gtk3/4, Qt через
Kvantum, kitty, zsh, starship, cava, dunst, yazi, zed и firefox-семейство
matugen красит, а посреди тёплого тёмного экрана стояло белое окно браузера.

Тема Chromium — это обычное распакованное расширение: manifest.json, в котором
цвета заданы тройками RGB. Скрипт пишет его в ~/.local/share/chromium-matugen,
а matugen зовёт скрипт при каждой смене обоев.

Палитра читается из собственного выхода шаблона, а не из чужого файла: matugen
4.1 пишет шаблоны в недетерминированном порядке, и хук, прочитавший выход
соседа, примерно в трети случаев собирает тему из палитры предыдущих обоев.
Ровно на этом однажды погорела генерация курсора.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

TRIGGER = Path.home() / ".config/matugen/out/chromium-colors.json"
DEST = Path.home() / ".local/share/chromium-matugen"

DEFAULTS = {
    "bg": "#18120e",
    "bgAlt": "#51443a",
    "bgDim": "#221a15",
    "fg": "#ece0d9",
    "fgDim": "#d6c3b5",
    "outline": "#9f8e81",
    "accent": "#feb879",
    "accentText": "#4b2700",
}

def read_palette() -> dict:
    palette = dict(DEFAULTS)
    if TRIGGER.is_file():
        try:
            loaded = json.loads(TRIGGER.read_text())
        except json.JSONDecodeError:
            return palette
        for key, value in loaded.items():
            if isinstance(value, str) and value.startswith("#") and len(value) >= 7:
                palette[key] = value[:7]
    return palette

def rgb(hex_colour: str) -> list[int]:
    h = hex_colour.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]

def mix(a: str, b: str, t: float) -> str:
    """Смешать два цвета. Нужен для неактивной рамки и рамки инкогнито:
    отдельных значений под них в палитре нет, а брать тот же цвет, что у
    активного окна, — значит потерять разницу между ними."""
    ca, cb = rgb(a), rgb(b)
    out = [round(x + (y - x) * t) for x, y in zip(ca, cb)]
    return "#" + "".join(f"{v:02x}" for v in out)

def build(palette: dict) -> dict:
    bg = palette["bg"]
    bg_dim = palette["bgDim"]
    fg = palette["fg"]
    fg_dim = palette["fgDim"]
    accent = palette["accent"]

    frame = mix(bg, "#000000", 0.35)
    frame_inactive = mix(frame, palette["outline"], 0.18)
    toolbar = bg_dim

    return {
        "manifest_version": 3,
        "version": "1.0.0",
        "name": "Matugen",
        "description": "Chromium colours generated from the current wallpaper",
        "theme": {
            "colors": {
                "frame": rgb(frame),
                "frame_inactive": rgb(frame_inactive),
                "frame_incognito": rgb(mix(frame, "#000000", 0.35)),
                "frame_incognito_inactive": rgb(mix(frame, "#000000", 0.2)),
                "toolbar": rgb(toolbar),
                "tab_text": rgb(fg),
                "tab_background_text": rgb(fg_dim),
                "tab_background_text_inactive": rgb(mix(fg_dim, bg, 0.35)),
                "bookmark_text": rgb(fg_dim),
                "toolbar_button_icon": rgb(fg_dim),
                "omnibox_background": rgb(mix(bg, "#000000", 0.18)),
                "omnibox_text": rgb(fg),
                "ntp_background": rgb(bg),
                "ntp_text": rgb(fg),
                "ntp_link": rgb(accent),
                "button_background": rgb(toolbar),
            },
            "tints": {
                "buttons": [-1.0, -1.0, -1.0],
            },
            "properties": {
                "ntp_logo_alternate": 1,
            },
        },
    }

def write(manifest: dict) -> Path:
    DEST.mkdir(parents=True, exist_ok=True)
    path = DEST / "manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    return path

def main() -> int:
    palette = read_palette()
    manifest = build(palette)
    path = write(manifest)
    print(f"palette: bg={palette['bg']} accent={palette['accent']}")
    print(f"written: {path}")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001 - хук не должен ронять matugen
        print(f"chromium theme: {exc}", file=sys.stderr)
        sys.exit(1)
