local v = require("cfg.vars")
local c = v.c

local mf = io.open(v.hypr .. "/config/monitors.conf")
if mf then
    for line in mf:lines() do
        local spec = line:match("^%s*monitor%s*=%s*(.-)%s*$")
        if spec then
            local f = {}
            for part in (spec .. ","):gmatch("%s*(.-)%s*,") do
                f[#f + 1] = part
            end
            if f[2] == "disable" then
                hl.monitor({ output = f[1], disabled = true })
            else
                hl.monitor({
                    output   = f[1],
                    mode     = f[2] ~= "" and f[2] or "preferred",
                    position = f[3] or "auto",
                    scale    = tonumber(f[4]) or f[4] or "auto",
                })
            end
        end
    end
    mf:close()
end

hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = {
                colors = { c.active_border_1, c.active_border_2, c.active_border_1 },
                angle = 45,
            },
            inactive_border = c.inactive_border,
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = v.winRounding,
        rounding_power = 2.6,

        active_opacity   = 1.0,
        inactive_opacity = 0.94,

        dim_inactive = true,
        dim_strength = 0.08,
        dim_special  = 0.25,

        blur = {
            enabled    = true,
            size       = 8,
            passes     = 3,
            xray              = true,
            ignore_opacity    = true,
            new_optimizations = true,
            noise      = 0.015,
            contrast   = 1.10,
            brightness = 1.00,
            vibrancy   = 0.24,
            vibrancy_darkness = 0.50,
            popups             = true,
            popups_ignorealpha = 0.40,
            special = true,
        },

        shadow = {
            enabled = true,
            range        = 30,
            render_power = 4,
            offset       = "0 6",
            sharp        = false,
            color          = c.shadow,
            color_inactive = c.shadow_inactive,
        },
    },

    input = {
        kb_layout  = "us,ru",
        kb_variant = ",",
        kb_options = "grp:alt_shift_toggle",

        follow_mouse = 1,
        sensitivity  = 0.3,
        repeat_rate  = 30,
        repeat_delay = 300,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            drag_lock            = true,
            disable_while_typing = true,
            scroll_factor        = 0.5,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        vrr               = 0,
        focus_on_activate = false,
    },

    xwayland = {
        enabled = true,
    },
})

hl.device({
    name          = "genius-optical-mouse",
    sensitivity   = -0.3,
    accel_profile = "flat",
    scroll_factor = 2.0,
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
