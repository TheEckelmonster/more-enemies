local storage

local Data = require("__TheEckelmonster-core-library__.libs.data.data")

local Attack_Group_Constants = require("libs.constants.attack-group-constants")
local Attack_Group_Repository = require("scripts.repositories.attack-group-repository")
local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
-- local Cache_Data = require("scripts.data.cache-data")
local Constants = require("libs.constants.constants")
-- local Chunk_Utils = require("scripts.utils.chunk_utils")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")
local Log = require("libs.log.log")
local Settings_Service = require("scripts.service.settings-service")
local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Constants = require("libs.constants.spawn-constants")
local Unit_Group_Utils = require("scripts.utils.unit-group-utils")

local locals = {}

local attack_group_service = {}

attack_group_service.attack_group = {}

local cache = {}
local cache_attributes = {}
setmetatable(cache_attributes, { __mode = "k" })

cache.do_random_attack_group = {
    chunks = {},
}
function attack_group_service.do_random_attack_group(data)
    Log.error("attack_group_service.do_random_attack_group")
    Log.info(data)

    if (type(data) ~= "table") then  return end
    if (not game or not game.surfaces) then return end
    if (type(data.planet) ~= "table" or type(data.planet.string_val) ~= "string") then return end
    local planet = data.planet
    local surface = game.surfaces[planet.string_val]
    if (not surface or not surface.valid) then return end
    if (type(data.event) ~= "number") then data.event = -1 end

    local attack_group_data = Attack_Group_Repository.get_attack_group_data(planet.string_val)
    if (not attack_group_service.attack_group[planet.string_val]) then
        -- local attack_group_data = Attack_Group_Repository.get_attack_group_data(planet.string_val)
        if (not attack_group_data.peace_time_tick or attack_group_data.peace_time_tick == nil) then
            local peace_time_tick = Settings_Service.get_attack_group_peace_time(planet.string_val) * Constants.time.TICKS_PER_MINUTE
            if (type(attack_group_data.surface) == "table" and attack_group_data.surface.index == 1) then
                attack_group_data.peace_time_tick = peace_time_tick
                attack_group_data.tick = peace_time_tick
            else
                attack_group_data.peace_time_tick = peace_time_tick
                attack_group_data.tick = attack_group_data.created + peace_time_tick
            end
        end

        -- attack_group_service.attack_group[planet.string_val] = attack_group_data
    end

    -- if (attack_group_service.attack_group and attack_group_service.attack_group[planet.string_val] and attack_group_service.attack_group[planet.string_val].tick and game and game.tick >= attack_group_service.attack_group[planet.string_val].tick) then
    if (attack_group_data and attack_group_data.tick and game and game.tick >= attack_group_data.tick) then

        local surface = game.surfaces[planet.string_val]
        if (surface and surface.valid) then
            -- local attack_group = attack_group_service.attack_group[planet.string_val]
            local attack_group = attack_group_data

            local chunk = locals.get_new_chunk(planet, surface.get_random_chunk())

            if (chunk) then
                Log.debug(planet.string_val)
                Log.debug(chunk)
                Log.debug(attack_group.radius)

                -- local source_spawner = nil
                local source_spawner = Attack_Group_Utils.get_closest_spawner({
                    chunk = chunk,
                    surface = surface,
                })

                local source_chunk = chunk
                if (source_spawner and source_spawner.valid) then
                    source_chunk = {
                        x = math.floor(source_spawner.position.x / 32),
                        y = math.floor(source_spawner.position.y / 32),
                    }
                end

                -- local enemies = Attack_Group_Utils.get_enemy(surface, chunk, attack_group.radius)
                local enemies = Attack_Group_Utils.get_enemy(surface, source_chunk, attack_group.radius)
                if (enemies and enemies[1] and enemies[1].valid) then
                    -- Log.debug(enemies)
                    Log.error(enemies[1])

                    local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(planet.string_val)]]

                    if (Settings_Service.get_attack_group_require_nearby_spawner(planet.string_val)) then
                        -- local spawner = Unit_Group_Utils.get_spawner(enemies[1], 4 * attack_group.radius, 1)
                        -- local spawner = source_spawner or Attack_Group_Utils.get_closest_spawner({
                        local spawner = Attack_Group_Utils.get_closest_spawner({
                            chunk = {
                                x = math.floor(enemies[1].position.x / 32),
                                y = math.floor(enemies[1].position.y / 32),
                            },
                            surface = surface,
                            closest = true,
                        })

                        if (not spawner or spawner == nil) then goto finally end
                        if (spawner and spawner.valid) then
                            local distance = ((spawner.position.x - enemies[1].position.x) ^ 2 + (spawner.position.y - enemies[1].position.y) ^ 2) ^ 0.5
                            if (distance > Constants.CHUNK_SIZE * (selected_difficulty.value ^ 0.75)) then goto finally end
                        end
                    end

                    -- local evolution_factor = enemies[1].force.get_evolution_factor(enemies[1].surface)
                    local evolution_factor = enemies[1].force.get_evolution_factor(enemies[1].surface)
                    local _evolution_factor = evolution_factor
                    evolution_factor = evolution_factor ^ (1 / selected_difficulty.value)

                    local rand = math.random()

                    local probability_modifier = Settings_Service.get_spawn_attack_group_probability_modifier(planet.string_val)

                    -- -- Maximum probability of an attack group spawning at 100% (1) evolution factor
                    -- local max_probability = 1 - (1 / selected_difficulty.value)

                    -- if (max_probability < 0) then max_probability = 0 end

                    -- max_probability = max_probability * probability_modifier

                    -- local threshold = max_probability * evolution_factor
                    -- Log.debug(threshold)
                    -- Log.debug(rand)

                    -- Maximum probability of an attack group spawning at 100% (1) evolution factor
                    local max_probability = 1 - (1 / selected_difficulty.value)

                    -- local max_probability_diff = 1 - max_probability
                    -- local max_probability_modifier = (math.random(max_probability_diff * 1000) / 1000) * evolution_factor
                    -- log(max_probability_modifier)

                    if (max_probability < 0) then max_probability = 0 end

                    max_probability = max_probability * probability_modifier

                    local threshold = max_probability * evolution_factor
                    -- Log.error(threshold)
                    -- Log.error(threshold + max_probability_modifier)
                    -- Log.error(rand)

                    -- if (rand >= threshold) then
                    --     -- return
                    --     goto finally
                    -- end

                    local retries = math.floor((selected_difficulty.value * 3) ^ 0.5)

                    local proceed = false
                    for i = 1, retries, 1 do
                        if (rand < threshold) then
                            proceed = true
                            break
                        end
                        threshold = threshold ^ 0.9
                        rand = math.random()
                    end

                    if (not proceed) then Log.error("proceed = false"); goto finally end

                    local unit_group = surface.create_unit_group({ position = enemies[1].position})
                    if (unit_group and unit_group.valid) then

                        local limit = 2 * (selected_difficulty.value * selected_difficulty.radius_modifier) * evolution_factor + math.random(#enemies)

                        for k, v in pairs(enemies) do
                            if (v and v.valid) then
                                v.release_from_spawner()
                                v.ai_settings.allow_try_return_to_spawner = false
                                v.ai_settings.join_attacks = true
                                unit_group.add_member(v)
                            end
                            if (k >= limit) then break end
                        end

                        if (not cache.do_random_attack_group.chunks[source_chunk.x] or not cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x]] or cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x]].time_to_live < game.tick) then
                            cache.do_random_attack_group.chunks[source_chunk.x] = {}
                            cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x]] = Data:new({ time_to_live = game.tick + 18000 + Random(18000), valid = true })
                        end

                        if (not cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y] or not cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y]] or cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y]].time_to_live < game.tick) then
                            cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y] = {}
                            cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y]] = Data:new({ time_to_live = game.tick + 9000 + Random(9000), valid = true })
                        end

                        local chunk_with = cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y].chunk_with

                        local entities = nil
                        if (chunk_with) then
                            Log.error("found chunk")
                            Log.error("x = " .. chunk_with.x .. ", y = " .. chunk_with.y)
                            Log.error("chunk_size = " .. chunk_with.chunk_size)
                            Log.error("entities = " .. chunk_with.parent.entity_count)
                            -- log(serpent.block(chunk_with.parent.entities))
                            entities = {}
                            for k, v in pairs(chunk_with.parent.entities) do
                                -- log(k)
                                -- log(serpent.block(v))
                                table.insert(entities, v.entity)
                            end
                            chunk_with.parent.entity_count = #entities
                        else
                            if (not chunk_with or chunk_with.chunk_size > 32) then
                                Log.error("going to finally")
                                goto finally
                            end
                        end

                        -- local target_entities = {}
                        -- if (chunk_with) then
                        --     for _, v in pairs(chunk_with.entities) do
                        --         table.insert(target_entities, v)
                        --     end
                        -- end

                        if (   not cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y].target_entities
                            or not cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y].target_entities]
                            or cache_attributes[cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y].target_entities].time_to_live < game.tick
                        ) then
                            local target_entities = entities or Attack_Group_Utils.get_target_entity({
                                source = "random",
                                selected_difficulty = selected_difficulty,
                                evolution_factor = evolution_factor,
                                chunk = chunk_with or chunk,
                                -- radius = 16 * attack_group.radius,
                                radius = attack_group.radius * selected_difficulty.radius_modifier,
                                limit = 1 + selected_difficulty.value * selected_difficulty.radius_modifier * evolution_factor,
                            })
                            if (target_entities) then
                                cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y].target_entities = target_entities
                                cache_attributes[target_entities] = Data:new({ time_to_live = game.tick + 900 + Random(900), valid = true })
                            end
                        end


                        -- local target_entities = Attack_Group_Utils.get_target_entity({
                        local target_entities = cache.do_random_attack_group.chunks[source_chunk.x][source_chunk.y].target_entities
                        -- local target_entities = entities or Attack_Group_Utils.get_target_entity({
                        --     source = "random",
                        --     selected_difficulty = selected_difficulty,
                        --     evolution_factor = evolution_factor,
                        --     chunk = chunk_with or chunk,
                        --     -- radius = 16 * attack_group.radius,
                        --     radius = attack_group.radius * selected_difficulty.radius_modifier,
                        --     limit = 1 + selected_difficulty.value * selected_difficulty.radius_modifier * evolution_factor,
                        -- })
                        -- local target_entities = Attack_Group_Utils.get_target_entity({
                        --     source = "random",
                        --     selected_difficulty = selected_difficulty,
                        --     evolution_factor = evolution_factor,
                        --     chunk = chunk,
                        --     radius = attack_group.radius,
                        --     limit = 1 + selected_difficulty.value * selected_difficulty.radius_modifier * evolution_factor,
                        -- })

                        local target_entity = nil
                        if (target_entities and #target_entities > 0) then
                            Log.error("target_entities = " .. #target_entities)
                            -- target_entity = target_entities[math.random(#target_entities)]
                            target_entity = table.remove(target_entities, math.random(#target_entities))
                            for _, v in pairs(target_entities) do
                                -- Log.error(v)
                                if (v and v.valid and v.name == "character") then
                                    Log.error("found character")
                                    target_entity = v
                                    break
                                end
                            end
                        end

                        if (target_entity and target_entity.valid) then

                            attack_group.chunks[chunk.x][chunk.y].tick = game.tick + 3600

                            local x = enemies[1].position.x / 32
                            -- x = x - x % 1
                            x = math.floor(x)

                            local y = enemies[1].position.y / 32
                            -- y = y - y % 1
                            y = math.floor(y)

                            if (x > 0 and x > attack_group.max_distance.pos_x) then attack_group.max_distance.pos_x = x end
                            if (y > 0 and y > attack_group.max_distance.pos_y) then attack_group.max_distance.pos_y = y end

                            if (x < 0 and x < attack_group.max_distance.neg_x) then attack_group.max_distance.neg_x = x end
                            if (y < 0 and y < attack_group.max_distance.neg_y) then attack_group.max_distance.neg_y = y end

                            if (not attack_group.chunks[x]) then attack_group.chunks[x] = {} end
                            if (not attack_group.chunks[x][y]) then attack_group.chunks[x][y] = { tick = 0, count = 1 } end
                            attack_group.chunks[x][y].tick = game.tick + 18000

                            -- Log.error("random: target_entity")
                            -- Log.error(target_entity)
                            game.print({ "messages.entity-gps", target_entity.name, target_entity.position.x, target_entity.position.y, target_entity.surface.name })

                            -- Log.info(attack_group.chunks)
                            -- log(serpent.block(attack_group.chunks))

                            if (target_entity and target_entity.valid) then

                                local radius_mult = math.random() + 0.25

                                unit_group.set_command({
                                    type = defines.command.attack_area,
                                    destination = target_entity.position,
                                    -- radius = 32 * 0.25, -- TODO: Make this configurable,
                                    radius = 24 * radius_mult, -- TODO: Make this configurable,
                                    distraction = defines.distraction.by_damage,
                                })
                                unit_group.release_from_spawner()
                                unit_group.start_moving()
                                Log.debug("unit group released")
                            else
                                Log.warn("no target; destroying")
                                unit_group.destroy()
                            end

                            if (attack_group.radius > 2) then
                                attack_group.radius = attack_group.radius / 2
                            end
                        end
                    end
                end

                ::finally::

                local delay_min = Settings_Service.get_minimum_attack_group_delay()
                local delay_max = Settings_Service.get_maximum_attack_group_delay()

                if (delay_min > delay_max) then
                    delay_min = Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.default_value
                end

                if (delay_max < delay_min ) then
                    delay_max = Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.default_value
                end

                local delay = math.random(delay_min, delay_max)
                -- log("error: delay")
                Log.debug(delay)

                local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(planet.string_val)]]
                local difficulty_val = Constants.difficulty.INSANITY.value

                if (selected_difficulty and selected_difficulty.value and selected_difficulty.value > 0) then
                    local evolution_factor = game.forces["enemy"] and game.forces["enemy"].valid and game.forces["enemy"].get_evolution_factor(planet.string_val) or 0.5
                    -- delay = delay / (selected_difficulty.value * (1 + ((evolution_factor ^ 0.75) / 2)))
                    delay = delay / ((selected_difficulty.radius_modifier ^ 2) * (0.5 + ((evolution_factor ^ 0.75) / 2)))
                    difficulty_val = selected_difficulty.value

                    Log.debug(delay)
                end

                if (attack_group.radius < delay * difficulty_val) then
                    attack_group.radius = 1.1 * attack_group.radius + 1
                    -- if (attack_group.radius > Constants.CHUNK_SIZE * 8) then attack_group.radius = Constants.CHUNK_SIZE * 8 end
                    local max_radius = (Constants.CHUNK_SIZE / 1.5) * selected_difficulty.radius_modifier
                    if (attack_group.radius > max_radius) then attack_group.radius = max_radius end
                end
                attack_group.tick = game.tick + delay
            end
        end
    end

    return true
end

function attack_group_service.init(__storage)
    storage = __storage
end

return attack_group_service