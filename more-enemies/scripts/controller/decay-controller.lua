local storage
local stats_data
local chunks_arrs
local chunk_maps
local decay
local entity_chunks
local entity_maps
local spawner_maps
local surfaces

local game
local planetary_surfaces

local Surfaces = Surfaces

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local string_find = string.find

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.chunks_arrs = storage.chunks_arrs or {}
    chunks_arrs = storage.chunks_arrs

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.decay = storage.decay or {}
    decay = storage.decay

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

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

        chunks_arrs[planet] = chunks_arrs[planet] or surfaces[planet].chunks
        entity_chunks[planet] = entity_chunks[planet] or surfaces[planet].entity_chunks
        chunk_maps[planet] = chunk_maps[planet] or surfaces[planet].chunk_map
        entity_maps[planet] = entity_maps[planet] or surfaces[planet].entity_maps
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_map
    end

    game = __game or _ENV.game

    _ENV.Surfaces = _ENV.Surfaces or {}
    Surfaces = _ENV.Surfaces
    Surfaces.list = Surfaces.list or {}
    for name, surface in pairs(game.surfaces) do
        if (surface.valid and not string_find(surface.name, "platform%-[%d]*")) then
            Surfaces[name] = surface
            Surfaces.list[surface.index] = name
        else
            Surfaces[name] = nil
        end
    end
    planetary_surfaces = Surfaces

    return game
end

local math_exp = math.exp
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local math_random = math.random
local pairs = pairs
local table_insert = table.insert
local table_size = table_size

local NTH_TICK = 12

local Log = Log

local Planets = Planets
local num_planets = table_size(Planets)
local planets = {}

local i = 0
local modulo = NTH_TICK
for _, planet in pairs(Planets) do
    local idx = i % modulo + 1
    planets[idx] = planets[idx] or {}
    table_insert(planets[idx], planet)
    i = i + 1
end

local Quadtree_Service = require("scripts.service.quadtree-service")
local apply_metrics = Quadtree_Service.apply_metrics
local remove_node = Quadtree_Service.remove_node

local decay_controller = {}
decay_controller.name = "decay_controller"
decay_controller.set_game = set_game

local DECAY_CONSTANT = 0.00001
local NEGATIVE_DECAY = -1 * DECAY_CONSTANT
local PRUNING_THRESHOLD = 1
local SCAR_STRESS_THRESHOLD = 2^17
local SCAR_WEIGHT_FLOOR = 50
local SCAR_PRIORITY_FLOOR = 3

local SIGN_OF_THE_BEAST = 666
local BASE_DELAY = 60*SIGN_OF_THE_BEAST

local DEFAULT_EMPTY_METRIC = { w = 0, fx = 0, p = 1, }

function decay_controller.on_nth_tick(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    local tick = event.tick or 0
    local inverse_stress = 1 - (stats_data.meta.last_load or 0)
    local sample_size = 1 + math_floor(9 * inverse_stress)

    if (not planetary_surfaces) then set_game() end
    decay = decay or set_game() and decay

    -- for _, surface_name in ipairs(planets[(tick / NTH_TICK ) % NTH_TICK + 1] or {}) do
    for _, surface_name in ipairs(planets[(tick / NTH_TICK ) % NTH_TICK] or {}) do
        if (not planetary_surfaces[surface_name] or not planetary_surfaces[surface_name].valid) then goto continue end

        chunks_arrs = chunks_arrs or set_game() and chunks_arrs
        chunks_arrs[surface_name] = chunks_arrs[surface_name] or {}
        local chunks_arr = chunks_arrs[surface_name]

        decay[surface_name] = decay[surface_name] or {}
        decay[surface_name].idx = decay[surface_name].idx or #chunks_arr

        local surface_decay = decay[surface_name]
        local curr_chunk_idx = surface_decay.idx or #chunks_arr
        local quota = math_min(sample_size, curr_chunk_idx)
        local num_processed = 0

        while num_processed < quota and curr_chunk_idx > 0 do
            local idx = curr_chunk_idx - num_processed
            if (idx < 1) then break end

            local rand = math_random(idx)
            local chunk = chunks_arr[rand]

            chunks_arr[rand] = chunks_arr[idx]
            chunks_arr[idx] = chunk

            if (    chunk
                and chunk.xy
                and chunk.meta
            ) then
                chunk_maps = chunk_maps or set_game() and chunk_maps
                chunk_maps[surface_name] = chunk_maps[surface_name] or {}
                local chunk_map = chunk_maps[surface_name]

                local mapped_chunk = chunk_map[chunk.xy]
                if (not mapped_chunk) then
                    chunk_map[chunk.xy] = chunk
                elseif (mapped_chunk ~= chunk) then
                    chunks_arr[idx] = mapped_chunk
                    chunk = mapped_chunk
                end

                local meta = chunk.meta
                local delta_t = tick - (meta.last_decayed_tick or meta.updated or meta.created or 0)

                if (delta_t > 0) then
                    local decay_factor = 0.1 + 0.9 * math_exp(NEGATIVE_DECAY * delta_t)

                    if ((meta.death_weight or 0) > SCAR_STRESS_THRESHOLD) then
                        num_processed = num_processed + 1

                        local old_w = meta.total_weight or 0
                        local old_fx = meta.aggregate_fx or 0

                        meta.total_weight = math_max(SCAR_WEIGHT_FLOOR, old_w * decay_factor)
                        meta.aggregate_fx = math_max(SCAR_WEIGHT_FLOOR / 10, old_fx * decay_factor)
                        meta.max_priority = math_max(SCAR_PRIORITY_FLOOR, meta.max_priority or 1)
                        -- meta.updated = tick

                        if (chunk.parent_node) then
                            apply_metrics(chunk, { w = meta.total_weight - old_w, fx = meta.aggregate_fx - old_fx, p = meta.max_priority, }, event.tick)
                        end
                    else
                        if (meta.total_weight <= PRUNING_THRESHOLD) then
                            if (    (chunk.entity_count or 0)  <= 0
                                and (chunk.spawner_count or 0) <= 0
                                and (meta.max_priority or 1)   <= PRUNING_THRESHOLD
                                and (meta.player_heat or 0)    <= 0
                                and (meta.enemy_heat or 0)     <= 0
                                and (meta.player_deaths or 0)  <= 0
                                and (meta.enemy_deaths or 0)   <= 0
                                and (   not meta.witnessed
                                    or  meta.witnessed
                                    and (meta.witnessed_tick or 0) < math_max(tick - BASE_DELAY, 0)
                                )
                            ) then
                                chunk_map[chunk.xy or ""] = nil

                                if (chunk.parent_node) then apply_metrics(chunk, { w = -1 * (meta.total_weight or 0), fx = -1 * (meta.aggregate_fx or 0), p = 1, }, event.tick) end
                                remove_node({ surface_name = surface_name, source_chunk = chunk, })

                                local tail_count = #chunks_arr
                                if (idx ~= tail_count) then chunks_arr[idx] = chunks_arr[tail_count] end
                                chunks_arr[tail_count] = nil

                                curr_chunk_idx = curr_chunk_idx - 1
                                quota = math_min(sample_size, curr_chunk_idx)

                                goto skip
                            end
                        end

                        num_processed = num_processed + 1
                        decay_factor = math_sqrt(decay_factor)

                        local old_w  = meta.total_weight or 0
                        local old_fx = meta.aggregate_fx or 0

                        meta.total_weight = old_w * decay_factor
                        meta.aggregate_fx = old_fx * decay_factor

                        meta.enemy_deaths = math_floor((meta.enemy_deaths or 0) * decay_factor)
                        meta.player_deaths = math_floor((meta.player_deaths or 0) * decay_factor)

                        if (chunk.parent_node) then apply_metrics(chunk, { w = meta.total_weight - old_w, fx = meta.aggregate_fx - old_fx, p = meta.max_priority or 1, }, event.tick) end
                    end
                    meta.last_decayed_tick = tick
                    meta.updated = tick
                else
                    num_processed = num_processed + 1
                end
            end
            ::skip::
        end

        curr_chunk_idx = curr_chunk_idx - num_processed
        if (curr_chunk_idx < 1) then curr_chunk_idx = #chunks_arr end
        surface_decay.idx = curr_chunk_idx

        ::continue::
    end
end
Event_Handler:register_event({
    event_name = "on_nth_tick",
    nth_tick = NTH_TICK,
    source_name = "decay_controller.on_nth_tick",
    func_name = "decay_controller.on_nth_tick",
    func = decay_controller.on_nth_tick,
})

function decay_controller.init(__storage) storage = __storage or _ENV.storage end

return decay_controller