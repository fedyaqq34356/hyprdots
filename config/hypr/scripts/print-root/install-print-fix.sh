#!/bin/bash
set -eu

HERE=$(dirname "$(readlink -f "$0")")

install -o root -g root -m 0755 "$HERE/print-repair"        /usr/local/bin/print-repair
install -o root -g root -m 0644 "$HERE/60-capt-hotplug.rules" /etc/udev/rules.d/60-capt-hotplug.rules

install -o root -g root -m 0440 "$HERE/print-repair-sudoers" /etc/sudoers.d/print-repair
if ! visudo -c -f /etc/sudoers.d/print-repair >/dev/null; then
    rm -f /etc/sudoers.d/print-repair
    echo "правило sudo отклонено, откатил" >&2
    exit 1
fi

udevadm control --reload-rules
udevadm trigger --subsystem-match=usbmisc

/usr/local/bin/print-repair ccpd
for p in $(lpstat -p 2>/dev/null | awk '/^printer/ { print $2 }'); do
    cupsenable "$p" 2>/dev/null || true
    cupsaccept "$p" 2>/dev/null || true
done

echo "готово"
