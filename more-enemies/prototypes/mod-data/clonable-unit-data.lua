local data = data

local Mod_Data = require("__TheEckelmonster-core-library__.libs.mod-data.mod-data")

local Constants = require("scripts.constants.constants")

data.raw["mod-data"] = data.raw["mod-data"] or {}
local clonable_unit_data = data.raw["mod-data"][Constants.mod_name .. "-clonable-unit-data"] or Mod_Data.create({
    name = Constants.mod_name .. "-clonable-unit-data",
})

local ENEMIES = "enemies"
for _, tbl in ipairs({
    data.raw.unit,
    data.raw["spider-unit"]
}) do
    for k, v in pairs(tbl) do
        if (v.subgroup == ENEMIES) then
            clonable_unit_data.data[k] = clonable_unit_data.data[k] or true
        end
    end
end

data:extend({ clonable_unit_data, })