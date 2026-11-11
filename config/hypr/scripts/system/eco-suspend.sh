#!/usr/bin/env bash

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/pc-eco"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/eco-suspend.pid"
GUARD="$HOME/.config/hypr/scripts/lock/idle-guard.sh"
CPU_MAX=12          # % total CPU load over the sample window
NET_MAX=150000      # bytes/s on all real interfaces (downloads, streams, sync)
RECHECK=60

log() { logger -t eco-suspend "$*" 2>/dev/null; }

cpu_sample() { awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat; }
net_sample() { awk -F'[: ]+' 'NR>2 && $2!="lo"{s+=$3+$11} END{print s+0}' /proc/net/dev; }

busy() {
    [ -e "$STATE" ] || { echo "eco off"; return 0; }
    islandd gaming 2>/dev/null && { echo "game"; return 0; }

    pgrep -x 'zoom|ZoomWebviewHost|zoom.real' >/dev/null && { echo "zoom"; return 0; }
    hyprctl clients -j 2>/dev/null | grep -qiE '"class": *"zoom|"title": *"Meet[^a-z]|"title": *"[^"]*Google Meet' \
        && { echo "meet"; return 0; }

    if loginctl list-inhibitors --no-legend 2>/dev/null | grep -qE '(^|[[:space:]])(sleep|idle)[^[:space:]]*[[:space:]].*block'; then
        echo "inhibitor"; return 0
    fi

    local r
    if r=$("$GUARD" check 2>/dev/null); then echo "$r"; return 0; fi

    read -r t1 i1 < <(cpu_sample); n1=$(net_sample)
    sleep 5
    read -r t2 i2 < <(cpu_sample); n2=$(net_sample)
    local dt=$((t2 - t1)) load=0 net=$(((n2 - n1) / 5))
    [ "$dt" -gt 0 ] && load=$((100 * (dt - (i2 - i1)) / dt))
    [ "$load" -ge "$CPU_MAX" ] && { echo "cpu ${load}%"; return 0; }
    [ "$net" -ge "$NET_MAX" ] && { echo "net ${net}B/s"; return 0; }

    return 1
}

loop() {
    while :; do
        if r=$(busy); then
            [ "$r" = "eco off" ] && exit 0
            log "skip: $r"
            sleep "$RECHECK"
            continue
        fi
        log "suspending"
        loginctl suspend
        exit 0
    done
}

stop() {
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
}

case "${1:-start}" in
    start)
        [ -e "$STATE" ] || exit 0
        stop
        loop &
        echo $! > "$PIDFILE"
        ;;
    stop) stop ;;
    check) if r=$(busy); then echo "busy: $r"; exit 1; else echo "idle, would suspend"; fi ;;
    *) echo "usage: $0 start|stop|check" >&2; exit 2 ;;
esac
