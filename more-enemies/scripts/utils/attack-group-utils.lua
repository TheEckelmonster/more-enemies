local storage
local stats_data
local chunks_arr
local chunk_maps
local difficulties
local entity_chunks
local entity_maps
local spawner_maps
local surfaces

local game
local get_surface
local surface_funcs

local Planets = Planets
local Surfaces = Surfaces

local Stats_Data = require("scripts.data.stats-data")
local new_Stats_Data = Stats_Data.new

local string_find = string.find

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.chunks_arr = storage.chunks_arr or {}
    chunks_arr = storage.chunks_arr

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    for _, planet in ipairs(Planets or {}) do
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

    game = __game or _ENV.game
    get_surface = game.get_surface

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

    return game
end

local CHUNK_SIZE = Constants.CHUNK_SIZE

local math_min = math.min

local next = next

local pairs = pairs

local Constants = Constants or require("scripts.constants.constants")
local Log = Log

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Attack_Group_Constants = require("libs.constants.attack-group-constants")
local type_blacklist = Attack_Group_Constants.type_blacklist
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template
local Quadtree_Service = require("scripts.service.quadtree-service")
local find_closest_spawner = Quadtree_Service.find_closest_spawner
local Settings_Service = require("scripts.service.settings-service")
local get_startup_setting = Settings_Service.get_startup_setting
local Settings_Utils = require("scripts.utils.settings-utils")

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table.insert(names, v)
    end
end

if (next(names, nil) == nil) then names = nil end

local attack_group_utils = {}
attack_group_utils.name = "attack_group_utils"
attack_group_utils.set_game = set_game

local ENEMY = "enemy"
local ENEMY_TYPES = { "unit", "spider-unit", }
local PLAYER_FORCES = { "enemy", "neutral" }
local TICKS_PER_MINUTE = Constants.time.TICKS_PER_MINUTE
local X_MINUTES = 1.25 * TICKS_PER_MINUTE

function attack_group_utils.get_enemy(params)
    -- Log.debug("attack_group_utils.get_enemy")
    -- Log.info(params)

    local surface_name = params.surface_name
    if (not surface_name) then return end

    -- local chunk = params.chunk
    -- log(serpent.block(chunk))
    -- if (not chunk) then return end

    if (not params.xy) then return end
    local xy = params.xy

    -- local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    local surface = (Surfaces or set_game() and Surfaces) and Surfaces[surface_name] or game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty) then return end

    entity_maps = entity_maps or set_game() and entity_maps
    local entity_map = entity_maps[surface_name]

    local chunk = entity_map[xy]
    if (not chunk) then
        chunk_maps = chunk_maps or set_game() and chunk_maps
        local chunk_map = chunk_maps[surface_name]

        chunk = chunk_map[xy]
        if (not chunk) then return end
        entity_map[xy] = chunk
    end

    chunk.meta = chunk.meta or new_template(Quad_Meta_Data, params.tick)
    -- log(serpent.block(chunk))
    -- log(serpent.block(chunk.xy))
    -- log(serpent.block(chunk.meta))
    if (chunk.meta.sleep_until and chunk.meta.sleep_until > params.tick) then return end

    local meta = chunk.meta

    local position = nil
    if (    meta.closest_spawner_chunk
        and (meta.closest_spawner_chunk.tick_returned or 0) >= (params.tick - X_MINUTES)
        and meta.closest_spawner_chunk.x
        and meta.closest_spawner_chunk.y
    ) then
        position = { x = meta.closest_spawner_chunk.x * CHUNK_SIZE + 16, y = meta.closest_spawner_chunk.y * CHUNK_SIZE + 16, }
    end

    if (not position) then
        stats_data = stats_data or set_game() and stats_data

        local closest_chunk = find_closest_spawner({
            tick = params.tick or 0,
            surface_name = surface_name,
            target_chunk = chunk,
            max_distance = meta.expanded_radius or nil
        })

        if (not closest_chunk) then
            meta.last_radius = nil
            local streak = (meta.fail_streak or 0) + 1
            meta.fail_streak = streak

            local curr_radius = meta.expanded_radius or 256
            meta.expanded_radius = math_min(curr_radius * 2, 1024 * CHUNK_SIZE)

            local sleep_duration = math_min(streak * streak * 60, 3600)
            meta.sleep_until = params.tick + sleep_duration

            meta.closest_spawner_chunk = nil
            return
        else
            meta.closest_spawner_chunk = closest_chunk
            meta.last_radius = (meta.last_radius or 256) + 64
            meta.tick = params.tick

            meta.sleep_until = nil
            meta.fail_streak = 0

            meta.closest_spawner_chunk = {
                tick_returned = params.tick,
                x = closest_chunk.x,
                y = closest_chunk.y,
                xy = closest_chunk.x .. "/" .. closest_chunk.y,
            }

            position = { x = closest_chunk.x * CHUNK_SIZE + 16, y = closest_chunk.y * CHUNK_SIZE + 16, }
        end
    end

    -- log(serpent.block(meta))
    if (not position) then return end

    surface_funcs = surface_funcs or set_game() and surface_funcs
    return surface_funcs[surface_name].find_entities_filtered({
        position = position,
        radius = 24,
        force = ENEMY,
        type = ENEMY_TYPES,
        limit = params.limit,
    })
end

function attack_group_utils.get_target_entity(params)
    -- Log.debug("attack_group_utils.get_target_entity")
    -- Log.info(params)

    if (not params) then return end
    if (not params.chunk) then return end
    if (not params.surface_name or not params.surface_name) then return end
    if (not params.limit and params.limit < 1) then params.limit = 1 end

    if (params.chunk.x and params.chunk.y) then
        surface_funcs = surface_funcs or set_game() and surface_funcs

        return surface_funcs[params.surface_name].find_entities_filtered({
            area = {
                { x = params.chunk.x * CHUNK_SIZE, y = params.chunk.y * CHUNK_SIZE, },
                { x = params.chunk.x * CHUNK_SIZE + CHUNK_SIZE, y = params.chunk.y * CHUNK_SIZE + CHUNK_SIZE, },
            },
            name = names,
            type = type_blacklist,
            limit = params.limit,
            force = PLAYER_FORCES,
            invert = true,
        })
    end
end

function attack_group_utils.init(__storage) storage = __storage or _ENV.storage end

return attack_group_utils
