

local Data = require("__TheEckelmonster-core-library__.libs.data.data")

local Attack_Group_Constants = require("libs.constants.attack-group-constants")
local Constants = require("libs.constants.constants")
local Log = require("libs.log.log")
local Overmind_Repository = require("scripts.repositories.overmind-repository")
local Settings_Service = require("scripts.service.settings-service")
local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Constants = require("libs.constants.spawn-constants")

local cache = {}
cache.closest_spawners = {}
cache.spawner_tick = {}
cache.enemies = {}
cache.targets = {}

local cache_attributes = {}
setmetatable(cache_attributes, { __mode = "k" })

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

    local x = math.random(neg_x or -1, pos_x or 1)
    -- x = x - x % 1
    x = math.floor(x)

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

    local y = math.random(neg_y or -1, pos_y or 1)
    -- y = y - y % 1
    y = math.floor(y)

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

    if (    cache.enemies[chunk.x]
        and cache.enemies[chunk.x][chunk.y]
        and cache_attributes[cache.enemies[chunk.x]]
        and cache_attributes[cache.enemies[chunk.x]].time_to_live >= game.tick
        and cache_attributes[cache.enemies[chunk.x][chunk.y]]
        and cache_attributes[cache.enemies[chunk.x][chunk.y]].time_to_live >= game.tick
    ) then
        if (cache.enemies[chunk.x][chunk.y][1] and cache.enemies[chunk.x][chunk.y][1].valid) then
        -- if (    cache.enemies[chunk.x][chunk.y].list
        --     and cache.enemies[chunk.x][chunk.y].list[1]
        --     and cache.enemies[chunk.x][chunk.y].list[1].valid
        -- ) then
            Log.error("found cached enemy list")
            cache_attributes[cache.enemies[chunk.x][chunk.y]].time_to_live = game.tick + math.ceil((cache_attributes[cache.enemies[chunk.x][chunk.y]].time_to_live - game.tick) ^ 0.95)
            return cache.enemies[chunk.x][chunk.y]
        else
            cache.enemies[chunk.x][chunk.y] = nil
            if (not next(cache.enemies[chunk.x])) then cache.enemies[chunk.x] = nil end
        end
    end

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
    -- if (not enemies or not enemies.list or not enemies.list[1]) then
        return attack_group_utils.get_enemy(surface, chunk, 1.1 * radius + selected_difficulty.radius_modifier, depth + 1)
    end

    if (not cache.enemies[chunk.x] or not cache_attributes[cache.enemies[chunk.x]] or cache_attributes[cache.enemies[chunk.x]].time_to_live < game.tick) then
        cache.enemies[chunk.x] = cache.enemies[chunk.x] or {}
        cache_attributes[cache.enemies[chunk.x]] = Data:new({ time_to_live = game.tick + 3600 + Random(3600), valid = true })
    end

    if (not cache.enemies[chunk.x][chunk.y] or not cache_attributes[cache.enemies[chunk.x][chunk.y]] or cache_attributes[cache.enemies[chunk.x][chunk.y]].time_to_live < game.tick) then
        cache.enemies[chunk.x][chunk.y] = enemies
        cache_attributes[cache.enemies[chunk.x][chunk.y]] = Data:new({ time_to_live = game.tick + 1800 + Random(1800), valid = true })
    end

    -- if (not cache.enemies[chunk.x]) then cache.enemies[chunk.x] = {} end
    -- cache.enemies[chunk.x][chunk.y] = enemies

    return enemies
    -- return enemies.list
end

function attack_group_utils.get_target_entity(data)
    Log.debug("attack_group_utils.get_target_entity")
    Log.info(data)

    if (type(data) ~= "table") then return end
    -- if (not data.unit_group or not data.unit_group.valid) then return end
    -- if (not data.unit_group.surface or not data.unit_group.surface.valid) then return end
    if (type(data.chunk) ~= "table") then return end

    if (    cache.targets[data.chunk.x]
        and cache.targets[data.chunk.x][data.chunk.y]
        and cache_attributes[cache.targets[data.chunk.x]]
        and cache_attributes[cache.targets[data.chunk.x]].time_to_live >= game.tick
        and cache_attributes[cache.targets[data.chunk.x][data.chunk.y]]
        and cache_attributes[cache.targets[data.chunk.x][data.chunk.y]].time_to_live >= game.tick
    ) then
        if (cache.targets[data.chunk.x][data.chunk.y][1] and cache.targets[data.chunk.x][data.chunk.y][1].valid) then
            Log.error("found cached target list")
            if (#cache.targets[data.chunk.x][data.chunk.y] > 0) then
                table.remove(cache.targets[data.chunk.x][data.chunk.y])
            end
            cache_attributes[cache.targets[data.chunk.x][data.chunk.y]].time_to_live = game.tick + math.ceil((cache_attributes[cache.targets[data.chunk.x][data.chunk.y]].time_to_live - game.tick) ^ 0.95)
            return cache.targets[data.chunk.x][data.chunk.y]
        else
            cache.targets[data.chunk.x][data.chunk.y] = nil
            if (not next(cache.targets[data.chunk.x])) then cache.targets[data.chunk.x] = nil end
        end
    end

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
    if (not cache.targets[chunk.x] or not cache_attributes[cache.targets[chunk.x]] or cache_attributes[cache.targets[chunk.x]].time_to_live < game.tick) then
        cache.targets[chunk.x] = cache.targets[chunk.x] or {}
        cache_attributes[cache.targets[chunk.x]] = Data:new({ time_to_live = game.tick + 3600 + Random(3600), valid = true })
    end

    if (not cache.targets[chunk.x][chunk.y] or not cache_attributes[cache.targets[chunk.x][chunk.y]] or cache_attributes[cache.targets[chunk.x][chunk.y]].time_to_live < game.tick) then
        cache.targets[chunk.x][chunk.y] = targets
        cache_attributes[cache.targets[chunk.x][chunk.y]] = Data:new({ time_to_live = game.tick + 1800 + Random(1800), valid = true })
    end

    -- if (not cache.targets[chunk.x]) then cache.targets[chunk.x] = {} end
    -- cache.targets[chunk.x][chunk.y] = targets

    return targets
end

function attack_group_utils.get_closest_spawner(data)
    Log.debug("attack_group_utils.get_closest_spawner")
    Log.info(data)

    if (not data or type(data) ~= "table") then return end
    if (not data.chunk or type(data.chunk) ~= "table") then return end
    if (not data.surface or not data.surface.valid) then return end
    if (data.closest ~= nil and type(data.closest) ~= "boolean") then data.closest = false end

    local chunk = data.chunk
    local surface = data.surface
    local closest = data.closest

    local overmind = Overmind_Repository.get_overmind_data(surface.name)
    local source_spawner = nil
    local source_spawners = {}
    if (next(overmind.spawners, nil)) then

        Log.error(chunk.x .. " - " .. chunk.y)
        -- if (Cache and Cache.closest_spawners and Cache.closest_spawners[chunk.x] and Cache.closest_spawners[chunk.x][chunk.y]) then
        if (cache.closest_spawners and cache.closest_spawners[chunk.x] and cache.closest_spawners[chunk.x][chunk.y]) then
            Log.error("found cached spawners")
            local cached_spawner_data = cache.closest_spawners[chunk.x][chunk.y]

            if (closest and cached_spawner_data.spawner and cached_spawner_data.spawner.valid) then
                return cached_spawner_data.spawner
            end

            local num_spawners = #cached_spawner_data.spawners_ordered_array
            local rand = 1
            local spawner = nil
            if (num_spawners > 1) then
                rand = closest and 1 or math.random(num_spawners)
                spawner = table.remove(cached_spawner_data.spawners_ordered_array, rand)
            end
            -- local spawner = cached_spawner_data.spawners_ordered_array[rand]
            -- local spawner = table.remove(cached_spawner_data.spawners_ordered_array, rand)
            while #cached_spawner_data.spawners_ordered_array > 1 and (not spawner or not spawner.valid) do
                -- table.remove(cached_spawner_data.spawners_ordered_array, rand)
                rand = closest and 1 or math.random(#cached_spawner_data.spawners_ordered_array)
                -- spawner = cached_spawner_data.spawners_ordered_array[rand]
                spawner = table.remove(cached_spawner_data.spawners_ordered_array, rand)
                if (spawner and spawner.valid) then
                    if (cache.spawner_tick[spawner.unit_number] and cache.spawner_tick[spawner.unit_number] > game.tick) then
                        spawner = nil
                    end
                end
            end
            if (spawner and spawner.valid) then
                Log.error("1: found valid random spawner")
                source_spawner = spawner
                cache.spawner_tick[spawner.unit_number] = game.tick + math.random(30, 1800)
            end
        end

        -- Log.error(source_spawner)

        if (not source_spawner) then
            local min_distance = math.huge
            for unit_number, spawner in pairs(overmind.spawners) do
                if (spawner.valid) then
                    if (cache.spawner_tick[unit_number] and cache.spawner_tick[unit_number] <= game.tick) then
                        cache.spawner_tick[unit_number] = nil
                    end
                    local distance = ((spawner.position.x - (chunk.x * 32 + 16)) ^ 2 + (spawner.position.y - (chunk.y * 32 + 16)) ^ 2) ^ 0.5
                    if (distance < min_distance) then
                        min_distance = distance
                        source_spawner = spawner
                        if (#source_spawners < 2 ^ 5) then
                            table.insert(source_spawners, 1, spawner)
                            while #source_spawners > 2 ^ 5 do
                                table.remove(source_spawners)
                            end
                        end
                    end
                else
                    overmind.spawners[unit_number] = nil
                    if (overmind.spawner_count >= 1) then overmind.spawner_count = overmind.spawner_count - 1 end
                end
            end

            if (source_spawner and source_spawner.valid) then
                -- if (not Cache.closest_spawners) then Cache.closest_spawners = cache.closest_spawners end
                -- cache.closest_spawners = Cache.closest_spawners
                -- if (not cache) then cache = {} end
                -- if (not cache.closest_spawners) then cache.closest_spawners = {} end
                if (not cache.closest_spawners[chunk.x]) then cache.closest_spawners[chunk.x] = {} end
                cache.closest_spawners[chunk.x][chunk.y] = {
                    position = {
                        x = source_spawner.position.x,
                        y = source_spawner.position.y
                    },
                    spawner = source_spawner,
                    spawners_ordered_array = source_spawners,
                }
            end
        end
    end

    -- Log.error(source_spawner)

    if (#source_spawners > 1) then
        local rand = closest and 1 or math.random(#source_spawners)
        -- local spawner = source_spawners[rand]
        local spawner = table.remove(source_spawners, rand)
        while #source_spawners > 1 and (not spawner or not spawner.valid) do
            -- table.remove(source_spawners, rand)
            rand = closest and 1 or math.random(#source_spawners)
            -- spawner = source_spawners[rand]
            spawner = table.remove(source_spawners, rand)
            if (spawner and spawner.valid) then
                if (cache.spawner_tick[spawner.unit_number] and cache.spawner_tick[spawner.unit_number] > game.tick) then
                    spawner = nil
                end
            end
        end
        if (spawner and spawner.valid) then
            Log.error("2: found valid random spawner")
            source_spawner = spawner
            cache.spawner_tick[spawner.unit_number] = game.tick + math.random(30, 1800)
        end
    end

    Log.error(source_spawner)

    return source_spawner
end

return attack_group_utils
