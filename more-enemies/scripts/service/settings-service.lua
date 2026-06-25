local storage
local storage_startup_settings
local storage_runtime_settings

local settings = settings
local settings_startup = settings.startup
local settings_runtime = settings.global

local Planets = Planets

local Valid_Surfaces = Valid_Surfaces or {}

local Startup_Settings_Constants = Startup_Settings_Constants or require("settings.startup.startup-settings-constants")
local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants or require("settings.runtime-global.runtime-global-settings-constants")

local settings_service = {}

local locals = {}

-- CLONE_NAUVIS_UNITS
-- CLONE_GLEBA_UNITS
local clone_units = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        clone_units[planet] = (Runtime_Global_Settings_Constants.settings["CLONE_" .. planet:gsub("%-", "_"):upper() .. "_UNITS"] or {}).name
    end
end
function settings_service.get_clone_unit_setting(surface_name)
    return Valid_Surfaces[surface_name] and locals.get_runtime_setting({ name = clone_units[surface_name], default = true, }) or nil
end

-- CLONE_NAUVIS_UNIT_GROUPS
-- CLONE_GLEBA_UNIT_GROUPS
local clone_unit_groups = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        clone_unit_groups[planet] = (Runtime_Global_Settings_Constants.settings["CLONE_" .. planet:gsub("%-", "_"):upper() .. "_UNIT_GROUPS"] or {}).name
    end
end
function settings_service.get_clone_unit_group_setting(surface_name)
    return Valid_Surfaces[surface_name] and locals.get_runtime_setting({ name = clone_unit_groups[surface_name], default = true, }) or nil
end

-- MAX_UNIT_GROUP_SIZE_RUNTIME
function settings_service.get_max_unit_group_size_runtime()
    local limit_runtime = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

    if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name]) then
        limit_runtime = settings_runtime[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name].value
    end

    return limit_runtime
end
settings_service.get_maximum_group_size = settings_service.get_max_unit_group_size_runtime

-- MAX_UNIT_GROUP_SIZE_STARTUP
function settings_service.get_max_unit_group_size_startup()
    local limit_startup = Startup_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_STARTUP.default_value

    if (settings_runtime and settings_runtime[Startup_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_STARTUP.name]) then
        limit_startup = settings_runtime[Startup_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_STARTUP.name].value
    end

    return limit_startup
end

-- CLONES_PER_TICK
function settings_service.get_clones_per_tick()
    local setting = Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK.value

    if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK.name]) then
        setting = settings_runtime[Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK.name].value
    end

    return setting
end

-- NAUVIS_DO_EVOLUTION_FACTOR
-- GLEBA_DO_EVOLUTION_FACTOR
local evolution_factors = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        evolution_factors[planet] = (Runtime_Global_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_DO_EVOLUTION_FACTOR"] or {}).name or nil
    end
end
function settings_service.get_do_evolution_factor(surface_name)
    return Valid_Surfaces[surface_name] and locals.get_runtime_setting({ name = evolution_factors[surface_name], default = true, })
end

-- NAUVIS_DIFFICULTY
-- GLEBA_DIFFICULTY
local VANILLA = "Vanilla"
local difficulties = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        difficulties[planet] = (Startup_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name or nil
    end
end
function settings_service.get_difficulty(surface_name)
    return Valid_Surfaces[surface_name] and locals.get_startup_setting({ name = difficulties[surface_name], default = VANILLA, }) or VANILLA
end

-- MAX_GATHERING_UNIT_GROUPS
function settings_service.get_max_gathering_unit_groups()
    local setting = Startup_Settings_Constants.settings.MAX_GATHERING_UNIT_GROUPS.default_value

    if (settings_startup and settings_startup[Startup_Settings_Constants.settings.MAX_GATHERING_UNIT_GROUPS.name]) then
        setting = settings_startup[Startup_Settings_Constants.settings.MAX_GATHERING_UNIT_GROUPS.name].value
    end

    return setting
end

-- MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST
function settings_service.get_max_clients_to_accept_any_new_request()
    local setting = Startup_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST.default_value

    if (settings_startup and settings_startup[Startup_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST.name]) then
        setting = settings_startup[Startup_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST.name].value
    end

    return setting
end

-- MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST
function settings_service.get_max_clients_to_accept_short_new_request()
    local setting = Startup_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST.default_value

    if (settings_startup and settings_startup[Startup_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST.name]) then
        setting = settings_startup[Startup_Settings_Constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST.name].value
    end

    return setting
end

-- DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST
function settings_service.get_direct_distance_to_consider_short_request()
    local setting = Startup_Settings_Constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST.default_value

    if (settings_startup and settings_startup[Startup_Settings_Constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST.name]) then
        setting = settings_startup[Startup_Settings_Constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST.name].value
    end

    return setting
end

-- SHORT_REQUEST_MAX_STEPS
function settings_service.get_short_request_max_steps()
    local setting = Startup_Settings_Constants.settings.SHORT_REQUEST_MAX_STEPS.default_value

    if (settings_startup and settings_startup[Startup_Settings_Constants.settings.SHORT_REQUEST_MAX_STEPS.name]) then
        setting = settings_startup[Startup_Settings_Constants.settings.SHORT_REQUEST_MAX_STEPS.name].value
    end

    return setting
end

-- MINIMUM_ATTACK_GROUP_DELAY
function settings_service.get_minimum_attack_group_delay()
    local setting = Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.default_value

    if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name]) then
        setting = settings_runtime[Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name].value
    end

    return setting
end

-- MAXIMUM_ATTACK_GROUP_DELAY
function settings_service.get_maximum_attack_group_delay()
    local setting = Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.default_value

    if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name]) then
        setting = settings_runtime[Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name].value
    end

    return setting
end

-- ATTACK_GROUP_BLACKLIST_NAMES
function settings_service.get_attack_group_blacklist_names()
    local setting = ""

    if (    settings_startup
        and Startup_Settings_Constants
        and Startup_Settings_Constants.settings
        and Startup_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES
        and Startup_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES.name
        and settings_startup[Startup_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES.name]
    ) then
        setting = settings_startup[Startup_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES.name].value
    end

    return setting
end

-- NAUVIS_DO_ATTACK_GROUP
-- GLEBA_DO_ATTACK_GROUP
local do_attack_group = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        do_attack_group[planet] = (Runtime_Global_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_DO_ATTACK_GROUP"] or {}).name
    end
end
function settings_service.get_do_attack_group(surface_name)
    local default = false
    local setting = default
    local name = do_attack_group[surface_name]

    if (name) then
        if (storage_runtime_settings and not storage_runtime_settings[name] and settings_runtime[name or ""]) then
            setting = settings_runtime[name].value
            storage_runtime_settings[name] = setting
        else
            setting = storage_runtime_settings and storage_runtime_settings[name] or settings_runtime[name] and settings_runtime[name].value
        end
    end

    return setting
end

-- NAUVIS_ATTACK_GROUP_PEACE_TIME
-- GLEBA_ATTACK_GROUP_PEACE_TIME
local attack_group_peace_time = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        attack_group_peace_time[planet] = Runtime_Global_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_ATTACK_GROUP_PEACE_TIME"] and Runtime_Global_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_ATTACK_GROUP_PEACE_TIME"].name or nil
    end
end
function settings_service.get_attack_group_peace_time(surface_name, reindex)
    return Valid_Surfaces[surface_name] and locals.get_runtime_setting({ name = attack_group_peace_time[surface_name], default = 45, reindex = reindex, }) or nil
end

-- NAUVIS_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER
-- GLEBA_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER
local attack_group_probability_modifiers = {}
if (Planets) then
    for _, planet in ipairs(Planets) do
        attack_group_probability_modifiers[planet] = Runtime_Global_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"] and Runtime_Global_Settings_Constants.settings[planet:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"].name or nil
    end
end
function settings_service.get_spawn_attack_group_probability_modifier(surface_name)
    return Valid_Surfaces[surface_name] and locals.get_runtime_setting({ name = attack_group_probability_modifiers[surface_name], default = 1, }) or nil
end

-- -- NAUVIS_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER
-- -- GLEBA_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER
-- local attack_group_probability_modifiers = {
--     [Constants.DEFAULTS.planets.nauvis.string_val] = Nauvis_Settings_Constants.settings.NAUVIS_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER.name,
--     [Constants.DEFAULTS.planets.gleba.string_val]  = Gleba_Settings_Constants.settings.GLEBA_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER.name,
-- }
-- function settings_service.get_attack_group_require_nearby_spawner(surface_name)
--     return locals.get_runtime_setting({ true, attack_group_probability_modifiers[surface_name], })
-- end

-- --[[
--       BREAM
--   ]]

-- -- BREAM_DO_CLONE
-- function settings_service.get_BREAM_do_clone()
--     local setting = Runtime_Global_Settings_Constants.settings.BREAM_DO_CLONE.default_value

--     if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.BREAM_DO_CLONE.name]) then
--         setting = settings_runtime[Runtime_Global_Settings_Constants.settings.BREAM_DO_CLONE.name].value
--     end

--     return setting
-- end

-- -- BREAM_CLONE_UNITS
-- function settings_service.get_BREAM_clone_units()
--     local setting = Runtime_Global_Settings_Constants.settings.BREAM_CLONE_UNITS.default_value

--     if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.BREAM_CLONE_UNITS.name]) then
--         setting = settings_runtime[Runtime_Global_Settings_Constants.settings.BREAM_CLONE_UNITS.name].value
--     end

--     return setting
-- end

-- -- BREAM_DIFFICULTY
-- function settings_service.get_BREAM_difficulty()
--     local setting = Runtime_Global_Settings_Constants.settings.BREAM_DIFFICULTY.default_value

--     if (settings_startup and settings_startup[Runtime_Global_Settings_Constants.settings.BREAM_DIFFICULTY.name]) then
--         setting = settings_startup[Runtime_Global_Settings_Constants.settings.BREAM_DIFFICULTY.name].value
--     end

--     return setting
-- end

-- -- BREAM_USE_EVOLUTION_FACTOR
-- function settings_service.get_BREAM_use_evolution_factor()
--     local setting = Runtime_Global_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR.default_value

--     if (settings_runtime and settings_runtime[Runtime_Global_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR.name]) then
--         setting = settings_runtime[Runtime_Global_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR.name].value
--     end

--     return setting
-- end

function settings_service.get_runtime_global_setting(params)
    if (not params or not type(params) == "table") then return end
    if (not params.setting or type(params.setting) ~= "string") then return end

    if (not storage_runtime_settings) then
        storage.settings_map = storage.settings_map or {}
        storage.settings_map.runtime_global = storage.settings_map.runtime_global or {}
        storage_runtime_settings = storage.settings_map.runtime_global
    end

    local setting = storage_runtime_settings and storage_runtime_settings[params.setting]

    if (setting == nil or params.reindex) then
        setting = settings_runtime[params.setting] and settings_runtime[params.setting].value or nil
    end

    if (storage_runtime_settings) then storage_runtime_settings[params.setting] = setting end

    return setting
end

function settings_service.get_startup_setting(params)

    if (not params or not type(params) == "table") then return end
    if (not params.setting or type(params.setting) ~= "string") then return end

    if (not storage_runtime_settings) then
        storage.settings_map = storage.settings_map or {}
        storage.settings_map.startup = storage.settings_map.startup or {}
        storage_runtime_settings = storage.settings_map.startup
    end

    local setting = storage_startup_settings and storage_startup_settings[params.setting]

    if (setting == nil or params.reindex) then
        setting = settings_startup[params.setting] and settings_startup[params.setting].value or nil
    end

    if (storage_startup_settings) then storage_startup_settings[params.setting] = setting end

    return setting
end

function locals.get_startup_setting(params)
    if (not params or not params.default or not params.name) then return end
    local setting = params.default
    local name = params.name

    if (storage_startup_settings and not storage_startup_settings[name] and settings_startup[name or ""]) then
        setting = settings_startup[name].value
        storage_runtime_settings[name] = setting
    else
        setting = storage_startup_settings and storage_startup_settings[name] or settings_startup[name] and settings_startup[name].value or params.default
    end

    return setting
end

function locals.get_runtime_setting(params)
    if (not params or not params.default or not params.name) then return end
    local setting = params.default
    local name = params.name

    if (storage_runtime_settings and settings_runtime[name] and (params.reindex or not storage_runtime_settings[name])) then
        setting = settings_runtime[name].value
        storage_runtime_settings[name] = setting
    else
        setting = storage_runtime_settings and storage_runtime_settings[name] or settings_runtime[name] and settings_runtime[name].value or params.default
    end

    return setting
end

function settings_service.init(__storage)
    storage = __storage or _ENV.storage

    if (storage and storage.settings_map) then
        if (storage.settings_map.startup) then storage_startup_settings = storage.settings_map.startup end
        if (storage.settings_map.runtime_global) then storage_runtime_settings = storage.settings_map.runtime_global end
    end
end

return settings_service