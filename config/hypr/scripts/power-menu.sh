#!/usr/bin/env bash
# Quickshell owns the power menu; wlogout is the fallback when the Waybar
# stack is the one running.
if pgrep -x 'quickshell|qs' >/dev/null; then
    hyprctl dispatch global quickshell:powerMenu
else
    wlogout -b 3 -l ~/.config/wlogout/layout -C ~/.config/wlogout/style.css
fi
