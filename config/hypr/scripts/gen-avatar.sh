#!/usr/bin/env bash
set -u

SRC="${1:-$HOME/.local/share/avatar/source.jpg}"
OUT="$HOME/.local/share/avatar/avatar.png"
COLORS="$HOME/.config/hypr/config/colors.conf"
SIZE=512
RING=10
GLOW=18

[[ -f "$SRC" ]] || { echo "gen-avatar: no source: $SRC" >&2; exit 1; }
command -v magick >/dev/null 2>&1 || { echo "gen-avatar: imagemagick missing" >&2; exit 1; }

hex_from() {
    local key="$1"
    sed -n "s/^\\\$$key *= *rgba\\?(\\([0-9a-fA-F]\\{6\\}\\).*/\\1/p" "$COLORS" | head -n1
}

ACCENT="#$(hex_from accent)"
[[ "$ACCENT" == "#" ]] && ACCENT="#f0b0ff"
ACCENT_ALT="#$(hex_from accent_alt)"
[[ "$ACCENT_ALT" == "#" ]] && ACCENT_ALT="$ACCENT"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

magick "$SRC" -auto-orient \
    -resize "${SIZE}x${SIZE}^" -gravity center -extent "${SIZE}x${SIZE}" \
    -blur 0x18 -modulate 88,110 "$TMP/bg.png"

magick "$SRC" -auto-orient -resize "${SIZE}x${SIZE}" "$TMP/fg.png"

magick "$TMP/bg.png" "$TMP/fg.png" -gravity center -composite "$TMP/sq.png"

R=$(( SIZE / 2 - RING - 2 ))
magick -size "$((SIZE*4))x$((SIZE*4))" xc:black \
    -fill white -draw "circle $((SIZE*2)),$((SIZE*2)) $((SIZE*2)),$((SIZE*2 - R*4))" \
    -resize "${SIZE}x${SIZE}" -alpha off "$TMP/mask.png"

magick "$TMP/sq.png" "$TMP/mask.png" \
    -alpha off -compose CopyOpacity -composite "$TMP/circle.png"

magick -size "${SIZE}x${SIZE}" \
    "radial-gradient:${ACCENT}-${ACCENT_ALT}" "$TMP/grad.png"

magick -size "$((SIZE*4))x$((SIZE*4))" xc:none \
    -stroke white -strokewidth "$((RING*4))" -fill none \
    -draw "circle $((SIZE*2)),$((SIZE*2)) $((SIZE*2)),$((SIZE*2 - R*4))" \
    -resize "${SIZE}x${SIZE}" -alpha extract "$TMP/ringmask.png"

magick "$TMP/grad.png" "$TMP/ringmask.png" \
    -alpha off -compose CopyOpacity -composite "$TMP/ring.png"

magick "$TMP/ring.png" -channel A -blur "0x${GLOW}" -evaluate multiply 0.55 +channel \
    "$TMP/glow.png"

magick "$TMP/glow.png" "$TMP/circle.png" -gravity center -composite \
    "$TMP/ring.png" -gravity center -composite "$OUT"

cp -f "$OUT" "$HOME/.face" 2>/dev/null
echo "$OUT"
