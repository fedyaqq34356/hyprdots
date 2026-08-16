#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
INTERVAL=10800

while true; do
    sleep "$INTERVAL"

    WALLPAPER=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
    [[ -z "$WALLPAPER" ]] && continue

    "$HOME/.config/hypr/scripts/set-wallpaper.sh" "$WALLPAPER"

done
