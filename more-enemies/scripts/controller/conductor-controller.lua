local storage
local stats_data
local system_stats
local active_scouts
local chunk_arr
local chunk_maps
local conductors
local difficulties
local entities
local entity_chunks
local entity_maps
local groups
local limits
local num_clones
local on_object_destroyed
local pathables
local post_entity_died_buckets
local scout_path_registry
local scout_registry
local spawner_chunks
local spawner_maps
local surfaces
local surface_creation
local target_registries
local unit_groups
local unique_ids

local game
local get_surface
local forces
local force_funcs
local planetary_surfaces
local surface_funcs

local Surfaces = Surfaces

local Set_Game_Funcs = Set_Game_Funcs

local Set_Num_Clones = Set_Num_Clones

local Constants = Constants or require("scripts.constants.constants")
local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new
local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local string_find = string.find

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.system_stats = storage.system_stats or {}
    system_stats = storage.system_stats

    storage.active_scouts = storage.active_scouts or {}
    active_scouts = storage.active_scouts

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.surface_creation = storage.surface_creation or {}
    surface_creation = storage.surface_creation

    storage.chunk_arr = storage.chunk_arr or {}
    chunk_arr = storage.chunk_arr

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.conductors = storage.conductors or {}
    conductors = storage.conductors

    storage.entities = storage.entities or {}
    entities = storage.entities

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.limits = storage.limits or {}
    limits = storage.limits

    storage.on_object_destroyed = storage.on_object_destroyed or new_Simple_Queue(Simple_Queue)
    on_object_destroyed = storage.on_object_destroyed

    storage.pathables = storage.pathables or {}
    pathables = storage.pathables

    storage.post_entity_died_buckets = storage.post_entity_died_buckets or {}
    post_entity_died_buckets = storage.post_entity_died_buckets

    storage.scout_path_registry = storage.scout_path_registry or {}
    scout_path_registry = storage.scout_path_registry

    storage.scout_registry = storage.scout_registry or new_Simple_Queue(Simple_Queue)
    scout_registry = storage.scout_registry

    storage.spawner_chunks = storage.spawner_chunks or {}
    spawner_chunks = storage.spawner_chunks

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    storage.target_registries = storage.target_registries or {}
    target_registries = storage.target_registries

    for _, planet in ipairs(Planets or {}) do
        post_entity_died_buckets[planet] = post_entity_died_buckets[planet] or {}

        surfaces[planet] = surfaces[planet] or {}
        surfaces[planet].chunks = surfaces[planet].chunks or {}
        surfaces[planet].entity_chunks = surfaces[planet].entity_chunks or {}
        surfaces[planet].spawner_chunks = surfaces[planet].spawner_chunks or {}
        surfaces[planet].chunk_map = surfaces[planet].chunk_map or {}
        surfaces[planet].entity_maps = surfaces[planet].entity_maps or {}
        surfaces[planet].spawner_map = surfaces[planet].spawner_map or {}

        chunk_arr[planet] = chunk_arr[planet] or surfaces[planet].chunks
        entity_chunks[planet] = entity_chunks[planet] or surfaces[planet].entity_chunks
        spawner_chunks[planet] = spawner_chunks[planet] or surfaces[planet].spawner_chunks
        chunk_maps[planet] = chunk_maps[planet] or surfaces[planet].chunk_map
        entity_maps[planet] = entity_maps[planet] or surfaces[planet].entity_maps
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_maps
    end

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    storage.unique_ids = storage.unique_ids or {}
    unique_ids = storage.unique_ids

    game = __game or _ENV.game
    get_surface = game.get_surface

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

    -- _ENV.Surface_Funcs = _ENV.Surface_Funcs or {}
    -- Surface_Funcs = _ENV.Surface_Funcs

    -- _ENV.Surfaces = _ENV.Surfaces or {}
    -- Surfaces = _ENV.Surfaces
    -- Surfaces.list = Surfaces.list or {}
    -- for name, surface in pairs(game.surfaces) do
    --     if (surface.valid and not string_find(surface.name, "platform%-[%d]*")) then
    --         Surfaces[name] = surface
    --         Surfaces.list[surface.index] = name

    --         Surface_Funcs[name] = Surface_Funcs[name] or {}
    --         Surface_Funcs[name].build_enemy_base = Surface_Funcs[name].build_enemy_base or surface.build_enemy_base
    --         Surface_Funcs[name].create_unit_group = Surface_Funcs[name].create_unit_group or surface.create_unit_group
    --         Surface_Funcs[name].count_entities_filtered = Surface_Funcs[name].count_entities_filtered or surface.count_entities_filtered
    --         Surface_Funcs[name].get_pollution = Surface_Funcs[name].get_pollution or surface.get_pollution
    --         Surface_Funcs[name].find_entities_filtered = Surface_Funcs[name].find_entities_filtered or surface.find_entities_filtered
    --         Surface_Funcs[name].find_non_colliding_position = Surface_Funcs[name].find_non_colliding_position or surface.find_non_colliding_position
    --         Surface_Funcs[name].request_path = Surface_Funcs[name].request_path or surface.request_path
    --     else
    --         Surfaces[name], Surface_Funcs[name] = nil, nil
    --     end
    -- end
    -- planetary_surfaces = Surfaces
    -- surface_funcs = Surface_Funcs
    Set_Game_Funcs()
    forces = _ENV.Forces
    force_funcs = _ENV.Force_Funcs
    planetary_surfaces = _ENV.Surfaces
    surface_funcs = _ENV.Surface_Funcs

    num_clones = Set_Num_Clones()

    return game
end


local math_abs = math.abs
local math_exp = math.exp
local math_floor = math.floor
local math_huge = math.huge
local math_log = math.log
local math_min = math.min
local math_max = math.max
local math_random = math.random
local math_sqrt = math.sqrt
local pairs = pairs
local table_insert = table.insert
local table_size = table_size

local E = math_exp(1)

local BASE_SEARCH_RADIUS = 1024 * Constants.CHUNK_SIZE
local CHUNK_SIZE = Constants.CHUNK_SIZE
local NTH_TICK = 45
local TWO_CHUNKS = 2 * CHUNK_SIZE

local SHIFT_LOOKUP = SHIFT_LOOKUP

local UINT8 = 2^8-1
local UINT64 = 2^64-1

local script = script
local register_on_object_destroyed = script.register_on_object_destroyed

local Log = Log
local Startup_Settings_Constants = Startup_Settings_Constants

local Settings_Service = Settings_Service
local get_startup_setting = Settings_Service.get_startup_setting

local deepcopy = Deepcopy

local Planets = Planets
local num_planets = table_size(Planets)
local planets = {}

local i = 0
local modulo = math_min(NTH_TICK, #Planets)
for _, planet in pairs(Planets) do
    local idx = i % modulo
    planets[idx] = planets[idx] or {}
    table_insert(planets[idx], planet)
    i = i + 1
end

local concurrent_actions = 1 + math_floor(2 * math_sqrt(num_planets))

log(serpent.block(Planets))
log(serpent.block(planets))

local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
local get_enemy = Attack_Group_Utils.get_enemy
local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template
local merge_data = Quad_Meta_Data.merge_data
local Quadtree_Service = require("scripts.service.quadtree-service")
local propagate_node_metrics_iteratively = Quadtree_Service.propagate_node_metrics_iteratively
local find_closest_iteratively = Quadtree_Service.find_closest_iteratively
local find_closest_spawner = Quadtree_Service.find_closest_spawner
local register_highest_chunk = Quadtree_Service.register_highest_chunk
local coordinates_to_leaf_node = Quadtree_Service.coordinates_to_leaf_node
local Requesting_Unit_Group = require("scripts.data.requesting-unit-group")
local new_Requesting_Unit_Group = Requesting_Unit_Group.new
local Scout_Group_Data = Scout_Group_Data or require("scripts.data.scout-group-data")
local new_Scout_Group = Scout_Group_Data.new
local Target_Registry_Data = require("scripts.data.target-registry-data")
local new_Target_Registry_Data = Target_Registry_Data.new

local STATES = require("scripts.constants.conductor-state-constants")

local BOUNDING_BOXES = {
    [UNIT] = {{-0.25, -0.25}, {0.25, 0.25},},
    [SPIDER_UNIT] = {{-0.05, -0.05}, {0.05, 0.05}},
}

local COLLISION_MASKS = {
    [FLYING_UNIT] = {
        layers = {
            ["empty_space"] = true,
            ["out_of_map"] = true,
        },
    },
    [WATERLESS_UNIT] = {
        layers = {
            ["object"] = true,
            ["empty_space"] = true,
            ["lava_tile"] = true,
            ["cliff"] = true,
            ["out_of_map"] = true,
        },
    },
    [UNIT] = {
        layers = {
            ["water_tile"] = true,
            ["object"] = true,
            ["empty_space"] = true,
            ["lava_tile"] = true,
            ["cliff"] = true,
            ["out_of_map"] = true,
        },
    },
    [SPIDER_UNIT] = {
        layers={
            ["player"] = true,
            ["train"] = true,
            ["is_object"] = true
        },
    },
}

local surface_unit_types = {
    [GLEBA] = SPIDER_UNIT,
    [FULGORA] = WATERLESS_UNIT,
    [CASTRA] = WATERLESS_UNIT,
}

local PATHFINDER_FLAGS = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, cache = true, }
local PATHFINDER_FLAGS_LOW_PRIORITY = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, cache = true, low_priority = true }

local conductor_styles = {
    ["None"] = 0,
    ["Random"] = 1,
    ["Adaptive"] = 2,
    ["Omni-mind"] = 3,
}
local NONE = conductor_styles["None"]
local RANDOM = conductor_styles["Random"]
local OMNI_MIND = conductor_styles["Omni-mind"]
local conductor_style = Data_Utils.get_startup_setting({ setting = Startup_Settings_Constants.settings.CONDUCTOR_STYLE.name, })
local selected_style = conductor_styles[conductor_style]

local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, }) or 30

local peace_time = {}
for _, surface_name in pairs(Planets) do
    local idx = surface_name:gsub("%-", "_"):upper()
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_ATTACK_GROUP_PEACE_TIME"]
    if (setting and setting.name) then
        peace_time[surface_name] = Data_Utils.get_runtime_global_setting({ setting = setting.name, }) * Constants.time.TICKS_PER_MINUTE
    end
end

local conductor_controller = {}
conductor_controller.name = "conductor_controller"
conductor_controller.set_game = set_game

local STATE_RECOVERY = STATES.RECOVERY
local STATE_IDLE = STATES.IDLE
local STATE_REQUESTING = STATES.REQUESTING
local STATE_SCANTREE = STATES.SCANTREE
local STATE_REQUESTING_PATH = STATES.REQUESTING_PATH
local STATE_PATHFINDING = STATES.PATHFINDING
local STATE_PATH_FOUND = STATES.PATH_FOUND
local STATE_PATH_PROCESSING = STATES.PATH_PROCESSING
local STATE_DISPATCH = STATES.DISPATCH
local STATE_FINALIZE = STATES.FINALIZE

local SIGN_OF_THE_BEAST = 666
local SIX_OF_THE_BEAST = 6*666
local BASE_DELAY = 60*SIGN_OF_THE_BEAST

local BOTTOM_UP = "bottom-up"
local TOP_DOWN = "top-down"

local ATTACK = ATTACK
local EXPANSION = EXPANSION
local SCOUT = SCOUT

local function request_action(surface_name, tick)
    if (not surface_name) then return end
    tick = tick or 0

    conductors = conductors or set_game()
    conductors[surface_name] = conductors[surface_name] or {}
    local  conductor = conductors[surface_name]

    if (((conductor.next_scoutng_tick or 0) - tick) > 0) then
        conductor.next_scoutng_tick = math_floor(conductor.next_scoutng_tick * 0.9)
        return
    end

    planetary_surfaces = planetary_surfaces or set_game() and planetary_surfaces
    if (not planetary_surfaces[surface_name] or not planetary_surfaces[surface_name].valid) then
        return
    end

    force_funcs = force_funcs or set_game() and force_funcs
    local z = force_funcs[ENEMY] and force_funcs[ENEMY].get_evolution_factor(surface_name) or 0.0

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])
    local selected_difficulty = difficulties[surface_name]
    local inverse_evolution = 1 - z
    if (selected_difficulty) then
        local val = selected_difficulty.value or 1
        conductor.base_delay_over_x = conductor.base_delay_over_x or BASE_DELAY / val
        conductor.scaled_base_delay = conductor.scaled_base_delay or BASE_DELAY / math_sqrt(val)
        conductor.rand_mult = conductor.rand_mult or (1 / math_log(val + 2, E)) + 1
    end

    conductor.next_scoutng_tick = tick + math_max(math_random((11.1 - selected_difficulty.value) ^ 2, 180), math_floor((conductor.base_delay_over_x + (conductor.scaled_base_delay * (inverse_evolution ^ 0.5))) + conductor.rand_mult * math_random(SIGN_OF_THE_BEAST)) / 10)
    return math_random() > 0.5
end

local pathing_recovery_states = {
    [STATE_PATHFINDING] = STATE_PATHFINDING,
    [STATE_PATH_FOUND] = STATE_PATH_FOUND,
    [STATE_PATH_PROCESSING] = STATE_PATH_PROCESSING,
    [STATE_DISPATCH] = STATE_DISPATCH,
}

local CHUNK_LEVELS = Constants.CHUNK_LEVELS

local function regionally_significant(chunk, ctx, tick)
    if (not chunk) then return end
    if (not chunk.x or not chunk.y) then return end
    if (not chunk.parent_node) then return end
    if (not chunk.meta) then return end
    if (not ctx) then return end

    tick = tick or (game or set_game()).tick

    local parent_node = chunk.parent_node
    local c_meta = chunk.meta
    local p_meta = parent_node.meta

    local raw_spawner_count = (c_meta.spawner_count or 0)
    local spawner_count = raw_spawner_count
    local spawner_density = 0

    local raw_entity_count = (c_meta.entity_count or 0)
    local entity_count = raw_entity_count
    local entity_density = 0

    local raw_witnessed_count = (c_meta.witnessed_entity_count or 0)
    local witnessed_count = raw_witnessed_count
    local witnessed_count_density = 0

    local raw_pollution = (c_meta.pollution or 0)
    local pollution_count = raw_pollution
    local pollution_count_density = 0

    if (parent_node and p_meta) then
        local qN, n = parent_node, 1
        local qN_meta = qN and qN.meta or nil
        local limit = (ctx.batch_limit or 3)

        while qN and qN_meta and n < CHUNK_LEVELS and n <= limit do
            local n_factor = (0.25 ^ n)

            spawner_count = spawner_count + (qN_meta.spawner_count or 0) * n_factor
            entity_count = entity_count + (qN_meta.entity_count or 0) * n_factor
            witnessed_count = witnessed_count + (qN_meta.witnessed_entity_count or 0) * n_factor
            pollution_count = pollution_count + (qN_meta.pollution or 0) * n_factor
            raw_spawner_count = (qN_meta.spawner_count or 0)
            raw_entity_count = (qN_meta.entity_count or 0)
            raw_witnessed_count = (qN_meta.witnessed_entity_count or 0)
            raw_pollution = (qN_meta.pollution or 0)

            -- local layer_size = 2 ^ (CHUNK_LEVELS - (qN.node_level or 0))
            local layer_size = SHIFT_LOOKUP[qN.node_level or 0]
            local margin = layer_size * 0.25

            local chunk_scaled_x = chunk.x / layer_size
            local chunk_scaled_y = chunk.y / layer_size

            local distance_from_center_x = chunk_scaled_x - qN.x
            local distance_from_center_y = chunk_scaled_y - qN.y

            local root_parent = qN.parent_node
            if (root_parent) then
                local is_north = qN.y < root_parent.y
                local is_west  = qN.x < root_parent.x

                local edge_threshold = 0.5 - (margin / layer_size)

                if (math_abs(distance_from_center_x) > edge_threshold) then
                    if (distance_from_center_x > 0) then
                        local adjacent_cousin = is_north and root_parent.ne or root_parent.se
                        if (adjacent_cousin and adjacent_cousin.meta) then
                            local ac_meta = adjacent_cousin.meta

                            spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                            entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                            witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                            pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor
                        end
                    else
                        local adjacent_cousin = is_north and root_parent.nw or root_parent.sw
                        if (adjacent_cousin and adjacent_cousin.meta) then
                            local ac_meta = adjacent_cousin.meta

                            spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                            entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                            witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                            pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor
                        end
                    end
                end

                if (math_abs(distance_from_center_y) > edge_threshold) then
                    if (distance_from_center_y > 0) then
                        local adjacent_cousin = is_west and root_parent.sw or root_parent.se
                        if (adjacent_cousin and adjacent_cousin.meta) then
                            local ac_meta = adjacent_cousin.meta

                            spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                            entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                            witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                            pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor
                        end
                    else
                        local adjacent_cousin = is_west and root_parent.nw or root_parent.ne
                        if (adjacent_cousin and adjacent_cousin.meta) then
                            local ac_meta = adjacent_cousin.meta

                            spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                            entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                            witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                            pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor
                        end
                    end
                end
            end

            n = n + 1
            qN = qN.parent_node
            qN_meta = qN and qN.meta or nil
        end
    end

    entity_density = entity_count / (raw_entity_count > 0  and raw_entity_count or 1)
    spawner_density = spawner_count / (raw_spawner_count > 0  and raw_spawner_count or 1)
    witnessed_count_density = witnessed_count / (raw_witnessed_count > 0  and raw_witnessed_count or 1)
    local raw_witnessed_density = raw_witnessed_count / (raw_entity_count > 0  and raw_entity_count or 1)
    pollution_count_density = pollution_count / (raw_pollution > 0  and raw_pollution or 1)

    local threat_pull = pollution_count_density * 4 + witnessed_count_density * 3 + raw_witnessed_density * 2

    local hive_vitality = 1.0
    if (spawner_density > 0.8) then
        hive_vitality = 0.10
    elseif (spawner_density < 0.05) then
        hive_vitality = 0.15
    else
        hive_vitality = 1.0 - spawner_density
    end

    local chunk_value = (entity_density * 1.5) + (threat_pull * hive_vitality)
    chunk.value = chunk_value
    chunk.value_tick = tick

    -- log(serpent.block({
    --     entity_density = entity_density,
    --     spawner_density = spawner_density,
    --     witnessed_count_density = witnessed_count_density,
    --     raw_witnessed_density = raw_witnessed_density,
    --     pollution_count_density = pollution_count_density,
    --     hive_vitality = hive_vitality,
    --     chunk_value = chunk_value,
    -- }))

    local SIGNIFICANCE_FLOOR = 0.02
    if (chunk_value < SIGNIFICANCE_FLOOR) then return nil end

    local adaptive_threshold = 0.1 + (ctx.evolution_factor or 0.01) * 0.15
    if ((chunk_value < adaptive_threshold) and witnessed_count_density == 0) then return end

    return chunk, chunk_value
end

local ENEMY = ENEMY
local GLEBA = GLEBA
local SPIDER_UNIT, UNIT = SPIDER_UNIT, UNIT
local GROUP = GROUP
function conductor_controller.on_nth_tick(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    local tick = event.tick or 0
    local inverse_stress = 1 - (stats_data.meta.last_load or 0)
    local max_steps_allowed_this_tick = 1 + math_floor(4 * inverse_stress)
    local max_scout_groups_processed_this_tick = 1 + math_floor(num_planets * inverse_stress)

    scout_registry = scout_registry or set_game() and scout_registry

    post_entity_died_buckets = post_entity_died_buckets or set_game() and post_entity_died_buckets
    local parents_to_propogate = nil
    local propgate_count = 0
    local awake_surfaces = nil

    difficulties = difficulties or set_game() and difficulties

    --[[ Phase 1 ]]
    for _, surface_name in ipairs(planets[(math_floor(tick / NTH_TICK) % modulo)] or {}) do
        planetary_surfaces = planetary_surfaces or set_game() and planetary_surfaces
        if (not planetary_surfaces[surface_name] or not planetary_surfaces[surface_name].valid) then goto continue end

        post_entity_died_buckets[surface_name] = post_entity_died_buckets[surface_name] or {}
        local buckets = post_entity_died_buckets[surface_name]
        local buckets_processed = {}

        difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])

        target_registries = target_registries or set_game() and target_registries
        target_registries[surface_name] = target_registries[surface_name] or new_Target_Registry_Data(Target_Registry_Data, {}, difficulties[surface_name].value or nil)
        local target_registry = target_registries[surface_name]

        for xy, bucket in pairs(buckets) do
            local chunk = bucket.chunk
            if (chunk.parent_node) then
                local parent_node = chunk.parent_node
                parent_node.chunk = chunk
                parent_node.meta = parent_node.meta or new_template(Quad_Meta_Data, tick)
                local p_meta = parent_node.meta
                local c_meta = chunk.meta

                merge_data(p_meta, c_meta, bucket, tick)

                p_meta.updated = tick
                propgate_count = propgate_count + 1

                parents_to_propogate = parents_to_propogate or {}
                parents_to_propogate[propgate_count] = chunk.parent_node

                if (not target_registry.mapped_idx[chunk.xy] or tick - (chunk.value_tick or 0) > SIX_OF_THE_BEAST) then
                    register_highest_chunk(chunk, surface_name, chunk.value or 0, tick)
                end
            end
            buckets_processed[xy] = 1
            buckets[xy] = nil
        end

        if (not planetary_surfaces[surface_name] or not planetary_surfaces[surface_name].valid) then goto continue end

        if (surface_creation and not surface_creation[surface_name]) then
            if (get_surface(surface_name).index == 1) then
                surface_creation[surface_name] = 0
            else
                surface_creation[surface_name] = event.tick
            end
        end

        if (((peace_time[surface_name] or UINT64) + (surface_creation and surface_creation[surface_name] or UINT64)) >= event.tick ) then goto continue end
        awake_surfaces = awake_surfaces or {}
        awake_surfaces[#awake_surfaces+1] = surface_name

        active_scouts = active_scouts or set_game() or active_scouts
        active_scouts[surface_name] = active_scouts[surface_name] or new_Simple_Queue(Simple_Queue)
        local local_active_scouts = active_scouts[surface_name]

        local_active_scouts.first = local_active_scouts.first or 1
        local_active_scouts.last = local_active_scouts.last or 1

        if ((local_active_scouts.last - local_active_scouts.first) > 0) then
            for _ = 1, max_scout_groups_processed_this_tick, 1 do
                local first_idx = local_active_scouts.first
                local local_active_scout = local_active_scouts.q[first_idx]
                local_active_scouts.q[first_idx] = nil
                local_active_scouts.first = first_idx + 1

                if (not local_active_scout) then break end
                local group = local_active_scout.group
                if (group and group.valid) then
                    chunk_maps = chunk_maps or set_game() and chunk_maps
                    local chunk_map = chunk_maps[surface_name]
                    if (chunk_map) then
                        local xy = pack_coordinates(group.position.x / CHUNK_SIZE, group.position.y / CHUNK_SIZE)
                        -- log(serpent.block(xy))
                        local chunk = chunk_map[xy]
                        if (chunk and chunk.parent_node) then
                            -- log(serpent.block({Coordinate_Utils.unpack(xy)}))
                            chunk.meta = chunk.meta or new_template(Quad_Meta_Data, tick)
                            local c_meta = chunk.meta
                            c_meta.witnessed_entity_count = c_meta.entity_count
                            c_meta.witnessed = 1
                            c_meta.witnessed_tick = tick
                            c_meta.updated = tick

                            local parent_node = chunk.parent_node
                            parent_node.chunk = chunk
                            parent_node.meta = parent_node.meta or new_template(Quad_Meta_Data, tick)

                            merge_data(parent_node.meta, c_meta, nil, tick)

                            if (not buckets_processed[xy]) then
                                buckets_processed[xy] = 1
                                propgate_count = propgate_count + 1

                                parents_to_propogate = parents_to_propogate or {}
                                parents_to_propogate[propgate_count] = parent_node
                            end
                        end

                        local next_last = local_active_scouts.last
                        local_active_scouts.last = next_last + 1
                        local_active_scouts.q[next_last] = local_active_scout
                        local_active_scout.idx = next_last
                        local_active_scout.updated = tick
                    else
                        --[[ Intentionally don't requeue the the scout_group_data as the group no longer exists, or is not longer valid ]]
                    end
                else
                    --[[ Intentionally don't requeue the the scout_group_data as the group no longer exists, or is not longer valid ]]
                end
            end

            if (local_active_scouts.last - local_active_scouts.first < 0 or local_active_scouts.last > 1 and local_active_scouts.last == local_active_scouts.first) then
                local_active_scouts.first, local_active_scouts.last, local_active_scouts.q = 1, 1, {}
            end
        end

        local scout_registry_count = (scout_registry.last or 0) - (scout_registry.first or 0)

        -- if (scout_registry_count >= 0 and scout_registry_count < concurrent_actions and request_action(surface_name, tick)) then
        if (    selected_style > RANDOM
            and scout_registry_count >= 0
            and scout_registry_count < concurrent_actions
            and request_action(surface_name, tick)
        ) then
            local next_idx = scout_registry.last
            scout_registry.last = next_idx + 1
            scout_registry.q[next_idx] = {
                state = STATE_REQUESTING,
                surface_name = surface_name,
                idx = next_idx,
                strictness = inverse_stress,
                unit_type = surface_unit_types[surface_name] or UNIT,
                created = tick,
                updated = tick,
            }
        end

        ::continue::
    end

    if (propgate_count > 0 and parents_to_propogate and parents_to_propogate[1]) then
        for _, node in ipairs(parents_to_propogate or {}) do
            propagate_node_metrics_iteratively(node, tick)
        end
    end

    --[[ Wake-up?! ]]
    if (not awake_surfaces or #awake_surfaces < 1) then return end

    --[[ Phase 2 ]]
    scout_registry.first = scout_registry.first or 1
    scout_registry.last = scout_registry.last or 1

    local total_active_requests = scout_registry.last - scout_registry.first
    local nominal_steps_executed = 0
    local entries_witnessed = 0

    local function requeue(ctx)
        local next_last = scout_registry.last
        scout_registry.last = next_last + 1
        scout_registry.q[next_last] = ctx
        ctx.idx = next_last
        ctx.updated = tick
    end

    while (entries_witnessed < total_active_requests) and nominal_steps_executed < max_steps_allowed_this_tick do
        entries_witnessed = entries_witnessed + 1
        local curr_idx = scout_registry.first
        local ctx = scout_registry.q[curr_idx]
        scout_registry.q[curr_idx] = nil
        scout_registry.first = curr_idx + 1

        if (ctx) then
            nominal_steps_executed = nominal_steps_executed + 1
            local surface_name = ctx.surface_name

            if (not planetary_surfaces[surface_name] or not planetary_surfaces[surface_name].valid) then goto continue end

            if (surface_creation and not surface_creation[surface_name]) then
                if (get_surface(surface_name).index == 1) then
                    surface_creation[surface_name] = 0
                else
                    surface_creation[surface_name] = event.tick
                end
            end

            if (((peace_time[surface_name] or UINT64) + (surface_creation and surface_creation[surface_name] or UINT64)) >= event.tick ) then goto continue end

            if (ctx.state == STATE_REQUESTING and selected_style > RANDOM) then
                ctx.request_attempts = ctx.request_attempts or 0

                spawner_chunks = spawner_chunks or set_game() and spawner_chunks
                spawner_chunks[surface_name] = spawner_chunks[surface_name] or {}

                local local_spawner_chunks = spawner_chunks[surface_name]
                local_spawner_chunks.upper_bound = local_spawner_chunks.upper_bound and local_spawner_chunks.upper_bound >= 1 and local_spawner_chunks.upper_bound or #local_spawner_chunks

                if (local_spawner_chunks.upper_bound >= 1) then
                    local attempts = 0
                    local next_chunk = nil
                    local candidate = nil
                    local rand = 1

                    while (local_spawner_chunks.upper_bound or 0) >= 1 and (attempts < 4) do
                        attempts = attempts + 1

                        rand = (local_spawner_chunks.upper_bound or 0) <= 1 and 1 or math_random(local_spawner_chunks.upper_bound)
                        candidate = local_spawner_chunks[rand]

                        local_spawner_chunks[rand] = local_spawner_chunks[local_spawner_chunks.upper_bound]
                        local_spawner_chunks[rand].i = rand
                        local_spawner_chunks[local_spawner_chunks.upper_bound] = candidate
                        candidate.i = local_spawner_chunks.upper_bound
                        local_spawner_chunks.upper_bound = local_spawner_chunks.upper_bound - 1

                        spawner_maps = spawner_maps or set_game() and spawner_maps
                        spawner_maps[surface_name] = spawner_maps[surface_name] or {}
                        local spawner_map = spawner_maps[surface_name]

                        if (not candidate.xy or not spawner_map[candidate.xy]) then
                            local last_idx = #local_spawner_chunks
                            local_spawner_chunks[candidate.i] = local_spawner_chunks[last_idx]
                            if (local_spawner_chunks[candidate.i]) then
                                local_spawner_chunks[candidate.i].i = candidate.i
                            end
                            local_spawner_chunks[last_idx] = nil
                            candidate = nil
                        else
                            ctx.batch_limit = ctx.batch_limit or 3
                            next_chunk = regionally_significant(candidate, ctx)
                            if (next_chunk) then
                                break
                            end
                        end
                    end

                    ctx.source_chunk = next_chunk
                    if (ctx.source_chunk) then
                        ctx.scalar = 1
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_SCANTREE
                    else
                        ctx.request_attempts = ctx.request_attempts + 1

                        if (ctx.request_attempts > 1 + 2 * inverse_stress) then
                            ctx.prev_state = ctx.state
                            ctx.state = STATE_RECOVERY
                        end
                    end
                else
                    ctx.request_attempts = ctx.request_attempts + 1

                    if (ctx.request_attempts > 1 + 2 * inverse_stress) then
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_RECOVERY
                    end
                end

                requeue(ctx)
            elseif (ctx.state == STATE_SCANTREE) then
                ctx.scanning_attempts = (ctx.scanning_attempts or 0) + 1

                system_stats = system_stats or set_game() and system_stats
                system_stats[ctx.surface_name] = system_stats[ctx.surface_name] or {}

                local search_type = BOTTOM_UP
                if (not ctx.search_checkpoint) then
                    if (    (system_stats[ctx.surface_name].last_load or 0) < 0.6
                        and (system_stats.last_load or 0) < 0.7
                    ) then
                        if (math_random() < 0.42) then search_type = TOP_DOWN end
                    end
                end

                ctx.search_checkpoint = ctx.search_checkpoint or {
                    search_type = search_type,
                    current_node = nil,
                    best_leaf = nil,
                    best_score = -1,
                    iterations = 1,
                    state = ctx.state,
                    force_name = ENEMY,
                }

                ctx.max_distance = math_max(TWO_CHUNKS, math_min(TWO_CHUNKS + ctx.search_checkpoint.iterations + (ctx.search_checkpoint.iterations * CHUNK_SIZE) / 2, BASE_SEARCH_RADIUS))
                find_closest_iteratively({
                    tick = tick,
                    checkpoint = ctx.search_checkpoint,
                    surface_name = ctx.surface_name,
                    source_chunk = ctx.source_chunk,
                    -- min_distance = TWO_CHUNKS,
                    min_distance = CHUNK_SIZE,
                    -- max_distance = math_min(TWO_CHUNKS + ctx.search_checkpoint.iterations + (ctx.search_checkpoint.iterations * CHUNK_SIZE) / 2, BASE_SEARCH_RADIUS),
                    max_distance = ctx.max_distance,
                })
                ctx.search_checkpoint.iterations = ctx.search_checkpoint.iterations + 1

                if (ctx.state ~= ctx.search_checkpoint.state) then
                    ctx.prev_state = ctx.state
                    ctx.state = ctx.search_checkpoint.state or STATE_RECOVERY
                    -- ctx.target_chunk = ctx.search_checkpoint.final_target or ctx.search_checkpoint.best_target
                    ctx.target_chunk = ctx.search_checkpoint.final_target
                    if (not ctx.target_chunk) then
                        if (ctx.search_checkpoint.search_type ~= TOP_DOWN or ctx.scanning_attempts > 1 + 2 * inverse_stress) then
                            ctx.prev_state = ctx.state
                            ctx.search_checkpoint = nil
                            ctx.state = STATE_RECOVERY
                        else
                            ctx.prev_state = ctx.state
                            ctx.search_checkpoint = nil
                            ctx.state = STATE_SCANTREE
                        end
                    else
                        ctx.scalar = (ctx.scalar or 1) * (ctx.search_checkpoint.scalar or 1)
                        ctx.action_type = ctx.search_checkpoint.action_type
                        ctx.search_checkpoint = nil
                    end
                else
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_SCANTREE

                    local chk_pt = ctx.search_checkpoint
                    ctx.fork_count = ctx.fork_count or 0
                    local count = 0
                    local candidates = nil
                    local action_mapping = nil

                    if (chk_pt.best_target) then
                        count = count + 1
                        candidates = candidates or {}
                        candidates[count] = chk_pt.best_target
                        action_mapping = action_mapping or {}
                        action_mapping[count] = ATTACK
                    end
                    if (chk_pt.best_frontier_node) then
                        count = count + 1
                        candidates = candidates or {}
                        candidates[count] = chk_pt.best_frontier_node
                        action_mapping = action_mapping or {}
                        action_mapping[count] = SCOUT
                    end
                    if (chk_pt.best_expansion_node) then
                        count = count + 1
                        candidates = candidates or {}
                        candidates[count] = chk_pt.best_expansion_node
                        action_mapping = action_mapping or {}
                        action_mapping[count] = EXPANSION
                    end

                    if (    count > 0
                        and candidates
                        and action_mapping
                        and chk_pt.stack_pointer
                        and chk_pt.stack_pointer > 0
                        and (ctx.fork_count or 0) < (1 + (chk_pt.fork_base or 0) * (chk_pt.evolution_factor or 0) + (chk_pt.fork_flat_bonus or 0))
                    ) then
                        local action, action_type = nil, nil
                        local rand = count == 1 and 1 or math_random(count)

                        action = candidates[rand]
                        action_type = action_mapping[rand]

                        local forked_ctx = {
                            state = STATE_REQUESTING_PATH,
                            prev_state = STATE_SCANTREE,
                            surface_name = ctx.surface_name,
                            -- source_chunk = ctx.source_chunk,
                            source_chunk = find_closest_spawner({
                                tick = tick,
                                surface_name = ctx.surface_name,
                                target_chunk = action,
                                max_distance = (ctx.max_distance * (2/3))
                            }) or ctx.source_chunk,
                            target_chunk = action,
                            action_type = action_type,
                            scalar = ctx.scalar,
                            unit_type = ctx.unit_type,
                            created = tick,
                            updated = tick,
                        }

                        if (action_type == ATTACK) then
                            chk_pt.best_target = nil
                        elseif (action_type == EXPANSION) then
                            chk_pt.best_expansion_node = nil
                        elseif (action_type == SCOUT) then
                            chk_pt.best_frontier_node = nil
                        else
                            chk_pt.best_target = nil
                            chk_pt.best_expansion_node = nil
                            chk_pt.best_frontier_node = nil
                        end
                        ctx.fork_count = (ctx.fork_count or 0) + 1

                        log("forked: " .. ctx.fork_count)
                        game.print("forked: " .. ctx.fork_count)
                        game.print({ "messages.entity-gps", "", forked_ctx.source_chunk.x * 32 + 16, forked_ctx.source_chunk.y * 32 + 16, forked_ctx.surface_name })
                        requeue(forked_ctx)
                    end
                end

                requeue(ctx)
            elseif (ctx.state == STATE_REQUESTING_PATH) then
                planetary_surfaces = planetary_surfaces or set_game and planetary_surfaces
                if (    planetary_surfaces[ctx.surface_name]
                    and planetary_surfaces[ctx.surface_name].valid
                ) then
                    ctx.path_request_attempts = ctx.path_request_attempts or 0
                    --[[ TODO: determine these more appropriately ]]

                    local source_chunk = ctx.source_chunk or find_closest_spawner({
                        surface_name = ctx.surface_name,
                        target_chunk = ctx.target_chunk,
                        max_distance = ctx.max_distance,
                        tick = tick,
                    })
                    if (source_chunk) then
                        log("found source chunk")
                        game.print("found source chunk")
                        game.print({ "messages.entity-gps", "", source_chunk.x * 32 + 16, source_chunk.y * 32 + 16, ctx.surface_name })
                        -- local start = { x = (ctx.source_chunk.x + 0.5) * CHUNK_SIZE, y = (ctx.source_chunk.y + 0.5) * CHUNK_SIZE, }
                        local start = { x = (source_chunk.x + 0.5) * CHUNK_SIZE, y = (source_chunk.y + 0.5) * CHUNK_SIZE, }
                        local goal  = { x = (ctx.target_chunk.x * CHUNK_SIZE) + (math_random() * CHUNK_SIZE), y = (ctx.target_chunk.y * CHUNK_SIZE) + (math_random() * CHUNK_SIZE), }

                        local path_request = {
                            bounding_box = BOUNDING_BOXES[ctx.unit_type] or BOUNDING_BOXES[UNIT],
                            collision_mask = COLLISION_MASKS[ctx.unit_type] or COLLISION_MASKS[UNIT],
                            start = start,
                            goal = goal,
                            force = ctx.force or ENEMY,
                            radius = 12,
                            pathfind_flags = PATHFINDER_FLAGS_LOW_PRIORITY,
                            can_open_gates = false,
                            path_resolution_modifier = -1,
                            max_gap_distance = ctx.unit_type == SPIDER_UNIT and 4 or 0,
                        }

                        local path_id = surface_funcs[ctx.surface_name].request_path(path_request)
                        if (not path_id) then
                            --[[
                                According to the mod API, a uint32 should always be returned
                                -> i.e. this shouldn't be needed, but oh well
                            ]]
                            ctx.path_request_attempts = ctx.path_request_attempts + 1
                            if (ctx.path_request_attempts > 1 + 2 * inverse_stress) then
                                ctx.prev_state = ctx.state
                                ctx.state = STATE_RECOVERY
                            end

                            requeue(ctx)
                        else
                            ctx.prev_state = ctx.state
                            ctx.state = STATE_PATHFINDING
                            ctx.path_id = path_id
                            ctx.path_request = path_request
                            ctx.path_request_attempts = nil
                            ctx.idx = nil

                            difficulties = difficulties or set_game() and difficulties
                            difficulties[ctx.surface_name] = difficulties[ctx.surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[ctx.surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])
                            local selected_difficulty = difficulties[ctx.surface_name]

                            unit_groups = unit_groups or set_game() and unit_groups
                            unit_groups[path_id] = new_Requesting_Unit_Group(Requesting_Unit_Group, {
                                enemies = {},
                                surface_name = ctx.surface_name,
                                force_name = ctx.force_name or ENEMY,
                                start_position  = path_request.start,
                                target_position = path_request.goal,
                                -- xy = pack_coordinates(math_floor(ctx.source_chunk.x), math_floor(ctx.source_chunk.y)),
                                xy = pack_coordinates(path_request.start.x / CHUNK_SIZE, path_request.start.y / CHUNK_SIZE),
                                scalar = ctx.scalar,
                                limit = math_min(max_unit_group_size, 1 + (11 + selected_difficulty.value + selected_difficulty.value * selected_difficulty.radius_modifier * (1 + selected_difficulty.radius_modifier * math_random(1 + selected_difficulty.value)))),
                                path_id = path_id,
                                path_request = path_request,
                                --[[ TODO: make configurable ]]
                                attempts = 0,
                                --[[ TODO: make configurable ]]
                                retries = 0,
                                spider_unit = ctx.unit_type == SPIDER_UNIT or nil,
                                action_type = ctx.action_type
                            })
                            ctx.requesting_unit_group = unit_groups[path_id]

                            scout_path_registry = scout_path_registry or set_game() and scout_path_registry
                            scout_path_registry[path_id] = ctx
                        end
                    else
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_RECOVERY
                        planetary_surfaces[ctx.surface_name] = nil

                        requeue(ctx)
                    end
                else
                    --[[ Surface does not exist or is not valid ]]
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_RECOVERY
                    planetary_surfaces[ctx.surface_name] = nil

                    requeue(ctx)
                end
            elseif (ctx.state == STATE_PATH_FOUND) then

                if (ctx.raw_path_data and #ctx.raw_path_data > 0) then
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_PATH_PROCESSING
                    ctx.waypoint_idx = 1
                    ctx.total_waypoints = #ctx.raw_path_data

                    requeue(ctx)
                else
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_RECOVERY
                    requeue(ctx)
                end
            elseif (ctx.state == STATE_PATH_PROCESSING) then
                if (ctx.requesting_unit_group and ctx.raw_path_data and #ctx.raw_path_data > 0) then
                    local map_position = ctx.raw_path_data[#ctx.raw_path_data]
                    if (map_position and map_position.position) then
                        ctx.requesting_unit_group.target_position = map_position.position
                        ctx.raw_path_data = nil
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_DISPATCH
                    else
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_RECOVERY
                    end
                else
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_RECOVERY
                end

                requeue(ctx)
            elseif (ctx.state == STATE_DISPATCH) then
                planetary_surfaces = planetary_surfaces or set_game() and planetary_surfaces
                local surface = planetary_surfaces[ctx.surface_name]
                if (surface and surface.valid) then
                    unit_groups = unit_groups or set_game() and unit_groups
                    unit_groups.surface_count = unit_groups.surface_count or {}
                    unit_groups.surface_count[ctx.surface_name] = (unit_groups.surface_count[ctx.surface_name] or 0)
                    if (unit_groups.surface_count[ctx.surface_name] < max_unit_groups) then

                        local spawn_pos = ctx.requesting_unit_group and ctx.requesting_unit_group.start_position or ctx.raw_path_data[1]

                        if (spawn_pos) then
                            surface_funcs = surface_funcs or set_game() and surface_funcs
                            -- local group = surface_funcs[ctx.surface_name].create_unit_group({
                            --     position = spawn_pos,
                            --     force = ctx.force or ENEMY,
                            -- })
                            local group = ctx.next_reg_tbl and ctx.next_reg_tbl.group or nil
                            if (not group or not group.valid) then
                                group =  surface_funcs[ctx.surface_name].create_unit_group({
                                    position = spawn_pos,
                                    force = ctx.force or ENEMY,
                                })
                            end
                            -- local group =  surface_funcs[ctx.surface_name].create_unit_group({
                            --     position = spawn_pos,
                            --     force = ctx.force or ENEMY,
                            -- })

                            if (group and group.valid) then
                                unit_groups.count = (unit_groups.count or 0) + 1
                                unit_groups.surface_count[ctx.surface_name] = (unit_groups.surface_count[ctx.surface_name] or 0) + 1

                                local unique_id = group.unique_id
                                ctx.unique_id = unique_id
                                local reg_tbl = { created = tick, updated = tick, refreshed_tick = tick, group = group, unique_id = unique_id, starting_pos = group.position, surface_name = ctx.surface_name, force_name = group.force.name, }
                                reg_tbl.xy = pack_coordinates(reg_tbl.starting_pos.x, reg_tbl.starting_pos.y)
                                reg_tbl.registration_number, reg_tbl.useful_id, reg_tbl.reg_target_type = register_on_object_destroyed(group)

                                groups = groups or set_game() and groups
                                groups[unique_id] = reg_tbl

                                unit_groups = unit_groups or set_game() and unit_groups
                                unit_groups.count = (unit_groups.count or 0) + 1
                                unit_groups.surface_count[reg_tbl.surface_name] = (unit_groups.surface_count[reg_tbl.surface_name] or 0) + 1

                                on_object_destroyed = on_object_destroyed or set_game() and on_object_destroyed
                                on_object_destroyed[reg_tbl.surface_name] = on_object_destroyed[reg_tbl.surface_name] or new_Simple_Queue(Simple_Queue)
                                local on_surface_object_destroyed = on_object_destroyed[reg_tbl.surface_name]
                                local next_idx = on_surface_object_destroyed.last
                                on_surface_object_destroyed.last = next_idx + 1
                                on_surface_object_destroyed.q[next_idx] = reg_tbl
                                reg_tbl.i = next_idx
                                on_object_destroyed[reg_tbl.registration_number] = reg_tbl

                                ctx.next_reg_tbl = reg_tbl

                                local requesting_unit_group = ctx.requesting_unit_group
                                requesting_unit_group.unique_id = unique_id

                                unique_ids = unique_ids or set_game() and unique_ids
                                unique_ids[unique_id] = requesting_unit_group

                                requesting_unit_group.attempts = nil
                                requesting_unit_group.retries = nil
                                requesting_unit_group.path_id = nil
                                requesting_unit_group.path_request = nil

                                local enemies = get_enemy({
                                    surface_name = ctx.surface_name,
                                    xy = ctx.requesting_unit_group.xy,
                                    tick = tick,
                                    limit = 1 + ctx.requesting_unit_group.limit,
                                }) or {}
                                local num_enemies = #enemies

                                local unit_group_enemies = ctx.requesting_unit_group.enemies
                                local enemies_added = 0
                                local limit = ctx.requesting_unit_group.limit
                                local enemy = nil
                                if (group and group.valid) then
                                    local add_member = group.add_member
                                    -- local unique_id = group.unique_id

                                    local evolution_factor = group.force.get_evolution_factor(ctx.surface_name)
                                    ctx.evolution_factor = evolution_factor

                                    num_clones = num_clones or set_game() and num_clones
                                    limits = limits or set_game() and limits

                                    difficulties = difficulties or set_game() and difficulties
                                    difficulties[ctx.surface_name] = difficulties[ctx.surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[ctx.surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])
                                    local selected_difficulty = difficulties[ctx.surface_name]

                                    local darkness = planetary_surfaces[ctx.surface_name].darkness

                                    for i = 1, num_enemies, 1 do
                                        if (i >= limit or i >= max_unit_group_size) then break end
                                        enemy = enemies[i]
                                        if (enemy and enemy.valid) then
                                            add_member(enemy)
                                            enemies_added = enemies_added + 1
                                            local unit_number = enemy.unit_number
                                            local name = enemy.name
                                            unit_group_enemies[enemies_added] = unit_number

                                            -- if (num_clones[GROUP][ctx.surface_name][name] > (limits[GROUP] and limits[SPAWNED][ctx.surface_name] and (limits[GROUP][ctx.surface_name][name] or limits[GROUP][ctx.surface_name].fallback) or 400)) then return end

                                            local idx = unit_number % 60 + 1

                                            entities = entities or set_game() and entities
                                            entities[idx] = entities[idx] or new_Simple_Queue(Simple_Queue)
                                            local entity_queue = entities[idx]
                                            local next_idx = 1
                                            for _ = 1, ctx.scalar, 1 do
                                                next_idx = entity_queue.last or 1
                                                entity_queue.last = next_idx + 1
                                                entity_queue.q[next_idx] = {
                                                    source = GROUP,
                                                    unique_id = unique_id or nil,
                                                    tick = event.tick,
                                                    unit_number = unit_number,
                                                    surface_name = ctx.surface_name,
                                                    type = enemy.type or UNIT,
                                                    name = name,
                                                }
                                                -- if (num_clones[GROUP][ctx.surface_name][name] > (limits[GROUP] and limits[SPAWNED][ctx.surface_name] and (limits[GROUP][ctx.surface_name][name] or limits[GROUP][ctx.surface_name].fallback) or 400)) then break end
                                                if (math_max(0, num_clones[GROUP][ctx.surface_name][name] - ((evolution_factor + darkness) * selected_difficulty.value)) > (limits[GROUP] and limits[SPAWNED][ctx.surface_name] and (limits[GROUP][ctx.surface_name][name] or limits[GROUP][ctx.surface_name].fallback) or 400)) then break end
                                            end
                                        end
                                    end
                                end
                                ctx.requesting_unit_group.num_enemies = enemies_added

                                ctx.prev_state = ctx.state
                                ctx.state = STATE_FINALIZE
                                ctx.group = group
                            else
                                ctx.prev_state = ctx.state
                                ctx.state = STATE_RECOVERY
                            end
                        else
                            ctx.prev_state = ctx.state
                            ctx.state = STATE_RECOVERY
                        end
                    end
                else
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_RECOVERY
                end

                requeue(ctx)
            elseif (ctx.state == STATE_FINALIZE) then
                local group = ctx.group
                if (group and group.valid) then
                    local idx = ctx.unique_id % 60 + 1

                    pathables = pathables or set_game() and pathables
                    pathables[idx] = pathables[idx] or new_Simple_Queue(Simple_Queue)

                    local next_idx = pathables[idx].last or 1
                    pathables[idx].q[next_idx] = ctx.requesting_unit_group
                    pathables[idx].last = next_idx + 1

                    active_scouts = active_scouts or set_game() or active_scouts
                    active_scouts[ctx.surface_name] = active_scouts[ctx.surface_name] or new_Simple_Queue(Simple_Queue)
                    local local_active_scouts = active_scouts[ctx.surface_name]

                    local requesting_unit_group = ctx.requesting_unit_group

                    next_idx = local_active_scouts.last or 1
                    local_active_scouts.q[next_idx] = new_Scout_Group(Scout_Group_Data, {
                        start_position = requesting_unit_group.start_position,
                        last_position = group.position,
                        target_position = requesting_unit_group.target_position,
                        group = group,
                    })
                    local_active_scouts.last = next_idx + 1

                    ctx.group.release_from_spawner()
                    ctx.group.start_moving()
                end

                ctx.prev_state = ctx.state
                ctx.state = STATE_IDLE
                requeue(ctx)
            elseif (ctx.state == STATE_RECOVERY) then

                if (pathing_recovery_states[ctx.prev_state]) then
                    unit_groups = unit_groups or set_game()

                    unit_groups.count = math_max((unit_groups.count or 1) - 1, 0)
                    unit_groups.surface_count[ctx.surface_name] = math_max((unit_groups.surface_count[ctx.surface_name] or 1) - 1, 0)
                else
                end

                if (ctx.prev_state == STATE_PATHFINDING or ctx.path_id) then
                    --[[
                        if called: surface.request_path
                            -> returns `path_id` (guaranteed uint32)
                    ]]
                    scout_path_registry[ctx.path_id or 0 --[[the zero shouldn't be necessary, but oh well ]]] = nil
                end

                if (ctx.source_chunk and chunk_maps[ctx.surface_name]) then
                    local chunk = chunk_maps[ctx.surface_name][ctx.source_chunk.xy or ""]
                    if (chunk) then
                        if (ctx.prev_state == STATE_SCANTREE) then
                            chunk.timeout = tick + 3600
                        elseif (ctx.prev_state == STATE_PATHFINDING or ctx.prev_state == STATE_PATH_FOUND) then
                            chunk.no_path = (chunk.no_path or 0) + 1
                            chunk.timeout = tick + math_min(216000, 1200 * (2 ^ chunk.no_path))
                        elseif (ctx.prev_state == STATE_DISPATCH) then
                            chunk.try_again_later_tick = tick + 600
                        end

                    end
                end

                ctx.prev_state = ctx.state
                ctx.state = STATE_IDLE
                requeue(ctx)
            elseif (ctx.state == STATE_IDLE) then
                --[[ TODO: implement ]]
            else
                --[[ ¿What do (if anything)? ]]
            end
            ctx.updated = tick
        end

        ::continue::
    end
    if (scout_registry.last > 1 and scout_registry.first >= scout_registry.last) then
        scout_registry.first, scout_registry.last = 1, 1
        scout_registry.q = {}
    end
end
if (    selected_style
    and selected_style > NONE
) then
    Event_Handler:register_event({
        event_name = "on_nth_tick",
        nth_tick = NTH_TICK,
        source_name = "conductor_controller.on_nth_tick",
        func_name = "conductor_controller.on_nth_tick",
        func = conductor_controller.on_nth_tick,
    })
end

function conductor_controller.on_script_path_request_finished(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    scout_path_registry = scout_path_registry or set_game() and scout_path_registry
    if (not event.id or not scout_path_registry[event.id]) then return end
    local id = event.id
    local ctx = scout_path_registry[id]
    scout_path_registry[id] = nil
    local surface_name = ctx.surface_name

    local requesting_unit_group = ctx.requesting_unit_group

    if (event.try_again_later) then
        --[[ Pathfinder is too busy presently ]]
        requesting_unit_group.attempts = requesting_unit_group.attempts or 0
        requesting_unit_group.retries = requesting_unit_group.retries or 0
        if (requesting_unit_group.attempts > requesting_unit_group.retries) then
            local next_last = scout_registry.last
            scout_registry.last = next_last + 1
            scout_registry.q[next_last] = ctx

            ctx.idx = next_last
            ctx.updated = event.tick

            ctx.prev_state = ctx.state
            ctx.state = STATE_RECOVERY

            return
        end
        requesting_unit_group.attempts = requesting_unit_group.attempts + 1

        --[[ TODO: make configurable ]]
        ctx.path_request.radius = (ctx.path_request.radius or 12) * 1.25
        --[[ TODO: make configurable ]]
        ctx.path_request.path_resolution_modifier = (ctx.path_request.path_resolution_modifier or -1) / 0.8
        if (ctx.path_request.path_resolution_modifier < -8) then ctx.path_request.path_resolution_modifier = -8 end

        ctx.path_request.max_gap_distance = ctx.spider_unit and ctx.path_request.max_gap_distance / 0.8 or 0

        local surface = (planetary_surfaces or set_game() and planetary_surfaces) and planetary_surfaces[surface_name] or game and get_surface(surface_name) or set_game().get_surface(surface_name)
        if (not surface or not surface.valid) then
            local next_last = scout_registry.last
            scout_registry.last = next_last + 1
            scout_registry.q[next_last] = ctx

            ctx.idx = next_last
            ctx.updated = event.tick

            ctx.prev_state = ctx.state
            ctx.state = STATE_RECOVERY
            return
        end

        surface_funcs = surface_funcs or set_game() and surface_funcs
        surface_funcs[surface_name] = surface_funcs[surface_name] or {}
        surface_funcs[surface_name].request_path = surface_funcs[surface_name].request_path or surface.request_path

        local path_id = surface_funcs[ctx.surface_name].request_path(ctx.path_request)
        ctx.path_id = path_id

        scout_path_registry[path_id] = ctx
        return
    else
        chunk_maps = chunk_maps or set_game() and chunk_maps
        chunk_maps[surface_name] = chunk_maps[surface_name] or {}
        local chunk = chunk_maps[surface_name][requesting_unit_group.xy or -1]

        if (not event.path) then
            if (chunk) then
                chunk.no_path = (chunk.no_path or 0) + 1
                chunk.timeout = event.tick + math_min(216000, 2 ^ (chunk.no_path))
            end

            local next_last = scout_registry.last
            scout_registry.last = next_last + 1
            scout_registry.q[next_last] = ctx

            ctx.idx = next_last
            ctx.updated = event.tick

            ctx.prev_state = ctx.state
            ctx.state = STATE_RECOVERY
            return
        else
            if (chunk) then chunk.no_path = math_max(1, math_floor((chunk.no_path or 0) ^ 0.5)) end
        end
    end

    ctx.prev_state = ctx.state
    ctx.state = STATE_PATH_FOUND
    ctx.raw_path_data = event.path

    local next_last = scout_registry.last
    scout_registry.last = next_last + 1
    scout_registry.q[next_last] = ctx

    ctx.idx = next_last
    ctx.updated = event.tick
end
if (    selected_style
    and selected_style > NONE
) then
    Event_Handler:register_event({
        event_name = "on_script_path_request_finished",
        source_name = "conductor_controller.on_script_path_request_finished",
        func_name = "conductor_controller.on_script_path_request_finished",
        func = conductor_controller.on_script_path_request_finished,
    })
end

function conductor_controller.on_rocket_launch_ordered(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    if (not process_event(stats_data, event.name, event.tick)) then return end

    if (not event.rocket_silo or not event.rocket_silo.valid) then return end
    local silo = event.rocket_silo
    local surface = silo.surface
    local surface_name = surface.name
    local tick = event.tick
    local chunk = coordinates_to_leaf_node({
        surface_name = surface_name,
        x = math_floor(silo.position.x / CHUNK_SIZE),
        y = math_floor(silo.position.y / CHUNK_SIZE),
    })
    if (not chunk or not chunk.parent_node) then return end

    local parent_node = chunk.parent_node
    local c_meta = chunk.meta

    local raw_spawner_count = (c_meta.spawner_count or 0)
    local spawner_count = raw_spawner_count
    local spawner_density = 0
    local spawner_chunk_count = 0

    local raw_entity_count = (c_meta.entity_count or 0)
    local entity_count = raw_entity_count
    local entity_density = 0

    local raw_witnessed_count = (c_meta.witnessed_entity_count or 0)
    local witnessed_count = raw_witnessed_count
    local witnessed_count_density = 0

    local raw_pollution = (c_meta.pollution or 0)
    local pollution_count = raw_pollution
    local pollution_count_density = 0

    local qN, n = parent_node, 1
    local qN_meta = qN and qN.meta or nil
    local ambient_darkness = surface.darkness or 0

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])
    local selected_difficulty = difficulties[surface_name]
    selected_difficulty.sqrt_value = selected_difficulty.sqrt_value or math_sqrt(selected_difficulty.value)
    local depth_limit = math_floor(3.5 + (ambient_darkness * (1 + selected_difficulty.sqrt_value)))

    while qN and qN_meta and n < CHUNK_LEVELS and n <= depth_limit do
        local n_factor = (0.25 ^ n)

        spawner_count = spawner_count + (qN_meta.spawner_count or 0) * n_factor
        entity_count = entity_count + (qN_meta.entity_count or 0) * n_factor
        witnessed_count = witnessed_count + (qN_meta.witnessed_entity_count or 0) * n_factor
        pollution_count = pollution_count + (qN_meta.pollution or 0) * n_factor
        raw_spawner_count = (qN_meta.spawner_count or 0)
        raw_entity_count = (qN_meta.entity_count or 0)
        raw_witnessed_count = (qN_meta.witnessed_entity_count or 0)
        raw_pollution = (qN_meta.pollution or 0)

        if (qN.meta and (qN.meta.spawner_count or 0) > 0) then
            spawner_chunk_count = spawner_chunk_count + 1
        end

        local layer_size = SHIFT_LOOKUP[(qN.node_level or 0)]
        local margin = layer_size * 0.25

        local chunk_scaled_x = chunk.x / layer_size
        local chunk_scaled_y = chunk.y / layer_size

        local distance_from_center_x = chunk_scaled_x - qN.x
        local distance_from_center_y = chunk_scaled_y - qN.y

        local root_parent = qN.parent_node
        if (root_parent) then
            local is_north = qN.y < root_parent.y
            local is_west  = qN.x < root_parent.x

            local edge_threshold = 0.5 - (margin / layer_size)

            if (math_abs(distance_from_center_x) > edge_threshold) then
                if (distance_from_center_x > 0) then
                    local adjacent_cousin = is_north and root_parent.ne or root_parent.se
                    if (adjacent_cousin and adjacent_cousin.meta) then
                        local ac_meta = adjacent_cousin.meta

                        spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                        entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                        witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                        pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor

                        if ((ac_meta.spawner_count or 0) > 0) then spawner_chunk_count = spawner_chunk_count + 1 end
                    end
                else
                    local adjacent_cousin = is_north and root_parent.nw or root_parent.sw
                    if (adjacent_cousin and adjacent_cousin.meta) then
                        local ac_meta = adjacent_cousin.meta

                        spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                        entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                        witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                        pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor

                        if ((ac_meta.spawner_count or 0) > 0) then spawner_chunk_count = spawner_chunk_count + 1 end
                    end
                end
            end

            if (math_abs(distance_from_center_y) > edge_threshold) then
                if (distance_from_center_y > 0) then
                    local adjacent_cousin = is_west and root_parent.sw or root_parent.se
                    if (adjacent_cousin and adjacent_cousin.meta) then
                        local ac_meta = adjacent_cousin.meta

                        spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                        entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                        witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                        pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor

                        if ((ac_meta.spawner_count or 0) > 0) then spawner_chunk_count = spawner_chunk_count + 1 end
                    end
                else
                    local adjacent_cousin = is_west and root_parent.nw or root_parent.ne
                    if (adjacent_cousin and adjacent_cousin.meta) then
                        local ac_meta = adjacent_cousin.meta

                        spawner_count = spawner_count + (ac_meta.spawner_count or 0) * n_factor
                        entity_count = entity_count + (ac_meta.entity_count or 0) * n_factor
                        witnessed_count = witnessed_count + (ac_meta.witnessed_entity_count or 0) * n_factor
                        pollution_count = pollution_count + (ac_meta.pollution or 0) * n_factor

                        if ((ac_meta.spawner_count or 0) > 0) then spawner_chunk_count = spawner_chunk_count + 1 end
                    end
                end
            end
        end

        n = n + 1
        qN = qN.parent_node
        qN_meta = qN and qN.meta or nil
    end

    if (spawner_chunk_count < 1) then return end

    entity_density = entity_count / (raw_entity_count > 0  and raw_entity_count or 1)
    spawner_density = spawner_count / (raw_spawner_count > 0  and raw_spawner_count or UINT64)
    witnessed_count_density = witnessed_count / (raw_witnessed_count > 0  and raw_witnessed_count or UINT64)
    local raw_witnessed_density = raw_witnessed_count / (raw_entity_count > 0  and raw_entity_count or UINT64)
    pollution_count_density = pollution_count / (raw_pollution > 0  and raw_pollution or 1)

    local threat_pull = pollution_count_density * 2 + witnessed_count_density * 2 + raw_witnessed_density * 2 + ((0.15 + 0.85 * ambient_darkness) * (selected_difficulty.radius_modifier + selected_difficulty.sqrt_value))
    local hive_vitality = 2 - ((0.9 + selected_difficulty.value) ^ (0 - (spawner_density ^ 2)))

    local chunk_value = spawner_chunk_count * (entity_density * 1.5) * (threat_pull ^ hive_vitality)
    chunk.value = chunk_value
    chunk.value_tick = tick


    local SIGNIFICANCE_FLOOR = 0.02
    if (chunk_value < SIGNIFICANCE_FLOOR) then return end

    scout_registry = scout_registry or set_game() and scout_registry
    scout_registry.first, scout_registry.last = scout_registry.first or 1, scout_registry.last or 1

    local dispatches = 1 + selected_difficulty.sqrt_value + ((1 + selected_difficulty.value) * (ambient_darkness))

    local spawner_chunk_pool = find_closest_spawner({
        tick = tick,
        surface_name = surface_name,
        target_chunk = chunk,
        max_distance = UINT8 * CHUNK_SIZE,
        limit = selected_style > RANDOM and dispatches or math_random(1 + math_floor(dispatches)),
    })
    if (not spawner_chunk_pool or #spawner_chunk_pool < 1) then return end
    local count = #spawner_chunk_pool
    local rand = 1

    for i = 1, dispatches, 1 do
        if (count < 1) then count = #spawner_chunk_pool end
        if (count < 2) then
            rand = 1
        else
            rand = math_random(count)
        end

        local source_chunk = spawner_chunk_pool[rand]
        if (not source_chunk) then return end

        spawner_chunk_pool[rand] = spawner_chunk_pool[count]
        spawner_chunk_pool[count] = source_chunk
        count = count - 1

        local next_idx = scout_registry.last
        scout_registry.last = next_idx + 1

        scout_registry.q[next_idx] = {
            state = STATE_REQUESTING_PATH,
            prev_state = STATE_SCANTREE,
            surface_name = surface_name,
            source_chunk = source_chunk,
            target_chunk = chunk,
            action_type = ATTACK,
            scalar = selected_difficulty.radius_modifier,
            unit_type = surface_unit_types[surface_name] or UNIT,
            created = tick,
            updated = tick,
        }
    end
end
if (    selected_style
    and selected_style == OMNI_MIND
) then
    Event_Handler:register_event({
        event_name = "on_rocket_launch_ordered",
        source_name = "conductor_controller.on_rocket_launch_ordered",
        func_name = "conductor_controller.on_rocket_launch_ordered",
        func = conductor_controller.on_rocket_launch_ordered,
    })
end

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name] = function (event, params) max_unit_groups = params.setting_value end
update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name] = function (event, params) max_unit_group_size = params.setting_value end

for _, surface_name in ipairs(Planets or {}) do
    update_settings[Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"]] = function (event, params) attack_group_probability_modifiers[surface_name] = params.setting_value end
    local idx = surface_name:gsub("%-", "_"):upper()
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_ATTACK_GROUP_PEACE_TIME"] or Runtime_Global_Settings_Constants.settings["FALLBACK_ATTACK_GROUP_PEACE_TIME"]
    if (setting and setting.name) then
        update_settings[setting.name] = function (event, params) peace_time[surface_name] = params.setting_value * 60 end
    end
end

local ME_PREFIX = ME_PREFIX
local STRING = Types.STRING
function conductor_controller.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = conductor_controller.on_runtime_mod_setting_changed
})

function conductor_controller.init(__storage) storage = __storage or _ENV.storage end

return conductor_controller