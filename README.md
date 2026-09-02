<div align="center">

<br>

# Hyprland Desktop

**A wallpaper-driven Wayland desktop for Arch and Artix Linux.**

Pick a wallpaper — the bar, the widgets, the terminal, the file manager, the editor
and the lock screen recolour themselves around it.

<br>

<a href="#english"><img src="https://img.shields.io/badge/docs-English-E4E3D8?style=flat-square&labelColor=13140E" alt="English"></a>
<a href="#русский"><img src="https://img.shields.io/badge/docs-Русский-E4E3D8?style=flat-square&labelColor=13140E" alt="Русский"></a>
<a href="docs/UPDATE.md"><img src="https://img.shields.io/badge/what's-new-C6C8B5?style=flat-square&labelColor=13140E" alt="What changed"></a>
<a href="#license"><img src="https://img.shields.io/badge/license-MIT-909281?style=flat-square&labelColor=13140E" alt="License"></a>

<img src="https://img.shields.io/badge/Hyprland-0.56-13140E?style=flat-square&labelColor=45483A" alt="Hyprland">
<img src="https://img.shields.io/badge/Quickshell-0.3-13140E?style=flat-square&labelColor=45483A" alt="Quickshell">
<img src="https://img.shields.io/badge/matugen-Material%20You-13140E?style=flat-square&labelColor=45483A" alt="matugen">
<img src="https://img.shields.io/badge/kitty-yazi-13140E?style=flat-square&labelColor=45483A" alt="kitty and yazi">
<img src="https://img.shields.io/badge/PipeWire-EQ-13140E?style=flat-square&labelColor=45483A" alt="PipeWire">

<br>
<br>

<img src="assets/hero.jpg" alt="The desktop" width="100%">

<img src="assets/bar.png" alt="The bar" width="100%">

<table>
<tr>
<td colspan="2"><img src="assets/launcher.jpg" alt="Application launcher" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>launcher — <code>Super</code> + <code>D</code></sub></td>
</tr>
<tr>
<td><img src="assets/osd.png" alt="Volume OSD drawn as a wave"></td>
<td><img src="assets/notifications.png" alt="Notification cards"></td>
</tr>
<tr>
<td align="center"><sub>volume — the clock widens, the ring becomes the level</sub></td>
<td align="center"><sub>notifications — the border counts the time down</sub></td>
</tr>
<tr>
<td><img src="assets/sysrings.png" alt="System monitor rings"></td>
<td><img src="assets/calendar.png" alt="Calendar with a commit heatmap"></td>
</tr>
<tr>
<td align="center"><sub>system — <code>Super</code> + <code>F1</code></sub></td>
<td align="center"><sub>calendar — the month as an orbit, tick length is that day's commits</sub></td>
</tr>
<tr>
<td><img src="assets/wifi.jpg" alt="Wi-Fi networks on the orbit view"></td>
<td><img src="assets/bluetooth.jpg" alt="Bluetooth devices on the orbit view"></td>
</tr>
<tr>
<td align="center"><sub>Wi-Fi — <code>Super</code> + <code>N</code></sub></td>
<td align="center"><sub>Bluetooth — <code>Super</code> + <code>B</code></sub></td>
</tr>
<tr>
<td><img src="assets/audio.jpg" alt="Audio devices on the orbit view"></td>
<td><img src="assets/media.jpg" alt="Media panel"></td>
</tr>
<tr>
<td align="center"><sub>audio — <code>Super</code> + <code>Shift</code> + <code>M</code></sub></td>
<td align="center"><sub>player — <code>Super</code> + <code>A</code></sub></td>
</tr>
<tr>
<td><img src="assets/clipboard.jpg" alt="Clipboard history"></td>
<td><img src="assets/wallpapers.jpg" alt="Wallpaper picker"></td>
</tr>
<tr>
<td align="center"><sub>clipboard — <code>Super</code> + <code>V</code></sub></td>
<td align="center"><sub>wallpapers — <code>Super</code> + <code>W</code></sub></td>
</tr>
<tr>
<td><img src="assets/focus.jpg" alt="Focus mode"></td>
<td><img src="assets/power.jpg" alt="Power menu"></td>
</tr>
<tr>
<td align="center"><sub>focus mode — <code>Super</code> + <code>Ctrl</code> + <code>F</code></sub></td>
<td align="center"><sub>power — <code>Super</code> + <code>P</code></sub></td>
</tr>
<tr>
<td><img src="assets/desk-edit.jpg" alt="Arranging the desktop widgets"></td>
<td><img src="assets/settings.jpg" alt="Settings panel"></td>
</tr>
<tr>
<td align="center"><sub>desktop widgets — <code>Super</code> + <code>Shift</code> + <code>W</code></sub></td>
<td align="center"><sub>settings — <code>Super</code> + <code>Shift</code> + <code>P</code></sub></td>
</tr>
<tr>
<td><img src="assets/equalizer.jpg" alt="Ten band equaliser"></td>
<td><img src="assets/notification-center.jpg" alt="Notification centre"></td>
</tr>
<tr>
<td align="center"><sub>equaliser — <code>Super</code> + <code>Shift</code> + <code>Q</code></sub></td>
<td align="center"><sub>notification centre — <code>Super</code> + <code>Shift</code> + <code>N</code></sub></td>
</tr>
<tr>
<td><img src="assets/draw.jpg" alt="Drawing over the screen"></td>
<td><img src="assets/polkit.jpg" alt="Authorisation prompt"></td>
</tr>
<tr>
<td align="center"><sub>draw over the screen — <code>Super</code> + <code>Shift</code> + <code>G</code></sub></td>
<td align="center"><sub>authorisation — the shell's own polkit agent</sub></td>
</tr>
<tr>
<td><img src="assets/files.jpg" alt="Media browser"></td>
<td><img src="assets/dock.jpg" alt="Dock"></td>
</tr>
<tr>
<td align="center"><sub>media browser — <code>Super</code> + <code>Shift</code> + <code>B</code></sub></td>
<td align="center"><sub>dock — hidden until the pointer reaches the edge</sub></td>
</tr>
<tr>
<td><img src="assets/guide.jpg" alt="First run tour"></td>
<td><img src="assets/calc.jpg" alt="Calculator inside the launcher"></td>
</tr>
<tr>
<td align="center"><sub>the tour, once, on first login</sub></td>
<td align="center"><sub>calculator — <code>Super</code> + <code>C</code></sub></td>
</tr>
<tr>
<td colspan="2"><img src="assets/yazi.jpg" alt="yazi themed from the wallpaper" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>the file manager takes the same palette — <code>Super</code> + <code>E</code></sub></td>
</tr>
</table>

</div>

<br>

<table>
<tr>
<td width="33%" valign="top">

**One palette, everywhere**

matugen reads the wallpaper and the whole system follows: shell, kitty, yazi, Zed,
GTK and Qt apps, even the mouse cursor. Colours ease into place rather than snapping.

</td>
<td width="33%" valign="top">

**Widgets on the wallpaper**

Clock, weather, load, screen time and the player as a turning record — under the
windows, intangible until you ask to arrange them.

</td>
<td width="33%" valign="top">

**One shell, one process**

Bar, launcher, clipboard, notifications, OSD, lock screen, dock and panels are all
Quickshell. ~6% CPU at idle on two monitors.

</td>
</tr>
<tr>
<td valign="top">

**Sound that belongs to the interface**

Every gesture has its own sample: clicks, panel stingers, a ratchet under a drag,
connect and disconnect for the radios.

</td>
<td valign="top">

**An equaliser without a daemon**

Ten bands on PipeWire's own biquads. The band curve and the live spectrum share one
grid, and the handles sit on the curve.

</td>
<td valign="top">

**Everything is a switch**

One settings card turns any optional part off — and anything switched off can be
deleted with its files and one line.

</td>
</tr>
</table>

<br>


<br>

<div align="center">

|  |  |  |  |
| --- | --- | --- | --- |
| **distro** | Arch · Artix (OpenRC) | **shell** | Quickshell 0.3 |
| **wm** | Hyprland 0.56 | **colours** | matugen, from the wallpaper |
| **terminal** | kitty | **files** | yazi, with real image previews |
| **editor** | Zed | **audio** | PipeWire + a filter-chain EQ |
| **fonts** | JetBrains Mono · Adwaita Sans | **prompt** | zsh + starship |

</div>

<br>

---

## English

### What this is

A complete daily-driver desktop configuration for [Hyprland](https://hypr.land): window manager,
status bar, launcher, clipboard history, notifications, on-screen display, lock screen, terminal,
file manager and shell. Every colour in the system is derived from the current wallpaper by
[matugen](https://github.com/InioX/matugen) (Material You), so the desktop is never out of sync
with what is on the screen.

The shell is Quickshell throughout — bar, launcher, clipboard, notifications, volume and
brightness OSD, wallpaper picker, overview and power menu are all one process.

A watchdog supervises it: if Quickshell dies it is restarted, and after three failures in a row it
stops retrying and says so in a notification instead of flapping. `shell-switch status` reports
the current state, `shell-switch restart` reloads it.

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

<details>
<summary><b>Updating</b> — <sub>one command, and what it will not overwrite</sub></summary>


Already installed? Do not run the installer again — there is an update path that keeps your
machine as it is and only brings the configuration forward:

```bash
dots-update
```

It pulls the newest revision, prints the commits you are about to get, replaces the configuration
files (backing up whatever it overwrites), installs only packages that are genuinely missing —
never a full system upgrade — regenerates the palette from your current wallpaper and reloads
Hyprland and the bar in place. No logout needed.

From a clone, the same thing:

```bash
cd hyprdots && ./install.sh --update
```

`--dry-run` works here too and prints every step without touching anything.

</details>

<details>
<summary><b>Theming</b> — <sub>how a wallpaper becomes a palette, and where each template lands</sub></summary>


```
wallpaper ──▶ matugen ──┬──▶ hyprland   window borders
                        ├──▶ hyprlock   lock screen
                        ├──▶ quickshell bar, launcher, OSD
                        ├──▶ kitty      terminal palette
                        ├──▶ rofi       launcher
                        ├──▶ dunst      notifications
                        ├──▶ gtk 3/4    Thunar and every other GTK app
                        ├──▶ papirus    folder icons tinted to the accent
                        ├──▶ wlogout    power menu
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

</details>

<details>
<summary><b>Hardware video decoding</b> — <sub>NVIDIA, VA-API and the browser flags that actually matter</sub></summary>


The session already exports `LIBVA_DRIVER_NAME=nvidia` and `NVD_BACKEND=direct`, which is only
half the story: NVIDIA needs `libva-nvidia-driver` to map VA-API onto NVDEC, and each browser has
to be told to use it.

Chromium wants the flags on its command line — the packaged binary is not a wrapper script, so
there is no `chromium-flags.conf` to edit; copy the desktop entry to
`~/.local/share/applications/` and add:

```
--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy --use-gl=angle --use-angle=gl
```

Firefox and LibreWolf want a `user.js` in the active profile:

```js
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("widget.dmabuf.force-enabled", true);
user_pref("gfx.webrender.all", true);
user_pref("media.av1.enabled", false);
```

plus `MOZ_DISABLE_RDD_SANDBOX=1` in the environment, otherwise the decoder process cannot reach
the driver. Turning AV1 off is deliberate on older cards: Pascal and earlier have no AV1 decoder,
so accepting those streams quietly moves the work back to the CPU.

Check the result in `chrome://gpu` and `about:support`, or watch `nvidia-smi dmon` while a video
plays — the `dec` column stays at zero when decoding is still on the CPU.

</details>

<details>
<summary><b>Idle</b> — <sub>timers in the shell, the decision in one guard script</sub></summary>


The shell locks the session after 50 minutes without input and turns the panels off five minutes
later. Both timers live in the shell's own settings rather than in a third config file with its own
syntax, and both actions still go through `config/hypr/scripts/idle-guard.sh`, which refuses to fire
while a window is fullscreen, audio is genuinely playing (uncorked, not merely holding the device
open), a recording is running, or any process named in `~/.config/hypr/idle-inhibit.list` is alive.

Keeping that decision in the script is deliberate: it already knows every reason not to lock, and a
second opinion written in QML would only end up disagreeing with it.

That list is matched against process names with `pgrep -x`, one per line. Only
`idle-inhibit.list.example` is tracked; copy it and add whatever should keep your own screen awake
— the working copy is deliberately kept out of the repository.

`hypridle` is no longer started; the line is left commented in `config/hypr/config/startup.conf` for
anyone who wants it back.

</details>

<details>
<summary><b>Power menu</b> — <sub>why it is a panel and not a script</sub></summary>


`Super`+`P` opens a native Quickshell menu: the clock, uptime and battery over five tiles — lock,
sleep, log out, reboot, shut down. Each tile carries its own letter, so `l`, `s`, `e`, `r` and `p`
fire straight away; arrows move the selection, `Enter` confirms, `Escape` or a click outside
closes. Reboot and shutdown glow red instead of the theme accent, so the two irreversible entries
never look like the others.

It takes its colours from the wallpaper like everything else. `wlogout` is still themed from the
same palette and stays available as a standalone power menu.

</details>

<details>
<summary><b>Screen capture</b> — <sub>region, window, monitor, colour picker, OCR</sub></summary>


`config/hypr/scripts/screenshot.sh` takes one argument and covers every case:

| Mode | What it grabs |
| --- | --- |
| `region` | an area drawn with the mouse |
| `window` | one window, snapped to its real geometry |
| `output` | the monitor under the cursor |
| `all` | every connected monitor in one image |
| `edit` | an area, then [satty](https://github.com/gabm/Satty) for arrows and blur |
| `color` | the colour under the cursor, hex into the clipboard |
| `ocr` | an area, its text recognised and copied — no image is kept |

The screen is frozen with `hyprpicker -r -z` while the selection is being drawn, so menus and
animations stay where they are. Every shot goes to `~/Pictures/Screenshots` **and** to the
clipboard, and the notification carries the image as its own thumbnail. Set `SCREENSHOT_DIR` to
save somewhere else.

</details>

<details>
<summary><b>Screen recording</b> — <sub>monitor or region, with system audio</sub></summary>


`config/hypr/scripts/record-toggle.sh` toggles: the first call starts, the second stops, whatever
mode started it.

| Argument | Effect |
| --- | --- |
| `screen` | the monitor under the cursor (default) |
| `region` | an area drawn with the mouse |
| `--mic` | record the microphone instead of the system output |
| `--no-audio` | video only |

By default the system output is recorded through the monitor source of the default sink, so a
recording carries the sound you actually heard. Files go to `~/Videos` (`RECORD_DIR` overrides it),
and the path of the finished file lands in the clipboard.

While something is being recorded the bar shows a pulsing red dot and the elapsed time — click it
to stop.

</details>

<details>
<summary><b>The bar</b> — <sub>what every island is and why it is there</sub></summary>


Workspaces on the left, clock in the middle, and on the right three groups divided by hairlines:
the recording indicator and the tray; Wi-Fi, microphone and volume; keyboard layout and battery.
Contrast follows how often something is read — battery and layout carry it, glyphs stay at 75%
opacity, and only a problem state takes colour, so a dropped Wi-Fi link or a muted microphone is
the one thing that stands out. The layout badge (`EN` / `RU` / `UA` …) follows
`Alt`+`Shift` and can also be clicked to cycle layouts.

`Super`+`Shift`+`M` opens the audio panel on the same orbit view: the current output sits in the
middle with its volume drawn as an arc around it, and every other sink circles it. Click a device to
make it the default, roll the wheel over it to set that device's own volume, or over the core for
the current one. `Tab` switches between outputs and inputs, `+`/`-` change the level, `M` mutes,
`Escape` closes.

Folder icons follow as well. Papirus ships one folder set per colour, and
`config/hypr/scripts/papirus-tint.py` picks whichever is closest to the current accent in CIE Lab
and builds a small user icon theme that inherits Papirus-Dark and overrides only the folders — no
root, no touching `/usr/share`. It runs from a matugen hook, so a new wallpaper repaints the
folders with everything else.

Clicking the Wi-Fi glyph, or `Super`+`N`, opens the network panel, and `Super`+`B` opens it on the
Bluetooth tab. Both share one view: whatever you are connected to burns in the middle, and the
alternatives orbit it on two tilted rings — the stronger the signal, the closer in and the faster
it travels. Hovering a chip stops the rotation and prints the full detail under the graph, since a
96-pixel chip cannot hold a link rate and a MAC address. Clicking connects; a secured network opens
a password field; clicking the active one disconnects.

The ring radii, the chip size and the tilt are not a taste decision — the combination was checked by
exhaustive search, so no two chips can overlap at any pair of ring rotations. Beyond the eight
orbit slots the panel switches to a plain list with the same rows, and the footer says how many were
left out. Wi-Fi drives `nmcli` and refreshes off `nmcli monitor`; Bluetooth talks to BlueZ over
D-Bus, so battery levels and pairing state arrive as they change rather than on a poll.

Next to the workspaces sits the player: album art and a spectrum drawn by a second `cava` instance
reading raw levels off pipewire. The track name lives in the tooltip and in the panel instead of
scrolling in the bar. Clicking the art pauses, the island opens the player panel, the wheel changes
track. `cava` only runs while something is playing.

Hovering any bar element raises a tooltip under the strip — the bar window is taller than the strip
itself, and its input region is masked to the strip so the empty space passes clicks through to the
windows below. Clicking the clock opens a calendar.

Peripherals with their own battery — mouse, keyboard, headset — appear only once they drop below
40%, since a permanent "mouse charged" glyph is noise. While the launcher is open, the workspace
dots of the highlighted application light up, so a second copy never gets started by accident.

Volume, microphone and brightness all raise the same OSD card at the bottom of the focused screen.
The level is drawn as a travelling wave rather than a bar. While something is playing, the spectrum
from `cava` modulates the wave's local amplitude, so it swells with the music; a player that reports
"playing" while its stream is corked sends nothing but zeros, and the wave fades back to a plain sine
instead of collapsing into a straight line. Muting flattens the wave rather than hiding it.
Brightness goes through `brightnessctl -c backlight`; on machines that expose no backlight device
the OSD says so instead of the keys doing nothing at all.

The clock island has no seconds digits — they are too busy at this size. Instead a stroke walks the
island's own rounded border once a minute, so the movement is there without the mess. Switching
workspaces leaves a short streak between the old and new dot which retracts toward the destination,
so the eye follows the move rather than hunting for the active dot again. The album art sits inside
a thin arc showing the track position, which spends no width on a progress bar or a timestamp. A VPN
dot appears next to the network glyph only while a tunnel is up: detection is local and cheap, and
the exit address is fetched when the tunnel state changes or the dot is clicked, never on a timer.
At session start the islands drop in from above with a stagger, left to right, so the bar assembles
instead of appearing all at once.

</details>

<details>
<summary><b>Widgets</b> — <sub>system rings, the commit heatmap, notifications, focus mode</sub></summary>


**System rings** — `Super` + `F1` opens six thin arcs: CPU, RAM, temperature, GPU, VRAM and GPU
temperature. Each arc walks from accent to red as its load rises, and a dot rides the head. The whole
panel lives inside an inactive loader: while it is closed there is no window, no canvas, no timer and
no polling process, which keeps a widget that is glanced at a few times a day from querying
`nvidia-smi` around the clock. Hardware the machine does not have shows `n/a` rather than a
fabricated zero.

**Calendar heatmap** — day cells are shaded by how many commits were made that day, across every git
repository under `$HOME`. `git-activity.py` counts them into a JSON cache once an hour; the calendar
only reads it, so the panel never blocks on a filesystem walk. The scale is a square root rather than
linear: one commit should be visible, and the difference between twenty and thirty should not be.

**Notifications** — cards slide in from the right and leave the same way. The remaining lifetime is
drawn as a stroke retreating around the card's own rounded border, so the countdown is part of the
shape instead of a separate progress bar. Hovering pauses it. Critical notifications keep a static
border and wait for a click. Each card plays a generated sound: `gen-notify-sounds.py` synthesises a
soft struck-bar blip for normal ones, a lower falling pair for critical ones, and a dry knock for
hitting either end of the volume range. Nothing is shipped as a binary — retune the note tables and
re-run the script.

**Focus mode** — `Super` + `Ctrl` + `F` pushes everything except the active window into shadow:
inactive windows dim hard, blur drops a pass, and the animated border gradient stops. Toggling back
restores the values by name rather than reloading the whole config, so unsaved experiments survive.

</details>

<details>
<summary><b>Theming, at runtime</b> — <sub>why the palette is not a QML file any more</sub></summary>


matugen used to generate `Colors.qml` directly. Writing a QML file made Quickshell reload the entire
configuration on every wallpaper change: every object was rebuilt, so the colours could only ever
snap over. The palette now lands in `~/.cache/matugen/colors.json`, outside the config directory, and
`Colors.qml` is a hand-written singleton that watches that file and eases each colour into its new
value over about two thirds of a second. The accents lag the surfaces slightly, which reads as the
scheme rebuilding itself rather than as a filter dropped over everything at once.

The pointer follows the wallpaper too. `gen-cursor-theme.py` reads the palette, draws twelve cursor
shapes as SVG, and builds them into a hyprcursor theme with `hyprcursor-util`. Every shape is a thick
outline in the background colour under a fill in the accent, so it stays readable on a white page and
in a dark terminal alike. X11 aliases are declared, so GTK and Qt applications pick it up. XWayland
still needs an Xcursor build of the same theme, which `hyprcursor-util` cannot produce.

</details>

<details>
<summary><b>Desktop widgets</b> — <sub>the wallpaper layer, its editor, and the faces each widget has</sub></summary>


`Super` + `Shift` + `W` lifts the wallpaper layer into an editable state: a grid appears, widgets can
be dragged, the wheel resizes them, and a palette along the bottom adds more. Outside that mode the
layer carries an empty input mask, so clicks, drags and scrolls pass straight through to whatever is
behind it — the widgets are visible and completely intangible.

Positions are stored as fractions of the screen rather than pixels, so a layout arranged on a laptop
panel lands in the same place on an external monitor. Each widget has faces to switch between:

| Widget | Faces |
| --- | --- |
| clock | two stacked numerals, a line with the date, or handwritten strokes |
| music | sleeve with title and seek line, or the record itself, turning while it plays |
| weather | a card with a three day strip, or just a glyph and a number |
| system | rings, or labelled bars |
| screen time | today's applications as bars, or the total alone |

Missing album art draws a record — grooves, a rotating highlight, a blank paper label — because "no
cover" is the normal case for streams and radio, and a lone music glyph reads as a broken image.

</details>

<details>
<summary><b>Settings</b> — <sub>one card, one flag per feature</sub></summary>


`Super` + `Shift` + `P` opens one card of switches. Every optional surface of the shell — sounds,
desktop widgets, dock, drawing, screen time, the authorisation agent, idle handling — is one row
here, one flag in `Prefs`, and one loader in `shell.qml`. Turning something off costs nothing at
runtime; removing it means deleting its files and one line.

The same card carries the interface language, the bar's edge, the heading font and the notification
tone, each previewed on selection.

</details>

<details>
<summary><b>Sounds</b> — <sub>a sample per gesture, and why they are fired and forgotten</sub></summary>


Every gesture in the shell has a sound: a click for buttons, a heavier one for anything that commits,
distinct stingers for a panel opening and closing, a ratchet under a dragging finger, connect and
disconnect for the radios. Playback is fire-and-forget through `execDetached`, one process per
sample, because a single shared process can only hold one child — the second sound would cut the
first off mid-note.

Volume and the notification tone are in the settings; the whole set is one switch away from silence.

</details>

<details>
<summary><b>Equaliser</b> — <sub>PipeWire biquads, the curve, the spectrum behind it</sub></summary>


`Super` + `Shift` + `Q` opens ten bands built on PipeWire's own biquad filters — no EasyEffects, no
plugin packs, no second sound daemon. The graph is declared in
`config/pipewire/pipewire.conf.d/99-shell-eq.conf` and read when PipeWire starts; gains after that
are pushed live, one `pw-cli` call per change.

Two things share the same grid: the curve the bands make, and the live spectrum behind it while
something is playing. The sliders say what you asked for, the spectrum says whether there is anything
there to lift, and the curve over it shows where your hand landed relative to the music. Handles sit
on the curve rather than on a separate strip, and a double click returns one band to zero.

Presets: flat, bass, treble, vocal, pop, rock, jazz, classic, and a night curve that lifts both ends
for quiet listening.

</details>

<details>
<summary><b>Screen time</b> — <sub>counted in the shell, paused when locked, kept for two weeks</sub></summary>


Counted in the shell rather than by a background daemon: the shell already knows which toplevel is
focused, so a separate process would only duplicate that and then disagree with it. A coarse 15
second tick is enough for the shape of a day and cheap enough to leave running forever.

Counting stops while the session is locked and while the screen is off. History is kept for two
weeks, in `~/.local/state/quickshell/`, and never leaves the machine.

</details>

<details>
<summary><b>Authorisation</b> — <sub>the shell's own polkit prompt</sub></summary>


The shell draws its own polkit prompt. Without one, an unrelated agent draws it — a different font, a
different radius, a different idea of what a dialog looks like — at exactly the moment the user is
being asked to trust what is on screen. A wrong password shakes the card rather than only printing a
line of red text.

</details>

<details>
<summary><b>Files</b> — <sub>yazi in kitty, recoloured with everything else</sub></summary>


`Super` + `E` opens yazi inside kitty: image and video previews come through kitty's graphics
protocol as real pixels rather than icons, and the flavour is generated by matugen alongside
everything else, so the file manager recolours with the wallpaper. Thunar stays installed on
`Super` + `Shift` + `Y` for dragging files into other applications, which a terminal cannot do.

</details>

<details>
<summary><b>Languages</b> — <sub>English and Russian, switched without a restart</sub></summary>


The interface ships in English and Russian, switchable in the settings without a restart. Strings
live in `config/quickshell/f/lang/*.json`; plural rules belong to the language, so English supplies
two forms and Russian three. Month and weekday names come from the same tables rather than from Qt's
locale, because the shell's language is its own setting and does not follow `LANG`.

</details>

### Keybindings

`Super` is the modifier.

**Shell**

| Key | Action |
| --- | --- |
| `Super` + `D` | application launcher |
| `Super` + `C` | launcher in calculator mode |
| `Super` + `Tab` | window overview with live thumbnails |
| `Super` + `V` | clipboard history |
| `Super` + `Shift` + `V` | wipe the clipboard and its history |
| `Super` + `W` | wallpaper picker |
| `Super` + `Shift` + `B` | media browser (thumbnail grid) |
| `Super` + `N` | Wi-Fi networks |
| `Super` + `B` | Bluetooth devices |
| `Super` + `A` | media player panel |
| `Super` + `Shift` + `M` | audio panel (output and microphone) |
| `Super` + `Shift` + `D` | calendar with a commit heatmap |
| `Super` + `F1` | system monitor rings |
| `Super` + `Shift` + `N` | notification centre |
| `Super` + `Ctrl` + `N` | do not disturb |
| `Super` + `P` | power menu |
| `Super` + `Shift` + `L` | lock screen |

**Added recently**

| Key | Action |
| --- | --- |
| `Super` + `Shift` + `P` | settings — every optional part has a switch here |
| `Super` + `Shift` + `W` | arrange the desktop widgets |
| `Super` + `Shift` + `Q` | ten band equaliser |
| `Super` + `Shift` + `G` | draw over the screen |
| `Super` + `Shift` + `A` | pin the dock |
| `>` in the launcher | run the rest of the line in a shell |
| `=` in the launcher | calculate the rest of the line |

**Windows**

| Key | Action |
| --- | --- |
| `Super` + `Return` | terminal (kitty) |
| `Super` + `T` | scratchpad terminal |
| `Super` + `E` | file manager (yazi in kitty) |
| `Super` + `Shift` + `Y` | Thunar, for dragging files into other apps |
| `Super` + `Q` | close window |
| `Super` + `F` | fullscreen |
| `Super` + `Shift` + `F` | toggle floating |
| `Super` + `H` / `J` / `K` / `L` | move focus (vim keys) |
| `Super` + arrows | move a floating window |
| `Super` + `Shift` + arrows | resize a window |
| `Super` + `1`…`9` | switch workspace |
| `Super` + `Shift` + `1`…`9` | move window to workspace |
| `Super` + `Ctrl` + `F` | focus mode — only the active window stays lit |
| `Super` + `Shift` + `R` | reload Hyprland |
| `Super` + `Shift` + `E` | exit Hyprland |

**Capture**

| Key | Action |
| --- | --- |
| `Print` | screenshot of a selected area |
| `Shift` + `Print` | select an area and open the annotation editor |
| `Alt` + `Print` | screenshot of a window |
| `Super` + `Print` | screenshot of the current monitor |
| `Ctrl` + `Print` | screenshot of every monitor |
| `Super` + `Shift` + `S` | screenshot of a selected area |
| `Super` + `Shift` + `X` | blur a region of the last screenshot |
| `Super` + `Shift` + `C` | colour picker, hex to the clipboard |
| `Super` + `Shift` + `T` | recognise text in a selected area, copy it |
| `Super` + `Alt` + `R` | record the monitor, with system audio |
| `Super` + `Alt` + `Shift` + `R` | record a selected area |

**Sound and screen**

| Key | Action |
| --- | --- |
| media keys | play / pause, next, previous track |
| `Super` + `=` / `-` | output volume |
| `Super` + `Shift` + `=` / `-` | microphone volume |
| `Super` + `M` | mute the microphone |
| brightness keys | screen brightness, with an OSD |

**Maintenance**

| Key | Action |
| --- | --- |
| `Super` + `Shift` + `F3` | cache cleanup |
| `Super` + `Shift` + `F4` | system update |
| `Super` + `Shift` + `F5` | force a modeset on the internal panel |
| `Super` + `Alt` + `N` | test notification |
| `Super` + `Shift` + `Alt` + `N` | test critical notification |
| `Super` + `Ctrl` + `Shift` + `N` | four notifications in a row |

<details>
<summary><b>Layout</b> — <sub>where everything lives in the repository</sub></summary>


```
config/
  hypr/          Hyprland, hyprlock, wallpaper and utility scripts
  quickshell/f/  the shell itself
      design/      colours, motion curves, glass and grain primitives
      services/    singletons: audio, network, weather, screen time, prefs, i18n
      reusables/   buttons, switches, sliders, fields, rings, the record
      bar/         the bar
      panels/      launcher, clipboard, calendar, settings, equaliser, tour
      desk/        wallpaper-layer widgets and their editor
      overlays/    notifications, OSD, lock, dock, drawing, polkit
      lang/        en.json, ru.json
  matugen/       colour-scheme templates for every application
  pipewire/      the equaliser graph
  zed/           editor settings
  firejail/      sandbox overrides shared by every profile
  cliphist/      clipboard history limits
  kitty/         terminal
  rofi/          launcher
  cava/          audio visualiser themes and shaders
  wlogout/       power menu
  yazi/          file manager
  fastfetch/     system information
  gtk-3.0, gtk-4.0, qt5ct, qt6ct
  starship.toml  shell prompt
home/            .zshrc, .zshenv, .bashrc
bin/             shell-autostart, shell-switch, shell-watchdog, dots-update
install.sh       automatic installer
extras/          pacman hook and helper that snapshot /etc before a transaction
IDEAS.md         a running list of what could be built next
```

Files generated at runtime — `colors.conf`, `lock-colors.conf`, `colors.css`,
`current-wallpaper`, `hyprpaper.conf` — are deliberately not tracked; matugen writes them on the
first run. `Colors.qml` is tracked: it is now source rather than a build product, and reads the
palette from `~/.cache/matugen/colors.json` at runtime.

</details>

<details>
<summary><b>Requirements</b> — <sub>the package list</sub></summary>


Arch or Artix Linux with an AUR helper (the installer builds `yay` if none is present).

**Repositories:** hyprland · hyprlock · hyprpaper · hyprpolkitagent · xdg-desktop-portal-hyprland ·
kitty · rofi-wayland · cava · fastfetch · yazi · starship · zoxide · fzf · eza ·
bat · ripgrep · lazygit · thunar · brightnessctl · playerctl · pipewire · wireplumber · cliphist ·
wl-clipboard · grim · slurp · satty · hyprpicker · ffmpeg · imagemagick · qt5ct · qt6ct · kvantum ·
kvantum-qt5 · papirus-icon-theme ·
ttf-jetbrains-mono-nerd · zsh

**AUR:** quickshell · matugen-bin · wlogout · wf-recorder · wl-clip-persist

Also `hypridle` for the idle timer.

On Artix, install the service packages for your init system (`-openrc`, `-runit`, `-s6`) instead of
the systemd variants.

</details>

<details>
<summary><b>Notes</b> — <sub>hardware, quirks and honest caveats</sub></summary>


* NVIDIA-specific environment variables live in `config/hypr/config/env.conf` — remove them on AMD
  or Intel hardware.
* Monitors are declared in `config/hypr/config/monitors.conf`; adjust it for your outputs.
* Wallpapers are read from `~/Pictures/Wallpapers` and rotate every three hours; the interval is
  set in `config/hypr/scripts/wallpaper-rotate.sh`.

</details>

### License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

---

## Русский

<div align="center">

|  |  |  |  |
| --- | --- | --- | --- |
| **дистрибутив** | Arch · Artix (OpenRC) | **шелл** | Quickshell 0.3 |
| **оконный менеджер** | Hyprland 0.56 | **цвета** | matugen, из обоев |
| **терминал** | kitty | **файлы** | yazi, превью настоящими пикселями |
| **редактор** | Zed | **звук** | PipeWire + filter-chain эквалайзер |
| **шрифты** | JetBrains Mono · Adwaita Sans | **приглашение** | zsh + starship |

</div>

<br>


### Что это

Полная конфигурация рабочего окружения на [Hyprland](https://hypr.land): оконный менеджер, панель,
лаунчер, история буфера обмена, уведомления, экранные индикаторы, экран блокировки, терминал,
файловый менеджер и оболочка. Все цвета в системе выводятся из текущих обоев через
[matugen](https://github.com/InioX/matugen) (Material You), поэтому оформление всегда совпадает с
тем, что на экране.

Оболочка целиком на Quickshell: панель, лаунчер, буфер обмена, уведомления, индикаторы
громкости и яркости, выбор обоев, обзор окон и меню выключения — всё один процесс.

За ним следит watchdog: упавший Quickshell перезапускается, а после трёх падений подряд попытки
прекращаются и приходит уведомление — вместо бесконечного мигания панели. `shell-switch status`
показывает состояние, `shell-switch restart` перезапускает.

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

<details>
<summary><b>Обновление</b> — <sub>одна команда и что она не тронет</sub></summary>


Если конфигурация уже стоит, установщик заново гонять не нужно — есть отдельный режим обновления,
который не трогает систему и подтягивает только конфиги:

```bash
dots-update
```

Он забирает свежую ревизию, показывает список коммитов, которые приедут, раскладывает файлы (всё
заменяемое сначала уходит в резервную копию), доставляет только реально отсутствующие пакеты —
полного обновления системы не делает, — пересобирает палитру по текущим обоям и перезапускает
Hyprland с панелью на месте. Перелогиниваться не надо.

Из клона то же самое:

```bash
cd hyprdots && ./install.sh --update
```

`--dry-run` работает и здесь: покажет каждый шаг, ничего не меняя.

</details>

<details>
<summary><b>Оформление</b> — <sub>как обои становятся палитрой и куда уходит каждый шаблон</sub></summary>


```
обои ──▶ matugen ──┬──▶ hyprland   рамки окон
                   ├──▶ hyprlock   экран блокировки
                   ├──▶ quickshell панель, лаунчер, индикаторы
                   ├──▶ kitty      палитра терминала
                   ├──▶ rofi       лаунчер
                   ├──▶ dunst      уведомления
                   ├──▶ gtk 3/4    Thunar и остальные GTK-приложения
                   ├──▶ papirus    иконки папок в тон акценту
                   ├──▶ wlogout    меню выключения
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

</details>

<details>
<summary><b>Аппаратное декодирование видео</b> — <sub>NVIDIA, VA-API и флаги браузера, которые правда важны</sub></summary>


Сессия уже экспортирует `LIBVA_DRIVER_NAME=nvidia` и `NVD_BACKEND=direct`, но этого мало: нужен
`libva-nvidia-driver`, который связывает VA-API с NVDEC, и каждому браузеру надо отдельно сказать
им пользоваться.

Chromium принимает флаги только в командной строке — бинарник не обёртка, редактировать
`chromium-flags.conf` нечего; скопируй ярлык в `~/.local/share/applications/` и допиши:

```
--ozone-platform-hint=auto --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy --use-gl=angle --use-angle=gl
```

Firefox и LibreWolf читают `user.js` в активном профиле:

```js
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("widget.dmabuf.force-enabled", true);
user_pref("gfx.webrender.all", true);
user_pref("media.av1.enabled", false);
```

и переменную `MOZ_DISABLE_RDD_SANDBOX=1`, иначе процесс декодера не достучится до драйвера. AV1
выключен намеренно: у Pascal и более старых карт аппаратного декодера AV1 нет, и такие потоки
тихо уезжают обратно на процессор.

Проверять в `chrome://gpu` и `about:support` или через `nvidia-smi dmon` во время
воспроизведения — колонка `dec` остаётся нулевой, пока декодирование идёт на процессоре.

</details>

<details>
<summary><b>Простой</b> — <sub>таймеры в шелле, решение — в одном скрипте</sub></summary>


Шелл блокирует сессию через 50 минут без ввода и гасит панели ещё через пять. Оба таймера лежат в
настройках самого шелла, а не в третьем конфиге со своим синтаксисом, но решение «стоит ли» осталось
за `config/hypr/scripts/idle-guard.sh`: он не даёт сработать, пока окно развёрнуто на весь экран,
пока реально играет звук (поток откупорен, а не просто держит устройство), пока идёт запись и пока
жив любой процесс из `~/.config/hypr/idle-inhibit.list`.

Это сделано намеренно: скрипт уже знает все причины не блокировать, а второе мнение, написанное на
QML, только спорило бы с ним.

Список сверяется с именами процессов через `pgrep -x`, по одному в строке. В репозитории лежит
только `idle-inhibit.list.example` — скопируйте и допишите своё, рабочая копия из репозитория
исключена.

`hypridle` больше не запускается; строка оставлена закомментированной в
`config/hypr/config/startup.conf`.

</details>

<details>
<summary><b>Меню выключения</b> — <sub>почему это панель, а не скрипт</sub></summary>


`Super`+`P` открывает меню Quickshell: часы, аптайм и заряд батареи над пятью плитками —
заблокировать, сон, выйти, перезагрузка, выключение. У каждой плитки своя буква, так что `l`, `s`,
`e`, `r` и `p` срабатывают сразу; стрелки двигают выбор, `Enter` подтверждает, `Escape` или клик
мимо закрывают. Перезагрузка и выключение подсвечиваются красным вместо цвета темы — два
необратимых пункта не выглядят как остальные.

Цвета берутся из обоев, как и везде. `wlogout` по-прежнему красится из той же палитры и остаётся
отдельным меню выключения.

</details>

<details>
<summary><b>Скриншоты</b> — <sub>область, окно, монитор, пипетка, распознавание текста</sub></summary>


`config/hypr/scripts/screenshot.sh` принимает один аргумент и закрывает все случаи:

| Режим | Что снимает |
| --- | --- |
| `region` | область, выделенную мышью |
| `window` | одно окно ровно по его границам |
| `output` | монитор под курсором |
| `all` | все подключённые мониторы одним снимком |
| `edit` | область, затем [satty](https://github.com/gabm/Satty) — стрелки, размытие, текст |
| `color` | цвет под курсором, hex в буфер обмена |
| `ocr` | область, её текст распознаётся и уходит в буфер — картинка не сохраняется |

Пока идёт выделение, экран заморожен через `hyprpicker -r -z` — меню и анимации не убегают. Каждый
снимок попадает в `~/Pictures/Screenshots` **и** в буфер обмена, а уведомление показывает его же
миниатюрой. Другая папка задаётся переменной `SCREENSHOT_DIR`.

</details>

<details>
<summary><b>Запись экрана</b> — <sub>монитор или область, со звуком системы</sub></summary>


`config/hypr/scripts/record-toggle.sh` работает переключателем: первый вызов запускает, второй
останавливает — в каком бы режиме запись ни началась.

| Аргумент | Что делает |
| --- | --- |
| `screen` | монитор под курсором (по умолчанию) |
| `region` | область, выделенная мышью |
| `--mic` | писать микрофон вместо звука системы |
| `--no-audio` | только видео |

По умолчанию пишется звук системы — через monitor-источник текущего вывода, то есть в записи будет
то, что было слышно. Файлы уходят в `~/Videos` (меняется переменной `RECORD_DIR`), путь готового
файла попадает в буфер обмена.

Пока идёт запись, в панели мигает красная точка с таймером — клик по ней останавливает запись.

</details>

<details>
<summary><b>Панель</b> — <sub>что такое каждый островок и зачем он там</sub></summary>


Слева рабочие столы, по центру часы, справа три группы, разделённые волосяными линиями: индикатор
записи и трей; Wi-Fi, микрофон и громкость; раскладка и батарея. Контраст расставлен по частоте
обращения: батарея и раскладка держат его на себе, значки приглушены до 75% прозрачности, цвет
берут только проблемные состояния — отвалившийся Wi-Fi или выключенный микрофон.

Иконки папок тоже. Papirus содержит по набору папок на каждый цвет, а
`config/hypr/scripts/papirus-tint.py` выбирает ближайший к текущему акценту в пространстве CIE Lab
и собирает маленькую пользовательскую тему иконок: она наследует Papirus-Dark и подменяет только
папки — без root и без записи в `/usr/share`. Запускается хуком matugen, поэтому новые обои
перекрашивают папки вместе со всем остальным.

Рядом с рабочими столами живёт плеер: обложка и спектр, который рисует второй экземпляр `cava`,
читающий сырые уровни с pipewire. Название трека вынесено в подсказку и в панель, а не бежит
строкой по бару. Клик по обложке ставит паузу, клик по островку открывает панель плеера, колесо
переключает треки. `cava` запускается только пока что-то играет.

Наведение на любой элемент бара поднимает подсказку под полосой: окно бара выше самой полосы, а
область ввода обрезана по ней, поэтому пустое место пропускает клики к окнам под баром. Клик по
часам открывает календарь.

Периферия со своей батареей — мышь, клавиатура, гарнитура — показывается только когда заряд падает
ниже 40%: постоянный значок «мышь заряжена» это шум. Пока открыт лаунчер, точки рабочих столов, где
уже запущено подсвеченное приложение, загораются — вторая копия не заводится по недосмотру.

Клик по значку Wi-Fi (или `Super`+`N`) открывает панель сетей, `Super`+`B` — её же на вкладке
Bluetooth. Вид общий: то, к чему подключён, горит в центре, остальное вращается вокруг по двум
наклонённым кольцам — чем сильнее сигнал, тем ближе к центру и тем быстрее орбита. Наведение
останавливает вращение и печатает подробности под графом: в чип шириной 96 пикселей не влезают ни
скорость канала, ни MAC. Клик подключает, защищённая сеть открывает поле пароля, клик по активной
отключает.

Радиусы колец, размер чипа и наклон — не вопрос вкуса: сочетание проверено полным перебором, и при
любом взаимном повороте колец два чипа не могут наложиться. Всё, что не поместилось в восемь
орбитальных мест, доступно в списочном режиме, а в подвале написано, сколько осталось за кадром.
Wi-Fi работает через `nmcli` и обновляется по событиям `nmcli monitor`, Bluetooth разговаривает с
BlueZ по D-Bus, поэтому заряд наушников и состояние сопряжения приходят по факту изменения, а не по
опросу. Индикатор раскладки (`EN` / `RU` / `UA` …) следует за `Alt`+`Shift`, по нему же можно
кликнуть, чтобы переключить раскладку.

`Super`+`Shift`+`M` открывает панель звука на том же орбитальном виде: текущий выход в центре,
громкость нарисована дугой вокруг него, остальные устройства кружат рядом. Клик делает устройство
основным, колесо над ним меняет громкость именно этого устройства, над ядром — текущего. `Tab`
переключает выход и вход, `+`/`-` меняют уровень, `M` заглушает, `Escape` закрывает.

Громкость, микрофон и яркость показывают одну и ту же карточку внизу активного экрана. Уровень
нарисован бегущей волной, а не полоской. Пока что-то играет, спектр из `cava` управляет местной
амплитудой волны — она вздувается там, где громче. Плеер иногда рапортует «играет», когда поток
на самом деле остановлен: тогда во всех полосах нули, и волна плавно возвращается к обычной
синусоиде, а не схлопывается в прямую. Мьют не прячет индикатор, а распрямляет его. Яркость идёт
через `brightnessctl -c backlight`; если устройства подсветки в системе нет, индикатор так и
скажет, вместо того чтобы клавиши молча ничего не делали.

У часов нет цифр секунд — на таком размере они суетливы. Вместо них обводка обходит контур самого
островка за минуту: движение есть, мельтешения нет. При переключении рабочего стола между старой и
новой точкой протягивается полоска, которая втягивается в точку назначения, поэтому взгляд следует
за переходом, а не ищет активную точку заново. Обложка трека сидит внутри тонкой дуги прогресса —
позиция читается, не отнимая ширины под полосу или цифры. Рядом со значком сети появляется точка
VPN, но только пока туннель поднят: определение локальное и дешёвое, а внешний адрес запрашивается
при смене состояния туннеля или по клику, не по таймеру. При старте сессии островки падают сверху
со сдвигом слева направо — бар собирается, а не возникает целиком.

</details>

<details>
<summary><b>Виджеты</b> — <sub>кольца системы, тепловая карта коммитов, уведомления, фокус-режим</sub></summary>


**Кольца системы** — `Super`+`F1` открывает шесть тонких дуг: CPU, RAM, температура, GPU, VRAM и
температура GPU. Цвет дуги идёт от акцента к красному по мере нагрузки, по её концу едет точка. Вся
панель живёт внутри неактивного загрузчика: пока она закрыта, нет ни окна, ни канвы, ни таймера, ни
процесса опроса. Виджет, на который смотрят пару раз в день, не дёргает `nvidia-smi` круглые сутки.
Железо, которого в машине нет, показывает `n/a`, а не выдуманный ноль.

**Тепловая карта в календаре** — ячейки дней залиты по числу коммитов за этот день во всех git-репозиториях
внутри `$HOME`. `git-activity.py` считает их в JSON-кэш раз в час, календарь только читает его и
никогда не ждёт обхода файловой системы. Шкала корневая, а не линейная: один коммит должен быть
заметен, а разница между двадцатью и тридцатью — нет.

**Уведомления** — карточки выезжают справа и уходят туда же. Остаток времени рисуется обводкой,
которая отступает по контуру самой карточки, поэтому отсчёт стал частью формы, а не отдельной
полосой. Наведение ставит его на паузу. Критические держат статичную рамку и ждут клика. Каждая
карточка играет сгенерированный звук: `gen-notify-sounds.py` синтезирует мягкий удар по бруску для
обычных, ниже и с падением для критических, и сухой стук на упор громкости. Ничего не лежит готовым
бинарником — правь таблицы нот и перезапускай скрипт.

**Фокус-режим** — `Super`+`Ctrl`+`F` уводит в тень всё, кроме активного окна: неактивные сильно
затемняются, блюр теряет проход, градиент рамки замирает. Обратное переключение возвращает значения
поимённо, а не перечитывает весь конфиг, поэтому несохранённые эксперименты переживают его.

</details>

<details>
<summary><b>Палитра в рантайме</b> — <sub>почему палитра больше не QML-файл</sub></summary>


Раньше matugen генерировал `Colors.qml` напрямую. Запись QML-файла заставляла Quickshell перечитать
весь конфиг при каждой смене обоев: все объекты пересоздавались, и цвета могли меняться только
скачком. Теперь палитра ложится в `~/.cache/matugen/colors.json`, вне каталога конфига, а
`Colors.qml` — написанный руками синглтон, который следит за этим файлом и переливает каждый цвет в
новый примерно за две трети секунды. Акценты немного отстают от поверхностей, и это читается как
пересборка схемы, а не как наложенный поверх всего фильтр.

Курсор тоже следует за обоями. `gen-cursor-theme.py` читает палитру, рисует двенадцать фигур в SVG и
собирает их в тему hyprcursor через `hyprcursor-util`. У каждой фигуры жирная обводка цветом фона под
заливкой акцентом, поэтому она читается и на белой странице, и в тёмном терминале. Прописаны X11-алиасы,
так что GTK- и Qt-приложения её подхватывают. Для XWayland нужна та же тема в формате Xcursor,
которую `hyprcursor-util` собирать не умеет.

</details>

<details>
<summary><b>Виджеты на столе</b> — <sub>слой обоев, редактор и виды каждого виджета</sub></summary>


`Super` + `Shift` + `W` поднимает слой обоев в режим правки: появляется сетка, виджеты таскаются
мышью, колесо меняет размер, снизу выезжает палитра. Вне этого режима у слоя пустая маска ввода —
клики, перетаскивания и прокрутка проходят насквозь, виджеты видно и они неосязаемы.

Позиции хранятся долями экрана, а не пикселями, поэтому раскладка, собранная на ноутбучной матрице,
ложится так же на внешнем мониторе. У каждого виджета несколько видов:

| Виджет | Виды |
| --- | --- |
| часы | две цифры друг под другом, строка с датой или рукописные штрихи |
| музыка | конверт с названием и полосой позиции либо сама пластинка, вращающаяся при игре |
| погода | карточка с прогнозом на три дня или только глиф и число |
| система | кольца или подписанные полосы |
| экранное время | приложения за сегодня полосами или один итог |

Когда обложки нет, рисуется пластинка — дорожки, вращающийся блик, пустая бумажная этикетка. Для
радио и потоков «без обложки» это норма, а одинокий значок ноты читается как битая картинка.

</details>

<details>
<summary><b>Настройки</b> — <sub>одна карточка, по флагу на функцию</sub></summary>


`Super` + `Shift` + `P` открывает одну карточку с переключателями. Каждая необязательная часть шелла
— звуки, виджеты, док, рисование, экранное время, агент прав, простой — это одна строка здесь, один
флаг в `Prefs` и один загрузчик в `shell.qml`. Выключенное не стоит ничего, а удаляется вместе со
своими файлами и одной строкой.

Там же язык интерфейса, край для бара, шрифт заголовков и сигнал уведомлений — каждый с
предпрослушкой или мгновенным применением.

</details>

<details>
<summary><b>Звук интерфейса</b> — <sub>по сэмплу на жест и почему они «выстрелил и забыл»</sub></summary>


У каждого жеста свой звук: клик для кнопок, тяжелее — для действий, которые что-то подтверждают,
разные стингеры на открытие и закрытие панели, храповик под тянущей рукой, подключение и отключение
для радиомодулей. Воспроизведение — «выстрелил и забыл» через `execDetached`, по процессу на сэмпл:
один общий процесс держит только одного ребёнка, и второй звук обрывал бы первый на полуноте.

Громкость и сигнал — в настройках, вся система выключается одним тумблером.

</details>

<details>
<summary><b>Эквалайзер</b> — <sub>биквады PipeWire, кривая и спектр за ней</sub></summary>


`Super` + `Shift` + `Q` — десять полос на штатных биквадах PipeWire: ни EasyEffects, ни наборов
плагинов, ни второго звукового демона. Граф описан в
`config/pipewire/pipewire.conf.d/99-shell-eq.conf` и читается при старте PipeWire, а усиления потом
уходят живьём, по одному вызову `pw-cli` на изменение.

На одной сетке две вещи: кривая, которую задают полосы, и живой спектр за ней, пока что-то играет.
Ползунки говорят, что попросили; спектр — есть ли там что поднимать; кривая поверх показывает, куда
легла рука относительно музыки. Ручки сидят на самой кривой, двойной клик обнуляет полосу.

Пресеты: ровно, низы, верхи, голос, поп, рок, джаз, классика и ночная кривая, поднимающая оба края
для тихого прослушивания.

</details>

<details>
<summary><b>Экранное время</b> — <sub>считает шелл, пауза на локскрине, хранится две недели</sub></summary>


Считает сам шелл, а не фоновый демон: он и так знает, какое окно в фокусе, и отдельный процесс лишь
дублировал бы это, чтобы потом с ним не сойтись. Шаг в 15 секунд достаточно точен для формы дня и
достаточно дёшев, чтобы работать всегда.

Счёт останавливается на локскрине и при погашенном экране. История хранится две недели в
`~/.local/state/quickshell/` и никуда не уходит с машины.

</details>

<details>
<summary><b>Запрос прав</b> — <sub>свой polkit-агент</sub></summary>


Шелл рисует свой polkit-агент. Без него запрос рисует чужой — другой шрифт, другие радиусы, другое
представление о том, как выглядит диалог, — ровно в тот момент, когда у человека спрашивают, доверяет
ли он тому, что на экране. Неверный пароль встряхивает карточку, а не просто печатает красную строку.

</details>

<details>
<summary><b>Файлы</b> — <sub>yazi в kitty, перекрашенный вместе со всем</sub></summary>


`Super` + `E` открывает yazi внутри kitty: превью картинок и видео идут честными пикселями через
графический протокол kitty, а флейвор генерируется matugen вместе со всем остальным — проводник
перекрашивается вслед за обоями. Thunar остался на `Super` + `Shift` + `Y` для перетаскивания файлов
в другие программы, чего терминал не умеет.

</details>

<details>
<summary><b>Языки</b> — <sub>английский и русский, без перезапуска</sub></summary>


Интерфейс на английском и русском, переключается в настройках без перезапуска. Строки лежат в
`config/quickshell/f/lang/*.json`; правило множественного числа принадлежит языку, поэтому английский
отдаёт две формы, русский три. Названия месяцев и дней берутся оттуда же, а не из локали Qt: язык
шелла — отдельная настройка и за `LANG` не следует.

</details>

### Горячие клавиши

Модификатор — `Super`.

**Шелл**

| Клавиши | Действие |
| --- | --- |
| `Super` + `D` | лаунчер |
| `Super` + `C` | лаунчер в режиме счёта |
| `Super` + `Tab` | обзор окон с живыми превью |
| `Super` + `V` | история буфера обмена |
| `Super` + `Shift` + `V` | очистить буфер и историю |
| `Super` + `W` | выбор обоев |
| `Super` + `Shift` + `B` | медиабраузер (сетка миниатюр) |
| `Super` + `N` | сети Wi-Fi |
| `Super` + `B` | устройства Bluetooth |
| `Super` + `A` | панель плеера |
| `Super` + `Shift` + `M` | звук: вывод и микрофон |
| `Super` + `Shift` + `D` | календарь с тепловой картой коммитов |
| `Super` + `F1` | кольца системного монитора |
| `Super` + `Shift` + `N` | центр уведомлений |
| `Super` + `Ctrl` + `N` | не беспокоить |
| `Super` + `P` | меню выключения |
| `Super` + `Shift` + `L` | заблокировать экран |

**Добавлено недавно**

| Клавиши | Действие |
| --- | --- |
| `Super` + `Shift` + `P` | настройки — у каждой необязательной части свой тумблер |
| `Super` + `Shift` + `W` | правка виджетов на столе |
| `Super` + `Shift` + `Q` | эквалайзер на десять полос |
| `Super` + `Shift` + `G` | рисовать поверх экрана |
| `Super` + `Shift` + `A` | закрепить док |
| `>` в лаунчере | выполнить остаток строки в шелле |
| `=` в лаунчере | посчитать остаток строки |

**Окна**

| Клавиши | Действие |
| --- | --- |
| `Super` + `Return` | терминал (kitty) |
| `Super` + `T` | выпадающий терминал |
| `Super` + `E` | файловый менеджер (yazi в kitty) |
| `Super` + `Shift` + `Y` | Thunar, для перетаскивания файлов |
| `Super` + `Q` | закрыть окно |
| `Super` + `F` | на весь экран |
| `Super` + `Shift` + `F` | плавающее окно |
| `Super` + `H` / `J` / `K` / `L` | переход фокуса (vim) |
| `Super` + стрелки | двигать плавающее окно |
| `Super` + `Shift` + стрелки | менять размер окна |
| `Super` + `1`…`9` | переключить рабочий стол |
| `Super` + `Shift` + `1`…`9` | перенести окно на стол |
| `Super` + `Ctrl` + `F` | фокус-режим — светится только активное окно |
| `Super` + `Shift` + `R` | перезагрузить Hyprland |
| `Super` + `Shift` + `E` | выйти из Hyprland |

**Снимки и запись**

| Клавиши | Действие |
| --- | --- |
| `Print` | снимок выделенной области |
| `Shift` + `Print` | выделить область и открыть редактор |
| `Alt` + `Print` | снимок окна |
| `Super` + `Print` | снимок текущего монитора |
| `Ctrl` + `Print` | снимок всех мониторов |
| `Super` + `Shift` + `S` | снимок выделенной области |
| `Super` + `Shift` + `X` | замылить область на последнем снимке |
| `Super` + `Shift` + `C` | пипетка, hex в буфер |
| `Super` + `Shift` + `T` | распознать текст в области и скопировать |
| `Super` + `Alt` + `R` | запись монитора со звуком системы |
| `Super` + `Alt` + `Shift` + `R` | запись выделенной области |

**Звук и экран**

| Клавиши | Действие |
| --- | --- |
| мультимедийные клавиши | пауза, следующий и предыдущий трек |
| `Super` + `=` / `-` | громкость вывода |
| `Super` + `Shift` + `=` / `-` | громкость микрофона |
| `Super` + `M` | выключить микрофон |
| клавиши яркости | яркость экрана с индикатором |

**Обслуживание**

| Клавиши | Действие |
| --- | --- |
| `Super` + `Shift` + `F3` | очистка кэшей |
| `Super` + `Shift` + `F4` | обновление системы |
| `Super` + `Shift` + `F5` | принудительный modeset внутренней матрицы |
| `Super` + `Alt` + `N` | тестовое уведомление |
| `Super` + `Shift` + `Alt` + `N` | тестовое критическое |
| `Super` + `Ctrl` + `Shift` + `N` | четыре подряд |

<details>
<summary><b>Структура</b> — <sub>где что лежит в репозитории</sub></summary>


```
config/
  hypr/          Hyprland, hyprlock, скрипты обоев и утилит
  quickshell/f/  сам шелл
      design/      цвета, кривые движения, стекло и зерно
      services/    синглтоны: звук, сеть, погода, экранное время, настройки, языки
      reusables/   кнопки, переключатели, ползунки, поля, кольца, пластинка
      bar/         панель
      panels/      лаунчер, буфер, календарь, настройки, эквалайзер, тур
      desk/        виджеты на слое обоев и их редактор
      overlays/    уведомления, индикаторы, локскрин, док, рисование, polkit
      lang/        en.json, ru.json
  matugen/       шаблоны цветовой схемы для всех приложений
  pipewire/      граф эквалайзера
  zed/           настройки редактора
  firejail/      общие правила песочницы для всех профилей
  cliphist/      ограничения истории буфера обмена
  kitty/         терминал
  rofi/          лаунчер
  cava/          темы и шейдеры визуализатора звука
  wlogout/       меню выключения
  yazi/          файловый менеджер
  fastfetch/     информация о системе
  gtk-3.0, gtk-4.0, qt5ct, qt6ct
  starship.toml  приглашение оболочки
home/            .zshrc, .zshenv, .bashrc
bin/             shell-autostart, shell-switch, shell-watchdog, dots-update
install.sh       автоматический установщик
extras/          хук pacman и скрипт, снимающий /etc перед транзакцией
IDEAS.md         список того, что можно сделать дальше
```

Файлы, которые создаются во время работы — `colors.conf`, `lock-colors.conf`, `colors.css`,
`current-wallpaper`, `hyprpaper.conf` — намеренно не хранятся в репозитории: matugen пишет их при
первом запуске. `Colors.qml` теперь хранится: это исходник, а не продукт сборки, и палитру он читает
из `~/.cache/matugen/colors.json` в рантайме.

</details>

<details>
<summary><b>Требования</b> — <sub>список пакетов</sub></summary>


Arch или Artix Linux, помощник AUR (если его нет, установщик соберёт `yay`).

**Репозитории:** hyprland · hyprlock · hyprpaper · hyprpolkitagent · xdg-desktop-portal-hyprland ·
kitty · rofi-wayland · cava · fastfetch · yazi · starship · zoxide · fzf · eza ·
bat · ripgrep · lazygit · thunar · brightnessctl · playerctl · pipewire · wireplumber · cliphist ·
wl-clipboard · grim · slurp · satty · hyprpicker · ffmpeg · imagemagick · qt5ct · qt6ct · kvantum ·
kvantum-qt5 · papirus-icon-theme ·
ttf-jetbrains-mono-nerd · zsh

**AUR:** quickshell · matugen-bin · wlogout · wf-recorder · wl-clip-persist

Also `hypridle` for the idle timer.

На Artix ставьте пакеты служб под свою систему инициализации (`-openrc`, `-runit`, `-s6`) вместо
systemd-вариантов.

</details>

<details>
<summary><b>Замечания</b> — <sub>железо, особенности и честные оговорки</sub></summary>


* Переменные окружения для NVIDIA лежат в `config/hypr/config/env.conf` — на AMD и Intel их нужно
  убрать.
* Мониторы описаны в `config/hypr/config/monitors.conf`, поправьте под свои выходы.
* Обои берутся из `~/Pictures/Wallpapers` и меняются раз в три часа; интервал задаётся в
  `config/hypr/scripts/wallpaper-rotate.sh`.

</details>

### Лицензия

GNU General Public License v3.0 — см. [LICENSE](LICENSE).


---

<div align="center">
<br>

**[Screenshots](#hyprland-desktop) · [Install](#install) · [Keybindings](#keybindings) · [What changed](docs/UPDATE.md)**

<sub>MIT. Take any part of it — the shell, a single panel, the palette pipeline — and make it yours.</sub>

<br>
</div>
