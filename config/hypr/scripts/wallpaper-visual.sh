#!/usr/bin/env bash
export LC_ALL=C

LOG="/tmp/wp-visual.log"
echo "=== $(date) START ===" >> "$LOG"
echo "HYPRLAND_INSTANCE_SIGNATURE=${HYPRLAND_INSTANCE_SIGNATURE:-MISSING}" >> "$LOG"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-MISSING}" >> "$LOG"
echo "DISPLAY=${DISPLAY:-MISSING}" >> "$LOG"

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
LOCK="$HOME/.cache/wallpaper-thumbs.lock"
mkdir -p "$THUMB_DIR"

if [[ ! -f "$LOCK" ]]; then
    touch "$LOCK"
    (
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | \
        while IFS= read -r wp; do
            NAME=$(basename "$wp")
            THUMB="$THUMB_DIR/$NAME"
            [[ -f "$THUMB" ]] && continue
            nice -n 19 ffmpeg -i "$wp" \
                -vf "scale=300:200:force_original_aspect_ratio=increase,crop=300:200" \
                -vframes 1 "$THUMB" -y -loglevel quiet 2>/dev/null
            sleep 0.05
        done
        rm -f "$LOCK"
    ) &>/dev/null &
fi

SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -printf "%f\n" | sort | \
    while IFS= read -r name; do
        THUMB="$THUMB_DIR/$name"
        if [[ -f "$THUMB" ]]; then
            printf '%s\0icon\x1f%s\n' "$name" "$THUMB"
        else
            echo "$name"
        fi
    done | rofi -dmenu -p "  Wallpaper" -i \
        -theme "$HOME/.config/rofi/launchers/type-2/style-1.rasi" \
        -theme-str 'configuration { show-icons: true; }' \
        -theme-str 'element-icon { size: 90px; }' \
        -theme-str 'listview { columns: 4; lines: 3; }' \
        -theme-str 'element { padding: 6px; }' \
        -theme-str 'window { width: 900px; }')

echo "SELECTED='${SELECTED}'" >> "$LOG"
echo "SELECTED_LEN=${#SELECTED}" >> "$LOG"

if [[ -z "$SELECTED" ]]; then
    echo "EXIT: empty selection" >> "$LOG"
    exit 0
fi

WALLPAPER="$WALLPAPER_DIR/$SELECTED"
echo "WALLPAPER='$WALLPAPER'" >> "$LOG"
echo "EXISTS=$(test -f "$WALLPAPER" && echo yes || echo NO)" >> "$LOG"

if [[ ! -f "$WALLPAPER" ]]; then
    echo "EXIT: wallpaper file not found" >> "$LOG"
    exit 1
fi

"$HOME/.config/hypr/scripts/set-wallpaper.sh" "$WALLPAPER" >> "$LOG" 2>&1
echo "set-wallpaper exit=$?" >> "$LOG"

notify-send "Wallpaper" "Changed to $SELECTED" --icon=image-x-generic -t 2000
echo "=== DONE ===" >> "$LOG"
