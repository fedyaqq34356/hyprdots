#!/usr/bin/env bash
I="$HOME/.local/bin/islandd"
[[ -x "$I" ]] && exec -a "$0" "$I" mount
exec udiskie --no-tray --automount --notify
