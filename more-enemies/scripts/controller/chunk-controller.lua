local storage = storage

local ipairs = ipairs

local table_insert = table.insert
local table_remove = table.remove

local Event_Handler = Event_Handler
local Log = Log

local Attack_Group_Constants = require("libs.constants.attack-group-constants")
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

function chunk_controller.on_chunk_generated(event)
    -- Log.debug("chunk_controller.on_chunk_generated")
    -- Log.info(event)

    if (not event) then return end

    local surface = event.surface
    if (not surface or not surface.valid) then return end

    local chunk_position = event.position
    if (not chunk_position) then return end

    local surface_name = surface.name

    storage.surfaces = storage.surfaces or {}
    storage.surfaces[surface_name] = storage.surfaces[surface_name] or {}
    storage.surfaces[surface_name].chunks = storage.surfaces[surface_name].chunks or {}
    local chunks = storage.surfaces[surface_name].chunks

    storage.surfaces[surface_name].spawner_map = storage.surfaces[surface_name].spawner_map or {}
    local spawner_map = storage.surfaces[surface_name].spawner_map

    storage.surfaces[surface_name].chunk_map = storage.surfaces[surface_name].chunk_map or {}
    local chunk_map = storage.surfaces[surface_name].chunk_map

    local chunk = {}
    chunk.x = chunk_position.x
    chunk.y = chunk_position.y
    chunk.xy = chunk.x .. "/" .. chunk.y

    local area = {
        { x = chunk.x * Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE, },
        { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
    }

    chunk.spawner_count = surface.count_entities_filtered({
        area = area,
        type = { "unit-spawner", },
        force = { "enemy", },
    })

    if (chunk.spawner_count > 0) then spawner_map[chunk.xy] = chunk end

    chunk.entity_count = surface.count_entities_filtered({
        area = area,
        name = names,
        type = Attack_Group_Constants.type_blacklist,
        force = { "enemy", "neutral" },
        invert = true,
    })

    if (chunk.entity_count > 0) then
        chunk_map[chunk.xy] = chunk
        chunks[#chunks+1] = chunk
    end
end
Event_Handler:register_event({
    event_name = "on_chunk_generated",
    source_name = "chunk_controller.on_chunk_generated",
    func_name = "chunk_controller.on_chunk_generated",
    func = chunk_controller.on_chunk_generated,
})

function chunk_controller.on_chunk_deleted(event)

    if (not event) then return end
    if (not event.positions or #event.positions < 1) then return end
    if (not event.surfce_index or event.surfce_index < 1) then return end

    local surface = game.get_surface(event.surfce_index)
    if (not surface or not surface.valid) then return end
    local surface_name = surface.name

    storage.surfaces = storage.surfaces or {}
    storage.surfaces[surface_name] = storage.surfaces[surface_name] or {}
    storage.surfaces[surface_name].chunks = storage.surfaces[surface_name].chunks or {}
    local chunks = storage.surfaces[surface_name].chunks

    storage.surfaces[surface_name].chunk_map = storage.surfaces[surface_name].chunk_map or {}
    local spawner_map = storage.surfaces[surface_name].spawner_map

    storage.surfaces[surface_name].chunk_map = storage.surfaces[surface_name].chunk_map or {}
    local chunk_map = storage.surfaces[surface_name].chunk_map

    for i, chunk_position in ipairs(event.positions) do
        local xy = chunk_position.x .. "/" .. chunk_position.y
        spawner_map[xy] = nil

        for j, v in ipairs(chunks) do
            v.xy = v.xy or (v.x .. "/" .. v.y)
            if (v.xy == xy) then
                chunk_map[v.xy] = nil
                table_remove(chunks, j)
                goto continue
            end
        end

        ::continue::
    end
end
Event_Handler:register_event({
    event_name = "on_chunk_deleted",
    source_name = "chunk_controller.on_chunk_deleted",
    func_name = "chunk_controller.on_chunk_deleted",
    func = chunk_controller.on_chunk_deleted,
})

function chunk_controller.init(__storage)
    storage = __storage
end

return chunk_controller