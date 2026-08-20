#!/bin/sh

[ -n "$1" ] || exit 1
DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
printf '%s' "${1%\%}" > "$DIR/mic-lock.target"
