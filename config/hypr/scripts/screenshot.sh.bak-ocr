#!/usr/bin/env bash
# screenshot.sh [region|window|output|all|edit|color] [--no-edit]
#
#   region  select an area with the mouse            (default)
#   window  pick one window, snapped to its geometry
#   output  the monitor under the cursor
#   all     every connected monitor at once
#   edit    region, then open the annotation editor
#   color   pick a colour under the cursor, copy the hex
#
# Every shot lands in ~/Pictures/Screenshots and in the clipboard.

set -uo pipefail

MODE="${1:-region}"
OUTDIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
FILE="$OUTDIR/$(date +%Y-%m-%d_%H-%M-%S).png"

mkdir -p "$OUTDIR"

notify() { bash "$NOTIFY" "$@" >/dev/null 2>&1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Freeze the screen so animations and menus stay put while selecting.
FREEZE_PID=""
freeze() {
    have hyprpicker || return 0
    hyprpicker -r -z >/dev/null 2>&1 &
    FREEZE_PID=$!
    sleep 0.12
}
unfreeze() {
    [ -n "$FREEZE_PID" ] && kill "$FREEZE_PID" 2>/dev/null
    FREEZE_PID=""
}
trap unfreeze EXIT

SLURP_STYLE=(-d -b 00000055 -c efbd90ff -s efbd9022 -w 2)

pick_region() {
    freeze
    slurp "${SLURP_STYLE[@]}"
}

pick_window() {
    local visible
    visible=$(hyprctl -j monitors | jq -c '[.[].activeWorkspace.id]')
    freeze
    hyprctl -j clients \
        | jq -r --argjson ws "$visible" '
            .[] | select(.mapped and (.hidden | not) and (.workspace.id as $i | $ws | index($i)))
                | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
        | slurp "${SLURP_STYLE[@]}" -r
}

pick_output() {
    hyprctl -j monitors | jq -r '.[] | select(.focused) | "\(.x),\(.y) \(.width/.scale|floor)x\(.height/.scale|floor)"'
}

finish() {
    if [ ! -s "$FILE" ]; then
        rm -f "$FILE"
        exit 1
    fi
    wl-copy --type image/png < "$FILE"
    notify "Скриншот" "$(basename "$FILE")" -i "$FILE" -t 2500 -a screenshot -r 9992
}

case "$MODE" in
    region|edit)
        GEOM=$(pick_region) || exit 1
        [ -z "$GEOM" ] && exit 1
        unfreeze
        grim -g "$GEOM" "$FILE" || exit 1
        if [ "$MODE" = edit ]; then
            if have satty; then
                satty --filename "$FILE" --output-filename "$FILE" --early-exit --copy-command wl-copy
            elif have swappy; then
                swappy -f "$FILE" -o "$FILE"
            else
                notify "Скриншот" "Редактор не установлен: pacman -S satty" -t 3000
            fi
        fi
        finish
        ;;
    window)
        GEOM=$(pick_window) || exit 1
        [ -z "$GEOM" ] && exit 1
        unfreeze
        grim -g "$GEOM" "$FILE" || exit 1
        finish
        ;;
    output)
        GEOM=$(pick_output)
        [ -z "$GEOM" ] && exit 1
        grim -g "$GEOM" "$FILE" || exit 1
        finish
        ;;
    all)
        grim "$FILE" || exit 1
        finish
        ;;
    color)
        if have hyprpicker; then
            HEX=$(hyprpicker -a -f hex)
        else
            # No hyprpicker: pick a single point and read the pixel out of grim.
            POINT=$(slurp -p -b 00000000) || exit 1
            [ -z "$POINT" ] && exit 1
            HEX=$(grim -g "$POINT" -t ppm - \
                  | magick - -format '#%[hex:p{0,0}]' info:)
            HEX=${HEX:0:7}
            [ -n "$HEX" ] && printf '%s' "$HEX" | wl-copy
        fi
        [ -z "$HEX" ] && exit 1
        SWATCH=$(mktemp -t swatch-XXXX.png)
        magick -size 96x96 "xc:$HEX" "$SWATCH" 2>/dev/null
        notify "Цвет" "$HEX скопирован" -i "$SWATCH" -t 3000 -a screenshot
        (sleep 6; rm -f "$SWATCH") >/dev/null 2>&1 &
        ;;
    *)
        echo "usage: screenshot.sh [region|window|output|all|edit|color]" >&2
        exit 2
        ;;
esac
