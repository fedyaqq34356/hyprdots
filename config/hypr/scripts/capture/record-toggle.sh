#!/usr/bin/env bash

set -uo pipefail

OUTDIR="${RECORD_DIR:-$HOME/Videos}"
NOTIFY="$HOME/.config/hypr/scripts/notify/dbus-notify.sh"
STATE="${XDG_RUNTIME_DIR:-/tmp}/recording.state"

TAB=$'\t'

notify() { bash "$NOTIFY" "$@" >/dev/null 2>&1; }

FIFO="${XDG_RUNTIME_DIR:-/tmp}/recording.fifo"
ENCODER_PID="${XDG_RUNTIME_DIR:-/tmp}/recording.encoder"
FFMPEG=/usr/bin/ffmpeg
GPU_FILTER="libplacebo=format=nv12:colorspace=bt709:color_primaries=bt709:color_trc=bt709:range=pc:dithering=-1:disable_linear=1:peak_detect=0"

encoder_alive() {
    local pid
    pid=$(cat "$ENCODER_PID" 2>/dev/null) || return 1
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

encoder_wait() {
    for _ in $(seq 1 50); do
        encoder_alive || break
        sleep 0.2
    done
    rm -f "$FIFO" "$ENCODER_PID"
}

if [ -f "$STATE" ] && ! pgrep -x wf-recorder >/dev/null; then
    rm -f "$STATE"
    encoder_wait
    case "${1:-}" in
        screen|region) : ;;
        *) notify "Recording" "Stopped unexpectedly" -t 3000 -a record -r 9993
           exit 0 ;;
    esac
fi

if pgrep -x wf-recorder >/dev/null; then
    FILE=$(cut -d"$TAB" -f3- < "$STATE" 2>/dev/null)
    pkill -INT -x wf-recorder
    rm -f "$STATE"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -x wf-recorder >/dev/null || break
        sleep 0.2
    done
    encoder_wait
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

ARGS=(-r 60)
CPU_ARGS=(-f "$FILE" -c libx264 -p preset=ultrafast -p crf=22 --pixel-format yuv420p)
GPU_ARGS=(-f "$FIFO" -c rawvideo --pixel-format bgr0 -m nut -C aac)

MONITOR=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
MONITOR="${MONITOR:-$(hyprctl -j monitors | jq -r '.[0].name')}"

if [ "$MODE" = region ]; then
    ACCENT=$(sed -n 's/^\$accent *= *rgb(\([0-9a-fA-F]\{6\}\)).*/\1/p' "$HOME/.config/hypr/config/colors.conf" 2>/dev/null | head -1)
    [ -n "$ACCENT" ] || ACCENT=ffffff
    GEOM=$(slurp -d -b 00000055 -c "${ACCENT}ff" -s "${ACCENT}22" -w 2) || exit 1
    [ -z "$GEOM" ] && exit 1
    ARGS+=(-g "$GEOM")
else
    ARGS+=(-o "$MONITOR")
fi

case "$AUDIO" in
    1) SINK=$(pactl get-default-sink 2>/dev/null)
       [ -n "$SINK" ] && ARGS+=(--audio="$SINK.monitor") || AUDIO=0 ;;
    2) SOURCE=$(pactl get-default-source 2>/dev/null)
       [ -n "$SOURCE" ] && ARGS+=(--audio="$SOURCE") || AUDIO=0 ;;
esac

vaapi_node() {
    local n drv
    for n in /sys/class/drm/renderD*; do
        drv=$(basename "$(readlink -f "$n/device/driver")" 2>/dev/null)
        case "$drv" in
            amdgpu|i915|xe) printf '/dev/dri/%s' "${n##*/}"; return 0 ;;
        esac
    done
    return 1
}

start_vaapi() {
    local node codec
    node=$(vaapi_node) || return 1
    case "${RECORD_CODEC:-h264}" in
        hevc|h265) codec=hevc_vaapi ;;
        av1)       codec=av1_vaapi ;;
        *)         codec=h264_vaapi ;;
    esac
    "$FFMPEG" -hide_banner -encoders 2>/dev/null | grep -q "$codec" || return 1
    nice -n 15 wf-recorder "${ARGS[@]}" -f "$FILE" -c "$codec" -d "$node" >/dev/null 2>&1 &
    sleep 0.8
    pgrep -x wf-recorder >/dev/null && return 0
    rm -f "$FILE"
    return 1
}

start_gpu() {
    "$FFMPEG" -hide_banner -encoders 2>/dev/null | grep h264_vulkan >/dev/null || return 1
    rm -f "$FIFO"
    mkfifo "$FIFO" || return 1
    nice -n 15 "$FFMPEG" -nostdin -v error -y \
        -init_hw_device vulkan=vk -filter_hw_device vk \
        -thread_queue_size 64 -f nut -i "$FIFO" \
        -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2:0:0,$GPU_FILTER" \
        -c:v h264_vulkan -qp 13 -c:a copy "$FILE" >/dev/null 2>&1 &
    echo $! > "$ENCODER_PID"
    nice -n 15 wf-recorder "${ARGS[@]}" "${GPU_ARGS[@]}" >/dev/null 2>&1 &
    sleep 0.6
    if encoder_alive && pgrep -x wf-recorder >/dev/null; then
        return 0
    fi
    pkill -x wf-recorder
    sleep 0.2
    pkill -KILL -x wf-recorder
    kill "$(cat "$ENCODER_PID" 2>/dev/null)" 2>/dev/null
    rm -f "$FIFO" "$ENCODER_PID" "$FILE"
    return 1
}

if ! start_vaapi && ! start_gpu; then
    nice -n 15 wf-recorder "${ARGS[@]}" "${CPU_ARGS[@]}" >/dev/null 2>&1 &
    sleep 0.6
fi

if ! pgrep -x wf-recorder >/dev/null; then
    notify "Recording" "Could not start wf-recorder" -u critical -t 4000 -a record
    exit 1
fi

printf '%s%s%s%s%s\n' "$(date +%s)" "$TAB" "$MONITOR" "$TAB" "$FILE" > "$STATE"
case "$AUDIO" in
    1) SOUND=" + sound" ;;
    2) SOUND=" + microphone" ;;
    *) SOUND="" ;;
esac
notify "Recording" "$([ "$MODE" = region ] && echo "Region" || echo "Screen")$SOUND" \
       -t 2000 -a record -r 9993
