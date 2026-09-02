#!/usr/bin/env bash

set -uo pipefail

OUTDIR="${RECORD_DIR:-$HOME/Videos}"
NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
STATE="${XDG_RUNTIME_DIR:-/tmp}/recording.state"

notify() { bash "$NOTIFY" "$@" >/dev/null 2>&1; }

if pgrep -x wf-recorder >/dev/null; then
    FILE=$(cut -d' ' -f2- < "$STATE" 2>/dev/null)
    pkill -INT -x wf-recorder
    rm -f "$STATE"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -x wf-recorder >/dev/null || break
        sleep 0.2
    done
    if [ -n "${FILE:-}" ] && [ -s "$FILE" ]; then
        printf '%s' "$FILE" | wl-copy
        SIZE=$(du -h "$FILE" | cut -f1)
        notify "Recording" "$(basename "$FILE") · $SIZE" -t 4000 -a record -r 9993
    else
        notify "Recording" "Stopped" -t 3000 -a record -r 9993
    fi
    exit 0
fi

MODE="screen"
AUDIO=1
for arg in "$@"; do
    case "$arg" in
        region)     MODE="region" ;;
        screen)     MODE="screen" ;;
        --mic)      AUDIO=2 ;;
        --no-audio) AUDIO=0 ;;
    esac
done

mkdir -p "$OUTDIR"
FILE="$OUTDIR/recording-$(date +%Y-%m-%d_%H-%M-%S).mp4"

ARGS=(-f "$FILE" -c libx264 -p preset=veryfast -p crf=22 --pixel-format yuv420p)

if [ "$MODE" = region ]; then
    GEOM=$(slurp -d -b 00000055 -c efbd90ff -s efbd9022 -w 2) || exit 1
    [ -z "$GEOM" ] && exit 1
    ARGS+=(-g "$GEOM")
else
    MONITOR=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
    ARGS+=(-o "${MONITOR:-eDP-1}")
fi

case "$AUDIO" in
    1) SINK=$(pactl get-default-sink 2>/dev/null)
       [ -n "$SINK" ] && ARGS+=(--audio="$SINK.monitor") || AUDIO=0 ;;
    2) SOURCE=$(pactl get-default-source 2>/dev/null)
       [ -n "$SOURCE" ] && ARGS+=(--audio="$SOURCE") || AUDIO=0 ;;
esac

wf-recorder "${ARGS[@]}" >/dev/null 2>&1 &
sleep 0.6

if ! pgrep -x wf-recorder >/dev/null; then
    notify "Recording" "Could not start wf-recorder" -u critical -t 4000 -a record
    exit 1
fi

printf '%s %s\n' "$(date +%s)" "$FILE" > "$STATE"
case "$AUDIO" in
    1) SOUND=" + sound" ;;
    2) SOUND=" + microphone" ;;
    *) SOUND="" ;;
esac
notify "Recording" "$([ "$MODE" = region ] && echo "Region" || echo "Screen")$SOUND" \
       -t 2000 -a record -r 9993
