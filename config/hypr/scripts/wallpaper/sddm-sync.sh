#!/bin/sh
set -eu

DIR=/var/lib/f-sddm
[ -w "$DIR" ] || exit 0

if [ "${1:-}" = "--wait" ]; then
    sleep 1
    while pgrep -x matugen >/dev/null 2>&1; do sleep 0.3; done
fi

WALL=$(cat "$HOME/.config/hypr/current-wallpaper" 2>/dev/null || true)
if [ -n "$WALL" ] && [ -f "$WALL" ]; then
    magick "$WALL" -resize '2560x1440^' -quality 92 "$DIR/wall.png.tmp" 2>/dev/null \
        || cp -f "$WALL" "$DIR/wall.png.tmp"
    mv -f "$DIR/wall.png.tmp" "$DIR/wall.png"
fi

[ -f "$HOME/.face" ] && cp -f "$HOME/.face" "$DIR/face.png"

C="$HOME/.cache/matugen/colors.json"
if [ -f "$C" ]; then
    python3 - "$C" "$DIR/Palette.qml.tmp" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
keys = ["bg", "bgAlt", "fg", "fgDim", "accent", "accentText", "bad"]
with open(sys.argv[2], "w") as f:
    f.write("import QtQuick\nQtObject {\n")
    for k in keys:
        if k in p:
            f.write(f'    property color {k}: "{p[k]}"\n')
    f.write("}\n")
PY
    mv -f "$DIR/Palette.qml.tmp" "$DIR/Palette.qml"
fi
chmod a+r "$DIR"/* 2>/dev/null || true
