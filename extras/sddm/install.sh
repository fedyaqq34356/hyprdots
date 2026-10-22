#!/bin/sh
set -eu

[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }

SRC=$(cd "$(dirname "$0")" && pwd)
DEST=/usr/share/sddm/themes/f
CONF=/etc/sddm.conf.d/theme.conf
USR=${SUDO_USER:?run with sudo from your own user}
HOMEDIR=$(getent passwd "$USR" | cut -d: -f6)

WALL=$(cat "$HOMEDIR/.config/hypr/current-wallpaper" 2>/dev/null || true)
if [ -n "$WALL" ] && [ -f "$WALL" ]; then
    magick "$WALL" -resize '2560x1440^' "$SRC/assets/wall.png" 2>/dev/null || cp -f "$WALL" "$SRC/assets/wall.png"
fi

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$SRC/Main.qml" "$SRC/metadata.desktop" "$SRC/theme.conf" "$SRC/assets" "$DEST/"
chmod -R a+rX "$DEST"
echo "theme copied to $DEST"

mkdir -p /var/lib/f-sddm
chown "$USR": /var/lib/f-sddm
chmod 755 /var/lib/f-sddm
SYNC="$HOMEDIR/.config/hypr/scripts/wallpaper/sddm-sync.sh"
[ -x "$SYNC" ] && su "$USR" -c "HOME='$HOMEDIR' '$SYNC'" || true
echo "live folder: /var/lib/f-sddm"

mkdir -p /etc/sddm.conf.d
if [ -f "$CONF" ] && grep -q '^Current=' "$CONF"; then
    sed -i 's/^Current=.*/Current=f/' "$CONF"
else
    printf '[Theme]\nCurrent=f\n' >> "$CONF"
fi
echo "SDDM theme set to f (takes effect at next login screen)"
