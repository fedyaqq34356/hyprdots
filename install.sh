#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/fedyaqq34356/rosa.git"
CLONE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/rosa"

DRY_RUN=0
SKIP_PACKAGES=0
ASSUME_YES=0
UPDATE=0
PULLED=0
GAMES=auto
PRINTER=auto
PULSE=auto

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'
YELLOW=$'\e[33m'; BLUE=$'\e[34m'; RESET=$'\e[0m'

log()  { printf '%s::%s %s\n' "$BLUE$BOLD" "$RESET$BOLD" "$1$RESET"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
die()  { printf '%serror:%s %s\n' "$RED$BOLD" "$RESET" "$1" >&2; exit 1; }
run()  { if ((DRY_RUN)); then printf '  %s$ %s%s\n' "$DIM" "$*" "$RESET"; else "$@"; fi; }

usage() {
    cat <<EOF
${BOLD}usage:${RESET} install.sh [options]

  --update        pull the latest revision and refresh an existing install
  --no-packages   skip package installation, only deploy the configuration
  --dry-run       print every action without touching the system
  --games         install Steam, gamemode and MangoHud (default on desktops)
  --no-games      skip the gaming packages
  --printer       set up the Canon LBP6000 (CUPS + CAPT), default when it is plugged in
  --no-printer    skip the printer
  --pulse-elite   install the PlayStation Pulse Elite headset profile (default when it is paired)
  --no-pulse-elite  skip it, and remove a copy left by an older install
  -y, --yes       do not ask for confirmation
  -h, --help      show this help
EOF
}

while (($#)); do
    case "$1" in
    --update) UPDATE=1 ;;
    --pulled) PULLED=1 ;;
    --no-packages) SKIP_PACKAGES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --games) GAMES=1 ;;
    --no-games) GAMES=0 ;;
    --printer) PRINTER=1 ;;
    --no-printer) PRINTER=0 ;;
    --pulse-elite) PULSE=1 ;;
    --no-pulse-elite) PULSE=0 ;;
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
    esac
    shift
done

for pair in "${XDG_DATA_HOME:-$HOME/.local/share}/hyprdots|$CLONE_DIR" "$HOME/.config/hyprdots|$HOME/.config/rosa"; do
    old=${pair%%|*}
    new=${pair##*|}
    if [[ -d "$old" && ! -L "$old" && ! -e "$new" ]]; then
        run mv "$old" "$new"
        run ln -s "$new" "$old"
    fi
done

SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -d "$SRC_DIR/config" ]]; then
    command -v git >/dev/null || die "git is required to fetch the repository"
    log "Fetching the repository"
    if [[ -d "$CLONE_DIR/.git" ]]; then
        git -C "$CLONE_DIR" pull --ff-only \
            || { git -C "$CLONE_DIR" fetch --quiet && git -C "$CLONE_DIR" reset --hard --quiet '@{u}'; }
    else
        git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
    fi
    exec bash "$CLONE_DIR/install.sh" "$@"
fi

if ((UPDATE)) && ((!PULLED)) && [[ -d "$SRC_DIR/.git" ]]; then
    command -v git >/dev/null || die "git is required to update"
    log "Fetching the latest revision"
    before=$(git -C "$SRC_DIR" rev-parse HEAD)
    run git -C "$SRC_DIR" pull --ff-only \
        || { run git -C "$SRC_DIR" fetch --quiet && run git -C "$SRC_DIR" reset --hard --quiet '@{u}'; }
    after=$(git -C "$SRC_DIR" rev-parse HEAD)
    if [[ "$before" == "$after" ]]; then
        ok "already up to date ($(git -C "$SRC_DIR" log -1 --format=%h))"
    else
        printf '\n'
        git -C "$SRC_DIR" log --oneline "$before..$after"
        printf '\n'
    fi
    args=(--update --pulled)
    ((DRY_RUN)) && args+=(--dry-run)
    ((SKIP_PACKAGES)) && args+=(--no-packages)
    ((ASSUME_YES)) && args+=(-y)
    [[ "$GAMES" != auto ]] && { ((GAMES)) && args+=(--games) || args+=(--no-games); }
    [[ "$PRINTER" != auto ]] && { ((PRINTER)) && args+=(--printer) || args+=(--no-printer); }
    [[ "$PULSE" != auto ]] && { ((PULSE)) && args+=(--pulse-elite) || args+=(--no-pulse-elite); }
    exec bash "$SRC_DIR/install.sh" "${args[@]}"
fi

command -v pacman >/dev/null || die "this installer targets Arch-based systems (pacman not found)"
[[ $EUID -ne 0 ]] || die "run as a normal user, not as root"

PACMAN_PKGS=(
    hyprland hyprlock awww hypridle hyprpolkitagent xdg-desktop-portal-hyprland
    kitty rofi-wayland cava fastfetch yazi
    starship zoxide fzf eza bat ripgrep lazygit thunar
    brightnessctl playerctl pipewire pipewire-pulse wireplumber upower bluez bluez-utils
    lm_sensors usb_modeswitch linux-firmware udiskie noise-suppression-for-voice
    cliphist wl-clipboard grim slurp satty hyprpicker ffmpeg imagemagick jq python rust
    git pciutils mesa vulkan-icd-loader
    waybar fuzzel mako networkmanager foot nnn udisks2 xwayland-satellite socat
    qt5ct qt6ct kvantum kvantum-qt5 papirus-icon-theme xdg-user-dirs polkit
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    zsh zsh-autosuggestions zsh-syntax-highlighting
)
AUR_PKGS=(quickshell matugen wlogout wf-recorder wl-clip-persist maybar-git)

confirm() {
    ((ASSUME_YES)) && return 0
    printf '%s' "  continue? [Y/n] "
    read -r reply </dev/tty || reply=y
    [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

IS_ARTIX=0
[[ -f /etc/artix-release ]] && IS_ARTIX=1

GPU_LIST=$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)
GPU_VENDORS=$(cat /sys/class/drm/card[0-9]*/device/vendor 2>/dev/null || true)
HAS_NVIDIA=0; HAS_AMD=0; HAS_INTEL=0
{ grep -qi 'nvidia' <<<"$GPU_LIST" || grep -q 0x10de <<<"$GPU_VENDORS"; } && HAS_NVIDIA=1
{ grep -Eqi 'amd|ati technologies|radeon' <<<"$GPU_LIST" || grep -q 0x1002 <<<"$GPU_VENDORS"; } && HAS_AMD=1
{ grep -qi 'intel' <<<"$GPU_LIST" || grep -q 0x8086 <<<"$GPU_VENDORS"; } && HAS_INTEL=1

nvidia_driver() {
    [[ -d /sys/module/nvidia_drm ]] || pacman -Qq 2>/dev/null | grep -Eq '^nvidia(-[0-9]+xx)?-utils$'
}

GPU_PROFILE=generic
if ((HAS_NVIDIA)) && nvidia_driver; then GPU_PROFILE=nvidia
elif ((HAS_AMD)); then GPU_PROFILE=amd
elif ((HAS_INTEL)); then GPU_PROFILE=intel
fi

HAS_BATTERY=0
compgen -G '/sys/class/power_supply/BAT*' >/dev/null && HAS_BATTERY=1

[[ "$GAMES" == auto ]] && GAMES=$((HAS_BATTERY ? 0 : 1))

printer_plugged() {
    local d
    for d in /sys/bus/usb/devices/*; do
        [[ "$(cat "$d/idVendor" 2>/dev/null)" == 04a9 ]] || continue
        grep -qi 'LBP' "$d/product" 2>/dev/null && return 0
    done
    return 1
}
if [[ "$PRINTER" == auto ]]; then
    PRINTER=0
    ((UPDATE)) || ! printer_plugged || PRINTER=1
fi

PULSE_MAC=""
command -v bluetoothctl >/dev/null \
    && PULSE_MAC=$(timeout 3 bluetoothctl devices 2>/dev/null | awk 'tolower($0) ~ /pulse elite/ { print $2; exit }')
if [[ "$PULSE" == auto ]]; then
    PULSE=0
    [[ -e "$HOME/.config/rosa/pulse-elite" ]] && PULSE=1
    grep -qsi 'playstation.*link' /sys/bus/usb/devices/*/product && PULSE=1
    [[ -n "$PULSE_MAC" ]] && PULSE=1
fi

gpu_packages() {
    ((HAS_AMD)) && printf '%s\n' mesa vulkan-radeon libva-mesa-driver libva-utils lact
    ((HAS_AMD)) && ((IS_ARTIX)) && printf '%s\n' lact-openrc
    ((HAS_INTEL)) && printf '%s\n' vulkan-intel intel-media-driver
    if ((HAS_NVIDIA)) && nvidia_driver; then
        printf '%s\n' egl-wayland libva-nvidia-driver
    fi
    if ((IS_ARTIX)); then
        printf '%s\n' elogind-openrc networkmanager-openrc bluez-openrc cronie cronie-openrc
    else
        printf '%s\n' cronie
        ((HAS_BATTERY)) || printf '%s\n' zram-generator
    fi
}

game_packages() {
    ((GAMES)) || return 0
    printf '%s\n' steam gamemode lib32-gamemode mangohud lib32-mangohud lib32-pipewire
    ((HAS_AMD)) && printf '%s\n' lib32-mesa lib32-vulkan-radeon lib32-libva-mesa-driver
    ((HAS_INTEL)) && printf '%s\n' lib32-mesa lib32-vulkan-intel
    return 0
}

repo_enabled() { pacman-conf --repo-list 2>/dev/null | grep -qx "$1"; }

setup_repos() {
    ((IS_ARTIX)) || {
        if ((GAMES)) && ! repo_enabled multilib; then
            warn "[multilib] is off in /etc/pacman.conf — gaming packages skipped"
            GAMES=0
        fi
        return 0
    }
    local conf=/etc/pacman.conf changed=0
    if ! repo_enabled extra || { ((GAMES)) && ! repo_enabled multilib; }; then
        log "Enabling the Arch repositories on Artix"
        run sudo pacman -S --needed --noconfirm artix-archlinux-support
        run sudo cp -a "$conf" "$conf.rosa-$(date +%Y%m%d-%H%M%S)"
    fi
    if ((GAMES)) && ! repo_enabled lib32; then
        if grep -q '^#\[lib32\]' "$conf"; then
            run sudo sed -i '/^#\[lib32\]$/{s/^#//;n;s/^#//}' "$conf"
        else
            printf '\n[lib32]\nInclude = /etc/pacman.d/mirrorlist\n' | run sudo tee -a "$conf" >/dev/null
        fi
        changed=1
    fi
    if ! repo_enabled extra; then
        printf '\n[extra]\nInclude = /etc/pacman.d/mirrorlist-arch\n' | run sudo tee -a "$conf" >/dev/null
        changed=1
    fi
    if ((GAMES)) && ! repo_enabled multilib; then
        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist-arch\n' | run sudo tee -a "$conf" >/dev/null
        changed=1
    fi
    if ((changed)); then
        run sudo pacman-key --populate archlinux
        run sudo pacman -Sy
        ok "repositories: Artix + [lib32], Arch [extra]$( ((GAMES)) && printf ' + [multilib]')"
    fi
}

detect_aur_helper() {
    for helper in paru yay; do
        command -v "$helper" >/dev/null && { echo "$helper"; return; }
    done
}

bootstrap_aur_helper() {
    local tmp
    tmp=$(mktemp -d)
    log "Building the yay AUR helper"
    run sudo pacman -S --needed --noconfirm base-devel git
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    run bash -c "cd '$tmp/yay-bin' && makepkg -si --noconfirm"
    rm -rf "$tmp"
}

install_packages() {
    log "Installing packages from the official repositories"
    setup_repos
    local extra=()
    mapfile -t extra < <(gpu_packages; game_packages)
    if ((UPDATE)); then
        run sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" "${extra[@]}"
    else
        run sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}" "${extra[@]}"
    fi
    if ((HAS_NVIDIA)) && ! nvidia_driver; then
        warn "NVIDIA card found but no driver installed — install it as the README describes, then run install.sh --update"
    fi
    ok "repository packages ready"

    local helper
    helper=$(detect_aur_helper)
    if [[ -z "$helper" ]]; then
        bootstrap_aur_helper
        helper=$(detect_aur_helper)
    fi
    [[ -n "$helper" ]] || { warn "no AUR helper available, skipping: ${AUR_PKGS[*]}"; return; }

    log "Installing AUR packages with $helper"
    run "$helper" -S --needed --noconfirm "${AUR_PKGS[@]}"
    ok "AUR packages ready"
}

BACKUP_DIR="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
STATE_DIR="$HOME/.config/rosa"
INSTALLED_TMP=$(mktemp)
trap 'rm -f "$INSTALLED_TMP"' EXIT

backup_path() {
    local target="$1" rel
    [[ -e "$target" || -L "$target" ]] || return 0
    rel="${target#"$HOME"/}"
    run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    run cp -a "$target" "$BACKUP_DIR/$rel"
}

deploy_tree() {
    local src="$1" dst="$2" file rel target
    while IFS= read -r -d '' file; do
        rel="${file#"$src"/}"
        target="$dst/$rel"
        backup_path "$target"
        run mkdir -p "$(dirname "$target")"
        run install -m "$(stat -c '%a' "$file")" "$file" "$target" \
            || warn "could not write ${target/#$HOME/\~}, skipped"
        printf '%s\n' "${target#"$HOME"/}" >>"$INSTALLED_TMP"
    done < <(find "$src" -type f -print0)
}

record_install() {
    ((DRY_RUN)) && return 0
    mkdir -p "$STATE_DIR"
    local list="$STATE_DIR/installed.list" origin="$STATE_DIR/origin-backup" first
    { [[ -f "$list" ]] && cat "$list"; cat "$INSTALLED_TMP"; } | sort -u >"$list.new"
    mv "$list.new" "$list"
    [[ -f "$origin" ]] && return 0
    first=$(find "$HOME/.config" -maxdepth 1 -type d -name 'dotfiles-backup-*' 2>/dev/null | sort | head -n1)
    printf '%s\n' "${first:-none}" >"$origin"
}

deploy_pulse() {
    local src="$SRC_DIR/extras/pulse-elite" file target removed=0
    [[ -d "$src" ]] || return 0
    if ((PULSE)); then
        deploy_tree "$src" "$HOME"
        if [[ -n "$PULSE_MAC" ]]; then
            while IFS= read -r -d '' file; do
                target="$HOME/${file#"$src"/}"
                grep -q '@PULSE_MAC' "$target" 2>/dev/null || continue
                run sed -i -e "s|@PULSE_MAC_U@|${PULSE_MAC//:/_}|g" -e "s|@PULSE_MAC@|$PULSE_MAC|g" "$target"
            done < <(find "$src" -type f -print0)
        else
            warn "Pulse Elite is not paired yet: pair it, then run rosa-update to fill in its address"
        fi
        ((DRY_RUN)) || { mkdir -p "$STATE_DIR"; : >"$STATE_DIR/pulse-elite"; }
        ok "Pulse Elite headset profile installed"
        return 0
    fi
    ((DRY_RUN)) || rm -f "$STATE_DIR/pulse-elite"
    while IFS= read -r -d '' file; do
        target="$HOME/${file#"$src"/}"
        [[ -f "$target" ]] || continue
        backup_path "$target"
        run rm -f "$target"
        removed=1
    done < <(find "$src" -type f -print0)
    ((removed)) && ok "removed the Pulse Elite headset profile (not paired here)"
    return 0
}

expand_home() {
    local file
    while IFS= read -r -d '' file; do
        grep -q '@HOME@' "$file" 2>/dev/null || continue
        run sed -i "s|@HOME@|$HOME|g" "$file"
    done < <(find "$HOME/.config/serezha" "$HOME/.config/hypr" "$HOME/.local/bin" \
        "$HOME/.local/share/applications" -type f -print0 2>/dev/null)
}

install_power() {
    local src="$SRC_DIR/bin/serezha-power"
    local dst=/usr/local/bin/serezha-power
    local rule=/etc/sudoers.d/serezha-power

    [[ -f "$src" ]] || return 0
    log "Installing the power profile helper (needs root)"

    run sudo install -m 755 "$src" "$dst" || {
        warn "could not install $dst — POWER=yes will do nothing"
        return 0
    }
    printf '%s ALL=(root) NOPASSWD: %s\n' "$USER" "$dst" |
        run sudo install -m 440 /dev/stdin "$rule" || {
            warn "could not write $rule — POWER=yes will do nothing"
            return 0
        }
    sudo visudo -cf "$rule" >/dev/null 2>&1 ||
        warn "$rule did not pass visudo — check it by hand"
    ok "power profile helper installed"
}

configure_parser() {
    local hypr="$HOME/.config/hypr" ver
    [[ -f "$hypr/hyprland.lua" ]] || return 0
    ver=$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [[ -n "$ver" ]] && printf '%s\n0.55\n' "$ver" | sort -V -C; then
        [[ "$ver" == 0.55 ]] && { ok "config: Lua (Hyprland $ver)"; return 0; }
        run rm -rf "$hypr/hyprland.lua" "$hypr/cfg"
        ok "config: hyprlang (Hyprland $ver has no Lua config)"
        return 0
    fi
    ok "config: Lua${ver:+ (Hyprland $ver)}"
}

configure_gpu() {
    local dir="$HOME/.config/hypr/config"
    [[ -f "$SRC_DIR/config/hypr/config/gpu-$GPU_PROFILE.conf" ]] || return 0
    run ln -sfn "gpu-$GPU_PROFILE.conf" "$dir/gpu.conf"
    case "$GPU_PROFILE" in
        nvidia) ok "GPU: NVIDIA — NVIDIA environment" ;;
        amd) ok "GPU: AMD — radeonsi VA-API, VRR on fullscreen, tearing for games" ;;
        intel) ok "GPU: Intel — VA-API set to iHD" ;;
        *) ok "GPU: generic" ;;
    esac
}

configure_kms() {
    ((HAS_AMD)) && ! ((HAS_NVIDIA)) || return 0
    [[ -f /etc/mkinitcpio.conf ]] || return 0
    local drop=/etc/mkinitcpio.conf.d/10-amdgpu.conf
    if grep -Eq '^MODULES=\(.*\bamdgpu\b' /etc/mkinitcpio.conf || [[ -f "$drop" ]]; then
        ok "early KMS: amdgpu already in the initramfs"
        return 0
    fi
    log "Early KMS for amdgpu (Plymouth and SDDM at native resolution)"
    run sudo mkdir -p /etc/mkinitcpio.conf.d
    printf 'MODULES+=(amdgpu)\n' | run sudo tee "$drop" >/dev/null
    run sudo mkinitcpio -P || warn "mkinitcpio -P failed — run it by hand before rebooting"
    ok "amdgpu added to MODULES ($drop)"
}

amd_card() {
    local c
    for c in /sys/class/drm/card[0-9]*; do
        [[ "$(cat "$c/device/vendor" 2>/dev/null)" == 0x1002 && -e "$c/device/gpu_busy_percent" ]] || continue
        printf '%s' "${c##*card}"
        return 0
    done
    return 1
}

configure_lact() {
    ((HAS_AMD)) && ! ((HAS_BATTERY)) || return 0
    command -v lact >/dev/null || ((DRY_RUN)) || return 0
    local conf=/etc/lact/config.yaml
    if [[ ! -s "$conf" ]] && amd_card >/dev/null; then
        log "LACT: quiet fan curve and power cap for the Radeon"
        run sudo mkdir -p /etc/lact
        if ! ((DRY_RUN)); then
            sh "$SRC_DIR/extras/lact/gen-config.sh" | sudo tee "$conf" >/dev/null \
                || warn "LACT config not written"
        fi
    fi
    if ((IS_ARTIX)); then
        local svc
        for svc in lactd lact; do
            [[ -e "/etc/init.d/$svc" ]] || continue
            run sudo rc-update add "$svc" default >/dev/null 2>&1 || true
            run sudo rc-service "$svc" restart >/dev/null 2>&1 || true
            break
        done
    elif command -v systemctl >/dev/null; then
        run sudo systemctl enable --now lactd.service >/dev/null 2>&1 || true
    fi
    ok "LACT daemon enabled (tune in the lact GUI, config in $conf)"
}

configure_gamemode() {
    ((GAMES)) && ((HAS_AMD)) && ! ((HAS_NVIDIA)) || return 0
    local dst="$HOME/.config/gamemode.ini" card
    card=$(amd_card) || card=0
    [[ -e "$dst" ]] && return 0
    run mkdir -p "$HOME/.config"
    ((DRY_RUN)) || sed "s/@CARD@/$card/" "$SRC_DIR/extras/gamemode/gamemode.ini" > "$dst"
    ok "gamemode: performance governor and GPU level high while a game runs (card$card)"
}

configure_zram() {
    ((HAS_BATTERY)) && return 0
    ((IS_ARTIX)) || { configure_zram_systemd; return 0; }
    [[ -e /etc/init.d/zram ]] && { ok "zram swap already set up"; return 0; }
    log "zram swap (half of RAM, zstd)"
    run sudo install -m 755 "$SRC_DIR/extras/zram/zram.openrc" /etc/init.d/zram
    run sudo install -m 644 "$SRC_DIR/extras/zram/zram.confd" /etc/conf.d/zram
    run sudo install -m 644 "$SRC_DIR/extras/zram/99-zram.conf" /etc/sysctl.d/99-zram.conf
    run sudo rc-update add zram boot >/dev/null 2>&1 || true
    if awk '$3 == "swap" && $1 !~ /^#/' /etc/fstab 2>/dev/null | grep -q .; then
        warn "a swap entry is still in /etc/fstab — comment it out and delete the swapfile"
    fi
    ok "zram enabled from the next boot"
}

configure_zram_systemd() {
    local conf=/etc/systemd/zram-generator.conf
    [[ -e "$conf" ]] && { ok "zram swap already set up"; return 0; }
    [[ -e /usr/lib/systemd/system-generators/zram-generator ]] || { warn "zram-generator is missing, zram skipped"; return 0; }
    log "zram swap (half of RAM, zstd)"
    printf '[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\nswap-priority = 100\n' \
        | run sudo install -m 644 /dev/stdin "$conf"
    run sudo install -m 644 "$SRC_DIR/extras/zram/99-zram.conf" /etc/sysctl.d/99-zram.conf
    run sudo systemctl daemon-reload
    run sudo systemctl start systemd-zram-setup@zram0.service >/dev/null 2>&1 || true
    ok "zram enabled"
}

configure_cmdline() {
    ((HAS_BATTERY)) && return 0
    local grub=/etc/default/grub want=() p cur
    [[ -f "$grub" ]] || return 0
    if grep -q AuthenticAMD /proc/cpuinfo; then
        if grep -qw cppc /proc/cpuinfo || [[ -d /sys/devices/system/cpu/amd_pstate ]]; then
            want+=(amd_pstate=active)
        else
            warn "CPU has no CPPC — enable it in the BIOS (AMD CBS → NBIO → SMU → CPPC) and rerun install.sh --update"
        fi
    fi
    ((HAS_AMD)) && ! ((HAS_NVIDIA)) && want+=(amdgpu.ppfeaturemask=0xffffffff)
    cur=$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"$/\1/p' "$grub")
    local add=()
    for p in "${want[@]}"; do
        [[ " $cur " == *" ${p%%=*}="* ]] || add+=("$p")
    done
    ((${#add[@]})) || return 0
    log "Kernel parameters: ${add[*]}"
    run sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"$|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 ${add[*]}\"|" "$grub"
    run sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null || warn "grub-mkconfig failed — run it by hand"
    ok "GRUB updated, reboot to apply"
}

install_printer() {
    ((PRINTER)) || return 0
    log "Setting up the Canon LBP6000 (CUPS + CAPT)"
    local root="$SRC_DIR/config/hypr/scripts/print/print-root"
    local helper
    helper=$(detect_aur_helper)
    run sudo pacman -S --needed --noconfirm cups cups-filters ghostscript \
        $( ((IS_ARTIX)) && printf cups-openrc) || { warn "CUPS did not install, printer skipped"; return 0; }
    if [[ -n "$helper" ]]; then
        run "$helper" -S --needed --noconfirm capt-src || { warn "capt-src did not build, printer skipped"; return 0; }
    else
        warn "no AUR helper for capt-src, printer skipped"
        return 0
    fi
    if ((IS_ARTIX)); then
        run sudo install -m 755 "$SRC_DIR/extras/printer/ccpd.openrc" /etc/init.d/ccpd
        run sudo rc-update add cupsd default >/dev/null 2>&1 || true
        run sudo rc-update add ccpd default >/dev/null 2>&1 || true
        run sudo rc-service cupsd start >/dev/null 2>&1 || true
    elif command -v systemctl >/dev/null; then
        [[ -e /usr/lib/systemd/system/ccpd.service || -e /etc/systemd/system/ccpd.service ]] \
            || { run sudo install -m 644 "$SRC_DIR/extras/printer/ccpd.service" /etc/systemd/system/ccpd.service \
                 && run sudo systemctl daemon-reload; }
        run sudo systemctl enable --now cups.service >/dev/null 2>&1 || true
        run sudo systemctl enable --now ccpd.service >/dev/null 2>&1 || warn "ccpd.service did not start"
    fi
    if ! lpstat -p LBP6000 >/dev/null 2>&1; then
        run sudo lpadmin -p LBP6000 -m CNCUPSLBP6018CAPTK.ppd -v ccp://localhost:59787 -E \
            || warn "lpadmin could not add LBP6000"
        run sudo ccpdadmin -p LBP6000 -o /dev/usb/lp0 >/dev/null 2>&1 \
            || warn "ccpdadmin could not register LBP6000"
    fi
    if [[ -f "$root/install-print-fix.sh" ]]; then
        local tmp
        tmp=$(mktemp -d)
        cp -a "$root/." "$tmp/"
        printf '%s ALL=(root) NOPASSWD: /usr/local/bin/print-repair\n' "$USER" >"$tmp/print-repair-sudoers"
        run sudo bash "$tmp/install-print-fix.sh" >/dev/null 2>&1 \
            || warn "print-repair helper not installed — the printer works, self-repair does not"
        rm -rf "$tmp"
    fi
    printer_plugged && ok "printer ready" || ok "printer configured — plug it in, ccpd picks it up on hotplug"
}

add_groups() {
    local want=(video input)
    ((GAMES)) && want+=(gamemode)
    ((PRINTER)) && want+=(lp)
    local g missing=()
    for g in "${want[@]}"; do
        getent group "$g" >/dev/null || continue
        id -nG "$USER" | tr ' ' '\n' | grep -qx "$g" || missing+=("$g")
    done
    ((${#missing[@]})) || return 0
    run sudo usermod -aG "$(IFS=,; echo "${missing[*]}")" "$USER" \
        && ok "groups added: ${missing[*]} (log in again to apply)"
}

enable_services() {
    log "Enabling services"
    if ((IS_ARTIX)); then
        local svc
        for svc in NetworkManager bluetoothd cronie; do
            [[ -e "/etc/init.d/$svc" ]] || continue
            run sudo rc-update add "$svc" default >/dev/null 2>&1 || true
            run sudo rc-service "$svc" start >/dev/null 2>&1 || true
        done
    elif command -v systemctl >/dev/null; then
        run sudo systemctl enable --now NetworkManager.service >/dev/null 2>&1 || true
        run sudo systemctl enable --now bluetooth.service >/dev/null 2>&1 || true
        run sudo systemctl enable --now cronie.service >/dev/null 2>&1 || true
    fi
    ok "network, bluetooth and cron enabled"
}

migrate_layout() {
    local scripts="$HOME/.config/hypr/scripts" state="$HOME/.local/state/hypr"
    local file name
    if [[ -d "$scripts" ]]; then
        while IFS= read -r -d '' file; do
            name="${file##*/}"
            compgen -G "$SRC_DIR/config/hypr/scripts/*/$name" >/dev/null || continue
            backup_path "$file"
            run rm -rf "$file"
        done < <(find "$scripts" -mindepth 1 -maxdepth 1 \
            \( -type f -o -name print-root \) -print0)
    fi
    run mkdir -p "$state"
    for name in mic-level lock-choice; do
        [[ -f "$HOME/.config/hypr/$name" && ! -e "$state/$name" ]] \
            && run mv "$HOME/.config/hypr/$name" "$state/$name"
    done
    return 0
}

build_islandd() {
    local manifest="$SRC_DIR/src/islandd/Cargo.toml"
    [[ -f "$manifest" ]] || return 0
    command -v cargo >/dev/null 2>&1 || { warn "no cargo: islandd not built"; return 0; }
    local target="${XDG_CACHE_HOME:-$HOME/.cache}/islandd-build"
    if run cargo build --release --quiet --manifest-path "$manifest" --target-dir "$target"; then
        run install -Dm755 "$target/release/islandd" "$HOME/.local/bin/islandd"
        run ln -sfn islandd "$HOME/.local/bin/aulactl"
        ok "islandd built"
    else
        warn "islandd build failed"
    fi
}

deploy_config() {
    log "Deploying the configuration"
    migrate_layout

    local monitors="$HOME/.config/hypr/config/monitors.conf" kept=""
    [[ -s "$monitors" ]] && kept=$(<"$monitors")

    deploy_tree "$SRC_DIR/config" "$HOME/.config"

    if [[ -n "$kept" ]] && ! ((DRY_RUN)); then
        printf '%s\n' "$kept" > "$monitors"
    fi
    deploy_tree "$SRC_DIR/home" "$HOME"
    deploy_tree "$SRC_DIR/bin" "$HOME/.local/bin"
    run ln -sfn rosa-update "$HOME/.local/bin/hyprdots-update"
    build_islandd

    if [[ -d "$SRC_DIR/config/serezha/applications" ]]; then
        deploy_tree "$SRC_DIR/config/serezha/applications" \
            "$HOME/.local/share/applications"
    fi

    run mkdir -p "$HOME/.config/rosa"
    if [[ -d "$SRC_DIR/.git" ]]; then
        ((DRY_RUN)) || printf '%s\n' "$SRC_DIR" > "$HOME/.config/rosa/source"
    fi

    deploy_pulse
    record_install

    expand_home
    configure_gpu
    configure_parser
    install_power
    ok "files installed (backup: ${BACKUP_DIR/#$HOME/\~})"
}

seed_wallpapers() {
    local dir="$HOME/Pictures/Wallpapers"
    run mkdir -p "$dir"
    if ! find "$dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        | grep -q .; then
        warn "no wallpapers in ${dir/#$HOME/\~} — add a few images, then press Super+W"
        return 1
    fi
}

generate_theme() {
    log "Generating the colour scheme from the current wallpaper"
    local current="$HOME/.config/hypr/current-wallpaper" wallpaper=""
    [[ -f "$current" ]] && wallpaper=$(<"$current")
    if [[ ! -f "$wallpaper" ]]; then
        wallpaper=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
            | sort | head -n1)
    fi
    [[ -f "$wallpaper" ]] || { warn "no wallpaper found, colours will be generated on the first Super+W"; return; }

    run bash -c "printf '%s\n' '$wallpaper' > '$current'"
    if command -v matugen >/dev/null; then
        run matugen image "$wallpaper" --mode dark --type scheme-content --prefer saturation
        ok "theme generated from $(basename "$wallpaper")"
    else
        warn "matugen is not installed, skipping theme generation"
    fi
}

set_shell() {
    command -v zsh >/dev/null || return 0
    [[ "${SHELL:-}" == *zsh ]] && return 0
    log "Setting zsh as the login shell"
    run chsh -s "$(command -v zsh)" || warn "could not change the login shell, do it manually with chsh -s \$(which zsh)"
}

if ((UPDATE)); then
cat <<EOF
${BOLD}Hyprland desktop — update${RESET}
  source      ${SRC_DIR/#$HOME/\~}
  target      ~/.config, ~/.local/bin, ~
  packages    checked, only missing ones are installed
  replaced files are backed up first
EOF
else
cat <<EOF
${BOLD}Hyprland desktop — automatic installation${RESET}
  source      ${SRC_DIR/#$HOME/\~}
  target      ~/.config, ~/.local/bin, ~
  packages    $((SKIP_PACKAGES ? 0 : ${#PACMAN_PKGS[@]} + ${#AUR_PKGS[@]}))
  system      $( ((IS_ARTIX)) && echo "Artix (OpenRC)" || echo "Arch (systemd)")
  gpu         $( ((HAS_NVIDIA)) && printf 'NVIDIA ')$( ((HAS_AMD)) && printf 'AMD ')$( ((HAS_INTEL)) && printf 'Intel ')(profile: $GPU_PROFILE)
  machine     $( ((HAS_BATTERY)) && echo laptop || echo desktop)$( ((GAMES)) && printf ', games')$( ((PRINTER)) && printf ', printer')
  existing files are backed up before being replaced
EOF
fi
confirm || die "aborted"

((SKIP_PACKAGES)) || install_packages
deploy_config
((SKIP_PACKAGES)) || configure_kms
((SKIP_PACKAGES)) || configure_cmdline
((SKIP_PACKAGES)) || configure_zram
((SKIP_PACKAGES)) || configure_lact
configure_gamemode
((SKIP_PACKAGES)) || install_printer
((UPDATE)) || ((SKIP_PACKAGES)) || add_groups
((UPDATE)) || seed_wallpapers || true
generate_theme
((UPDATE)) || ((SKIP_PACKAGES)) || enable_services
((UPDATE)) || set_shell

reload_session() {
    log "Reloading the running session"
    if command -v hyprctl >/dev/null && pgrep -x Hyprland >/dev/null; then
        if [[ -f "$HOME/.config/hypr/hyprland.lua" ]] \
            && [[ "$(hyprctl eval 'return 1' 2>/dev/null)" == *"only supported with the lua"* ]]; then
            [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && ! ((DRY_RUN)) \
                && : >"${XDG_RUNTIME_DIR:-/tmp}/hypr-lua-started-$HYPRLAND_INSTANCE_SIGNATURE"
            run hyprctl reload full-reset >/dev/null
        else
            run hyprctl reload >/dev/null
        fi
    fi
    if pgrep -x quickshell >/dev/null; then
        run pkill -x quickshell
        run setsid -f "$HOME/.local/bin/shell-autostart" >/dev/null 2>&1
    fi
    ok "session reloaded"
}

((UPDATE)) && reload_session

if ((UPDATE)); then
cat <<EOF

${GREEN}${BOLD}Updated.${RESET}
  revision    $(git -C "$SRC_DIR" log -1 --format='%h %s' 2>/dev/null || echo unknown)
  the bar and Hyprland were reloaded in place; log out only if something looks stale
EOF
exit 0
fi

cat <<EOF

${GREEN}${BOLD}Done.${RESET}
  1. log out, log in on a TTY and run ${BOLD}start-hyprland${RESET}
  2. press ${BOLD}Super+W${RESET} to pick a wallpaper — the whole desktop is recoloured from it
  3. press ${BOLD}Super+Shift+I${RESET} to tune the dynamic island — it replaces the bar clock and reacts to music, volume, notifications and timers
  4. press ${BOLD}Super+Shift+L${RESET} to see the lock screen
  5. when a new version lands on GitHub, an ${BOLD}update${RESET} button appears next to the workspaces
  6. run ${BOLD}shell-switch status${RESET} to check the Quickshell bar (${BOLD}shell-switch restart${RESET} to reload it)

  backup of the previous configuration: ${BACKUP_DIR/#$HOME/\~}
  to remove everything again: ${BOLD}bash ${SRC_DIR/#$HOME/\~}/uninstall.sh${RESET}
$( ((HAS_BATTERY)) || printf '\n  desktop: the manual steps (BIOS, services, cron) are in docs/DESKTOP.md\n')
EOF
