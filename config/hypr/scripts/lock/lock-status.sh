#!/usr/bin/env bash
set -u

case "${1:-}" in
uptime)
    up=$(uptime -p 2>/dev/null | sed 's/^up //')
    printf '󰅐  %s\n' "${up:-online}"
    ;;
power)
    bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
    state=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
    if [[ -z "$bat" ]]; then
        printf '󰚥  ac\n'
        exit 0
    fi
    case "$state" in
    Charging) icon="󰂄" ;;
    Full) icon="󰁹" ;;
    *)
        if   ((bat >= 80)); then icon="󰂁"
        elif ((bat >= 60)); then icon="󰁿"
        elif ((bat >= 40)); then icon="󰁽"
        elif ((bat >= 20)); then icon="󰁻"
        else icon="󰁺"
        fi
        ;;
    esac
    printf '%s  %s%%\n' "$icon" "$bat"
    ;;
*)
    exit 1
    ;;
esac
