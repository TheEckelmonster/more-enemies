local Util = require("settings.startup.util")
local planet = "tellus"
local names = { planet .. "-spawner", planet .. "-spawner-small", }
local settings = {}

for _, name in ipairs(names or {}) do Util.make_planet_settings({ settings = settings, id = name, planet = planet, }) end

return settings