local v = require("cfg.vars")
local dsp = hl.dsp
local S = v.scripts

local function key(mods, k)
    if mods == "" then return k end
    return (mods:gsub("%$mainMod", v.mainMod):gsub("%s+", " + ")) .. " + " .. k
end

local function bind(mods, k, d, opts)
    hl.bind(key(mods, k), d, opts)
end

local function exec(cmd) return dsp.exec_cmd(cmd) end
local function qs(name) return dsp.global("quickshell:" .. name) end

local rep    = { repeating = true }
local locked = { locked = true }
local lrep   = { locked = true, repeating = true }

bind("$mainMod",       "Return", exec("kitty"))
bind("$mainMod",       "D",      qs("launcher"))
bind("$mainMod",       "Tab",    qs("overview"))
bind("$mainMod",       "E",      exec("kitty --class yazi -e yazi"))
bind("$mainMod SHIFT", "Y",      exec("thunar"))
bind("$mainMod",       "W",      qs("wallpapers"))
bind("$mainMod",       "N",      qs("wifi"))
bind("$mainMod",       "V",      qs("clipboard"))
bind("$mainMod",       "A",      qs("media"))
bind("$mainMod SHIFT", "D",      qs("calendar"))
bind("$mainMod SHIFT", "V",      exec(S .. "/clipboard/clipboard-wipe.sh"))

bind("$mainMod",       "Q",  dsp.window.close())
bind("ALT",            "F4", dsp.window.close())
bind("$mainMod",       "F",  dsp.window.fullscreen({ mode = "fullscreen" }))
bind("$mainMod SHIFT", "F",  dsp.window.float({ action = "toggle" }))

bind("$mainMod", "H", dsp.focus({ direction = "left" }))
bind("$mainMod", "L", dsp.focus({ direction = "right" }))
bind("$mainMod", "K", dsp.focus({ direction = "up" }))
bind("$mainMod", "J", dsp.focus({ direction = "down" }))

bind("$mainMod SHIFT", "L", exec(S .. "/lock/lock.sh"))

bind("$mainMod",       "right", dsp.window.move({ x = 30,  y = 0,   relative = true }), rep)
bind("$mainMod",       "left",  dsp.window.move({ x = -30, y = 0,   relative = true }), rep)
bind("$mainMod",       "up",    dsp.window.move({ x = 0,   y = -30, relative = true }), rep)
bind("$mainMod",       "down",  dsp.window.move({ x = 0,   y = 30,  relative = true }), rep)
bind("$mainMod SHIFT", "right", dsp.window.resize({ x = 50,  y = 0,   relative = true }), rep)
bind("$mainMod SHIFT", "left",  dsp.window.resize({ x = -50, y = 0,   relative = true }), rep)
bind("$mainMod SHIFT", "up",    dsp.window.resize({ x = 0,   y = -50, relative = true }), rep)
bind("$mainMod SHIFT", "down",  dsp.window.resize({ x = 0,   y = 50,  relative = true }), rep)

bind("$mainMod", "mouse:272", dsp.window.drag(),   { mouse = true })
bind("$mainMod", "mouse:273", dsp.window.resize(), { mouse = true })

for i = 1, 9 do
    bind("$mainMod", tostring(i), dsp.focus({ workspace = i }))
    if i ~= 6 then
        bind("$mainMod SHIFT", tostring(i), dsp.window.move({ workspace = i }))
    end
end
bind("$mainMod SHIFT", "6", qs("gtavi"))

bind("$mainMod", "P", exec(S .. "/system/power-menu.sh"))

local shot = S .. "/capture/screenshot.sh "
bind("",               "Print", exec(shot .. "region"))
bind("SHIFT",          "Print", exec(shot .. "edit"))
bind("ALT",            "Print", exec(shot .. "window"))
bind("CTRL",           "Print", exec(shot .. "all"))
bind("$mainMod",       "Print", exec(shot .. "output"))
bind("$mainMod SHIFT", "S",     exec(shot .. "region"))
bind("$mainMod SHIFT", "C",     exec(shot .. "color"))
bind("$mainMod SHIFT", "T",     exec(shot .. "ocr"))
bind("$mainMod ALT",   "G",     exec(shot .. "lens"))
bind("$mainMod SHIFT", "X",     exec(shot .. "blur"))
bind("$mainMod ALT",       "R", exec(S .. "/capture/record-toggle.sh screen"))
bind("$mainMod ALT SHIFT", "R", exec(S .. "/capture/record-toggle.sh region"))

bind("", "XF86AudioRaiseVolume", qs("volumeUp"),   lrep)
bind("", "XF86AudioLowerVolume", qs("volumeDown"), lrep)
bind("", "XF86AudioMute",        qs("volumeMute"), locked)
bind("", "XF86AudioMicMute",     qs("micMute"),    locked)

bind("", "XF86AudioPlay",  qs("mediaToggle"), locked)
bind("", "XF86AudioPause", qs("mediaToggle"), locked)
bind("", "XF86AudioNext",  qs("mediaNext"),   locked)
bind("", "XF86AudioPrev",  qs("mediaPrev"),   locked)

bind("$mainMod",       "equal", qs("volumeUp"),   lrep)
bind("$mainMod",       "minus", qs("volumeDown"), lrep)
bind("$mainMod",       "M",     qs("micMute"))
bind("$mainMod SHIFT", "M",     qs("audioPanel"))
bind("$mainMod SHIFT", "equal", qs("micUp"),   lrep)
bind("$mainMod SHIFT", "minus", qs("micDown"), lrep)
bind("$mainMod CTRL",  "M",     exec(S .. "/audio/mic-boost.sh"))
bind("", "XF86AudioPlay", exec("playerctl play-pause"), locked)
bind("", "XF86AudioNext", exec("playerctl next"),       locked)
bind("", "XF86AudioPrev", exec("playerctl previous"),   locked)
bind("", "XF86MonBrightnessUp",   qs("brightnessUp"),   lrep)
bind("", "XF86MonBrightnessDown", qs("brightnessDown"), lrep)

bind("$mainMod SHIFT", "F3", exec('kitty --title "clean-cache" sh -c "' .. S .. '/system/clean-cache.sh"'))
bind("$mainMod SHIFT", "F4", exec('kitty --title "update-packages" sh -c "' .. S .. '/system/update-packages.sh"'))

bind("$mainMod SHIFT", "E", dsp.exit())
bind("$mainMod SHIFT", "R", exec("hyprctl reload"))

bind("$mainMod SHIFT", "F5", exec(S .. "/system/panel-reset.sh eDP-1"))

bind("$mainMod",      "F1", qs("sysRings"))
bind("$mainMod CTRL", "B",  qs("battery"))

bind("$mainMod SHIFT",      "N", qs("notifCenter"))
bind("$mainMod CTRL",       "N", qs("dnd"))
bind("$mainMod ALT",        "N", exec(S .. "/notify/notify-test.sh"))
bind("$mainMod SHIFT ALT",  "N", exec(S .. "/notify/notify-test.sh critical"))
bind("$mainMod CTRL SHIFT", "N", exec(S .. "/notify/notify-test.sh burst"))

bind("$mainMod CTRL", "F", exec(S .. "/system/focus-mode.sh"))

bind("$mainMod",       "B", qs("bluetooth"))
bind("$mainMod",       "C", qs("launcherCalc"))
bind("$mainMod SHIFT", "B", qs("files"))
bind("$mainMod CTRL",  "P", qs("print"))

bind("$mainMod SHIFT", "P", qs("settings"))
bind("$mainMod SHIFT", "W", qs("deskEdit"))
bind("$mainMod SHIFT", "G", qs("draw"))
bind("$mainMod SHIFT", "A", qs("dock"))
bind("$mainMod SHIFT", "J", qs("barBuilder"))
bind("$mainMod SHIFT", "I", qs("island"))
bind("$mainMod SHIFT", "Q", qs("eq"))
bind("$mainMod",       "T", qs("timer"))
bind("$mainMod ALT",   "T", qs("timerDismiss"))

return { bind = bind, key = key, exec = exec }
