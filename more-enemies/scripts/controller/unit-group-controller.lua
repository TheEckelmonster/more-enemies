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
local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.on_object_destroyed = storage.on_object_destroyed or new_Simple_Queue(Simple_Queue)
    on_object_destroyed = storage.on_object_destroyed

    storage.unique_ids = storage.unique_ids
    unique_ids = storage.unique_ids

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    game = __game or _ENV.game

    return game
end

local script = script
local register_on_object_destroyed = script.register_on_object_destroyed

local Valid_Surfaces = Valid_Surfaces

local Log = require("libs.log.log")

local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack
local Unit_Group_Service = require("scripts.service.unit-group-service")

local on_unit_group_finished_gathering = Unit_Group_Service.on_unit_group_finished_gathering

local unit_group_controller = {}
unit_group_controller.name = "unit_group_controller"
unit_group_controller.set_game = set_game

function unit_group_controller.on_unit_group_created(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    if (not event.group or not event.group.valid) then return end
    local commandable = event.group
    if (commandable.is_script_driven) then return end
    if (not commandable.is_unit_group) then return end
    local tick = event.tick
    local unique_id = commandable.unique_id

    local reg_tbl = { created = tick, updated = tick, refreshed_tick = tick, group = commandable, unique_id = unique_id, starting_pos = commandable.position, surface_name = commandable.surface.name, force_name = commandable.force.name, }
    reg_tbl.xy = pack_coordinates(reg_tbl.starting_pos.x, reg_tbl.starting_pos.y)
    reg_tbl.registration_number, reg_tbl.useful_id, reg_tbl.reg_target_type = register_on_object_destroyed(commandable)

    groups = groups or set_game() and groups
    groups[unique_id] = reg_tbl

    unit_groups = unit_groups or set_game() and unit_groups
    unit_groups.count = (unit_groups.count or 0) + 1
    unit_groups.surface_count = unit_groups.surface_count or {}
    unit_groups.surface_count[reg_tbl.surface_name] = (unit_groups.surface_count[reg_tbl.surface_name] or 0) + 1

    on_object_destroyed = on_object_destroyed or set_game() and on_object_destroyed
    on_object_destroyed[reg_tbl.surface_name] = on_object_destroyed[reg_tbl.surface_name] or new_Simple_Queue(Simple_Queue)
    local on_surface_object_destroyed = on_object_destroyed[reg_tbl.surface_name]
    local next_idx = on_surface_object_destroyed.last
    on_surface_object_destroyed.last = next_idx + 1
    on_surface_object_destroyed.q[next_idx] = reg_tbl
    reg_tbl.i = next_idx
    on_object_destroyed[reg_tbl.registration_number] = reg_tbl
end
Event_Handler:register_event({
    event_name = "on_unit_group_created",
    source_name = "unit_group_controller.on_unit_group_created",
    func_name = "unit_group_controller.on_unit_group_created",
    func = unit_group_controller.on_unit_group_created,
})

function unit_group_controller.on_unit_group_finished_gathering(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    -- if (not process_event(stats_data, event.name, event.tick)) then return end
    local do_process_event = process_event(stats_data, event.name, event.tick)

    if (not event.group or not event.group.valid) then return end
    local commandable = event.group
    if (commandable.is_script_driven) then return end
    if (not commandable.is_unit_group) then return end
    local tick = event.tick
    local unique_id = commandable.unique_id

    if (not groups[unique_id]) then
        local reg_tbl = { created = tick, updated = tick, refreshed_tick = tick, group = commandable, unique_id = unique_id, starting_pos = commandable.position, surface_name = commandable.surface.name, force_name = commandable.force.name, }
        reg_tbl.xy = pack_coordinates(reg_tbl.starting_pos.x, reg_tbl.starting_pos.y)
        reg_tbl.registration_number, reg_tbl.useful_id, reg_tbl.reg_target_type = register_on_object_destroyed(commandable)

        groups = groups or set_game() and groups
        groups[unique_id] = reg_tbl

        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups.count = (unit_groups.count or 0) + 1
        unit_groups.surface_count[reg_tbl.surface_name] = (unit_groups.surface_count[reg_tbl.surface_name] or 0) + 1
    end

    if (not do_process_event) then return end

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
    on_object_destroyed[event.registration_number or 0] = nil

    local surface_name = reg_tbl.surface_name
    if (not reg_tbl.surface_name or not Valid_Surfaces[reg_tbl.surface_name]) then return end
    on_object_destroyed[surface_name] = on_object_destroyed[surface_name] or new_Simple_Queue(Simple_Queue)
    local on_surface_object_destroyed = on_object_destroyed[surface_name]

    on_surface_object_destroyed.first, on_surface_object_destroyed.last = (on_surface_object_destroyed.first or 1), (on_surface_object_destroyed.last or 1)
    if (on_surface_object_destroyed.last <= on_surface_object_destroyed.first) then
        on_surface_object_destroyed.first, on_surface_object_destroyed.last = 1, 1
        on_surface_object_destroyed.q = {}
    end

    local s_last = (on_object_destroyed.last - on_object_destroyed.first) > 1 and on_object_destroyed.last - 1 or 1
    local s_idx  = reg_tbl.i or s_last
    on_surface_object_destroyed.q[s_idx] = on_object_destroyed.q[s_last]
    if (on_object_destroyed.q[s_idx]) then
        on_object_destroyed.q[s_idx].i = s_idx
        on_object_destroyed.q[s_last] = nil
    end

    -- on_object_destroyed.first, on_object_destroyed.last = (on_object_destroyed.first or 1), (on_object_destroyed.last or 1)
    -- if (on_object_destroyed.last <= on_object_destroyed.first) then
    --     on_object_destroyed.first, on_object_destroyed.last = 1, 1
    --     on_object_destroyed.q = {}
    -- end

    -- local last = (on_object_destroyed.last - on_object_destroyed.first) > 1 and on_object_destroyed.last - 1 or 1
    -- local idx  = reg_tbl.i or last
    -- on_object_destroyed.q[idx] = on_object_destroyed.q[last]
    -- if (on_object_destroyed.q[idx]) then
    --     on_object_destroyed.q[idx].i = idx
    --     on_object_destroyed.q[last] = nil
    -- end

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