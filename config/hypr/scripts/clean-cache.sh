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

# Freedesktop trash: drop everything deleted more than $TRASH_DAYS days ago.
# The deletion date lives in the .trashinfo file, not in the file's own mtime.
purge_trash() {
    local root="$1" cutoff="$2" info name when ts
    [[ -d "$root/files" ]] || return 0

    shopt -s nullglob
    for info in "$root"/info/*.trashinfo; do
        when=$(sed -n 's/^DeletionDate=//p' "$info" | head -1)
        ts=$(date -d "$when" +%s 2>/dev/null) || ts=$(stat -c %Y "$info")
        (( ts > cutoff )) && continue
        name=$(basename "$info" .trashinfo)
        rm -rf -- "$root/files/$name"
        rm -f -- "$info"
    done

    # Entries whose .trashinfo was lost: fall back to the file's own age.
    for name in "$root"/files/*; do
        [[ -e "$root/info/$(basename "$name").trashinfo" ]] && continue
        (( $(stat -c %Y "$name" 2>/dev/null || echo 0) > cutoff )) && continue
        rm -rf -- "$name"
    done
    shopt -u nullglob
}
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

TRASH_DAYS=${TRASH_DAYS:-30}
CUTOFF=$(( $(date +%s) - TRASH_DAYS * 86400 ))

say "${YLW}> корзина (старше ${TRASH_DAYS} дней)...${RST}"
for TRASH in ~/.local/share/Trash /mnt/*/.Trash-"$(id -u)" /run/media/"$USER"/*/.Trash-"$(id -u)"; do
    [[ -d "$TRASH/files" ]] || continue
    BEFORE=$(dir_size "$TRASH")
    purge_trash "$TRASH" "$CUTOFF"
    say "   ${TRASH}"
    freed "$BEFORE" "$(dir_size "$TRASH")"
done
say ""

say "${BLD}${GRN}Готово.${RST}"
if (( ! AUTO )); then
    say ""
    free -h | grep -E "^(Mem|Swap)"
    say ""
    read -n1 -rp "Нажмите любую клавишу..."
fi
