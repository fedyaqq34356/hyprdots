#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.config/rosa"
[[ -d "$STATE_DIR" ]] || STATE_DIR="$HOME/.config/hyprdots"
SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)
TRASH="$HOME/.config/rosa-removed-$STAMP"

DRY_RUN=0
ASSUME_YES=0
SYSTEM=0

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'
YELLOW=$'\e[33m'; BLUE=$'\e[34m'; RESET=$'\e[0m'

log()  { printf '%s::%s %s\n' "$BLUE$BOLD" "$RESET$BOLD" "$1$RESET"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
die()  { printf '%serror:%s %s\n' "$RED$BOLD" "$RESET" "$1" >&2; exit 1; }
run()  { if ((DRY_RUN)); then printf '  %s$ %s%s\n' "$DIM" "$*" "$RESET"; else "$@"; fi; }

usage() {
    cat <<EOF
${BOLD}usage:${RESET} uninstall.sh [options]

  Removes every file install.sh put into your home directory and puts back
  the configuration you had before the first install. Removed files are
  moved to ~/.config/rosa-removed-<date>, nothing is deleted outright.

  --system      also remove the root helpers install.sh added
                (sudoers rules, /usr/local/bin helpers, zram, amdgpu KMS drop-in)
  --dry-run     print every action without touching the system
  -y, --yes     do not ask for confirmation
  -h, --help    show this help

  Packages are left installed: remove the ones you do not need with pacman -Rns.
EOF
}

while (($#)); do
    case "$1" in
    --system) SYSTEM=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
    esac
    shift
done

[[ $EUID -ne 0 ]] || die "run as a normal user, not as root"

confirm() {
    ((ASSUME_YES)) && return 0
    printf '%s' "  continue? [y/N] "
    read -r reply </dev/tty || reply=n
    [[ "$reply" =~ ^[Yy]$ ]]
}

collect_from_tree() {
    local src="$1" dst="$2" file
    [[ -d "$src" ]] || return 0
    while IFS= read -r -d '' file; do
        printf '%s\n' "${dst:+$dst/}${file#"$src"/}"
    done < <(find "$src" -type f -print0)
}

installed_files() {
    if [[ -s "$STATE_DIR/installed.list" ]]; then
        cat "$STATE_DIR/installed.list"
        return
    fi
    [[ -d "$SRC_DIR/config" ]] || die "no install record in $STATE_DIR and no repository next to this script"
    {
        collect_from_tree "$SRC_DIR/config" .config
        collect_from_tree "$SRC_DIR/home" ""
        collect_from_tree "$SRC_DIR/bin" .local/bin
        collect_from_tree "$SRC_DIR/config/serezha/applications" .local/share/applications
        collect_from_tree "$SRC_DIR/extras/pulse-elite" ""
    } | sort -u
}

built_files() {
    printf '%s\n' .local/bin/islandd .local/bin/serezha-wsbar .local/bin/serezha-mountd
}

origin_backup() {
    local origin=""
    [[ -f "$STATE_DIR/origin-backup" ]] && origin=$(<"$STATE_DIR/origin-backup")
    if [[ -z "$origin" ]]; then
        origin=$(find "$HOME/.config" -maxdepth 1 -type d -name 'dotfiles-backup-*' 2>/dev/null | sort | head -n1)
    fi
    [[ "$origin" != none && -d "$origin" ]] && printf '%s\n' "$origin"
    return 0
}

mapfile -t FILES < <({ installed_files; built_files; } | sort -u)
ORIGIN=$(origin_backup)
present=0
for rel in "${FILES[@]}"; do
    [[ -e "$HOME/$rel" || -L "$HOME/$rel" ]] && present=$((present + 1))
done

RESTORE="nothing to restore (no backup from before the first install)"
[[ -n "$ORIGIN" ]] && RESTORE="${ORIGIN/#$HOME/\~}"

cat <<EOF
${BOLD}Hyprland desktop — uninstall${RESET}
  files       $present installed files will be moved to ${TRASH/#$HOME/\~}
  restore     $RESTORE
  system      $( ((SYSTEM)) && echo "root helpers are removed too" || echo "root helpers kept (add --system to remove them)")
  packages    kept
EOF
confirm || die "aborted"

log "Removing the installed files"
for rel in "${FILES[@]}"; do
    target="$HOME/$rel"
    [[ -e "$target" || -L "$target" ]] || continue
    run mkdir -p "$TRASH/$(dirname "$rel")"
    run mv "$target" "$TRASH/$rel"
    ((DRY_RUN)) || rmdir -p --ignore-fail-on-non-empty "$(dirname "$target")" 2>/dev/null || true
done
ok "$present files moved to ${TRASH/#$HOME/\~}"

if [[ -n "$ORIGIN" ]]; then
    log "Restoring the configuration from before the first install"
    run cp -a "$ORIGIN/." "$HOME/"
    ok "restored from ${ORIGIN/#$HOME/\~}"
fi

remove_root() {
    local path
    for path in "$@"; do
        [[ -e "$path" ]] || continue
        run sudo rm -f "$path" && ok "removed $path"
    done
}

if ((SYSTEM)); then
    log "Removing the root helpers"
    if [[ -e /etc/init.d/zram ]]; then
        run sudo rc-update del zram boot >/dev/null 2>&1 || true
    fi
    remove_root \
        /usr/local/bin/serezha-power /etc/sudoers.d/serezha-power \
        /usr/local/bin/print-repair /etc/sudoers.d/print-repair /etc/udev/rules.d/60-capt-hotplug.rules \
        /etc/init.d/zram /etc/conf.d/zram /etc/systemd/zram-generator.conf /etc/sysctl.d/99-zram.conf \
        /etc/mkinitcpio.conf.d/10-amdgpu.conf
    if [[ -f /etc/mkinitcpio.conf ]] && ! ((DRY_RUN)); then
        sudo mkinitcpio -P >/dev/null 2>&1 || warn "mkinitcpio -P failed — run it by hand before rebooting"
    fi
    warn "kernel parameters added to /etc/default/grub (amd_pstate, amdgpu.ppfeaturemask) are left in place"
fi

((DRY_RUN)) || run rm -rf "$STATE_DIR"

cat <<EOF

${GREEN}${BOLD}Removed.${RESET}
  log out to leave the Hyprland session that still runs the old configuration
  your login shell is unchanged; switch back with ${BOLD}chsh -s /bin/bash${RESET} if you want
  the removed files stay in ${TRASH/#$HOME/\~} until you delete it
EOF
