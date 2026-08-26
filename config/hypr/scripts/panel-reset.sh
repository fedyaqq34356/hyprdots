#!/bin/sh

MON="${1:-eDP-1}"
MODE="${2:-1920x1080@60,0x1080,1}"

restore() {
    hyprctl keyword monitor "$MON,$MODE" >/dev/null 2>&1
    hyprctl dispatch dpms on >/dev/null 2>&1
}
trap restore EXIT INT TERM

hyprctl monitors all 2>/dev/null | grep -q "Monitor $MON" || exit 0

hyprctl keyword monitor "$MON,disable" >/dev/null 2>&1
sleep 2
