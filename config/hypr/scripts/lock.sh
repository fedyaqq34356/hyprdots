#!/usr/bin/env bash
set -u

CONFIG_DIR="$HOME/.config/hypr"
COLORS="$CONFIG_DIR/config/lock-colors.conf"
CURRENT="$CONFIG_DIR/current-wallpaper"

wallpaper=""
[[ -f "$CURRENT" ]] && wallpaper=$(<"$CURRENT")

if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
    if [[ ! -f "$COLORS" || "$wallpaper" -nt "$COLORS" ]] \
        || ! grep -qxF "\$wallpaper = $wallpaper" "$COLORS" 2>/dev/null; then
        matugen image "$wallpaper" --mode dark --type scheme-content --prefer saturation >/dev/null 2>&1
    fi
fi

if [[ ! -f "$COLORS" ]]; then
    mkdir -p "$(dirname "$COLORS")"
    cat > "$COLORS" <<EOF
\$wallpaper = ${wallpaper:-}
\$primary = rgb(c8b6ff)
\$on_primary = rgb(1b1b1f)
\$secondary = rgb(e0c3a0)
\$tertiary = rgb(a8d5ba)
\$error = rgb(ffb4ab)
\$surface = rgba(14141ab3)
\$surface_glass = rgba(e6e0e926)
\$on_surface = rgb(e6e0e9)
\$on_surface_dim = rgba(cac4d0cc)
\$on_surface_faint = rgba(cac4d080)
\$outline = rgba(938f9959)
\$shadow = rgba(0000006e)
\$placeholder = <span foreground="##cac4d099">  password</span>
EOF
fi

CHOICE_FILE="$CONFIG_DIR/lock-choice"
choice=$(cat "$CHOICE_FILE" 2>/dev/null || echo hyprlock)

case "${1:-}" in
    qs|hyprlock) choice="$1"; shift ;;
esac

RUN="${XDG_RUNTIME_DIR:-/tmp}"
FLAG="$RUN/session-locked"
MISSED="$RUN/missed-notifications"

lock_begin() {
    echo 0 > "$MISSED"
    echo 1 > "$FLAG"
}

lock_end() {
    echo 0 > "$FLAG"
    echo 0 > "$MISSED"
    command -v qs >/dev/null 2>&1 && qs -c f ipc call curtain up >/dev/null 2>&1
}

if [[ "$choice" == "qs" ]]; then
    "$CONFIG_DIR/scripts/lock-prepare.sh" 2>/dev/null

    if command -v qs >/dev/null 2>&1; then
        lock_begin
        if qs -c f ipc call lock lock >/dev/null 2>&1; then
            exit 0
        fi
        echo 0 > "$FLAG"
    fi

    notify-send -u critical "Lock screen" \
        "Quickshell did not answer, locking with hyprlock" 2>/dev/null
fi

"$CONFIG_DIR/scripts/lock-prepare.sh" 2>/dev/null
lock_begin
hyprlock "$@"
status=$?
lock_end
exit "$status"
