local storage
local stats_data
local attack_groups
local chunks_arr
local chunk_maps
local entity_chunks
local entity_maps
local num_clones
local post_entity_died_buckets
local spawner_maps
local surfaces
local unit_groups

local game
local surface_funcs

local Set_Num_Clones = Set_Num_Clones
local Surfaces = Surfaces

local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new
local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local string_find = string.find

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

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.post_entity_died_buckets = storage.post_entity_died_buckets or {}
    post_entity_died_buckets = storage.post_entity_died_buckets

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    for _, planet in ipairs(Planets or {}) do
        post_entity_died_buckets[planet] = post_entity_died_buckets[planet] or {}

        surfaces[planet] = surfaces[planet] or {}
        surfaces[planet].chunks = surfaces[planet].chunks or {}
        surfaces[planet].entity_chunks = surfaces[planet].entity_chunks or {}
        surfaces[planet].chunk_map = surfaces[planet].chunk_map or {}
        surfaces[planet].entity_maps = surfaces[planet].entity_maps or {}
        surfaces[planet].spawner_map = surfaces[planet].spawner_map or {}

        chunks_arr[planet] = chunks_arr[planet] or surfaces[planet].chunks
        entity_chunks[planet] = entity_chunks[planet] or surfaces[planet].entity_chunks
        chunk_maps[planet] = chunk_maps[planet] or surfaces[planet].chunk_map
        entity_maps[planet] = entity_maps[planet] or surfaces[planet].entity_maps
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_map
    end

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    game = __game or _ENV.game

    _ENV.Surface_Funcs = _ENV.Surface_Funcs or {}
    Surface_Funcs = _ENV.Surface_Funcs

    _ENV.Surfaces = _ENV.Surfaces or {}
    Surfaces = _ENV.Surfaces
    Surfaces.list = Surfaces.list or {}
    for name, surface in pairs(game.surfaces) do
        if (surface.valid and not string_find(surface.name, "platform%-[%d]*")) then
            Surfaces[name] = surface
            Surfaces.list[surface.index] = name

            Surface_Funcs[name] = Surface_Funcs[name] or {}
            Surface_Funcs[name].create_unit_group = Surface_Funcs[name].create_unit_group or surface.create_unit_group
            Surface_Funcs[name].count_entities_filtered = Surface_Funcs[name].count_entities_filtered or surface.count_entities_filtered
            Surface_Funcs[name].find_entities_filtered = Surface_Funcs[name].find_entities_filtered or surface.find_entities_filtered
            Surface_Funcs[name].find_non_colliding_position = Surface_Funcs[name].find_non_colliding_position or surface.find_non_colliding_position
            Surface_Funcs[name].request_path = Surface_Funcs[name].request_path or surface.request_path
        else
            Surfaces[name], Surface_Funcs[name] = nil, nil
        end
    end
    surface_funcs = Surface_Funcs

    num_clones = Set_Num_Clones()

    return game
end

local math_floor = math.floor
local math_max = math.max
local pairs = pairs
local table_insert = table.insert
local table_size = table_size

local Constants = Constants or require("scripts.constants.constants")
local Log = Log

local Planets = Planets
local num_planets = table_size(Planets)
local planets = {}

local i = 0
local modulo = math.ceil(10 + table_size(Planets) / 2) % 60 + 1
for _, planet in pairs(Planets) do
    local idx = i % (modulo) + 1
    planets[idx] = planets[idx] or {}
    table.insert(planets[idx], planet)
    i = i + 1
end

local Attack_Group_Constants = require("scripts.constants.attack-group-constants")
local attack_group_type_blacklist = Attack_Group_Constants.type_blacklist
local Leaf_Data = require("scripts.data.leaf-data")
local new_Leaf_Data = Leaf_Data.new
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template
local Quadtree_Service = require("scripts.service.quadtree-service")
local add_node = Quadtree_Service.add_node
local Settings_Utils = require("scripts.utils.settings-utils")

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table_insert(names, v)
    end
end

if (next(names, nil) == nil) then names = nil end

local metrics_controller = {}
metrics_controller.name = "metrics_controller"
metrics_controller.set_game = set_game

local CHUNK_SIZE = Constants.CHUNK_SIZE
local ME_PREFIX = ME_PREFIX
local UINT64 = 2^64-1
local UNKNOWN = "unknown"

local clone_count = 0

local prototypes = prototypes
local mod_data = prototypes.mod_data
local target_priority_data = mod_data[Constants.mod_name .. "-target-priority-data"]
local target_priority_DB = target_priority_data.data

local metrics_filter = {
    { filter = "type", type = UNIT, },
    { filter = "type", type = SPIDER_UNIT, },
}

-- log(serpent.block(target_priority_DB))

local types_map = {}
for _, entry in pairs(target_priority_DB or {}) do
    if (entry.type) then
        types_map[entry.type] = 1
    end
end

for entity_type, _ in pairs(types_map or {}) do
    metrics_filter[#metrics_filter+1] = { filter = "type", type = entity_type, }
end

local types = {
    [UNIT] = 1,
    [SPIDER_UNIT] = 1,
}

local unit_spawner_type_tbl = { UNIT_SPAWNER, }
local enemy_force_tbl = { ENEMY, }
local player_force_tbl = { ENEMY, NEUTRAL }

local GROUP, SPAWNED = GROUP, SPAWNED
local FORWARD_SLASH = FORWARD_SLASH
function metrics_controller.on_post_entity_died(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end
    -- log(serpent.block(event))
    -- if (not process_event(stats_data, event.name, event.tick)) then if (types[event.prototype.type]) then return end end
    process_event(stats_data, event.name, event.tick)

    if (not event.prototype or not event.prototype.valid) then return end
    local proto = event.prototype
    local entity_name = proto.name

    unit_groups = unit_groups or set_game() and unit_groups
    unit_groups.unit_nums = unit_groups.unit_nums or {}
    local source = unit_groups.unit_nums[event.unit_number] and GROUP or SPAWNED
    unit_groups.unit_nums[event.unit_number or 0] = nil

    Surfaces = Surfaces or set_game() and Surfaces
    Surfaces.list = Surfaces.list or {}
    local surface_name = Surfaces.list[event.surface_index]
    if (not surface_name) then return end

    num_clones = num_clones or set_game() and num_clones

    num_clones[source] = num_clones[source] or {}
    num_clones[source][surface_name] = num_clones[source][surface_name] or {}
    num_clones[source][surface_name][entity_name] = num_clones[source][surface_name][entity_name] or 0
    num_clones[source][surface_name][entity_name] = math_max(num_clones[source][surface_name][entity_name], 1) - 1

    if (not event.force or not event.force.valid) then return end
    local force_name = event.force.name

    local is_building = proto.is_building and 1 or 0
    local is_combatant = types[proto.type] or 0

    local killer_force_name = force_name or UNKNOWN
    local was_killed_by_enemy      = killer_force_name == ENEMY
    local was_killed_by_player     = killer_force_name == PLAYER
    local was_killed_by_NOT_enemy  = killer_force_name ~= ENEMY
    local was_killed_by_NOT_player = killer_force_name ~= PLAYER

    local player_infrastructure_loss = 0
    local enemy_combatant_loss = 0

    if (is_building and (was_killed_by_NOT_player or was_killed_by_enemy)) then
        player_infrastructure_loss = 1
    elseif (is_combatant and (was_killed_by_NOT_enemy or was_killed_by_player)) then
        enemy_combatant_loss = 1
    else
        return
    end

    chunk_maps = chunk_maps or set_game() and chunk_maps
    chunk_maps[surface_name] = chunk_maps[surface_name] or {}
    local chunk_map = chunk_maps[surface_name]

    local x = math_floor(event.position.x / CHUNK_SIZE)
    local y = math_floor(event.position.y / CHUNK_SIZE)
    local xy = x .. FORWARD_SLASH .. y

    if (not chunk_map[xy]) then
        local chunk = new_Leaf_Data(Leaf_Data, { x = x, y = y, }, event.tick)
        chunk.xy = xy
        local area = {
            { x = chunk.x * Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE, },
            { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
        }

        surface_funcs = surface_funcs or set_game() and surface_funcs
        chunk.spawner_count = surface_funcs[surface_name].count_entities_filtered({
            area = area,
            type = unit_spawner_type_tbl,
            force = enemy_force_tbl,
        })

        spawner_maps = spawner_maps or set_game() and spawner_maps
        spawner_maps[surface_name] = spawner_maps[surface_name] or {}
        local spawner_map = spawner_maps[surface_name]
        if (chunk.spawner_count > 0) then spawner_map[chunk.xy] = chunk end

        chunk.entity_count = surface_funcs[surface_name].count_entities_filtered({
            area = area,
            name = names,
            type = attack_group_type_blacklist,
            force = player_force_tbl,
            invert = true,
        })

        chunks_arr = chunks_arr or set_game() and chunks_arr
        local chunks = chunks_arr[surface_name] or {}

        local node = add_node({
            tick = event.tick or 0,
            source_chunk = chunk,
            surface_name = surface_name,
        })

        chunk.parent_node = node

        if (chunk.entity_count > 0) then
            attack_groups = attack_groups or set_game() and attack_groups
            local attack_group = attack_groups[surface_name]
            if (attack_group) then
                attack_group.next_chunks = attack_group.next_chunks or {}
                attack_group.next_chunks[#attack_group.next_chunks+1] = chunk
            end

            entity_chunks = entity_chunks or set_game() and entity_chunks
            entity_chunks[surface_name] = entity_chunks[surface_name] or {}
            local entity_chunk_arr = entity_chunks[surface_name]

            entity_chunk_arr[#entity_chunk_arr+1] = chunk

            entity_maps = entity_maps or set_game() and entity_maps
            entity_maps[surface_name] = entity_maps[surface_name] or {}
            local entity_map = entity_maps[surface_name]

            entity_map[chunk.xy] = chunk
        end

        chunk_map[chunk.xy] = chunk
        chunks[#chunks+1] = chunk
    end
    local chunk = chunk_map[xy]
    chunk.meta = chunk.meta or new_template(Quad_Meta_Data, event.tick)
    local meta = chunk.meta

    local metrics = target_priority_DB[entity_name] or {}
    local weight = metrics.w or 4
    --[[ TODO: Add/inject weight ^ evolution_factor]]
    -- weight = weight ^ evolution_factor

    meta.death_weight = meta.death_weight + weight
    meta.prev_death_tick = meta.last_death_tick or 0
    meta.last_death_tick = event.tick

    meta.player_deaths = (meta.player_deaths or 0) + player_infrastructure_loss
    meta.enemy_deaths = (meta.enemy_deaths or 0) + enemy_combatant_loss

    meta.total_player_deaths = (meta.total_player_deaths or 0) + player_infrastructure_loss
    meta.total_enemy_deaths = (meta.total_enemy_deaths or 0) + enemy_combatant_loss

    meta.total_deaths = meta.total_deaths + player_infrastructure_loss + enemy_combatant_loss

    post_entity_died_buckets = post_entity_died_buckets or set_game() and post_entity_died_buckets
    post_entity_died_buckets[surface_name] = post_entity_died_buckets[surface_name] or {}
    post_entity_died_buckets[surface_name][xy] = post_entity_died_buckets[surface_name][xy] or {
        xy = xy, chunk = chunk,
        w = 0, p = 1, fx = 0,
    }

    local bucket = post_entity_died_buckets[surface_name][xy]
    bucket.w = bucket.w + weight
    bucket.fx = bucket.fx + (metrics.fx or 1.0)
    bucket.p = math_max(bucket.p, metrics.p or 1)
end
Event_Handler:register_event({
    event_name = "on_post_entity_died",
    filter = metrics_filter,
    source_name = "metrics_controller.on_post_entity_died",
    func_name = "metrics_controller.on_post_entity_died",
    func = metrics_controller.on_post_entity_died,
})

function metrics_controller.init(__storage) storage = __storage or _ENV.storage end

return metrics_controller