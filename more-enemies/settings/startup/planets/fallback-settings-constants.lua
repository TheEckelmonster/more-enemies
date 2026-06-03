local Util = require("settings.startup.util")
local id = "fallback"
local order = "aab[zzz" .. id .. "]-zzz[difficulty]"
return Util.make_difficulty_settings({ settings = {}, id = id, order = order, })