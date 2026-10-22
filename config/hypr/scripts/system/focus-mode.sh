#!/bin/sh

STATE="${XDG_RUNTIME_DIR:-/tmp}/focus-mode"

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "focus" -t 1800 -h string:x-canonical-private-synchronous:focus \
        "$1" "$2" 2>/dev/null
}

enable() {
    hyprdo keyword decoration:dim_inactive true >/dev/null
    hyprdo keyword decoration:dim_strength 0.62 >/dev/null
    hyprdo keyword decoration:dim_around 0.35 >/dev/null
    hyprdo keyword decoration:inactive_opacity 0.82 >/dev/null
    hyprdo keyword decoration:blur:passes 2 >/dev/null
    hyprdo keyword general:border_size 1 >/dev/null
    hyprdo keyword animation borderangle,0 >/dev/null

    : > "$STATE"
    notify "Focus mode" "Active window only. Press again to turn off."
}

disable() {
    hyprdo keyword decoration:dim_inactive true >/dev/null
    hyprdo keyword decoration:dim_strength 0.08 >/dev/null
    hyprdo keyword decoration:dim_around 0.4 >/dev/null
    hyprdo keyword decoration:inactive_opacity 0.94 >/dev/null
    hyprdo keyword decoration:blur:passes 3 >/dev/null
    hyprdo keyword general:border_size 2 >/dev/null
    hyprdo keyword animation borderangle,1,60,linear,loop >/dev/null

    rm -f "$STATE"
    notify "Focus mode" "Off"
}

case "${1:-toggle}" in
    on)  enable ;;
    off) disable ;;
    status) [ -e "$STATE" ] && echo on || echo off ;;
    *)   [ -e "$STATE" ] && disable || enable ;;
esac
