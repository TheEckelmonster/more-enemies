local storage
local storage_startup_settings
local storage_runtime_settings

local settings = settings
local settings_startup = settings.startup
local settings_runtime = settings.global

local BREAM_Settings_Constants = require("libs.constants.settings.mods.BREAM.BREAM-settings-constants")
local Constants = require("libs.constants.constants")
local Gleba_Settings_Constants = require("libs.constants.settings.gleba-settings-constants")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")
local Nauvis_Settings_Constants = require("libs.constants.settings.nauvis-settings-constants")

local settings_service = {}

local locals = {}

-- CLONE_NAUVIS_UNITS
function settings_service.get_clone_unit_setting(surface_name)
    local setting = 1

    if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val
            and settings_runtime and settings_runtime[Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNITS.name])
    then
        setting = settings_runtime[Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNITS.name].value
    elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val
            and settings_runtime and settings_runtime[Gleba_Settings_Constants.settings.CLONE_GLEBA_UNITS.name])
    then
        setting = settings_runtime[Gleba_Settings_Constants.settings.CLONE_GLEBA_UNITS.name].value
    end

    return setting
end

-- CLONE_NAUVIS_UNIT_GROUPS
function settings_service.get_clone_unit_group_setting(surface_name)
    local setting = 1

    if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val and settings_runtime and settings_runtime[Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNIT_GROUPS.name]) then
        setting = settings_runtime[Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNIT_GROUPS.name].value
    elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val and settings_runtime and settings_runtime[Gleba_Settings_Constants.settings.CLONE_GLEBA_UNIT_GROUPS.name]) then
        setting = settings_runtime[Gleba_Settings_Constants.settings.CLONE_GLEBA_UNIT_GROUPS.name].value
    end

    return setting
end

-- MAX_UNIT_GROUP_SIZE_RUNTIME
-- MAX_UNIT_GROUP_SIZE_STARTUP
function settings_service.get_maximum_group_size()
    local limit_runtime = Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

    limit_runtime = settings_service.get_max_unit_group_size_runtime()

    return limit_runtime
end

-- MAX_UNIT_GROUP_SIZE_RUNTIME
function settings_service.get_max_unit_group_size_runtime()
    local limit_runtime = Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

    if (settings_runtime and settings_runtime[Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name]) then
        limit_runtime = settings_runtime[Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name].value
    end

    return limit_runtime
end

-- MAX_UNIT_GROUP_SIZE_STARTUP
function settings_service.get_max_unit_group_size_startup()
    local limit_startup = Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_STARTUP.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_STARTUP.name]) then
        limit_startup = settings_startup[Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_STARTUP.name].value
    end

    return limit_startup
end

-- NTH_TICK
function settings_service.get_nth_tick()
    local setting = Global_Settings_Constants.settings.NTH_TICK.value

    if (settings_runtime and settings_runtime[Global_Settings_Constants.settings.NTH_TICK.name]) then
        setting = settings_runtime[Global_Settings_Constants.settings.NTH_TICK.name].value
    end

    return setting
end

-- CLONES_PER_TICK
function settings_service.get_clones_per_tick()
    local setting = Global_Settings_Constants.settings.CLONES_PER_TICK.value

    if (settings_runtime and settings_runtime[Global_Settings_Constants.settings.CLONES_PER_TICK.name]) then
        setting = settings_runtime[Global_Settings_Constants.settings.CLONES_PER_TICK.name].value
    end

    return setting
end

-- MAXIMUM_NUMBER_OF_SPAWNED_CLONES
function settings_service.get_maximum_number_of_spawned_clones(surface_name)
    local setting = 0

    if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val and settings_runtime and settings_runtime[Nauvis_Settings_Constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS.name]) then
        setting = settings_runtime[Nauvis_Settings_Constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS.name].value
    elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val and settings_runtime and settings_runtime[Gleba_Settings_Constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA.name]) then
        setting = settings_runtime[Gleba_Settings_Constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA.name].value
    end

    return setting
end

-- MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES
function settings_service.get_maximum_number_of_unit_group_clones(surface_name)
    local setting = 0

    if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val and settings_runtime and settings_runtime[Nauvis_Settings_Constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS.name]) then
        setting = settings_runtime[Nauvis_Settings_Constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS.name].value
    elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val and settings_runtime and settings_runtime[Gleba_Settings_Constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA.name]) then
        setting = settings_runtime[Gleba_Settings_Constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA.name].value
    end

    return setting
end

-- MAXIMUM_NUMBER_OF_MODDED_CLONES
function settings_service.get_maximum_number_of_modded_clones()
    local setting = Global_Settings_Constants.settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.default_value

    if (settings_runtime and settings_runtime[Global_Settings_Constants.settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name]) then
        setting = settings_runtime[Global_Settings_Constants.settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name].value
    end

    return setting
end

-- NAUVIS_DO_EVOLUTION_FACTOR
-- GLEBA_DO_EVOLUTION_FACTOR
function settings_service.get_do_evolution_factor(surface_name)
    local setting = false

    if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val
            and settings_runtime and settings_runtime[Nauvis_Settings_Constants.settings.NAUVIS_DO_EVOLUTION_FACTOR.name])
    then
        setting = settings_runtime[Nauvis_Settings_Constants.settings.NAUVIS_DO_EVOLUTION_FACTOR.name].value
    elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val
            and settings_runtime and settings_runtime[Gleba_Settings_Constants.settings.GLEBA_DO_EVOLUTION_FACTOR.name]) then
        setting = settings_runtime[Gleba_Settings_Constants.settings.GLEBA_DO_EVOLUTION_FACTOR.name].value
    end

    return setting
end

-- NAUVIS_DIFFICULTY
-- GLEBA_DIFFICULTY
function settings_service.get_difficulty(surface_name)
    local setting = "Vanilla"

    if (surface_name == Constants.DEFAULTS.planets.nauvis.string_val and settings_startup and settings_startup[Nauvis_Settings_Constants.settings.NAUVIS_DIFFICULTY.name]) then
        setting = settings_startup[Nauvis_Settings_Constants.settings.NAUVIS_DIFFICULTY.name].value
    elseif (surface_name == Constants.DEFAULTS.planets.gleba.string_val and settings_startup and settings_startup[Gleba_Settings_Constants.settings.GLEBA_DIFFICULTY.name]) then
        setting = settings_startup[Gleba_Settings_Constants.settings.GLEBA_DIFFICULTY.name].value
    end

    return setting
end

-- MAX_GATHERING_UNIT_GROUPS
function settings_service.get_max_gathering_unit_groups()
    local setting = Global_Settings_Constants.settings.MAX_GATHERING_UNIT_GROUPS.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.MAX_GATHERING_UNIT_GROUPS.name]) then
        setting = settings_startup[Global_Settings_Constants.settings.MAX_GATHERING_UNIT_GROUPS.name].value
    end

    return setting
end

-- MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST
function settings_service.get_max_clients_to_accept_any_new_request()
    local setting = Global_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST.name]) then
        setting = settings_startup[Global_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST.name].value
    end

    return setting
end

-- MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST
function settings_service.get_max_clients_to_accept_short_new_request()
    local setting = Global_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST.name]) then
        setting = settings_startup[Global_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST.name].value
    end

    return setting
end

-- DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST
function settings_service.get_direct_distance_to_consider_short_request()
    local setting = Global_Settings_Constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST.name]) then
        setting = settings_startup[Global_Settings_Constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST.name].value
    end

    return setting
end

-- SHORT_REQUEST_MAX_STEPS
function settings_service.get_short_request_max_steps()
    local setting = Global_Settings_Constants.settings.SHORT_REQUEST_MAX_STEPS.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.SHORT_REQUEST_MAX_STEPS.name]) then
        setting = settings_startup[Global_Settings_Constants.settings.SHORT_REQUEST_MAX_STEPS.name].value
    end

    return setting
end

-- MINIMUM_ATTACK_GROUP_DELAY
function settings_service.get_minimum_attack_group_delay()
    local setting = Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.default_value

    if (settings_runtime and settings_runtime[Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name]) then
        setting = settings_runtime[Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name].value
    end

    return setting
end

-- MAXIMUM_ATTACK_GROUP_DELAY
function settings_service.get_maximum_attack_group_delay()
    local setting = Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.default_value

    if (settings_runtime and settings_runtime[Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name]) then
        setting = settings_runtime[Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name].value
    end

    return setting
end

-- ATTACK_GROUP_BLACKLIST_NAMES
function settings_service.get_attack_group_blacklist_names()
    local setting = Global_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES.default_value

    if (settings_startup and settings_startup[Global_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES.name]) then
        setting = settings_startup[Global_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES.name].value
    end

    return setting
end

-- NAUVIS_DO_ATTACK_GROUP
-- GLEBA_DO_ATTACK_GROUP
local do_attack_group = {
    [Constants.DEFAULTS.planets.nauvis.string_val] = Nauvis_Settings_Constants.settings.NAUVIS_DO_ATTACK_GROUP.name,
    [Constants.DEFAULTS.planets.gleba.string_val]  = Gleba_Settings_Constants.settings.GLEBA_DO_ATTACK_GROUP.name,
}
function settings_service.get_do_attack_group(surface_name)
    local default = false
    local setting = default
    local name = do_attack_group[surface_name]

    if (storage_runtime_settings and not storage_runtime_settings[name] and settings_runtime[name or ""]) then
        setting = settings_runtime[name].value
        storage_runtime_settings[name] = setting
    else
        setting = storage_runtime_settings and storage_runtime_settings[name] or settings_runtime[name].value
    end

    return setting
end

-- NAUVIS_ATTACK_GROUP_PEACE_TIME
-- GLEBA_ATTACK_GROUP_PEACE_TIME
local attack_group_peace_time = {
    [Constants.DEFAULTS.planets.nauvis.string_val] = Nauvis_Settings_Constants.settings.NAUVIS_ATTACK_GROUP_PEACE_TIME.name,
    [Constants.DEFAULTS.planets.gleba.string_val]  = Gleba_Settings_Constants.settings.GLEBA_ATTACK_GROUP_PEACE_TIME.name,
}
function settings_service.get_attack_group_peace_time(surface_name)
    local default = 45
    local setting = default
    local name = attack_group_peace_time[surface_name]

    if (storage_runtime_settings and not storage_runtime_settings[name] and settings_runtime[name or ""]) then
        setting = settings_runtime[name].value
        storage_runtime_settings[name] = setting
    else
        setting = storage_runtime_settings and storage_runtime_settings[name] or settings_runtime[name].value
    end

    return setting
end

-- NAUVIS_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER
-- GLEBA_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER
local spawn_attack_group_probability_modifier = {
    [Constants.DEFAULTS.planets.nauvis.string_val] = Nauvis_Settings_Constants.settings.NAUVIS_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER.name,
    [Constants.DEFAULTS.planets.gleba.string_val]  = Gleba_Settings_Constants.settings.GLEBA_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER.name,
}
function settings_service.get_spawn_attack_group_probability_modifier(surface_name)
    local default = 1
    local setting = default
    local name = spawn_attack_group_probability_modifier[surface_name]

    if (storage_runtime_settings and not storage_runtime_settings[name] and settings_runtime[name or ""]) then
        setting = settings_runtime[name].value
        storage_runtime_settings[name] = setting
    else
        setting = storage_runtime_settings and storage_runtime_settings[name] or settings_runtime[name].value
    end

    return setting
end

-- NAUVIS_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER
-- GLEBA_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER
local attack_group_probability_modifiers = {
    [Constants.DEFAULTS.planets.nauvis.string_val] = Nauvis_Settings_Constants.settings.NAUVIS_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER.name,
    [Constants.DEFAULTS.planets.gleba.string_val]  = Gleba_Settings_Constants.settings.GLEBA_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER.name,
}
function settings_service.get_attack_group_require_nearby_spawner(surface_name)
    return locals.get_runtime_setting({ true, attack_group_probability_modifiers[surface_name], })
end

--[[
      BREAM
  ]]

-- BREAM_DO_CLONE
function settings_service.get_BREAM_do_clone()
    local setting = BREAM_Settings_Constants.settings.BREAM_DO_CLONE.default_value

    if (settings_runtime and settings_runtime[BREAM_Settings_Constants.settings.BREAM_DO_CLONE.name]) then
        setting = settings_runtime[BREAM_Settings_Constants.settings.BREAM_DO_CLONE.name].value
    end

    return setting
end

-- BREAM_CLONE_UNITS
function settings_service.get_BREAM_clone_units()
    local setting = BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS.default_value

    if (settings_runtime and settings_runtime[BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS.name]) then
        setting = settings_runtime[BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS.name].value
    end

    return setting
end

-- BREAM_DIFFICULTY
function settings_service.get_BREAM_difficulty()
    local setting = BREAM_Settings_Constants.settings.BREAM_DIFFICULTY.default_value

    if (settings_startup and settings_startup[BREAM_Settings_Constants.settings.BREAM_DIFFICULTY.name]) then
        setting = settings_startup[BREAM_Settings_Constants.settings.BREAM_DIFFICULTY.name].value
    end

    return setting
end

-- BREAM_USE_EVOLUTION_FACTOR
function settings_service.get_BREAM_use_evolution_factor()
    local setting = BREAM_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR.default_value

    if (settings_runtime and settings_runtime[BREAM_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR.name]) then
        setting = settings_runtime[BREAM_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR.name].value
    end

    return setting
end

function locals.get_runtime_setting(params)
    if (not params or not params.default or not params.name) then return end
    local setting = params.default
    local name = params.name

    if (storage_runtime_settings and not storage_runtime_settings[name] and settings_runtime[name or ""]) then
        setting = settings_runtime[name].value
        storage_runtime_settings[name] = setting.value
    else
        setting = storage_runtime_settings and storage_runtime_settings[name] or settings_runtime[name].value
    end

    return setting
end

function settings_service.init(__storage)
    storage = __storage

    if (storage and storage.settings) then
        if (storage.settings.startup) then storage_startup_settings = storage.settings.startup end
        if (storage.settings.runtime_global) then storage_runtime_settings = storage.settings.runtime_global end
    end
end

return settings_service