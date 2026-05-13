local storage
local stats
local surfaces

local game

local function set_game(__game, __storage)
    storage = __storage or _ENV.storage

    storage.stats = storage.stats or {}
    stats = storage.stats

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    --[[ game ]]
    game = __game or _ENV.game

    return game
end

local math_floor = math.floor
local ipairs = ipairs
local table_remove = table.remove

local Constants = Constants
local Event_Handler = Event_Handler
local Log = Log

local Forces = {
    ["enemy"] = 1,
    ["neutral"] = 1,
}
local Valid_Surfaces = Valid_Surfaces

local entity_controller = {}
entity_controller.name = "entity_controller"
entity_controller.set_game = set_game

function entity_controller.on_built_entity(event)
    -- Log.debug("entity_controller.on_built_entity")
    -- Log.info(event)

    if (not event) then return end

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
    local xy = chunk.x .. "/" .. chunk.y
    chunk.xy = xy

    if (not chunk_map[xy]) then
        chunk_map[xy] = chunk
        chunks[#chunks+1] = chunk
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

    if (not event) then return end

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

    surfaces[surface_name].spawner_map = surfaces[surface_name].spawner_map or {}

    local xy = math_floor(position.x / Constants.CHUNK_SIZE) .. "/" .. math_floor(position.y / Constants.CHUNK_SIZE)

    local chunk = chunk_map[xy]
    if (not chunk) then return end
    chunk.entity_count = chunk.entity_count or 1
    chunk.entity_count = chunk.entity_count - 1

    if (chunk.entity_count < 1) then
        for i, v in ipairs(chunks) do
            v.xy = v.xy or (v.x .. "/" .. v.y)
            if (v.xy == xy) then
                chunk_map[v.xy] = nil
                table_remove(chunks, i)
                break
            end
        end
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

    if (not event) then return end

    local entity = event.entity
    if (not entity or not entity.valid or entity.type ~= "unit-spawner") then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end

    local x = math_floor(entity.position.x / Constants.CHUNK_SIZE)
    local y = math_floor(entity.position.y / Constants.CHUNK_SIZE)
    local xy = x .. "/" .. y

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

function entity_controller.init(__storage)
    storage = __storage
end

return entity_controller