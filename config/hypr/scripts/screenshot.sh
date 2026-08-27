#!/usr/bin/env bash

set -uo pipefail

MODE="${1:-region}"
OUTDIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
FILE="$OUTDIR/$(date +%Y-%m-%d_%H-%M-%S).png"

mkdir -p "$OUTDIR"

notify() { bash "$NOTIFY" "$@" >/dev/null 2>&1; }

have() { command -v "$1" >/dev/null 2>&1; }

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

scrub_meta() {
    [ -s "$1" ] || return 0
    if have exiftool; then
        exiftool -overwrite_original -all= "$1" >/dev/null 2>&1 && return 0
    fi
    if have magick; then
        magick "$1" -strip "$1" >/dev/null 2>&1
    fi
}

scan_secrets() {
    have tesseract || return 0
    text=$(tesseract "$1" - -l rus+eng 2>/dev/null) || return 0
    hits=$(printf '%s' "$text" | grep -oiE \
        'sk-ant-[a-z0-9_-]{8,}|ghp_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|[0-9]{8,10}:AA[A-Za-z0-9_-]{30,}|BEGIN [A-Z ]*PRIVATE KEY|/home/[a-z0-9_-]+/' \
        | sort -u | head -4)
    [ -z "$hits" ] && return 0
    notify "Скриншот: проверь содержимое" \
        "$(printf '%s' "$hits" | tr '\n' ' ')" -u critical -t 6000 -a screenshot
}

finish() {
    if [ ! -s "$FILE" ]; then
        rm -f "$FILE"
        exit 1
    fi
    scrub_meta "$FILE"
    wl-copy --type image/png < "$FILE"
    notify "Скриншот" "$(basename "$FILE")" -i "$FILE" -t 2500 -a screenshot -r 9992
    scan_secrets "$FILE" &
}

case "$MODE" in
    blur)
        GEOM=$(pick_region) || exit 1
        [ -z "$GEOM" ] && exit 1
        unfreeze
        grim -g "$GEOM" "$FILE" || exit 1

        if ! have magick; then
            notify "Скриншот" "Нужен imagemagick для замыливания" -t 3000
            finish
            exit 0
        fi

        BASE_X=${GEOM%%,*}
        REST=${GEOM#*,}
        BASE_Y=${REST%% *}

        while :; do
            freeze
            SUB=$(slurp -d 2>/dev/null) || { unfreeze; break; }
            unfreeze
            [ -z "$SUB" ] && break

            SX=${SUB%%,*}
            SR=${SUB#*,}
            SY=${SR%% *}
            SSIZE=${SUB##* }
            SW=${SSIZE%%x*}
            SH=${SSIZE##*x}

            RX=$((SX - BASE_X))
            RY=$((SY - BASE_Y))
            [ "$RX" -lt 0 ] && RX=0
            [ "$RY" -lt 0 ] && RY=0

            magick "$FILE" \
                \( +clone -crop "${SW}x${SH}+${RX}+${RY}" +repage \
                   -resize 6% -resize "${SW}x${SH}!" -blur 0x8 \) \
                -geometry "+${RX}+${RY}" -composite "$FILE" 2>/dev/null

            notify "Скриншот" "Область замылена — выбери ещё или Esc" \
                   -t 1800 -a screenshot -r 9993
        done

        finish
        ;;
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
    ocr)
        have tesseract || {
            notify "OCR" "Не установлен: pacman -S tesseract tesseract-data-rus" -t 4000
            exit 1
        }

        SLURP_STYLE=(-d -b 000000aa -c efbd90ff -s efbd9033 -w 3)

        GEOM=$(pick_region) || {
            notify "OCR" "Область не выбрана" -t 2000 -a screenshot -r 9993
            exit 1
        }
        if [ -z "$GEOM" ]; then
            notify "OCR" "Область не выбрана" -t 2000 -a screenshot -r 9993
            exit 1
        fi
        unfreeze

        SHOT=$(mktemp -t ocr-XXXXXX.png)
        trap 'unfreeze; rm -f "$SHOT"' EXIT

        grim -g "$GEOM" "$SHOT" || exit 1

        if have magick; then
            magick "$SHOT" -colorspace Gray -resize 300% -sharpen 0x1 "$SHOT" 2>/dev/null
        fi

        TEXT=$(tesseract "$SHOT" - -l "${OCR_LANG:-rus+eng}" 2>/dev/null)
        TEXT=$(printf '%s' "$TEXT" | sed -e 's/[[:space:]]*$//' -e '/./,$!d')

        if [ -z "$TEXT" ]; then
            notify "OCR" "Текст не распознан" -t 2500 -a screenshot -r 9993
            exit 1
        fi

        printf '%s' "$TEXT" | wl-copy
        PREVIEW=$(printf '%s' "$TEXT" | head -c 160)
        notify "OCR" "$PREVIEW" -t 4000 -a screenshot -r 9993
        ;;
    *)
        echo "usage: screenshot.sh [region|window|output|all|edit|color|ocr]" >&2
        exit 2
        ;;
esac
