#!/usr/bin/env bash
NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
grim -g "$(slurp)" - | wl-copy && bash "$NOTIFY" "Скриншот" "Скопирован в буфер" -t 1500
