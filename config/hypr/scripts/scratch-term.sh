#!/usr/bin/env bash

SCRATCH_CLASS="kitty-scratch"
SPECIAL_WS="scratch-term"

if hyprctl clients -j | python3 -c "import sys,json; clients=json.load(sys.stdin); exit(0 if any(c['class']=='$SCRATCH_CLASS' for c in clients) else 1)" 2>/dev/null; then
    hyprctl dispatch togglespecialworkspace "$SPECIAL_WS"
else
    hyprctl dispatch exec "[workspace special:$SPECIAL_WS silent] kitty --class $SCRATCH_CLASS"
fi
