local Util = require("settings.startup.util")
local planet = "nauvis"
local names = { planet .. "-toxic-biter-spawner", planet .. "-tb_infected_ship", planet .. "-tb_infected_boss", planet .. "-tb_infected_radar",}
local settings = {}

for _, name in ipairs(names or {}) do Util.make_planet_settings({ settings = settings, id = name, planet = planet, }) end

return settings