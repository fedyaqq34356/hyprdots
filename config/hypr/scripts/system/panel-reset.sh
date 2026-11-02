#!/bin/sh

MON="${1:-$(hyprctl -j monitors all | jq -r '[.[] | select(.name | startswith("eDP"))][0].name // empty')}"
MODE="${2:-$(hyprctl -j monitors all | jq -r --arg m "$MON" '.[] | select(.name == $m) | "\(.width)x\(.height)@\(.refreshRate),\(.x)x\(.y),\(.scale)"')}"
[ -n "$MON" ] && [ -n "$MODE" ] || exit 0

restore() {
    hyprdo keyword monitor "$MON,$MODE" >/dev/null 2>&1
    hyprdo dispatch dpms on >/dev/null 2>&1
}
trap restore EXIT INT TERM

hyprctl monitors all 2>/dev/null | grep -q "Monitor $MON" || exit 0

hyprdo keyword monitor "$MON,disable" >/dev/null 2>&1
sleep 2
