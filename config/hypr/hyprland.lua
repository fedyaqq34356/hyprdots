local v = require("cfg.vars")

require("cfg.env")
require("cfg.look")
require("cfg.animations")
require("cfg.binds")
require("cfg.rules")
require("cfg.startup")

if v.serezha then
    require("cfg.serezha")
end
