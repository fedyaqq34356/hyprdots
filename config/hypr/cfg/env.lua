local v = require("cfg.vars")

local function load(path)
    local f = io.open(path)
    if not f then return end
    for line in f:lines() do
        local name, value = line:match("^%s*env%s*=%s*([^,%s]+)%s*,%s*(.-)%s*$")
        if name then
            hl.env(name, (value:gsub("@HOME@", v.home)))
        end
    end
    f:close()
end

load(v.hypr .. "/config/env.conf")
load(v.hypr .. "/config/gpu-" .. v.gpu .. ".conf")
