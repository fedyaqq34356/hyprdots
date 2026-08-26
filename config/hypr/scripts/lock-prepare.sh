#!/bin/sh
# Take the blurred backdrop for the lock screen.
#
# The lock shows the desktop as it was, blurred, rather than the wallpaper:
# it makes the lock feel like a state of the session rather than a separate
# screen. The shot has to be taken before the lock surface appears, otherwise
# it would capture the lock itself.

OUT="${XDG_RUNTIME_DIR:-/tmp}/lock-bg.png"

command -v grim >/dev/null 2>&1 || exit 0

# Focused output only; the lock surface is drawn per screen and each one
# scales this to fill, which is close enough and much cheaper than one shot
# per monitor.
grim -o "$(hyprctl -j monitors 2>/dev/null \
    | python3 -c 'import sys,json; print(next((m["name"] for m in json.load(sys.stdin) if m.get("focused")), ""))' \
    2>/dev/null)" "$OUT.raw" 2>/dev/null || grim "$OUT.raw" 2>/dev/null || exit 0

if command -v magick >/dev/null 2>&1; then
    # Blur at a quarter size and leave it small: the lock surface scales it
    # back up itself, which costs nothing and blurs it further for free.
    # Upscaling here instead cost about a second per lock.
    magick "$OUT.raw" -resize 25% -blur 0x6 -modulate 82,105 "$OUT" 2>/dev/null \
        || mv "$OUT.raw" "$OUT"
else
    mv "$OUT.raw" "$OUT"
fi

rm -f "$OUT.raw"
chmod 600 "$OUT" 2>/dev/null
