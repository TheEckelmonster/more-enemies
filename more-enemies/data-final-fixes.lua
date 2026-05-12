local mods = mods

require("prototypes.attack-groups")
require("prototypes.entities.unit")

if (mods and mods["space-age"]) then
    require("prototypes.entities.spider-unit")
end

-- Fix the character dying in menu_simulations.nauvis_biter_base_laser_defense when difficulty is turned up
require("menu-simulations.menu-simulations")