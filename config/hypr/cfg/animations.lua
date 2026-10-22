hl.config({ animations = { enabled = true } })

local function bezier(name, x1, y1, x2, y2)
    hl.curve(name, { type = "bezier", points = { { x1, y1 }, { x2, y2 } } })
end

local function spring(name, response, damping)
    local w = 2 * math.pi / response
    hl.curve(name, { type = "spring", mass = 1, stiffness = w * w, dampening = 2 * damping * w })
end

bezier("md3_standard", 0.20, 0.00, 0.00, 1.00)
bezier("md3_decel",    0.05, 0.70, 0.10, 1.00)
bezier("md3_accel",    0.30, 0.00, 0.80, 0.15)
bezier("glide",        0.10, 0.90, 0.15, 1.00)
bezier("linear",       0.00, 0.00, 1.00, 1.00)
bezier("isleOut",      0.40, 0.00, 0.30, 1.00)
bezier("closeSoft",    0.32, 0.00, 0.18, 1.00)

spring("isle",      0.42, 0.86)
spring("isleCalm",  0.46, 0.96)
spring("isleGlide", 0.55, 1.00)

local function anim(leaf, speed, curve, style)
    local spec = { leaf = leaf, enabled = true, speed = speed, style = style }
    if curve == "isle" or curve == "isleCalm" or curve == "isleGlide" then
        spec.spring = curve
    else
        spec.bezier = curve
    end
    hl.animation(spec)
end

anim("windowsIn",   5.0, "isleCalm", "popin 86%")
anim("windowsOut",  5.6, "closeSoft", "popin 93%")
anim("windowsMove", 4.7, "isle")

anim("border", 9, "glide")
anim("borderangle", 60, "linear", "loop")

anim("fadeIn",     4,   "md3_decel")
anim("fadeOut",    5.0, "closeSoft")
anim("fadeSwitch", 4,   "glide")
anim("fadeShadow", 5,   "md3_decel")
anim("fadeDim",    4,   "md3_decel")

anim("fadePopupsIn",  3, "md3_decel")
anim("fadePopupsOut", 2, "md3_accel")

anim("layersIn",      5.0, "isleCalm", "popin 92%")
anim("layersOut",     3,   "md3_accel", "popin 96%")
anim("fadeLayersIn",  3,   "md3_decel")
anim("fadeLayersOut", 2,   "md3_accel")

anim("workspacesIn",  6.7, "isleGlide", "slidefade 12%")
anim("workspacesOut", 6.7, "isleGlide", "slidefade 12%")

anim("specialWorkspaceIn",  6.7, "isleGlide", "slidevert")
anim("specialWorkspaceOut", 4,   "md3_accel", "slidevert")

anim("zoomFactor", 5.0, "isleCalm")
