#!/bin/sh
# Recovers a dark internal panel by forcing a full modeset on it.
#
# Symptom this fixes: Hyprland is rendering fine (grim returns a normal frame)
# but the physical panel shows nothing. A plain "dpms on" does not clear it -
# the mode has to be torn down and re-applied.
#
# Safe to run blind: the panel is always re-enabled and DPMS forced on, even
# if the script is interrupted partway through.

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
# restore() runs on exit and brings the mode + DPMS back.
