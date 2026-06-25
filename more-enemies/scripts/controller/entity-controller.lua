local storage
local stats_data
local attack_groups
local chunks_arr
local chunk_maps
local spawner_maps
local surfaces

local game

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.attack_groups = storage.attack_groups or {}
    attack_groups = storage.attack_groups

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.chunks_arr = storage.chunks_arr or {}
    chunks_arr = storage.chunks_arr

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    for _, planet in ipairs(Planets or {}) do
        surfaces[planet] = surfaces[planet] or {}
        surfaces[planet].chunks = surfaces[planet].chunks or {}
        surfaces[planet].chunk_map = surfaces[planet].chunk_map or {}
        surfaces[planet].spawner_map = surfaces[planet].spawner_map or {}

        chunks_arr[planet] = chunks_arr[planet] or surfaces[planet].chunks
        chunk_maps[planet] = chunk_maps[planet] or surfaces[planet].chunk_map
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_map
    end

    game = __game or _ENV.game

    return game
end

local math_floor = math.floor

local Constants = Constants
local Event_Handler = Event_Handler
local Log = Log

local Forces = {
    [ENEMY] = 1,
    [NEUTRAL] = 1,
}
local Valid_Surfaces = Valid_Surfaces

local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack

local entity_controller = {}
entity_controller.name = "entity_controller"
entity_controller.set_game = set_game

function entity_controller.on_built_entity(event)
    -- Log.debug("entity_controller.on_built_entity")
    -- Log.info(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    stats_data.current[event.name] = (stats_data.current[event.name] or 0) + 1

    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local force = entity.force
    if (not force or not force.valid or Forces[force.name]) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end

    local surface_name = surface.name
    if (not Valid_Surfaces[surface_name]) then return end

    local position = entity.position
    if (not position) then return end

    surfaces = surfaces or set_game() and surfaces
    surfaces[surface_name] = surfaces[surface_name] or {}
    surfaces[surface_name].chunks = surfaces[surface_name].chunks or {}
    local chunks = surfaces[surface_name].chunks

    surfaces[surface_name].chunk_map = surfaces[surface_name].chunk_map or {}
    local chunk_map = surfaces[surface_name].chunk_map

    local chunk = {}
    chunk.x = math_floor(position.x / Constants.CHUNK_SIZE)
    chunk.y = math_floor(position.y / Constants.CHUNK_SIZE)
    local xy = pack_coordinates(chunk.x, chunk.y)
    chunk.xy = xy

    if (not chunk_map[xy]) then
        chunk_map[xy] = chunk
        chunks[#chunks+1] = chunk

        attack_groups = attack_groups or set_game() and attack_groups
        local attack_group = attack_groups[surface_name]
        if (attack_group) then
            attack_group.next_chunks = attack_group.next_chunks or {}
            attack_group.next_chunks[#attack_group.next_chunks+1] = chunk
        end
    else
        chunk = chunk_map[xy]
    end

    chunk.entity_count = chunk.entity_count or 0
    chunk.entity_count = chunk.entity_count + 1
end
Event_Handler:register_events({
    {
        event_name = "on_built_entity",
        source_name = "entity_controller.on_built_entity",
        func_name = "entity_controller.on_built_entity",
        func = entity_controller.on_built_entity,
    },
    {
        event_name = "on_robot_built_entity",
        source_name = "entity_controller.on_built_entity",
        func_name = "entity_controller.on_built_entity",
        func = entity_controller.on_built_entity,
    },
})

function entity_controller.on_mined_entity(event)
    -- Log.debug("entity_controller.on_built_entity")
    -- Log.info(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    stats_data.current[event.name] = (stats_data.current[event.name] or 0) + 1

    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local force = entity.force
    if (not force or not force.valid or Forces[force.name]) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end

    local surface_name = surface.name
    if (not Valid_Surfaces[surface_name]) then return end

    local position = entity.position
    if (not position) then return end

    surfaces = surfaces or set_game() and surfaces
    surfaces[surface_name] = surfaces[surface_name] or {}
    surfaces[surface_name].chunks = surfaces[surface_name].chunks or {}
    local chunks = surfaces[surface_name].chunks

    surfaces[surface_name].chunk_map = surfaces[surface_name].chunk_map or {}
    local chunk_map = surfaces[surface_name].chunk_map

    local xy = pack_coordinates(position.x / Constants.CHUNK_SIZE, position.y / Constants.CHUNK_SIZE)

    local chunk = chunk_map[xy]
    if (not chunk) then return end
    chunk.entity_count = chunk.entity_count or 1
    chunk.entity_count = chunk.entity_count - 1

    if (chunk.entity_count < 1) then
        if (chunk.i) then
            local count = #chunks
            local temp = chunks[count]

            chunks[chunk.i] = temp
            chunks[count] = nil

            if (temp) then temp.i = chunk.i end
        else
            local count = #chunks
            for i = 1, count, 1 do chunks[i].i = i end

            local chunk = chunk_map[xy]
            if (chunk and chunk.i) then
                local temp = chunks[count]

                chunks[chunk.i] = temp
                chunks[count] = nil

                if (temp) then temp.i = chunk.i end
            end
        end

        chunk_map[xy] = nil
    end
end
Event_Handler:register_events({
    {
        event_name = "on_player_mined_entity",
        source_name = "entity_controller.on_mined_entity",
        func_name = "entity_controller.on_mined_entity",
        func = entity_controller.on_mined_entity,
    },
    {
        event_name = "on_robot_mined_entity",
        source_name = "entity_controller.on_mined_entity",
        func_name = "entity_controller.on_mined_entity",
        func = entity_controller.on_mined_entity,
    },
})

function entity_controller.on_biter_base_built(event)

    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    local entity = event.entity
    if (not entity or not entity.valid or entity.type ~= UNIT_SPAWNER) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end

    local x = math_floor(entity.position.x / Constants.CHUNK_SIZE)
    local y = math_floor(entity.position.y / Constants.CHUNK_SIZE)
    local xy = pack_coordinates(x, y)

    local surface_name = surface.name
    surfaces = surfaces or set_game() and surfaces
    surfaces[surface_name] = surfaces[surface_name] or {}

    surfaces[surface_name].spawner_map = surfaces[surface_name].spawner_map or {}
    local spawner_map = surfaces[surface_name].spawner_map
    spawner_map[xy] = spawner_map[xy] or { x = x, y = y, xy = xy, }

    local chunk = spawner_map[xy]
    if (chunk) then chunk.spawner_count = (chunk.spawner_count or 0) + 1 end
end
Event_Handler:register_event(
{
    event_name = "on_biter_base_built",
    source_name = "entity_controller.on_biter_base_built",
    func_name = "entity_controller.on_biter_base_built",
    func = entity_controller.on_biter_base_built,
})

function entity_controller.init(__storage) storage = __storage or _ENV.storage end

return entity_controller