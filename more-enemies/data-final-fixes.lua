local mods = mods

require("prototypes.globals.me-data-api")

require("prototypes.mod-data.clonable-unit-data")
require("prototypes.mod-data.target-priority-data")

require("prototypes.attack-groups")
require("prototypes.entities.unit")

if (mods and mods["space-age"]) then
    require("prototypes.entities.spider-unit")
end

require("prototypes.mod-data.planet-data")

-- Fix the character dying in menu_simulations.nauvis_biter_base_laser_defense when difficulty is turned up
require("menu-simulations.menu-simulations")