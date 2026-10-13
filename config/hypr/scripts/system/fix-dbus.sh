#!/bin/bash
for i in $(seq 1 20); do
    pid=$(pgrep -u "$(id -u)" -x 'quickshell|qs' | head -1)
    if [ -n "$pid" ]; then
        addr=$(tr '\0' '\n' < /proc/$pid/environ 2>/dev/null | grep ^DBUS_SESSION_BUS_ADDRESS= | head -1 | cut -d= -f2-)
        if [ -n "$addr" ]; then
            hyprctl setenv DBUS_SESSION_BUS_ADDRESS "$addr"
            exit 0
        fi
    fi
    sleep 0.5
done
