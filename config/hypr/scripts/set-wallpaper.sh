#!/usr/bin/env bash
set -u

WALLPAPER="${1:-}"
NO_THEME="${2:-}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "set-wallpaper: no such file: $WALLPAPER" >&2
    exit 1
fi

monitors() {
    hyprctl monitors -j 2>/dev/null \
        | python3 -c "import sys,json;[print(m['name']) for m in json.load(sys.stdin) if not m.get('disabled')]" 2>/dev/null
}

MONS=$(monitors)
[[ -z "$MONS" ]] && MONS=""

PREV=""
[[ -f "$HOME/.config/hypr/current-wallpaper" ]] && PREV=$(<"$HOME/.config/hypr/current-wallpaper")

if pgrep -x awww-daemon >/dev/null 2>&1; then
    awww img "$WALLPAPER" \
        --transition-type fade --transition-duration 1.4 \
        --transition-fps 60 --transition-bezier .25,1,.3,1 >/dev/null 2>&1
else
    hyprctl hyprpaper preload "$WALLPAPER" >/dev/null 2>&1
    for _ in $(seq 1 40); do
        hyprctl hyprpaper listloaded 2>/dev/null | grep -qxF "$WALLPAPER" && break
        sleep 0.05
    done

    if [[ -n "$MONS" ]]; then
        while IFS= read -r m; do
            [[ -n "$m" ]] && hyprctl hyprpaper wallpaper "$m,$WALLPAPER" >/dev/null 2>&1
        done <<< "$MONS"
    else
        hyprctl hyprpaper wallpaper ",$WALLPAPER" >/dev/null 2>&1
    fi

    if [[ -n "$PREV" && "$PREV" != "$WALLPAPER" ]]; then
        ( sleep 2; hyprctl hyprpaper unload "$PREV" >/dev/null 2>&1 ) &
    fi
fi

{
    if [[ -n "$MONS" ]]; then
        while IFS= read -r m; do
            [[ -z "$m" ]] && continue
            printf 'wallpaper {\n    monitor = %s\n    path = %s\n    fit_mode = cover\n}\n' \
                   "$m" "$WALLPAPER"
        done <<< "$MONS"
    else
        printf 'wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "$WALLPAPER"
    fi
} > "$HOME/.config/hypr/hyprpaper.conf"

echo "$WALLPAPER" > "$HOME/.config/hypr/current-wallpaper"

if [[ "$NO_THEME" != "--no-theme" ]]; then
    matugen image "$WALLPAPER" --mode dark --type scheme-content --prefer saturation >/dev/null 2>&1 &
fi
