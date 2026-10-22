local c = require("cfg.vars").c

local function win(match, props)
    props.match = match
    hl.window_rule(props)
end

local function layer(ns, props)
    props.match = { namespace = ns }
    hl.layer_rule(props)
end

win({ class = "^(org.kde.dolphin)$", title = "^(Progress Dialog)$" }, { float = true })
win({ class = "^(org.kde.dolphin)$", title = "^(Copying)$" },         { float = true })
win({ class = "^(org.kde.polkit-kde-authentication-agent-1)$" },      { float = true })
win({ class = "^(hyprpolkitagent)$" }, { float = true, center = true })

win({ title = "^(Picture-in-Picture)$" }, { float = true, pin = true })

layer("rofi", { blur = true, ignore_alpha = 0.8 })

win({ class = "^(xwaylandvideobridge)$" }, { opacity = "0.0 override" })

layer("^(qs-bar)$", { blur = true, ignore_alpha = 0.55 })

layer("^(qs-notifications|qs-osd)$", { blur = true, ignore_alpha = 0.45 })

layer("^(qs-launcher|qs-clipboard|qs-wallpapers|qs-audio|qs-power|qs-net)$", { blur = true, ignore_alpha = 0.60 })

layer("^(qs-overview)$", { blur = true, ignore_alpha = 0.50 })

layer("^(qs-flash)$", { no_anim = true })

win({ class = "^(kitty)$" }, { border_color = c.accent .. " rgba(00000000)", border_size = 1 })

win({ class = "^(yazi)$" }, { float = true, center = true, size = "1280 820" })

layer("^(qs-settings|qs-calendar|qs-media|qs-eq|qs-files|qs-guide|qs-notifcenter|qs-print|qs-timer|qs-islandsettings|qs-quick|qs-polkit)$",
    { blur = true, ignore_alpha = 0.80 })

win({ class = "^(hyprdots-update)$" }, { float = true, center = true, size = "820 560" })

return { win = win, layer = layer }
