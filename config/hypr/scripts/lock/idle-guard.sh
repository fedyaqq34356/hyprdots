#!/usr/bin/env bash

set -uo pipefail

ACTION="${1:-lock}"
CONF="$HOME/.config/hypr"
LIST="$CONF/idle-inhibit.list"
[ -f "$LIST" ] || cp "$CONF/idle-inhibit.list.example" "$LIST" 2>/dev/null

blocked() {
    if [ -e "${XDG_RUNTIME_DIR:-/tmp}/dnd-mode" ]; then
        echo "dnd"; return 0
    fi

    if command -v playerctl >/dev/null 2>&1; then
        if playerctl -a status 2>/dev/null | grep -q '^Playing$'; then
            echo "player"; return 0
        fi
    fi

    if hyprctl -j workspaces 2>/dev/null | grep -q '"hasfullscreen": true'; then
        echo "fullscreen"; return 0
    fi

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
