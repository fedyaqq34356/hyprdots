local v = require("cfg.vars")

local f = io.open(v.hypr .. "/config/env.conf")
if f then
    for line in f:lines() do
        local name, value = line:match("^%s*env%s*=%s*([^,%s]+)%s*,%s*(.-)%s*$")
        if name then
            hl.env(name, value)
        end
    end
    f:close()
end
