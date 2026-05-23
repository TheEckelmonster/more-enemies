local Util = require("settings.runtime-global.util")

local planets = { "fulgora", }

local names = { "walking", "flying", }

local tbls = {
    { planet = planets[1], name = names[1], },
    { planet = planets[1], name = names[2], },
}

local settings = {}

for i = 1, #tbls, 1 do
    local id = tbls[i].planet .. "-" .. tbls[i].name
    Util.make_settings({ settings = settings, planet = tbls[i].planet, name = tbls[i].name, id = id, })
end

return settings