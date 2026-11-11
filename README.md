<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/brand/banner-dark.png">
  <img src="assets/brand/banner-light.png" alt="Rosa: a dew drop on a leaf next to the island" width="100%">
</picture>

<br>

**A Hyprland desktop built around one liquid island.**

Every colour comes from your wallpaper. Every part can be switched off. Nothing makes noise it doesn't need to.

<br>

<a href="docs/GUIDE.md"><img src="https://img.shields.io/badge/guide-English-E3DACB?style=flat-square&labelColor=1A1816" alt="Guide"></a>
<a href="docs/GUIDE.ru.md"><img src="https://img.shields.io/badge/руководство-Русский-E3DACB?style=flat-square&labelColor=1A1816" alt="Руководство"></a>
<a href="docs/UPDATE.md"><img src="https://img.shields.io/badge/what's-new-D27352?style=flat-square&labelColor=1A1816" alt="What changed"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-B0A08E?style=flat-square&labelColor=1A1816" alt="License"></a>

<img src="https://img.shields.io/badge/Hyprland-0.56-1A1816?style=flat-square&labelColor=D27352" alt="Hyprland">
<img src="https://img.shields.io/badge/Quickshell-0.3-1A1816?style=flat-square&labelColor=D27352" alt="Quickshell">
<img src="https://img.shields.io/badge/Arch-systemd-1A1816?style=flat-square&labelColor=D27352" alt="Arch">
<img src="https://img.shields.io/badge/Artix-OpenRC-1A1816?style=flat-square&labelColor=D27352" alt="Artix">
<img src="https://img.shields.io/badge/matugen-Material%20You-1A1816?style=flat-square&labelColor=D27352" alt="matugen">

<br>
<br>

<img src="assets/island/island-hero.jpg" alt="The dynamic island expanded into a music card" width="100%">

<br>
<br>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fedyaqq34356/rosa/main/install.sh)
```

<sub>Arch or Artix · AMD, Intel or NVIDIA, detected on its own · your old configs are backed up first · <a href="#uninstall">one command to undo</a></sub>

</div>

<br>

## Quiet by design

<img src="assets/brand/rosa-film.gif" alt="A drop falls on a leaf, becomes the island, the island opens into a player, splits into windows, notes, a calendar, song lyrics and three liquid gauges" width="100%">

Rosa started as one rule: the desktop stays out of the way until it has something to say.
Everything that happens on the machine passes through a single island at the top of the screen.
It grows when there is news and shrinks back into a pill when there isn't. Panels that are closed
are not loaded at all, a hidden bar stops reading the spectrum, and the island goes still while a
game runs fullscreen.

<br>

<table>
<tr>
<td width="20%" valign="top">

**The island**

Takes the place of the bar clock and grows into music, calls, timers, messages, volume and
downloads, with a goo seam between the shapes.

</td>
<td width="20%" valign="top">

**One palette**

matugen reads the wallpaper and the shell, kitty, yazi, Zed, GTK, Qt and the cursor follow,
easing into the new colours.

</td>
<td width="20%" valign="top">

**One process**

Bar, launcher, clipboard, notifications, OSD, lock screen, dock and every panel are a single
Quickshell instance.

</td>
<td width="20%" valign="top">

**Every part is a switch**

<code>Super</code>+<code>Shift</code>+<code>P</code> turns modules off,
<code>Super</code>+<code>Shift</code>+<code>I</code> holds about sixty island knobs. No QML editing.

</td>
<td width="20%" valign="top">

**Leaves cleanly**

Updates arrive as a button next to the workspaces. <code>uninstall.sh</code> puts your old setup
back.

</td>
</tr>
</table>

<br>

<div align="center">

<sub><b>The dynamic island</b> takes the place of the bar clock and grows into whatever is happening — <code>Super</code> + <code>Shift</code> + <code>I</code> to tune it</sub>

<table>
<tr>
<td colspan="2"><img src="assets/island/island-media.gif" alt="Music starts: the cover slides out of the island, then the island opens into a player card" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>music — the cover and a live spectrum settle into the corner, the card opens on hover</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-notif.gif" alt="A message arriving in the island"></td>
<td><img src="assets/island/island-timer.gif" alt="A timer counting down in the left slot, then ringing"></td>
</tr>
<tr>
<td align="center"><sub>a message unfolds out of the pill and folds back into it</sub></td>
<td align="center"><sub>a timer ticks in the left slot, then rings</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-volume.gif" alt="Volume changes in the island"></td>
<td><img src="assets/island/island-bright.gif" alt="Brightness changes in the island"></td>
</tr>
<tr>
<td align="center"><sub>volume</sub></td>
<td align="center"><sub>brightness</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-bt.gif" alt="Headphones connecting and disconnecting"></td>
<td><img src="assets/island/island-power.gif" alt="Charger plugged in, then a low battery warning"></td>
</tr>
<tr>
<td align="center"><sub>headphones connect with their charge, then drop off</sub></td>
<td align="center"><sub>charger in, then a low battery</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-peri.gif" alt="A mouse running low on charge"></td>
<td><img src="assets/island/island-workspace.gif" alt="Switching workspaces"></td>
</tr>
<tr>
<td align="center"><sub>a mouse or keyboard running low</sub></td>
<td align="center"><sub>workspaces — the number lives inside the active dot</sub></td>
</tr>
<tr>
<td colspan="2"><img src="assets/island/island-layout.gif" alt="Switching the keyboard layout" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>keyboard layout</sub></td>
</tr>
<tr>
<td colspan="2"><img src="assets/island/island-media-big.gif" alt="Super+A: the island grows into a large player with rings, sparks and a spectrum driven by the music" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub><code>Super</code> + <code>A</code> — the island itself grows into a large player, everything around the cover moving with the music</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-call.gif" alt="An incoming call with answer and decline"></td>
<td><img src="assets/island/island-weather.gif" alt="Rain, then snow, coming soon"></td>
</tr>
<tr>
<td align="center"><sub>a call rings in the island</sub></td>
<td align="center"><sub>rain or snow on the way, drawn as falling drops</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-cmd.gif" alt="A long terminal command finishing, then failing"></td>
<td><img src="assets/island/island-task.gif" alt="A running task with its progress, then a failure"></td>
</tr>
<tr>
<td align="center"><sub>a long command finishes while you look elsewhere</sub></td>
<td align="center"><sub>a task with progress, then a failure</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-done.gif" alt="A success mark, then a failure mark"></td>
<td><img src="assets/island/island-shot.gif" alt="A screenshot thumbnail sliding out of the island"></td>
</tr>
<tr>
<td align="center"><sub>done and failed</sub></td>
<td align="center"><sub>a screenshot to open, keep or throw away</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-clip.gif" alt="Copied text, then a copied image"></td>
<td><img src="assets/island/island-record.gif" alt="Screen recording with a stop button"></td>
</tr>
<tr>
<td align="center"><sub>copied text, then a copied image</sub></td>
<td align="center"><sub>screen recording</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-alarm.gif" alt="An alarm ringing with snooze and stop"></td>
<td><img src="assets/island/island-stack.gif" alt="Several messages stacked in the island"></td>
</tr>
<tr>
<td align="center"><sub>an alarm</sub></td>
<td align="center"><sub>several messages at once</sub></td>
</tr>
<tr>
<td><img src="assets/island/island-print.gif" alt="A print job in the queue"></td>
<td><img src="assets/island/island-net.gif" alt="Wi-Fi connecting, then a VPN dropping"></td>
</tr>
<tr>
<td align="center"><sub>a print job</sub></td>
<td align="center"><sub>Wi-Fi and VPN</sub></td>
</tr>
<tr>
<td colspan="2"><img src="assets/island/island-focus.gif" alt="Do not disturb switching on" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>do not disturb</sub></td>
</tr>
</table>

<br>

</div>

<details>
<summary><b>The rest of the desktop</b> — <sub>launcher, panels, widgets, the black mode</sub></summary>

<div align="center">

<sub><b>The rest of the desktop</b></sub>

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
<td colspan="2"><img src="assets/power.jpg" alt="Power menu" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>power — <code>Super</code> + <code>P</code></sub></td>
</tr>
<tr>
<td colspan="2"><img src="assets/bar-builder.jpg" alt="Bar builder" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>bar builder — <code>Super</code> + <code>Shift</code> + <code>J</code> — three zones, any number of islands, thirty-three modules</sub></td>
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
<td><img src="assets/timer.jpg" alt="Timers and alarms"></td>
<td><img src="assets/equalizer.jpg" alt="Ten band equaliser"></td>
</tr>
<tr>
<td align="center"><sub>timers — <code>Super</code> + <code>T</code></sub></td>
<td align="center"><sub>equaliser — <code>Super</code> + <code>Shift</code> + <code>Q</code></sub></td>
</tr>
<tr>
<td><img src="assets/notification-center.jpg" alt="Notification centre"></td>
<td><img src="assets/files.jpg" alt="Media browser"></td>
</tr>
<tr>
<td align="center"><sub>notification centre — <code>Super</code> + <code>Shift</code> + <code>N</code></sub></td>
<td align="center"><sub>media browser — <code>Super</code> + <code>Shift</code> + <code>B</code></sub></td>
</tr>
<tr>
<td><img src="assets/polkit.jpg" alt="Authorisation prompt"></td>
<td><img src="assets/guide.jpg" alt="First run tour"></td>
</tr>
<tr>
<td align="center"><sub>authorisation — the shell's own polkit agent</sub></td>
<td align="center"><sub>the tour, once, on first login</sub></td>
</tr>
<tr>
<td><img src="assets/dock.jpg" alt="Dock"></td>
<td><img src="assets/draw.jpg" alt="Drawing over the screen"></td>
</tr>
<tr>
<td align="center"><sub>dock — hidden until the pointer reaches the edge</sub></td>
<td align="center"><sub>draw over the screen — <code>Super</code> + <code>Shift</code> + <code>G</code></sub></td>
</tr>
<tr>
<td><img src="assets/calc.jpg" alt="Calculator inside the launcher"></td>
<td><img src="assets/focus.jpg" alt="Focus mode"></td>
</tr>
<tr>
<td align="center"><sub>calculator — <code>Super</code> + <code>C</code></sub></td>
<td align="center"><sub>focus mode — <code>Super</code> + <code>Ctrl</code> + <code>F</code></sub></td>
</tr>
<tr>
<td colspan="2"><img src="assets/yazi.jpg" alt="yazi themed from the wallpaper" width="100%"></td>
</tr>
<tr>
<td colspan="2" align="center"><sub>the file manager takes the same palette — <code>Super</code> + <code>E</code></sub></td>
</tr>
<tr>
<td colspan="2" align="center"><sub><b>Serezha mode</b> — the same session with the shell shut down: black, waybar, 236 MB</sub></td>
</tr>
<tr>
<td><img src="assets/serezha-desktop.jpg" alt="The black desktop with waybar"></td>
<td><img src="assets/serezha-launcher.jpg" alt="fuzzel as the launcher"></td>
</tr>
<tr>
<td align="center"><sub>the desktop — no wallpaper, no rounding, no animation</sub></td>
<td align="center"><sub>launcher — <code>Super</code> + <code>D</code>, fuzzel instead of the shell</sub></td>
</tr>
<tr>
<td><img src="assets/serezha-menu.jpg" alt="The mode menu, which replaces the settings panel"></td>
<td><img src="assets/serezha-memory.jpg" alt="Session memory, measured in PSS"></td>
</tr>
<tr>
<td align="center"><sub>mode menu — <code>Super</code> + <code>Shift</code> + <code>P</code>, and the way back</sub></td>
<td align="center"><sub>the whole session, measured in PSS</sub></td>
</tr>
</table>

</div>

</details>

## Performance

Measured on 2026-11-04 over 30 seconds with music playing, so the island, its spectrum and the
album art were all live. The machine has a Ryzen 5 5600 and one 1080p monitor at 144 Hz.

| | CPU (one core = 100%) | Memory |
| --- | --- | --- |
| Quickshell: bar, island, desk, panels | 6.0% | 495 MB PSS |
| Hyprland | 5.1% | — |
| Serezha mode: the shell off, waybar on | — | 236 MB for the whole session |

Panels that are closed are not loaded. A hidden bar stops reading the spectrum, and the island
stops animating while a game is fullscreen.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fedyaqq34356/rosa/main/install.sh)
```

The installer needs `pacman` and a normal user, not root. It detects Arch (systemd) or
Artix (OpenRC) and the GPU, then installs the packages and an AUR helper if none is present.
Your current configs are copied to `~/.config/dotfiles-backup-<timestamp>` before anything
is replaced, and the colour scheme is generated from your first wallpaper. Add `--dry-run` to
see every step without running it. The [guide](docs/GUIDE.md) has a full walk-through from a
blank disk, every flag and every keybinding.

**Update:** press the update chip that appears next to the workspaces, or run `rosa-update`.
Installs from the time this project was called hyprdots move over on their own.

### Uninstall

```bash
bash ~/.local/share/rosa/uninstall.sh
```

Each file the installer wrote moves to `~/.config/rosa-removed-<timestamp>`, and the
configs you had before the first install come back. `--system` also removes the root helpers.
Packages stay installed.

## Documentation

| | |
| --- | --- |
| [Guide](docs/GUIDE.md) · [Руководство](docs/GUIDE.ru.md) | install from a blank disk, flags, layout, keybindings |
| [What changed](docs/UPDATE.md) | release notes |
| [Desktop notes](docs/DESKTOP.md) | BIOS, services and tuning for a desktop PC |

## License

GNU General Public License v3.0, see [LICENSE](LICENSE).
