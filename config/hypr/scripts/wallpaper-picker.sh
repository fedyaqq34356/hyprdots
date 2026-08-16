#!/usr/bin/env bash
export LC_ALL=C

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THEME="$HOME/.config/rofi/launchers/type-2/style-1.rasi"

SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -printf "%f\n" | sort | \
    rofi -dmenu -p "  Wallpaper" -i \
         -theme "$THEME" \
         -theme-str 'configuration { show-icons: false; }')

[[ -z "$SELECTED" ]] && exit 0

WALLPAPER="$WALLPAPER_DIR/$SELECTED"

"$HOME/.config/hypr/scripts/set-wallpaper.sh" "$WALLPAPER"

notify-send "Wallpaper" "Changed to $SELECTED" --icon=image-x-generic -t 2000
