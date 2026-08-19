#!/usr/bin/env bash
# Drop the clipboard history and whatever is currently in the clipboard.
NOTIFY="$HOME/.config/hypr/scripts/dbus-notify.sh"

COUNT=$(cliphist list 2>/dev/null | wc -l)
cliphist wipe
wl-copy --clear
wl-copy --primary --clear 2>/dev/null

bash "$NOTIFY" "Буфер обмена" "История очищена ($COUNT записей)" -t 2500 -a clipboard >/dev/null 2>&1
