#!/usr/bin/env bash
export LC_ALL=C
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -printf "%f\n" | sort | \
    rofi -dmenu -p "  Wallpaper" -i \
         -theme-str 'window { width: 420px; }' \
         -theme-str 'listview { lines: 12; }')

[[ -z "$SELECTED" ]] && exit 0

WALLPAPER="$WALLPAPER_DIR/$SELECTED"

hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALLPAPER"
hyprctl hyprpaper wallpaper ",$WALLPAPER"

echo "$WALLPAPER" > "$HOME/.config/hypr/current-wallpaper"

notify-send "Wallpaper" "Changed to $SELECTED" --icon=image-x-generic -t 2000
