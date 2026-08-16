#!/usr/bin/env bash
OUTDIR="$HOME/Videos"
NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"
mkdir -p "$OUTDIR"

if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    bash "$NOTIFY" "Запись" "Остановлена, сохранено в ~/Videos" -t 3000
else
    MONITOR=$(hyprctl monitors -j | python3 -c "import sys,json; m=[x for x in json.load(sys.stdin) if x['focused']]; print(m[0]['name'] if m else 'eDP-1')")
    OUTFILE="$OUTDIR/recording-$(date +%Y%m%d-%H%M%S).mp4"
    wf-recorder -o "$MONITOR" -f "$OUTFILE" &
    bash "$NOTIFY" "Запись" "Началась → $(basename "$OUTFILE")" -t 3000
fi
