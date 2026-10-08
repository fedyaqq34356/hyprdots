#!/usr/bin/env bash
set -u

img="${1:-}"; theme="${2:-1}"; delay="${3:-6000}"
setter="$HOME/.config/hypr/scripts/set-wallpaper.sh"
current="$HOME/.config/hypr/current-wallpaper"

[[ -f "$img" ]] || { echo "gtavi-wallpaper: missing $img" >&2; exit 1; }
if [[ -f "$current" && "$(<"$current")" == "$img" ]]; then
    echo "gtavi-wallpaper: already current"
    exit 0
fi

if [[ -x "$setter" ]]; then
    "$setter" "$img" --no-theme || { echo "gtavi-wallpaper: set-wallpaper.sh failed" >&2; exit 1; }
elif pgrep -x awww-daemon >/dev/null; then
    awww img "$img" --transition-type fade --transition-duration 1.4 --transition-fps 60 \
        || exit 1
    echo "$img" > "$current"
else
    echo "gtavi-wallpaper: no wallpaper backend available" >&2
    exit 1
fi

if [[ "$theme" == 1 ]] && command -v matugen >/dev/null; then
    sleep "$(awk -v d="$delay" 'BEGIN { printf "%.3f", d / 1000 }')"
    [[ "$(<"$current")" == "$img" ]] || exit 0
    nice -n 10 matugen image "$img" --mode dark --type scheme-content --prefer saturation >/dev/null 2>&1
fi
exit 0
