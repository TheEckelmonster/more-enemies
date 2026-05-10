local data = data
local mods = mods

local Difficulty_Utils = require("scripts.utils.difficulty-utils")
local Nauvis_Constants = require("libs.constants.nauvis-constants")
local Settings_Validations = require("scripts.validations.settings-validations")

local difficulty = Difficulty_Utils.get_difficulty("nauvis", true)

local unit_spawner = "unit-spawner"

--
-- Biters

local spawner_name = "biter-spawner"

if (data and data.raw and data.raw[unit_spawner] and data.raw[unit_spawner][spawner_name]) then
    local spawner = data.raw[unit_spawner][spawner_name]

    local max_count_of_owned_units_biter = settings.startup["more-enemies-spawner-nauvis-max-count-of-owned-units-biter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_count_of_owned_units_biter, Nauvis_Constants.nauvis.biter.MAX_COUNT_OF_OWNED_UNITS)) then
        spawner.max_count_of_owned_units = max_count_of_owned_units_biter.value
    else
        spawner.max_count_of_owned_units = difficulty.biter.max_count_of_owned_units
    end

    local max_count_of_owned_defensive_units_biter = settings.startup["more-enemies-spawner-nauvis-max-count-of-owned-defensive-units-biter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_count_of_owned_defensive_units_biter, Nauvis_Constants.nauvis.biter.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS)) then
        spawner.max_count_of_owned_defensive_units = max_count_of_owned_defensive_units_biter.value
    else
        spawner.max_count_of_owned_defensive_units = difficulty.biter.max_count_of_owned_defensive_units
    end

    local max_friends_around_to_spawn_biter = settings.startup["more-enemies-spawner-nauvis-max-friends-around-to-spawn-biter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_friends_around_to_spawn_biter, Nauvis_Constants.nauvis.biter.MAX_FRIENDS_AROUND_TO_SPAWN)) then
        spawner.max_friends_around_to_spawn = max_friends_around_to_spawn_biter.value
    else
        spawner.max_friends_around_to_spawn = difficulty.biter.max_friends_around_to_spawn
    end

    local max_defensive_friends_around_to_spawn_biter = settings.startup["more-enemies-spawner-nauvis-max-defensive-friends-around-to-spawn-biter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_defensive_friends_around_to_spawn_biter, Nauvis_Constants.nauvis.biter.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN)) then
        spawner.max_defensive_friends_around_to_spawn = max_defensive_friends_around_to_spawn_biter.value
    else
        spawner.max_defensive_friends_around_to_spawn = difficulty.biter.max_defensive_friends_around_to_spawn
    end

    -- Spawning cooldown parameters
    local max_spawning_cooldown_biters = settings.startup["more-enemies-max-spawning-cooldown-biter"]
    local min_spawning_cooldown_biters = settings.startup["more-enemies-min-spawning-cooldown-biter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_spawning_cooldown_biters, Nauvis_Constants.nauvis.biter.MAX_SPAWNING_COOLDOWN)
            and Settings_Validations.validate_setting_not_equal_to(min_spawning_cooldown_biters, Nauvis_Constants.nauvis.biter.MIN_SPAWNING_COOLDOWN)) then
        spawner.spawning_cooldown = {
            max_spawning_cooldown_biters.value,
            min_spawning_cooldown_biters.value
        }
    else
        spawner.spawning_cooldown = {
            difficulty.biter.spawning_cooldown.max,
            difficulty.biter.spawning_cooldown.min
        }
    end
end

--
-- Spitters

spawner_name = "spitter-spawner"

if (data and data.raw and data.raw[unit_spawner] and data.raw[unit_spawner][spawner_name]) then
    local spawner = data.raw[unit_spawner][spawner_name]

    local max_count_of_owned_units_spitter = settings.startup["more-enemies-spawner-nauvis-max-count-of-owned-units-spitter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_count_of_owned_units_spitter, Nauvis_Constants.nauvis.spitter.MAX_COUNT_OF_OWNED_UNITS)) then
        spawner.max_count_of_owned_units = max_count_of_owned_units_spitter.value
    else
        spawner.max_count_of_owned_units = difficulty.spitter.max_count_of_owned_units
    end

    local max_count_of_owned_defensive_units_spitter = settings.startup["more-enemies-spawner-nauvis-max-count-of-owned-defensive-units-spitter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_count_of_owned_defensive_units_spitter, Nauvis_Constants.nauvis.spitter.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS)) then
        spawner.max_count_of_owned_defensive_units = max_count_of_owned_defensive_units_spitter.value
    else
        spawner.max_count_of_owned_defensive_units = difficulty.spitter.max_count_of_owned_defensive_units
    end

    local max_friends_around_to_spawn_spitter = settings.startup["more-enemies-spawner-nauvis-max-friends-around-to-spawn-spitter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_friends_around_to_spawn_spitter, Nauvis_Constants.nauvis.spitter.MAX_FRIENDS_AROUND_TO_SPAWN)) then
        spawner.max_friends_around_to_spawn = max_friends_around_to_spawn_spitter.value
    else
        spawner.max_friends_around_to_spawn = difficulty.spitter.max_friends_around_to_spawn
    end

    local max_defensive_friends_around_to_spawn_spitter = settings.startup["more-enemies-spawner-nauvis-max-defensive-friends-around-to-spawn-spitter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_defensive_friends_around_to_spawn_spitter, Nauvis_Constants.nauvis.spitter.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN)) then
        spawner.max_defensive_friends_around_to_spawn = max_defensive_friends_around_to_spawn_spitter.value
    else
        spawner.max_defensive_friends_around_to_spawn = difficulty.spitter.max_defensive_friends_around_to_spawn
    end

    -- Spawning cooldown parameters
    local max_spawning_cooldown_spitters = settings.startup["more-enemies-max-spawning-cooldown-spitter"]
    local min_spawning_cooldown_spitters = settings.startup["more-enemies-min-spawning-cooldown-spitter"]
    if (Settings_Validations.validate_setting_not_equal_to(max_spawning_cooldown_spitters, Nauvis_Constants.nauvis.spitter.MAX_SPAWNING_COOLDOWN)
            and Settings_Validations.validate_setting_not_equal_to(min_spawning_cooldown_spitters, Nauvis_Constants.nauvis.spitter.MIN_SPAWNING_COOLDOWN)) then
        spawner.spawning_cooldown = {
            min_spawning_cooldown_spitters.value,
            min_spawning_cooldown_spitters.value
        }
    else
        spawner.spawning_cooldown = {
            difficulty.spitter.spawning_cooldown.max,
            difficulty.spitter.spawning_cooldown.min
        }
    end
end


if (mods and mods["ArmouredBiters"]) then
    require("prototypes.spawners.mods.armoured-biters")
end

if (mods and mods["Cold_biters"]) then
    require("prototypes.spawners.mods.cold-biters")
end

if (mods and mods["Explosive_biters"]) then
    require("prototypes.spawners.mods.explosive-biters")
end

if (mods and mods["Toxic_biters"]) then
    require("prototypes.spawners.mods.toxic-biters")
end

if (mods and mods["old_biters_remastered"]) then
    require("prototypes.spawners.mods.proto-biters")
end