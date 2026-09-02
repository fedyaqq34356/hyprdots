#!/usr/bin/env bash

set -uo pipefail

NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
notify() { bash "$NOTIFY" "$@" >/dev/null 2>&1; }

command -v realesrgan-ncnn-vulkan >/dev/null || {
    notify "Upscale" "realesrgan-ncnn-vulkan is not installed" -u critical -t 4000
    exit 1
}

FILES=("$@")

if [ ${#FILES[@]} -eq 0 ]; then
    mapfile -t FILES < <(
        zenity --file-selection --multiple --separator=$'\n' \
               --title="What to upscale" \
               --file-filter="Images | *.png *.jpg *.jpeg *.webp *.bmp *.tif *.tiff" \
               2>/dev/null
    )
    [ ${#FILES[@]} -eq 0 ] && exit 0
fi

CHOICE=$(zenity --list --radiolist --title="Model" --width=460 --height=280 \
    --text="What is in the picture" \
    --column="" --column="Model" --column="Scale" \
    TRUE  "Photos and anything real"      "4" \
    FALSE "Anime and drawings"    "4" \
    FALSE "A frame from anime video"   "4" \
    FALSE "Photo, 2x"   "2" \
    --hide-column=3 --print-column=2,3 --separator="|" 2>/dev/null)

[ -z "$CHOICE" ] && exit 0

case "${CHOICE%%|*}" in
    "Anime and drawings")  MODEL="realesrgan-x4plus-anime"; SCALE=4 ;;
    "A frame from anime video") MODEL="realesr-animevideov3";    SCALE=4 ;;
    "Photo, 2x") MODEL="realesr-animevideov3";    SCALE=2 ;;
    *)                     MODEL="realesrgan-x4plus";       SCALE=4 ;;
esac

TOTAL=${#FILES[@]}
DONE=0
LAST=""

notify "Upscale" "Working: $TOTAL file(s), model $MODEL" -t 2500 -a upscale -r 9994

for FILE in "${FILES[@]}"; do
    [ -f "$FILE" ] || continue
    DIR=$(dirname "$FILE")
    BASE=$(basename "${FILE%.*}")
    OUT="$DIR/${BASE}_x${SCALE}.png"

    if realesrgan-ncnn-vulkan -i "$FILE" -o "$OUT" -n "$MODEL" -s "$SCALE" >/dev/null 2>&1; then
        DONE=$((DONE + 1))
        LAST="$OUT"
    fi
done

if [ "$DONE" -eq 0 ]; then
    notify "Upscale" "Could not process a single file" -u critical -t 4000 -a upscale -r 9994
    exit 1
fi

SIZE=$(identify -format "%wx%h" "$LAST" 2>/dev/null)
printf '%s' "$LAST" | wl-copy
notify "Upscale" "Done: $DONE of $TOTAL · $SIZE" -i "$LAST" -t 5000 -a upscale -r 9994
