#!/bin/sh

OUT="$HOME/.cache/notify-trace.log"
printf '\n===== сессия начата %s =====\n' "$(date '+%F %T')" >> "$OUT"

dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null \
| while read -r line; do
    printf '%s %s\n' "$(date '+%T')" "$line" >> "$OUT"
done
