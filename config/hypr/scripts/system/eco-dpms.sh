#!/bin/sh
[ -e "${XDG_STATE_HOME:-$HOME/.local/state}/pc-eco" ] || exit 0

pgrep -x 'zoom|ZoomWebviewHost|zoom.real' >/dev/null && exit 0
hyprctl clients -j 2>/dev/null | grep -qiE '"class": *"zoom|"title": *"Meet[^a-z]|"title": *"[^"]*Google Meet' && exit 0

active=$(hyprctl activewindow -j 2>/dev/null | grep -E '"(class|initialClass|title)"')

exec "$HOME/.config/hypr/scripts/lock/idle-guard.sh" dpms-off
