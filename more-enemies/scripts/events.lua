local pairs = pairs
local ipairs = ipairs

--[[ Globals ]]
Util = require("__core__.lualib.util")
Deepcopy = Util.table.deepcopy
local deepcopy = Deepcopy

Did_Init = false

Constants = require("scripts.constants.constants")
Custom_Events = require("prototypes.custom-events.custom-events")
Startup_Settings_Constants = require("settings.startup.startup-settings-constants")
Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

Data_Utils = require("__TheEckelmonster-core-library__.libs.utils.data-utils")
_Settings_Service = require("__TheEckelmonster-core-library__.scripts.services.settings-serivce")
Settings_Service = require("scripts.service.settings-service")

local FUNCTION = Types.FUNCTION
local TABLE = Types.TABLE
local STRING = Types.STRING

local EMPTY = EMPTY
local ESCAPED_DASH = ESCAPED_DASH
local NEUTRAL = NEUTRAL
local PLAYER = PLAYER
local UNDERSCORE = UNDERSCORE


local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants

local prototypes = prototypes
local mod_data = prototypes.mod_data
local clonable_units = mod_data[Constants.mod_name .. "-clonable-unit-data"]
local planets = mod_data[Constants.mod_name .. "-planet-data"]

Clonable_Units = clonable_units.data

Planets = {}

Filters = {}
Forces = {
    [PLAYER] = 1,
    [NEUTRAL] = 1,
}

Valid_Surfaces = {}

Valid_Sources = {
    [SPAWNED] = SPAWNED,
    [GROUP] = GROUP,
    [BUILT] = BUILT,
}


local string_find = string.find

Clone_Unit_Setting = {}
Clone_Unit_Group_Setting = {}
Max_Num_Unit_Clones = {}
Max_Num_Unit_Group_Clones = {}
Max_Num_Modded_Clones = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name, }) or 500

Limits = {}

for planet, _ in pairs(planets.data or { [NAUVIS] = true, }) do
    Planets[#Planets+1] = planet
    Valid_Surfaces[planet] = planet

    local idx = planet:gsub(ESCAPED_DASH, UNDERSCORE):upper()
    Clone_Unit_Setting[planet] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_CLONE_UNITS"] or {}).name, })
    Clone_Unit_Group_Setting[planet] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_CLONE_UNIT_GROUPS"] or {}).name, })
    for unit, _ in pairs(Clonable_Units) do
        local idx = (planet .. "_" .. (unit:match("[a-z]+%-(.*)") or "")):gsub(ESCAPED_DASH, UNDERSCORE):upper() or EMPTY
        Max_Num_Unit_Clones[planet] = Max_Num_Unit_Clones[planet] or {}
        if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"]) then
            Max_Num_Unit_Clones[planet][unit] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"] or {}).name, })
        end
        Max_Num_Unit_Clones[planet].fallback = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings["FALLBACK_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"] or {}).name, })
        Max_Num_Unit_Group_Clones[planet] = Max_Num_Unit_Group_Clones[planet] or {}
        if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"]) then
            Max_Num_Unit_Group_Clones[planet][unit] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name, })
        end
        Max_Num_Unit_Group_Clones[planet].fallback = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings["FALLBACK_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name, })
    end
end

local Settings_Service = Settings_Service
local get_runtime_global_setting = Settings_Service.get_runtime_global_setting
local get_startup_setting = Settings_Service.get_startup_setting

local settings_registry = { registry = {}, }
Settings_Registry = settings_registry
function Settings_Registry:register_setting(params)
    if (not params) then return end
    if (type(params.func_name) ~= STRING) then return end
    if (type(params.func) ~= FUNCTION) then return end

    if (not self or not Settings_Registry) then
        self = self or {}
        Settings_Registry = self
    end
    self.registry = self.registry or {}
    self.registry[#self.registry+1] = { func_name = params.func_name, func = params.func, }
end

for _, planet in ipairs(Planets or { NAUVIS, }) do
    for unit, _ in pairs(Clonable_Units) do
        local idx = (planet .. "_" .. (unit:match("[a-z]+%-(.*)") or "")):gsub(ESCAPED_DASH, UNDERSCORE):upper() or EMPTY
        if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"]) then
            Max_Num_Unit_Clones[planet] = Max_Num_Unit_Clones[planet] or {}
            Max_Num_Unit_Clones[planet][unit] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"] or {}).name, })
        end
        if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"]) then
            Max_Num_Unit_Group_Clones[planet] = Max_Num_Unit_Group_Clones[planet] or {}
            Max_Num_Unit_Group_Clones[planet][unit] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name, })
        end
    end
end

function Get_Clone_Settings()
    storage.limits = storage.limits or {}
    Limits = storage.limits
    Limits[SPAWNED] = Max_Num_Unit_Clones
    Limits[GROUP] = Max_Num_Unit_Group_Clones
    Limits[BUILT] = Max_Num_Modded_Clones

    for _, planet in ipairs(Planets or { NAUVIS, }) do
        for unit, _ in pairs(Clonable_Units) do
            local idx = (planet .. "_" .. (unit:match("[a-z]+%-(.*)") or "")):gsub(ESCAPED_DASH, UNDERSCORE):upper() or EMPTY
            if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"]) then
                Max_Num_Unit_Clones[planet] = Max_Num_Unit_Clones[planet] or {}
                Max_Num_Unit_Clones[planet][unit] = get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"] or {}).name, reindex = true, })
            end
            if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"]) then
                Max_Num_Unit_Group_Clones[planet] = Max_Num_Unit_Group_Clones[planet] or {}
                Max_Num_Unit_Group_Clones[planet][unit] = get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name, reindex = true, })
            end
        end
        Max_Num_Unit_Clones[planet].fallback = get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings["FALLBACK_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"] or {}).name, reindex = true, })
        Max_Num_Unit_Group_Clones[planet].fallback = get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings["FALLBACK_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name, reindex = true, })
    end

    return Limits
end

function Set_Num_Clones()
    storage.num_clones = storage.num_clones or {}

    Get_Clone_Settings()

    for k, _ in pairs(Limits) do
        storage.num_clones[k] = type(storage.num_clones[k]) == TABLE and storage.num_clones[k] or {}
        for planet, _ in pairs(planets.data or {}) do
            storage.num_clones[k][planet] = type(storage.num_clones[k][planet]) == TABLE and storage.num_clones[k][planet] or {}
            for u, _ in pairs(clonable_units.data) do
                storage.num_clones[k][planet][u] = storage.num_clones[k][planet][u] or 0
            end
            storage.num_clones[k][planet].fallback = storage.num_clones[k][planet].fallback or 0
        end
    end

    return storage.num_clones
end

local script_raised_built_filter = {}

Filters.on_entity_died = require("scripts.filters.on-entity-died-filter")
Filters.script_raised_built = script_raised_built_filter

SHIFT_LOOKUP = {}
for lvls = 0, Constants.CHUNK_LEVELS, 1 do
    SHIFT_LOOKUP[lvls] = 2 ^ (Constants.CHUNK_LEVELS - lvls)
end

require("scripts.to-set-game")

---

local Custom_Events = Custom_Events
local Event_Handler = Event_Handler

local Initialization = require("scripts.initialization")
local Chunk_Controller = require("scripts.controller.chunk-controller")
local Entity_Controller = require("scripts.controller.entity-controller")
local Planet_Controller = require("scripts.controller.planet-controller")
local Spawn_Controller = require("scripts.controller.spawn-controller")
local Unit_Group_Controller = require("scripts.controller.unit-group-controller")

local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")
local Settings_Controller = require("__TheEckelmonster-core-library__.scripts.controllers.settings-controller")

--
-- Register events

local events = {
    [Chunk_Controller.name] = Chunk_Controller,
    [Entity_Controller.name] = Entity_Controller,
    [Planet_Controller.name] = Planet_Controller,
    [Spawn_Controller.name] = Spawn_Controller,
    [Unit_Group_Controller.name] = Unit_Group_Controller,
    [Settings_Controller.name] = Settings_Controller,
}

---

local to_init_storage = {
    Chunk_Controller,
    Entity_Controller,
    Planet_Controller,
    Spawn_Controller,
    Unit_Group_Controller,
    Settings_Service,

    require("scripts.data.leaf-data"),
    require("scripts.data.quadnode"),
    require("scripts.service.attack-group-service"),
    require("scripts.service.planet-service"),
    require("scripts.service.settings-service"),
    require("scripts.service.spawn-service"),
    require("scripts.service.quadtree-service"),
    require("scripts.service.unit-group-service"),
    require("scripts.utils.attack-group-utils"),
    require("scripts.utils.difficulty-utils"),
    require("scripts.utils.settings-utils"),
    require("scripts.utils.spawn-utils"),
}

function to_init_storage.reinit_all(event)
    for _, v in ipairs(to_init_storage) do
        v.init(storage)
    end
end
Event_Handler:register_events({
    {
        event_name = Custom_Events.me_on_init_complete.name,
        source_name = "to_init_storage.reinit_all",
        func_name = "to_init_storage.reinit_all",
        func = to_init_storage.reinit_all,
    },
    {
        event_name = Custom_Events.me_migrations_applied.name,
        source_name = "to_init_storage.reinit_all",
        func_name = "to_init_storage.reinit_all",
        func = to_init_storage.reinit_all,
    },
    {
        event_name = "on_configuration_changed",
        source_name = "to_init_storage.on_configuration_changed",
        func_name = "to_init_storage.on_configuration_changed",
        func = to_init_storage.reinit_all,
    }
})

local globals = {}
globals.set_num_clones = Set_Num_Clones
Event_Handler:register_events({
    {
        event_name = Custom_Events.me_on_init_complete.name,
        source_name = "globals.set_num_clones",
        func_name = "globals.set_num_clones",
        func = globals.set_num_clones,
    },
    {
        event_name = "on_configuration_changed",
        source_name = "globals.set_num_clones",
        func_name = "globals.set_num_clones",
        func = globals.set_num_clones,
    }
})

---

Init = false
function events.on_init()
    Init = true
    if (type(storage) ~= TABLE) then return end

    storage.handles = {
        log_handle = {},
        setting_handle = {},
    }

    Settings_Service.init({ storage_ref = storage.handles.setting_handle })
    Settings_Controller.init({ settings_service = Settings_Service })

    local log_settings = Log_Settings.create({ prefix = Constants.mod_name })

    Log.init({
        storage_ref = storage.handles.log_handle,
        debug_level_name = log_settings[1].name,
        traceback_setting_name = log_settings[2].name,
        do_not_print_setting_name = log_settings[3].name,
    })
    Log.ready()

    Initialization.init({ maintain_data = false })

    for _, v in ipairs(to_init_storage) do
        v.init(storage)
    end

    Did_Init = true
    Init = false
end
Event_Handler:register_event({
    event_name = "on_init",
    source_name = "events.on_init",
    func_name = "events.on_init",
    func = events.on_init,
})

local initialized_from_load = false

Load = false
function events.on_load()
    Load = true
    if (type(storage.handles) == TABLE) then
        local return_val = nil
        initialized_from_load = true
        return_val = initialized_from_load and Settings_Service.init({ storage_ref = storage.handles.setting_handle })
        if (not return_val) then initialized_from_load = false end
        return_val = initialized_from_load and Settings_Controller.init({ settings_service = Settings_Service })
        if (not return_val) then initialized_from_load = false end

        local log_settings = Log_Settings.create({ prefix = Constants.mod_name })

        return_val = initialized_from_load and Log.init({
            storage_ref = storage.handles.log_handle,
            debug_level_name = log_settings[1].name,
            traceback_setting_name = log_settings[2].name,
            do_not_print_setting_name = log_settings[3].name,
        })
        if (not return_val) then initialized_from_load = false end

        if (initialized_from_load) then Log.ready() end
    end

    Event_Handler:on_load_restore({ events = events })

    for _, v in ipairs(to_init_storage) do
        v.init(storage)
    end
    Load = false
end
Event_Handler:register_event({
    event_name = "on_load",
    source_name = "events.on_load",
    func_name = "events.on_load",
    func = events.on_load,
})

Configuration_Changed = false

function events.on_configuration_changed(event)
    Configuration_Changed = true
    if (event.mod_startup_settings_changed) then
        storage.difficulties = storage.difficulties or {}

        for _, surface_name in ipairs(Planets or {}) do
            storage.difficulties[surface_name] = deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])
        end
    end

    if (event.mod_changes) then
        --[[ Check if our mod updated ]]
        if (event.mod_changes[Constants.mod_name]) then
            if (not Did_Init) then
                game.print({ Constants.mod_name .. ".on-configuration-changed", Constants.mod_name })

                if (type(storage.handles) ~= TABLE or not initialized_from_load) then
                    storage.handles = {
                        log_handle = {},
                        setting_handle = {},
                    }

                    Settings_Service.init({ storage_ref = storage.handles.setting_handle })
                    Settings_Controller.init({ settings_service = Settings_Service })

                    local log_settings = Log_Settings.create({ prefix = Constants.mod_name })

                    Log.init({
                        storage_ref = storage.handles.log_handle,
                        debug_level_name = log_settings[1].name,
                        traceback_setting_name = log_settings[2].name,
                        do_not_print_setting_name = log_settings[3].name,
                    })

                    Log.ready()
                end

                Initialization.init({ maintain_data = true })

                for _, v in ipairs(to_init_storage) do
                    v.init(_ENV.storage)
                end
            end
        end
    end

    storage.settings_map = storage.settings_map or {}
    storage.settings_map.runtime_global = storage.settings_map.runtime_global or {}
    Settings_Map = storage.settings_map
    for _, setting_tbl in pairs(Runtime_Global_Settings_Constants.settings or {}) do
        Settings_Map.runtime_global[setting_tbl.name] = get_runtime_global_setting({ setting = setting_tbl.name, }) or setting_tbl.default_value
    end

    Configuration_Changed = false
end
Event_Handler:register_event({
    event_name = "on_configuration_changed",
    source_name = "events.on_configuration_changed",
    func_name = "events.on_configuration_changed",
    func = events.on_configuration_changed,
})

local string_match = string.match
local string_gsub = string.gsub
local string_upper = string.upper
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "settings_map.on_runtime_mod_setting_changed",
    func_name = "settings_map.on_runtime_mod_setting_changed",
    func = function (event)
        if (not event or not event.setting or not string_find(event.setting, ME_PREFIX_ESCAPED)) then return end
        local trimmed = string_match(event.setting, ME_PREFIX_ESCAPED .. "(.*)")
        local subbed_to_upper = string_upper(string_gsub(trimmed, "%-", "_"))

        storage.settings_map = storage.settings_map or {}
        Settings_Map = storage.settings_map

        local setting_value = nil
        local setting = nil
        local planet = nil
        if (Runtime_Global_Settings_Constants.settings[subbed_to_upper]) then
            Settings_Map.runtime_global = Settings_Map.runtime_global or {}
            planet = Runtime_Global_Settings_Constants.settings[subbed_to_upper].planet
            Settings_Map.runtime_global[event.setting] = get_runtime_global_setting({ setting = event.setting, reindex = true, })
            setting_value = Settings_Map.runtime_global[event.setting]
            setting = Runtime_Global_Settings_Constants.settings[subbed_to_upper]
        elseif (Startup_Settings_Constants.settings[subbed_to_upper]) then
            Settings_Map.startup = Settings_Map.startup or {}
            planet = Startup_Settings_Constants.settings[subbed_to_upper].planet
            Settings_Map.startup[event.setting] = get_startup_setting({ setting = event.setting, reindex = true, })
            setting_value = Settings_Map.startup[event.setting]
            setting = Startup_Settings_Constants.settings[subbed_to_upper]
        end

        for _, registered in ipairs(Settings_Registry.registry or {}) do
            if (registered.func and type(registered.func) == FUNCTION) then registered.func(event, { setting_constant = setting, setting_value = setting_value, surface_name = planet, }) end
        end
    end,
})

Event_Handler:set_event_position({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "settings_map.on_runtime_mod_setting_changed",
    new_position = 1,
})