local data = data
local mods = mods

local pairs = pairs

local castra_active = mods and (mods["castra"] or mods["castra-prime"]) and true
local cold_biters_active = mods and mods["Cold_biters"] and true
local electric_flying_enemies_active = mods and mods["Electric_flying_enemies"] and true
local explosive_biters_active = mods and mods["Explosive_biters"] and true
local sa_active = mods and mods["space-age"]

local Mod_Data = require("__TheEckelmonster-core-library__.libs.mod-data.mod-data")

local Constants = require("scripts.constants.constants")

local name = Constants.mod_name .. "-planet-data"

data.raw["mod-data"] = data.raw["mod-data"] or {}
local planet_data = data.raw["mod-data"][name] or Mod_Data.create({
    name = name,
})

local planets = {}

planets["nauvis"] = true
planets["gleba"] = sa_active
planets["castra"] = castra_active
planets["aquilo"] = cold_biters_active
planets["fulgora"] = electric_flying_enemies_active
planets["vulcanus"] = explosive_biters_active

for planet_name, enabled in pairs(planets) do
    if (planet_data.data[planet_name] == nil) then planet_data.data[planet_name] = enabled end
end

for k, v in pairs(data.raw.planet) do
    if (v.map_gen_settings and v.map_gen_settings.property_expression_names) then
        if (    v.map_gen_settings.property_expression_names["enemy_base_frequency"]
            or  v.map_gen_settings.property_expression_names["enemy_base_radius"]
        ) then
            planet_data.data[k] = true
        end
    end
end

data:extend({ planet_data, })