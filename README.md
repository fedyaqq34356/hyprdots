<div align="center">

# Hyprland Desktop

**A wallpaper-driven Wayland desktop for Arch and Artix Linux.**

Pick a wallpaper — the bar, the terminal, the notifications, the launcher and the lock screen
recolour themselves around it.

[English](#english) · [Русский](#русский)

`Hyprland` `Quickshell` `Waybar` `matugen` `hyprlock` `kitty` `zsh`

</div>

---

## English

### What this is

A complete daily-driver desktop configuration for [Hyprland](https://hypr.land): window manager,
status bar, launcher, clipboard history, notifications, on-screen display, lock screen, terminal,
file manager and shell. Every colour in the system is derived from the current wallpaper by
[matugen](https://github.com/InioX/matugen) (Material You), so the desktop is never out of sync
with what is on the screen.

Two shell stacks ship side by side and can be swapped at runtime:

| Stack | Contents | Switch |
| --- | --- | --- |
| **Quickshell** (default) | custom bar, launcher, clipboard, notifications, volume/brightness OSD, wallpaper picker | `shell-switch qs` |
| **Waybar** | Waybar + dunst + rofi | `shell-switch waybar` |

A watchdog supervises the active stack: if Quickshell dies, Waybar is brought up automatically, so
the desktop is never left without a bar.

### Install

One command. It fetches the repository, installs every dependency, backs up whatever is already
in place and generates the colour scheme:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fedyaqq34356/hyprdots/main/install.sh)
```

Or, from a clone:

```bash
git clone https://github.com/fedyaqq34356/hyprdots.git
cd hyprdots
./install.sh
```

| Flag | Effect |
| --- | --- |
| `--dry-run` | print every action, change nothing |
| `--no-packages` | deploy the configuration only, install no packages |
| `-y`, `--yes` | do not ask for confirmation |

The installer requires `pacman`, must be run as a normal user (not root), and copies the previous
configuration to `~/.config/dotfiles-backup-<timestamp>` before writing anything.

### Theming

```
wallpaper ──▶ matugen ──┬──▶ hyprland   window borders
                        ├──▶ hyprlock   lock screen
                        ├──▶ quickshell bar, launcher, OSD
                        ├──▶ waybar     bar
                        ├──▶ kitty      terminal palette
                        ├──▶ rofi       launcher
                        ├──▶ dunst      notifications
                        └──▶ cava       audio visualiser
```

`~/.config/hypr/scripts/set-wallpaper.sh` is the single entry point: it paints every connected
monitor, persists the choice to `~/.config/hypr/current-wallpaper`, and re-runs matugen. Templates
live in `~/.config/matugen/templates` — add a file there plus one block in
`~/.config/matugen/config.toml` and any other application joins the scheme.

The lock screen reads the same source. `Super+Shift+L` runs a wrapper that regenerates the palette
if the wallpaper has changed since the last run, so the lock screen always shows the wallpaper that
is on the desktop right now — blurred, dimmed, behind a frosted card with the clock, the date, the
keyboard layout, uptime and battery.

### Keybindings

`Super` is the modifier.

| Key | Action |
| --- | --- |
| `Super` + `Return` | terminal (kitty) |
| `Super` + `T` | scratchpad terminal |
| `Super` + `D` | application launcher |
| `Super` + `E` | file manager |
| `Super` + `W` | wallpaper picker |
| `Super` + `V` | clipboard history |
| `Super` + `P` | power menu |
| `Super` + `Q` | close window |
| `Super` + `F` | fullscreen |
| `Super` + `Shift` + `F` | toggle floating |
| `Super` + `H` / `J` / `K` / `L` | move focus (vim keys) |
| `Super` + arrows | move a floating window |
| `Super` + `Shift` + arrows | resize a window |
| `Super` + `1`…`9` | switch workspace |
| `Super` + `Shift` + `1`…`9` | move window to workspace |
| `Super` + `Shift` + `L` | lock screen |
| `Super` + `Shift` + `R` | reload Hyprland |
| `Super` + `Shift` + `E` | exit Hyprland |
| `Print` | screenshot |
| `Shift` + `Print` | screen recording on/off |
| `Super` + `Shift` + `F3` | cache cleanup |
| `Super` + `Shift` + `F4` | system update |

### Layout

```
config/
  hypr/          Hyprland, hyprlock, wallpaper and utility scripts
  quickshell/f/  the Quickshell stack (bar, launcher, clipboard, OSD, notifications)
  waybar/        the fallback bar
  matugen/       colour-scheme templates for every application
  kitty/         terminal
  rofi/          launcher used by the Waybar stack
  cava/          audio visualiser themes and shaders
  wlogout/       power menu
  yazi/          file manager
  fastfetch/     system information
  gtk-3.0, gtk-4.0, qt6ct
  starship.toml  shell prompt
home/            .zshrc, .zshenv, .bashrc
bin/             shell-autostart, shell-switch, shell-watchdog
install.sh       automatic installer
```

Files generated at runtime — `colors.conf`, `lock-colors.conf`, `colors.css`, `Colors.qml`,
`current-wallpaper`, `hyprpaper.conf` — are deliberately not tracked; matugen writes them on the
first run.

### Requirements

Arch or Artix Linux with an AUR helper (the installer builds `yay` if none is present).

**Repositories:** hyprland · hyprlock · hyprpaper · hyprpolkitagent · xdg-desktop-portal-hyprland ·
waybar · kitty · rofi-wayland · dunst · cava · fastfetch · yazi · starship · zoxide · fzf · eza ·
bat · ripgrep · lazygit · thunar · brightnessctl · playerctl · pipewire · wireplumber · cliphist ·
wl-clipboard · grim · slurp · ffmpeg · imagemagick · qt6ct · kvantum · papirus-icon-theme ·
ttf-jetbrains-mono-nerd · zsh

**AUR:** quickshell · matugen-bin · wlogout · wf-recorder · wl-clip-persist

On Artix, install the service packages for your init system (`-openrc`, `-runit`, `-s6`) instead of
the systemd variants.

### Notes

* NVIDIA-specific environment variables live in `config/hypr/config/env.conf` — remove them on AMD
  or Intel hardware.
* Monitors are declared in `config/hypr/config/monitors.conf`; adjust it for your outputs.
* Wallpapers are read from `~/Pictures/Wallpapers` and rotate every three hours; the interval is
  set in `config/hypr/scripts/wallpaper-rotate.sh`.

### License

MIT — see [LICENSE](LICENSE).

---

## Русский

### Что это

Полная конфигурация рабочего окружения на [Hyprland](https://hypr.land): оконный менеджер, панель,
лаунчер, история буфера обмена, уведомления, экранные индикаторы, экран блокировки, терминал,
файловый менеджер и оболочка. Все цвета в системе выводятся из текущих обоев через
[matugen](https://github.com/InioX/matugen) (Material You), поэтому оформление всегда совпадает с
тем, что на экране.

В комплекте два набора оболочки, переключаются на лету:

| Набор | Состав | Переключение |
| --- | --- | --- |
| **Quickshell** (по умолчанию) | своя панель, лаунчер, буфер обмена, уведомления, индикаторы громкости и яркости, выбор обоев | `shell-switch qs` |
| **Waybar** | Waybar + dunst + rofi | `shell-switch waybar` |

За активным набором следит watchdog: если Quickshell падает, автоматически поднимается Waybar —
рабочий стол не остаётся без панели.

### Установка

Одна команда: скачивает репозиторий, ставит все зависимости, делает резервную копию текущих
конфигов и генерирует цветовую схему.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fedyaqq34356/hyprdots/main/install.sh)
```

Или из клона:

```bash
git clone https://github.com/fedyaqq34356/hyprdots.git
cd hyprdots
./install.sh
```

| Флаг | Действие |
| --- | --- |
| `--dry-run` | показать все шаги, ничего не менять |
| `--no-packages` | только разложить конфиги, пакеты не ставить |
| `-y`, `--yes` | не спрашивать подтверждения |

Установщику нужен `pacman`, запускать нужно от обычного пользователя (не от root). Предыдущая
конфигурация сохраняется в `~/.config/dotfiles-backup-<время>`.

### Оформление

```
обои ──▶ matugen ──┬──▶ hyprland   рамки окон
                   ├──▶ hyprlock   экран блокировки
                   ├──▶ quickshell панель, лаунчер, индикаторы
                   ├──▶ waybar     панель
                   ├──▶ kitty      палитра терминала
                   ├──▶ rofi       лаунчер
                   ├──▶ dunst      уведомления
                   └──▶ cava       визуализатор звука
```

Единая точка входа — `~/.config/hypr/scripts/set-wallpaper.sh`: он красит все подключённые
мониторы, сохраняет выбор в `~/.config/hypr/current-wallpaper` и перезапускает matugen. Шаблоны
лежат в `~/.config/matugen/templates` — добавьте туда файл и один блок в
`~/.config/matugen/config.toml`, и в общую схему войдёт любое другое приложение.

Экран блокировки берёт те же обои. `Super+Shift+L` запускает обёртку, которая пересобирает палитру,
если обои сменились с прошлого раза, — на локскрине всегда те обои, что стоят на рабочем столе:
размытые и притемнённые, поверх них матовая карточка с часами, датой, раскладкой клавиатуры,
аптаймом и зарядом батареи.

### Горячие клавиши

Модификатор — `Super`.

| Клавиши | Действие |
| --- | --- |
| `Super` + `Return` | терминал (kitty) |
| `Super` + `T` | выпадающий терминал |
| `Super` + `D` | лаунчер приложений |
| `Super` + `E` | файловый менеджер |
| `Super` + `W` | выбор обоев |
| `Super` + `V` | история буфера обмена |
| `Super` + `P` | меню выключения |
| `Super` + `Q` | закрыть окно |
| `Super` + `F` | полный экран |
| `Super` + `Shift` + `F` | плавающее окно |
| `Super` + `H` / `J` / `K` / `L` | перемещение фокуса (vim-клавиши) |
| `Super` + стрелки | двигать плавающее окно |
| `Super` + `Shift` + стрелки | менять размер окна |
| `Super` + `1`…`9` | переключить рабочий стол |
| `Super` + `Shift` + `1`…`9` | перенести окно на рабочий стол |
| `Super` + `Shift` + `L` | блокировка экрана |
| `Super` + `Shift` + `R` | перезагрузить Hyprland |
| `Super` + `Shift` + `E` | выйти из Hyprland |
| `Print` | скриншот |
| `Shift` + `Print` | запись экрана вкл/выкл |
| `Super` + `Shift` + `F3` | очистка кэша |
| `Super` + `Shift` + `F4` | обновление системы |

### Структура

```
config/
  hypr/          Hyprland, hyprlock, скрипты обоев и утилит
  quickshell/f/  набор Quickshell (панель, лаунчер, буфер, индикаторы, уведомления)
  waybar/        запасная панель
  matugen/       шаблоны цветовой схемы для всех приложений
  kitty/         терминал
  rofi/          лаунчер для набора с Waybar
  cava/          темы и шейдеры визуализатора звука
  wlogout/       меню выключения
  yazi/          файловый менеджер
  fastfetch/     информация о системе
  gtk-3.0, gtk-4.0, qt6ct
  starship.toml  приглашение оболочки
home/            .zshrc, .zshenv, .bashrc
bin/             shell-autostart, shell-switch, shell-watchdog
install.sh       автоматический установщик
```

Файлы, которые создаются во время работы — `colors.conf`, `lock-colors.conf`, `colors.css`,
`Colors.qml`, `current-wallpaper`, `hyprpaper.conf` — намеренно не хранятся в репозитории: matugen
пишет их при первом запуске.

### Требования

Arch или Artix Linux, помощник AUR (если его нет, установщик соберёт `yay`).

**Репозитории:** hyprland · hyprlock · hyprpaper · hyprpolkitagent · xdg-desktop-portal-hyprland ·
waybar · kitty · rofi-wayland · dunst · cava · fastfetch · yazi · starship · zoxide · fzf · eza ·
bat · ripgrep · lazygit · thunar · brightnessctl · playerctl · pipewire · wireplumber · cliphist ·
wl-clipboard · grim · slurp · ffmpeg · imagemagick · qt6ct · kvantum · papirus-icon-theme ·
ttf-jetbrains-mono-nerd · zsh

**AUR:** quickshell · matugen-bin · wlogout · wf-recorder · wl-clip-persist

На Artix ставьте пакеты служб под свою систему инициализации (`-openrc`, `-runit`, `-s6`) вместо
systemd-вариантов.

### Замечания

* Переменные окружения для NVIDIA лежат в `config/hypr/config/env.conf` — на AMD и Intel их нужно
  убрать.
* Мониторы описаны в `config/hypr/config/monitors.conf`, поправьте под свои выходы.
* Обои берутся из `~/Pictures/Wallpapers` и меняются раз в три часа; интервал задаётся в
  `config/hypr/scripts/wallpaper-rotate.sh`.

### Лицензия

MIT — см. [LICENSE](LICENSE).
