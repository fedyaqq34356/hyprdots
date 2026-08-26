#!/bin/sh

OUT="${XDG_RUNTIME_DIR:-/tmp}/lock-bg.png"

command -v grim >/dev/null 2>&1 || exit 0

grim -o "$(hyprctl -j monitors 2>/dev/null \
    | python3 -c 'import sys,json; print(next((m["name"] for m in json.load(sys.stdin) if m.get("focused")), ""))' \
    2>/dev/null)" "$OUT.raw" 2>/dev/null || grim "$OUT.raw" 2>/dev/null || exit 0

if command -v magick >/dev/null 2>&1; then
    magick "$OUT.raw" -resize 25% -blur 0x6 -modulate 82,105 "$OUT" 2>/dev/null \
        || mv "$OUT.raw" "$OUT"
else
    mv "$OUT.raw" "$OUT"
fi

rm -f "$OUT.raw"
chmod 600 "$OUT" 2>/dev/null
