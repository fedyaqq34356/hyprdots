#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/fedyaqq34356/hyprdots.git"
CLONE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hyprdots"

DRY_RUN=0
SKIP_PACKAGES=0
ASSUME_YES=0

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

  --no-packages   skip package installation, only deploy the configuration
  --dry-run       print every action without touching the system
  -y, --yes       do not ask for confirmation
  -h, --help      show this help
EOF
}

while (($#)); do
    case "$1" in
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

command -v pacman >/dev/null || die "this installer targets Arch-based systems (pacman not found)"
[[ $EUID -ne 0 ]] || die "run as a normal user, not as root"

PACMAN_PKGS=(
    hyprland hyprlock hyprpaper hyprpolkitagent xdg-desktop-portal-hyprland
    waybar kitty rofi-wayland dunst cava fastfetch yazi
    starship zoxide fzf eza bat ripgrep lazygit thunar
    brightnessctl playerctl pipewire pipewire-pulse wireplumber
    cliphist wl-clipboard grim slurp satty hyprpicker ffmpeg imagemagick jq python
    qt6ct kvantum papirus-icon-theme xdg-user-dirs polkit
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
    run sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"
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

deploy_config() {
    log "Deploying the configuration"
    deploy_tree "$SRC_DIR/config" "$HOME/.config"
    deploy_tree "$SRC_DIR/home" "$HOME"
    deploy_tree "$SRC_DIR/bin" "$HOME/.local/bin"
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

cat <<EOF
${BOLD}Hyprland desktop — automatic installation${RESET}
  source      ${SRC_DIR/#$HOME/\~}
  target      ~/.config, ~/.local/bin, ~
  packages    $((SKIP_PACKAGES ? 0 : ${#PACMAN_PKGS[@]} + ${#AUR_PKGS[@]}))
  existing files are backed up before being replaced
EOF
confirm || die "aborted"

((SKIP_PACKAGES)) || install_packages
deploy_config
seed_wallpapers || true
generate_theme
set_shell

cat <<EOF

${GREEN}${BOLD}Done.${RESET}
  1. log out and start Hyprland
  2. press ${BOLD}Super+W${RESET} to pick a wallpaper — the whole desktop is recoloured from it
  3. press ${BOLD}Super+Shift+L${RESET} to see the lock screen
  4. run ${BOLD}shell-switch qs${RESET} for the Quickshell bar, ${BOLD}shell-switch waybar${RESET} for Waybar

  backup of the previous configuration: ${BACKUP_DIR/#$HOME/\~}
EOF
