local storage
local stats_data
local system_stats
local chunks_arr
local chunk_maps
local difficulties
local entity_chunks
local entity_maps
local spawner_maps
local quadtrees
local surfaces
local target_registries
local unit_groups

local game
local game_print
local forces
local force_funcs

local Set_Game_Funcs = Set_Game_Funcs

local Quadtree = require("scripts.data.quadtree-data")
local new_Quadtree = Quadtree.new

local Stats_Data = require("scripts.data.stats-data")
local new_Stats_Data = Stats_Data.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.system_stats = storage.system_stats or {}
    system_stats = storage.system_stats

    storage.chunks_arr = storage.chunks_arr or {}
    chunks_arr = storage.chunks_arr

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.target_registries = storage.target_registries or {}
    target_registries = storage.target_registries

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
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_maps
    end

    storage.quadtrees = storage.quadtrees or {}
    quadtrees = storage.quadtrees

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    game = __game or _ENV.game
    game_print = game.print

    -- _ENV.Forces = _ENV.Forces or {}
    -- Forces = _ENV.Forces
    -- Forces.list = Forces.list or {}

    -- _ENV.Force_Funcs = _ENV.Force_Funcs or {}
    -- Force_Funcs = _ENV.Force_Funcs
    -- for name, force in pairs(game.forces) do
    --     if (force.valid) then
    --         Forces[name] = force
    --         Forces.list[force.index] = name
    --         Force_Funcs[name] = Force_Funcs[name] or {}
    --         Force_Funcs[name].get_evolution_factor = force.get_evolution_factor
    --     else
    --         Forces[name] = nil
    --     end
    -- end
    -- forces = Forces
    -- force_funcs = Force_Funcs

    Set_Game_Funcs()
    forces = _ENV.Forces
    force_funcs = _ENV.Force_Funcs

    return game
end

local log = log

local math_ceil = math.ceil
local math_floor = math.floor
local math_exp = math.exp
local math_huge = math.huge
local math_max = math.max
local math_min = math.min
local math_random =  math.random
local math_sqrt = math.sqrt
local table_sort = table.sort

local table_size = table_size

local E = math_exp(1)
local PI = math.pi
local EIGHTH_PI = PI / 8

local UINT16 = 2^16-1
local UINT64 = 2^64-1

local Log = Log

local Constants = Constants or require("scripts.constants.constants")

local Startup_Settings_Constants = Startup_Settings_Constants

local Planets = Planets
local num_planets = table_size(Planets)

local Valid_Surfaces = Valid_Surfaces

local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack
local unpack_coordinates = Coordinate_Utils.unpack
local Leaf_Data = require("scripts.data.leaf-data")
local new_Leaf_Data = Leaf_Data.new
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template
local aggregate_leaf_nodes = Quad_Meta_Data.aggregate_leaf_nodes
local merge_data = Quad_Meta_Data.merge_data
local Quadnode = require("scripts.data.quadnode")
local new_Quadnode = Quadnode.new
local Target_Registry_Data = require("scripts.data.target-registry-data")
local new_Target_Registry_Data = Target_Registry_Data.new
local merge_target_registry = Target_Registry_Data.merge_data

local STATES = require("scripts.constants.conductor-state-constants")

local STATE_RECOVERY = STATES.RECOVERY
local STATE_REQUESTING_PATH = STATES.REQUESTING_PATH

local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, })

local conductor_styles = {
    ["None"] = 0,
    ["Random"] = 1,
    ["Adaptive"] = 2,
    ["Omni-mind"] = 3,
}
local RANDOM = conductor_styles["Random"]
local conductor_style = Data_Utils.get_startup_setting({ setting = Startup_Settings_Constants.settings.CONDUCTOR_STYLE.name, })
local selected_style = conductor_styles[conductor_style]

local HALF_MAP_SIZE = Constants.HALF_MAP_SIZE
local CHUNK_LEVELS = Constants.CHUNK_LEVELS
local MAP_SIZE = 2*HALF_MAP_SIZE

local SHIFT_LOOKUP = SHIFT_LOOKUP

local quadtree_service = {}
quadtree_service.name = "quadtree_service"
quadtree_service.set_game = set_game

local CHUNK_SIZE = Constants.CHUNK_SIZE
local HALF_CHUNK = CHUNK_SIZE / 2
local BASE_SEARCH_RADIUS = 1024 * CHUNK_SIZE
local TWO_CHUNKS = CHUNK_SIZE * 2
local CHUNK_SQUARED = CHUNK_SIZE ^ 2
local CHUNK_CUBED = CHUNK_SIZE ^ 3
local CHUNK_CUBED_SQ = CHUNK_CUBED * CHUNK_CUBED

local SIGN_OF_THE_BEAST = 666
local BASE_DELAY = 60*SIGN_OF_THE_BEAST

local ATTACK, EXPANSION, SCOUT = "attack", "expansion", "scout"

local BOTTOM_UP = "bottom-up"
local TOP_DOWN = "top-down"

local EMPTY = EMPTY

local NW, NE, SW, SE = "nw", "ne", "sw", "se"

local DEFAULT_EMPTY_METRIC = Quad_Meta_Data.DEFAULT_EMPTY_METRIC
local EMPTY_TEMPLATE = Quad_Meta_Data.EMPTY_TEMPLATE


function quadtree_service.add_node(params)
    if (not params) then return end

    params.depth = params.depth or 0
    if (params.depth > CHUNK_LEVELS) then return end

    if (not params.surface_name) then return end
    if (not params.source_chunk) then return end

    local tick = params.tick or set_game().tick

    quadtrees = quadtrees or set_game() and quadtrees

    quadtrees[params.surface_name] = quadtrees[params.surface_name] or new_Quadtree(Quadtree, { surface_name = params.surface_name, })
    local quadtree = quadtrees[params.surface_name]

    quadtree.base = quadtree.base or new_Quadnode(Quadnode, {
        size = MAP_SIZE,
        node_level = 0,
        x = 0,
        y = 0,
        count = 0,
        meta = new_template(Quad_Meta_Data, tick),
    }, tick)
    local base = params.base or quadtree.base
    local parent_node = params.parent_node or base
    -- if (parent_node.size and parent_node.size < 1) then return end
    -- if (parent_node.size and parent_node.size < 0) then return end

    local start_position = params.start_position or { x = 0, y = 0, }
    local direction = ""

    local source_chunk = params.source_chunk
    source_chunk.xy = source_chunk.xy or pack_coordinates(source_chunk.x, source_chunk.y)

    if ((source_chunk.x + 0.5) < start_position.x) then
        direction = ((source_chunk.y + 0.5) < start_position.y) and NW or SW
    else
        direction = ((source_chunk.y + 0.5) < start_position.y) and NE or SE
    end

    chunk_maps = chunk_maps or set_game() and chunk_maps
    chunk_maps[params.surface_name] = chunk_maps[params.surface_name] or {}
    local chunk_map = chunk_maps[params.surface_name]

    chunk_map[source_chunk.xy] = chunk_map[source_chunk.xy] or new_Leaf_Data(Leaf_Data, source_chunk, tick)
    source_chunk = chunk_map[source_chunk.xy]
    source_chunk.meta = source_chunk.meta or new_template(Quad_Meta_Data, tick)
    local c_meta = source_chunk.meta
    c_meta.entity_count = c_meta.entity_count or source_chunk.entity_count
    c_meta.spawner_count = c_meta.spawner_count or source_chunk.spawner_count

    -- if (parent_node[direction] and parent_node.size > 1) then
    if (parent_node[direction] and parent_node.size >= CHUNK_SIZE) then
    -- if (parent_node[direction] and parent_node.size > 0) then
        local next_base = parent_node
        local target_node = parent_node[direction]

        target_node.parent_node = target_node.parent_node or parent_node

        -- local shift_factor = 2 ^ (CHUNK_LEVELS - target_node.node_level)
        local shift_factor = SHIFT_LOOKUP[target_node.node_level]
        local pos = {
            x = math_floor(target_node.x * shift_factor) or 0,
            y = math_floor(target_node.y * shift_factor) or 0,
        }

        if (target_node.chunk) then
            local historical_chunk = target_node.chunk
            local new_direction = ""

            if (    historical_chunk == source_chunk
                or  historical_chunk.x == source_chunk.x
                and historical_chunk.y == source_chunk.y
            ) then
                if (not chunk_map[historical_chunk.xy] or chunk_map[historical_chunk.xy] ~= historical_chunk) then
                    target_node.chunk = new_Leaf_Data(Leaf_Data, historical_chunk, tick)
                    target_node.chunk.meta = new_template(Quad_Meta_Data, tick)
                    chunk_map[historical_chunk.xy] = target_node.chunk
                end
                target_node.parent_node = target_node.parent_node or parent_node

                historical_chunk = chunk_map[historical_chunk.xy]
                historical_chunk.parent_node = target_node
                historical_chunk.meta = historical_chunk.meta or new_template(Quad_Meta_Data, tick)

                source_chunk.parent_node = target_node

                return target_node, historical_chunk
            end

            if ((historical_chunk.x + 0.5) < pos.x) then
                new_direction = ((historical_chunk.y + 0.5) < pos.y) and NW or SW
            else
                new_direction = ((historical_chunk.y + 0.5) < pos.y) and NE or SE
            end

            local next_level = target_node.node_level + 1
            if (next_level <= CHUNK_LEVELS) then
                -- local next_shift = 2 ^ (CHUNK_LEVELS - next_level)
                local next_shift = SHIFT_LOOKUP[next_level]

                target_node[new_direction] = new_Quadnode(Quadnode, {
                    parent_node = target_node,
                    size = target_node.size / 2,
                    node_level = next_level,
                    x = math_floor(historical_chunk.x / next_shift) + 0.5,
                    y = math_floor(historical_chunk.y / next_shift) + 0.5,
                    xy = pack_coordinates(math_floor(historical_chunk.x / next_shift), math_floor(historical_chunk.y / next_shift)),
                    meta = new_template(Quad_Meta_Data, tick),
                }, tick)

                if (not chunk_map[historical_chunk.xy] or chunk_map[historical_chunk.xy] ~= historical_chunk) then
                    historical_chunk.meta = new_template(Quad_Meta_Data, tick)
                    target_node.chunk = new_Leaf_Data(Leaf_Data, historical_chunk, tick)
                    chunk_map[historical_chunk.xy] = target_node.chunk
                end
                historical_chunk = chunk_map[historical_chunk.xy]

                target_node[new_direction].chunk = historical_chunk

                historical_chunk.parent_node = target_node[new_direction]

                base.count = (quadtree.base.count or 0) + 1
                target_node.count = (target_node.count or 0) + 1
                target_node.chunk = nil

                quadtree_service.apply_metrics(historical_chunk, nil, tick)
                -- merge_data(target_node[new_direction].meta, historical_chunk.meta, nil, tick)
            end
        end

        target_node.count = (target_node.count or 0) + 1

        return quadtree_service.add_node({
            tick = tick,
            surface_name = params.surface_name,
            source_chunk = source_chunk,
            parent_node = target_node,
            base = next_base,
            start_position = pos,
            depth = params.depth + 1
        })

    else
        local next_level = parent_node.node_level + 1
        if (next_level <= CHUNK_LEVELS) then
            -- local next_shift = 2 ^ (CHUNK_LEVELS - next_level)
            local next_shift = SHIFT_LOOKUP[next_level]

            parent_node[direction] = new_Quadnode(Quadnode, {
                parent_node = parent_node,
                size = (parent_node.size or HALF_MAP_SIZE) / 2,
                node_level = next_level,
                x = math_floor(source_chunk.x / next_shift) + 0.5,
                y = math_floor(source_chunk.y / next_shift) + 0.5,
                xy = pack_coordinates(math_floor(source_chunk.x / next_shift), math_floor(source_chunk.y / next_shift)),
                meta = new_template(Quad_Meta_Data, tick),
            }, tick)

            if (not chunk_map[source_chunk.xy] or chunk_map[source_chunk.xy] ~= source_chunk) then
                parent_node[direction].chunk = new_Leaf_Data(Leaf_Data, source_chunk, tick)
                chunk_map[source_chunk.xy] = parent_node[direction].chunk
            end
            source_chunk = chunk_map[source_chunk.xy]

            quadtree.base.count = (quadtree.base.count or 0) + 1
            parent_node.count = (parent_node.count or 0) + 1
            parent_node.chunk = nil

            quadtree_service.apply_metrics(source_chunk, nil, tick)
            -- merge_data(parent_node[direction], source_chunk.meta, nil, tick)

            source_chunk.parent_node = parent_node[direction]
            parent_node[direction].chunk = source_chunk

            -- return parent_node[direction], parent_node[direction].chunk
            return parent_node[direction], source_chunk
        end
        log("hwat?!")
    end
end

local function is_empty_node(node)
    return  not node
        or  not node.chunk
        and not (
                node.nw
            or  node.ne
            or  node.sw
            or  node.se
        )
end

local function get_quadrant_search_weight(node, evolution_factor, rand, tick)
    local ret_val = 0
    if (not node) then return ret_val end

    evolution_factor = evolution_factor or 0
    tick = tick or (game or set_game()).tick
    local meta = node.meta or new_template(Quad_Meta_Data, tick)

    local industry = (meta.pollution or 0) + (meta.entity_count or 0) * (meta.vision_factor or 0)
    local nest_density = (meta.spawner_count or 0) * 2

    rand = rand or math_random()
    if (((evolution_factor + rand) / 2) < 0.42) then
        ret_val = 1000 - industry - nest_density
    else
        ret_val = industry * 2 + nest_density
    end
    return ret_val
end

function quadtree_service.find_closest_iteratively(params)
    if (not params) then return end
    if (not params.surface_name) then return end
    if (not params.source_chunk) then return end
    local surface_name = params.surface_name

    local checkpoint = params.checkpoint
    if (not checkpoint) then return end

    quadtrees = quadtrees or set_game() and quadtrees
    quadtrees[surface_name] = quadtrees[surface_name] or new_Quadtree(Quadtree, { surface_name = surface_name, })
    local quadtree = quadtrees[surface_name]

    -- Parameters
    local iterations = checkpoint.iterations or 0
    checkpoint.iterations = iterations + 1

    checkpoint.best_frontier_score = checkpoint.best_frontier_score or 0
    checkpoint.best_frontier_node = checkpoint.best_frontier_node or nil

    checkpoint.best_expansion_score = checkpoint.best_expansion_score or EIGHTH_PI
    checkpoint.best_expansion_node = checkpoint.best_expansion_node or nil

    checkpoint.rand = checkpoint.rand or math_random()

    local source_chunk = params.source_chunk
    local tick = params.tick or 0

    source_chunk.meta = source_chunk.meta or new_template(Quad_Meta_Data, tick)
    local meta = source_chunk.meta

    -- Optional parameters
    local max_distance = params.max_distance
    local min_distance = params.min_distance or 0
    local greedy = params.greedy
    local strictness = params.strictness

    -- Composite system load factor
    local blended_x = checkpoint.blended_x or 0.0

    local delta_t = tick - (checkpoint.updated or 0)

    if (delta_t > (150 + 750 * (checkpoint.curr_instant_load or 0.25))) then checkpoint.reevluate = 1 end

    if (not checkpoint.node_stack or checkpoint.reevluate) then
        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups.count = unit_groups.count or 0

        system_stats = system_stats or set_game() and system_stats
        system_stats[surface_name] = system_stats[surface_name] or {}

        unit_groups.surface_count = unit_groups.surface_count or {}
        unit_groups.surface_count[surface_name] = unit_groups.surface_count[surface_name] or 0
        stats_data.surface_group_stress[surface_name] = (unit_groups.surface_count[surface_name] + 0) / (max_unit_groups + 1)
        stats_data.current.group_stress = (unit_groups.count + 0) / (num_planets * max_unit_groups + 1)

        local curr_stress = math_max(0.0, stats_data.surface_group_stress[surface_name], (stats_data.current.group_stress or 0.5))
        local curr_activity = stats_data.current.total or 1
        local activity_stress = math_min(curr_activity / 512, 1.0)

        local hist_a = stats_data.activity_history
        local hist_s = stats_data.stress_history

        local trend_modifier = 0

        if (hist_s.acceleration > 0) then
            trend_modifier = trend_modifier + (hist_s.acceleration * 0.6)
        end
        if (hist_a.acceleration > 0) then
            trend_modifier = trend_modifier + math_min(hist_a.acceleration / 50, 0.3)
        end

        if (hist_s.v_1s > 0) then trend_modifier = trend_modifier + hist_s.v_1s * 0.2 end
        if (hist_s.v_2s > 0) then trend_modifier = trend_modifier + hist_s.v_2s * 0.1 end
        if (hist_s.v_4s > 0) then trend_modifier = trend_modifier + hist_s.v_4s * 0.05 end
        if (hist_s.v_8s > 0) then trend_modifier = trend_modifier + hist_s.v_8s * 0.02 end

        stats_data = stats_data or set_game() and stats_data
        local stats_meta = stats_data.meta
        local wv = stats_data.welford_variance

        local engine_volatility = (wv and wv.sd) or 0
        local volatility_penalty = math_min(engine_volatility / 50, 0.25)

        local base_load = (curr_stress * 0.7) + (activity_stress * 0.3)

        local curr_instant_load = math_min(base_load + trend_modifier + volatility_penalty, 1.0)
        checkpoint.last_load = curr_instant_load

        surfaces = surfaces or set_game() and surfaces
        surfaces[surface_name] = surfaces[surface_name] or {}
        surfaces[surface_name].meta = surfaces[surface_name].meta or {}
        local surface_meta = surfaces[surface_name].meta

        local last_local_load, last_surface_load, last_global_load = meta.last_load or 0, surface_meta.last_load or 0, stats_meta.last_load or 0

        meta.last_load, surface_meta.last_load, stats_meta.last_load = curr_instant_load, curr_instant_load, curr_instant_load
        system_stats[surface_name].last_load, system_stats.last_load = curr_instant_load, curr_instant_load

        blended_x = math_max(curr_instant_load, last_global_load, last_surface_load, last_local_load)
        checkpoint.blended_x = blended_x

        strictness = math_min(1.0 - blended_x, 0.97)

        if (strictness < 1 and blended_x >= strictness) then
            local greed_threshold =
                    (0.25 * blended_x) -- Linear
                +   (0.5 * (blended_x * blended_x * blended_x)) -- Polynomial
                +   (0.25 * ((2 ^ blended_x) / (1.01 - blended_x))) -- Exponential

            if (greed_threshold > 1) then
                greed_threshold = 1
            elseif (greed_threshold < 0) then
                greed_threshold = 0
            end

            greedy = math_random() < greed_threshold
        else
            greedy = false
        end

        checkpoint.greedy = greedy
        checkpoint.blended_x = blended_x

        checkpoint.iterations = 1
        iterations = 0
    end

    if (meta.last_radius) then
        max_distance = meta.last_radius
    elseif (meta.expanded_radius) then
        max_distance = meta.expanded_radius
    else
        max_distance = math_min(
            TWO_CHUNKS + (iterations * (1 + HALF_CHUNK) * (1.0 - blended_x)),
            BASE_SEARCH_RADIUS * (1.0 - (0.96875 * blended_x))
        )
    end

    meta.last_radius = max_distance

    checkpoint.best_distance = checkpoint.best_distance or UINT64
    checkpoint.updated = tick
    checkpoint.actionable_targets_found = checkpoint.actionable_targets_found or 0

    force_funcs = force_funcs or set_game() and force_funcs
    checkpoint.evolution_factor = checkpoint.evolution_factor or force_funcs[checkpoint.force_name].get_evolution_factor(surface_name) or 0
    local evolution_factor = checkpoint.evolution_factor

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])
    local selected_difficulty = difficulties[surface_name]

    selected_difficulty.inverse_value = selected_difficulty.inverse_value or (1 / selected_difficulty.value)
    selected_difficulty.sqrt_value = selected_difficulty.sqrt_value or math_sqrt(selected_difficulty.value)

    checkpoint.fork_base = checkpoint.fork_base or selected_difficulty.value
    checkpoint.fork_flat_bonus = checkpoint.fork_flat_bonus or selected_difficulty.sqrt_value

    local search_iteration_limit = math_max(24 + selected_difficulty.value, math_floor(selected_difficulty.sqrt_value + (128 * (1 - blended_x))))

    if (not checkpoint.node_stack) then
        checkpoint.node_stack = { checkpoint.search_type == TOP_DOWN and quadtree.base or source_chunk, }
        checkpoint.stack_pointer = 1
    end

    local processing_steps_allowed = math_max(3, math_floor(1 + selected_difficulty.sqrt_value + (2 * selected_difficulty.sqrt_value) * (1 - blended_x)))
    local steps_executed = 0

    local node_stack = checkpoint.node_stack
    local ptr = checkpoint.stack_pointer

    local math_max = math_max
    local math_sqrt = math_sqrt
    local CHUNK_LEVELS = CHUNK_LEVELS
    local is_empty_node = is_empty_node
    local get_quadrant_search_weight = get_quadrant_search_weight

    while (ptr > 0) and (steps_executed < processing_steps_allowed) do
        steps_executed = steps_executed + 1

        local current_node = node_stack[ptr]
        local is_spine
        if (current_node and checkpoint.spine_nodes) then
            is_spine = checkpoint.spine_nodes[current_node]
            checkpoint.spine_nodes[current_node] = nil
        end
        node_stack[ptr] = nil
        ptr = ptr - 1

        if (not is_empty_node(current_node) and current_node.node_level and current_node.node_level >= 0 and current_node.node_level <= 35) then
            local shift = SHIFT_LOOKUP[current_node.node_level or 0]

            local min_x, min_y = current_node.x - shift, current_node.y - shift
            local max_x, max_y = current_node.x + shift, current_node.y + shift

            local dx, dy = math_max(min_x - source_chunk.x, 0, source_chunk.x - max_x), math_max(min_y - source_chunk.y, 0, source_chunk.y - max_y)
            -- local delta_min = math_sqrt(dx * dx + dy * dy)

            local source_tile_x, source_tile_y = (source_chunk.x * CHUNK_SIZE) + 16, (source_chunk.y * CHUNK_SIZE) + 16
            -- local delta_min_tiles = delta_min * CHUNK_SIZE
            local delta_min_sq = dx * dx + dy * dy
            local delta_min_tiles_sq = delta_min_sq * CHUNK_SQUARED

            local chunk = current_node.chunk
            -- if (chunk and delta_min_tiles > 0 and delta_min_tiles < checkpoint.best_distance and delta_min_tiles < CHUNK_CUBED) then
            if (chunk and delta_min_tiles_sq > 0 and delta_min_tiles_sq < (checkpoint.best_distance * checkpoint.best_distance) and delta_min_tiles_sq < CHUNK_CUBED_SQ) then
                local delta_min_tiles = math_sqrt(delta_min_sq) * CHUNK_SIZE

                local chunk_meta = chunk and chunk.meta or EMPTY_TEMPLATE

                local action_history = chunk_meta.last_action_tick
                local action_counts = chunk_meta.action_counts

                local delta_since_last_action = tick - (action_history.total or 0)
                local fatigue_multiplier = math_max(0.2, 1.0 - ((action_counts.total or 0) * 0.05))

                local recency_multiplier = 1.0
                if (delta_since_last_action < BASE_DELAY) then recency_multiplier = 0.1 + 0.9 * (delta_since_last_action / BASE_DELAY) end

                local memory_dampener = math_min(1.0, recency_multiplier * fatigue_multiplier)

                local node_meta = current_node.meta or EMPTY_TEMPLATE
                local parent_meta = current_node.parent_node and current_node.parent_node.meta or EMPTY_TEMPLATE

                local chunk_witnessed = chunk_meta and chunk_meta.witnessed and chunk_meta.witnessed_tick or 0
                local sector_witnessed = parent_meta and parent_meta.witnessed and parent_meta.witnessed_tick or 0

                local parent_node = current_node.parent_node
                local is_hidden = ((chunk.entity_count or 0) > 0) and not chunk_meta.witnessed
                local is_frontier_edge = chunk_witnessed and (not current_node.nw or not current_node.ne or not current_node.sw or not current_node.se)
                                    or   sector_witnessed and (not parent_node.nw or not parent_node.ne or not parent_node.sw or not parent_node.se)
                local delta_t = tick - math_max(chunk_witnessed, sector_witnessed)

                local stagnation_factor = 0.09 + math_max(0.0, 0.9 - (delta_t / BASE_DELAY))

                local dt = math_max(1, tick - (chunk_meta.prev_death_tick or tick))
                local dw = (chunk_meta.death_weight or 0) - (chunk_meta.prev_death_weight or 0)
                local velocity = dw / dt
                local acceleration = (velocity - (chunk_meta.last_velocity or 0)) / dt

                if (chunk_meta.created) then
                    chunk_meta.prev_death_weight = chunk_meta.death_weight or 0
                    chunk_meta.last_velocity = velocity
                end

                local imperialism = 0.1 + 0.9 * (evolution_factor ^ selected_difficulty.inverse_value)

                local priority_val = chunk_meta.max_priority
                local priority_sq = priority_val * priority_val

                local spawner_density = 0

                local raw_spawner_count = (chunk_meta.spawner_count or 0)
                local spawner_count = raw_spawner_count
                local raw_entity_count = (chunk_meta.entity_count or 0)
                local entity_count = raw_entity_count
                local blended_vision = (chunk_meta.spawner_count or 0) > 0 and 1 or chunk_meta.witnessed and chunk_meta.vision_factor or 0
                local aggregate_pollution = 0 + (node_meta.pollution or 0)

                local raw_witnessed_count = (chunk_meta.witnessed_entity_count or 0)
                local witnessed_count = raw_witnessed_count
                if (chunk_witnessed or sector_witnessed) then
                    if (parent_node and parent_meta) then
                        local q0, qN, n = parent_node, parent_node.parent_node, (CHUNK_LEVELS - (parent_node.node_level or 0))
                        local q0_meta, qN_meta = q0 and q0.meta or nil, qN and qN.meta or nil
                        local pollution_limit = 1 + (1 + selected_difficulty.sqrt_value) * (evolution_factor)
                        local fov_limit = 2 + math_floor(selected_difficulty.sqrt_value * (0.01 + evolution_factor))
                        local density_limit = 0.5 + selected_difficulty.sqrt_value * evolution_factor
                        local limit = math_max(1, pollution_limit, fov_limit, density_limit)
                        local quarter_raised_n = 1

                        while q0 and qN and q0_meta and qN_meta and n < CHUNK_LEVELS and n <= limit do
                            if ((qN_meta.spawner_count or 0) > 0) then
                                blended_vision = (blended_vision + (q0_meta.spawner_count or 0) / qN_meta.spawner_count) / 2
                            else
                                blended_vision = (blended_vision + (q0_meta.witnessed and q0_meta.vision_factor or 0)) / 2
                            end

                            -- local quarter_raised_n = (0.25 ^ n)
                            quarter_raised_n = quarter_raised_n * 0.25

                            aggregate_pollution = aggregate_pollution + (qN_meta.pollution or 0) * quarter_raised_n
                            entity_count = entity_count + (qN_meta.entity_count or 0) * quarter_raised_n
                            spawner_count = spawner_count + (qN_meta.spawner_count or 0) * quarter_raised_n
                            entity_count = entity_count + (qN_meta.entity_count or 0) * quarter_raised_n
                            witnessed_count = witnessed_count + (qN_meta.witnessed_entity_count or 0) * quarter_raised_n
                            raw_spawner_count = (qN_meta.spawner_count or 0)
                            raw_entity_count = (qN_meta.entity_count or 0)
                            raw_witnessed_count = (qN_meta.witnessed_entity_count or 0)
                            n = n + 1
                            q0 = qN
                            qN = qN.parent_node
                            q0_meta = q0 and q0.meta or nil
                            qN_meta = qN and qN.meta or nil
                        end
                    end
                end

                if ((chunk_witnessed or sector_witnessed) and chunk_meta.entity_count > 0) then

                    local entity_density = 0

                    entity_density = entity_count / raw_entity_count
                    spawner_density = spawner_count / raw_spawner_count

                    local pollution_pull_limit = (selected_difficulty.sqrt_value + evolution_factor + imperialism) * (evolution_factor)
                    local pollution_pull = math_min(CHUNK_SIZE * pollution_pull_limit, aggregate_pollution * (0.15 + 0.85 * evolution_factor))

                    local return_on_investment = (parent_meta.death_weight or 0) / ((parent_meta.enemy_deaths or 0) + 1)
                    local meta_grinder_ratio = (chunk_meta.enemy_deaths or 0) / ((chunk_meta.death_weight or 0) + 1)
                    local chunk_score = (
                          return_on_investment * ((blended_vision + stagnation_factor + imperialism) / 3)
                        + (pollution_pull) * math_sqrt(0.2 + 0.8 * entity_density)
                        + (spawner_density)
                        + (chunk_meta.entity_count or 0)
                        - (meta_grinder_ratio * 15)
                        + priority_sq
                    )   * (chunk_meta.witnessed and chunk_meta.vision_factor or 0.42)

                    local node_level_ratio = math_max(0, (1 - ((current_node.node_level or 0) / CHUNK_LEVELS)))
                    node_level_ratio = (1 + node_level_ratio) / 2
                    local total_score = math_sqrt(
                        math_max(
                            0,
                               chunk_score
                            +  priority_sq
                        )
                    )   * stagnation_factor
                        * memory_dampener

                    if (node_meta.created and (total_score >= PI) and (total_score > checkpoint.best_score) and (chunk or current_node and (current_node.chunk or current_node.node_level >= 35))) then
                        node_meta.last_action_tick = node_meta.last_action_tick or { total = 0, [ATTACK] = 0, }
                        local last_action_tick = node_meta.last_action_tick

                        local action_delta = math_min(1, (tick - (last_action_tick.total or 0)) / BASE_DELAY)
                        local action_specific_delta = math_min(1, (tick - (last_action_tick[ATTACK] or 0)) / BASE_DELAY)
                        local blended_action_delta = math_sqrt(action_delta * action_specific_delta)

                        local target_tile_x, target_tile_y = (current_node.x * CHUNK_SIZE) + 16, (current_node.y * CHUNK_SIZE) + 16
                        local distance = math_sqrt((target_tile_x - source_tile_x)^2 + (target_tile_y - source_tile_y)^2)

                        if (distance < checkpoint.best_distance and distance >= (1 + (blended_action_delta * min_distance))) then
                            node_meta.action_counts.total = (node_meta.action_counts.total or 0) + 1
                            node_meta.action_counts[ATTACK] = (node_meta.action_counts[ATTACK] or 0) + 1
                            node_meta.last_action_tick.total = tick
                            node_meta.last_action_tick[ATTACK] = tick

                            checkpoint.best_target = chunk or current_node.chunk or current_node
                            checkpoint.best_score = total_score
                            checkpoint.best_distance = distance
                            checkpoint.best_found_tick = tick

                            quadtree_service.register_highest_chunk(checkpoint.best_target, surface_name, total_score, tick)

                            checkpoint.actionable_targets_found = checkpoint.actionable_targets_found + 1

                            if (checkpoint.greedy) then
                                ptr = 0
                                break
                            end
                        end
                    end
                end

                local frontier_stagnation = is_hidden and 0.05 or stagnation_factor
                if (chunk_witnessed or sector_witnessed or is_hidden or is_frontier_edge) then
                    local min_distance_threshold = delta_min_tiles / (delta_min_tiles ^ (1/3))
                    local max_distance_threshold = CHUNK_SQUARED - min_distance_threshold

                    local imminent_domain = imperialism + imperialism * math_max(0, velocity * 10) + imperialism * math_max(0, acceleration * 100)
                    local get_off_my_lawn = (((0.1 + 0.9 * blended_vision) + (0.1 + 0.9 * evolution_factor)) / 2) * (entity_count)
                    local personal_space = math_max(1, 64 * (1.0 - (0.1 + 0.9 * evolution_factor)))
                    checkpoint.personal_space = personal_space
                    local vacuum_abhorrence = math_max(0, CHUNK_SQUARED - (chunk_meta.entity_count or 0) * personal_space - (chunk_meta.spawner_count or 0) * 10)

                    local pollution_pull_limit = (selected_difficulty.sqrt_value + evolution_factor + imperialism) * (evolution_factor)
                    local pollution_pull = math_min(CHUNK_SIZE * pollution_pull_limit, aggregate_pollution * (0.15 + 0.85 * evolution_factor))

                    local frontier_score = (
                          pollution_pull
                        + get_off_my_lawn * (0.1 + 0.9 * frontier_stagnation)
                        - (
                              (delta_min_tiles * 0.35)
                            * (0.1 + 0.9 * frontier_stagnation)
                            * (1.0 - (0.1 + 0.9 * blended_vision))
                        )
                        - spawner_count
                        + (max_distance_threshold / CHUNK_SIZE^2)
                        + priority_sq
                        + (imperialism)
                    )
                        * memory_dampener
                        + priority_sq

                    if (node_meta.created and (frontier_score > checkpoint.best_frontier_score) and (chunk or current_node and (current_node.chunk or current_node.node_level >= 35))) then

                        checkpoint.best_expansion_distance = checkpoint.best_expansion_distance or UINT64

                        local target_tile_x, target_tile_y = (current_node.x * CHUNK_SIZE) + 16, (current_node.y * CHUNK_SIZE) + 16

                        local dx, dy = target_tile_x - source_tile_x, target_tile_y - source_tile_y
                        -- local distance = math_sqrt(dx * dx + dy * dy)
                        local distance_sq = dx * dx + dy * dy

                        node_meta.last_action_tick = node_meta.last_action_tick or { total = 0, [SCOUT] = 0, }
                        local last_action_tick = node_meta.last_action_tick

                        local action_delta = math_min(1, (tick - (last_action_tick.total or 0)) / BASE_DELAY)
                        local action_specific_delta = math_min(1, (tick - (last_action_tick[SCOUT] or 0)) / BASE_DELAY)
                        local blended_action_delta = math_sqrt(action_delta * action_specific_delta)

                        local base_horizon = 8 + 6 * CHUNK_SIZE * ((evolution_factor + (imminent_domain + imperialism) / 2) / 2)

                        local bubble_variance = (max_distance * 0.25) * (1 - blended_vision)

                        local max_frontier_distance = (base_horizon + pollution_pull + bubble_variance) * blended_action_delta

                        -- if (distance > 8 and distance < max_frontier_distance) then
                        if (distance_sq > TWO_CHUNKS and distance_sq < (max_frontier_distance * max_frontier_distance)) then
                            node_meta.action_counts.total = (node_meta.action_counts.total or 0) + 1
                            node_meta.action_counts[SCOUT] = (node_meta.action_counts[SCOUT] or 0) + 1
                            node_meta.last_action_tick.total = tick
                            node_meta.last_action_tick[SCOUT] = tick

                            checkpoint.best_frontier_distance = math_sqrt(distance_sq)
                            checkpoint.best_frontier_score = frontier_score
                            checkpoint.best_frontier_node = chunk or current_node.chunk or current_node

                            checkpoint.best_frontier_tick = tick

                            checkpoint.actionable_targets_found = checkpoint.actionable_targets_found + 1

                            if (checkpoint.greedy) then
                                ptr = 0
                                break
                            end
                        end
                    end

                    local expansion_score = (
                          math_sqrt((1 + vacuum_abhorrence * imperialism))
                        + (imminent_domain)
                        + (get_off_my_lawn)
                        - (0.35 * min_distance_threshold)
                        +  priority_sq
                    )   * frontier_stagnation
                        * memory_dampener
                        * (0.1 + 0.9 * blended_vision)
                        +  priority_sq

                    selected_difficulty.expansion_threshold = selected_difficulty.expansion_threshold or math_sqrt(selected_difficulty.inverse_value)
                    expansion_score = expansion_score * math_sqrt(0.25 + 0.75 * blended_vision) + 0.1

                    if (node_meta.created and (expansion_score > 0 and expansion_score > checkpoint.best_expansion_score) and (chunk or (current_node and (current_node.chunk or current_node.node_level >= 35)))) then
                        checkpoint.best_expansion_distance = checkpoint.best_expansion_distance or UINT64

                        local target_tile_x, target_tile_y = (current_node.x * CHUNK_SIZE) + 16, (current_node.y * CHUNK_SIZE) + 16
                        -- local distance = math_sqrt((target_tile_x - source_tile_x)^2 + (target_tile_y - source_tile_y)^2)
                        local dx, dy = target_tile_x - source_tile_x, target_tile_y - source_tile_y
                        -- local distance = math_sqrt(dx * dx + dy * dy)
                        local distance_sq = dx * dx + dy * dy

                        node_meta.last_action_tick = node_meta.last_action_tick or { total = 0, [EXPANSION] = 0, }
                        local last_action_tick = node_meta.last_action_tick

                        local action_delta = math_min(1, (tick - (last_action_tick.total or 0)) / BASE_DELAY)
                        local action_specific_delta = math_min(1, (tick - (last_action_tick[EXPANSION] or 0)) / BASE_DELAY)
                        local blended_action_delta = math_sqrt(action_delta * action_specific_delta)

                        -- if ((distance < checkpoint.best_expansion_distance)) then
                        if ((distance_sq < (checkpoint.best_expansion_distance * checkpoint.best_expansion_distance))) then
                            -- if (distance >= 8 and (distance < ((TWO_CHUNKS * blended_action_delta) + HALF_CHUNK + (2 * max_distance_threshold) + (4 * (min_distance_threshold))))) then
                            local distance_threshold = ((TWO_CHUNKS * blended_action_delta) + HALF_CHUNK + (2 * max_distance_threshold) + (4 * (min_distance_threshold)))
                            if (distance_sq >= TWO_CHUNKS and (distance_sq < (distance_threshold * distance_threshold))) then
                                node_meta.action_counts.total = (node_meta.action_counts.total or 0) + 1
                                node_meta.last_action_tick.total = tick
                                node_meta.action_counts[EXPANSION] = (node_meta.action_counts[EXPANSION] or 0) + 1
                                node_meta.last_action_tick[EXPANSION] = tick

                                checkpoint.best_expansion_score = expansion_score
                                checkpoint.best_expansion_node = chunk or current_node.chunk or current_node

                                checkpoint.best_expansion_distance = math_sqrt(distance_sq)
                                checkpoint.best_expansion_tick = tick

                                checkpoint.actionable_targets_found = checkpoint.actionable_targets_found + 1

                                if (checkpoint.greedy) then
                                    ptr = 0
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if (    checkpoint.search_type == TOP_DOWN
                or
                    checkpoint.search_type == BOTTOM_UP
                and not is_spine
                and checkpoint.climb_count
            ) then
                local north = (source_chunk.y + 0.5) < (current_node.y * shift)
                local west  = (source_chunk.x + 0.5) < (current_node.x * shift)

                local q1, q2, q3, q4 = nil, nil, nil, nil
                if (north) then
                    if (west) then
                        q1, q2, q3, q4 = current_node.se, current_node.sw, current_node.ne, current_node.nw
                    else
                        q1, q2, q3, q4 = current_node.sw, current_node.se, current_node.nw, current_node.ne
                    end
                else
                    if (west) then
                        q1, q2, q3, q4 = current_node.ne, current_node.nw, current_node.se, current_node.sw
                    else
                        q1, q2, q3, q4 = current_node.nw, current_node.ne, current_node.sw, current_node.se
                    end
                end

                local w1 = q1 and get_quadrant_search_weight(q1, evolution_factor, checkpoint.rand, tick) or -1
                local w2 = q2 and get_quadrant_search_weight(q2, evolution_factor, checkpoint.rand, tick) or -1
                local w3 = q3 and get_quadrant_search_weight(q3, evolution_factor, checkpoint.rand, tick) or -1
                local w4 = q4 and get_quadrant_search_weight(q4, evolution_factor, checkpoint.rand, tick) or -1

                local temp_q, temp_w = nil, nil
                if (w2 > w1) then
                    temp_q, temp_w = q2, w2
                    q2, w2 = q1, w1
                    q1, w1 = temp_q, temp_w
                end
                if (w3 > w2) then
                    temp_q, temp_w = q3, w3
                    q3, w3 = q2, w2
                    q2, w2 = temp_q, temp_w
                    if (w2 > w1) then
                        temp_q, temp_w = q2, w2
                        q2, w2 = q1, w1
                        q1, w1 = temp_q, temp_w
                    end
                end
                if (w4 > w3) then
                    temp_q, temp_w = q4, w4
                    q4, w4 = q3, w3
                    q3, w3 = temp_q, temp_w
                    if (w3 > w2) then
                        temp_q, temp_w = q3, w3
                        q3, w3 = q2, w2
                        q2, w2 = temp_q, temp_w
                        if (w2 > w1) then
                            temp_q, temp_w = q2, w2
                            q2, w2 = q1, w1
                            q1, w1 = temp_q, temp_w
                        end
                    end
                end

                if (q4 and w4 >= 0) then ptr = ptr + 1; node_stack[ptr] = q4 end
                if (q3 and w3 >= 0) then ptr = ptr + 1; node_stack[ptr] = q3 end
                if (q2 and w2 >= 0) then ptr = ptr + 1; node_stack[ptr] = q2 end
                if (q1 and w1 >= 0) then ptr = ptr + 1; node_stack[ptr] = q1 end
            else
                checkpoint.climb_limit = checkpoint.climb_limit or (1 + (math_floor(selected_difficulty.sqrt_value + evolution_factor) * (0.01 + evolution_factor)))

                if (current_node.chunk and not checkpoint.climb_count) then
                    checkpoint.climb_count = 0
                    checkpoint.last_spine_node = current_node
                    local initial_parent = current_node.parent_node

                    if (initial_parent) then
                        ptr = ptr + 1
                        checkpoint.spine_nodes = checkpoint.spine_nodes or {}
                        checkpoint.spine_nodes[initial_parent] = 1
                        node_stack[ptr] = initial_parent
                    end
                elseif (not current_node.chunk) then
                    checkpoint.climb_count = (checkpoint.climb_count or 0) + 1

                    if (current_node.parent_node and checkpoint.climb_count <= checkpoint.climb_limit) then

                        local q1, q2, q3, q4 = current_node.nw, current_node.ne, current_node.sw, current_node.se

                        local last_spine = checkpoint.last_spine_node

                        local n1 = (q1 and q1 ~= last_spine) and q1 or nil
                        local n2 = (q2 and q2 ~= last_spine) and q2 or nil
                        local n3 = (q3 and q3 ~= last_spine) and q3 or nil
                        local n4 = (q4 and q4 ~= last_spine) and q4 or nil

                        local w1 = n1 and get_quadrant_search_weight(q1, evolution_factor, checkpoint.rand, tick) or -1
                        local w2 = n2 and get_quadrant_search_weight(q2, evolution_factor, checkpoint.rand, tick) or -1
                        local w3 = n3 and get_quadrant_search_weight(q3, evolution_factor, checkpoint.rand, tick) or -1
                        local w4 = n4 and get_quadrant_search_weight(q4, evolution_factor, checkpoint.rand, tick) or -1

                        local temp_n, temp_w = nil, nil
                        if (w2 > w1) then
                            temp_n, temp_w = n2, w2
                            n2, w2 = n1, w1
                            n1, w1 = temp_n, temp_w
                        end
                        if (w3 > w2) then
                            temp_n, temp_w = n3, w3
                            n3, w3 = n2, w2
                            n2, w2 = temp_n, temp_w
                            if (w2 > w1) then
                                temp_n, temp_w = n2, w2
                                n2, w2 = n1, w1
                                n1, w1 = temp_n, temp_w
                            end
                        end
                        if (w4 > w3) then
                            temp_n, temp_w = n4, w4
                            n4, w4 = n3, w3
                            n3, w3 = temp_n, temp_w
                            if (w3 > w2) then
                                temp_n, temp_w = n3, w3
                                n3, w3 = n2, w2
                                n2, w2 = temp_n, temp_w
                                if (w2 > w1) then
                                    temp_n, temp_w = n2, w2
                                    n2, w2 = n1, w1
                                    n1, w1 = temp_n, temp_w
                                end
                            end
                        end

                        checkpoint.last_spine_node = current_node

                        if (current_node.parent_node) then
                            ptr = ptr + 1
                            node_stack[ptr] = current_node.parent_node
                            checkpoint.spine_nodes[current_node.parent_node] = 1
                        end

                        if (n4 and w4 >= 0) then ptr = ptr + 1; node_stack[ptr] = n4 end
                        if (n3 and w3 >= 0) then ptr = ptr + 1; node_stack[ptr] = n3 end
                        if (n2 and w2 >= 0) then ptr = ptr + 1; node_stack[ptr] = n2 end
                        if (n1 and w1 >= 0) then ptr = ptr + 1; node_stack[ptr] = n1 end
                    else
                        break
                    end
                end
            end
        end
    end

    if (    ptr <= 0
        or  checkpoint.actionable_targets_found >= 3
        or  checkpoint.iterations >= search_iteration_limit
        or (    checkpoint.actionable_targets_found > 0
            and checkpoint.iterations >= (0.5 * search_iteration_limit)
        )
    ) then
        -- log("Exhausted search")
        game_print("Exhausted search")
        local rand = math_random(100)
        if (selected_style == RANDOM) then
            local targets = nil
            local types = nil
            if (checkpoint.best_target) then
                targets = targets or {}; targets[#targets+1] = checkpoint.best_target
                types = types or {}; types[#types+1] = ATTACK
            end
            if (checkpoint.best_expansion_node) then
                targets = targets or {}; targets[#targets+1] = checkpoint.best_expansion_node
                types = types or {}; types[#types+1] = EXPANSION
            end
            if (checkpoint.best_frontier_node) then
                targets = targets or {}; targets[#targets+1] = checkpoint.best_frontier_node
                types = types or {}; types[#types+1] = SCOUT
            end

            if (targets and #targets > 0 and types and #types > 0) then
                checkpoint.scalar = 1 + rand
                rand = (rand % 3) + 1
                checkpoint.final_target = targets[rand]
                checkpoint.action_type = types[rand]
            end
        elseif (checkpoint.best_target and rand < 48) then
            checkpoint.final_target = checkpoint.best_target
            checkpoint.action_type = ATTACK
            checkpoint.scalar = 2.25
        elseif (checkpoint.best_expansion_node and rand < 8 and (rand >= 48 or not checkpoint.best_target)) then
            checkpoint.action_type = EXPANSION
            checkpoint.scalar = 1.5
            checkpoint.final_target = checkpoint.best_expansion_node
        elseif (checkpoint.best_frontier_node) then
            checkpoint.action_type = SCOUT
            checkpoint.scalar = 1
            checkpoint.final_target = checkpoint.best_frontier_node
        else
            checkpoint.final_target = nil
        end
        -- log(checkpoint.action_type)
        game_print(checkpoint.search_type .. "." .. checkpoint.search_type)

        if (checkpoint.final_target) then
            -- log("Found target: " .. checkpoint.action_type)
            game_print("Found target: " .. checkpoint.action_type)
            --[[ Progress to the next state]]
            checkpoint.state = STATE_REQUESTING_PATH
            checkpoint.final_target.xy = pack_coordinates(checkpoint.final_target.x, checkpoint.final_target.y)

            local c_meta = checkpoint.final_target.meta
            c_meta.action_counts.total = (c_meta.action_counts.total or 0) + 1
            c_meta.action_counts[checkpoint.action_type] = (c_meta.action_counts[checkpoint.action_type] or 0) + 1
            c_meta.last_action_tick.total = tick
            c_meta.last_action_tick[checkpoint.action_type] = tick

        else
            --[[ Reset the state to recovery ]]
            checkpoint.state = STATE_RECOVERY
        end

        checkpoint.node_stack = nil
        checkpoint.stack_pointer = nil
        checkpoint.best_distance = nil
        checkpoint.best_target = nil
        checkpoint.best_frontier_node = nil
        checkpoint.best_frontier_score = nil
        checkpoint.best_expansion_node = nil
        checkpoint.best_expansion_score = nil
    end

    checkpoint.stack_pointer = ptr
end

function quadtree_service.find_closest_spawner(params)
    if (not params) then return end
    if (not params.surface_name) then return end
    if (not params.target_chunk) then return end
    local surface_name = params.surface_name

    quadtrees = quadtrees or set_game() and quadtrees
    quadtrees[surface_name] = quadtrees[surface_name] or new_Quadtree(Quadtree, { surface_name = surface_name, })
    local quadtree = quadtrees[surface_name]

    -- Parameters
    local target_chunk = params.target_chunk

    target_chunk.meta = target_chunk.meta or new_template(Quad_Meta_Data, params.tick)
    local meta = target_chunk.meta

    -- Optional parameters
    local limit = params.limit or nil
    local spawner_pool = params.spawner_pool or nil
    local spawner_distance_map = nil

    local max_distance = params.max_distance
    local greedy = params.greedy
    local strictness = params.strictness

    -- Composite system load factor
    local blended_x = 0.0

    if (greedy == nil) then
        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups.count = unit_groups.count or 0

        local curr_stress = (unit_groups.count + 1) / (max_unit_groups + 1)
        local curr_activity = stats_data.current.total or 1
        local activity_stress = math_min(curr_activity / 500, 1.0)

        local hist_a = stats_data.activity_history
        local hist_s = stats_data.stress_history

        local trend_modifier = 0

        if (hist_s.acceleration > 0) then
            trend_modifier = trend_modifier + (hist_s.acceleration * 0.6)
        end
        if (hist_a.acceleration > 0) then
            trend_modifier = trend_modifier + math_min(hist_a.acceleration / 50, 0.3)
        end

        if (hist_s.v_1s > 0) then trend_modifier = trend_modifier + hist_s.v_1s * 0.2 end
        if (hist_s.v_2s > 0) then trend_modifier = trend_modifier + hist_s.v_2s * 0.1 end
        if (hist_s.v_4s > 0) then trend_modifier = trend_modifier + hist_s.v_4s * 0.05 end
        if (hist_s.v_8s > 0) then trend_modifier = trend_modifier + hist_s.v_8s * 0.02 end

        stats_data = stats_data or set_game() and stats_data
        local stats_meta = stats_data.meta
        local wv = stats_data.welford_variance

        local engine_volatility = (wv and wv.sd) or 0
        local volatility_penalty = math_min(engine_volatility / 50, 0.25)

        local base_load = (curr_stress * 0.7) + (activity_stress * 0.3)

        local curr_instant_load = math_min(base_load + trend_modifier + volatility_penalty, 1.0)

        surfaces = surfaces or set_game() and surfaces
        surfaces[surface_name] = surfaces[surface_name] or {}
        surfaces[surface_name].meta = surfaces[surface_name].meta or {}
        local surface_meta = surfaces[surface_name].meta

        local last_local_load, last_surface_load, last_global_load = meta.last_load or 0, surface_meta.last_load or 0, stats_meta.last_load or 0

        blended_x = math_max(curr_instant_load, last_global_load, last_surface_load, last_local_load)
        meta.last_load, surface_meta.last_load, stats_meta.last_load = curr_instant_load, curr_instant_load, curr_instant_load

        strictness = math_min(1.0 - blended_x, 0.97)

        if (strictness < 1 and blended_x >= strictness) then
            local greed_threshold =
                    (0.25 * blended_x) -- Linear
                +   (0.5 * (blended_x * blended_x * blended_x)) -- Polynomial
                +   (0.25 * ((2 ^ blended_x) / (1.01 - blended_x))) -- Exponential

            if (greed_threshold > 1) then
                greed_threshold = 1
            elseif (greed_threshold < 0) then
                greed_threshold = 0
            end

            greedy = math_random() < greed_threshold
        else
            greedy = false
        end
    end

    if (not max_distance) then
        if (meta.last_radius) then
            max_distance = meta.last_radius
        elseif (meta.expanded_radius) then
            max_distance = meta.expanded_radius
        else
            max_distance = BASE_SEARCH_RADIUS * (1.0 - (0.96875 * blended_x))
        end
    end

    meta.last_radius = max_distance

    local best_distance = max_distance
    local worst_valid_distance = max_distance
    local best_target = nil

    local math_max = math_max
    local math_sqrt = math_sqrt
    local CHUNK_LEVELS = CHUNK_LEVELS
    local CHUNK_SIZE = CHUNK_SIZE or 32
    local math_huge = math_huge

    local stack = params.stack or { quadtree.base, }
    local stack_ptr = stack and #stack or 0

    local iteration_limit = params.iteration_limit or UINT16
    local iterations = 0
    local completed = true
    while stack_ptr > 0 do
        if (iterations > iteration_limit) then
            completed = false
            break
        end
        iterations = iterations + 1

        local node = stack[stack_ptr]
        stack_ptr = stack_ptr - 1
        if (node and not is_empty_node(node)) then
            local node_level = node.node_level or 0
            if (node_level <= CHUNK_LEVELS) then
                local shift = SHIFT_LOOKUP[node_level]

                local min_x, min_y = node.x - shift, node.y - shift
                local max_x, max_y = node.x + shift, node.y + shift
                local dx, dy = math_max(min_x - target_chunk.x, 0, target_chunk.x - max_x), math_max(min_y - target_chunk.y, 0, target_chunk.y - max_y)

                local delta = math_sqrt(dx * dx + dy * dy)
                local delta_threshold = limit and worst_valid_distance or best_distance
                if (delta < delta_threshold) then
                    local chunk = node.chunk
                    if (chunk) then
                        chunk.meta = chunk.meta or new_template(Quad_Meta_Data, params.tick)
                        if (chunk.meta.spawner_count > 0) then
                            local distance = math_huge
                            distance = math_sqrt(((chunk.x - target_chunk.x) * CHUNK_SIZE)^2 + ((chunk.y - target_chunk.y) * CHUNK_SIZE)^2)
                            if (limit) then
                                spawner_pool = spawner_pool or {}
                                spawner_distance_map = spawner_distance_map or {}

                                local pool_count = #spawner_pool

                                if (pool_count < limit or distance < worst_valid_distance) then
                                    spawner_distance_map[chunk.xy] = distance

                                    local insert_pos = pool_count + 1
                                    while insert_pos > 1 and distance < spawner_distance_map[spawner_pool[insert_pos - 1].xy] do
                                        spawner_pool[insert_pos] = spawner_pool[insert_pos - 1]
                                        insert_pos = insert_pos - 1
                                    end
                                    spawner_pool[insert_pos] = chunk
                                    pool_count = pool_count + 1

                                    if (pool_count > limit) then
                                        spawner_pool[pool_count] = nil
                                        pool_count = pool_count - 1
                                        worst_valid_distance = spawner_distance_map[spawner_pool[pool_count].xy]
                                    elseif (pool_count == limit) then
                                        worst_valid_distance = spawner_distance_map[spawner_pool[pool_count].xy]
                                    else
                                        worst_valid_distance = max_distance
                                    end

                                    best_target = spawner_pool[1]
                                    best_distance = spawner_distance_map[best_target.xy]

                                    if (greedy) then break end
                                end
                            elseif (distance < best_distance) then
                                best_target = chunk
                                best_distance = distance
                                worst_valid_distance = distance
                                if (greedy) then break end
                            end
                        end
                    end

                    local north = (target_chunk.y + 0.5) < (node.y * shift)
                    local west  = (target_chunk.x + 0.5) < (node.x * shift)

                    if (north) then
                        if (west) then
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.se
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.sw
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.ne
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.nw
                        else
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.sw
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.se
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.nw
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.ne
                        end
                    else
                        if (west) then
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.ne
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.nw
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.se
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.sw
                        else
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.nw
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.ne
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.sw
                            stack_ptr = stack_ptr + 1; stack[stack_ptr] = node.se
                        end
                    end
                end
            end
        end
    end

    -- local function search(node)
    --     if (is_empty_node(node) or not node.node_level or node.node_level > CHUNK_LEVELS) then return end

    --     local shift = 2 ^ (CHUNK_LEVELS - (node.node_level or 0))

    --     local min_x, min_y = node.x - shift, node.y - shift
    --     local max_x, max_y = node.x + shift, node.y + shift
    --     local dx, dy = math_max(min_x - target_chunk.x, 0, target_chunk.x - max_x), math_max(min_y - target_chunk.y, 0, target_chunk.y - max_y)

    --     local delta = math_sqrt(dx * dx + dy * dy)
    --     if (delta >= best_distance) then return end

    --     local chunk = node.chunk
    --     if (chunk) then
    --         chunk.meta = chunk.meta or new_template(Quad_Meta_Data, params.tick)
    --         if (chunk.meta.spawner_count > 0) then
    --             local distance = math_huge
    --             distance = math_sqrt(((chunk.x - target_chunk.x) * CHUNK_SIZE)^2 + ((chunk.y - target_chunk.y) * CHUNK_SIZE)^2)
    --             if (distance < best_distance) then
    --                 best_target = chunk
    --                 best_distance = distance
    --             end
    --         end
    --     end

    --     local north = (target_chunk.y + 0.5) < (node.y * shift)
    --     local west  = (target_chunk.x + 0.5) < (node.x * shift)

    --     if (north) then
    --         if (west) then
    --             if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
    --             if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
    --             if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
    --             if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
    --         else
    --             if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
    --             if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
    --             if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
    --             if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
    --         end
    --     else
    --         if (west) then
    --             if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
    --             if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
    --             if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
    --             if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
    --         else
    --             if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
    --             if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
    --             if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
    --             if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
    --         end
    --     end

    --     return best_target
    -- end

    -- return search(quadtree.base)
    return spawner_pool or best_target, stack, stack_ptr, completed
end

local function find_leaf_node(node)
   if (not node) then return end
   if (node.chunk) then return node end

    if (node.nw) then return find_leaf_node(node.nw) end
    if (node.ne) then return find_leaf_node(node.ne) end
    if (node.sw) then return find_leaf_node(node.sw) end
    if (node.se) then return find_leaf_node(node.se) end
end

function quadtree_service.remove_node(params)
    if (not params) then return end
    if (not params.surface_name or not params.source_chunk) then return end

    local surface_name = params.surface_name

    quadtrees = quadtrees or set_game() and quadtrees
    if (not quadtrees[surface_name]) then return end

    local quadtree = quadtrees[surface_name]
    if (    not quadtree.base
        or  not quadtree.base.nw
        and not quadtree.base.ne
        and not quadtree.base.sw
        and not quadtree.base.se
    ) then
        if (quadtree.base) then quadtree.base.count = 0 end
        return
    end

    if (params.metrics) then quadtree_service.apply_metrics(params.source_chunk, params.metrics, params.tick) end

    local root = { x = 0, y = 0, }
    local function remove(parent_node, source_chunk, start_pos)
        if (not parent_node or not source_chunk or not start_pos) then return end

        local direction = ""
        if ((source_chunk.x + 0.5) < start_pos.x) then
            direction = ((source_chunk.y + 0.5) < start_pos.y) and NW or SW
        else
            direction = ((source_chunk.y + 0.5) < start_pos.y) and NE or SE
        end

        local target_node = parent_node[direction]
        if (not target_node) then return end

        if (target_node.chunk) then
            if (target_node.chunk.x == source_chunk.x and target_node.chunk.y == source_chunk.y) then
                parent_node[direction] = nil
                parent_node.count = math_max((parent_node.count or 1) - 1, 0)

                quadtree.base.count = math_max((quadtree.base.count or 1) - 1, 0)

                return true
            end

            return
        end

        -- local shift_factor = 2 ^ (CHUNK_LEVELS - (target_node.node_level or CHUNK_LEVELS))
        local shift_factor = SHIFT_LOOKUP[target_node.node_level or CHUNK_LEVELS]
        local node_pos = {
            x = math_floor(target_node.x * shift_factor) or 0,
            y = math_floor(target_node.y * shift_factor) or 0,
        }

        local removed = remove(target_node, source_chunk, node_pos)
        if (removed) then
            if (is_empty_node(target_node)) then parent_node[direction] = nil end

            parent_node.count = 0
            local p_nw, p_ne, p_sw, p_se = parent_node.nw, parent_node.ne, parent_node.sw, parent_node.se

            if (p_nw) then parent_node.count = math_max((parent_node.count or 0), 0) + (p_nw.chunk and 1 or p_nw.count or 0) end
            if (p_ne) then parent_node.count = math_max((parent_node.count or 0), 0) + (p_ne.chunk and 1 or p_ne.count or 0) end
            if (p_sw) then parent_node.count = math_max((parent_node.count or 0), 0) + (p_sw.chunk and 1 or p_sw.count or 0) end
            if (p_se) then parent_node.count = math_max((parent_node.count or 0), 0) + (p_se.chunk and 1 or p_se.count or 0) end

            if (parent_node.count == 1) then
                local leaf_node = find_leaf_node(parent_node)
                if (leaf_node and leaf_node.chunk) then
                    leaf_node.chunk.parent_node = parent_node
                    parent_node.chunk = leaf_node.chunk
                    parent_node.count = nil
                    parent_node.nw, parent_node.ne, parent_node.sw, parent_node.se = nil, nil, nil, nil
                end
            end
        end

        return removed
    end

    remove(quadtree.base, params.source_chunk, root)

    if (is_empty_node(quadtree.base)) then quadtree.base = new_Quadnode(Quadnode, { count = 0, }, params.tick) end
end

function quadtree_service.propagate_node_metrics_iteratively(node, tick)
    if (not node) then return end

    tick = tick or (game or set_game()).tick

    local new_template = new_template
    local aggregate_leaf_nodes = aggregate_leaf_nodes

    local current_node = node.parent_node
    local parent = nil
    local count = 0
    while current_node ~= nil and (current_node.node_level or -1) >= 0 and count <= (CHUNK_LEVELS + 1) do
        count = count + 1
        parent = current_node.parent_node

        if (not current_node.chunk) then
            local nw, ne, sw, se = current_node.nw, current_node.ne, current_node.sw, current_node.se
            local nwm, nem, swm, sem = nw and nw.meta or new_template(Quad_Meta_Data, tick), ne and ne.meta or new_template(Quad_Meta_Data, tick), sw and sw.meta or new_template(Quad_Meta_Data, tick), se and se.meta or new_template(Quad_Meta_Data, tick)

            local meta = current_node.meta
            if (not meta or (meta.created or -1) < 0) then
                current_node.meta = new_template(Quad_Meta_Data, tick)
                meta = current_node.meta
            end

            aggregate_leaf_nodes(meta, tick, nwm, nem, swm, sem)
        end

        current_node = parent
        parent = nil
    end
end

function quadtree_service.apply_metrics(chunk, metrics, tick)
    if (not chunk or not chunk.parent_node) then return end
    -- metrics = metrics or { w = 0, fx = 0, p = 1, }
    metrics = metrics or DEFAULT_EMPTY_METRIC

    tick = tick or (game or set_game()).tick

    local c_meta = chunk.meta
    if (not c_meta or (c_meta.created or -1) < 0) then
        chunk.meta = new_template(Quad_Meta_Data, tick)
        c_meta = chunk.meta
    end

    local parent_node = chunk.parent_node
    parent_node.meta = parent_node.meta or new_template(Quad_Meta_Data, tick)
    local p_meta = parent_node.meta

    merge_data(p_meta, c_meta, metrics, tick)

    quadtree_service.propagate_node_metrics_iteratively(parent_node, tick)
end

function quadtree_service.register_highest_chunk(chunk, surface_name, value, tick)
    if (not chunk or not chunk.xy) then return end
    if (not surface_name or not Valid_Surfaces[surface_name]) then return end
    value = value or 0
    tick = tick or (game or set_game()).tick

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])
    local selected_difficulty = difficulties[surface_name]

    target_registries = target_registries or set_game() and target_registries
    target_registries[surface_name] = target_registries[surface_name] or new_Target_Registry_Data(Target_Registry_Data, {}, selected_difficulty and selected_difficulty.value or nil)

    local target_registry = target_registries[surface_name]

    local q_key = nil
    if (chunk.y < 0) then
        q_key = chunk.x < 0 and NW or NE
    else
        q_key = chunk.x < 0 and SW or SE
    end

    local q_matrix = target_registry[q_key or EMPTY]
    if (q_matrix) then
        merge_target_registry(q_matrix, chunk, surface_name, value, tick)
    end

    merge_target_registry(target_registry, chunk, surface_name, value, tick)
end

function quadtree_service.coordinates_to_leaf_node(params)
    if (not params) then return end
    if (not params.xy and (not params.x or not params.y)) then return end
    if (not params.surface_name or not Valid_Surfaces[params.surface_name]) then return end

    local surface_name = params.surface_name
    quadtrees = quadtrees or set_game() and quadtrees
    quadtrees[surface_name] = quadtrees[surface_name] or new_Quadtree(Quadtree, { surface_name = surface_name, })
    local quadtree = quadtrees[surface_name]

    local chunk_x, chunk_y = params.x, params.y
    if (not chunk_x or not chunk_y) then chunk_x, chunk_y = unpack_coordinates(params.xy) end
    if (not chunk_x or not chunk_y) then return end

    local current_node = params.base or quadtree.base
    local current_x, current_y = current_node and current_node.x or nil, current_node and current_node.y or nil
    local layer_chunks = SHIFT_LOOKUP[(current_node and current_node.node_level or 0)]
    local offset = layer_chunks / 4

    local CHUNK_LEVELS = CHUNK_LEVELS
    local iterations = 0
    while current_node and not current_node.chunk and current_node.node_level < CHUNK_LEVELS and iterations < 40 do
        iterations = iterations + 1

        layer_chunks = SHIFT_LOOKUP[current_node.node_level]
        offset = layer_chunks / 4

        local is_north = chunk_y < current_y
        local is_west = chunk_x < current_x

        if (is_north) then
            current_y = current_y - offset
            if (is_west) then
                current_x = current_x - offset
                current_node = current_node.nw
            else
                current_x = current_x + offset
                current_node = current_node.ne
            end
        else
            current_y = current_y + offset
            if (is_west) then
                current_x = current_x - offset
                current_node = current_node.sw
            else
                current_x = current_x + offset
                current_node = current_node.se
            end
        end
    end

    return current_node and current_node.chunk or nil
end

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name] = function (event, params) max_unit_groups = params.setting_value end

local ME_PREFIX = ME_PREFIX
local STRING = Types.STRING
function quadtree_service.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = quadtree_service.on_runtime_mod_setting_changed
})

function quadtree_service.init(__storage) storage = __storage or _ENV.storage end

return quadtree_service