local Util = require("settings.startup.util")
local names = { "fallback", }
local settings = {}

for _, name in ipairs(names or {}) do Util.make_planet_settings({ settings = settings, id = name, }) end

return settings