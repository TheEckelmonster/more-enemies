local storage
local game
local get_surface

local function set_game(__game)
    game = __game or _ENV.game
    get_surface = game.get_surface

    return game
end

local math_huge = math.huge

local next = next
local type = type

local pairs = pairs

local Log = Log

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Attack_Group_Constants = require("libs.constants.attack-group-constants")
local Constants = require("libs.constants.constants")
local Settings_Service = require("scripts.service.settings-service")
local get_difficulty = Settings_Service.get_difficulty
local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Constants = require("libs.constants.spawn-constants")

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table.insert(names, v)
    end
end

if (next(names, nil) == nil) then names = nil end

local attack_group_utils = {}

function attack_group_utils.get_enemy(params)
    -- Log.debug("attack_group_utils.get_enemy")
    -- Log.info(params)

    local surface_name = params.surface_name
    if (not surface_name) then return end

    local chunk = params.chunk
    if (not chunk) then return end

    local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    storage.difficulties = storage.difficulties or {}
    storage.difficulties[surface_name] = storage.difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])

    local selected_difficulty = storage.difficulties[surface_name]
    if (not selected_difficulty) then return end

    chunk.spawner_count = chunk.spawner_count or 0

    local position = nil
    if (chunk.closest_spawner_chunk) then position = { x = chunk.closest_spawner_chunk.x * Constants.CHUNK_SIZE + 16, y = chunk.closest_spawner_chunk.y * Constants.CHUNK_SIZE + 16, } end
    if (not position) then
        local closest_chunk = attack_group_utils.get_closest_spawner({ surface_name = surface_name, chunk = chunk, tick = params.tick, })
        if (not closest_chunk) then return end
        position = { x = closest_chunk.x * Constants.CHUNK_SIZE + 16, y = closest_chunk.y * Constants.CHUNK_SIZE + 16, }
    end

    if (not position) then return end

    return surface.find_entities_filtered({
        position = position,
        radius = 24,
        name = Spawn_Constants.name,
        force = "enemy",
        type = { "unit", "spider-unit", },
        limit = selected_difficulty.enemy_group_limit or (function (param)
            selected_difficulty.enemy_group_limit = param
            return param
        end)(1 + 4 * selected_difficulty.value * selected_difficulty.radius_modifier + 4 * (selected_difficulty.value ^ 2)) or nil,
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
                { x = params.chunk.x * Constants.CHUNK_SIZE, y = params.chunk.y * Constants.CHUNK_SIZE, },
                { x = params.chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = params.chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
            },
            name = names,
            type = Attack_Group_Constants.type_blacklist,
            limit = params.limit,
            force = { "enemy", "neutral" },
            invert = true,
        })
    end
end

function attack_group_utils.get_closest_spawner(params)
    -- log(serpent.block("attack_group_utils.get_closest_spawner"))

    if (not params) then return end

    local surface_name = params.surface_name
    if (not params.surface_name) then return end

    local source_chunk = params.chunk
    if (not source_chunk) then return end

    storage.surfaces = storage.surfaces or {}
    storage.surfaces[surface_name] = storage.surfaces[surface_name] or {}

    storage.surfaces[surface_name].spawner_map = storage.surfaces[surface_name].spawner_map or {}
    local spawner_map = storage.surfaces[surface_name].spawner_map

    storage.surfaces[surface_name].chunk_map = storage.surfaces[surface_name].chunk_map or {}
    local chunk_map = storage.surfaces[surface_name].chunk_map
    chunk_map.levels = chunk_map.levels or {}

    if (source_chunk.closest_spawner_chunk) then
        source_chunk.closest_spawner_chunk.tick_returned = source_chunk.closest_spawner_chunk.tick_returned or params.tick
        if (source_chunk.closest_spawner_chunk.tick_returned >= (params.tick - (2.25 * Constants.TICKS_PER_MINUTE))) then
            return source_chunk.closest_spawner_chunk
        end
    end
    source_chunk.closest_spawner_chunk = nil

    local distance = math_huge
    local min_distance = math_huge

    for _xy, _chunk in pairs(spawner_map) do
        if (_chunk.spawner_count > 0) then
            distance = ((source_chunk.x - _chunk.x) ^ 2 + (source_chunk.y - _chunk.y) ^ 2) ^ 0.5
            if (distance <  min_distance) then
                min_distance = distance
                source_chunk.closest_spawner_chunk = _chunk
            end
        end
    end

    return source_chunk.closest_spawner_chunk
end

function attack_group_utils.init(__storage)
    storage = __storage
end

return attack_group_utils
