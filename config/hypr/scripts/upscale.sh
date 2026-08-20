#!/usr/bin/env bash

set -uo pipefail

NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
notify() { bash "$NOTIFY" "$@" >/dev/null 2>&1; }

command -v realesrgan-ncnn-vulkan >/dev/null || {
    notify "Апскейл" "realesrgan-ncnn-vulkan не установлен" -u critical -t 4000
    exit 1
}

FILES=("$@")

if [ ${#FILES[@]} -eq 0 ]; then
    mapfile -t FILES < <(
        zenity --file-selection --multiple --separator=$'\n' \
               --title="Что увеличиваем" \
               --file-filter="Изображения | *.png *.jpg *.jpeg *.webp *.bmp *.tif *.tiff" \
               2>/dev/null
    )
    [ ${#FILES[@]} -eq 0 ] && exit 0
fi

CHOICE=$(zenity --list --radiolist --title="Модель" --width=460 --height=280 \
    --text="Что на картинке" \
    --column="" --column="Модель" --column="Кратность" \
    TRUE  "Фото и всё живое"      "4" \
    FALSE "Аниме и рисованное"    "4" \
    FALSE "Кадр из аниме-видео"   "4" \
    FALSE "Фото, увеличение x2"   "2" \
    --hide-column=3 --print-column=2,3 --separator="|" 2>/dev/null)

[ -z "$CHOICE" ] && exit 0

case "${CHOICE%%|*}" in
    "Аниме и рисованное")  MODEL="realesrgan-x4plus-anime"; SCALE=4 ;;
    "Кадр из аниме-видео") MODEL="realesr-animevideov3";    SCALE=4 ;;
    "Фото, увеличение x2") MODEL="realesr-animevideov3";    SCALE=2 ;;
    *)                     MODEL="realesrgan-x4plus";       SCALE=4 ;;
esac

TOTAL=${#FILES[@]}
DONE=0
LAST=""

notify "Апскейл" "Считаю: $TOTAL шт., модель $MODEL" -t 2500 -a upscale -r 9994

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
    notify "Апскейл" "Не удалось обработать ни одного файла" -u critical -t 4000 -a upscale -r 9994
    exit 1
fi

SIZE=$(identify -format "%wx%h" "$LAST" 2>/dev/null)
printf '%s' "$LAST" | wl-copy
notify "Апскейл" "Готово: $DONE из $TOTAL · $SIZE" -i "$LAST" -t 5000 -a upscale -r 9994
