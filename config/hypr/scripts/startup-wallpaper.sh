#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LAST_WALLPAPER="$HOME/.config/hypr/current-wallpaper"

if [[ -f "$LAST_WALLPAPER" ]]; then
    WALLPAPER=$(cat "$LAST_WALLPAPER")
    [[ ! -f "$WALLPAPER" ]] && WALLPAPER=""
fi

if [[ -z "$WALLPAPER" ]]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
fi

[[ -z "$WALLPAPER" ]] && exit 0

for i in $(seq 1 20); do
    pgrep -x awww-daemon &>/dev/null && break
    sleep 0.3
done

"$HOME/.config/hypr/scripts/set-wallpaper.sh" "$WALLPAPER"
