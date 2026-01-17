-- local Collision_Mask_Util = require("__base__/core/lualib/collision-mask-util")

-- D:\Steam\steamapps\common\Factorio\data\core\lualib\collision-mask-util.lua

local Collision_Mask_Util = require("__core__.lualib.collision-mask-util")

local new_collision_layer = { type = "collision-layer", name = "more_enemies" }

data:extend{new_collision_layer}

local units = data.raw["unit"]
local unit_spawners = data.raw["unit-spawner"]

local default_masks = Collision_Mask_Util.get_default_mask("unit")

for _, v in pairs(units) do
    -- if (not v.collision_mask) then v.collision_mask = {} end
    if (not v.collision_mask) then v.collision_mask = default_masks end
    -- if (not v.collision_mask.layers) then v.collision_mask.layers = {} end
    v.collision_mask.layers[new_collision_layer.name] = true
    v.collision_mask.layers["object"] = true
end

default_masks = Collision_Mask_Util.get_default_mask("unit-spawner")

for _, v in pairs(unit_spawners) do
    -- if (not v.collision_mask) then v.collision_mask = {} end
    if (not v.collision_mask) then v.collision_mask = default_masks end
    -- if (not v.collision_mask.layers) then v.collision_mask.layers = {} end
    v.collision_mask.layers[new_collision_layer.name] = true
    v.collision_mask.layers["object"] = true
end