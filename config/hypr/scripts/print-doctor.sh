#!/usr/bin/env bash
set -u

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

say() { (( QUIET )) || printf '%s\n' "$*"; }

REPAIR=/usr/local/bin/print-repair

DEV=""
for d in /dev/usb/lp*; do
    [[ -e "$d" ]] && { DEV="$d"; break; }
done

if [[ -z "$DEV" ]]; then
    say "принтер не виден на шине: выключен или кабель не вставлен"
    [[ -x "$REPAIR" ]] && sudo -n "$REPAIR" modprobe >/dev/null 2>&1
    exit 1
fi

if [[ ! -x "$REPAIR" ]]; then
    say "хелпер $REPAIR не установлен — чинить нечем"
    exit 2
fi

CCPD_PID=$(pidof ccpd 2>/dev/null | awk '{print $1}')
NEED_RESTART=0

if [[ -z "$CCPD_PID" ]]; then
    say "демон ccpd не запущен"
    NEED_RESTART=1
else
    dev_age=$(stat -c %Z "$DEV" 2>/dev/null || echo 0)
    pid_age=$(stat -c %Z "/proc/$CCPD_PID" 2>/dev/null || echo 0)
    if (( pid_age < dev_age )); then
        say "ccpd старше устройства — держит отвалившийся узел"
        NEED_RESTART=1
    fi
fi

if (( NEED_RESTART )); then
    sudo -n "$REPAIR" ccpd || { say "не удалось перезапустить ccpd"; exit 3; }
    say "ccpd перезапущен"
fi

while IFS= read -r line; do
    [[ "$line" =~ ^printer\ ([^ ]+)\ .*(disabled|not\ accepting) ]] || continue
    name="${BASH_REMATCH[1]}"
    say "снимаю паузу с $name"
    sudo -n "$REPAIR" enable "$name" || say "не удалось разбудить $name"
done < <(lpstat -p -a 2>/dev/null)

say "печать готова"
exit 0
