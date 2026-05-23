local Util = require("settings.runtime-global.util")

local planet = "nauvis"

local tbls = {
    { planet = planet, name = "biter", },
    { planet = planet, name = "spitter", },
}

local settings = {}

for i = 1, #tbls, 1 do
    local id = tbls[i].planet .. "-" .. tbls[i].name
    Util.make_settings({ settings = settings, planet = tbls[i].planet, name = tbls[i].name, id = id, })
end

return settings