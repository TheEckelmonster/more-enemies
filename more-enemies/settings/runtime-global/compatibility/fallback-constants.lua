local Util = require("settings.runtime-global.util")
local id = "fallback"
local settings = {}
Util.make_settings({ settings = settings, id = id, })
return settings