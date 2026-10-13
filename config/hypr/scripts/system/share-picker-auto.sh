#!/bin/sh
mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
[ -n "$mon" ] || mon=$(hyprctl monitors -j | jq -r '.[0].name')
echo "[SELECTION]r/screen:$mon"
