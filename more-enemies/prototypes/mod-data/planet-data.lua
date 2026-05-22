local data = data
local mods = mods

local cold_biters_active = mods and mods["Cold_biters"] and true
local electric_flying_enemies_active = mods and mods["Electric_flying_enemies"] and true
local explosive_biters_active = mods and mods["Explosive_biters"] and true
local sa_active = mods and mods["space-age"]

local Mod_Data = require("__TheEckelmonster-core-library__.libs.mod-data.mod-data")

local Constants = require("scripts.constants.constants")

local planet_data = Mod_Data.create({
    name = Constants.mod_name .. "-planet-data",
})

planet_data.data["nauvis"] = planet_data.data["nauvis"] or true
planet_data.data["gleba"] = planet_data.data["gleba"] or sa_active or nil

planet_data.data["aquilo"] = planet_data.data["aquilo"] or cold_biters_active or nil
planet_data.data["fulgora"] = planet_data.data["fulgora"] or electric_flying_enemies_active or nil
planet_data.data["vulcanus"] = planet_data.data["vulcanus"] or explosive_biters_active or nil

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