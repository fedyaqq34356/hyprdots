#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/fedyaqq34356/hyprdots.git"
CLONE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprdots"

DRY_RUN=0
SKIP_PACKAGES=0
ASSUME_YES=0
UPDATE=0
PULLED=0

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
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
    esac
    shift
done

SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -d "$SRC_DIR/config" ]]; then
    command -v git >/dev/null || die "git is required to fetch the repository"
    log "Fetching the repository"
    if [[ -d "$CLONE_DIR/.git" ]]; then
        git -C "$CLONE_DIR" pull --ff-only
    else
        git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
    fi
    exec bash "$CLONE_DIR/install.sh" "$@"
fi

if ((UPDATE)) && ((!PULLED)) && [[ -d "$SRC_DIR/.git" ]]; then
    command -v git >/dev/null || die "git is required to update"
    log "Fetching the latest revision"
    before=$(git -C "$SRC_DIR" rev-parse HEAD)
    run git -C "$SRC_DIR" pull --ff-only
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
    exec bash "$SRC_DIR/install.sh" "${args[@]}"
fi

command -v pacman >/dev/null || die "this installer targets Arch-based systems (pacman not found)"
[[ $EUID -ne 0 ]] || die "run as a normal user, not as root"

PACMAN_PKGS=(
    hyprland hyprlock hyprpaper hypridle hyprpolkitagent xdg-desktop-portal-hyprland
    kitty rofi-wayland cava fastfetch yazi
    starship zoxide fzf eza bat ripgrep lazygit thunar
    brightnessctl playerctl pipewire pipewire-pulse wireplumber upower bluez bluez-utils
    cliphist wl-clipboard grim slurp satty hyprpicker ffmpeg imagemagick jq python
    git pciutils mesa vulkan-icd-loader
    waybar fuzzel mako networkmanager foot nnn udisks2
    qt5ct qt6ct kvantum kvantum-qt5 papirus-icon-theme xdg-user-dirs polkit
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    zsh zsh-autosuggestions zsh-syntax-highlighting
)
AUR_PKGS=(quickshell matugen-bin wlogout wf-recorder wl-clip-persist)

confirm() {
    ((ASSUME_YES)) && return 0
    printf '%s' "  continue? [Y/n] "
    read -r reply </dev/tty || reply=y
    [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

IS_ARTIX=0
[[ -f /etc/artix-release ]] && IS_ARTIX=1

GPU_LIST=$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)
HAS_NVIDIA=0; HAS_AMD=0; HAS_INTEL=0
grep -qi 'nvidia' <<<"$GPU_LIST" && HAS_NVIDIA=1
grep -Eqi 'amd|ati technologies|radeon' <<<"$GPU_LIST" && HAS_AMD=1
grep -qi 'intel' <<<"$GPU_LIST" && HAS_INTEL=1

gpu_packages() {
    ((HAS_AMD)) && printf '%s\n' vulkan-radeon
    ((HAS_INTEL)) && printf '%s\n' vulkan-intel intel-media-driver
    if ((HAS_NVIDIA)) && pacman -Q nvidia-utils >/dev/null 2>&1; then
        printf '%s\n' egl-wayland libva-nvidia-driver
    fi
    if ((IS_ARTIX)); then
        printf '%s\n' elogind-openrc networkmanager-openrc bluez-openrc
    fi
}

check_repos() {
    ((IS_ARTIX)) || return 0
    if ! pacman -Sl extra >/dev/null 2>&1; then
        die "Artix needs the Arch [extra] repository for Hyprland and Quickshell — see the README, section \"Artix: Arch repositories\""
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
    check_repos
    local extra=()
    mapfile -t extra < <(gpu_packages)
    if ((UPDATE)); then
        run sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" "${extra[@]}"
    else
        run sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}" "${extra[@]}"
    fi
    if ((HAS_NVIDIA)) && ! pacman -Q nvidia-utils >/dev/null 2>&1; then
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
    done < <(find "$src" -type f -print0)
}

# Files that need the real home directory rather than a tilde: qt6ct and
# fuzzel do not expand ~, so the published copies carry an @HOME@ marker that
# is filled in here.
expand_home() {
    local file
    while IFS= read -r -d '' file; do
        grep -q '@HOME@' "$file" 2>/dev/null || continue
        run sed -i "s|@HOME@|$HOME|g" "$file"
    done < <(find "$HOME/.config/serezha" "$HOME/.local/bin" \
        "$HOME/.local/share/applications" -type f -print0 2>/dev/null)
}

# The black mode's power profile touches the CPU governor, PCIe ASPM, USB
# autosuspend and the GPU power cap — all of it root-only. The script lands in
# /usr/local/bin and gets one passwordless sudo rule for itself alone, so that
# switching modes does not stop to ask for a password. Nothing else in the
# repository asks for root, and the rule grants nothing beyond this one path.
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

configure_gpu() {
    local env="$HOME/.config/hypr/config/env.conf"
    [[ -f "$env" && -w "$env" ]] || return 0
    if ((HAS_NVIDIA)); then
        ok "GPU: NVIDIA — NVIDIA environment kept"
        return 0
    fi
    run sed -i -E '/^env = (__GLX_VENDOR_LIBRARY_NAME|LIBVA_DRIVER_NAME|GBM_BACKEND|NVD_BACKEND|WLR_DRM_DEVICES|__GL_SHADER_DISK_CACHE|__GL_SHADER_DISK_CACHE_PATH),/d' "$env"
    if ((HAS_AMD)); then
        run sed -i '1i env = LIBVA_DRIVER_NAME,radeonsi' "$env"
        ok "GPU: AMD — VA-API set to radeonsi"
    elif ((HAS_INTEL)); then
        run sed -i '1i env = LIBVA_DRIVER_NAME,iHD' "$env"
        ok "GPU: Intel — VA-API set to iHD"
    else
        ok "GPU: generic — NVIDIA environment removed"
    fi
}

enable_services() {
    log "Enabling services"
    if ((IS_ARTIX)); then
        local svc
        for svc in NetworkManager bluetoothd; do
            [[ -e "/etc/init.d/$svc" ]] || continue
            run sudo rc-update add "$svc" default >/dev/null 2>&1 || true
            run sudo rc-service "$svc" start >/dev/null 2>&1 || true
        done
    elif command -v systemctl >/dev/null; then
        run sudo systemctl enable --now NetworkManager.service >/dev/null 2>&1 || true
        run sudo systemctl enable --now bluetooth.service >/dev/null 2>&1 || true
    fi
    ok "network and bluetooth enabled"
}

deploy_config() {
    log "Deploying the configuration"
    deploy_tree "$SRC_DIR/config" "$HOME/.config"
    deploy_tree "$SRC_DIR/home" "$HOME"
    deploy_tree "$SRC_DIR/bin" "$HOME/.local/bin"

    # The mode's file manager needs a desktop entry so that xdg-open can name
    # it as the handler for inode/directory.
    if [[ -d "$SRC_DIR/config/serezha/applications" ]]; then
        deploy_tree "$SRC_DIR/config/serezha/applications" \
            "$HOME/.local/share/applications"
    fi

    run mkdir -p "$HOME/.config/hyprdots"
    if [[ -d "$SRC_DIR/.git" ]]; then
        ((DRY_RUN)) || printf '%s\n' "$SRC_DIR" > "$HOME/.config/hyprdots/source"
    fi

    expand_home
    configure_gpu
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
  gpu         $( ((HAS_NVIDIA)) && printf 'NVIDIA ')$( ((HAS_AMD)) && printf 'AMD ')$( ((HAS_INTEL)) && printf 'Intel')
  existing files are backed up before being replaced
EOF
fi
confirm || die "aborted"

((SKIP_PACKAGES)) || install_packages
deploy_config
((UPDATE)) || seed_wallpapers || true
generate_theme
((UPDATE)) || ((SKIP_PACKAGES)) || enable_services
((UPDATE)) || set_shell

reload_session() {
    log "Reloading the running session"
    command -v hyprctl >/dev/null && pgrep -x Hyprland >/dev/null \
        && run hyprctl reload >/dev/null
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
EOF
