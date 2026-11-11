#!/bin/sh
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/monitor-eco"
ECO_BRIGHT=0
ECO_CONTRAST=60
NORMAL_BRIGHT=75
NORMAL_CONTRAST=75

on() {
    ddcutil --noverify setvcp 10 "$ECO_BRIGHT" 12 "$ECO_CONTRAST"
    hyprdo keyword monitor "desc:Lenovo Group Limited R24s,1920x1080@60,0x0,1,cm,srgb" >/dev/null
    mkdir -p "${STATE%/*}" && touch "$STATE"
}

off() {
    ddcutil --noverify setvcp 10 "$NORMAL_BRIGHT" 12 "$NORMAL_CONTRAST"
    hyprdo keyword monitor "desc:Lenovo Group Limited R24s,1920x1080@143.85,0x0,1,cm,srgb" >/dev/null
    rm -f "$STATE"
}

case "$1" in
    on) on ;;
    off) off ;;
    toggle) if [ -e "$STATE" ]; then off; else on; fi ;;
    status) [ -e "$STATE" ] && echo on || echo off ;;
    *) echo "usage: $0 on|off|toggle|status" >&2; exit 1 ;;
esac
