

local Data = require("__TheEckelmonster-core-library__.libs.data.data")

local Chunk_Data = require("scripts.data.chunk-data.chunk-data")
local Constants = require("scripts.constants.constants")
local Log = require("libs.log.log")
-- local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Overmind_Data = require("scripts.data.overmind-data")
local Overmind_Repository = require("scripts.repositories.overmind-repository")
local Overmind_Target_Priorities = require("libs.constants.overmind.overmind-target-priorities")
local Pollution_Data = require("scripts.data.chunk-data.pollution-data")
-- local Queue_Data = require("scripts.data.structures.queue-data")
local Recent_Death_Data = require("scripts.data.chunk-data.recent-deaths-data")
local Staged_Chunk_Data = require("scripts.data.chunk-data.staged-chunk-data")
local Settings_Service = require("scripts.service.settings-service")
local Spawn_Constants = require("libs.constants.spawn-constants")

local locals = {}

local overmind_utils = {}

local cache = {}
local cache_attributes = {}
setmetatable(cache_attributes, { __mode = "k" })

cache.process_chunk = {}
cache.process_chunk.surfaces = {}
function overmind_utils.process_chunk(data)
    Log.debug("overmind_utils.process_chunk")
    Log.info(data)

    if (not game or type(data) ~= "table") then return end
    if (type(data.chunk) ~= "table" or not data.chunk.valid) then return end
    if (not data.surface or not data.surface.valid) then return end
    if (not data.entity or not data.entity.valid) then if (data.event_name >= 0 and data.event_name ~= defines.events.on_chunk_generated) then return end end
    if (type(data.cause) == "table" and not data.cause.valid) then return end
    local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(data.surface.name)]]
    if (type(data.radius) ~= "number" or data.radius) then data.radius = selected_difficulty.value end
    if (type(data.spawners_required) ~= "boolean") then data.spawners_required = false end
    if (type(data.spawners_optional) ~= "boolean") then data.spawners_optional = false end
    if (type(data.target_cause) ~= "boolean") then data.target_cause = false end
    if (type(data.event_name) ~= "number") then data.event_name = -1 end
    if (type(data.chunk_size) ~= "number") then data.chunk_size = Constants.CHUNK_SIZE end
    if (type(data.witnessed) ~= "boolean") then data.witnessed = false end

    if (not cache.process_chunk.surfaces[data.surface.name] or not cache_attributes[cache.process_chunk.surfaces[data.surface.name]] or cache_attributes[cache.process_chunk.surfaces[data.surface.name]].time_to_live < game.tick) then
        cache.process_chunk.surfaces[data.surface.name] = { surface = data.surface, name = data.surface.name, index = data.surface.index }
        cache_attributes[cache.process_chunk.surfaces[data.surface.name]] = Data:new({ time_to_live = game.tick + 12345 + Random(2345), valid = true, })
    end

    if (not cache.process_chunk.surfaces[data.surface.name].overmind or not cache_attributes[cache.process_chunk.surfaces[data.surface.name].overmind] or cache_attributes[cache.process_chunk.surfaces[data.surface.name].overmind].time_to_live < game.tick) then
        cache.process_chunk.surfaces[data.surface.name].overmind = Overmind_Repository.get_overmind_data(data.surface.name)
        cache_attributes[cache.process_chunk.surfaces[data.surface.name]] = Data:new({ time_to_live = game.tick + 12345 + Random(2345), valid = true, })
    end

    local chunk = data.chunk
    local surface = data.surface
    local entity = data.entity
    local radius = data.radius
    local event_name = data.event_name
    local overmind = data.overmind
    local chunk_size = data.chunk_size
    -- local witnessed = data.witnessed
    chunk.witnessed = chunk.witnessed or data.witnessed

    -- log("event: " .. tostring(event_name))

    -- log("1")
    if (type(overmind) == "table" and event_name ~= -1) then log("overmind present, but not needed"); return end
    -- log("2")
    if (type(overmind) ~= "table" and event_name == -1) then
        log("overmind needed, but not present")
        overmind = cache.process_chunk.surfaces[data.surface.name].overmind
        if (type(overmind) ~= "table") then return end
    end
    -- log("3")

    -- Log.error("event: " .. tostring(event_name))
    -- log("event: " .. tostring(event_name))

    local position = chunk_size == Constants.CHUNK_SIZE and {
        x = chunk.x * 32,
        y = chunk.y * 32,
    } or {
        x = chunk.x * 2,
        y = chunk.y * 2,
    }

    local position_2 = chunk_size == Constants.CHUNK_SIZE and {
        x = position.x + 32,
        y = position.y + 32
    } or {
        x = position.x + 1,
        y = position.y + 1,
    }

    local previous_pollution_level = chunk.pollution_data and chunk.pollution_data.pollution
    local current_pollution_level = 0

    local last_pollution_check_proportion_average = 0
    local average_pollution_delta = 0

    if (chunk.pollution_data == nil) then
        -- local t = {}
        -- for k, v in pairs(data) do
        --     if (k ~= "overmind") then
        --         -- Log.error(k)
        --         -- Log.error(v)
        --         t[k] = v
        --     end
        -- end
        -- Log.error(t)
        -- log(serpent.block(t))
        log(serpent.block(chunk))
        error("pollution_data is nil")
    end
    if (chunk.pollution_data.tick_next < game.tick) then
        if (chunk_size == Constants.CHUNK_SIZE) then
            current_pollution_level = surface.get_pollution(position)
        -- else
        --     if (chunk_size == Constants.chunk_sizes[2]) then
        --         if (surface.is_chunk_generated({ x = math.floor(position.x / Constants.chunk_sizes[2]), y = math.floor(position.y / Constants.chunk_sizes[2]) })) then
        --             current_pollution_level = surface.get_pollution({ x = math.floor(position.x / Constants.chunk_sizes[2]), y = math.floor(position.y / Constants.chunk_sizes[2]) })
        --         end
        --     end
        --     if (chunk_size == Constants.chunk_sizes[3]) then
        --         if (surface.is_chunk_generated({ x = math.floor(position.x / Constants.chunk_sizes[3]), y = math.floor(position.y / Constants.chunk_sizes[3]) })) then
        --             current_pollution_level = surface.get_pollution({ x = math.floor(position.x / Constants.chunk_sizes[3]), y = math.floor(position.y / Constants.chunk_sizes[3]) })
        --         end
        --     end
        --     if (chunk_size == Constants.chunk_sizes[4]) then
        --         if (surface.is_chunk_generated({ x = math.floor(position.x / Constants.chunk_sizes[4]), y = math.floor(position.y / Constants.chunk_sizes[4]) })) then
        --             current_pollution_level = surface.get_pollution({ x = math.floor(position.x / Constants.chunk_sizes[4]), y = math.floor(position.y / Constants.chunk_sizes[4]) })
        --         end
        --     end
        --     if (chunk_size == Constants.chunk_sizes[5]) then
        --         if (surface.is_chunk_generated({ x = math.floor(position.x / Constants.chunk_sizes[5]), y = math.floor(position.y / Constants.chunk_sizes[5]) })) then
        --             current_pollution_level = surface.get_pollution({ x = math.floor(position.x / Constants.chunk_sizes[5]), y = math.floor(position.y / Constants.chunk_sizes[5]) })
        --         end
        --     end
        --     if (chunk_size == Constants.chunk_sizes[6]) then
        --         if (surface.is_chunk_generated({ x = math.floor(position.x / Constants.chunk_sizes[6]), y = math.floor(position.y / Constants.chunk_sizes[6]) })) then
        --             current_pollution_level = surface.get_pollution({ x = math.floor(position.x / Constants.chunk_sizes[6]), y = math.floor(position.y / Constants.chunk_sizes[6]) })
        --         end
        --     end
        end
        chunk.pollution_data.pollution = current_pollution_level

        local tick_past_prev = chunk.pollution_data.tick_past
        chunk.pollution_data.tick_past = chunk.pollution_data.tick_current
        chunk.pollution_data.tick_current = game.tick
        chunk.pollution_data.tick_next = chunk.pollution_data.tick_current + Constants.time.TICKS_PER_SECOND/ (selected_difficulty.value)

        local time_since_last_pollution_check = chunk.pollution_data.tick_current - chunk.pollution_data.tick_past
        local time_since_pollution_detection = chunk.pollution_data.tick_current - chunk.pollution_data.created

        if (time_since_last_pollution_check < 1) then time_since_last_pollution_check = 1 end
        if (time_since_pollution_detection < 1) then time_since_pollution_detection = 1 end

        local average_pollution_delta_per_tick = current_pollution_level / time_since_pollution_detection

        if (time_since_pollution_detection < Constants.time.TICKS_PER_SECOND) then time_since_pollution_detection = Constants.time.TICKS_PER_SECOND end
        local average_pollution_delta_per_second = current_pollution_level / (time_since_pollution_detection / Constants.time.TICKS_PER_SECOND)

        if (time_since_pollution_detection < Constants.time.TICKS_PER_MINUTE) then time_since_pollution_detection = Constants.time.TICKS_PER_MINUTE end
        local average_pollution_delta_per_minute = current_pollution_level / (time_since_pollution_detection / Constants.time.TICKS_PER_MINUTE)

        if (time_since_pollution_detection < Constants.time.TICKS_PER_HOUR) then time_since_pollution_detection = Constants.time.TICKS_PER_HOUR end
        local average_pollution_delta_per_hour = current_pollution_level / (time_since_pollution_detection / Constants.time.TICKS_PER_HOUR)

        -- local average_pollution_delta = (average_pollution_delta_per_tick + average_pollution_delta_per_second + average_pollution_delta_per_minute + average_pollution_delta_per_hour) / 4
        average_pollution_delta = (average_pollution_delta_per_tick + average_pollution_delta_per_second + average_pollution_delta_per_minute + average_pollution_delta_per_hour) / 4

        -- Log.error("pollution data")
        -- Log.error(average_pollution_delta)

        local last_pollution_check_proportion_creation = time_since_last_pollution_check / time_since_pollution_detection
        local last_pollution_check_proportion_seconds = time_since_last_pollution_check / (Constants.time.TICKS_PER_SECOND / selected_difficulty.value)
        local last_pollution_check_proportion_minutes = time_since_last_pollution_check / (Constants.time.TICKS_PER_MINUTE / selected_difficulty.value)
        local last_pollution_check_proportion_hour = time_since_last_pollution_check / (Constants.time.TICKS_PER_HOUR / selected_difficulty.value)
        -- local last_pollution_check_proportion_average = (last_pollution_check_proportion_creation + last_pollution_check_proportion_seconds + last_pollution_check_proportion_minutes + last_pollution_check_proportion_hour) / 5
        last_pollution_check_proportion_average = (last_pollution_check_proportion_creation + last_pollution_check_proportion_seconds + last_pollution_check_proportion_minutes + last_pollution_check_proportion_hour) / 5

        -- Log.error(last_pollution_check_proportion_average)
        -- Log.error(average_pollution_delta * last_pollution_check_proportion_average)

        if (    type (current_pollution_level) == "number"
            and type(previous_pollution_level) == "number"
            and current_pollution_level > previous_pollution_level)
        then
            -- Pollution went up
            local diff = current_pollution_level - previous_pollution_level
        else
            -- Pollution went down
            local diff = previous_pollution_level - current_pollution_level
        end
    end

    -- log("chunk.tick_next")
    if (type(chunk.tick_next) ~= "number") then return end

    chunk.tick_past = chunk.tick_current
    chunk.tick_current = game.tick
    -- chunk.tick_next = Settings_Service.get_overmind_chunk_tick_step(surface.name)
    chunk.pollution_data.tick_next = chunk.pollution_data.tick_current + math.random(60, 900 / selected_difficulty.value)

    -- Look for any nearby enemy units

    -- Look for any nearby spawners
    local root = 1 / selected_difficulty.value
    local evolution_factor = game.forces["enemy"].get_evolution_factor(surface)
    evolution_factor = evolution_factor ^ root
    local spawner_limit = 1 + (selected_difficulty.value ^ (selected_difficulty.radius_modifier ^ 2))
    spawner_limit = math.random(spawner_limit)
    spawner_limit = math.ceil(spawner_limit * evolution_factor)

    -- Log.error("1")

    local max_depth = nil
    -- if (type(event_name) == "number" and event_name > 0) then
    if (type(event_name) == "number") then
        if (event_name == defines.events.on_chunk_generated) then
            max_depth = 1
            spawner_limit = Constants.BIG_INTEGER
            -- spawner_limit = nil
        elseif (event_name == defines.events.on_entity_damaged) then
            -- unit-spawners
            max_depth = 1 * (selected_difficulty.value)
        elseif (event_name == defines.events.on_entity_died) then
            -- max_depth = 2 * (selected_difficulty.value / selected_difficulty.radius_modifier)
            max_depth = 2 * (selected_difficulty.value)
        elseif (event_name == defines.events.on_rocket_launch_ordered) then
            max_depth = 12 * selected_difficulty.radius_modifier
        elseif (event_name < 0) then
            max_depth = selected_difficulty.value / selected_difficulty.radius_modifier
            max_depth = math.ceil(max_depth)
        end
    end

    local target_position = nil
    local target_found = false

    if (chunk_size == Constants.CHUNK_SIZE) then
        if (data.spawners_required) then

            local spawners = surface.find_entities_filtered({
                area = {{ chunk.x * 32, chunk.y * 32 }, { chunk.x * 32 + 32, chunk.y * 32 + 32 }},
                force = "enemy",
                type = "unit-spawner",
                -- limit = 1,
                -- collision_mask = "more_enemies",
            })

            if (spawners and #spawners > 0) then
                for _, v in pairs(spawners) do
                    if (v and v.valid and v.unit_number) then
                        if (chunk.spawners[v.unit_number] == nil) then
                            chunk.spawners[v.unit_number] = v
                            -- chunk.spawners[v.unit_number] = {
                            --     unit_number = v.unit_number,
                            --     name = v.name,
                            --     position = v.position,
                            --     entity = v,
                            -- }
                            chunk.spawner_count = chunk.spawner_count + 1
                        end
                    end
                end
            end

            if (not spawners or (spawners and #spawners <= 0)) then
                spawners = overmind_utils.get_spawners({
                    -- overmind = overmind,
                    x = position.x,
                    y = position.y,
                    spawner_limit = spawner_limit,
                    radius = radius,
                    radius_limit = radius_limit,
                    surface = surface,
                    max_depth = max_depth,
                    event = event_name,
                })
            end

            if (not spawners or #spawners <= 0) then
                log("spawners required; found none")
                return
            end

            target_position = spawners[1].position
            target_found = true
        else
            local spawners = nil
            if (data.spawners_optional) then
                if (type(event_name) == "number" and event_name < 0) then
                    spawners = surface.find_entities_filtered({
                        area = {{ chunk.x * 32, chunk.y * 32 }, { chunk.x * 32 + 32, chunk.y * 32 + 32 }},
                        force = "enemy",
                        type = "unit-spawner",
                        -- limit = 1,
                        -- collision_mask = "more_enemies",
                    })

                    -- Log.error(spawners)
                    if (spawners and #spawners > 0) then
                        -- local overmind = Overmind_Repository.get_overmind_data(surface.name)
                        local overmind = cache.process_chunk.surfaces[data.surface.name].overmind
                        if (type(overmind) == "table") then
                            for _, v in pairs(spawners) do
                                if (v and v.valid and v.unit_number) then
                                    if (chunk.spawners[v.unit_number] == nil) then
                                        chunk.spawners[v.unit_number] = v
                                        -- chunk.spawners[v.unit_number] = {
                                        --     unit_number = v.unit_number,
                                        --     name = v.name,
                                        --     position = v.position,
                                        --     entity = v,
                                        -- }
                                        chunk.spawner_count = chunk.spawner_count + 1
                                    end
                                    if (overmind.spawners[v.unit_number] == nil) then
                                        overmind.spawners[v.unit_number] = v
                                        overmind.spawner_count = overmind.spawner_count + 1
                                    end
                                end
                            end
                        end
                    end
                else
                    spawners = surface.find_entities_filtered({
                        area = {{ chunk.x * 32, chunk.y * 32 }, { chunk.x * 32 + 32, chunk.y * 32 + 32 }},
                        force = "enemy",
                        type = "unit-spawner",
                        -- limit = 1,
                        -- collision_mask = "more_enemies",
                    })

                    -- Log.error(spawners)
                    if (spawners and #spawners > 0) then
                        -- local overmind = Overmind_Repository.get_overmind_data(surface.name)
                        local overmind = cache.process_chunk.surfaces[data.surface.name].overmind
                        if (type(overmind) == "table") then
                            for _, v in pairs(spawners) do
                                if (v and v.valid) then
                                    if (overmind.spawners[v.unit_number] == nil) then
                                        overmind.spawners[v.unit_number] = v
                                        overmind.spawner_count = overmind.spawner_count + 1
                                    end
                                end
                            end
                        end
                    end
                end

                if (not spawners or (spawners and #spawners <= 0)) then
                    spawners = overmind_utils.get_spawners({
                        -- overmind = overmind,
                        x = position.x,
                        y = position.y,
                        spawner_limit = spawner_limit,
                        radius = radius,
                        radius_limit = radius_limit,
                        surface = surface,
                        max_depth = max_depth,
                        event = event_name,
                    })
                end

                if (spawners and #spawners > 0) then
                    target_position = spawners[1].position
                    target_found = true
                    for _, v in pairs(spawners) do
                        if (v and v.valid) then
                            table.insert(chunk.spawners, v)
                            chunk.spawner_count = chunk.spawner_count + 1
                        end
                    end
                end
            end

            if (type(event_name) == "number" and event_name >= 0) then
                if ((target_position == nil or target_cause) and data.cause and data.cause.valid) then
                    target_position = data.cause.position
                    target_found = true
                end
            end
        end
    end
    -- Log.error("2")

    if (target_position == nil) then
        target_found = false
        -- target_position = entity.position
        -- target_position = position
        target_position = position_2
    end

    -- local distance = math.sqrt((entity.position.x - target_position.x) ^ 2 + (entity.position.y - target_position.y) ^ 2)
    local distance = ((position.x - target_position.x) ^ 2 + (position.y - target_position.y) ^ 2) ^ 0.5
    -- if (distance <= 0) then distance = 32 end
    if (distance < 32) then distance = 32 end
    local chunk_distance = distance / Constants.CHUNK_SIZE
    local proportional_distance = chunk_distance * (1 - evolution_factor)

    local distance_modifier = chunk_distance - proportional_distance
    -- local distance_multiplier = ((selected_difficulty.value * (math.exp(1) ^ (distance_modifier) - 1)) / (selected_difficulty.value ^ .5)) / 4

    local distance_ratio = 1
    if (chunk_distance > 0) then distance_ratio = (chunk_distance + (distance_modifier ^ 0.5)) / chunk_distance end

    if (distance_modifier < 0) then distance_modifier = 0 end

    if (distance_ratio < 0.25) then distance_ratio = 0.25 end

    -- Multiplier of the pollution in a chunk based on distance to spawners
    -- local pollution_distance_modifier = chunk_distance / distance_ratio
    -- local pollution_distance_modifier = ((selected_difficulty.value * (math.exp(1) ^ (distance_modifier) - 1)) / (selected_difficulty.value ^ .5)) / 4
    local pollution_distance_modifier = ((selected_difficulty.value * (Constants.e ^ (distance_modifier) - 1)) / (selected_difficulty.value ^ .5)) / 4

    -- local modifier = (-1 * (Constants.CHUNK_SIZE / (selected_difficulty.value ^ (math.log(selected_difficulty.value + 1, 1000)))) + Constants.CHUNK_SIZE) / 2
    -- local weight = 0 + ((current_pollution_level / (Constants.CHUNK_SIZE / (selected_difficulty.value ^ 1))) * pollution_distance_modifier) * (average_pollution_delta * last_pollution_check_proportion_average)
    -- local weight = 0 + ((current_pollution_level * modifier) * pollution_distance_modifier) * (average_pollution_delta * last_pollution_check_proportion_average)
    -- local weight = 0 + (current_pollution_level * pollution_distance_modifier) * (average_pollution_delta * last_pollution_check_proportion_average)
    local weight = 0 + ((current_pollution_level * pollution_distance_modifier) ^ 2 + (current_pollution_level * average_pollution_delta * last_pollution_check_proportion_average) ^ 2) ^ 0.5

    -- Witnessed?
    -- if (type(event_name) == "number" and event_name > 0) then
    if (type(event_name) == "number" and chunk_distance < selected_difficulty.value + 6.66) then
        -- local distance_limit = selected_difficulty.value * ((evolution_factor ^ root) ^ selected_difficulty.value) + (((selected_difficulty.value - selected_difficulty.value/(math.pi/2) * ((0 - 1) * math.atan((1 / selected_difficulty.value) * ((evolution_factor * 10) ^ 2)) + math.pi/2)) ^ 2) / selected_difficulty.value) / (math.exp(1) / selected_difficulty.radius_modifier)
        local distance_limit = selected_difficulty.value * ((evolution_factor ^ root) ^ (selected_difficulty.radius_modifier ^ 2)) + (((selected_difficulty.value - selected_difficulty.value/(math.pi/2) * ((0 - 1) * math.atan((1 / selected_difficulty.value) * ((evolution_factor * 10) ^ 2)) + math.pi/2)) ^ 2) / selected_difficulty.value) / (Constants.e / selected_difficulty.radius_modifier)

        if (event_name == defines.events.on_entity_damaged) then
            if (entity.type == "unit-spawner" and entity.force.name == "enemy") then
                -- Log.error("spawner damaged")
                -- if (data.cause and data.cause.valid) then
                    if (distance_modifier <= distance_limit) then
                        chunk.witnessed = chunk.witnessed or target_found
                        if (chunk.witnessed) then overmind_utils.chunk_witnessed({ chunk = chunk }) end
                    end
                -- end
            end
        elseif (event_name == defines.events.on_entity_died) then
            -- if (data.cause and data.cause.valid) then
                if (distance_modifier <= distance_limit) then
                    chunk.witnessed = chunk.witnessed or target_found
                    if (chunk.witnessed) then overmind_utils.chunk_witnessed({ chunk = chunk }) end
                end
            -- end
        elseif (event_name == defines.events.on_rocket_launch_ordered) then
            if (distance_modifier <= distance_limit * 6.66) then
                chunk.witnessed = chunk.witnessed or target_found
                if (chunk.witnessed) then overmind_utils.chunk_witnessed({ chunk = chunk }) end
                if (chunk.tick_rocket_launch_witnessed) then chunk.tick_rocket_launch_witnessed = game.tick end
            end
        elseif (event_name < 0) then
            if (chunk.spawner_count > 0) then
                chunk.witnessed = true
                overmind_utils.chunk_witnessed({ chunk = chunk })
                -- Log.error("chunk witnessed")
            end
        end
    end

    -- Log.error(weight)

    local time_since_last_death = chunk.recent_deaths.tick_current - chunk.recent_deaths.tick_past
    local time_since_creation = chunk.recent_deaths.tick_current - chunk.recent_deaths.created

    if (time_since_last_death < 1) then time_since_last_death = 1 end
    if (time_since_creation < 1) then time_since_creation = 1 end

    local average_deaths_per_tick = chunk.deaths / time_since_creation

    if (time_since_creation < Constants.time.TICKS_PER_SECOND) then time_since_creation = Constants.time.TICKS_PER_SECOND end
    local average_deaths_per_second = chunk.deaths / (time_since_creation / Constants.time.TICKS_PER_SECOND)

    local last_death_time_proportion_creation = time_since_last_death / time_since_creation
    local last_death_time_proportion_seconds = time_since_last_death / (Constants.time.TICKS_PER_SECOND / selected_difficulty.value)
    local last_death_time_proportion_minutes = time_since_last_death / (Constants.time.TICKS_PER_MINUTE / selected_difficulty.value)
    local last_death_time_proportion_hour = time_since_last_death / (Constants.time.TICKS_PER_HOUR / selected_difficulty.value)
    local last_death_time_proportion_average = (last_death_time_proportion_creation + last_death_time_proportion_seconds + last_death_time_proportion_minutes + last_death_time_proportion_hour) / 5

    if (chunk.recent_deaths.average_deaths_per_tick < average_deaths_per_tick) then
        -- average going up
        -- attack probably starting
        -- reduce the weight of deaths?
        if (chunk.recent_deaths.modifier < 0) then chunk.recent_deaths.modifier = 1 end
    else
        -- average staying steady or going down
        -- attack ending?
        -- increase the weight of deaths?
        if (chunk.recent_deaths.modifier < 0) then chunk.recent_deaths.modifier = 1 end
    end

    chunk.recent_deaths.average_deaths_per_tick = average_deaths_per_tick
    chunk.recent_deaths.average_deaths_per_second = average_deaths_per_second

    if (chunk_size == Constants.CHUNK_SIZE and entity and entity.valid and type(event_name) == "number" and event_name > 0) then
        -- Log.error(entity.type)
        local root = 1 / selected_difficulty.value
        if (event_name == defines.events.on_entity_damaged) then
            if (entity.type == "unit-spawner" and entity.force.name == "enemy") then
                -- Log.error("spawner damaged")
                weight = weight + ((16000 * selected_difficulty.value) * (evolution_factor ^ root)) ^ 0.95
                chunk.tick_attack_next = game.tick
                chunk.tick_next = game.tick

                if (not chunk.witnessed) then
                    chunk.witnessed = true
                    chunk.tick_witnessed = game.tick
                end

                if (chunk.witnessed) then overmind_utils.chunk_witnessed({ chunk = chunk }) end

                if (data.cause and data.cause.valid and data.cause.force == "player") then
                    if (Overmind_Target_Priorities.target_priorities[data.cause.name]) then
                        weight = weight + (Overmind_Target_Priorities.target_priorities[data.cause.name].weight * (evolution_factor ^ root) - distance_modifier) ^ 0.95
                    end
                end
            elseif (entity.force.name == "player") then
                weight = weight + selected_difficulty.value * (selected_difficulty.radius_modifier ^ 2) * (evolution_factor ^ root)
            end
        else
            if (event_name == defines.events.on_entity_died) then
                if (entity.force.name == "enemy") then
                    chunk.witnessed = true
                    if (chunk.witnessed) then overmind_utils.chunk_witnessed({ chunk = chunk }) end

                    if (entity.type == "unit-spawner") then
                        -- Log.error("spawner died")
                        weight = weight + ((64000 * selected_difficulty.value) * (evolution_factor ^ root))
                        chunk.tick_attack_next = game.tick
                        chunk.tick_next = game.tick

                        for k, v in pairs(chunk.spawners) do
                            if (v and not v.valid) then
                                chunk.spawners[k] = nil
                                if (chunk.spawner_count > 0) then chunk.spawner_count = chunk.spawner_count - 1 end
                            end
                        end

                        -- local overmind = Overmind_Repository.get_overmind_data(surface.name)
                        local overmind = cache.process_chunk.surfaces[data.surface.name].overmind
                        if (type(overmind) == "table") then
                            if (overmind.spawners[entity.unit_number]) then
                                overmind.spawners[entity.unit_number] = nil
                                if (overmind.spawner_count > 0) then overmind.spawner_count = overmind.spawner_count - 1 end
                            end
                        end

                        if (data.cause and data.cause.valid and data.cause.force == "player") then
                            if (Overmind_Target_Priorities.target_priorities[data.cause.name]) then
                                weight = weight + (Overmind_Target_Priorities.target_priorities[data.cause.name].weight * (evolution_factor ^ root) - distance_modifier) ^ 0.95
                            end
                        end
                    elseif (entity.type == "unit") then
                        -- Log.error("unit died")
                        -- Log.error(entity)
                        local entry = Spawn_Constants.name_table[entity.name]
                        local entity_weight = 0
                        if (type(entry) == "number") then
                            entity_weight = entry
                        end

                        weight = weight - (((entity_weight * selected_difficulty.radius_modifier) * (last_death_time_proportion_average ^ root)) * (evolution_factor ^ root)) ^ 0.95

                        if (Overmind_Target_Priorities.target_priorities[data.entity.name]) then
                            weight = weight + (Overmind_Target_Priorities.target_priorities[data.entity.name].weight * (evolution_factor ^ root) - distance_modifier) ^ 0.95
                        end
                        if (data.cause and data.cause.valid and data.cause.force == "player") then
                            if (Overmind_Target_Priorities.target_priorities[data.cause.name]) then
                                weight = weight + (Overmind_Target_Priorities.target_priorities[data.cause.name].weight * (evolution_factor ^ root) - distance_modifier) ^ 0.95
                            end
                        end
                    end
                elseif (entity.force.name == "player") then
                    if (entity and entity.valid) then
                        if (Overmind_Target_Priorities.target_priorities[entity.name]) then
                            weight = weight + (Overmind_Target_Priorities.target_priorities[entity.name].weight * (((1 + selected_difficulty.radius_modifier) ^ (selected_difficulty.radius_modifier ^ 2))) * (evolution_factor ^ root)) ^ 0.95
                        end
                    end
                end
            elseif (event_name == defines.events.on_rocket_launch_ordered) then
                if (chunk.witnessed) then
                    overmind_utils.chunk_witnessed({ chunk = chunk })

                    if (Overmind_Target_Priorities.target_priorities[entity.name]) then
                        weight = weight + (Overmind_Target_Priorities.target_priorities[entity.name].weight * (evolution_factor ^ root) - distance_modifier) ^ 0.95
                    end
                end
            end
        end
    elseif (type(event_name) == "number" and event_name < 0) then
        -- Log.error("event_name: " .. tostring(event_name))
        -- Scan the chunk for "player" entities
        for k, v in pairs(chunk.entities) do
            -- if (v and not v.valid) then
            --     weight = weight - v.weight
            --     chunk.entities[k] = nil
            --     chunk.entity_count = chunk.entity_count - 1
            -- end
            if ((v and not v.valid) or (v and (not v.entity or not v.entity.valid))) then
                local _weight = v.weight or v.entity.weight or 0
                weight = weight - _weight
                if (weight < 1) then weight = 1 end
                chunk.entities[v.unit_number] = nil
                if (chunk.entity_count >= 1) then
                    chunk.entity_count = chunk.entity_count - 1
                end
            end
        end

        -- Scan the chunk for "enemy" spawners
        for k, v in pairs(chunk.spawners) do
            if (v and not v.valid) then
                chunk.spawners[k] = nil
                if (chunk.spawner_count > 0) then chunk.spawner_count = chunk.spawner_count - 1 end
            end
        end

        if (chunk.witnessed) then
            overmind_utils.chunk_witnessed({ chunk = chunk })
        end
            -- Log.error("chunk witnessed")
            -- if (chunk_distance == Constants.CHUNK_SIZE) then
            if (chunk_size == Constants.CHUNK_SIZE) then
                local entities = surface.find_entities_filtered({
                    area = {{ chunk.x * 32, chunk.y * 32 }, { chunk.x * 32 + 32, chunk.y * 32 + 32}},
                    force = "player",
                })
                -- Log.error("finding entities")

                if (entities and #entities > 0) then
                    -- Log.error("found entities")
                    for _, v in pairs(entities) do
                        if (    (v and v.valid and v.unit_number)
                            or  (type(v) == "table" and v.entity and v.entity.valid and v.entity.unit_number))
                        then
                            -- Log.error("found valid entity")
                            -- Log.error(v)
                            -- if (v and v.valid and v.unit_number) then
                            if (chunk.entities[v.unit_number] == nil) then
                                -- Log.error("entity not tracked")
                                if (Overmind_Target_Priorities.target_priorities[v.name]) then
                                    -- Log.error("entity has weight priority")

                                    -- local weight_modifier = Overmind_Target_Priorities.target_priorities[v.name].weight * ((selected_difficulty.radius_modifier ^ 2)) * (evolution_factor ^ root)
                                    local weight_modifier = (((selected_difficulty.radius_modifier ^ 2)) * (evolution_factor ^ root)) ^ 0.25

                                    local unit_number = v.unit_number or v.entity.unit_number
                                    local name = v.name or v.entity.name
                                    local type = v.type or v.entity.type
                                    local force = v.force or v.entity.force
                                    local surface = v.surface or v.entity.surface
                                    local entity = v.valid and v or v.entity.valid and v.entity

                                    chunk.entities[unit_number] = {
                                        unit_number = unit_number,
                                        name = name,
                                        type = type,
                                        force = {
                                            name = force.name,
                                            index = force.index,
                                        },
                                        surface = {
                                            name  =  surface.name,
                                            index  =  surface.index,
                                        },
                                        entity = {
                                            type = entity.type,
                                            name = entity.name,
                                            force = {
                                                index = entity.force.index,
                                                name = entity.force.name,
                                                valid = entity.force.valid,
                                            },
                                            surface = entity.surface,
                                            position = entity.position,
                                            unit_number = unit_number,
                                            valid = entity.valid,
                                        },
                                        position = entity.position,
                                        -- weight = weight_modifier
                                        weight = Overmind_Target_Priorities.target_priorities[v.name].weight * weight_modifier
                                    }

                                    chunk.entity_count = chunk.entity_count + 1

                                    weight = weight + weight_modifier
                                end
                            end
                        end
                    end
                end
            end

            weight = weight + chunk.entity_count * (evolution_factor ^ root)

            -- if (chunk_weight == Constants.CHUNK_SIZE) then

                -- log("gathering sub chunk data")
                local _locals = locals.gather_sub_chunk_data({
                    locals = {
                        chunk_size = Constants.CHUNK_SIZE,
                        selected_difficulty = selected_difficulty,
                        evolution_modifier = evolution_factor ^ root,
                        weight = chunk.weight,
                        entities = chunk.entities,
                        entity_count = chunk.entity_count,
                        spawners = chunk.spawners,
                        spawner_count = chunk.spawner_count,
                        witnessed = chunk.witnessed,
                        witnessed_tick = chunk.witnessed_tick,
                        pollution = chunk.pollution_data.pollution,
                        deaths = chunk.deaths,
                        rocket_launches = chunk.rocket_launches,
                    },
                    chunk = chunk,
                    overmind = overmind,
                })

                local chunk_data_vals = {
                    weight = 0,
                    entities = {},
                    entity_count = 0,
                    spawners = {},
                    spawner_count = 0,
                    witnessed = false,
                    witnessed_tick = nil,
                    pollution = 0,
                    deaths = 0,
                    rocket_launches = 0,
                    valid = true
                }

                if (_locals) then
                    -- log("collating sub chunk data")
                    -- chunk_data_vals = locals.collate_chunk_data({ chunk_size = Constants.CHUNK_SIZE, locals = _locals, chunk_data_vals = chunk_data_vals })
                    chunk_data_vals = locals.collate_chunk_data({ chunk_size = chunk_size, locals = _locals, chunk_data_vals = chunk_data_vals })
                    if (type(chunk_data_vals) == "table" and chunk_data_vals.valid) then
                        chunk.weight = chunk.weight + chunk_data_vals.weight
                        if (chunk_data_vals.entities) then
                            for _, v in pairs(chunk_data_vals.entities) do
                                if (    (v and v.valid and v.unit_number)
                                    or  (type(v) == "table" and v.entity and v.entity.valid and v.entity.unit_number)
                                ) then
                                    local unit_number = v.unit_number or v.entity.unit_number
                                    local name = v.name or v.entity.name
                                    local type = v.type or v.entity.type
                                    local force = v.force or v.entity.force
                                    local surface = v.surface or v.entity.surface
                                    local entity = v.valid and v or v.entity.valid and v.entity
                                    if (not chunk.entities[unit_number]) then
                                        -- chunk.entities[k] = v
                                        chunk.entities[unit_number] = {
                                            unit_number = unit_number,
                                            name = name,
                                            type = type,
                                            force = {
                                                name = force.name,
                                                index = force.index,
                                            },
                                            surface = {
                                                name  = surface.name,
                                                index  = surface.index,
                                            },
                                            entity = {
                                                type = entity.type,
                                                name = entity.name,
                                                force = {
                                                    index = entity.force.index,
                                                    name = entity.force.name,
                                                    valid = entity.force.valid,
                                                },
                                                surface = entity.surface,
                                                position = entity.position,
                                                unit_number = unit_number,
                                                valid = entity.valid,
                                            },
                                            weight = weight_modifier or 1
                                        }
                                    end
                                end
                            end
                        end
                        chunk.entity_count = chunk.entity_count + chunk_data_vals.entity_count
                        if (chunk_data_vals.spawners) then
                            for _, v in pairs(chunk_data_vals.spawners) do
                                if (v and v.valid and v.unit_number) then
                                    if (not chunk.spawners[v.unit_number]) then
                                        chunk.spawners[v.unit_number] = v
                                    end
                                end
                            end
                        end
                        chunk.spawner_count = chunk.spawner_count + chunk_data_vals.spawner_count
                        chunk.witnessed = chunk.witnessed or chunk_data_vals.witnessed
                        chunk.witnessed_tick = chunk.witnessed_tick or chunk_data_vals.witnessed_tick
                        if (type(chunk.witnessed_tick) ~= "number") then chunk.witnessed_tick = nil end
                        -- chunk.pollution = chunk.pollution + chunk_data_vals.pollution
                        chunk.pollution_data.pollution = chunk.pollution_data.pollution + chunk_data_vals.pollution
                        chunk.deaths = chunk.deaths + chunk_data_vals.deaths
                        chunk.rocket_launches = chunk.rocket_launches + chunk_data_vals.rocket_launches
                    end
                end

            -- end
        -- end

    end

    -- if (weight < 0) then weight = 0 end

    return weight, chunk_distance
end

function overmind_utils.get_spawners(data)
    Log.debug("overmind_utils.get_spawner")
    Log.info(data)

    if (not type(data) == "table") then return end
    if (data.overmind and type(data.overmind) ~= "table") then return end
    if (not data.x or data.x == nil) then return end
    if (not data.y or data.y == nil) then return end
    if (not data.spawner_limit or data.spawner_limit == nil) then data.spawner_limit = Constants.BIG_INTEGER end
    if (not data.surface or not data.surface.valid) then return end
    if (not data.radius_limit or data.radius_limit == nil) then
        local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(data.surface.name)]]
        -- local root = 1 / selected_difficulty.value
        -- data.radius_limit = ((selected_difficulty.value ^ (selected_difficulty.radius_modifier ^ 2)) ^ root) * selected_difficulty.value
        local evolution_factor = game.forces["enemy"].get_evolution_factor(data.surface)
        evolution_factor = evolution_factor ^ (1 / selected_difficulty.value)
        data.radius_limit = ((selected_difficulty.radius_modifier ^ 2)) * evolution_factor
    end
    if (not data.radius or data.radius == nil) then data.radius = 1 end
    if (not data.depth or data.depth == nil) then data.depth = 1 end
    if (not data.max_depth or data.max_depth == nil) then data.max_depth = 1 end

    if (data.depth > data.max_depth) then return end
    if (data.radius > Constants.CHUNK_SIZE * (1 + data.radius_limit) and data.depth > 1) then return end

    local spawners

    if (data.event and (data.event == defines.events.on_chunk_generated or data.event < 0)) then
        -- Log.error("searching newly generated chunk")
        spawners = data.surface.find_entities_filtered({
            type = "unit-spawner",
            force = "enemy",
            area = {{ data.x * 32, data.y * 32 }, { data.x * 32 + 32, data.y * 32 + 32 }},
            limit = data.spawner_limit,
        })

    else
        -- Log.error("searching for spawners by radius")
        spawners = data.surface.find_entities_filtered({
            type = "unit-spawner",
            force = "enemy",
            position = { x = data.x, y = data.y },
            limit = data.spawner_limit,
            -- radius = 32 * data.radius,
            radius = 16 * data.radius,
        })
    end

    if (not spawners or #spawners < 1) then
        data.radius = 1.1 * data.radius + 1
        data.depth = data.depth + 1

        return overmind_utils.get_spawners(data)
    end

    if (data.overmind) then
        if (spawners and #spawners > 0) then
            for _, v in pairs(spawners) do
                if (v and v.valid) then
                    if (not overmind.spawners[v.unit_number]) then
                        overmind.spawners[v.unit_number] = v
                        overmind.spawner_count = overmind.spawner_count + 1
                    end
                end
            end
        end
    end

    return spawners, data
end

function overmind_utils.stage_new_chunk(data)
    Log.debug("overmind_utils.stage_new_chunk")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.queue) ~= "table") then return end
    if (type(data.chunk_pos) ~= "table") then return end
    if (type(data.chunk_pos.x) ~= "number" or type(data.chunk_pos.y) ~= "number") then return end
    if (type(data.surface) ~= "userdata" or not data.surface.valid) then return end
    if (type(data.position) == "table" and (type(data.position.x) ~= "number" or type(data.position.y) ~= "number")) then return end
    if (type(data.area) == "table" and (type(data.area.left_top) ~= "table" or type(data.area.right_bottom) ~= "table")) then return end
    if (type(data.area) == "table" and (type(data.area.left_top.x) ~= "number" or type(data.area.left_top.y) ~= "number")) then return end
    if (type(data.area) == "table" and (type(data.area.right_bottom.x) ~= "number" or type(data.area.right_bottom.y) ~= "number")) then return end
    if (type(data.position) ~= "table" and type(data.area) ~= "table") then return end
    if (type(data.entity) == "table"
        and (  type(data.entity.type) ~= "string"
            or type(data.entity.name) ~= "string"
            or type(data.entity.force) ~= "table"
            or not data.entity.force.valid
            or type(data.entity.surface) ~= "userdata"
            or not data.entity.surface.valid
            or type(data.entity.position) ~= "table"
            or type(data.entity.position.x) ~= "number"
            or type(data.entity.position.y) ~= "number"
            or not data.entity.valid))
    then return end
    if (type(data.cause) == "table"
        and (  type(data.cause.type) ~= "string"
            or type(data.cause.name) ~= "string"
            or type(data.cause.force) ~= "table"
            or not data.cause.force.valid
            or type(data.cause.surface) ~= "userdata"
            or not data.cause.surface.valid
            or type(data.cause.position) ~= "table"
            or type(data.cause.position.x) ~= "number"
            or type(data.cause.position.y) ~= "number"
            or not data.cause.valid))
    then return end
    if (type(data.event) ~= "number") then return end
    if (type(data.witnessed) ~= "boolean") then data.witnessed = false end

    if (type(data.chunk_size) ~= "number") then data.chunk_size = Constants.CHUNK_SIZE end

    if (not Constants.chunk_sizes_map[data.chunk_size]) then return end
    -- log(serpent.line(data.chunk_size))

    local queue = data.queue
    -- log(serpent.block(data))
    -- log(serpent.block(queue))

    local position = data.position

    if (not position) then
        position = {
            x = data.area.left_top.x,
            y = data.area.left_top.y,
        }
    end
    -- log(serpent.line(position))

    local staged_chunk_data = Staged_Chunk_Data:new({
        event = data.event,
        x = data.chunk_pos.x,
        y = data.chunk_pos.y,
        entity = data.entity,
        force = data.entity and data.entity.force,
        cause = data.cause,
        surface = data.surface,
        surface_name = data.surface.name,
        position = position,
        area = data.area,
        witnessed = data.witnessed,
        chunk_size = data.chunk_size,
    })

    if (staged_chunk_data and staged_chunk_data.valid) then
        local source = queue.name .. " count = " .. queue.count .." - staged_chunk_data - " .. data.event
        -- log(source)
        queue:enqueue({ source = source, data = staged_chunk_data})
    end
end

function overmind_utils.create_new_chunk(data)
    Log.debug("overmind_utils.create_new_chunk")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.surface) ~= "userdata" or not data.surface.valid) then return end
    if (type(data.position) == "table" and (type(data.position.x) ~= "number" or type(data.position.y) ~= "number")) then return end
    if (type(data.area) == "table" and (type(data.area.left_top) ~= "table" or type(data.area.right_bottom) ~= "table")) then return end
    if (type(data.area) == "table" and (type(data.area.left_top.x) ~= "number" or type(data.area.left_top.y) ~= "number")) then return end
    if (type(data.area) == "table" and (type(data.area.right_bottom.x) ~= "number" or type(data.area.right_bottom.y) ~= "number")) then return end
    if (type(data.position) ~= "table" and type(data.area) ~= "table") then return end
    if (type(data.witnessed) ~= "boolean") then data.witnessed = false end
    if (type(data.chunk_size) ~= "number") then data.chunk_size = Constants.CHUNK_SIZE end
    if (type(data.event) ~= "number") then data.event = -1 end

    if (not Constants.chunk_sizes_map[data.chunk_size]) then return end

    local overmind = data.overmind
    local surface = data.surface
    local area = data.area
    local position = data.position
    local x, y = 0, 0
    local chunk_size = data.chunk_size

    if (position) then
        x = math.floor(position.x / chunk_size)
        y = math.floor(position.y / chunk_size)
    elseif (area) then
        x = math.floor(area.left_top.x / chunk_size)
        y = math.floor(area.left_top.y / chunk_size)
    end

    local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(data.surface.name)]]
    -- if (selected_difficulty.value ~= 4) then return end
    local evolution_modifier = game.forces["enemy"].get_evolution_factor(surface) ^ (1 / selected_difficulty.value)
    local weight = 0

    -- local entities = {}
    local entity_count = 0

    -- local spawners = {}
    local spawner_count = 0

    -- local witnessed = data.witnessed
    local witnessed = false
    local witnessed_tick = nil

    local pollution = 0
    local deaths = 0
    local rocket_launches = 0

    local function new_local()
        return {
            selected_difficulty = selected_difficulty,
            evolution_modifier = evolution_modifier,
            weight = weight,
            entities = {},
            entity_count = entity_count,
            spawners = {},
            spawner_count = spawner_count,
            witnessed = witnessed,
            witnessed_tick = witnessed_tick,
            pollution = pollution,
            deaths = deaths,
            rocket_launches = rocket_launches,
        }
    end

    local _locals = new_local()

    local locals_1, locals_2, locals_3, locals_4 = new_local(), new_local(), new_local(), new_local()

    local chunk_level = Constants.chunk_sizes_map[chunk_size]

    -- if (chunk_size == Constants.CHUNK_SIZE) then
    if (chunk_level == 1) then
        local entities = surface.find_entities_filtered({
            area = area or {{ x * 32, y * 32 }, { x * 32 + 32, y * 32 + 32}},
            force = "player",
        })

        if (entities and #entities > 0) then
            -- Log.error("found player entities")
            for _, v in pairs(entities) do
                if (    (v and v.valid and v.unit_number)
                    or  (type(v) == "table" and v.entity and v.entity.valid and v.entity.unit_number))
                then
                    -- Log.error("validating player enttities")
                    local unit_number = v.unit_number or v.entity.unit_number
                    local name = v.name or v.entity.name
                    local type = v.type or v.entity.type
                    local force = v.force or v.entity.force
                    local surface = v.surface or v.entity.surface
                    local entity = v.valid and v or v.entity.valid and v.entity
                    if (_locals.entities[unit_number] == nil) then
                        -- Log.error("player entity valid")
                        -- Log.error(v)
                        _locals.entities[unit_number] = {
                            unit_number = unit_number,
                            name = name,
                            type = type,
                            force = {
                                name = force.name,
                                index = force.index,
                            },
                            surface = {
                                name  =  surface.name,
                                index  =  surface.index,
                            },
                            entity = {
                                type = entity.type,
                                name = entity.name,
                                force = {
                                    index = entity.force.index,
                                    name = entity.force.name,
                                    valid = entity.force.valid,
                                },
                                surface = entity.surface,
                                position = entity.position,
                                unit_number = unit_number,
                                valid = entity.valid,
                            },
                            position = entity.position,
                            weight = 1,
                        }

                        _locals.entity_count = _locals.entity_count + 1
                        _locals.valid = true
                    end
                end
            end
        end

        local spawners = surface.find_entities_filtered({
            area = area or {{ x * 32, y * 32 }, { x * 32 + 32, y * 32 + 32 }},
            force = "enemy",
            type = "unit-spawner",
            -- collision_mask = "more_enemies",
        })

        if (spawners and #spawners > 0) then
            -- Log.error("found spawners")
            -- log("found spawners")
            _locals.witnessed = true
            for _, v in pairs(spawners) do
                if (v and v.valid and v.unit_number) then
                    if (_locals.spawners[v.unit_number] == nil) then
                        _locals.spawners[v.unit_number] = v
                        _locals.spawner_count = spawner_count + 1
                    end
                    if (overmind.spawners[v.unit_number] == nil) then
                        overmind.spawners[v.unit_number] = v
                        overmind.spawner_count = overmind.spawner_count + 1
                    end
                end
            end
        end
    elseif (chunk_level < Constants.CHUNK_LEVELS) then
        if (overmind.chunks["chunks_" .. chunk_level - 1][x * 2] and overmind.chunks["chunks_" .. chunk_level - 1][x * 2][y * 2]) then locals_1 = locals.gather_sub_chunk_data({ chunk_size = Constants.chunk_sizes[chunk_level - 1], locals = locals_1, chunk = overmind.chunks["chunks_" .. chunk_level - 1][x * 2][y * 2], overmind = overmind }) end
        if (overmind.chunks["chunks_" .. chunk_level - 1][x * 2] and overmind.chunks["chunks_" .. chunk_level - 1][x * 2][y * 2 + 1]) then locals_2 = locals.gather_sub_chunk_data({ chunk_size = Constants.chunk_sizes[chunk_level - 1], locals = locals_2, chunk = overmind.chunks["chunks_" .. chunk_level - 1][x * 2][y * 2 + 1], overmind = overmind }) end
        if (overmind.chunks["chunks_" .. chunk_level - 1][x * 2 + 1] and overmind.chunks["chunks_" .. chunk_level - 1][x * 2 + 1][y * 2]) then locals_3 = locals.gather_sub_chunk_data({ chunk_size = Constants.chunk_sizes[chunk_level - 1], locals = locals_3, chunk = overmind.chunks["chunks_" .. chunk_level - 1][x * 2 + 1][y * 2], overmind = overmind }) end
        if (overmind.chunks["chunks_" .. chunk_level - 1][x * 2 + 1] and overmind.chunks["chunks_" .. chunk_level - 1][x * 2 + 1][y * 2 + 1]) then locals_4 = locals.gather_sub_chunk_data({ chunk_size = Constants.chunk_sizes[chunk_level - 1], locals = locals_4, chunk = overmind.chunks["chunks_" .. chunk_level - 1][x * 2 + 1][y * 2 + 1], overmind = overmind }) end
    else
        Log.error("How did this happen?")
        log("How did this happen?")
        log(serpent.block(chunk_size))
        error("how")
        return
    end

    if (not _locals and not locals_1 and not locals_2 and not locals_3 and not locals_4) then return end

    local chunk_data_vals = {
        weight = 0,
        entities = {},
        entity_count = 0,
        spawners = {},
        spawner_count = 0,
        witnessed = false,
        witnessed_tick = nil,
        pollution = 0,
        deaths = 0,
        rocket_launches = 0,
        valid = true
    }

    if (_locals and _locals.valid) then chunk_data_vals = locals.collate_chunk_data({ chunk_size = chunk_size, locals = _locals, chunk_data_vals = chunk_data_vals }) end
    if (locals_1) then chunk_data_vals = locals.collate_chunk_data({ chunk_size = chunk_size, locals = locals_1, chunk_data_vals = chunk_data_vals }) end
    if (locals_2) then chunk_data_vals = locals.collate_chunk_data({ chunk_size = chunk_size, locals = locals_2, chunk_data_vals = chunk_data_vals }) end
    if (locals_3) then chunk_data_vals = locals.collate_chunk_data({ chunk_size = chunk_size, locals = locals_3, chunk_data_vals = chunk_data_vals }) end
    if (locals_4) then chunk_data_vals = locals.collate_chunk_data({ chunk_size = chunk_size, locals = locals_4, chunk_data_vals = chunk_data_vals }) end

    if (type(chunk_data_vals) ~= "table" or not chunk_data_vals.valid) then return end

    local chunk_data = Chunk_Data:new({
        chunk_size = chunk_size,
        deaths = chunk_data_vals.deaths,
        entities = chunk_data_vals.entities,
        entity_count = chunk_data_vals.entity_count,
        pollution_data = Pollution_Data:new({
            pollution = chunk_data_vals.pollution or surface.get_pollution(position),
            tick_current = game.tick,
            tick_next = game.tick,
            tick_past = game.tick,
        }),
        recent_deaths = Recent_Death_Data:new(),
        rocket_launches = chunk_data_vals.rocket_launches,
        spawners = chunk_data_vals.spawners,
        spawner_count = chunk_data_vals.spawner_count,
        surface = surface,
        surface_name = surface.name,
        tick_attack_next = game.tick,
        tick_current = game.tick,
        tick_next = game.tick,
        tick_past = game.tick,
        tick_rocket_launch_witnessed = nil,
        tick_witnessed = chunk_data_vals.witnessed_tick,
        weight = chunk_data_vals.weight,
        witnessed = chunk_data_vals.witnessed,
        -- x = x,
        -- y = y,
        x = nil,
        y = nil,
        valid = surface.valid,
    })

    -- if (chunk_size > Constants.CHUNK_SIZE) then
    --     -- Log.error(chunk_data_vals)
    --     -- Log.error(chunk_data)
    --     -- Log.error("create_new_chunk - " .. chunk_size)
    --     log("create_new_chunk - " .. chunk_size)
    --     -- log(serpent.block(chunk_data_vals))
    --     -- log(serpent.block(chunk_data))
    -- end

    if (chunk_data_vals.witnessed) then overmind_utils.chunk_witnessed({ chunk = chunk_data }) end

    if (chunk_size == Constants.CHUNK_SIZE) then
        overmind_utils.update_highest_chunks({
            chunk = chunk_data,
            selected_difficulty = selected_difficulty,
            evolution_factor = game.forces["enemy"].get_evolution_factor(overmind.surface_name),
            overmind = overmind,
            mode = "new"
        })
    end

    if (overmind.weighted_chunks.highest and overmind.weighted_chunks.highest == overmind.weighted_chunks.highest.below) then
        Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
        error("pointing to self")
    elseif (overmind.weighted_chunks.highest == nil and overmind.weighted_chunks.size > 0) then
        Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
        error("highest is nil")
    end

    if (table_size(overmind.weighted_chunks.chunks_weighted) >= 0 and table_size(overmind.weighted_chunks.chunks_weighted) ~= overmind.weighted_chunks.size) then
        Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
        error("counts don't match")
    end

    for k, v in pairs(overmind.weighted_chunks.chunks_weighted) do
        if (v ~= overmind.weighted_chunks.highest and v.weight >= overmind.weighted_chunks.highest.weight) then
            -- log(serpent.block(overmind.weighted_chunks))
            Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
            error("highest chunk isn't highest")
        end
    end

    return chunk_data
end

function overmind_utils.get_new_chunk(data)
    Log.debug("overmind_utils.get_new_chunk")
    Log.info(data)

    -- for k, v in pairs(data) do if (k ~= "overmind") then log(serpent.block(v)) end end

    if (type(data.overmind) ~= "table") then return end
    if (type(data.planet) ~= "table") then return end
    if (type(data.chunk) ~= "table") then return end
    if (type(data.depth) ~= "number") then data.depth = 1 end
    -- if (type(data.event) ~= "string") then data.event = "none" end
    if (type(data.event) ~= "number") then data.event = -1 end

    local overmind = data.overmind

    if (data.depth > 12) then
        Log.warn("could not find a new chunk")
        Log.error("returning math.random chunk")
        return {
            x = (math.random() * overmind.max_distance.pos_x + math.random() * overmind.max_distance.neg_x) / 2,
            y = (math.random() * overmind.max_distance.pos_y + math.random() * overmind.max_distance.neg_y) / 2,
            valid = true,
        }
    end

    -- local overmind = data.overmind
    local planet = data.planet
    local chunk = data.chunk

    local position = {
        x = chunk.x,
        y = chunk.y,
    }

    if (chunk.x > 0 and chunk.x > overmind.max_distance.pos_x) then overmind.max_distance.pos_x = chunk.x end
    if (chunk.y > 0 and chunk.y > overmind.max_distance.pos_y) then overmind.max_distance.pos_y = chunk.y end

    if (chunk.x < 0 and chunk.x < overmind.max_distance.neg_x) then overmind.max_distance.neg_x = chunk.x end
    if (chunk.y < 0 and chunk.y < overmind.max_distance.neg_y) then overmind.max_distance.neg_y = chunk.y end


    local neg_x = -1
    if (not overmind.max_distance.neg_x or overmind.max_distance.neg_x == nil) then overmind.max_distance.neg_x = -1 end
    if (overmind.max_distance.neg_x) then neg_x = overmind.max_distance.neg_x end

    local pos_x = 1
    if (not overmind.max_distance.pos_x or overmind.max_distance.pos_x == nil) then overmind.max_distance.pos_x = 1 end
    if (overmind.max_distance.pos_x) then pos_x = overmind.max_distance.pos_x end

    local x = math.floor(math.random(neg_x or -1, pos_x or 1))
    -- x = x - x % 1
    -- x = math.floor(x)

    local neg_y = -1
    if (not overmind.max_distance.neg_y or overmind.max_distance.neg_y == nil) then overmind.max_distance.neg_y = -1 end
    if (overmind.max_distance.neg_y) then neg_y = overmind.max_distance.neg_y end

    local pos_y = 1
    if (not overmind.max_distance.pos_y or overmind.max_distance.pos_y == nil) then overmind.max_distance.pos_y = 1 end

    if (overmind.max_distance.pos_y) then pos_y = overmind.max_distance.pos_y end

    local y = math.floor(math.random(neg_y or -1, pos_y or 1))
    -- y = y - y % 1
    -- y = math.floor(y)

    chunk.x = x
    chunk.y = y

    local surface = game.surfaces[planet.string_val]

    if (surface and surface.valid and not surface.is_chunk_generated({ x, y })) then
        if (x > 0) then
            if (overmind.max_distance.pos_x > 2) then
                overmind.max_distance.pos_x = overmind.max_distance.pos_x / 2
            end
        else
            if (overmind.max_distance.neg_x < -2) then
                overmind.max_distance.neg_x = overmind.max_distance.neg_x / 2
            end
        end

        if (y > 0) then
            if (overmind.max_distance.pos_y > 2) then
                overmind.max_distance.pos_y = overmind.max_distance.pos_y / 2
            end
        else
            if (overmind.max_distance.neg_y < -2) then
                overmind.max_distance.neg_y = overmind.max_distance.neg_y / 2
            end
        end

        Log.warn("chunk not generated - getting new chunk")
        -- return overmind_utils.get_new_chunk(overmind, planet, surface.get_random_chunk(), depth + 1)
        data.chunk = surface.get_random_chunk()
        data.depth = data.depth + 1
        return overmind_utils.get_new_chunk(data)
    end

    -- if (not overmind.chunks[x]) then
    -- if (type(overmind.chunks[x]) ~= "table") then
    --     if (not overmind.chunks.queue or overmind.chunks.queue.count == nil) then
    if (type(overmind.chunks.chunks_1[x]) ~= "table") then
        if (not overmind.chunks.chunks_1.queue or overmind.chunks.chunks_1.queue.count == nil) then
            -- Overmind_Repository.get_overmind_data(overmind.surface_name):reinit()
            overmind = Overmind_Data:reinit(overmind)
        end

        -- log("overmind-utils 1")
        overmind_utils.stage_new_chunk({
            chunk_size = Constants.CHUNK_SIZE,
            event = data.event,
            -- queue = overmind.chunks.queue,
            -- queue = overmind.chunks.queue.count <= overmind.chunks_priority_low.count * 1.5 and overmind.chunks.queue
            -- queue = overmind.chunks.chunks_1.queue.count <= overmind.chunks_priority_low.count * 1.5 and overmind.chunks.chunks_1.queue
            --     or overmind.chunks_priority_low.count <= overmind.chunks_priority_medium.count * 1.5 and overmind.chunks_priority_medium
            --     or overmind.chunks_priority_medium.count,
            queue = overmind.chunks.chunks_1.queue,
            chunk_pos = {
                x = x,
                y = y,
            },
            surface = surface,
            position = position
        })
    else
        local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(planet.string_val)]]
        -- if (type(overmind.chunks[x][y]) ~= "table" or not overmind.chunks[x][y].valid) then
        --     if (not overmind.chunks.queue or overmind.chunks.queue.count == nil) then Overmind_Repository.get_overmind_data(overmind.surface_name):reinit() end
        if (type(overmind.chunks.chunks_1[x][y]) ~= "table" or not overmind.chunks.chunks_1[x][y].valid) then
            if (not overmind.chunks.chunks_1.queue or overmind.chunks.chunks_1.queue.count == nil) then Overmind_Repository.get_overmind_data(overmind.surface_name):reinit() end

            -- log("overmind-utils 2")
            overmind_utils.stage_new_chunk({
                chunk_size = Constants.CHUNK_SIZE,
                event = data.event,
                -- queue = overmind.chunks.queue,
                -- queue = overmind.chunks.queue.count <= overmind.chunks_priority_low.count * 1.5 and overmind.chunks.queue
                -- queue = overmind.chunks.chunks_1.queue.count <= overmind.chunks_priority_low.count * 1.5 and overmind.chunks.chunks_1.queue
                --     or overmind.chunks_priority_low.count <= overmind.chunks_priority_medium.count * 1.5 and overmind.chunks_priority_medium
                --     or overmind.chunks_priority_medium.count,
                queue = overmind.chunks.chunks_1.queue,
                chunk_pos = {
                    x = x,
                    y = y,
                },
                surface = surface,
                position = position
            })
        -- elseif (type(overmind.chunks[x][y].tick_next) == "number" and game.tick >= overmind.chunks[x][y].tick_next) then
        --     overmind.chunks[x][y].tick_past = overmind.chunks[x][y].tick_current
        --     overmind.chunks[x][y].tick_current = game.tick
        --     overmind.chunks[x][y].tick_next = game.tick + math.random(36000 / selected_difficulty.value)
        elseif (type(overmind.chunks.chunks_1[x][y].tick_next) == "number" and game.tick >= overmind.chunks.chunks_1[x][y].tick_next) then
            overmind.chunks.chunks_1[x][y].tick_past = overmind.chunks.chunks_1[x][y].tick_current
            overmind.chunks.chunks_1[x][y].tick_current = game.tick
            overmind.chunks.chunks_1[x][y].tick_next = game.tick + math.random(36000 / selected_difficulty.value)
        else
            -- if (type(overmind.chunks[x][y].tick_next) == "number" and game.tick < overmind.chunks[x][y].tick_next) then
            --     overmind.chunks[x][y].tick_next = overmind.chunks[x][y].tick_next * (1 / selected_difficulty.radius_modifier)
            if (type(overmind.chunks.chunks_1[x][y].tick_next) == "number" and game.tick < overmind.chunks.chunks_1[x][y].tick_next) then
                overmind.chunks.chunks_1[x][y].tick_next = overmind.chunks.chunks_1[x][y].tick_next * (1 / selected_difficulty.radius_modifier)
            end
            Log.debug("getting new chunk")

            overmind.max_distance.pos_x = overmind.max_distance.pos_x + 1
            overmind.max_distance.pos_y = overmind.max_distance.pos_y + 1
            overmind.max_distance.neg_x = overmind.max_distance.neg_x - 1
            overmind.max_distance.neg_y = overmind.max_distance.neg_y - 1

            -- return overmind_utils.get_new_chunk(overmind, planet, surface.get_random_chunk(), depth + 1)
            data.chunk = surface.get_random_chunk()
            data.depth = data.depth + 1
            return overmind_utils.get_new_chunk(data)
        end
    end

    chunk.surface = surface
    chunk.valid = true

    return chunk
end

function overmind_utils.update_highest_chunks(data)
    Log.debug("overmind_utils.update_highest_chunks")
    Log.info(data)

    if (data == nil or type(data) ~= "table") then return end
    if (data.chunk == nil or type(data.chunk) ~= "table") then return end
    if (data.chunk.weight == nil or type(data.chunk.weight) ~= "number" or data.chunk.weight < 0) then data.chunk.weight = 0 end
    if (data.selected_difficulty == nil or type(data.selected_difficulty) ~= "table") then return end
    if (data.overmind == nil or type(data.overmind) ~= "table") then return end
    if (data.overmind.weighted_chunks == nil or type(data.overmind.weighted_chunks) ~= "table") then return end
    if (data.evolution_factor == nil or type(data.evolution_factor) ~= "number") then data.evolution_factor = game.forces["enemy"].get_evolution_factor(overmind.surface_name) end
    if (data.mode == nil or type(data.mode) ~= "string") then data.mode = "" end
    if (data.new_weight ~= nil and type(data.new_weight) ~= "number") then data.new_weight = data.chunk.weight end

    local chunk = data.chunk
    local overmind = data.overmind

    local weighted_chunks = overmind.weighted_chunks
    local weight_index_old = math.floor(chunk.weight)
    local evolution_factor = data.evolution_factor
    local selected_difficulty = data.selected_difficulty
    local root = 1 / selected_difficulty.value

    local weight = data.new_weight or chunk.weight
    if (data.mode ~= "new" and not data.new_weight) then
        weight = weight + ((chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor) ^ 0.5
        weight = weight ^ root
    end
    local weight_index_new = math.floor(weight)

    for k, v in pairs(overmind.weighted_chunks.chunks_weighted) do
        if (overmind.weighted_chunks.size > 1 and v ~= overmind.weighted_chunks.highest and v.weight >= overmind.weighted_chunks.highest.weight) then
            Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
            error("highest chunk isn't highest")
        end
    end

    if (weight_index_old >= 0) then
        if (    weighted_chunks.chunks_weighted[weight_index_old] ~= nil
            and weighted_chunks.size > 0)
        then
            weighted_chunks.size = weighted_chunks.size - 1

            if (weighted_chunks.size > 0 and weighted_chunks.highest == weighted_chunks.chunks_weighted[weight_index_old]) then
                weighted_chunks.highest = weighted_chunks.highest.below
            end

            weighted_chunks.chunks_weighted[weight_index_old] = nil
        end
    end

    if (weight_index_new > 0) then
        if (weighted_chunks.chunks_weighted[weight_index_new] == nil) then
            weighted_chunks.size = weighted_chunks.size + 1
            weighted_chunks.chunks_weighted[weight_index_new] = chunk
        else
            weighted_chunks.chunks_weighted[weight_index_new] = chunk
        end
        chunk.weight = weight

        -- Actually sort the list
        -- -> Trying for cocktail-shaker sort
        local list = {}
        local count = 0

        for _, v in pairs(weighted_chunks.chunks_weighted) do
            count = count + 1
            list[count] = v
        end

        local swaps = 0
        for i = 1, count, 1 do
            swaps = 0
            for j = i, count, 1 do
                if (not list[j + 1]) then break end
                if (list[j].weight > list[j + 1].weight) then
                    swaps = swaps + 1
                    local temp = list[j]
                    list[j] = list[j + 1]
                    list[j + 1] = temp
                end
            end
            if (swaps == 0) then break end

            swaps = 0
            for j = count, i, -1 do-- for j = count, 1, -1 do
                if (not list[j - 1]) then break end
                if (list[j].weight < list[j - 1].weight) then
                    swaps = swaps + 1
                    local temp = list[j]
                    list[j] = list[j - 1]
                    list[j - 1] = temp
                end
            end
            if (swaps == 0) then break end
        end

        if (count > 2 ^ 8) then
            local diff = count - 2 ^ 8
            for i = 1, diff, 1 do
                list[i] = nil
            end
        end

        local highest = nil
        for i = 1, count, 1 do
            if (list[i]) then
                if (highest == nil or highest.weight < list[i].weight) then highest = list[i] end
                if (list[i - 1]) then list[i - 1].above = list[i] end
                -- if (list[i - 1] and highest and list[i - 1].weight > highest.weight) then highest = list[i - 1] end
                list[i].below = list[i - 1]
                -- if (highest and list[i].weight > highest.weight) then highest = list[i] end
                list[i].above = list[i + 1]
                if (list[i + 1]) then list[i + 1].below = list[i] end
                -- if (list[i + 1] and highest and list[i + 1].weight > highest.weight) then highest = list[i + 1] end
            end
        end

        -- if (count > 0) then weighted_chunks.highest = list[count] end
        weighted_chunks.highest = highest


        local t = weighted_chunks.highest
        local found = {}

        local i = 1
        while t ~= nil do
            -- log(i)
            if (found[t]) then Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick); error("cycle found while checking order") end
            if ((t == weighted_chunks.highest and not t.below) and (table_size(weighted_chunks.chunks_weighted) > 1 or weighted_chunks.size > 1)) then Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick); error("highest is detached") end
            if (t == weighted_chunks.highest and t.above) then Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick); error("highest has an above") end
            if (t.above and t.weight > t.above.weight) then Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick); error("t is higher than above") end
            if (t.below and t.weight < t.below.weight) then Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick); error("t is lower than below") end
            found[t] = i
            t = t.below
            i = i + 1
            -- if (i > 2 ^ 8) then error("too many iterations without completing") end
            if (i > 2 ^ 10) then error("too many iterations without completing") end
        end

    end
end

function overmind_utils.chunk_witnessed(data)
    Log.debug("overmind_utils.chunk_witnessed")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.chunk) ~= "table" or not data.chunk.valid) then return end

    local chunk = data.chunk

    if (chunk.witnessed) then
        if (not chunk.tick_witnessed) then chunk.tick_witnessed = game.tick end
        if (chunk.witnessed_data and not chunk.witnessed_data[game.tick]) then
            local witnessed_data = {
                tick = game.tick,
                newer = nil,
                older = chunk.witnessed_data.newest,
                x = chunk.x,
                y = chunk.y,
            }
            chunk.witnessed_data[game.tick] = witnessed_data

            local newest = chunk.witnessed_data.newest
            local oldest = chunk.witnessed_data.oldest

            witnessed_data.older = newest
            if (newest) then newest.newer = witnessed_data end

            chunk.witnessed_data.newest = witnessed_data
            chunk.witnessed_data.count = chunk.witnessed_data.count + 1

            if (type(oldest) ~= "table") then chunk.witnessed_data.oldest = witnessed_data end

            if (chunk.witnessed_data.count > 4) then
                if (type(oldest) == "table") then chunk.witnessed_data.oldest = oldest.newer end

                oldest.older = nil
                oldest.newer = nil
                chunk.witnessed_data[oldest.tick] = nil
                chunk.witnessed_data.oldest.older = nil

                if (chunk.witnessed_data.count > 0) then chunk.witnessed_data.count = chunk.witnessed_data.count - 1 end
            end
        end
    end
end

function locals.gather_sub_chunk_data(data)
    Log.debug("locals.gather_sub_chunk_data")
    Log.info(data)

    -- if (data.chunk_size and data.chunk_size > Constants.CHUNK_SIZE) then
    --     -- Log.error(data)
    --     -- serpent.block((data))
    -- end

    if (type(data) ~= "table") then return end
    if (type(data.chunk) ~= "table") then return end
    if (type(data.locals) ~= "table") then return end
    if (type(data.locals.weight) ~= "number") then return end
    if (type(data.locals.rocket_launches) ~= "number") then return end
    if (type(data.locals.deaths) ~= "number") then return end
    if (type(data.overmind) ~= "table") then return end

    local chunk = data.chunk
    local overmind = data.overmind

    if (chunk.witnessed) then
        data.locals.witnessed = true
    end

    if (chunk.weight > 0) then
        data.locals.weight = data.locals.weight + chunk.weight
    end

    if (chunk.rocket_launches > 0) then
        data.rocket_launches = data.locals.rocket_launches + chunk.rocket_launches
    end

    if (chunk.deaths > 0) then
        data.locals.deaths = data.locals.deaths + chunk.deaths
    end

    if (chunk.pollution_data.pollution > 0) then
        data.locals.pollution = data.locals.pollution + chunk.pollution_data.pollution
    end

    if (chunk.entity_count > 0) then
        -- Log.error(data.locals.entity_count)
        -- Log.error("entity_count - " .. chunk.entity_count)
        -- log("chunk_size = " .. chunk.chunk_size)
        for _, v in pairs(chunk.entities) do
            -- if (v and v.valid and v.unit_number) then
            if (v and v.entity and v.entity.valid and v.unit_number) then
                if (    (v and v.valid and v.unit_number)
                    or  (type(v) == "table" and v.entity and v.entity.valid and v.entity.unit_number))
                then
                    local unit_number = v.unit_number or v.entity.unit_number
                    local name = v.name or v.entity.name
                    local type = v.type or v.entity.type
                    local force = v.force or v.entity.force
                    local surface = v.surface or v.entity.surface
                    local entity = v.valid and v or v.entity.valid and v.entity
                    if (data.locals.entities[unit_number] == nil) then
                        data.locals.entities[unit_number] = {
                            unit_number = unit_number,
                            name = name,
                            type = type,
                            force = {
                                name = force.name,
                                index = force.index,
                            },
                            surface = {
                                name  = surface.name,
                                index  = surface.index,
                            },
                            entity = {
                                type = entity.type,
                                name = entity.name,
                                force = {
                                    index = entity.force.index,
                                    name = entity.force.name,
                                    valid = entity.force.valid,
                                },
                                surface = entity.surface,
                                position = entity.position,
                                unit_number = unit_number,
                                valid = entity.valid,
                            },
                            position = entity.position,
                            weight = 1
                        }

                        data.locals.entity_count = data.locals.entity_count + 1
                    end
                end
            end
        end
    end

    if (chunk.spawner_count > 0) then
        data.locals.witnessed = true
        -- Log.error(data.locals.spawner_count)
        -- if (chunk.surface_name == "nauvis") then
        --     Log.error("spawner_count - " .. chunk.spawner_count)
        --     log(serpent.block(#chunk.spawners))
        --     -- log(serpent.block(chunk.spawners))
        --     -- log(serpent.block(chunk))
        -- end
        for _, v in pairs(chunk.spawners) do
            if (v and v.valid and v.unit_number) then
                if (data.locals.spawners[v.unit_number] == nil) then
                    data.locals.spawners[v.unit_number] = v
                    data.locals.spawner_count = data.locals.spawner_count + 1
                end
                if (overmind.spawners[v.unit_number] == nil) then
                    overmind.spawners[v.unit_number] = v
                    overmind.spawner_count = overmind.spawner_count + 1
                end
            end
        end
    end

    return data.locals
end

function locals.collate_chunk_data (data)
    Log.debug("locals.collate_chunk_data")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.locals) ~= "table") then return end
    if (type(data.chunk_data_vals) ~= "table") then return end

    local _locals = data.locals
    local chunk_data_vals = data.chunk_data_vals

    if (_locals.witnessed) then chunk_data_vals.witnessed = true end
    if (_locals.witnessed_tick) then chunk_data_vals.witnessed_tick = game.tick end
    if (_locals.deaths) then chunk_data_vals.deaths = chunk_data_vals.deaths + _locals.deaths end
    if (_locals.pollution) then chunk_data_vals.pollution = chunk_data_vals.pollution + _locals.pollution end
    if (_locals.rocket_launches) then chunk_data_vals.rocket_launches = chunk_data_vals.rocket_launches + _locals.rocket_launches end
    if (_locals.entities) then
        -- Log.error("collating entities")
        -- Log.error(_locals.entities)
        for _, v in pairs(_locals.entities) do
            -- Log.error("collating")
            -- Log.error(v)
            -- if (v and v.valid and v.unit_number and k == v.unit_number) then
            if (    (v and v.valid and v.unit_number)
                or  (type(v) == "table" and v.entity and v.entity.valid and v.entity.unit_number))
            then
                -- Log.error("collating valid entity")
                local unit_number = v.unit_number or v.entity.unit_number
                local name = v.name or v.entity.name
                local type = v.type or v.entity.type
                local force = v.force or v.entity.force
                local surface = v.surface or v.entity.surface
                local entity = v.valid and v or v.entity.valid and v.entity
                if (not chunk_data_vals.entities[unit_number]) then
                    chunk_data_vals.entities[unit_number] = {
                        unit_number = unit_number,
                        name = name,
                        type = type,
                        force = {
                            name = force.name,
                            index = force.index,
                        },
                        surface = {
                            name  = surface.name,
                            index  = surface.index,
                        },
                        entity = {
                            type = entity.type,
                            name = entity.name,
                            force = {
                                index = entity.force.index,
                                name = entity.force.name,
                                valid = entity.force.valid,
                            },
                            surface = entity.surface,
                            position = entity.position,
                            unit_number = unit_number,
                            valid = entity.valid,
                        },
                        position = entity.position,
                        weight = weight_modifier
                    }
                end
            end
        end
    end
    if (_locals.entity_count) then chunk_data_vals.entity_count = chunk_data_vals.entity_count + _locals.entity_count end
    if (_locals.spawners) then
        -- Log.error(_locals.spawners)
        for _, v in pairs(_locals.spawners) do
            if (v and v.valid and v.unit_number) then
                if (not chunk_data_vals.spawners[v.unit_number]) then
                    chunk_data_vals.spawners[v.unit_number] = v
                end
            end
        end
    end
    if (_locals.spawner_count) then chunk_data_vals.spawner_count = chunk_data_vals.spawner_count + _locals.spawner_count end

    -- if (data.chunk_size and data.chunk_size > Constants.CHUNK_SIZE) then
    --     log(serpent.block(chunk_data_vals))
    -- end

    -- Log.error("collated_chunk_data")
    if (data.chunk_size > Constants.CHUNK_SIZE and not data.locals.selected_difficulty.string_val:find("Vanilla")) then
        -- Log.error(chunk_data_vals)
        -- Log.error(chunk_data)
        if (Constants.chunk_sizes_map[data.chunk_size] > 57) then
            Log.error("collated chunk_data, level - " .. Constants.chunk_sizes_map[data.chunk_size])
        else
            log("collated chunk_data, level - " .. Constants.chunk_sizes_map[data.chunk_size])
        end
        -- Log.error("collated chunk_data, size - " .. Constants.chunk_sizes[Constants.chunk_sizes_map[data.chunk_size] - 1])
        -- log(serpent.block(locals))
        -- log(serpent.block(chunk_data_vals))
    end

    return chunk_data_vals
end

return overmind_utils
