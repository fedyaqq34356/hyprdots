local v = require("cfg.vars")
local b = require("cfg.binds")
local r = require("cfg.rules")
local H = v.home
local bind, exec = b.bind, b.exec

hl.config({
    general = {
        gaps_in  = 0,
        gaps_out = 0,
        border_size = 1,
        col = {
            active_border   = "rgba(ffffffff)",
            inactive_border = "rgba(000000ff)",
        },
        resize_on_border = true,
    },

    decoration = {
        rounding = 0,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = false,
        dim_strength = 0.0,
        dim_special  = 0.0,
        blur   = { enabled = false },
        shadow = { enabled = false },
    },

    animations = { enabled = false },

    misc = {
        background_color = "rgb(000000)",
        force_default_wallpaper = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        vrr = 0,
        focus_on_activate = false,
        disable_autoreload = true,
    },

    render = {
        direct_scanout = true,
        cm_enabled = false,
        expand_undersized_textures = false,
    },

    opengl = {
        nvidia_anti_flicker = false,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },

    cursor = {
        no_hardware_cursors = false,
        inactive_timeout = 5,
        hide_on_key_press = true,
    },
})

local unbinds = {
    { "$mainMod", "D" }, { "$mainMod", "Tab" }, { "$mainMod", "W" }, { "$mainMod", "N" },
    { "$mainMod", "V" }, { "$mainMod", "A" }, { "$mainMod SHIFT", "D" }, { "$mainMod", "F1" },
    { "$mainMod SHIFT", "N" }, { "$mainMod CTRL", "N" }, { "$mainMod", "B" }, { "$mainMod", "C" },
    { "$mainMod SHIFT", "B" }, { "$mainMod SHIFT", "P" }, { "$mainMod SHIFT", "W" },
    { "$mainMod SHIFT", "G" }, { "$mainMod SHIFT", "A" }, { "$mainMod SHIFT", "J" },
    { "$mainMod SHIFT", "Q" }, { "$mainMod CTRL", "T" }, { "$mainMod ALT", "T" },
    { "$mainMod", "M" }, { "$mainMod SHIFT", "M" }, { "$mainMod SHIFT", "L" },

    { "", "XF86AudioRaiseVolume" }, { "", "XF86AudioLowerVolume" }, { "", "XF86AudioMute" },
    { "", "XF86AudioMicMute" }, { "", "XF86AudioPlay" }, { "", "XF86AudioPause" },
    { "", "XF86AudioNext" }, { "", "XF86AudioPrev" },
    { "", "XF86MonBrightnessUp" }, { "", "XF86MonBrightnessDown" },
    { "$mainMod", "equal" }, { "$mainMod", "minus" },
    { "$mainMod SHIFT", "equal" }, { "$mainMod SHIFT", "minus" },

    { "$mainMod", "Return" }, { "$mainMod", "E" }, { "$mainMod SHIFT", "Y" },
}
for _, u in ipairs(unbinds) do
    hl.unbind(b.key(u[1], u[2]))
end

local locked = { locked = true }
local lrep   = { locked = true, repeating = true }

bind("$mainMod", "D", exec("fuzzel --config=" .. H .. "/.config/serezha/fuzzel.ini"))
bind("$mainMod", "V", exec(H .. "/.local/bin/serezha-clip"))
bind("$mainMod SHIFT", "P", exec(H .. "/.local/bin/serezha-menu"))

local term = "foot -c " .. H .. "/.config/serezha/foot/foot.ini"
bind("$mainMod", "Return", exec(term))

bind("$mainMod", "E", exec(H .. "/.local/bin/serezha-files"))

bind("$mainMod", "N", exec(term .. " --app-id serezha-tui -e nmtui"))
bind("$mainMod", "B", exec(term .. " --app-id serezha-tui -e bluetoothctl"))

bind("$mainMod SHIFT", "M", exec(H .. "/.local/bin/serezha-menu audio"))

bind("$mainMod SHIFT", "L", exec("hyprlock -c " .. H .. "/.config/serezha/hyprlock.conf"))

bind("", "XF86AudioRaiseVolume", exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), lrep)
bind("", "XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), lrep)
bind("", "XF86AudioMute",        exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
bind("", "XF86AudioMicMute",     exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
bind("$mainMod", "equal",        exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), lrep)
bind("$mainMod", "minus",        exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), lrep)
bind("$mainMod", "M",            exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
bind("$mainMod SHIFT", "equal",  exec("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+"), lrep)
bind("$mainMod SHIFT", "minus",  exec("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-"), lrep)

bind("", "XF86AudioPlay",  exec("playerctl play-pause"), locked)
bind("", "XF86AudioPause", exec("playerctl play-pause"), locked)
bind("", "XF86AudioNext",  exec("playerctl next"),       locked)
bind("", "XF86AudioPrev",  exec("playerctl previous"),   locked)

bind("", "XF86MonBrightnessUp",   exec("brightnessctl -c backlight set 5%+"), lrep)
bind("", "XF86MonBrightnessDown", exec("brightnessctl -c backlight set 5%-"), lrep)

bind("$mainMod SHIFT", "N", exec("makoctl restore"))
bind("$mainMod CTRL",  "N", exec(H .. "/.local/bin/serezha-dnd"))

r.win({ class = "^(serezha-tui)$" },   { float = true, center = true, size = "900 600" })
r.win({ class = "^(serezha-files)$" }, { float = true, center = true, size = "1000 640" })
