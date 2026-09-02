<div align="center">

<br>

# What changed

**Everything added in this round, and every key that now does something.**

<a href="../README.md"><img src="https://img.shields.io/badge/back%20to-README-E4E3D8?style=flat-square&labelColor=13140E" alt="README"></a>
<img src="https://img.shields.io/badge/idle%20CPU-43%25%20→%206%25-C6C8B5?style=flat-square&labelColor=13140E" alt="idle CPU">

<br>

</div>

<table>
<tr>
<td valign="top" width="50%">

**New surfaces**

[Desktop widgets](#desktop-widgets--super--shift--w) ·
[Settings](#settings--super--shift--p) ·
[Equaliser](#equaliser--super--shift--q) ·
[Drawing](#drawing--super--shift--g) ·
[Dock](#dock) ·
[Authorisation](#authorisation-prompts) ·
[Tour](#first-run-tour) ·
[Typed notifications](#typed-notifications) ·
[Screen time](#screen-time) ·
[Idle](#idle-handling) ·
[Languages](#interface-languages) ·
[Sounds](#sounds)

</td>
<td valign="top" width="50%">

**Changed**

[Launcher](#launcher) ·
[File manager](#file-manager) ·
[Terminal](#terminal) ·
[Editor](#editor) ·
[Typography](#typography) ·
[Config layout](#layout-of-the-config) ·
[Performance](#performance)

**Reference**

[Keybindings](#keybindings) ·
[yazi](#yazi) ·
[Left to do by hand](#still-to-do-by-hand)

</td>
</tr>
</table>

---

## New surfaces

### Desktop widgets — `Super` + `Shift` + `W`

Widgets that live on the wallpaper, under the windows. Outside edit mode the
layer carries an empty input mask, so clicks and scrolls pass through it: the
widgets are visible and completely intangible. Edit mode raises the layer above
the windows — a layout that cannot be seen behind a maximised window cannot be
arranged — and adds a grid, drag handles, a wheel-to-resize gesture and a
palette.

Positions are stored as fractions of the screen, so a layout arranged on the
laptop panel lands in the same place on an external monitor.

| Widget | Faces |
| --- | --- |
| clock | stacked numerals · line with the date · handwritten strokes |
| music | sleeve with seek line · the record itself, turning while it plays |
| weather | card with a three-day strip · glyph and number |
| system | rings · labelled bars |
| screen time | today's applications as bars · the total alone |

### Settings — `Super` + `Shift` + `P`

One card. Every optional part of the shell is one row here, one flag in
`Prefs`, one loader in `shell.qml`. Also carries interface language, bar edge,
heading font, notification tone, interface volume, and a way back to the tour.

### Equaliser — `Super` + `Shift` + `Q`

Ten bands on PipeWire's own biquad filters. No EasyEffects, no plugin packs, no
second sound daemon. The graph is declared in
`~/.config/pipewire/pipewire.conf.d/99-shell-eq.conf`; gains are pushed live
with one `pw-cli` call per change.

The curve and the live spectrum share one grid. Handles sit on the curve
itself; a double click returns a band to zero. Presets: flat, bass, treble,
vocal, pop, rock, jazz, classic, night.

**One-time step:** PipeWire reads the graph only at start, and it is started
from `hypr/config/startup.conf`. Until the next login the panel says
`not loaded — restart audio`.

### Drawing — `Super` + `Shift` + `G`

Draw over the screen. Strokes are kept as point lists and repainted, so undo is
possible; a canvas that has been drawn into has no memory of what a stroke was.
Five colours, `Ctrl` + `Z` to undo, `C` to clear, `Esc` to leave.

### Dock

Hidden along the bottom edge; only a few pixels accept input while it is away.
Icons swell with the distance to the pointer. `Super` + `Shift` + `A` pins it.

### Authorisation prompts

The shell draws its own polkit agent, in the shell's own style. A wrong password
shakes the card.

### First-run tour

Five cards, once, on first login (`Prefs.guideSeen`). Re-openable from the
settings.

### Typed notifications

A screenshot notification shows the screenshot, with copy and open buttons. A
package-update notification shows the count and the first few names. Weather
gets a glyph and a temperature. Everything else keeps the one-line card.

### Screen time

Counted in the shell, per application, at a 15-second tick. Stops while the
session is locked and while the screen is off. Two weeks of history, in
`~/.local/state/quickshell/`, never leaving the machine.

### Idle handling

Replaces `hypridle`. Lock and screen-off timers live in the shell's settings;
the decision of *whether* to fire stays in `hypr/scripts/idle-guard.sh`, which
already knows about fullscreen windows, playing audio, recordings and the
personal inhibit list.

### Interface languages

English and Russian, switched in the settings without a restart. Strings in
`config/quickshell/f/lang/*.json`. Plural rules belong to the language: English
supplies two forms, Russian three. Month and weekday names come from the same
tables, not from Qt's locale.

### Sounds

Every gesture has one: clicks, panel stingers, a ratchet under a dragging
finger, connect and disconnect for the radios, typing, alerts. Volume and the
notification tone are in the settings.

---

## Changed

### Launcher

- `>` runs the rest of the line in a shell. The command is shown in full before
  it runs.
- Ranking is now frecency with a 14-day half-life, so an application used forty
  times in July stops outranking one used four times this week. The old counters
  were migrated, dated from the day of the change, so they fade rather than
  vanish.

### File manager

`Super` + `E` opens **yazi** inside kitty — image and video previews as real
pixels through kitty's graphics protocol, and a flavour generated by matugen, so
it recolours with the wallpaper. Thunar moved to `Super` + `Shift` + `Y` for
dragging files into other applications.

Three things were fixed while wiring it up: the yazi flavour was in the old
`use =` syntax and was silently ignored; `g` was bound twice, so "go to top"
never worked; the editor opener pointed at `nvim`, which is not installed.

### Terminal

- `allow_remote_control` + `listen_on` — `kitty @` now works, which is what
  yazi's `Ctrl` + `G` (lazygit) needs.
- Tab bar appears from the second tab.
- `disable_ligatures cursor`, heavier text composition on Wayland.
- 50k lines of scrollback.
- Removed a dead `dynamic_background_color` key that kitty had been warning
  about on every start.

### Editor

Zed keeps its place as the graphical editor. Its theme is now generated by
matugen like everything else, the buffer font matches the terminal, the
interface font matches the shell's headings, and Python is wired to ruff plus
pyright with format-on-save.

### Typography

The shell used to be one monospace face at four sizes. Now a proportional face
names things — panel titles, application names, track titles — and the
monospace one carries anything that has to be scanned or compared. Choice of
display face in the settings.

### Layout of the config

87 QML files moved out of one flat directory into `design/`, `services/`,
`reusables/`, `bar/`, `panels/`, `desk/`, `overlays/`, each with a `qmldir`,
imported as `root:/…`.

---

## Performance

Idle CPU went from **43% to 6%** with nothing removed visually.

1. The seconds arc around the bar clock is a `Canvas`, which rasterises on the
   CPU, and its value was animated smoothly across each second — 60 repaints for
   a sweep that grows about 1.7 pixels. All three ring components now repaint
   only when the drawn arc moves half a pixel.
2. Three transient full-screen overlays stayed mapped forever because
   `LazyLoader` never destroys what it built, so the compositor kept compositing
   them. They now bind `visible` to their own state, and the hidden dock shrinks
   to a 4-pixel strip.

When measuring: use `pgrep -x quickshell`, and restart the shell first — hot
reloads accumulate, and a session with a hundred of them sat at 14% where a
fresh start sat at 6%.

---

## Keybindings

`Super` is the modifier.

### Shell

| Key | Action |
| --- | --- |
| `Super` + `D` | application launcher |
| `Super` + `C` | launcher in calculator mode |
| `Super` + `Tab` | window overview with live thumbnails |
| `Super` + `V` | clipboard history |
| `Super` + `Shift` + `V` | wipe the clipboard and its history |
| `Super` + `W` | wallpaper picker |
| `Super` + `Shift` + `B` | media browser |
| `Super` + `N` | Wi-Fi |
| `Super` + `B` | Bluetooth |
| `Super` + `A` | media player panel |
| `Super` + `Shift` + `M` | audio panel |
| `Super` + `Shift` + `D` | calendar |
| `Super` + `F1` | system rings |
| `Super` + `Shift` + `N` | notification centre |
| `Super` + `Ctrl` + `N` | do not disturb |
| `Super` + `P` | power menu |
| `Super` + `Shift` + `L` | lock screen |

### Added in this round

| Key | Action |
| --- | --- |
| `Super` + `Shift` + `P` | settings |
| `Super` + `Shift` + `W` | arrange desktop widgets |
| `Super` + `Shift` + `Q` | equaliser |
| `Super` + `Shift` + `G` | draw over the screen |
| `Super` + `Shift` + `A` | pin the dock |
| `Super` + `Shift` + `Y` | Thunar |
| `>` in the launcher | run a shell command |

### Inside the panels

| Key | Where | Action |
| --- | --- | --- |
| `Esc` | anywhere | close |
| `↑` `↓` `Enter` | launcher, overview | select and act |
| `Tab` | wallpapers | cycle the colour filter |
| `d` | notification centre | do not disturb |
| `Del` | notification centre | clear all |
| `←` `→` `Enter` `Space` | tour | move between cards |
| `Ctrl` + `Z` | drawing | undo |
| `C` | drawing | clear |
| double click | equaliser | zero one band |
| wheel | desktop widget edit | resize the widget |

### Windows

| Key | Action |
| --- | --- |
| `Super` + `Return` | kitty |
| `Super` + `T` | scratchpad terminal |
| `Super` + `E` | yazi |
| `Super` + `Q` | close window |
| `Super` + `F` | fullscreen |
| `Super` + `Shift` + `F` | floating |
| `Super` + `H` `J` `K` `L` | move focus |
| `Super` + arrows | move a floating window |
| `Super` + `Shift` + arrows | resize |
| `Super` + `1`…`9` | workspace |
| `Super` + `Shift` + `1`…`9` | move window to workspace |
| `Super` + `Ctrl` + `F` | focus mode |
| `Super` + `Shift` + `R` | reload Hyprland |
| `Super` + `Shift` + `E` | exit Hyprland |

### Capture

| Key | Action |
| --- | --- |
| `Print` | area |
| `Shift` + `Print` | area, then the annotation editor |
| `Alt` + `Print` | window |
| `Super` + `Print` | current monitor |
| `Ctrl` + `Print` | every monitor |
| `Super` + `Shift` + `S` | area |
| `Super` + `Shift` + `X` | blur a region of the last screenshot |
| `Super` + `Shift` + `C` | colour picker |
| `Super` + `Shift` + `T` | OCR a region |
| `Super` + `Alt` + `R` | record the monitor |
| `Super` + `Alt` + `Shift` + `R` | record a region |

### Sound and screen

| Key | Action |
| --- | --- |
| media keys | play/pause, next, previous |
| `Super` + `=` / `-` | output volume |
| `Super` + `Shift` + `=` / `-` | microphone volume |
| `Super` + `M` | mute the microphone |
| brightness keys | brightness |

### Maintenance

| Key | Action |
| --- | --- |
| `Super` + `Shift` + `F3` | cache cleanup |
| `Super` + `Shift` + `F4` | system update |
| `Super` + `Shift` + `F5` | modeset the internal panel |
| `Super` + `Alt` + `N` | test notification |
| `Super` + `Shift` + `Alt` + `N` | test critical notification |
| `Super` + `Ctrl` + `Shift` + `N` | four in a row |

### yazi

| Key | Action |
| --- | --- |
| `h` `j` `k` `l` | navigate |
| `J` `K` | five at a time |
| `g` `G` | top, bottom |
| `Space` | mark, `A` mark all, `Esc` clear |
| `y` `x` `p` | copy, cut, paste (`P` overwrites) |
| `d` `D` | trash, delete |
| `r` `a` | rename, create (`/` at the end makes a folder) |
| `/` `n` `N` | filter, next, previous |
| `f` `F` | find files (fd), find in files (rg) |
| `.` | show hidden |
| `t` `Tab` `1` `2` `3` | tabs |
| `s` then `n` `m` `s` | sort by name, date, size |
| `e` | open with a chosen application |
| `Ctrl` + `G` | lazygit |
| `q` `Q` | quit, quit without changing directory |
| `~` | full key list |

---

## Still to do by hand

- **Log out once** so PipeWire picks up the equaliser graph.
- Zed downloads its Python language servers on first `.py` open; QML has no
  built-in support there, so install a QML extension if you want highlighting
  in the shell's own source.
