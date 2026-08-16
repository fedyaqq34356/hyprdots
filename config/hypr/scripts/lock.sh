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

exec hyprlock "$@"
