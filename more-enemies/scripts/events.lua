--[[ Globals ]]
Did_Init = false

Constants = require("scripts.constants.constants")

Data_Utils = require("__TheEckelmonster-core-library__.libs.utils.data-utils")
Settings_Service = require("__TheEckelmonster-core-library__.scripts.services.settings-serivce")

-- Startup_Settings_Constants = require("settings.startup.startup-settings-constants")
-- Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

Filters = {}

local on_entity_damaged_filter = {}
local on_entity_died_filter = {}

local Spawn_Constants = require("libs.constants.spawn-constants")
local Overmind_Target_Priorities = require("libs.constants.overmind.overmind-target-priorities")

for _, v in pairs(Spawn_Constants.filter) do table.insert(on_entity_died_filter, v) end

for _, v in pairs(Overmind_Target_Priorities.overmind_taget_priorities_filter) do
    table.insert(on_entity_died_filter, v)
    -- table.insert(on_entity_damaged_filter, v)
end

table.insert(on_entity_died_filter, { filter = "name", name = "biter-spawner"})
table.insert(on_entity_died_filter, { filter = "name", name = "spitter-spawner"})

if (script and script.active_mods and script.active_mods["space-age"]) then
    table.insert(on_entity_died_filter, { filter = "name", name = "gleba-spawner-small"})
    table.insert(on_entity_died_filter, { filter = "name", name = "gleba-spawner"})
end

table.insert(on_entity_damaged_filter, { filter = "name", name = "biter-spawner"})
table.insert(on_entity_damaged_filter, { filter = "name", name = "spitter-spawner"})

if (script and script.active_mods and script.active_mods["space-age"]) then
    table.insert(on_entity_damaged_filter, { filter = "name", name = "gleba-spawner-small"})
    table.insert(on_entity_damaged_filter, { filter = "name", name = "gleba-spawner"})
end

Filters.on_entity_damaged = on_entity_damaged_filter
Filters.on_entity_died = on_entity_died_filter
Filters.script_raised_built = Spawn_Constants.filter

---

-- local Cache_Data = require("scripts.data.cache-data")
-- Cache_Data = require("scripts.data.cache-data")
-- local Constants = require("libs.constants.constants")
-- local Data = require("scripts.data.data")
-- local Event_Data = require("scripts.data.event-data")
Event_Data = require("scripts.data.event-data")
local Initialization = require("scripts.initialization")
-- local Log = require("libs.log.log")
local Mod_Settings_Controller = require("scripts.controller.mod-settings-controller")
local Overmind_Controller = require("scripts.controller.overmind-controller")
-- local Overmind_Target_Priorities = require("libs.constants.overmind.overmind-target-priorities")
local Planet_Controller = require("scripts.controller.planet-controller")
-- local Queue_Data = require("scripts.data.structures.queue-data")
-- local Spawn_Constants = require("libs.constants.spawn-constants")
local Spawn_Controller = require("scripts.controller.spawn-controller")
local Unit_Group_Controller = require("scripts.controller.unit-group-controller")

local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")
local Settings_Controller = require("__TheEckelmonster-core-library__.scripts.controllers.settings-controller")

-- local on_entity_damaged_filter = {}
-- local on_entity_died_filter = {}

-- for _, v in pairs(Spawn_Constants.filter) do
--     table.insert(on_entity_died_filter, v)
-- end

-- for _, v in pairs(Overmind_Target_Priorities.overmind_taget_priorities_filter) do
--     table.insert(on_entity_died_filter, v)
--     -- table.insert(on_entity_damaged_filter, v)
-- end

-- table.insert(on_entity_died_filter, { filter = "name", name = "biter-spawner"})
-- table.insert(on_entity_died_filter, { filter = "name", name = "spitter-spawner"})

-- if ((mods and mods["space-age"]) or (script and script.active_mods and script.active_mods["space-age"])) then
--     table.insert(on_entity_died_filter, { filter = "name", name = "gleba-spawner-small"})
--     table.insert(on_entity_died_filter, { filter = "name", name = "gleba-spawner"})
-- end

-- table.insert(on_entity_damaged_filter, { filter = "name", name = "biter-spawner"})
-- table.insert(on_entity_damaged_filter, { filter = "name", name = "spitter-spawner"})

-- if ((mods and mods["space-age"]) or (script and script.active_mods and script.active_mods["space-age"])) then
--     table.insert(on_entity_damaged_filter, { filter = "name", name = "gleba-spawner-small"})
--     table.insert(on_entity_damaged_filter, { filter = "name", name = "gleba-spawner"})
-- end

-- log(serpent.block(on_entity_damaged_filter))
-- log(serpent.block(on_entity_died_filter))

-- script.register_metatable("Cache_Data", Cache_Data.mt)
-- script.register_metatable("Data", Data)
-- script.register_metatable("Event_Data", Event_Data.mt)
-- script.register_metatable("Queue_Data", Queue_Data)

--
-- Register events

local events = {
    [Overmind_Controller.name] = Overmind_Controller,
    [Planet_Controller.name] = Planet_Controller,
    [Mod_Settings_Controller.name] = Mod_Settings_Controller,
    [Spawn_Controller.name] = Spawn_Controller,
    [Unit_Group_Controller.name] = Unit_Group_Controller,
    [Settings_Controller.name] = Settings_Controller,
}

function events.on_init()
    if (type(storage) ~= "table") then return end

    local return_val = 0

    storage.handles = {
        log_handle = {},
        setting_handle = {},
    }

    return_val = Settings_Service.init({ storage_ref = storage.handles.setting_handle })
    return_val = Settings_Controller.init({ settings_service = Settings_Service })

    local log_settings = Log_Settings.create({ prefix = Constants.mod_name })

    return_val = Log.init({
        storage_ref = storage.handles.log_handle,
        debug_level_name = log_settings[1].name,
        traceback_setting_name = log_settings[2].name,
        do_not_print_setting_name = log_settings[3].name,
    })
    Log.ready()

    Initialization.init({ maintain_data = false })

    Random = storage.random

    S_Cache = storage.cache
    S_Cache_Attributes = storage.cache_attributes
    if (S_Cache_Attributes) then
        setmetatable(S_Cache_Attributes, { __mode = "k" })
    end

    Did_Init = true
end
Event_Handler:register_event({
    event_name = "on_init",
    source_name = "events.on_init",
    func_name = "events.on_init",
    func = events.on_init,
})

local initialized_from_load = false

function events.on_load()
    Random = storage.random

    S_Cache = storage.cache
    S_Cache_Attributes = storage.cache_attributes
    if (S_Cache_Attributes) then
        setmetatable(S_Cache_Attributes, { __mode = "k" })
    end

    local return_val = 0

    if (type(storage.handles) == "table") then
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
end
Event_Handler:register_event({
    event_name = "on_load",
    source_name = "events.on_load",
    func_name = "events.on_load",
    func = events.on_load,
})

function events.on_configuration_changed(event)
    local sa_active = script and script.active_mods and script.active_mods["space-age"]
    local se_active = script and script.active_mods and script.active_mods["space-exploration"]

    storage.sa_active = sa_active
    storage.se_active = se_active

    if (event.mod_changes) then
        --[[ Check if our mod updated ]]
        -- if (event.mod_changes["more-enemies"]) then
        if (event.mod_changes[Constants.mod_name]) then
            if (not Did_Init) then
                game.print({ Constants.mod_name .. ".on-configuration-changed", Constants.mod_name })

                if (type(storage.handles) ~= "table" or not initialized_from_load) then
                    storage.handles = {
                        log_handle = {},
                        setting_handle = {},
                    }

                    local return_val = 0
                    return_val = Settings_Service.init({ storage_ref = storage.handles.setting_handle })
                    return_val = Settings_Controller.init({ settings_service = Settings_Service })

                    local log_settings = Log_Settings.create({ prefix = Constants.mod_name })

                    return_val = Log.init({
                        storage_ref = storage.handles.log_handle,
                        debug_level_name = log_settings[1].name,
                        traceback_setting_name = log_settings[2].name,
                        do_not_print_setting_name = log_settings[3].name,
                    })

                    Log.ready()
                end

                Initialization.init({ maintain_data = true })

                Random = storage.random

                S_Cache = storage.cache
                S_Cache_Attributes = storage.cache_attributes
                if (S_Cache_Attributes) then
                    setmetatable(S_Cache_Attributes, { __mode = "k" })
                end
            end
        end
    end
end
Event_Handler:register_event({
    event_name = "on_configuration_changed",
    source_name = "events.on_configuration_changed",
    func_name = "events.on_configuration_changed",
    func = events.on_configuration_changed,
})

-- script.on_event(defines.events.on_tick, function (event)
--     -- if (storage.num_actions_performed == nil) then storage.num_actions_performed = 0 end
--     storage.num_actions_performed = 0
--     -- local _event_data = Event_Data:get()
--     Event_Data:increment()
--     Spawn_Controller.do_tick(event)
--     -- Event_Data:increment()

--     Overmind_Controller.do_tick(event)

--     for _, v in pairs(Constants.time.TICKS) do if (game.tick % v == 0) then Event_Data:reset({ index = v }) end end
-- end)

function events.on_tick()
    storage.num_actions_performed = 0
    for _, v in pairs(Constants.time.TICKS) do if (game.tick % v == 0) then Event_Data:reset({ index = v }) end end
    Event_Data:increment()
end
Event_Handler:register_event({
    event_name = "on_tick",
    source_name = "events.on_tick",
    func_name = "events.on_tick",
    func = events.on_tick,
})

Event_Handler:set_event_position({
    event_name = "on_tick",
    source_name = "events.on_tick",
    new_position = 1,
})

local event_data_events = {
    "script_raised_built",
    "on_script_path_request_finished",
    "on_biter_base_built",
    "on_build_base_arrived",
    "on_chunk_generated",
    "on_entity_spawned",
    "on_entity_damaged",
    "on_entity_died",
    "on_unit_group_created",
    "on_unit_group_finished_gathering",
    "on_surface_created",
    "on_built_entity",
    "on_cargo_pod_finished_descending",
    "on_player_mined_entity",
    "on_player_mined_item",
    "on_post_entity_died",
    "on_robot_built_entity",
    "on_robot_exploded_cliff",
    "on_robot_mined_entity",
    "on_rocket_launch_ordered",
}

function events.increment_event_data(event)
    Event_Data:increment()
end

for k, v in pairs(event_data_events) do
    -- log(serpent.block(v))
    -- log(serpent.block(Filters[v]))

    Event_Handler:register_event({
        event_name = v,
        filter = Filters[v],
        source_name = "events.increment_event_data." .. v,
        func_name = "events.increment_event_data",
        func = events.increment_event_data,
    })

    Event_Handler:set_event_position({
        event_name = v,
        source_name = "events.increment_event_data." .. v,
        new_position = 1,
    })
end

-- Event_Handler:register_events({
--     {
--         event_name = "script_raised_built",
--         source_name = "Event_Data.script_raised_built",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_script_path_request_finished",
--         source_name = "Event_Data.on_script_path_request_finished",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_biter_base_built",
--         source_name = "Event_Data.on_biter_base_built",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_build_base_arrived",
--         source_name = "Event_Data.on_build_base_arrived",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_chunk_generated",
--         source_name = "Event_Data.on_chunk_generated",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_entity_spawned",
--         source_name = "Event_Data.on_entity_spawned",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_entity_damaged",
--         source_name = "Event_Data.on_entity_damaged",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_entity_died",
--         source_name = "Event_Data.on_entity_died",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_unit_group_created",
--         source_name = "Event_Data.on_unit_group_created",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_unit_group_finished_gathering",
--         source_name = "Event_Data.on_unit_group_finished_gathering",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_surface_created",
--         source_name = "Event_Data.on_surface_created",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_built_entity",
--         source_name = "Event_Data.on_built_entity",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_cargo_pod_finished_descending",
--         source_name = "Event_Data.on_cargo_pod_finished_descending",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_player_mined_entity",
--         source_name = "Event_Data.on_player_mined_entity",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_player_mined_item",
--         source_name = "Event_Data.on_player_mined_item",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_post_entity_died",
--         source_name = "Event_Data.on_post_entity_died",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_robot_built_entity",
--         source_name = "Event_Data.on_robot_built_entity",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_robot_exploded_cliff",
--         source_name = "Event_Data.on_robot_exploded_cliff",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_robot_mined_entity",
--         source_name = "Event_Data.on_robot_mined_entity",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
--     {
--         event_name = "on_rocket_launch_ordered",
--         source_name = "Event_Data.on_rocket_launch_ordered",
--         func_name = "Event_Data.increment",
--         func = Event_Data.increment,
--         func_data = Event_Data,
--     },
-- })

-- Detect entities built by other mods
--  -> Could be enemies created by other mods
-- script.on_event(defines.events.script_raised_built, function (event)
--     Event_Data:increment()
--     Spawn_Controller.entity_built(event)
-- end,
-- Spawn_Constants.filter)

-- script.on_event(defines.events.on_script_path_request_finished, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_script_path_request_finished(event)
-- end)

-- script.on_event(defines.events.on_runtime_mod_setting_changed, function (event)
--     Event_Data:increment()
--     Settings_Controller.mod_setting_changed(event)
-- end)

-- script.on_event(defines.events.on_biter_base_built, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_biter_base_built(event)
-- end)

-- script.on_event(defines.events.on_build_base_arrived, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_build_base_arrived(event)
-- end)

-- script.on_event(defines.events.on_chunk_generated, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_chunk_generated(event)
-- end)

-- script.on_event(defines.events.on_entity_spawned, function (event)
--     Event_Data:increment()
--     Spawn_Controller.entity_spawned(event)
-- end)

-- script.on_event(defines.events.on_entity_damaged, function (event)
--     Overmind_Controller.on_entity_damaged(event)
-- end,
-- on_entity_damaged_filter)

-- script.on_event(defines.events.on_entity_died, function (event)
--     Overmind_Controller.on_entity_died(event)
--     Spawn_Controller.entity_died(event)
-- end,
-- on_entity_died_filter)

-- script.on_event(defines.events.on_unit_group_created, function (event)
--     Event_Data:increment()
--     Unit_Group_Controller.unit_group_created(event)
-- end)
-- script.on_event(defines.events.on_unit_group_finished_gathering, function (event)
--     Event_Data:increment()
--     Unit_Group_Controller.unit_group_finished_gathering(event)
-- end)

-- script.on_event(defines.events.on_surface_created, function (event)
--     Event_Data:increment()
--     Planet_Controller.on_surface_created(event)
-- end)

-- script.on_event(defines.events.on_built_entity, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_built_entity(event)
-- end)

-- script.on_event(defines.events.on_cargo_pod_finished_descending, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_cargo_pod_finished_descending(event)
-- end)

-- script.on_event(defines.events.on_player_mined_entity, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_player_mined_entity(event)
-- end)

-- script.on_event(defines.events.on_player_mined_item, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_player_mined_item(event)
-- end)

-- script.on_event(defines.events.on_post_entity_died, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_post_entity_died(event)
-- end)

-- script.on_event(defines.events.on_robot_built_entity, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_robot_built_entity(event)
-- end)

-- script.on_event(defines.events.on_robot_exploded_cliff, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_robot_exploded_cliff(event)
-- end)

-- script.on_event(defines.events.on_robot_mined_entity, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_robot_mined_entity(event)
-- end)

-- script.on_event(defines.events.on_rocket_launch_ordered, function (event)
--     Event_Data:increment()
--     Overmind_Controller.on_rocket_launch_ordered(event)
--     -- local _cache_data = Cache_Data:get()
--     -- if (_cache_data) then log(serpent.block(_cache_data)) end
-- end)