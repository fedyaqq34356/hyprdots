#!/bin/sh

SRC="@DEFAULT_SOURCE@"
DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
TARGET_FILE="$DIR/mic-lock.target"
PERSIST_FILE="$HOME/.config/hypr/mic-level"

saved=$(cat "$PERSIST_FILE" 2>/dev/null)
case "$saved" in
    ''|*[!0-9]*) saved=100 ;;
esac
DEFAULT_LEVEL="${MIC_LOCK_LEVEL:-$saved}"

[ -f "$TARGET_FILE" ] || printf '%s' "$DEFAULT_LEVEL" > "$TARGET_FILE"

target() {
    t=$(cat "$TARGET_FILE" 2>/dev/null)
    case "$t" in
        ''|*[!0-9]*) t="$DEFAULT_LEVEL" ;;
    esac
    echo "$t"
}

pactl set-source-volume "$SRC" "$(target)%"
pactl set-source-mute "$SRC" 0

stdbuf -oL pactl subscribe 2>/dev/null | while read -r line; do
    case "$line" in
        *"'change'"*"on source"*)
            want=$(target)
            cur=$(pactl get-source-volume "$SRC" 2>/dev/null | grep -o '[0-9]\+%' | head -1)
            [ "$cur" = "${want}%" ] || pactl set-source-volume "$SRC" "${want}%"
            ;;
    esac
done
