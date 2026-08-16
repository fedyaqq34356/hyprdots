#!/usr/bin/env bash

set -u

AUTO=0
[[ "${1:-}" == "--auto" ]] && AUTO=1

if (( AUTO )); then
    renice -n 19 $$ >/dev/null 2>&1
    ionice -c3 -p $$ >/dev/null 2>&1
    RED='' GRN='' YLW='' CYN='' BLD='' RST=''
else
    RED='\033[0;31m' GRN='\033[0;32m' YLW='\033[1;33m'
    CYN='\033[0;36m' BLD='\033[1m' RST='\033[0m'
fi

dir_size() { du -sh "$1" 2>/dev/null | cut -f1; }
freed()    { echo -e "${GRN}  освобождено: ${1:-0} -> ${2:-0}${RST}"; }
say()      { echo -e "$@"; }

say ""
say "${BLD}${CYN}=== ОЧИСТКА КЭША $(date '+%F %T') ===${RST}"
say ""

if (( ! AUTO )); then
    say "${YLW}> pacman кэш...${RST}"
    BEFORE=$(dir_size /var/cache/pacman/pkg)
    sudo paccache -rk1 2>&1 | grep -E "disk space|removed|error" || true
    sudo paccache -ruk0 2>&1 | grep -E "disk space|removed|error" || true
    freed "$BEFORE" "$(dir_size /var/cache/pacman/pkg)"
    say ""
fi

say "${YLW}> chrome кэш...${RST}"
if pgrep -x chrome >/dev/null 2>&1; then
    say "   chrome запущен — пропуск (закрой и запусти снова)"
else
    BEFORE=$(dir_size ~/.cache/google-chrome)
    rm -rf ~/.cache/google-chrome
    freed "$BEFORE" 0
fi
say ""

say "${YLW}> spotify кэш...${RST}"
if pgrep -x spotify >/dev/null 2>&1; then
    say "   spotify запущен — пропуск"
else
    BEFORE=$(dir_size ~/.cache/spotify)
    rm -rf ~/.cache/spotify
    freed "$BEFORE" 0
fi
say ""

say "${YLW}> yay кэш сборок...${RST}"
BEFORE=$(dir_size ~/.cache/yay)
if [[ -d ~/.cache/yay ]]; then
    rm -rf ~/.cache/yay/*/
    freed "${BEFORE:-0}" "$(dir_size ~/.cache/yay)"
else
    say "   уже пусто"
fi
say ""

say "${YLW}> миниатюры...${RST}"
BEFORE=$(dir_size ~/.cache/thumbnails)
rm -rf ~/.cache/thumbnails
mkdir -p ~/.cache/thumbnails
freed "$BEFORE" 0
say ""

say "${YLW}> pip кэш...${RST}"
BEFORE=$(dir_size ~/.cache/pip)
rm -rf ~/.cache/pip
freed "$BEFORE" 0
say ""

say "${BLD}${GRN}Готово.${RST}"
if (( ! AUTO )); then
    say ""
    free -h | grep -E "^(Mem|Swap)"
    say ""
    read -n1 -rp "Нажмите любую клавишу..."
fi
