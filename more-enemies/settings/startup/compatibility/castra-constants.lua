local Util = require("settings.startup.util")
local planet = "castra"
local names = { "enemy-tank", }
local settings = {}

for _, name in ipairs(names or {}) do Util.make_planet_settings({ settings = settings, id = name, planet = planet, }) end

return settings