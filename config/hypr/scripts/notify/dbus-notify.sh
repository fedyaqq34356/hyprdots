#!/usr/bin/env bash
for pid in $(pgrep -u "$(id -u)"); do
    addr=$(tr '\0' '\n' < /proc/$pid/environ 2>/dev/null | grep ^DBUS_SESSION_BUS_ADDRESS= | head -1)
    if [ -n "$addr" ]; then
        export "${addr?}"
        break
    fi
done
dunstify "$@"
