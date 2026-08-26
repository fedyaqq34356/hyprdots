#!/bin/sh

STATE="${XDG_RUNTIME_DIR:-/tmp}/focus-mode"

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "focus" -t 1800 -h string:x-canonical-private-synchronous:focus \
        "$1" "$2" 2>/dev/null
}

enable() {
    hyprctl --batch "\
        keyword decoration:dim_inactive true;\
        keyword decoration:dim_strength 0.62;\
        keyword decoration:dim_around 0.35;\
        keyword decoration:inactive_opacity 0.82;\
        keyword decoration:blur:passes 2;\
        keyword general:border_size 1;\
        keyword animation borderangle,0" >/dev/null

    : > "$STATE"
    notify "Фокус-режим" "Только активное окно. Повтор — выключить."
}

disable() {
    hyprctl --batch "\
        keyword decoration:dim_inactive true;\
        keyword decoration:dim_strength 0.08;\
        keyword decoration:dim_around 0.4;\
        keyword decoration:inactive_opacity 0.94;\
        keyword decoration:blur:passes 3;\
        keyword general:border_size 2;\
        keyword animation borderangle,1,60,linear,loop" >/dev/null

    rm -f "$STATE"
    notify "Фокус-режим" "Выключен"
}

case "${1:-toggle}" in
    on)  enable ;;
    off) disable ;;
    status) [ -e "$STATE" ] && echo on || echo off ;;
    *)   [ -e "$STATE" ] && disable || enable ;;
esac
