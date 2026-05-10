local data = data
local mods = mods

local Armoured_Biters_Constants = require("libs.constants.mods.armoured-biters-constants")
local Behemoth_Enemies_Constants = require("libs.constants.mods.behemoth-enemies-constants")
local Constants = require("libs.constants.constants")
local Difficulty_Utils = require("scripts.utils.difficulty-utils")
local Gleba_Constants = require("libs.constants.gleba-constants")
local Log = require("libs.log.log")
local Nauvis_Constants = require("libs.constants.nauvis-constants")
local Settings_Service = require("scripts.service.settings-service")

local difficulties = {}

for k, planet in pairs(Constants.DEFAULTS.planets) do
    if (planet) then
        difficulties[planet.string_val] = Difficulty_Utils.get_difficulty(planet.string_val, true)
    end
end

local modifier = 1
local radius_modifier = 1
local vanilla = false

if (data and data.raw and data.raw["map-settings"] and data.raw["map-settings"]["map-settings"]) then
    local map_settings = data.raw["map-settings"]["map-settings"]
    map_settings.max_gathering_unit_groups = Settings_Service.get_max_gathering_unit_groups()
    map_settings.path_finder.clients_to_accept_any_new_request = Settings_Service.get_max_clients_to_accept_any_new_request()
    map_settings.path_finder.clients_to_accept_short_new_request = Settings_Service.get_max_clients_to_accept_short_new_request()
    map_settings.path_finder.direct_distance_to_consider_short_request = Settings_Service.get_direct_distance_to_consider_short_request()
    map_settings.path_finder.short_request_max_steps = Settings_Service.get_short_request_max_steps()
    map_settings.unit_group.max_unit_group_size = Settings_Service.get_max_unit_group_size_runtime()
end

for planet, difficulty in pairs(difficulties) do
    vanilla = false

    if (not planet or not difficulty or not difficulty.valid) then goto continue end

    if (difficulty.selected_difficulty.string_val == Constants.difficulty.EASY.string_val
            or difficulty.selected_difficulty.value == Constants.difficulty.EASY.value)
    then
        modifier = Constants.difficulty.EASY.value
        -- radius_modifier = 0.5 --      15
        radius_modifier = Constants.difficulty.EASY.radius_modifier
    elseif (difficulty.selected_difficulty.string_val == Constants.difficulty.VANILLA.string_val
            or difficulty.selected_difficulty.value == Constants.difficulty.VANILLA.value)
    then
        modifier = Constants.difficulty.VANILLA.value
        -- radius_modifier = 1 --        30
        radius_modifier = Constants.difficulty.VANILLA.radius_modifier
        vanilla = true
    elseif (difficulty.selected_difficulty.string_val == Constants.difficulty.VANILLA_PLUS.string_val
            or difficulty.selected_difficulty.value == Constants.difficulty.VANILLA_PLUS.value)
    then
        modifier = Constants.difficulty.VANILLA_PLUS.value
        -- radius_modifier = 1.25 --     37.5
        radius_modifier = Constants.difficulty.VANILLA_PLUS.radius_modifier
    elseif (difficulty.selected_difficulty.string_val == Constants.difficulty.HARD.string_val
            or difficulty.selected_difficulty.value == Constants.difficulty.HARD.value)
    then
        modifier = Constants.difficulty.HARD.value
        -- radius_modifier = 1.5625 --   46.875
        radius_modifier = Constants.difficulty.HARD.radius_modifier
    elseif (difficulty.selected_difficulty.string_val == Constants.difficulty.INSANITY.string_val
            or difficulty.selected_difficulty.value == Constants.difficulty.INSANITY.value)
    then
        modifier = Constants.difficulty.INSANITY.value
        -- radius_modifier = 1.953125 -- 58.59375
        radius_modifier = Constants.difficulty.INSANITY.radius_modifier
    else
        Log.debug("more-enemies: map-settings -> difficulty = ")
        Log.info(difficulty)
        Log.warn("No difficulty detected ")
        modifier = -1
    end

    if (not vanilla and modifier > 0 and radius_modifier >= 0) then
        data.raw["map-settings"]["map-settings"].max_group_radius = Constants.DEFAULTS.unit_group.max_group_radius * radius_modifier
        -- data.raw["map-settings"]["map-settings"].min_group_radius = unit_group.min_group_radius / radius_modifier
        -- data.raw["map-settings"]["map-settings"].unit_group.max_unit_group_size = Constants.DEFAULTS.unit_group.max_unit_group_size * modifier

        if (planet == "nauvis") then
            for k, v in pairs(Nauvis_Constants.nauvis.categories) do
                data.raw["unit"][v.name .. "-biter"].absorptions_to_join_attack.pollution = data.raw["unit"][v.name .. "-biter"].absorptions_to_join_attack.pollution / modifier
                data.raw["unit"][v.name .. "-spitter"].absorptions_to_join_attack.pollution = data.raw["unit"][v.name .. "-spitter"].absorptions_to_join_attack.pollution / modifier
            end

            if (mods and mods["ArmouredBiters"]) then
                for k, v in pairs(Armoured_Biters_Constants.nauvis.categories) do
                    data.raw["unit"][v .. "-armoured-biter"].absorptions_to_join_attack.pollution = data.raw["unit"][v .. "-armoured-biter"].absorptions_to_join_attack.pollution / modifier
                end
            end
        end

        if (planet == "gleba" and mods and mods["space-age"]) then
            for k, v in pairs(Gleba_Constants.gleba.categories) do
                data.raw["unit"][v.name .. "-wriggler-pentapod"].absorptions_to_join_attack.spores = data.raw["unit"][v.name .. "-wriggler-pentapod"].absorptions_to_join_attack.spores / modifier
                data.raw["spider-unit"][v.name .. "-strafer-pentapod"].absorptions_to_join_attack.spores = data.raw["spider-unit"][v.name .. "-strafer-pentapod"].absorptions_to_join_attack.spores / modifier
                data.raw["spider-unit"][v.name .. "-stomper-pentapod"].absorptions_to_join_attack.spores = data.raw["spider-unit"][v.name .. "-stomper-pentapod"].absorptions_to_join_attack.spores / modifier
            end
        end
    end
    ::continue::
end

if (modifier > 0 and mods and mods["space-age"] and mods["behemoth-enemies"]) then
    data.raw["unit"][Behemoth_Enemies_Constants.prefix .. "-wriggler-pentapod"].absorptions_to_join_attack.spores = data.raw["unit"][Behemoth_Enemies_Constants.prefix .. "-wriggler-pentapod"].absorptions_to_join_attack.spores / modifier
    data.raw["spider-unit"][Behemoth_Enemies_Constants.prefix .. "-strafer-pentapod"].absorptions_to_join_attack.spores = data.raw["spider-unit"][Behemoth_Enemies_Constants.prefix .. "-strafer-pentapod"].absorptions_to_join_attack.spores / modifier
    data.raw["spider-unit"][Behemoth_Enemies_Constants.prefix .. "-stomper-pentapod"].absorptions_to_join_attack.spores = data.raw["spider-unit"][Behemoth_Enemies_Constants.prefix .. "-stomper-pentapod"].absorptions_to_join_attack.spores / modifier
end