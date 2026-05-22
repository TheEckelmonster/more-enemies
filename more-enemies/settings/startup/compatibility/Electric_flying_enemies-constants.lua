local Util = require("settings.startup.util")
local planet = "fulgora"
local names = { planet .. "-flying-unit-spawner", planet .. "-walker-unit-spawner", }
local settings = {}

for _, name in ipairs(names or {}) do Util.make_planet_settings({ settings = settings, id = name, planet = planet, }) end

return settings