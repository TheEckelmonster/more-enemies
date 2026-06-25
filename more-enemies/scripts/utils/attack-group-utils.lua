local storage
local chunks_arr
local chunk_maps
local difficulties
local spawner_maps
local stats_data
local surfaces

local game
local surface_funcs
local planetary_surfaces

local Planets = Planets

local Set_Game_Funcs = Set_Game_Funcs

local Stats_Data = require("scripts.data.stats-data")
local new_Stats_Data = Stats_Data.new

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

    Set_Game_Funcs()
    -- forces = _ENV.Forces
    -- force_funcs = _ENV.Force_Funcs

    planetary_surfaces = _ENV.Surfaces
    surface_funcs = _ENV.Surface_Funcs

    return game
end

local CHUNK_SIZE = Constants.CHUNK_SIZE

local math_min = math.min
local math_random = math.random

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
local find_closest_spawners = Quadtree_Service.find_closest_spawners
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

local PLAYER_FORCES = { "enemy", "neutral" }
local TICKS_PER_MINUTE = Constants.time.TICKS_PER_MINUTE
local X_MINUTES = 1.25 * TICKS_PER_MINUTE

function attack_group_utils.get_enemy(surface_name, chunk, tick)
    -- Log.debug("attack_group_utils.get_enemy")
    -- Log.info(params)

    if (not surface_name) then return end

    if (not chunk) then return end

    tick = tick or (game or set_game()).tick

    planetary_surfaces = planetary_surfaces or set_game() and planetary_surfaces
    local surface = planetary_surfaces and planetary_surfaces[surface_name] or nil
    if (not surface or not surface.valid) then return end

    difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty) then return end

    chunk.meta = chunk.meta or new_template(Quad_Meta_Data, tick)
    if (chunk.meta.sleep_until and chunk.meta.sleep_until > tick) then return end

    local meta = chunk.meta

    local position = nil
    if (    meta.closest_spawner_chunks
        and meta.closest_spawner_chunks[1]
        and (meta.closest_spawner_chunks.tick_returned or 0) >= (tick - X_MINUTES)
    ) then
        local count = #meta.closest_spawner_chunks
        local rand = count > 1 and math_random(count) or 1
        position = { x = meta.closest_spawner_chunks[rand].x * CHUNK_SIZE + 16, y = meta.closest_spawner_chunks[rand].y * CHUNK_SIZE + 16, }
    end

    if (not position) then
        stats_data = stats_data or set_game() and stats_data

        local closest_chunks = find_closest_spawners({
            tick = tick or 0,
            surface_name = surface_name,
            target_chunk = chunk,
            max_distance = meta.expanded_radius or nil,
            limit = 1 + selected_difficulty.value,
        })

        if (not closest_chunks or not closest_chunks[1]) then
            meta.last_radius = nil
            local streak = (meta.fail_streak or 0) + 1
            meta.fail_streak = streak

            local curr_radius = meta.expanded_radius or 256
            meta.expanded_radius = math_min(curr_radius * 2, 1024 * CHUNK_SIZE)

            local sleep_duration = math_min(streak * streak * 60, 3600)
            meta.sleep_until = tick + sleep_duration

            meta.closest_spawner_chunks = nil
            return
        else
            meta.last_radius = (meta.last_radius or 256) + 64
            meta.tick = tick

            meta.sleep_until = nil
            meta.fail_streak = 0

            local count = #closest_chunks
            meta.closest_spawner_chunks = closest_chunks
            local rand_chunk = count <= 1 and closest_chunks[1] or closest_chunks[math_random(count)]
            position = { x = rand_chunk.x * CHUNK_SIZE + 16, y = rand_chunk.y * CHUNK_SIZE + 16, }
        end
    end

    if (not position) then return end

    surface_funcs = surface_funcs or set_game() and surface_funcs
    return  surface_funcs
        and surface_funcs[surface_name].find_enemy_units
        and surface_funcs[surface_name].find_enemy_units(position, 24)
        or  nil
end

function attack_group_utils.get_target_entity(surface_name, chunk, limit)
    -- Log.debug("attack_group_utils.get_target_entity")
    -- Log.info(params)

    if (not surface_name) then return end
    if (not chunk) then return end
    if (not limit and limit < 1) then limit = 1 end

    if (chunk.x and chunk.y) then
        surface_funcs = surface_funcs or set_game()
        return  surface_funcs
            and surface_funcs[surface_name]
            and surface_funcs[surface_name].find_entities_filtered
            and surface_funcs[surface_name].find_entities_filtered({
                area = {
                    { x = chunk.x * CHUNK_SIZE, y = chunk.y * CHUNK_SIZE, },
                    { x = chunk.x * CHUNK_SIZE + CHUNK_SIZE, y = chunk.y * CHUNK_SIZE + CHUNK_SIZE, },
                },
                name = names,
                type = type_blacklist,
                limit = limit,
                force = PLAYER_FORCES,
                invert = true,
            })
            or  nil
    end
end

function attack_group_utils.init(__storage) storage = __storage or _ENV.storage end

return attack_group_utils
