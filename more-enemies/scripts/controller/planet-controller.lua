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

local Log = Log

local Planet_Service = require("scripts.service.planet-service")
local on_surface_created = Planet_Service.on_surface_created
local on_surface_deleted = Planet_Service.on_surface_deleted
local on_surface_renamed = Planet_Service.on_surface_renamed

local planet_controller = {}
planet_controller.name = "planet_controller"
planet_controller.set_game = set_game

function planet_controller.on_surface_created(event)
    -- Log.debug("planet_controller.on_surface_created")
    -- Log.info(event)

    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)
    on_surface_created(event)
end
Event_Handler:register_event({
    event_name = "on_surface_created",
    source_name = "planet_controller.on_surface_created",
    func_name = "planet_controller.on_surface_created",
    func = planet_controller.on_surface_created,
})

function planet_controller.on_surface_deleted(event)
    -- Log.debug("planet_controller.on_surface_deleted")
    -- Log.info(event)

    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)
    on_surface_deleted(event)
end
Event_Handler:register_event({
    event_name = "on_surface_deleted",
    source_name = "planet_controller.on_surface_deleted",
    func_name = "planet_controller.on_surface_deleted",
    func = planet_controller.on_surface_deleted,
})

function planet_controller.on_surface_renamed(event)
    -- Log.debug("planet_controller.on_surface_renamed")
    -- Log.info(event)

    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)
    on_surface_renamed(event)
end
Event_Handler:register_event({
    event_name = "on_surface_renamed",
    source_name = "planet_controller.on_surface_renamed",
    func_name = "planet_controller.on_surface_renamed",
    func = planet_controller.on_surface_renamed,
})

function planet_controller.init(__storage) storage = __storage or _ENV.storage end

return planet_controller