#!/usr/bin/env bash
set -u

RUN="${XDG_RUNTIME_DIR:-/tmp}"
FLAG="$RUN/session-locked"
COUNT="$RUN/missed-notifications"

[[ -f "$COUNT" ]] || echo 0 > "$COUNT"

dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" 2>/dev/null \
| while IFS= read -r line; do
    case "$line" in
        *"member=Notify"*) ;;
        *) continue ;;
    esac
    [[ "$(cat "$FLAG" 2>/dev/null)" == 1 ]] || continue
    n=$(cat "$COUNT" 2>/dev/null)
    [[ "$n" =~ ^[0-9]+$ ]] || n=0
    echo $((n + 1)) > "$COUNT"
done
