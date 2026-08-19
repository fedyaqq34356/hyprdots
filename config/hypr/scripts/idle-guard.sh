#!/usr/bin/env bash
# idle-guard.sh <lock|dpms-off>
#
# Runs the idle action only when nothing is worth keeping the screen alive for.
# Blockers: a fullscreen window, audio actually playing, an active screen
# recording, and any process named in the inhibit list.
#
#   ~/.config/hypr/idle-inhibit.list   one process name per line, # comments
#
# The list is personal and not tracked; idle-inhibit.list.example seeds it on
# first run.

set -uo pipefail

ACTION="${1:-lock}"
CONF="$HOME/.config/hypr"
LIST="$CONF/idle-inhibit.list"
[ -f "$LIST" ] || cp "$CONF/idle-inhibit.list.example" "$LIST" 2>/dev/null

blocked() {
    # a window is fullscreen on any workspace
    if hyprctl -j workspaces 2>/dev/null | grep -q '"hasfullscreen": true'; then
        echo "fullscreen"; return 0
    fi

    # something is really playing, not just holding the device open
    if pactl list short sink-inputs 2>/dev/null | grep -qv '^$'; then
        if pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"; then
            echo "audio"; return 0
        fi
    fi

    if pgrep -x wf-recorder >/dev/null; then
        echo "recording"; return 0
    fi

    if [ -f "$LIST" ]; then
        while IFS= read -r name; do
            name="${name%%#*}"
            name="$(echo "$name" | tr -d '[:space:]')"
            [ -z "$name" ] && continue
            # Match the process name, not the command line: a full-cmdline
            # search also hits this script and whatever shell spawned it.
            if pgrep -x -- "$name" >/dev/null 2>&1; then
                echo "$name"; return 0
            fi
        done < "$LIST"
    fi

    return 1
}

if REASON=$(blocked); then
    logger -t idle-guard "skipped $ACTION: $REASON" 2>/dev/null
    exit 0
fi

case "$ACTION" in
    lock)
        pidof hyprlock >/dev/null || "$CONF/scripts/lock.sh"
        ;;
    dpms-off)
        hyprctl dispatch dpms off
        ;;
    *)
        echo "usage: idle-guard.sh [lock|dpms-off]" >&2
        exit 2
        ;;
esac
