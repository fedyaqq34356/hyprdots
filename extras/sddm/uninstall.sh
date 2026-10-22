#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }
if [ -d /usr/share/sddm/themes/gtavi ]; then
    sed -i 's/^Current=.*/Current=gtavi/' /etc/sddm.conf.d/theme.conf
else
    sed -i '/^Current=f$/d' /etc/sddm.conf.d/theme.conf
fi
rm -rf /usr/share/sddm/themes/f /var/lib/f-sddm
echo "SDDM theme f removed"
