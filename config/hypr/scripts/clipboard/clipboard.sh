#!/usr/bin/env bash
export LC_ALL=C

THEME="$HOME/.config/rofi/launchers/type-2/style-1.rasi"

cliphist list | \
    rofi -dmenu -p "  Clipboard" -i \
         -theme "$THEME" \
         -theme-str 'configuration { show-icons: false; }' | \
    cliphist decode | wl-copy
