local storage
local chunks_arr
local chunk_maps
local difficulties
local spawner_maps
local stats_data
local surfaces

local game
local get_surface

local Planets = Planets

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
    get_surface = game.get_surface

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
local Quadtree_Service = require("scripts.service.quadtree-service")
local find_closest = Quadtree_Service.find_closest
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

    local chunk = params.chunk
    if (not chunk) then return end

    local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty) then return end

    chunk.meta = chunk.meta or {}
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

        local closest_chunk = find_closest({
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

    if (not position) then return end

    return surface.find_entities_filtered({
        position = position,
        radius = 24,
        force = ENEMY,
        type = ENEMY_TYPES,
        limit = selected_difficulty.enemy_group_limit
            or (function (arr)
                arr[1].enemy_group_limit = arr[2]
                return arr[2] end)(
                {
                    selected_difficulty,
                    1 + 4 * selected_difficulty.value * selected_difficulty.radius_modifier + 4 * (
                            selected_difficulty.value_squared
                        or (function (arr)
                            arr[1].value_squared = arr[2]
                            return arr[2] end
                        )({ selected_difficulty, selected_difficulty.value ^ 2, })
                    )
                }
            )
            or nil,
    })
end

function attack_group_utils.get_target_entity(params)
    -- Log.debug("attack_group_utils.get_target_entity")
    -- Log.info(params)

    if (not params) then return end
    if (not params.chunk) then return end
    if (not params.surface or not params.surface.valid) then return end
    if (not params.limit and params.limit < 1) then params.limit = 1 end

    if (params.chunk.x and params.chunk.y) then
        return params.surface.find_entities_filtered({
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
