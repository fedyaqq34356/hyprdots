local BT_SINK = "bluez_output.98_FA_2E_AD_E1_BE*"
local LINK = "*PlayStation*Link*"

local function configured (metadata, key)
  local value = metadata:find (0, key)
  return value or ""
end

local function set (metadata, key, name)
  metadata:set (0, key, "Spa:String:JSON", Json.Object { name = name }:to_string ())
end

SimpleEventHook {
  name = "custom/pulse-elite-default",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "node.name", "#", BT_SINK },
    },
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "node.name", "#", "alsa_output." .. LINK },
    },
    EventInterest {
      Constraint { "event.type", "=", "node-added" },
      Constraint { "node.name", "#", "alsa_input." .. LINK },
    },
  },
  execute = function (event)
    local node = event:get_subject ()
    local name = node.properties ["node.name"]
    local om = event:get_source ():call ("get-object-manager", "metadata")
    local metadata = om:lookup { Constraint { "metadata.name", "=", "default" } }
    if not metadata or not name then
      return
    end
    if name:find ("^alsa_input%.") then
      set (metadata, "default.configured.audio.source", name)
    elseif name:find ("^alsa_output%.") then
      set (metadata, "default.configured.audio.sink", name)
    elseif not configured (metadata, "default.configured.audio.sink"):find ("PlayStation") then
      set (metadata, "default.configured.audio.sink", name)
    end
  end
}:register ()
