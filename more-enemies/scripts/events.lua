local pairs = pairs
local ipairs = ipairs

--[[ Globals ]]
Util = require("__core__.lualib.util")
Deepcopy = Util.table.deepcopy
local deepcopy = Deepcopy

Did_Init = false

Constants = require("scripts.constants.constants")

Data_Utils = require("__TheEckelmonster-core-library__.libs.utils.data-utils")
Settings_Service = require("__TheEckelmonster-core-library__.scripts.services.settings-serivce")

Mod_Settings = require("scripts.constants.settings.mod-settings")
local Mod_Settings = Mod_Settings

Filters = {}
Forces = {
    ["player"] = 1,
    ["neutral"] = 1,
}

Valid_Surfaces = {}

for _, planet in pairs(Constants.DEFAULTS.planets) do
    Valid_Surfaces[planet.string_val] = planet.string_val
end

Valid_Sources = {
    ["spawned"] = "spawned",
    ["group"] = "group",
    ["built"] = "built",
}

Clone_Unit_Setting = {}
Clone_Unit_Group_Setting = {}
Max_Num_Unit_Clones = {}
Max_Num_Unit_Group_Clones = {}
Max_Num_Modded_Clones = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name, }) or 500

for _, planet in pairs(Constants.DEFAULTS.planets) do
    Clone_Unit_Setting[planet.string_val] = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings["CLONE_" .. planet.string_val:upper() .. "_UNITS"].name, }) or 1
    Clone_Unit_Group_Setting[planet.string_val] = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings["CLONE_" .. planet.string_val:upper() .. "_UNIT_GROUPS"].name, }) or 1
    Max_Num_Unit_Clones[planet.string_val] = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_SPAWNED_CLONES_" .. planet.string_val:upper()].name, }) or 1
    Max_Num_Unit_Group_Clones[planet.string_val] = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_" .. planet.string_val:upper()].name, }) or 1
end

Limits = {
    ["spawned"] = Max_Num_Unit_Clones,
    ["group"] = Max_Num_Unit_Group_Clones,
    ["built"] = Max_Num_Modded_Clones,
}

function Set_Num_Clones()
    storage.num_clones = storage.num_clones or {}

    for k, _ in pairs(Limits) do
        storage.num_clones[k] = storage.num_clones[k] or {}
        for _, planet in pairs(Constants.DEFAULTS.planets) do
            storage.num_clones[k][planet.string_val] = storage.num_clones[k][planet.string_val] or 0
        end
    end

    return storage.num_clones
end

local on_entity_died_filter = {}
local script_raised_built_filter = {}

local Spawn_Constants = require("libs.constants.spawn-constants")

for _, v in pairs(Spawn_Constants.name) do
    table.insert(script_raised_built_filter, { filter = "name", name = v, })
    on_entity_died_filter[v] = 1
end

Filters.on_entity_died = on_entity_died_filter
Filters.script_raised_built = script_raised_built_filter

---

local Event_Handler = Event_Handler

local Initialization = require("scripts.initialization")
local Custom_Events = require("prototypes.custom-events.custom-events")
local Chunk_Controller = require("scripts.controller.chunk-controller")
local Entity_Controller = require("scripts.controller.entity-controller")
local Planet_Controller = require("scripts.controller.planet-controller")
local Spawn_Controller = require("scripts.controller.spawn-controller")
Spawn_Controller.Entity_Controller = Entity_Controller
local Unit_Group_Controller = require("scripts.controller.unit-group-controller")

local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")
local Settings_Controller = require("__TheEckelmonster-core-library__.scripts.controllers.settings-controller")

--
-- Register events

local to_init_storage = {
    Chunk_Controller,
    Entity_Controller,
    Planet_Controller,
    Spawn_Controller,
    Unit_Group_Controller,
    -- Settings_Controller,
    require("scripts.service.attack-group-service"),
    require("scripts.service.planet-service"),
    require("scripts.service.settings-service"),
    require("scripts.service.spawn-service"),
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
Event_Handler:register_event({
    event_name = Custom_Events.me_on_init_complete.name,
    source_name = "to_init_storage.reinit_all",
    func_name = "to_init_storage.reinit_all",
    func = to_init_storage.reinit_all,
})

local to_set_game = {
    Entity_Controller,
    Spawn_Controller,
    require("scripts.service.attack-group-service"),
    require("scripts.service.planet-service"),
    require("scripts.service.spawn-service"),
    require("scripts.service.unit-group-service"),
    require("scripts.utils.attack-group-utils"),
    require("scripts.utils.spawn-utils"),
}

function to_set_game.set_game_all(event)
    for _, v in ipairs(to_set_game) do
        v.set_game()
    end
end
Event_Handler:register_event({
    event_name = Custom_Events.me_on_init_complete.name,
    source_name = "to_set_game.set_game_all",
    func_name = "to_set_game.set_game_all",
    func = to_set_game.set_game_all,
})

local globals = {}
globals.set_num_clones = Set_Num_Clones
Event_Handler:register_event({
    event_name = Custom_Events.me_on_init_complete.name,
    source_name = "globals.set_num_clones",
    func_name = "globals.set_num_clones",
    func = globals.set_num_clones,
})

---

local events = {
    [Chunk_Controller.name] = Chunk_Controller,
    [Entity_Controller.name] = Entity_Controller,
    [Planet_Controller.name] = Planet_Controller,
    [Spawn_Controller.name] = Spawn_Controller,
    [Unit_Group_Controller.name] = Unit_Group_Controller,
    [Settings_Controller.name] = Settings_Controller,
}

Init = false
function events.on_init()
    Init = true
    if (type(storage) ~= "table") then return end

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
    if (type(storage.handles) == "table") then
        local return_val = false
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

local settings_service = require("scripts.service.settings-service")
local get_difficulty = settings_service.get_difficulty
function events.on_configuration_changed(event)
    Configuration_Changed = true
    if (event.mod_startup_settings_changed) then
        storage.difficulties = storage.difficulties or {}

        for surface_name, _ in pairs(Constants.DEFAULTS.planets or {}) do
            storage.difficulties[surface_name] = deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])
        end
    end

    if (event.mod_changes) then
        --[[ Check if our mod updated ]]
        if (event.mod_changes[Constants.mod_name]) then
            if (not Did_Init) then
                game.print({ Constants.mod_name .. ".on-configuration-changed", Constants.mod_name })

                if (type(storage.handles) ~= "table" or not initialized_from_load) then
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
                    v.init(storage)
                end
            end
        end
    end
    Configuration_Changed = false
end
Event_Handler:register_event({
    event_name = "on_configuration_changed",
    source_name = "events.on_configuration_changed",
    func_name = "events.on_configuration_changed",
    func = events.on_configuration_changed,
})