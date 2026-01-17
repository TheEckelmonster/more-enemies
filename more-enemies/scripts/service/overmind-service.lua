
local Attack_Group_Service = require("scripts.service.attack-group-service")
local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
local Cache_Data = require("scripts.data.cache-data")
local Chunk_Data = require("scripts.data.chunk-data.chunk-data")
local Constants = require("libs.constants.constants")
local Log = require("libs.log.log")
local Overmind_Repository = require("scripts.repositories.overmind-repository")
local Overmind_Utils = require("scripts.utils.overmind-utils")
-- local Queue_Data = require("scripts.data.structures.queue-data")
-- local Recent_Death_Data = require("scripts.data.chunk-data.recent-deaths-data")
local Settings_Service = require("scripts.service.settings-service")

local locals = {}

local overmind_service = {}

local cache = {}
local cache_attributes = {}
setmetatable(cache_attributes, { __mode = "k" })

cache.do_highest_attack = {}
function overmind_service.do_highest_attack(data)
    Log.error("overmind_service.do_highest_attack")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.chunk) ~= "table" or not data.chunk.valid) then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.evolution_factor) ~= "number") then data.evolution_factor = 0.5 end
    if (type(data.planet) ~= "table") then return end

    local chunk = data.chunk
    local overmind = data.overmind
    local selected_difficulty = data.selected_difficulty
    local root = 1 / selected_difficulty.value
    local evolution_factor = data.evolution_factor
    local planet = data.planet

    -- Log.error(chunk.weight)
    chunk.tick_attack = game.tick
    local tick_modifier = ((selected_difficulty.radius_modifier ^ 2) * evolution_factor)
    chunk.tick_attack_next = game.tick + math.random(60 + 90 * tick_modifier, 1800 / tick_modifier)

    chunk.tick_past = chunk.tick_current
    chunk.tick_current = game.tick
    -- chunk.tick_next = Settings_Service.get_overmind_chunk_tick_step(surface.name)
    Log.warn(planet.string_val .. " - " .. chunk.tick_attack_next)
    Log.warn(planet.string_val .. " - " .. game.tick)

    if (Settings_Service.get_do_attack_group(planet.string_val)) then
        -- local chunk_highest = overmind.weighted_chunks.highest
        Log.warn("attempting highest attack")
        Attack_Group_Service.do_attack_group({
            -- event = event.name,
            overmind = overmind,
            planet = planet,
            chunk = chunk
        })

        for k, v in pairs(overmind.weighted_chunks.chunks_weighted) do
            if (v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
                -- log(serpent.block(overmind.weighted_chunks))
                Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                error("highest chunk isn't highest")
            end
        end

        -- local new_weight = chunk.weight + (chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor
        local new_weight = chunk.weight + ((chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor) ^ 0.5
        new_weight = new_weight ^ root

        Overmind_Utils.update_highest_chunks({
            chunk = chunk,
            selected_difficulty = selected_difficulty,
            evolution_factor = evolution_factor,
            overmind = overmind,
            new_weight = new_weight
        })

        for k, v in pairs(overmind.weighted_chunks.chunks_weighted) do
            if (overmind.weighted_chunks.highest == nil) then
                Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                error("highest chunk is nil")
            end
            if (table_size(overmind.weighted_chunks.chunks_weighted) > 0 and v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
                -- log(serpent.block(overmind.weighted_chunks))
                Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                error("highest chunk isn't highest")
            end
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
            if (v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
                -- log(serpent.block(overmind.weighted_chunks))
                Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                error("highest chunk isn't highest")
            end
        end

        -- TODO: Make this into an event call to a given queue
        return locals.send_attack_if_spawner_near_player_entities({ source = "highest", overmind = overmind, chunk = chunk, })
    end
end

function overmind_service.do_expansion(data)
    Log.debug("overmind_service.do_expansion")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.chunk) ~= "table" or not data.chunk.valid) then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.evolution_factor) ~= "number") then data.evolution_factor = 0.5 end
    if (type(data.surface) ~= "userdata" or not data.surface.valid) then return end

    local overmind = data.overmind
    local chunk = data.chunk
    local selected_difficulty = data.selected_difficulty
    local evolution_factor = data.evolution_factor
    local surface = data.surface

    local spawner = Attack_Group_Utils.get_closest_spawner({ chunk = chunk, surface = surface, })
    if (not spawner or not spawner.valid) then return end

    log("valid spawner found for expansion")
    local radius = (Constants.CHUNK_SIZE / 1.5) * selected_difficulty.radius_modifier * ((1 + (evolution_factor ^ 0.75)) / 2)
    local position = surface.find_non_colliding_position(spawner, spawner.position, radius, 0.5, true)

    if (position) then
        Log.error("expansion: " .. serpent.line({ x = chunk.x, y = chunk.y }))

        game.get_player(1).add_pin({ surface = surface, position = position })

        local root = 1 / selected_difficulty.value
        local rand = 1 + selected_difficulty.value + math.random(2) * math.random(math.random(math.ceil((1 + selected_difficulty.value) * (evolution_factor ^ root))), math.ceil((1 + selected_difficulty.value ^ 2 + selected_difficulty.value ^ 2 * math.log(((10 - 10 * Constants.e ^ (-((evolution_factor ^ root) ^ 2)) + 1)), Constants.e))))

        Log.error("expansion: spawner base building group size: " .. rand)
        log("expansion: spawner base building group size: " .. rand)
        surface.build_enemy_base(position, rand, "enemy")
    end
end

function overmind_service.do_random_expansion(data)
    Log.debug("overmind_service.do_random_expansion")
    Log.info(data)

    -- for k, v in pairs(data) do if (k ~= "overmind") then log(serpent.block(v)) end end

    -- log("process_random_expansion 3")
    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.chunk) ~= "table" or not data.chunk.valid) then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.evolution_factor) ~= "number") then data.evolution_factor = 0.5 end
    -- if (type(data.planet) ~= "table") then return end
    if (type(data.surface) ~= "userdata" or not data.surface.valid) then return end

    local chunk = data.chunk
    -- local overmind = data.overmind
    local selected_difficulty = data.selected_difficulty
    local root = 1 / selected_difficulty.radius_modifier
    local evolution_factor = data.evolution_factor
    local surface = data.surface
    local planet = { string_val = data.overmind.surface_name }

    -- local chunk = Overmind_Utils.get_new_chunk({
    --     overmind = data.overmind,
    --     -- planet = data.planet,
    --     planet = planet,
    --     chunk = data.surface.get_random_chunk(),
    -- })
    -- log(serpent.block(chunk))
    local pos = chunk and { x = chunk.x * 32, y = chunk.y * 32, valid = chunk.valid } or nil
    local count = 0
    -- local name = surface.name == "gleba" and "gleba-spawner" or "biter-spawner"
    local name = { "water", "deepwater", "water-green", "deepwater-green", "out-of-map", "water-wube" }

    local tile_count = nil
    if (chunk and chunk.valid) then
        tile_count = surface.count_tiles_filtered({
            area = {{ chunk.x * 32, chunk.y * 32 }, { chunk.x * 32 + 32, chunk.y * 32 + 32 }},
            name = name,
        })
    end

    if (tile_count == nil or tile_count > (32 ^ 2) / 2) then
        -- Log.error("too many invalid tiles for expansion in chunk: " .. serpent.line(chunk))
        pos = nil
        chunk = nil
    end

    while chunk == nil or not chunk.valid do
        count = count + 1; if (count >= 1 + 2 * selected_difficulty.value) then break end
        if (pos) then
            break
        else
            chunk = Overmind_Utils.get_new_chunk({
                overmind = data.overmind,
                -- planet = data.planet,
                planet = planet,
                chunk = data.surface.get_random_chunk(),
            })
        end

        if (chunk and chunk.valid) then
            tile_count = surface.count_tiles_filtered({
                area = {{ chunk.x * 32, chunk.y * 32 }, { chunk.x * 32 + 32, chunk.y * 32 + 32 }},
                name = name,
            })

            if (tile_count < (32 ^ 2) / 2) then
                pos = { chunk.x * 32, chunk.y * 32 }
            end
        end
    end

    -- log("process_random_expansion 4")

    if (chunk and chunk.valid) then
        Log.error("random expansion: " .. serpent.line({ x = chunk.x, y = chunk.y }))
        if (pos == nil) then Log.warn("Could not find_non_colliding_position_in_box for: ".. serpent.line({ x = chunk.x * 32, y = chunk.y * 32 })); return end

        game.get_player(1).add_pin({ surface = surface, position = pos })

        local rand = 1 + selected_difficulty.value + math.random(3) * math.random(math.random(math.ceil((1 + selected_difficulty.value) * (evolution_factor ^ root))), math.ceil((1 + selected_difficulty.value ^ 2 + selected_difficulty.value ^ 2 * math.log(((10 - 10 * Constants.e ^ (-((evolution_factor ^ root) ^ 2)) + 1)), Constants.e))))

        Log.warn("random expansion: spawner base building group size: " .. rand)
        log("random expansion: spawner base building group size: " .. rand)
        surface.build_enemy_base(pos, rand, "enemy")
    end
end

function overmind_service.process_random_chunk(data)
    Log.error("overmind_service.process_random_chunk")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.chunk) ~= "table") then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.surface) ~= "userdata" or not data.surface.valid) then return end
    if (type(data.evolution_factor) ~= "number") then return end

    local overmind = data.overmind
    local random_chunk = data.chunk
    local selected_difficulty = data.selected_difficulty
    local root = 1 / selected_difficulty.value
    local surface = data.surface
    local evolution_factor = data.evolution_factor

    -- log("process_random_chunk")
    local weight = Overmind_Utils.process_chunk({
        event_name = -1,
        chunk = random_chunk,
        surface = surface,
        radius = 1 + selected_difficulty.value,
        spawners_optional = true,
    })

    -- TODO: Make this into an event call to a given queue
    locals.send_attack_if_spawner_near_player_entities({ source = "random_chunk", overmind = overmind, chunk = random_chunk, })
    -- locals.send_attack_if_spawner_near_player_entities({ overmind = overmind, chunk = random_chunk })

    random_chunk.tick_past = random_chunk.tick_current
    random_chunk.tick_current = game.tick
    -- random_chunk.tick_next = game.tick + math.random(60 + 90 / ((selected_difficulty.radius_modifier ^ 2) * evolution_factor_diff), 18000 / ((selected_difficulty.radius_modifier ^ 2) * evolution_factor_diff))
    random_chunk.tick_next = game.tick + math.random(300 + 300 / ((selected_difficulty.radius_modifier ^ 2) * evolution_factor), 18000 + 18000 / ((selected_difficulty.radius_modifier ^ 2) * evolution_factor))

    if (type(weight) ~= "number") then weight = 0 end
    if (random_chunk.weight < 0) then random_chunk.weight = 0 end

    -- local weighted_chunks = overmind.weighted_chunks
    -- local weight_index_old = math.floor(random_chunk.weight)
    local multiplier = math.random() + (math.random(50, 100) / 100)
    if (multiplier > 1) then multiplier = 1 end
    -- random_chunk.weight = random_chunk.weight * multiplier
    local new_weight = random_chunk.weight
    new_weight = new_weight ^ root
    -- random_chunk.weight = random_chunk.weight ^ root
    -- random_chunk.weight = random_chunk.weight + weight
    -- random_chunk.weight = random_chunk.weight + weight + (chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor
    new_weight = new_weight + weight + ((chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor) ^ 0.95
    -- if (random_chunk.weight < 0) then random_chunk.weight = 0 end
    if (new_weight < 0) then new_weight = 0 end
    -- local weight_index_new = math.floor(random_chunk.weight)

    Overmind_Utils.update_highest_chunks({
        chunk = random_chunk,
        selected_difficulty = selected_difficulty,
        evolution_factor = evolution_factor,
        overmind = overmind,
        new_weight = new_weight
    })

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
        if (v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
            -- log(serpent.block(overmind.weighted_chunks))
            Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
            error("highest chunk isn't highest")
        end
    end

    return true
end

function overmind_service.process_ordered_chunk(data)
    Log.debug("overmind_service.process_ordered_chunk")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.chunks) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.evolution_factor) ~= "number") then return end
    if (type(data.root) ~= "number") then return end

    local chunks = data.chunks
    local overmind = data.overmind
    local selected_difficulty = data.selected_difficulty
    local evolution_factor = data.evolution_factor
    local root = data.root

    local chunk_x, chunk_y = nil, nil
    local x,y = chunks.x, chunks.y
    -- if (overmind.chunks[chunks.x] == nil) then chunks.x = nil end
    if (overmind.chunks.chunks_1[chunks.x] == nil) then chunks.x = nil end

    -- x, chunk_x = next(overmind.chunks, chunks.x)
    x, chunk_x = next(overmind.chunks.chunks_1, chunks.x)

    if (chunk_x ~= nil) then
        if (chunks.y == nil or chunk_x[chunks.y]) then
            y, chunk_y = next(chunk_x, chunks.y)

            local weight
            if (type(chunk_y) == "table") then
                -- log("process_ordered_chunk")
                weight = Overmind_Utils.process_chunk({
                    event_name = -1,
                    chunk = chunk_y,
                    surface = chunk_y.surface,
                    radius = 1 + selected_difficulty.value,
                    spawners_optional = true,
                })
            end

            -- locals.send_attack_if_spawner_near_player_entities({ source = "chunk_y", overmind = overmind, chunk = chunk_y, planet = { string_val = chunk_y.surface.name }, })

            if (type(weight) ~= "number") then weight = 0 end
            if (type(chunk_y) == "table") then
                if (type(chunk_y.weight) ~= "number" or chunk_y.weight < 0) then chunk_y.weight = 0 end

                locals.send_attack_if_spawner_near_player_entities({ source = "chunk_y", overmind = overmind, chunk = chunk_y, })

                -- local weighted_chunks = overmind.weighted_chunks
                -- local weight_index_old = math.floor(chunk_y.weight)
                -- local multiplier = math.random() + (math.random(50, 100) / 100)
                -- if (multiplier > 1) then multiplier = 1 end
                local new_weight = chunk_y.weight ^ root
                new_weight = new_weight + weight

                if (new_weight > 1 and new_weight < 2) then
                    if (type(chunk_y.surface) == "userdata" and chunk_y.surface.valid) then
                        new_weight = new_weight * (0.0025 + math.random(selected_difficulty.radius) * evolution_factor) + chunk_y.surface.get_pollution({ x = chunk_y.x * 32, y = chunk_y.y * 32 }) * evolution_factor
                    end
                end

                Overmind_Utils.update_highest_chunks({
                    chunk = chunk_y,
                    selected_difficulty = selected_difficulty,
                    evolution_factor = evolution_factor,
                    overmind = overmind,
                    new_weight = new_weight
                })

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
                    if (v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
                        -- log(serpent.block(overmind.weighted_chunks))
                        Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                        error("highest chunk isn't highest")
                    end
                end
            end
        else
            y = nil
        end
    end
    if (y == nil) then chunks.x = x end
    if (x == nil) then y = nil end
    chunks.y = y
end

function overmind_service.process_staged_chunk(data)
    Log.debug("overmind_service.process_staged_chunk")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.queue) ~= "table") then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.evolution_factor) ~= "number") then return end

    local overmind = data.overmind
    local queue = data.queue
    local selected_difficulty = data.selected_difficulty
    local evolution_factor = data.evolution_factor

    local staged_chunk

    if (type(queue) == "table" and type(queue.name) == "string") then
        staged_chunk, _ = queue:next({
            source = queue.name .. " count = " .. queue.count .. " - overmind_service - process_staged_chunk",
            order = "first",
            maintain = false,
        })
    else
        log("queue is not valid")
        log(serpent.block(queue))
    end

    if (type(staged_chunk) ~= "table") then
        -- log(serpent.line(staged_chunk))
        -- log("queue - " .. queue.name .. ", count = " .. queue.count)
        return
    end

    local x = staged_chunk.x
    local y = staged_chunk.y

    local chunk_level = Constants.chunk_sizes_map[staged_chunk.chunk_size]
    if (Constants.chunk_sizes[chunk_level]) then
        if (type(overmind.chunks["chunks_" .. chunk_level][x]) ~= "table") then overmind.chunks["chunks_" .. chunk_level][x] = {} end
        if (type(overmind.chunks["chunks_" .. chunk_level][x][y]) ~= "table" or not overmind.chunks["chunks_" .. chunk_level][x][y].valid) then
            overmind.chunks["chunks_" .. chunk_level][x][y] = Overmind_Utils.create_new_chunk({
                overmind = overmind,
                surface = staged_chunk.surface,
                position = staged_chunk.position,
                area = staged_chunk.area,
                witnessed = false,
                chunk_size = staged_chunk.chunk_size,
            })
            if (type(overmind.chunks["chunks_" .. chunk_level][x][y]) == "table") then
                overmind.chunks["chunks_" .. chunk_level][x][y].x = x
                overmind.chunks["chunks_" .. chunk_level][x][y].y = y
            end
        end
    else
        log(serpent.block(chunk_level))
        log(serpent.block(staged_chunk))
        error("invalid chunk level/size")
        return
    end

    local chunk = nil

    for k, v in pairs(Constants.chunk_sizes) do
        if (staged_chunk.chunk_size == v) then
            chunk = overmind.chunks["chunks_" .. k][x][y]
            break
        end
    end

    if (chunk == nil or type(chunk) ~= "table") then
        log(serpent.block(type(chunk)))
        log(serpent.block(chunk))
        log(serpent.block(staged_chunk))
        error("how")
        chunk = Chunk_Data:new({ valid = false })
    end

    if (chunk == nil) then return end

    -- local chunk = overmind.chunks[x][y]
    if (chunk.x ~= x) then chunk.x = x end
    if (chunk.y ~= y) then chunk.y = y end

    if (chunk.x > 0 and chunk.x > overmind.max_distance.pos_x) then overmind.max_distance.pos_x = chunk.x end
    if (chunk.y > 0 and chunk.y > overmind.max_distance.pos_y) then overmind.max_distance.pos_y = chunk.y end

    if (chunk.x < 0 and chunk.x < overmind.max_distance.neg_x) then overmind.max_distance.neg_x = chunk.x end
    if (chunk.y < 0 and chunk.y < overmind.max_distance.neg_y) then overmind.max_distance.neg_y = chunk.y end

    local spawners_optional = false
    local spawners_required = false
    local target_cause = false
    local check_personal_space = false

    if (type(staged_chunk.event) == "number") then
        if (staged_chunk.event < 0) then
            spawners_optional = true
            check_personal_space = true
        elseif (staged_chunk.event == defines.events.on_biter_base_built) then
        elseif (staged_chunk.event == defines.events.on_build_base_arrived) then
        elseif (staged_chunk.event == defines.events.on_built_entity) then
        elseif (staged_chunk.event == defines.events.on_cargo_pod_finished_descending) then
        elseif (staged_chunk.event == defines.events.on_chunk_generated) then
        elseif (staged_chunk.event == defines.events.on_entity_damaged) then
            spawners_optional = true
            if (staged_chunk.cause and staged_chunk.cause.valid) then
                target_cause = true
                check_personal_space = true
            end
            chunk.witnessed = true
        elseif (staged_chunk.event == defines.events.on_entity_died) then
            if (staged_chunk.entity and staged_chunk.entity.type == "unit-spawner") then
                spawners_optional = true
                if (staged_chunk.cause and staged_chunk.cause.valid) then
                    target_cause = true
                    check_personal_space = true
                end
                chunk.witnessed = true
            elseif (staged_chunk.entity and staged_chunk.entity.force.name == "enemy") then
                if (staged_chunk.cause and staged_chunk.cause.valid) then
                    target_cause = true
                end
                chunk.witnessed = true
            end
        elseif (staged_chunk.event == defines.events.on_entity_spawned) then
        elseif (staged_chunk.event == defines.events.on_player_changed_position) then
        elseif (staged_chunk.event == defines.events.on_player_died) then
        elseif (staged_chunk.event == defines.events.on_player_driving_changed_state) then
        elseif (staged_chunk.event == defines.events.on_player_mined_entity) then
        elseif (staged_chunk.event == defines.events.on_player_mined_item) then
        elseif (staged_chunk.event == defines.events.on_player_mined_tile) then
        elseif (staged_chunk.event == defines.events.on_robot_built_entity) then
        elseif (staged_chunk.event == defines.events.on_robot_built_tile) then
        elseif (staged_chunk.event == defines.events.on_robot_exploded_cliff) then
        elseif (staged_chunk.event == defines.events.on_robot_mined) then
        elseif (staged_chunk.event == defines.events.on_robot_mined_entity) then
        elseif (staged_chunk.event == defines.events.on_robot_mined_tile) then
        elseif (staged_chunk.event == defines.events.on_rocket_launch_ordered) then
        end
    else
        return false, staged_chunk
        -- goto before_cleaning_1
    end

    if (chunk.witnessed) then Overmind_Utils.chunk_witnessed({ chunk = chunk }) end

    local weight = 0
    -- local weight_index_old = math.floor(chunk.weight) or weight

    -- This temporary
    -- TODO: Remove this
    -- if (staged_chunk.chunk_size ~= Constants.CHUNK_SIZE) then goto before_cleaning_1 end
    -- if (staged_chunk.chunk_size == Constants.CHUNK_SIZE) then
        -- log(overmind.surface_name .. " - process_staged_chunk - " .. tostring(staged_chunk.chunk_size))
        -- weight = Overmind_Utils.process_chunk({
        --     overmind = type(staged_chunk.event) == "number" and staged_chunk.event < 0 and overmind,
        --     event_name = staged_chunk.event,
        --     entity = staged_chunk.entity,
        --     cause = staged_chunk.cause,
        --     chunk = chunk,
        --     surface = staged_chunk.surface,
        --     radius = 1 + selected_difficulty.value,
        --     spawners_optional = spawners_optional,
        --     spawners_required = spawners_required,
        --     target_cause = target_cause,
        --     witnessed = staged_chunk.witnessed,
        --     source = "overmind_service.process_staged_chunk",
        -- })
        local _data = {
            overmind = type(staged_chunk.event) == "number" and staged_chunk.event < 0 and overmind or nil,
            event_name = staged_chunk.event,
            entity = staged_chunk.entity,
            cause = staged_chunk.cause,
            chunk = chunk,
            surface = staged_chunk.surface,
            radius = 1 + selected_difficulty.value,
            spawners_optional = spawners_optional,
            spawners_required = spawners_required,
            target_cause = target_cause,
            witnessed = staged_chunk.witnessed,
            source = "overmind_service.process_staged_chunk",
        }
        weight = Overmind_Utils.process_chunk(_data)
    -- end
    if (weight == nil) then
        Constants.table.traverse_print(_data, "Overmind_Utils.process_chunk(data)." .. overmind.surface_name .. "_" .. game.tick)
        error("hWat?")
    end

    -- log("weight = " .. tostring(weight))
    if (type(weight) ~= "number") then weight = 0 end
    -- if (type(chunk.weight) ~= "number" or chunk.weight < 0) then chunk.weight = 0 end
    if (type(chunk.weight) ~= "number") then chunk.weight = 0 end --[[ TODO: Come back to this ]]

    local weighted_chunks = overmind.weighted_chunks
    -- local weight_index_old = math.floor(chunk.weight)

    -- TODO: Make this depend on the calling event
    -- local multiplier = math.random() + (math.random(50, 100) / 100)
    local multiplier = 1
    if (type(staged_chunk.event) == "number") then
        if (staged_chunk.event < 0) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_biter_base_built) then
        elseif (staged_chunk.event == defines.events.on_build_base_arrived) then
        elseif (staged_chunk.event == defines.events.on_built_entity) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_cargo_pod_finished_descending) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_chunk_generated) then
        elseif (staged_chunk.event == defines.events.on_entity_damaged) then
        elseif (staged_chunk.event == defines.events.on_entity_died) then
        elseif (staged_chunk.event == defines.events.on_entity_spawned) then
        elseif (staged_chunk.event == defines.events.on_player_changed_position) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_player_died) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_player_driving_changed_state) then
        elseif (staged_chunk.event == defines.events.on_player_mined_entity) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_player_mined_item) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_player_mined_tile) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_robot_built_entity) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_robot_built_tile) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_robot_exploded_cliff) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_robot_mined) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_robot_mined_entity) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_robot_mined_tile) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        elseif (staged_chunk.event == defines.events.on_rocket_launch_ordered) then
            multiplier = math.random() + (math.random(50, 100) / 100)
        end
    else
        return false, staged_chunk
        -- goto before_cleaning_1
    end

    if (staged_chunk.chunk_size == Constants.CHUNK_SIZE) then
        if (multiplier > 1) then multiplier = 1 end
        local new_weight = chunk.weight * multiplier
        -- log(new_weight)
        -- chunk.weight = chunk.weight * multiplier
        -- -- chunk.weight = chunk.weight ^ root
        -- -- chunk.weight = chunk.weight + weight
        -- chunk.weight = chunk.weight + weight + (chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor
        new_weight = new_weight + weight + (chunk.entity_count * selected_difficulty.radius_modifier) * evolution_factor
        -- log(new_weight)

        -- if (chunk.weight > --[[ TODO: Make configurable? ]] 2 ^ 42 ) then chunk.weight = 2 ^ 42 end
        -- if (chunk.weight < 0) then chunk.weight = 0 end
        if (new_weight > --[[ TODO: Make configurable? ]] 2 ^ 42 ) then new_weight = 2 ^ 42 end
        if (new_weight < 0) then new_weight = 0 end

        Overmind_Utils.update_highest_chunks({
            chunk = chunk,
            selected_difficulty = selected_difficulty,
            evolution_factor = evolution_factor,
            overmind = overmind,
            new_weight = new_weight
        })

        if (table_size(overmind.weighted_chunks.chunks_weighted) >= 0 and table_size(overmind.weighted_chunks.chunks_weighted) ~= overmind.weighted_chunks.size) then
            Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
            error("counts don't match")
        end

        for k, v in pairs(overmind.weighted_chunks.chunks_weighted) do
            if (v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
                Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                error("highest chunk isn't highest")
            end
        end

        if (overmind.weighted_chunks.highest and overmind.weighted_chunks.highest == overmind.weighted_chunks.highest.below) then
            Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
            error("pointing to self")
        elseif (overmind.weighted_chunks.highest == nil and overmind.weighted_chunks.size > 0) then
            Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
            error("highest is nil")
        end

        if (check_personal_space) then
            -- Log.error("checking personal space")
            if (staged_chunk.event < 0) then
                -- Log.error("chunk update personal space")
                -- if (game.tick % 4 == 2) then
                    -- Log.error("chunk update personal space " .. game.tick)
                    locals.send_attack_if_spawner_near_player_entities({ source = "process_staged", overmind = overmind, chunk = chunk })
                -- end
            else
                -- Log.error("non-chunk update personal space")
                locals.send_attack_if_spawner_near_player_entities({ source = "process_staged", overmind = overmind, chunk = chunk })
            end

            -- log("overmind-service 1")
            if (overmind.chunks_priority_high.count < overmind.chunks_priority_high.limit / 1.5) then
                Overmind_Utils.stage_new_chunk({
                    chunk_size = Constants.CHUNK_SIZE,
                    event = -1,
                    queue =    overmind.chunks_priority_high.count < overmind.chunks_priority_high.limit / 1.5 and overmind.chunks_priority_high
                            or overmind.chunks_priority_medium.count < overmind.chunks_priority_medium.limit / 1.5 and overmind.chunks_priority_medium
                            or overmind.chunks_priority_low.count < overmind.chunks_priority_low.limit / 1.5 and overmind.chunks_priority_low,
                    chunk_pos = {
                        x = chunk.x,
                        y = chunk.y,
                    },
                    surface = overmind.surface,
                    position = staged_chunk.position,
                    witnessed = staged_chunk.witnessed,
                })
            end
            if (overmind.chunks.chunks_1.queue.count < overmind.chunks.chunks_1.queue.limit / 1.5) then
                Overmind_Utils.stage_new_chunk({
                    chunk_size = Constants.CHUNK_SIZE,
                    event = -1,
                    queue = overmind.chunks.chunks_1.queue,
                    chunk_pos = {
                        x = chunk.x,
                        y = chunk.y,
                    },
                    surface = overmind.surface,
                    position = staged_chunk.position,
                    witnessed = staged_chunk.witnessed,
                })
            end
        end
    end

    local no_data_of_interest =     type(chunk) == "table"
                                and chunk.entity_count <= 0
                                and chunk.deaths <= 0
                                and chunk.pollution_data.pollution <= 0
                                and chunk.spawner_count <= 0
                                and chunk.rocket_launches <= 0
                                and chunk.weight <= 1.00025
                                and chunk.witnessed == false
                                -- and false --[[ TODO: Remove this hopefully ]]


    -- -- local tick_modifier = chunk_level * (4 * selected_difficulty.radius ^ 2 + ((Constants.e * selected_difficulty.value * Constants.time.TICKS_PER_MINUTE) / 1.25 + math.random((Constants.e * selected_difficulty.value * Constants.time.TICKS_PER_MINUTE) / 5 ) * (evolution_factor ^ (1 / selected_difficulty.radius_modifier))))
    -- local tick_modifier = chunk_level * (16 * selected_difficulty.radius ^ 2 + ((Constants.e * selected_difficulty.value * Constants.time.TICKS_PER_MINUTE) / 1.25 + math.random((Constants.e * selected_difficulty.value * Constants.time.TICKS_PER_MINUTE) / 5 ) * (evolution_factor ^ (1 / selected_difficulty.radius_modifier))))
    -- tick_modifier = math.floor(tick_modifier)
    -- log(tick_modifier)
    -- log(game.tick)
    -- if ((   type(chunk) == "table"
    --     and chunk.entity_count <= 0
    --     and chunk.deaths <= 0
    --     and chunk.pollution_data.pollution <= 0
    --     and chunk.spawner_count <= 0
    --     and chunk.rocket_launches <= 0
    --     -- and chunk.weight <= 1.00025)
    --     and chunk.weight <= 1.00025
    --     and chunk.witnessed == false)
    if (   no_data_of_interest
        -- and chunk.witnessed == false
    --     or (chunk.witnessed == true
    --    and chunk.witnessed_data.count > 0
    --     -- and chunk.witness_data.newest <= game.tick + 12345 --[[ TODO: Come up with a better value for this ]]
    -- --    and chunk.witnessed_data.newest.tick <= game.tick + chunk_level * (4 * selected_difficulty.radius ^ 2 + ((Constants.e * selected_difficulty.value * Constants.time.TICKS_PER_MINUTE) / 1.25 + math.random((Constants.e * selected_difficulty.value * Constants.time.TICKS_PER_MINUTE) / 5 ) * (evolution_factor ^ (1 / selected_difficulty.radius_modifier)))))
    --    and chunk.witnessed_data.newest.tick <= game.tick - tick_modifier)
    ) then
        local _, v = next(chunk.spawners)
        if (v) then
            -- log(serpent.block(chunk)); error("tried to remove chunk with spawners");
            Overmind_Utils.chunk_witnessed({ chunk = chunk })
            goto continue
        end
        _, v = next(chunk.entities)
        if (v) then
            Log.error("tried to remove chunk with entities")
            goto continue
        end

        -- log("removing chunk")
        -- log("removing chunk: " .. tostring(chunk.chunk_size) .. " - position: x = " .. chunk.x .. ", y = " .. chunk.y)
        -- -- log(serpent.block(chunk))
        -- log(chunk.chunk_size)
        -- log(serpent.block(chunk.weight))
        if (chunk.chunk_size > Constants.CHUNK_SIZE) then
            log("x: " .. chunk.x .. ", y: " .. chunk.y .. ", chunk_size = " .. chunk.chunk_size)
        end
        -- log("no_data_of_interest = " .. tostring(no_data_of_interest))

        -- log(type(chunk))
        -- log(chunk.entity_count)
        -- log(chunk.deaths)
        -- log(chunk.pollution_data.pollution)
        -- log(chunk.spawner_count)
        -- log(chunk.rocket_launches)
        -- log(chunk.weight)
        -- log(chunk.witnessed)

        for k, v in pairs(Constants.chunk_sizes) do
            if (staged_chunk.chunk_size == v) then
                -- log("chunk_" .. k)
                overmind.chunks["chunks_" .. k][x][y] = nil
                -- if (type(chunk.above) == "table" and type(chunk.below) == "table") then chunk.above.below = chunk.below.above end
                -- if (type(chunk.above) == "table" and type(chunk.below) == "table") then chunk.above.below = chunk.below end
                local below = chunk.below
                local above = chunk.above
                if (below) then below.above = above end
                if (above) then above.below = below end
                chunk.above = nil
                chunk.below = nil
                -- if (type(chunk.next) == "table" and type(chunk.prev) == "table") then chunk.next.prev = chunk.prev.next end
                if (type(chunk.next) == "table" and type(chunk.prev) == "table") then chunk.next.prev = chunk.prev end
                chunk.next = nil
                chunk.prev = nil
                if (not next(overmind.chunks["chunks_" .. k][x])) then
                    overmind.chunks["chunks_" .. k][x] = nil
                end

                if (overmind.weighted_chunks.chunks_weighted[math.floor(chunk.weight)]) then
                    -- log(overmind.weighted_chunks.size)
                    overmind.weighted_chunks.size = overmind.weighted_chunks.size - 1
                    -- log(overmind.weighted_chunks.size)
                end
                overmind.weighted_chunks.chunks_weighted[math.floor(chunk.weight)] = nil
                break
            end
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
            if (v ~= overmind.weighted_chunks.highest and k > math.floor(overmind.weighted_chunks.highest.weight)) then
                Constants.table.traverse_print(overmind.weighted_chunks, "overmind.".. overmind.surface_name .. ".weighted_chunks_" .. game.tick)
                error("highest chunk isn't highest")
            end
        end

        ::continue::

    end

    if (no_data_of_interest == false and staged_chunk.chunk_size < Constants.chunk_sizes[Constants.CHUNK_LEVELS - 1]) then

        -- log("overmind-service 2")
        -- Overmind_Utils.stage_new_chunk({
        --     event = -1,
        --     chunk_size = staged_chunk.chunk_size * 2,
        --     queue =    overmind.chunks_priority_high.count < overmind.chunks_priority_high.limit / 1.5 and overmind.chunks_priority_high
        --             or overmind.chunks_priority_medium.count < overmind.chunks_priority_medium.limit / 1.5 and overmind.chunks_priority_medium
        --             or overmind.chunks_priority_low.count < overmind.chunks_priority_low.limit / 1.5 and overmind.chunks_priority_low,
        --     chunk_pos = {
        --         x = math.floor(staged_chunk.x / 2),
        --         y = math.floor(staged_chunk.y / 2),
        --     },
        --     surface = overmind.surface,
        --     position = staged_chunk.position,
        --     witnessed = staged_chunk.witnessed,
        -- })
        -- log(serpent.block(staged_chunk.chunk_size))
        -- log(serpent.block(staged_chunk.chunk_size * 2))
        -- log(serpent.block(chunk_level))
        -- log(serpent.block(chunk_level + 1))
        Overmind_Utils.stage_new_chunk({
            event = -1,
            chunk_size = staged_chunk.chunk_size * 2,
            -- queue = overmind.chunks["chunks_" .. chunk_level].queue,
            queue = overmind.chunks["chunks_" .. chunk_level + 1].queue,
            chunk_pos = {
                x = math.floor(staged_chunk.x / 2),
                y = math.floor(staged_chunk.y / 2),
            },
            surface = overmind.surface,
            position = staged_chunk.position,
            witnessed = staged_chunk.witnessed,
        })
    end

    -- log("processed chunk")
    return true
end

function overmind_service.process_chunk(data)
    Log.debug("overmind_service.process_chunk")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.queue) ~= "table") then return end
    if (type(data.selected_difficulty) ~= "table") then return end
    if (type(data.evolution_factor) ~= "number") then return end

    return overmind_service.process_staged_chunk(data)
end

function overmind_service.on_biter_base_built(event)
    Log.debug("overmind_service.on_biter_base_built")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or event.name ~= defines.events.on_biter_base_built) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.surface or not event.entity.surface.valid ) then return end

    if (not locals.validate_planet({ surface = event.entity.surface })) then return end


end

function overmind_service.on_build_base_arrived(event)
    Log.debug("overmind_service.on_build_base_arrived")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

    if (event.unit and event.unit.valid) then
        if (not locals.validate_planet({ surface = event.unit.surface })) then return end
    elseif (event.commandable and event.commandable.valid) then
        if (not locals.validate_planet({ surface = event.commandable.surface })) then return end
    else
        return
    end

end

function overmind_service.on_built_entity(event)
    Log.debug("overmind_service.on_built_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

end

function overmind_service.on_cargo_pod_finished_descending(event)
    Log.debug("overmind_service.on_cargo_pod_finished_descending")
    Log.info(event)

    if (not event) then return end
    if (not event.tick or not event.cargo_pod or event.launched_by_rocket) then return end

end

function overmind_service.on_chunk_generated(event)
    Log.debug("overmind_service.on_chunk_generated")
    Log.info(event)

    if (not event) then return end
    if (not event.tick ) then return end
    if (not event.name or event.name ~= defines.events.on_chunk_generated) then return end
    if (not event.surface or not event.surface.valid ) then return end
    if (not event.area or not event.area.left_top or not event.area.right_bottom) then return end
    if (not event.area or not event.area.left_top.x or not event.area.left_top.y) then return end
    if (not event.area or not event.area.right_bottom.x or not event.area.right_bottom.y) then return end
    if (not event.position or not event.position.x or not event.position.y) then return end

    local position = event.position
    local surface = event.surface

    local x = position.x
    local y = position.y

    local overmind = Overmind_Repository.get_overmind_data(surface.name)

    -- log("overmind-service 3")
    Overmind_Utils.stage_new_chunk({
        chunk_size = Constants.CHUNK_SIZE,
        event = defines.events.on_chunk_generated,
        -- queue =    overmind.chunks_priority_low.count < 10 and overmind.chunks_priority_low
        --         or overmind.chunks_priority_medium.count < 25 and overmind.chunks_priority_medium
        --         or overmind.chunks_priority_high,
        -- queue =    overmind.chunks_priority_low.count > 1 + overmind.chunks_priority_medium.count * 1.5 and overmind.chunks_priority_low
        --         or overmind.chunks_priority_medium.count > 1 + overmind.chunks_priority_high.count * 1.5 and overmind.chunks_priority_medium
        --         or overmind.chunks_priority_high,
        queue = overmind.chunks_priority_high,
        chunk_pos = {
            x = x,
            y = y,
        },
        surface = surface,
        area = event.area,
        -- position = position
    })

end

function overmind_service.on_player_mined_entity(event)
    Log.debug("overmind_service.on_player_mined_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

end

function overmind_service.on_player_mined_item(event)
    Log.debug("overmind_service.on_player_mined_item")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

end

function overmind_service.on_entity_damaged(event)
    Log.debug("overmind_service.on_entity_damaged")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or not event.name == defines.events.on_entity_damaged) then return end
    if (not event.entity or not event.entity.valid) then return end
    local entity = event.entity
    if (not entity.surface or not entity.surface.valid) then return end
    local surface = entity.surface

    if (not Constants.DEFAULTS.planets[surface.name]) then return end

    local cause = nil
    if (event.cause and not event.cause.valid) then return
    elseif (event.cause and event.cause.valid) then cause = event.cause end

    -- log(serpent.block(event))
    -- log(serpent.block(cause))

    local force = nil
    if (event.force and not event.force.valid) then return
    elseif (event.force and event.force.valid) then force = event.force end

    if (force) then
        local position = entity.position
        if (not position or not position.x or not position.y) then return end

        local x = position.x / Constants.CHUNK_SIZE
        -- x = x - x % 1
        x = math.floor(x)

        local y = position.y / Constants.CHUNK_SIZE
        -- y = y - y % 1
        y = math.floor(y)

        local overmind = Overmind_Repository.get_overmind_data(surface.name)

        -- log("overmind-service 4")
        Overmind_Utils.stage_new_chunk({
            chunk_size = Constants.CHUNK_SIZE,
            event = defines.events.on_entity_damaged,
            -- queue = overmind.chunks_priority_high,
            -- queue =    overmind.chunks_priority_low.count > 1 + overmind.chunks_priority_medium.count * 1.5 and overmind.chunks_priority_low
            --         or overmind.chunks_priority_medium.count > 1 + overmind.chunks_priority_high.count * 1.5 and overmind.chunks_priority_medium
            --         or overmind.chunks_priority_high,
            queue = overmind.chunks_priority_high,
            witnessed = true,
            chunk_pos = {
                x = x,
                y = y,
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
                valid = entity.valid,
            },
            surface = surface,
            position = position,
            cause = cause and {
                type = cause.type,
                name = cause.name,
                force = {
                    index = cause.force.index,
                    name = cause.force.name,
                    valid = cause.force.valid,
                },
                surface = cause.surface,
                position = cause.position,
                valid = cause.valid,
            },
        })

    end
end

function overmind_service.on_entity_died(event)
    Log.debug("overmind_service.on_entity_died")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or not event.name == defines.events.on_entity_died) then return end

    local entity = event.entity
    if (not entity or not entity.valid) then return end
    local surface = entity.surface
    if (not surface or not surface.valid or not surface.name) then return end
    if (not entity.force or not entity.force.valid) then return end

    if (not Constants.DEFAULTS.planets[surface.name]) then return end

    local cause = nil
    if (event.cause and not event.cause.valid) then return
    elseif (event.cause and event.cause.valid) then cause = event.cause end

    local position = entity.position
    if (not position or not position.x or not position.y) then return end

    local x = position.x / Constants.CHUNK_SIZE
    -- x = x - x % 1
    x = math.floor(x)

    local y = position.y / Constants.CHUNK_SIZE
    y = math.floor(y)

    local overmind = Overmind_Repository.get_overmind_data(surface.name)

    -- log("overmind-service 5")
    Overmind_Utils.stage_new_chunk({
        chunk_size = Constants.CHUNK_SIZE,
        event = defines.events.on_entity_died,
        -- queue = overmind.chunks_priority_high,
        -- queue =    overmind.chunks_priority_low.count > 1 + overmind.chunks_priority_medium.count * 1.5 and overmind.chunks_priority_low
        --         or overmind.chunks_priority_medium.count > 1 + overmind.chunks_priority_high.count * 1.5 and overmind.chunks_priority_medium
        --         or overmind.chunks_priority_high,
        queue = overmind.chunks_priority_high,
        witnessed = true,
        chunk_pos = {
            x = x,
            y = y,
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
            valid = entity.valid,
        },
        surface = surface,
        position = position,
        cause = cause and {
            type = cause.type,
            name = cause.name,
            force = {
                index = cause.force.index,
                name = cause.force.name,
                valid = cause.force.valid,
            },
            surface = cause.surface,
            position = cause.position,
            valid = cause.valid,
        },
    })
end

function overmind_service.process_aggregate_entity_died(event_data)
    Log.debug("overmind_service.process_aggregate_entity_died")
    Log.info(event_data)

    if (not event_data) then return end
    if (not event_data.event or event_data.event ~= defines.events.on_entity_died) then return end

    if (not Constants.DEFAULTS.planets[event_data.surface.name]) then return end

    local surface = game.get_surface(event_data.surface.name)
    if (not surface or not surface.valid) then return end

    local position = event_data.entity.position
    if (not position or not position.x or not position.y) then return end

    local x = position.x / Constants.CHUNK_SIZE
    x = math.floor(x)

    local y = position.y / Constants.CHUNK_SIZE
    y = math.floor(y)

    local overmind = Overmind_Repository.get_overmind_data(event_data.surface.name)

    Overmind_Utils.stage_new_chunk({
        chunk_size = Constants.CHUNK_SIZE,
        event = defines.events.on_entity_died,
        queue = overmind.chunks_priority_high,
        witnessed = true,
        chunk_pos = {
            x = x,
            y = y,
        },
        entity = {
            type = event_data.entity.type,
            name = event_data.entity.name,
            force = {
                index = event_data.entity.force.index,
                name = event_data.entity.force.name,
                valid = true,
            },
            surface = event_data.entity.surface_data.surface,
            position = event_data.entity.position,
            valid = true,
        },
        surface = surface,
        position = event_data.entity.position,
        cause = event_data.cause and {
            type = event_data.cause.type,
            name = event_data.cause.name,
            force = {
                index = event_data.cause.force.index,
                name = event_data.cause.force.name,
                valid = true,
            },
            surface = event_data.cause.surface_data.surface,
            position = event_data.cause.position,
            valid = true,
        },
    })
end

function overmind_service.on_robot_built_entity(event)
    Log.debug("overmind_service.on_robot_built_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

end

function overmind_service.on_robot_exploded_cliff(event)
    Log.debug("overmind_service.on_robot_exploded_cliff")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

end

function overmind_service.on_robot_mined_entity(event)
    Log.debug("overmind_service.on_robot_mined_entity")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end

end

function overmind_service.on_rocket_launch_ordered(event)
    Log.debug("overmind_service.on_rocket_launch_ordered")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.name or not event.name == defines.events.on_rocket_launch_ordered) then return end
    if (not event.rocket_silo or not event.rocket_silo.valid) then return end

    local rocket_silo = event.rocket_silo
    if (not rocket_silo.valid) then return end

    local surface = rocket_silo.surface
    if (not surface or not surface.valid) then return end

    local position = rocket_silo.position
    if (not position or not position.x or not position.y) then return end

    -- local overmind = cache[surface.name]
    -- local overmind = Overmind_Repository.get_overmind_data(surface.name)

    -- if (type(overmind) ~= "table") then
    --     local overmind_data = Overmind_Repository.get_overmind_data(surface.name)
    --     if (type(overmind_data) ~= "table") then return end

    --     cache[surface.name] = overmind_data
    --     overmind = overmind_data
    -- end

    local x = position.x / Constants.CHUNK_SIZE
    -- x = x - x % 1
    x = math.floor(x)

    local y = position.y / Constants.CHUNK_SIZE
    -- y = y - y % 1
    y = math.floor(y)

    -- if (not overmind.chunks[x]) then overmind.chunks[x] = {} end
    -- if (not overmind.chunks[x][y]) then
    --     overmind.chunks[x][y] = Overmind_Utils.create_new_chunk({
    --         overmind = overmind,
    --         surface = surface,
    --         position = position,
    --     })
    -- end

    local overmind = Overmind_Repository.get_overmind_data(surface.name)

    -- log("overmind-service 6")
    Overmind_Utils.stage_new_chunk({
        chunk_size = Constants.CHUNK_SIZE,
        event = defines.events.on_rocket_launch_ordered,
        -- queue =    overmind.chunks_priority_low.count > 1 + overmind.chunks_priority_medium.count * 1.5 and overmind.chunks_priority_low
        --         or overmind.chunks_priority_medium,
        queue =    overmind.chunks_priority_medium.count <= overmind.chunks_priority_high.count and overmind.chunks_priority_medium
                or overmind.chunks_priority_high,
        chunk_pos = {
            x = x,
            y = y,
        },
        entity = {
            type = rocket_silo.type,
            name = rocket_silo.name,
            force = {
                index = rocket_silo.force.index,
                name = rocket_silo.force.name,
                valid = rocket_silo.force.valid,
            },
            surface = rocket_silo.surface,
            position = rocket_silo.position,
            valid = rocket_silo.valid,
        },
        surface = surface,
        position = position
    })


    -- local chunk = overmind.chunks[x][y]
    -- if (type(chunk) ~= "table") then return end

    -- -- Log.error("rocket_launches += 1")
    -- chunk.rocket_launches = chunk.rocket_launches + 1

    -- local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(surface.name)]]

    -- local weight, chunk_distance = Overmind_Utils.process_chunk({
    --     event_name = defines.events.on_rocket_launch_ordered,
    --     chunk = chunk,
    --     surface = surface,
    --     entity = rocket_silo,
    --     radius = 1 + 12 * selected_difficulty.radius_modifier,
    -- })

    -- if (type(chunk.weight) ~= "number" or chunk.weight < 0) then chunk.weight = 0 end
    -- if (type(weight) ~= "number" or weight < 0) then weight = 0 end
    -- if (type(chunk_distance) ~= "number" or chunk_distance < 0) then chunk_distance = math.huge end

    -- local weight_index_old = math.floor(chunk.weight)

    -- local evolution_modifier = game.forces["enemy"].get_evolution_factor(surface) ^ (1 / selected_difficulty.value)
    -- local threshold = 0.125
    -- threshold = threshold ^ (1.1 - surface.darkness)

    -- -- if (distance < Constants.CHUNK_SIZE * Settings_Service.get_rocket_witness_chunk_distance(surface.name)) then
    -- if (chunk_distance < 24 * selected_difficulty.radius_modifier) then
    --     chunk.tick_rocket_launch_witnessed = game.tick
    --     chunk.weight = chunk.weight + weight * evolution_modifier
    --     threshold = threshold ^ ((1 - (1/24)) / 1.25)
    -- end

    -- -- if (distance < Constants.CHUNK_SIZE * Settings_Service.get_rocket_hear_chunk_distance(surface.name)) then
    -- if (chunk_distance < 16 * selected_difficulty.radius_modifier) then
    --     chunk.tick_rocket_heard = game.tick
    --     chunk.weight = chunk.weight + (weight ^ 1.0666)  * evolution_modifier
    --     threshold = threshold ^ ((1 - (1/16)) / 1.25)
    -- end

    -- -- if (distance < Constants.CHUNK_SIZE * Settings_Service.get_rocket_feel_chunk_distance(surface.name)) then
    -- if (chunk_distance < 8 * selected_difficulty.radius_modifier) then
    --     chunk.tick_rocket_felt = game.tick
    --     chunk.weight = chunk.weight + (weight ^ 1.0666) * evolution_modifier
    --     threshold = threshold ^ ((1 - (1/8)) / 1.25)
    -- end

    -- local weighted_chunks = overmind.weighted_chunks
    -- local weight_index_new = math.floor(chunk.weight)

    -- if (weight_index_old >= 0) then
    --     if (    weighted_chunks.chunks_weighted[weight_index_old] ~= nil
    --         and weighted_chunks.size > 0)
    --     then
    --         weighted_chunks.size = weighted_chunks.size - 1
    --         local below = weighted_chunks.chunks_weighted[weight_index_old].below
    --         local above = weighted_chunks.chunks_weighted[weight_index_old].above
    --         if (below) then below.above = above end
    --         if (above) then above.below = below end
    --     end
    --     weighted_chunks.chunks_weighted[weight_index_old] = nil
    -- end

    -- if (weight_index_new > 0) then
    --     -- if (weighted_chunks.highest ~= nil) then
    --     --     if (weighted_chunks.highest.weight < chunk.weight) then
    --     --         weighted_chunks.highest = chunk
    --     --     end
    --     -- else
    --     --     weighted_chunks.highest = chunk
    --     -- end

    --     -- if (weighted_chunks.chunks_weighted[weight_index_new] == nil) then weighted_chunks.size = weighted_chunks.size + 1 end
    --     -- weighted_chunks.chunks_weighted[weight_index_new] = chunk

    --     if (weighted_chunks.highest ~= nil) then
    --         if (weighted_chunks.highest.weight <= chunk.weight) then
    --             weighted_chunks.highest.above = chunk
    --             chunk.below = weighted_chunks.highest
    --             weighted_chunks.highest = chunk
    --             chunk.above = nil
    --         end
    --     else
    --         weighted_chunks.highest = chunk
    --     end

    --     if (weighted_chunks.chunks_weighted[weight_index_new] == nil) then
    --         weighted_chunks.size = weighted_chunks.size + 1
    --         weighted_chunks.chunks_weighted[weight_index_new] = chunk
    --     else
    --         local below = weighted_chunks.chunks_weighted[weight_index_new].below
    --         if (below) then below.above = chunk end
    --         local above = weighted_chunks.chunks_weighted[weight_index_new].above
    --         if (above) then above.below = chunk end
    --         weighted_chunks.chunks_weighted[weight_index_new] = chunk
    --     end
    -- end

    -- local rand = math.random()
    -- Log.error(threshold)
    -- Log.error(rand)

    -- if (rand < threshold) then
    --     Attack_Group_Service.do_attack_group({
    --         source = "rocket_launch_ordered",
    --         overmind = overmind,
    --         planet = { string_val = surface.name },
    --         chunk = chunk
    --     })
    -- end
end

function locals.validate_planet(data)
    Log.debug("locals.validate_planet")
    Log.info(data)

    local return_val = false

    if (type(data) ~= "table") then return return_val end
    if (not data.surface or not data.surface.valid) then return return_val end

    return Constants.DEFAULTS.planets[data.surface.name] ~= nil
end

cache.locals = {}
cache.locals.send_attack_if_spawner_near_player_entities = {}
function locals.send_attack_if_spawner_near_player_entities(data)
    Log.debug("locals.send_attack_if_spawner_near_player_entities")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.chunk) ~= "table") then return end
    -- if (type(data.source) ~= "number") then return end

    -- if (data.source) then Log.error(data.source) end

    local _cache = cache.locals.send_attack_if_spawner_near_player_entities
    local chunk = data.chunk
    local overmind = data.overmind

    if (chunk.spawners and #chunk.spawners > 0) then
        local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Settings_Service.get_difficulty(overmind.surface_name)]]
        local root = 1 / selected_difficulty.value
        -- local evolution_factor = game.forces["enemy"].get_evolution_factor(overmind.surface)
        local evolution_factor = game.forces["enemy"].get_evolution_factor(overmind.surface or overmind.surface_name)
        -- local radius = (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2)) * (evolution_factor ^ root)
        local radius = (1 + ((selected_difficulty.value / 1.5) / (selected_difficulty.radius_modifier))) * (evolution_factor ^ root)
        log("radius = " .. radius)

        -- Log.error("chunk has spawners")
        -- Chunk has spawners
        -- Look for player entities
        -- local target_entities = Attack_Group_Utils.get_target_entity({
        --     source = "personal_space",
        --     selected_difficulty = selected_difficulty,
        --     evolution_factor = evolution_factor,
        --     chunk = chunk,
        --     -- radius = (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2)) * (evolution_factor ^ root),
        --     radius = radius,
        --     depth = 1 + (selected_difficulty.value / selected_difficulty.radius_modifier) * (evolution_factor ^ root),
        --     limit = 1 + (selected_difficulty.radius) * selected_difficulty.radius_modifier * (evolution_factor ^ root) ,
        -- })


        local key_rand = --[[ TODO: Make this configurable ]] math.random(math.ceil(1 + selected_difficulty.value * 1.25))
        local key = overmind.surface_name .. "..personal_space..get_target_entities.." .. key_rand

        local target_entities = Cache_Data:get_by_key({
            key = key,
            fallback = function ()
                -- Log.error(key)
                -- log(game.tick)
                -- log(key)

                local target_entities = Attack_Group_Utils.get_target_entity({
                    source = "personal_space",
                    selected_difficulty = selected_difficulty,
                    evolution_factor = evolution_factor,
                    chunk = chunk,
                    -- radius = (selected_difficulty.value / (selected_difficulty.radius_modifier ^ 2)) * (evolution_factor ^ root),
                    radius = (Constants.CHUNK_SIZE / 1.5) * radius,
                    depth = 1 + (selected_difficulty.value / selected_difficulty.radius_modifier) * (evolution_factor ^ root),
                    limit = 1 + (selected_difficulty.radius) * selected_difficulty.radius_modifier * (evolution_factor ^ root) ,
                })

                -- log(serpent.block(target_entities))

                return {
                    key = key,
                    value = target_entities,
                    -- tick_valid_until = game.tick + selected_difficulty.value + (((2 ^ 4) * (selected_difficulty.value ^ 1.5)) ^ 0.75) * (2 ^ (math.random(((math.random(8) + math.random(8)) / 2)))),
                    tick_valid_until = game.tick + selected_difficulty.value + (evolution_factor * (((2 ^ 6) * (selected_difficulty.value ^ 1.5)) ^ 0.75) * (2 ^ (math.random(((math.random(8) + math.random(8)) / 2))))),
                }
            end
        })

        local target_entity = nil
        if (target_entities and #target_entities > 0) then
            target_entity = target_entities[math.random(#target_entities)]
            for _, v in pairs(target_entities) do
                if (v and v.valid and v.name == "character") then
                    Log.error("found character")
                    target_entity = v
                    break
                end
            end
        end

        -- Found target
        if (target_entity and target_entity.valid) then
            -- Log.error("found target")
            -- local enemies = Attack_Group_Utils.get_enemy(overmind.surface, chunk, radius)

            local key = overmind.surface_name .. "..personal_space..get_enemies.." .. key_rand

            local enemies = Cache_Data:get_by_key({
                key = key,
                fallback = function ()
                    -- Log.error(key)
                    -- log(game.tick)
                    -- log(key)

                    local source_spawner = Attack_Group_Utils.get_closest_spawner({
                        chunk = chunk,
                        surface = overmind.surface,
                        closest = true,
                    })

                    -- local source_chunk = chunk
                    local source_chunk = nil
                    if (source_spawner and source_spawner.valid) then
                        local distance = ((target_entity.position.x - source_spawner.position.x) ^ 2 + (target_entity.position.y - source_spawner.position.y) ^ 2) ^ 0.5
                        log("distance = " .. distance)
                        log("radius = " .. ((Constants.CHUNK_SIZE / 1.5) * radius) ^ 0.6)
                        -- if (distance < ((Constants.CHUNK_SIZE / 1.5) * radius) ^ 0.6) then
                        if (distance < Constants.CHUNK_SIZE * ((Constants.CHUNK_SIZE / 1.5) * radius) ^ 0.6) then
                            Log.error(source_spawner)
                            log(serpent.block(source_spawner))
                            source_chunk = {
                                x = math.floor(source_spawner.position.x / 32),
                                y = math.floor(source_spawner.position.y / 32),
                            }
                        end
                    end

                    -- local enemies = Attack_Group_Utils.get_enemy(overmind.surface, chunk, radius)
                    local enemies = Attack_Group_Utils.get_enemy(overmind.surface, source_chunk, radius ^ 0.6) or {}

                    return {
                        key = key,
                        value = enemies,
                        -- tick_valid_until = game.tick + selected_difficulty.value + (((2 ^ 4) * (selected_difficulty.value ^ 1.5)) ^ 0.75) * (2 ^ (math.random(((math.random(8) + math.random(8)) / 2)))),
                        tick_valid_until = game.tick + selected_difficulty.value + (evolution_factor * (((2 ^ 6) * (selected_difficulty.value ^ 1.5)) ^ 0.75) * (2 ^ (math.random(((math.random(8) + math.random(8)) / 2))))),
                    }
                end
            })

            -- Found enemies
            if (enemies and #enemies > 0) then
                -- Log.error("found enemies")
                -- Log.error(evolution_factor)

                local rand = math.random()

                local probability_modifier = Settings_Service.get_spawn_attack_group_probability_modifier(overmind.surface_name)

                -- -- Maximum probability of an attack group spawning at 100% (1) evolution factor
                -- local max_probability = 1 - (1 / selected_difficulty.value)

                -- if (max_probability < 0) then max_probability = 0 end

                -- max_probability = max_probability * probability_modifier

                -- local threshold = max_probability * evolution_factor
                -- Log.error(threshold)
                -- Log.error(rand)

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

                local enemy_rand = math.random(#enemies)

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

                -- if (rand < threshold and enemy_rand and enemies[enemy_rand].valid) then
                if (proceed and enemy_rand and enemies[enemy_rand].valid) then
                    local unit_group = enemies[enemy_rand].surface.create_unit_group({ position = enemies[enemy_rand].position})
                    if (unit_group and unit_group.valid) then

                        local limit = 6 * (selected_difficulty.value * selected_difficulty.radius_modifier) * evolution_factor + math.random(#enemies)

                        for k, v in pairs(enemies) do
                            if (v and v.valid) then
                                v.release_from_spawner()
                                v.ai_settings.allow_try_return_to_spawner = false
                                v.ai_settings.join_attacks = true
                                unit_group.add_member(v)
                            end
                            if (k >= limit) then break end
                        end

                        Log.error("target_entity - source chunk had spawner(s)")
                        Log.error(target_entity)

                        if (target_entity and target_entity.valid) then

                            local x = target_entity.position.x / 32
                            -- x = x - x % 1
                            x = math.floor(x)

                            local y = target_entity.position.y / 32
                            -- y = y - y % 1
                            y = math.floor(y)

                            -- if (chunk.tick_attack_next < game.tick) then
                            --     chunk.tick_attack = game.tick
                            --     chunk.tick_attack_next = game.tick + math.random(90 + 90 / selected_difficulty.value, 60 + 1740 / selected_difficulty.value)

                                -- log("overmind-service 7")
                                Overmind_Utils.stage_new_chunk({
                                    chunk_size = Constants.CHUNK_SIZE,
                                    event = -1,
                                    queue =    overmind.chunks_priority_high.count < overmind.chunks_priority_high.limit / 1.5 and overmind.chunks_priority_high
                                            or overmind.chunks_priority_medium.count < overmind.chunks_priority_medium.limit / 1.5 and overmind.chunks_priority_medium
                                            or overmind.chunks_priority_low.count < overmind.chunks_priority_low.limit / 1.5 and overmind.chunks_priority_low,
                                    chunk_pos = {
                                        x = x,
                                        y = y,
                                    },
                                    surface = target_entity.surface,
                                    position = target_entity.position,
                                    witnessed = true,
                                })
                                -- Overmind_Utils.stage_new_chunk({
                                --     chunk_size = Constants.CHUNK_SIZE,
                                --     event = -1,
                                --     queue = overmind.chunks.chunks_1.queue,
                                --     chunk_pos = {
                                --         x = x,
                                --         y = y,
                                --     },
                                --     surface = target_entity.surface,
                                --     position = target_entity.position,
                                --     witnessed = true,
                                -- })
                            -- end

                            if (x > 0 and x > overmind.max_distance.pos_x) then overmind.max_distance.pos_x = x end
                            if (y > 0 and y > overmind.max_distance.pos_y) then overmind.max_distance.pos_y = y end

                            if (x < 0 and x < overmind.max_distance.neg_x) then overmind.max_distance.neg_x = x end
                            if (y < 0 and y < overmind.max_distance.neg_y) then overmind.max_distance.neg_y = y end

                            local radius_mult = math.random() + 0.25

                            unit_group.set_command({
                                type = defines.command.attack_area,
                                destination = target_entity.position,
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
                    end
                end
            end
        end
    end

    return true
end

return overmind_service