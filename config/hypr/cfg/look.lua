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
            if f[1] == "" then
            elseif f[2] == "disable" then
                hl.monitor({ output = f[1], disabled = true })
            else
                local m = {
                    output   = f[1],
                    mode     = f[2] ~= "" and f[2] or "preferred",
                    position = f[3] or "auto",
                    scale    = tonumber(f[4]) or f[4] or "auto",
                }
                for i = 5, #f - 1, 2 do
                    if f[i] == "transform" or f[i] == "vrr" or f[i] == "bitdepth"
                        or f[i] == "supports_wide_color" or f[i] == "sdrbrightness"
                        or f[i] == "sdrsaturation" then
                        m[f[i]] = tonumber(f[i + 1])
                    elseif f[i] == "cm" then
                        m.cm = f[i + 1]
                    elseif f[i] == "mirror" then
                        m.mirror = f[i + 1]
                    end
                end
                hl.monitor(m)
            end
        end
    end
    mf:close()
end

local kb = {
    kb_layout  = "us,ru",
    kb_variant = ",",
    kb_options = "grp:alt_shift_toggle",
}
local kf = io.open(v.hypr .. "/config/keyboard.conf")
if kf then
    for line in kf:lines() do
        local key, value = line:match("^%s*(kb_[%w_]+)%s*=%s*(.-)%s*$")
        if key and kb[key] ~= nil then
            kb[key] = value
        end
    end
    kf:close()
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
        allow_tearing = v.gpu == "amd",
    },

    decoration = {
        rounding = v.winRounding,
        rounding_power = 2.6,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

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
        kb_layout  = kb.kb_layout,
        kb_variant = kb.kb_variant,
        kb_options = kb.kb_options,

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
        vrr               = 0,  -- VRR 2 stuttered on fullscreen (R24s over HDMI)
        focus_on_activate = false,
    },

    xwayland = {
        enabled = true,
    },

    render = {
        direct_scanout    = 2,
        send_content_type = false,
        cm_auto_hdr       = 0,
    },
})

hl.device({
    name          = "genius-optical-mouse",
    sensitivity   = -0.3,
    accel_profile = "flat",
    scroll_factor = 2.0,
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
