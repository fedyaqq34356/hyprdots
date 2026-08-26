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

# Which lock to use. The Quickshell lock draws the handwritten clock, the wave
# password field and the now-playing card; hyprlock cannot. It is opt-in
# because a lock screen is the one component where a bug locks you out: if
# quickshell dies while the session is locked, the compositor keeps the screen
# locked with nothing drawn on it, and the way back is a TTY.
#
#   echo qs       > ~/.config/hypr/lock-choice   use the Quickshell lock
#   echo hyprlock > ~/.config/hypr/lock-choice   use hyprlock (default)
#
# `lock.sh qs` and `lock.sh hyprlock` override the file for one run.
CHOICE_FILE="$CONFIG_DIR/lock-choice"
choice=$(cat "$CHOICE_FILE" 2>/dev/null || echo hyprlock)

case "${1:-}" in
    qs|hyprlock) choice="$1"; shift ;;
esac

if [[ "$choice" == "qs" ]]; then
    # Backdrop for the Quickshell lock: the desktop as it is, blurred. Has to
    # be taken before anything covers the screen.
    "$CONFIG_DIR/scripts/lock-prepare.sh" 2>/dev/null

    if command -v qs >/dev/null 2>&1 && qs -c f ipc call lock lock >/dev/null 2>&1; then
        exit 0
    fi

    # Shell not running, or the lock refused: fall through to hyprlock rather
    # than leaving the session unlocked.
    notify-send -u critical "Экран блокировки" \
        "Quickshell не ответил, блокирую через hyprlock" 2>/dev/null
fi

exec hyprlock "$@"
