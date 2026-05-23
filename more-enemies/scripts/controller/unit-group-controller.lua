local storage
local stats_data

local game

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

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

function unit_group_controller.init(__storage) storage = __storage or _ENV.storage end

return unit_group_controller