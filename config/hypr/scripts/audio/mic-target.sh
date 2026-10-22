#!/bin/sh

[ -n "$1" ] || exit 1
DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
LEVEL="${1%\%}"
printf '%s' "$LEVEL" > "$DIR/mic-lock.target"

mkdir -p "$HOME/.local/state/hypr"
printf '%s' "$LEVEL" > "$HOME/.local/state/hypr/mic-level"

pactl set-source-volume @DEFAULT_SOURCE@ "${LEVEL}%"
