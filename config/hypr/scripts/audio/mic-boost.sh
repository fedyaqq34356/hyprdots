#!/bin/sh

DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE="$DIR/mic-boost.state"
PIDF="$DIR/mic-boost.pid"
TARGET_FILE="$DIR/mic-lock.target"
PERSIST_FILE="$HOME/.local/state/hypr/mic-level"
CHAIN="$(dirname "$(readlink -f "$0")")/mic-boost-chain.conf"
RAW=alsa_input.usb-3142_FIFINE_Microphone-00.mono-fallback
NODE=mic_boost
RAW_FALLBACK="${MIC_BOOST_LEVEL:-400}"
CARD=Microphone
CTL=Mic

level() {
    l=$(cat "$PERSIST_FILE" 2>/dev/null)
    case "$l" in ''|*[!0-9]*) l=100 ;; esac
    echo "$l"
}

note() {
    notify-send -a mic-boost -t 1500 -i "$1" "Микрофон" "$2"
}

if [ -f "$STATE" ]; then
    read -r hw lvl src < "$STATE"
    rm -f "$STATE"
    [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
    rm -f "$PIDF"
    case "$lvl" in ''|*[!0-9]*) lvl=$(level) ;; esac
    printf '%s' "$lvl" > "$TARGET_FILE"
    printf '%s' "$lvl" > "$PERSIST_FILE"
    [ -n "$hw" ] && amixer -q -c "$CARD" sset "$CTL" "$hw" 2>/dev/null
    [ -n "$src" ] && [ "$src" != "$NODE" ] && pactl set-default-source "$src"
    pactl set-source-volume "$RAW" "${lvl}%" 2>/dev/null
    pactl set-source-volume @DEFAULT_SOURCE@ "${lvl}%"
    note audio-input-microphone "Обычный режим · ${lvl}%"
    exit 0
fi

hw=$(amixer -c "$CARD" sget "$CTL" 2>/dev/null | sed -n 's/.*Capture \([0-9][0-9]*\) \[.*/\1/p' | head -1)
src=$(pactl get-default-source)
printf '%s %s %s' "$hw" "$(level)" "$src" > "$STATE"

setsid -f sh -c 'echo $$ > "$1"; exec pipewire -c "$2"' _ "$PIDF" "$CHAIN" >/dev/null 2>&1
i=0
until pactl list short sources | grep -q "	$NODE	"; do
    i=$((i + 1))
    [ "$i" -gt 30 ] && break
    sleep 0.1
done

if pactl list short sources | grep -q "	$NODE	"; then
    printf '100' > "$TARGET_FILE"
    pactl set-source-mute "$RAW" 0
    pactl set-source-volume "$RAW" 100%
    pactl set-default-source "$NODE"
    pactl set-source-volume "$NODE" 100%
    note audio-input-microphone-high "BOOST · максимум"
else
    [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null
    rm -f "$PIDF"
    amixer -q -c "$CARD" sset "$CTL" 100% unmute 2>/dev/null
    printf '%s' "$RAW_FALLBACK" > "$TARGET_FILE"
    pactl set-source-mute @DEFAULT_SOURCE@ 0
    pactl set-source-volume @DEFAULT_SOURCE@ "${RAW_FALLBACK}%"
    note audio-input-microphone-high "BOOST · ${RAW_FALLBACK}% (нет swh-plugins)"
fi
