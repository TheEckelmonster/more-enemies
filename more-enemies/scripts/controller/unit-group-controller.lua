local storage
local stats_data
local groups
local on_object_destroyed
local unique_ids
local unit_groups

local game

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.on_object_destroyed = storage.on_object_destroyed or {}
    on_object_destroyed = storage.on_object_destroyed

    storage.unique_ids = storage.unique_ids
    unique_ids = storage.unique_ids

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    game = __game or _ENV.game

    return game
end

local Log = require("libs.log.log")
local Unit_Group_Service = require("scripts.service.unit-group-service")

local on_unit_group_finished_gathering = Unit_Group_Service.on_unit_group_finished_gathering

local unit_group_controller = {}
unit_group_controller.name = "unit_group_controller"
unit_group_controller.set_game = set_game

function unit_group_controller.on_unit_group_finished_gathering(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)
    on_unit_group_finished_gathering(event)
end
Event_Handler:register_event({
    event_name = "on_unit_group_finished_gathering",
    source_name = "unit_group_controller.on_unit_group_finished_gathering",
    func_name = "unit_group_controller.on_unit_group_finished_gathering",
    func = unit_group_controller.on_unit_group_finished_gathering,
})

function unit_group_controller.on_object_destroyed(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    if (not event.registration_number) then return end
    on_object_destroyed = on_object_destroyed or set_game() and on_object_destroyed

    local reg_tbl = on_object_destroyed[event.registration_number]
    if (not reg_tbl) then return end
    on_object_destroyed[event.registration_number] = nil

    local surface_name = reg_tbl.surface_name

    -- log(serpent.block(event))
    -- log(serpent.block(reg_tbl))

    groups = groups or set_game() and groups
    groups[reg_tbl.unique_id] = nil

    unique_ids = unique_ids or set_game() and unique_ids
    unique_ids[reg_tbl.unique_id] = nil

    unit_groups = unit_groups or set_game() and unit_groups

    unit_groups.count = (unit_groups.count or 1) - 1
    if (unit_groups.count < 0) then unit_groups.count = 0 end

    unit_groups.surface_count = unit_groups.surface_count or {}
    unit_groups.surface_count[surface_name] = (unit_groups.surface_count[surface_name] or 1) - 1
    if (unit_groups.surface_count[surface_name] < 0) then unit_groups.surface_count[surface_name] = 0 end
end
Event_Handler:register_event({
    event_name = "on_object_destroyed",
    source_name = "unit_group_controller.on_object_destroyed",
    func_name = "unit_group_controller.on_object_destroyed",
    func = unit_group_controller.on_object_destroyed,
})

function unit_group_controller.init(__storage) storage = __storage or _ENV.storage end

return unit_group_controller