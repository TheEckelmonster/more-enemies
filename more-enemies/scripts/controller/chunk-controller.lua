local storage
local stats_data
local attack_groups
local chunks_arr
local chunk_maps
local spawner_maps
local surfaces

local game

local Planets = Planets

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

local ipairs = ipairs

local table_insert = table.insert
local table_remove = table.remove

local Event_Handler = Event_Handler
local Log = Log

local Attack_Group_Constants = require("scripts.constants.attack-group-constants")
local attack_group_type_blacklist = Attack_Group_Constants.type_blacklist
local Quadtree_Service = require("scripts.service.quadtree-service")
local add_node = Quadtree_Service.add_node
local remove_node = Quadtree_Service.remove_node
local Settings_Utils = require("scripts.utils.settings-utils")

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table_insert(names, v)
    end
end

if (next(names, nil) == nil) then names = nil end

local chunk_controller = {}
chunk_controller.name = "chunk_controller"
chunk_controller.set_game = set_game

local unit_spawner_type_tbl = { UNIT_SPAWNER, }
local enemy_force_tbl = { ENEMY, }
local player_force_tbl = { ENEMY, NEUTRAL }

local FORWARD_SLASH = FORWARD_SLASH

function chunk_controller.on_chunk_generated(event)
    -- Log.debug("chunk_controller.on_chunk_generated")
    -- Log.info(event)

    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    if (not event.surface or not event.surface.valid) then return end
    local surface = event.surface

    local chunk_position = event.position
    if (not chunk_position) then return end

    local surface_name = surface.name

    chunks_arr = chunks_arr or set_game() and chunks_arr
    local chunks = chunks_arr[surface_name] or {}

    spawner_maps = spawner_maps or set_game() and spawner_maps
    local spawner_map = spawner_maps[surface_name] or {}

    chunk_maps = chunk_maps or set_game() and chunk_maps
    local chunk_map = chunk_maps[surface_name] or {}

    local chunk = {}
    chunk.x = chunk_position.x
    chunk.y = chunk_position.y
    chunk.xy = chunk.x .. FORWARD_SLASH .. chunk.y

    local area = {
        { x = chunk.x * Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE, },
        { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
    }

    chunk.spawner_count = surface.count_entities_filtered({
        area = area,
        type = unit_spawner_type_tbl,
        force = enemy_force_tbl,
    })

    if (chunk.spawner_count > 0) then spawner_map[chunk.xy] = chunk end

    chunk.entity_count = surface.count_entities_filtered({
        area = area,
        name = names,
        type = attack_group_type_blacklist,
        force = player_force_tbl,
        invert = true,
    })

    if (chunk.entity_count > 0) then
        chunk_map[chunk.xy] = chunk
        chunks[#chunks+1] = chunk

        attack_groups = attack_groups or set_game() and attack_groups
        local attack_group = attack_groups[surface_name]
        if (attack_group) then
            attack_group.next_chunks = attack_group.next_chunks or {}
            attack_group.next_chunks[#attack_group.next_chunks+1] = chunk
        end
    end

    if (chunk.spawner_count > 0) then
        add_node({
            tick = event.tick or 0,
            source_chunk = chunk,
            surface_name = surface_name,
        })
    end
end
Event_Handler:register_event({
    event_name = "on_chunk_generated",
    source_name = "chunk_controller.on_chunk_generated",
    func_name = "chunk_controller.on_chunk_generated",
    func = chunk_controller.on_chunk_generated,
})

function chunk_controller.on_chunk_deleted(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    if (not event.positions or #event.positions < 1) then return end
    if (not event.surfce_index or event.surfce_index < 1) then return end

    local surface = game.get_surface(event.surfce_index)
    if (not surface or not surface.valid) then return end
    local surface_name = surface.name

    chunks_arr = chunks_arr or set_game() and chunks_arr
    local chunks = chunks_arr[surface_name]

    spawner_maps = spawner_maps or set_game() and spawner_maps
    local spawner_map = spawner_maps[surface_name]

    chunk_maps = chunk_maps or set_game() and chunk_maps
    local chunk_map = chunk_maps[surface_name]
    if (not chunk_map) then return end

    for i, chunk_position in ipairs(event.positions) do
        remove_node({ surface_name = surface_name, source_chunk = chunk_position, })

        local xy = chunk_position.x .. FORWARD_SLASH .. chunk_position.y
        spawner_map[xy] = nil

        local count = #chunks
        chunks[count] = nil

        for j, chunk in ipairs(chunks) do
            chunk.xy = chunk.xy or (chunk.x .. FORWARD_SLASH .. chunk.y)
            if (chunk.xy == xy) then
                chunk_map[chunk.xy] = nil
                -- local temp = chunks[j]
                chunks[j] = chunks[#chunks]
                chunks[#chunks] = nil
                break
            end
        end
    end
end
Event_Handler:register_event({
    event_name = "on_chunk_deleted",
    source_name = "chunk_controller.on_chunk_deleted",
    func_name = "chunk_controller.on_chunk_deleted",
    func = chunk_controller.on_chunk_deleted,
})

function chunk_controller.init(__storage) storage = __storage or _ENV.storage end

return chunk_controller