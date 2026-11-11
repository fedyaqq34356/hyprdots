local M = {}

M.home = os.getenv("HOME")
M.hypr = M.home .. "/.config/hypr"
M.scripts = M.hypr .. "/scripts"
M.mainMod = "SUPER"

local function readVars(path)
    local vars = {}
    local f = io.open(path)
    if not f then return vars end
    for line in f:lines() do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name then vars[name] = value end
    end
    f:close()
    return vars
end

local colors = readVars(M.hypr .. "/config/colors.conf")
local fallback = {
    accent = "rgb(efbf67)",
    active_border_1 = "rgba(efbf67ff)",
    active_border_2 = "rgba(bccf7cff)",
    inactive_border = "rgba(9b8f7eaa)",
    shadow = "rgba(0d0b0866)",
    shadow_inactive = "rgba(0d0b083d)",
}
M.c = setmetatable({}, {
    __index = function(_, k) return colors[k] or fallback[k] end,
})

local shape = readVars(M.hypr .. "/config/shape.conf")
M.winRounding = tonumber(shape.winRounding) or 30

local p = io.popen("readlink -f '" .. M.hypr .. "/config/mode.conf' 2>/dev/null")
local target = p and p:read("l") or ""
if p then p:close() end
M.serezha = target:match("mode%-serezha%.conf$") ~= nil

local function exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end

local function detectGpu()
    local vendors = {}
    local q = io.popen("cat /sys/class/drm/card[0-9]*/device/vendor 2>/dev/null")
    if q then
        for id in q:lines() do vendors[id] = true end
        q:close()
    end
    if vendors["0x10de"] and exists("/sys/module/nvidia_drm") then return "nvidia" end
    if vendors["0x1002"] then return "amd" end
    if vendors["0x8086"] then return "intel" end
    return "generic"
end

M.gpu = os.getenv("ROSA_GPU") or os.getenv("HYPRDOTS_GPU") or detectGpu()

local b = io.popen("ls -d /sys/class/power_supply/BAT* /sys/class/backlight/* 2>/dev/null")
local found = b and b:read("a") or ""
if b then b:close() end
M.battery = found:match("/power_supply/BAT") ~= nil
M.backlight = found:match("/backlight/") ~= nil

return M
