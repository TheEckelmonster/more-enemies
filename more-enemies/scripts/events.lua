--[[ Globals ]]
Did_Init = false

Constants = require("scripts.constants.constants")

Data_Utils = require("__TheEckelmonster-core-library__.libs.utils.data-utils")
Settings_Service = require("__TheEckelmonster-core-library__.scripts.services.settings-serivce")

Mod_Settings = require("scripts.constants.settings.mod-settings")

-- Startup_Settings_Constants = require("settings.startup.startup-settings-constants")
-- Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

Filters = {}

local on_entity_damaged_filter = {}
local on_entity_died_filter = {}
local script_raised_built_filter = {}

local Spawn_Constants = require("libs.constants.spawn-constants")
-- local Spawn_Constants = { filter = require("libs.constants.spawn-constants"), }

-- for _, v in pairs(Spawn_Constants.filter) do table.insert(on_entity_died_filter, v) end
for _, v in pairs(Spawn_Constants.name) do
    table.insert(script_raised_built_filter, { filter = "name", name = v, })
    table.insert(on_entity_died_filter, { filter = "name", name = v, })
end

table.insert(on_entity_died_filter, { filter = "name", name = "biter-spawner"})
table.insert(on_entity_died_filter, { filter = "name", name = "spitter-spawner"})

if (script and script.active_mods and script.active_mods["space-age"]) then
    table.insert(on_entity_died_filter, { filter = "name", name = "gleba-spawner-small"})
    table.insert(on_entity_died_filter, { filter = "name", name = "gleba-spawner"})
end

-- table.insert(on_entity_damaged_filter, { filter = "name", name = "biter-spawner"})
-- table.insert(on_entity_damaged_filter, { filter = "name", name = "spitter-spawner"})

-- if (script and script.active_mods and script.active_mods["space-age"]) then
--     table.insert(on_entity_damaged_filter, { filter = "name", name = "gleba-spawner-small"})
--     table.insert(on_entity_damaged_filter, { filter = "name", name = "gleba-spawner"})
-- end

-- Filters.on_entity_damaged = on_entity_damaged_filter
Filters.on_entity_died = on_entity_died_filter
Filters.script_raised_built = script_raised_built_filter

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


local to_init = {
    Planet_Controller,
    Mod_Settings_Controller,
    Spawn_Controller,
    Unit_Group_Controller,
    -- Settings_Controller,
    require("scripts.repositories.attack-group-repository"),
    require("scripts.repositories.mod-repository"),
    require("scripts.repositories.more-enemies-repository"),
    require("scripts.repositories.nth-tick-repository"),
    require("scripts.repositories.version-repository"),
    -- require("scripts.service.attack-group-service"),
    require("scripts.service.planet-service"),
    -- require("scripts.service.settings-service"),
    require("scripts.service.spawn-service"),
    require("scripts.service.unit-group-service"),
    require("scripts.service.version-service"),
    require("scripts.utils.attack-group-utils"),
    require("scripts.utils.difficulty-utils"),
    require("scripts.utils.settings-utils"),
    require("scripts.utils.spawn-utils"),
    require("scripts.utils.unit-group-utils"),
}

--
-- Register events

local events = {
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

    for _, v in ipairs(to_init) do
        v.init(storage)
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

    for _, v in ipairs(to_init) do
        v.init(storage)
    end
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

-- function events.on_tick()
--     storage.num_actions_performed = 0
--     for _, v in pairs(Constants.time.TICKS) do if (game.tick % v == 0) then Event_Data:reset({ index = v }) end end
--     Event_Data:increment()
-- end
-- Event_Handler:register_event({
--     event_name = "on_tick",
--     source_name = "events.on_tick",
--     func_name = "events.on_tick",
--     func = events.on_tick,
-- })

-- Event_Handler:set_event_position({
--     event_name = "on_tick",
--     source_name = "events.on_tick",
--     new_position = 1,
-- })

-- local event_data_events = {
--     "script_raised_built",
--     "on_script_path_request_finished",
--     "on_biter_base_built",
--     "on_build_base_arrived",
--     "on_chunk_generated",
--     "on_entity_spawned",
--     "on_entity_damaged",
--     "on_entity_died",
--     "on_unit_group_created",
--     "on_unit_group_finished_gathering",
--     "on_surface_created",
--     "on_built_entity",
--     "on_cargo_pod_finished_descending",
--     "on_player_mined_entity",
--     "on_player_mined_item",
--     "on_post_entity_died",
--     "on_robot_built_entity",
--     "on_robot_exploded_cliff",
--     "on_robot_mined_entity",
--     "on_rocket_launch_ordered",
-- }

-- function events.increment_event_data(event)
--     Event_Data:increment()
-- end

-- for k, v in pairs(event_data_events) do
--     -- log(serpent.block(v))
--     -- log(serpent.block(Filters[v]))

--     Event_Handler:register_event({
--         event_name = v,
--         filter = Filters[v],
--         source_name = "events.increment_event_data." .. v,
--         func_name = "events.increment_event_data",
--         func = events.increment_event_data,
--     })

--     Event_Handler:set_event_position({
--         event_name = v,
--         source_name = "events.increment_event_data." .. v,
--         new_position = 1,
--     })
-- end