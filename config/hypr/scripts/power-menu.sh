#!/usr/bin/env bash
if pgrep -x 'quickshell|qs' >/dev/null; then
    hyprctl dispatch global quickshell:powerMenu
else
    wlogout -b 3 -l ~/.config/wlogout/layout -C ~/.config/wlogout/style.css
fi
