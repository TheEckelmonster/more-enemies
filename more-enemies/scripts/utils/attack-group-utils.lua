local storage

local next = next
local type = type

local math_floor = math.floor
local math_random = math.random

local Attack_Group_Constants = require("libs.constants.attack-group-constants")
local Constants = require("libs.constants.constants")
local Log = require("libs.log.log")
local Settings_Service = require("scripts.service.settings-service")
local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Constants = require("libs.constants.spawn-constants")

local attack_group_utils = {}

function attack_group_utils.get_new_chunk(attack_group, planet, chunk, depth)
    Log.debug("attack_group_utils.get_new_chunk")
    Log.info(attack_group)
    Log.info(planet)
    Log.info(chunk)
    Log.info(depth)

    if (not type(attack_group) == "table") then return end
    if (not planet or planet == nil) then return end
    if (not chunk or chunk == nil) then return end
    if (not depth or depth == nil) then depth = 1 end

    -- if (depth > 12) then
    if (depth > 10) then
        Log.error("could not find a new chunk")
        return
    end

    if (not attack_group) then return end

    if (chunk.x > 0 and chunk.x > attack_group.max_distance.pos_x) then attack_group.max_distance.pos_x = chunk.x end
    if (chunk.y > 0 and chunk.y > attack_group.max_distance.pos_y) then attack_group.max_distance.pos_y = chunk.y end

    if (chunk.x < 0 and chunk.x < attack_group.max_distance.neg_x) then attack_group.max_distance.neg_x = chunk.x end
    if (chunk.y < 0 and chunk.y < attack_group.max_distance.neg_y) then attack_group.max_distance.neg_y = chunk.y end


    local neg_x = -1

    if (not attack_group.max_distance.neg_x or attack_group.max_distance.neg_x == nil) then
        attack_group.max_distance.neg_x = -1
    end

    if (attack_group.max_distance.neg_x) then
        neg_x = attack_group.max_distance.neg_x
    end

    local pos_x = 1

    if (not attack_group.max_distance.pos_x or attack_group.max_distance.pos_x == nil) then
        attack_group.max_distance.pos_x = 1
    end

    if (attack_group.max_distance.pos_x) then
        pos_x = attack_group.max_distance.pos_x
    end

    local x = math_random(neg_x or -1, pos_x or 1)
    -- x = x - x % 1
    x = math_floor(x)

    local neg_y = -1

    if (not attack_group.max_distance.neg_y or attack_group.max_distance.neg_y == nil) then
        attack_group.max_distance.neg_y = -1
    end

    if (attack_group.max_distance.neg_y) then
        neg_y = attack_group.max_distance.neg_y
    end

    local pos_y = 1

    if (not attack_group.max_distance.pos_y or attack_group.max_distance.pos_y == nil) then
        attack_group.max_distance.pos_y = 1
    end

    if (attack_group.max_distance.pos_y) then
        pos_y = attack_group.max_distance.pos_y
    end

    local y = math_random(neg_y or -1, pos_y or 1)
    -- y = y - y % 1
    y = math_floor(y)

    chunk.x = x
    chunk.y = y

    local surface = game.surfaces[planet.string_val]

    if (surface and surface.valid and not surface.is_chunk_generated({ x, y })) then
        if (x > 0) then
            if (attack_group.max_distance.pos_x > 2) then
            attack_group.max_distance.pos_x = attack_group.max_distance.pos_x / 2
            end
        else
            if (attack_group.max_distance.neg_x > 2) then
            attack_group.max_distance.neg_x = attack_group.max_distance.neg_x / 2
            end
        end

        if (y > 0) then
            if (attack_group.max_distance.pos_y > 2) then
            attack_group.max_distance.pos_y = attack_group.max_distance.pos_y / 2
            end
        else
            if (attack_group.max_distance.neg_y > 2) then
            attack_group.max_distance.neg_y = attack_group.max_distance.neg_y / 2
            end
        end

        Log.warn("chunk not generated - getting new chunk")
        return attack_group_utils.get_new_chunk(attack_group, planet, surface.get_random_chunk(), depth + 1)
    end

    if (not attack_group.chunks[x]) then
        attack_group.chunks[x] = {}
        attack_group.chunks[x][y] = {
            tick = game.tick + 9000,
            count = 1,
        }
    else
        if (not attack_group.chunks[x][y]) then
            attack_group.chunks[x][y] = {
                tick = game.tick + 9000,
                count = 1
            }
        elseif (type(attack_group.chunks[x][y].tick) == "number" and game.tick >= attack_group.chunks[x][y].tick) then
            if (attack_group.chunks[x][y].count > 1) then
                attack_group.chunks[x][y].tick = game.tick + 36000 / attack_group.chunks[x][y].count
            else
                attack_group.chunks[x][y].tick = game.tick + 36000
            end

            if (attack_group.chunks[x][y].count > 2) then
                attack_group.chunks[x][y].count = attack_group.chunks[x][y].count / 2
            end
        else
            attack_group.chunks[x][y].count = attack_group.chunks[x][y].count + 1

            Log.debug("getting new chunk")

            attack_group.max_distance.pos_x = attack_group.max_distance.pos_x + 1
            attack_group.max_distance.pos_y = attack_group.max_distance.pos_y + 1
            attack_group.max_distance.neg_x = attack_group.max_distance.neg_x - 1
            attack_group.max_distance.neg_y = attack_group.max_distance.neg_y - 1

            return attack_group_utils.get_new_chunk(attack_group, planet, surface.get_random_chunk(), depth + 1)
        end
    end

    chunk.surface = surface.valid and surface

    return chunk
end

function attack_group_utils.get_enemy(surface, chunk, radius, depth)
    Log.debug("attack_group_utils.get_enemy")
    Log.info(surface)
    Log.info(chunk)
    Log.info(radius)
    Log.info(depth)

    if (not surface or not surface.valid) then return end
    if (not chunk or chunk == nil) then return end
    if (not radius or radius == nil) then radius = 1 end
    if (not depth or depth == nil) then depth = 1 end

    if (radius > (Constants.CHUNK_SIZE / 1.5) * 6 and depth > 1) then return end

    -- if (depth > 12) then
    if (depth > 6) then
        Log.error("could not find an enemy")
        return
    end

    local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(surface.name)]]

    local limit = 1 + 4 * depth * selected_difficulty.value * selected_difficulty.radius_modifier + 4 * (selected_difficulty.value ^ 2)

    -- local enemies = {}
    -- enemies.list = surface.find_entities_filtered({
    local enemies = surface.find_entities_filtered({
        -- position = { x = chunk.x * 32, y = chunk.y * 32 },
        position = { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE / 2, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE / 2 },
        radius = 4 * radius * selected_difficulty.radius_modifier + selected_difficulty.radius / 1.5,
        name = Spawn_Constants.name,
        force = "enemy",
        type = "unit",
        limit = limit,
        -- collision_mask = "more_enemies",
    })

    if (not enemies or not enemies[1]) then
        return attack_group_utils.get_enemy(surface, chunk, 1.1 * radius + selected_difficulty.radius_modifier, depth + 1)
    end

    return enemies
end

function attack_group_utils.get_target_entity(data)
    Log.debug("attack_group_utils.get_target_entity")
    Log.info(data)

    if (type(data) ~= "table") then return end
    -- if (not data.unit_group or not data.unit_group.valid) then return end
    -- if (not data.unit_group.surface or not data.unit_group.surface.valid) then return end
    if (type(data.chunk) ~= "table") then return end

    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.chunk.surface) ~= "userdata" or not data.chunk.surface.valid) then return end
    if (type(data.evolution_factor) ~= "number") then data.evolution_factor = 0.5 end
    if (type(data.radius) ~= "number") then data.radius = 1 end
    if (type(data.depth) ~= "number") then data.depth = 1 end
    if (type(data.limit) ~= "number" or data.limit < 1) then data.limit = 1 end
    local sources = {
        ["random"] = 1,
        ["targeted"] = 1,
        ["personal_space"] = 1,
    }
    if (type(data.source) ~= "string" or not sources[data.source]) then return end
    -- if (type(data.max_depth) ~= "number") then data.max_depth = 12 end
    if (type(data.max_depth) ~= "number" or data.max_depth > 6) then data.max_depth = 6 end

    local selected_difficulty = data.selected_difficulty
    local evolution_factor = data.evolution_factor
    local root = 1 / selected_difficulty.value
    local source = data.source
    local radius = data.radius
    local depth = data.depth
    local max_depth  = data.max_depth
    -- local unit_group = data.unit_group

    local distance_limit = (Constants.CHUNK_SIZE / 1.5) * 12

    if (source == "targeted") then
        -- distance_limit = ((selected_difficulty.value - selected_difficulty.value / (math.pi / 2) * ((0 - 1) * atan + math.pi / 2)) ^ 2) / selected_difficulty.value
        distance_limit = selected_difficulty.value * ((evolution_factor ^ root) ^ (selected_difficulty.value / selected_difficulty.radius_modifier)) + ((selected_difficulty.value - selected_difficulty.value/(math.pi / 2) * ((0 - 1) * math.atan((1 / selected_difficulty.value) * (((evolution_factor ^ root) * 10) ^ 2)) + math.pi / 2)) ^ 2) / (selected_difficulty.value / 2)
        -- distance_limit = ((selected_difficulty.value - selected_difficulty.value / (3.141592653 / 2)((0 - 1) * math.atan((1 / selected_difficulty.value) * (evolution_factor * 10) ^ 2) + 3.141592653 / 2)) ^ 2) / selected_difficulty.value

    elseif (source == "personal_space") then
        -- Log.error(data)
        distance_limit = selected_difficulty.value * ((evolution_factor ^ root) ^ (selected_difficulty.value / selected_difficulty.radius_modifier)) + (((selected_difficulty.value - selected_difficulty.value/(math.pi / 2) * ((0 - 1) * math.atan((1 / selected_difficulty.value) * (((evolution_factor ^ root) * 10) ^ 2)) + math.pi / 2)) ^ 2) / selected_difficulty.value) / (Constants.e / selected_difficulty.radius_modifier)
        -- Log.error(distance_limit)
        -- log("distance_limit = " .. distance_limit)
    end

    if (depth > max_depth) then return end
    if (radius > (Constants.CHUNK_SIZE / 1.5) * 12 and depth > 1) then return end

    if (radius > distance_limit) then
        -- Log.error(radius)
        -- radius = distance_limit * selected_difficulty.radius_modifier
        radius = distance_limit
    end

    local names = {}
    local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

    if (blacklist_names) then
        for _, v in pairs(blacklist_names) do
            table.insert(names, v)
        end
    end

    if (next(names, nil) == nil) then names = nil end

    local chunk = data.chunk
    local position = nil
    local targets = nil

    if (type(chunk) == "table" and type(chunk.x) == "number" and type(chunk.y) == "number") then
        -- Log.error("targeted attack")
        -- Log.error(source)
        position = {
            -- x = chunk.x * Constants.CHUNK_SIZE,
            -- y = chunk.y * Constants.CHUNK_SIZE
            x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE / 2,
            y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE / 2,
        }

        targets = data.chunk.surface.find_entities_filtered({
            position = position,
            -- radius = (Constants.CHUNK_SIZE / 1.5) * radius * selected_difficulty.radius_modifier + depth,
            radius = radius * selected_difficulty.radius_modifier + depth,
            name = names,
            type = Attack_Group_Constants.type_blacklist,
            limit = data.limit,
            force = { "enemy", "neutral" },
            invert = true,
        })
    end

    if (radius > distance_limit) then depth = max_depth end

    data.radius = 1.1 * radius + selected_difficulty.radius_modifier
    data.depth = depth + 1
    if (not targets or not targets[1]) then return attack_group_utils.get_target_entity(data) end

    Log.debug("found 'em")
    return targets
end

function attack_group_utils.init(__storage)
    storage = __storage
end

return attack_group_utils
