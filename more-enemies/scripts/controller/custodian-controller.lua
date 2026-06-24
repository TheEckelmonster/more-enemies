local storage
local stats_data
local system_stats
local chunk_arr
local chunk_maps
local custodians
local custodian_registry
local difficulties
local entity_chunks
local entity_maps
local groups
local on_object_destroyed
local scout_registry
local spawner_chunks
local spawner_maps
local surfaces
local surface_creation
local unit_groups
local unique_ids

local game
local get_entity_by_unit_number
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

    storage.custodian_registry = storage.custodian_registry or new_Simple_Queue(Simple_Queue)
    custodian_registry = storage.custodian_registry

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.chunk_arr = storage.chunk_arr or {}
    chunk_arr = storage.chunk_arr

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.custodians = storage.custodians or {}
    custodians = storage.custodians

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.on_object_destroyed = storage.on_object_destroyed or new_Simple_Queue(Simple_Queue)
    on_object_destroyed = storage.on_object_destroyed

    storage.scout_registry = storage.scout_registry or new_Simple_Queue(Simple_Queue)
    scout_registry = storage.scout_registry

    storage.spawner_chunks = storage.spawner_chunks or {}
    spawner_chunks = storage.spawner_chunks

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    storage.surface_creation = storage.surface_creation or {}
    surface_creation = storage.surface_creation

    for _, planet in ipairs(Planets or {}) do
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
    get_entity_by_unit_number = game.get_entity_by_unit_number
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

    return game
end

local math_abs = math.abs
local math_exp = math.exp
local math_floor = math.floor
local math_log = math.log
local math_min = math.min
local math_max = math.max
local math_random = math.random
local math_sqrt = math.sqrt
local pairs = pairs
local table_insert = table.insert
local table_size = table_size

local E = math_exp(1)

local NTH_TICK = 40

local UINT64 = 2^64-1

local defines = defines
local command_build_base = defines.command.build_base

local defines = defines
local defines_command = defines.command
local valid_commands = {
    [defines_command.attack] = defines_command.attack,
    [defines_command.attack_area] = defines_command.attack_area,
    [defines_command.compound] = defines_command.compound,
    [defines_command.go_to_location] = defines_command.go_to_location,
    [defines_command.group] = defines_command.group,
    [defines_command.build_base] = command_build_base,
}
local defines_moving_state = defines.moving_state
local valid_moving_state = {
    [defines_moving_state.moving] = defines_moving_state.moving,
    [defines_moving_state.adaptive] = defines_moving_state.adaptive
}
local defines_behavior_result = defines.behavior_result
local valid_behavior_results = {
    [defines_behavior_result.in_progress] = defines_behavior_result.in_progress,
    [defines_behavior_result.success] = defines_behavior_result.success,
    [defines_behavior_result.deleted] = defines_behavior_result.deleted,
}
local no_op_behavior_results = {
    [defines_behavior_result.in_progress] = defines_behavior_result.in_progress,
    [defines_behavior_result.deleted] = defines_behavior_result.deleted,
}

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

local conductor_styles = {
    ["None"] = 0,
    ["Random"] = 1,
    ["Adaptive"] = 2,
    ["Omni-mind"] = 3,
}
local RANDOM = conductor_styles["Random"]
local conductor_style = Data_Utils.get_startup_setting({ setting = Startup_Settings_Constants.settings.CONDUCTOR_STYLE.name, })
local selected_style = conductor_styles[conductor_style]

local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack
local Quadtree_Service = require("scripts.service.quadtree-service")
local coordinates_to_leaf_node = Quadtree_Service.coordinates_to_leaf_node

local CONDUCTOR_STATES = require("scripts.constants.conductor-state-constants")
local CUSTODIAN_STATES = require("scripts.constants.custodian-state-constants")

local TICKS_PER_MINUTE = Constants.time.TICKS_PER_MINUTE
local MAX_AGE = 60 * TICKS_PER_MINUTE

local max_age = TICKS_PER_MINUTE * Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_AGE.name, })
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, }) or 30


local peace_time = {}
for _, surface_name in pairs(Planets) do
    local idx = surface_name:gsub("%-", "_"):upper()
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_ATTACK_GROUP_PEACE_TIME"]
    if (setting and setting.name) then
        peace_time[surface_name] = Data_Utils.get_runtime_global_setting({ setting = setting.name, }) * TICKS_PER_MINUTE
    end
end

local surface_unit_types = {
    [GLEBA] = SPIDER_UNIT,
    [FULGORA] = WATERLESS_UNIT,
    [CASTRA] = WATERLESS_UNIT,
}

local custodian_controller = {}
custodian_controller.name = "custodian_controller"
custodian_controller.set_game = set_game

local CONDUCTOR_STATE_SCANTREE = CONDUCTOR_STATES.SCANTREE

local STATE_RECOVERY = CUSTODIAN_STATES.RECOVERY
local STATE_EVALUATION = CUSTODIAN_STATES.EVALUATION
local STATE_PROCESSING = CUSTODIAN_STATES.PROCESSING
local STATE_REMOVING = CUSTODIAN_STATES.REMOVING
local STATE_FINALIZE = CUSTODIAN_STATES.FINALIZE
local STATE_COMMAND_COMPLETED = CUSTODIAN_STATES.COMMAND_COMPLETED

local SIGN_OF_THE_BEAST = 666
local SIX_OF_THE_BEAST = 6*666
local BASE_DELAY = 60*SIGN_OF_THE_BEAST

local BOTTOM_UP = "bottom-up"
local TOP_DOWN = "top-down"

local ENEMY = ENEMY

local CHUNK_LEVELS = Constants.CHUNK_LEVELS
local CHUNK_SIZE = Constants.CHUNK_SIZE
local SHIFT_LOOKUP = SHIFT_LOOKUP

local COMMAND_BUILD_BASE_PARAMS = {
    type = command_build_base,
    destination = nil,
    ignore_planner = true,
}
local DESTROY_PARAMS = { raise_destroy = true, }

local function regionally_significant(reg_tbl, ctx, tick)
    if (not reg_tbl) then return end
    if (not reg_tbl.starting_pos or not reg_tbl.starting_pos.x or not reg_tbl.starting_pos.y) then return end
    if (not ctx) then return end

    if (not Valid_Surfaces[reg_tbl.surface_name]) then return end
    local surface_name = reg_tbl.surface_name

    tick = tick or (game or set_game()).tick

    chunk_maps = chunk_maps or set_game() and chunk_maps
    chunk_maps[surface_name] = chunk_maps[surface_name] or {}
    local chunk_map = chunk_maps[surface_name]

    local xy = reg_tbl.xy or pack_coordinates(reg_tbl.starting_pos.x / 32, reg_tbl.starting_pos.y / 32)
    local chunk = chunk_map[xy]
    if (not chunk) then
        chunk = coordinates_to_leaf_node({
            surface_name = reg_tbl.surface_name,
            x = math_floor(reg_tbl.starting_pos.x / 32),
            y = math_floor(reg_tbl.starting_pos.y / 32),
            xy = xy,
        })
    end
    if (not chunk or not chunk.parent_node) then return end

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

    reg_tbl.current_chunk = chunk
    reg_tbl.current_chunk_tick = tick

    return reg_tbl, chunk_value
end

function custodian_controller.on_nth_tick(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    local tick = event.tick or 0
    local inverse_stress = 1 - (stats_data.meta.last_load or 0)
    local max_steps_allowed_this_tick = 1 + math_floor(4 * inverse_stress)

    local awake_surfaces = nil

    on_object_destroyed = on_object_destroyed or set_game() and on_object_destroyed

    groups = groups or set_game() and groups

    custodian_registry = custodian_registry or set_game() and custodian_registry
    on_object_destroyed = on_object_destroyed or set_game() and on_object_destroyed

    --[[ Phase 1 ]]
    for _, surface_name in ipairs(planets[(math_floor(tick / NTH_TICK) % modulo)] or {}) do
        planetary_surfaces = planetary_surfaces or set_game() and planetary_surfaces
        if (not planetary_surfaces[surface_name] or not planetary_surfaces[surface_name].valid) then goto continue end

        if (surface_creation and not surface_creation[surface_name]) then
            if (get_surface(surface_name).index == 1) then
                surface_creation[surface_name] = 0
            else
                surface_creation[surface_name] = event.tick
            end
        end

        on_object_destroyed[surface_name] = on_object_destroyed[surface_name] or new_Simple_Queue(Simple_Queue)
        local on_surface_object_destroyed = on_object_destroyed[surface_name]

        if (((on_surface_object_destroyed.last or 1) - (on_surface_object_destroyed.first or 1)) > 0) then
            awake_surfaces = awake_surfaces or {}
            awake_surfaces[#awake_surfaces+1] = surface_name

            local custodian_registry_count = (custodian_registry.last or 1) - (custodian_registry.first or 1)

            if (custodian_registry_count >= 0 and custodian_registry_count < concurrent_actions) then
                local next_idx = custodian_registry.last
                custodian_registry.last = next_idx + 1
                custodian_registry.q[next_idx] = {
                    state = STATE_EVALUATION,
                    surface_name = surface_name,
                    on_surface_object_destroyed = on_surface_object_destroyed,
                    idx = next_idx,
                    created = tick,
                    updated = tick,
                }
            end
        end

        ::continue::
    end

    --[[ Wake-up?! ]]
    -- log(serpent.block(awake_surfaces and #awake_surfaces or "asleep"))
    if (not awake_surfaces or #awake_surfaces < 1) then return end

    --[[ Phase 2 ]]
    custodian_registry.first = custodian_registry.first or 1
    custodian_registry.last = custodian_registry.last or 1

    local total_active_requests = custodian_registry.last - custodian_registry.first
    local nominal_steps_executed = 0
    local entries_witnessed = 0

    local function requeue(ctx)
        local next_last = custodian_registry.last
        custodian_registry.last = next_last + 1
        custodian_registry.q[next_last] = ctx
        ctx.idx = next_last
        ctx.updated = tick
    end

    while (entries_witnessed < total_active_requests) and nominal_steps_executed < max_steps_allowed_this_tick do
        entries_witnessed = entries_witnessed + 1
        local curr_idx = custodian_registry.first
        local ctx = custodian_registry.q[curr_idx]
        custodian_registry.q[curr_idx] = nil
        custodian_registry.first = curr_idx + 1

        if (ctx) then
            -- log(serpent.block(tostring(ctx)))
            -- log(serpent.block(ctx.prev_state))
            -- log(serpent.block(ctx.state))
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

            if (ctx.state == STATE_EVALUATION) then
                ctx.evaluation_attempts = ctx.evaluation_attempts or 0

                local on_surface_object_destroyed = ctx.on_surface_object_destroyed

                if (on_surface_object_destroyed.last > 1) then
                    local attempts = 0
                    local candidate = nil
                    local remove, remobilize = nil, nil

                    local count = on_surface_object_destroyed.last - on_surface_object_destroyed.first

                    force_funcs = force_funcs or set_game() and force_funcs
                    if (not force_funcs[ENEMY]) then
                        ctx.evolution_factor = 0.666
                    else
                        ctx.evolution_factor = ctx.evolution_factor or force_funcs[ENEMY].get_evolution_factor(ctx.surface_name)
                    end

                    while (count >= 1) and (attempts < 4) do
                        attempts = attempts + 1

                        -- Dequeue the first element
                        local next_idx = on_surface_object_destroyed.first
                        candidate = on_surface_object_destroyed.q[next_idx]
                        on_surface_object_destroyed.q[next_idx] = nil
                        on_surface_object_destroyed.first = next_idx + 1

                        -- Requeue the element to the back of the queue
                        if (candidate and candidate.group and candidate.group.valid) then
                            local next_last = on_surface_object_destroyed.last
                            on_surface_object_destroyed.last = next_last + 1
                            on_surface_object_destroyed.q[next_last] = ctx
                            candidate.idx = next_last
                            candidate.updated = tick
                        end

                        ctx.batch_limit = ctx.batch_limit or 3

                        local group = candidate and candidate.group or nil
                        if (group and group.valid) then
                            if (not stats_data.group_allowed_age) then
                                unit_groups = unit_groups or set_game() and unit_groups

                                unit_groups.count = unit_groups.count or 0
                                unit_groups.surface_count = unit_groups.surface_count or {}
                                unit_groups.surface_count[candidate.surface_name] = unit_groups.surface_count[candidate.surface_name] or 0
                                stats_data.surface_group_stress[candidate.surface_name] = (unit_groups.surface_count[candidate.surface_name] + 0) / (max_unit_groups + 1)

                                stats_data.current.group_stress = (unit_groups.count + 0) / (num_planets * max_unit_groups + 1)

                                stats_data.group_allowed_age = (max_age or MAX_AGE) * (1.0 - (0.75 * (math_max(stats_data.current.group_stress, stats_data.surface_group_stress[candidate.surface_name]))))
                            end
                            if (   not valid_moving_state[group.moving_state]
                                or not valid_commands[group.state]
                                or ((candidate.refreshed_tick or candidate.created or 0) < (tick - (stats_data.group_allowed_age)))
                            ) then
                                if ((candidate.refreshed_tick or candidate.created or 0) < (tick - (stats_data.group_allowed_age))) then
                                    remove = remove or {}
                                    remove[#remove+1] = candidate
                                elseif (regionally_significant(candidate, ctx)) then
                                    remobilize = remobilize or {}
                                    remobilize[#remobilize+1] = candidate
                                else
                                    remove = remove or {}
                                    remove[#remove+1] = candidate
                                end
                            end
                        else
                            remove = remove or {}
                            remove[#remove+1] = candidate
                        end
                    end

                    if (not remove and not remobilize) then
                        ctx.evaluation_attempts = ctx.evaluation_attempts + 1

                        if (ctx.evaluation_attempts > 1 + 2 * inverse_stress) then
                            ctx.prev_state = ctx.state
                            ctx.state = STATE_RECOVERY
                        end
                    else
                        ctx.remove = remove
                        ctx.remobilize = remobilize
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_PROCESSING
                    end
                else
                    ctx.evaluation_attempts = ctx.evaluation_attempts + 1

                    if (ctx.evaluation_attempts > 1 + 2 * inverse_stress) then
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_RECOVERY
                    end
                end

                if (ctx.state ~= STATE_RECOVERY) then requeue(ctx) end
            elseif (ctx.state == STATE_PROCESSING) then
                ctx.prev_state = ctx.state

                local remove_pool = ctx.remove
                local remobilize_pool = ctx.remobilize
                ctx.staged = nil

                if ((not remove_pool or #remove_pool == 0) and (not remobilize_pool or #remobilize_pool == 0)) then
                    ctx.remove, ctx.remobilize = nil, nil
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_FINALIZE
                else
                    local iterations = 0
                    local num_added = 0
                    ctx.removed = ctx.removed or 0
                    while num_added < 3 and iterations < 4 do
                        iterations = iterations + 1
                        if (remove_pool and #remove_pool > 0) then
                            local pool_idx = #remove_pool
                            ctx.staged = ctx.staged or {}
                            ctx.staged[#ctx.staged+1] = remove_pool[pool_idx]
                            remove_pool[pool_idx] = nil
                            ctx.removed = ctx.removed + 1
                            num_added = num_added + 1
                        end
                        if (remobilize_pool and #remobilize_pool > 0) then
                            local pool_idx = #remobilize_pool
                            local next_reg_tbl = remobilize_pool[pool_idx]
                            remobilize_pool[pool_idx] = nil

                            scout_registry = scout_registry or set_game() and scout_registry

                            -- local source_chunk = coordinates_to_leaf_node({ xy = next_reg_tbl.xy, })

                            -- if (not source_chunk and next_reg_tbl.group and next_reg_tbl.group.valid) then
                            local source_chunk = nil
                            if (next_reg_tbl.group and next_reg_tbl.group.valid) then
                                local position = next_reg_tbl.group.position
                                source_chunk = {
                                    x = math_floor(position.x / 32),
                                    y = math_floor(position.y / 32),
                                    xy = pack_coordinates(position.x / CHUNK_SIZE, position.y / CHUNK_SIZE),
                                }

                                next_reg_tbl.mobilized_count = (next_reg_tbl.mobilized_count or 0) + 1
                            -- end
                            -- if (source_chunk) then
                                -- log(serpent.block("remobilizing unit-group"))
                                -- log(serpent.block({ "messages.entity-gps", "", (source_chunk.x + 0.5) * CHUNK_SIZE, (source_chunk.y + 0.5) * CHUNK_SIZE, next_reg_tbl.surface_name, }))
                                game.print("remobilizing unit-group")
                                game.print({ "messages.entity-gps", "", (source_chunk.x + 0.5) * CHUNK_SIZE, (source_chunk.y + 0.5) * CHUNK_SIZE, next_reg_tbl.surface_name, })

                                local rand = math_random()
                                local darkness_modifier = 0.42
                                local daytime_modifier = 0.42
                                local surface = planetary_surfaces[next_reg_tbl.surface_name]
                                if (surface and surface.valid) then
                                    darkness_modifier = surface.darkness
                                    daytime_modifier = 4 * ((surface.daytime - 0.5) ^ 2)
                                end

                                if (rand < ((0.5 + darkness_modifier + daytime_modifier + 0.2 * (1 - (1 / next_reg_tbl.mobilized_count))) / 2)) then
                                    local group = next_reg_tbl.group
                                    if (group and group.valid) then
                                        next_reg_tbl.base_xy_prev = next_reg_tbl.base_xy
                                        next_reg_tbl.base_xy = pack_coordinates(source_chunk.x, source_chunk.y)

                                        if (next_reg_tbl.base_xy_prev and next_reg_tbl.base_xy_prev == next_reg_tbl.base_xy and (tick - next_reg_tbl.build_base_tick) > SIGN_OF_THE_BEAST or (next_reg_tbl.build_base_command_count or 0) > 2) then
                                            local remove_pool = ctx.remove or {}
                                            ctx.remove = remove_pool
                                            local pool_idx = #remove_pool
                                            ctx.staged = ctx.staged or {}
                                            ctx.staged[#ctx.staged+1] = remove_pool[pool_idx]
                                            remove_pool[pool_idx] = nil
                                            ctx.removed = ctx.removed + 1
                                            num_added = num_added + 1
                                        else
                                            difficulties = difficulties or set_game() and difficulties
                                            local selected_difficulty = difficulties[next_reg_tbl.surface_name]

                                            -- group.set_command({
                                            --     type = command_build_base,
                                            --     destination = source_chunk,
                                            --     ignore_planner = true,
                                            -- })
                                            COMMAND_BUILD_BASE_PARAMS.destination = source_chunk
                                            group.set_command(COMMAND_BUILD_BASE_PARAMS)
                                            if (group.valid) then
                                                surface_funcs[ctx.surface_name].build_enemy_base(source_chunk, selected_difficulty.value + #group.commandable_members, next_reg_tbl.force_name or group.force)
                                            end

                                            next_reg_tbl.build_base_command_count = (next_reg_tbl.build_base_command_count or 0) + 1
                                            next_reg_tbl.build_base_tick = next_reg_tbl.build_base_tick or tick
                                        end
                                    end
                                else
                                    local next_idx = scout_registry.last
                                    scout_registry.last = next_idx + 1
                                    scout_registry.q[next_idx] = {
                                        state = CONDUCTOR_STATE_SCANTREE,
                                        surface_name = next_reg_tbl.surface_name,
                                        source_chunk = source_chunk,
                                        idx = next_idx,
                                        strictness = inverse_stress,
                                        unit_type = surface_unit_types[next_reg_tbl.surface_name] or UNIT,
                                        created = tick,
                                        updated = tick,
                                        next_reg_tbl = next_reg_tbl,
                                        search_checkpoint = {
                                            search_type = BOTTOM_UP,
                                            current_node = nil,
                                            best_leaf = nil,
                                            best_score = -1,
                                            iterations = 1,
                                            state = CONDUCTOR_STATE_SCANTREE,
                                            force_name = next_reg_tbl.force_name or ENEMY,
                                        },
                                    }
                                end
                                next_reg_tbl.updated = tick

                                num_added = num_added + 1
                            end

                        end
                    end

                    if ((not remove_pool or #remove_pool < 1) and (not remobilize_pool or #remobilize_pool < 1)) then
                        if ((ctx.removed or 0) > 0) then
                            ctx.state = STATE_REMOVING
                        else
                            ctx.state = STATE_FINALIZE
                        end
                    end
                end

                if (ctx.state ~= STATE_FINALIZE) then
                    requeue(ctx)
                end
            elseif (ctx.state == STATE_REMOVING) then
                ctx.prev_state = ctx.state

                ctx.staged_idx = ctx.staged_idx or ctx.staged and #ctx.staged or 0
                if (not ctx.staged or ctx.staged_idx == 0) then
                    ctx.staged = nil
                    ctx.staged_idx = nil
                    ctx.state = STATE_FINALIZE
                else
                    local staged_tbl = ctx.staged[ctx.staged_idx]
                    local staged_group = staged_tbl and staged_tbl.group or nil
                    ctx.staged[ctx.staged_idx] = nil

                    if (staged_group and staged_group.valid) then
                        local rand = math_random()

                        difficulties = difficulties or set_game() and difficulties
                        difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])
                        local selected_difficulty = difficulties[surface_name]

                        selected_difficulty.inverse_value = selected_difficulty.inverse_value or (1 / selected_difficulty.value)

                        if (rand < (0.05 + 0.95 * (((ctx.evolution_factor or 0.666) + (1 - selected_difficulty.inverse_value)) / 2))) then
                            surface_funcs = surface_funcs or set_game() and surface_funcs
                            if (not surface_funcs[ctx.surface_name]) then
                                local member_unit = nil
                                local commandable_members = staged_group.commandable_members
                                for i = 1, #commandable_members, 1 do
                                    member_unit = commandable_members[i]
                                    if (member_unit and member_unit.valid and member_unit.is_entity) then
                                        member_unit.entity.destroy(DESTROY_PARAMS)
                                    end
                                end
                                staged_group.destroy()
                            else
                                local position = staged_group.position
                                staged_tbl.base_xy_prev = staged_tbl.base_xy
                                staged_tbl.base_xy = pack_coordinates(position.x / CHUNK_SIZE, position.y / CHUNK_SIZE)
                                staged_tbl.build_base_tick = staged_tbl.build_base_tick or tick

                                if (staged_tbl.base_xy_prev and staged_tbl.base_xy_prev == staged_tbl.base_xy and (tick - staged_tbl.build_base_tick) > SIGN_OF_THE_BEAST or (staged_tbl.build_base_command_count or 0) > 2) then
                                    local member_unit = nil
                                    local commandable_members = staged_group.commandable_members
                                    for i = 1, #commandable_members, 1 do
                                        member_unit = commandable_members[i]
                                        if (member_unit and member_unit.valid and member_unit.is_entity) then
                                            member_unit.entity.destroy(DESTROY_PARAMS)
                                        end
                                    end
                                    staged_group.destroy()
                                else
                                    staged_group.set_command({
                                        type = command_build_base,
                                        destination = position,
                                        ignore_planner = true,
                                    })
                                    surface_funcs[staged_tbl.surface_name].build_enemy_base(position, selected_difficulty.value + #staged_group.commandable_members, staged_tbl.force_name or staged_group.force)

                                    staged_tbl.build_base_command_count = (staged_tbl.build_base_command_count or 0) + 1
                                    staged_tbl.build_base_tick = staged_tbl.build_base_tick or tick
                                end
                            end
                        else
                            local member_unit = nil
                            local commandable_members = staged_group.commandable_members
                            for i = 1, #commandable_members, 1 do
                                member_unit = commandable_members[i]
                                if (member_unit and member_unit.valid and member_unit.is_entity) then
                                    member_unit.entity.destroy(DESTROY_PARAMS)
                                end
                            end
                            staged_group.destroy()
                        end
                    end
                    ctx.staged_idx = ctx.staged_idx - 1

                    if (ctx.staged_idx <= 0) then
                        ctx.staged = nil
                        ctx.staged_idx = nil
                        ctx.state = STATE_FINALIZE
                    else
                        requeue(ctx)
                    end
                end
            elseif (ctx.state == STATE_FINALIZE) then
                --[[ ¿What do (if anything)? ]]
            elseif (ctx.state == STATE_RECOVERY) then
                --[[ ¿What do (if anything)? ]]
            else
                --[[ ¿What do (if anything)? ]]
            end
            ctx.updated = tick
        end

        ::continue::
    end
    if (custodian_registry.last > 1 and custodian_registry.first >= custodian_registry.last) then
        custodian_registry.first, custodian_registry.last = 1, 1
        custodian_registry.q = {}
    end
end
if (    selected_style
    and selected_style > 0
) then
    Event_Handler:register_event({
        event_name = "on_nth_tick",
        nth_tick = NTH_TICK,
        source_name = "custodian_controller.on_nth_tick",
        func_name = "custodian_controller.on_nth_tick",
        func = custodian_controller.on_nth_tick,
    })
end

function custodian_controller.on_ai_command_completed(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    if (not process_event(stats_data, event.name, event.tick)) then return end

    if (not event.result) then return end
    local result = event.result
    if (not valid_behavior_results[result] or no_op_behavior_results[result]) then return end

    if (not event.unit_number) then return end
    local unit_number = event.unit_number

    groups = groups or set_game() and groups
    local reg_tbl = groups[unit_number]
    local group = reg_tbl and reg_tbl.group or nil
    if (not group or not group.valid) then
        unit_groups = unit_groups or set_game() and unit_groups
        if (unit_groups.unit_nums and unit_groups.unit_nums[unit_number]) then
            local entity = (game or set_game()) and get_entity_by_unit_number(unit_number)
            if (not entity or not entity.valid) then return end
            local commandable = entity.commandable
            if (not commandable or not commandable.valid) then return end
            group = commandable.is_unit_group or commandable.parent_group
        end
    end
    if (not group or not group.valid) then return end

    if (   not valid_moving_state[group.moving_state]
        or not valid_commands[group.state]
        or ((reg_tbl.refreshed_tick or reg_tbl.created or 0) < (event.tick - stats_data.group_allowed_age))
    ) then
        local tick = event.tick
        local remobilize = nil
        local remove = nil
        local surface_name = reg_tbl and reg_tbl.surface_name or group.surface.name
        local ctx = { created = tick, batch_limit = 3, evolution_factor = group.force.get_evolution_factor(surface_name), }
        if ((reg_tbl.refreshed_tick or reg_tbl.created or 0) < (tick - stats_data.group_allowed_age)) then
            remove = remove or {}
            remove[#remove+1] = reg_tbl
        elseif (regionally_significant(reg_tbl, ctx)) then
            remobilize = remobilize or {}
            remobilize[#remobilize+1] = reg_tbl
        else
            remove = remove or {}
            remove[#remove+1] = reg_tbl
        end
        -- if (regionally_significant(reg_tbl, ctx)) then
        --     remobilize = remobilize or {}
        --     remobilize[#remobilize+1] = reg_tbl
        -- else
        --     remove = remove or {}
        --     remove[#remove+1] = reg_tbl
        -- end

        if (remobilize and #remobilize > 0 or remove and #remove > 0) then
            ctx.remove = remove
            ctx.remobilize = remobilize
            ctx.prev_state = STATE_COMMAND_COMPLETED
            ctx.state = STATE_PROCESSING

            custodian_registry = custodian_registry or set_game() and custodian_registry
            custodian_registry.first, custodian_registry.last = custodian_registry.first or 1, custodian_registry.last or 1

            local next_last = custodian_registry.last
            custodian_registry.last = next_last + 1
            custodian_registry.q[next_last] = ctx
            ctx.idx = next_last
            ctx.updated = tick
        end
    end
end
if (    selected_style
    and selected_style > 0
) then
    Event_Handler:register_event({
        event_name = "on_ai_command_completed",
        source_name = "custodian_controller.on_ai_command_completed",
        func_name = "custodian_controller.on_ai_command_completed",
        func = custodian_controller.on_ai_command_completed,
    })
end

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_AGE.name] = function (event, params) max_age = TICKS_PER_MINUTE * params.setting_value end
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
function custodian_controller.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = custodian_controller.on_runtime_mod_setting_changed
})

function custodian_controller.init(__storage) storage = __storage or _ENV.storage end

return custodian_controller