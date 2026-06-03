local storage
local stats_data
local chunks_arrs
local chunk_maps
local conductors
local difficulties
local entity_chunks
local entity_maps
local groups
local on_object_destroyed
local pathables
local post_entity_died_buckets
local scout_path_registry
local scout_registry
local spawner_maps
local surfaces
local unit_groups
local unique_ids

local game
local get_surface
local forces
local force_funcs
local planetary_surfaces
local surface_funcs

local Surfaces = Surfaces

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

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.chunks_arrs = storage.chunks_arrs or {}
    chunks_arrs = storage.chunks_arrs

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.conductors = storage.conductors or {}
    conductors = storage.conductors

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.on_object_destroyed = storage.on_object_destroyed or {}
    on_object_destroyed = storage.on_object_destroyed

    storage.pathables = storage.pathables or {}
    pathables = storage.pathables

    storage.post_entity_died_buckets = storage.post_entity_died_buckets or {}
    post_entity_died_buckets = storage.post_entity_died_buckets

    storage.scout_path_registry = storage.scout_path_registry or {}
    scout_path_registry = storage.scout_path_registry

    storage.scout_registry = storage.scout_registry or new_Simple_Queue(Simple_Queue)
    scout_registry = storage.scout_registry

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    for _, planet in ipairs(Planets or {}) do
        post_entity_died_buckets[planet] = post_entity_died_buckets[planet] or {}

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

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    storage.unique_ids = storage.unique_ids or {}
    unique_ids = storage.unique_ids

    game = __game or _ENV.game
    get_surface = game.get_surface

    _ENV.Forces = _ENV.Forces or {}
    Forces = _ENV.Forces
    Forces.list = Forces.list or {}

    _ENV.Force_Funcs = _ENV.Force_Funcs or {}
    Force_Funcs = _ENV.Force_Funcs
    for name, force in pairs(game.forces) do
        if (force.valid) then
            Forces[name] = force
            Forces.list[force.index] = name
            Force_Funcs[name] = Force_Funcs[name] or {}
            Force_Funcs[name].get_evolution_factor = force.get_evolution_factor
        else
            Forces[name] = nil
        end
    end
    forces = Forces
    force_funcs = Force_Funcs

    _ENV.Surface_Funcs = _ENV.Surface_Funcs or {}
    Surface_Funcs = _ENV.Surface_Funcs

    _ENV.Surfaces = _ENV.Surfaces or {}
    Surfaces = _ENV.Surfaces
    Surfaces.list = Surfaces.list or {}
    for name, surface in pairs(game.surfaces) do
        if (surface.valid and not string_find(surface.name, "platform%-[%d]*")) then
            Surfaces[name] = surface
            Surfaces.list[surface.index] = name

            Surface_Funcs[name] = Surface_Funcs[name] or {}
            Surface_Funcs[name].create_unit_group = Surface_Funcs[name].create_unit_group or surface.create_unit_group
            Surface_Funcs[name].count_entities_filtered = Surface_Funcs[name].count_entities_filtered or surface.count_entities_filtered
            Surface_Funcs[name].get_pollution = Surface_Funcs[name].get_pollution or surface.get_pollution
            Surface_Funcs[name].find_entities_filtered = Surface_Funcs[name].find_entities_filtered or surface.find_entities_filtered
            Surface_Funcs[name].find_non_colliding_position = Surface_Funcs[name].find_non_colliding_position or surface.find_non_colliding_position
            Surface_Funcs[name].request_path = Surface_Funcs[name].request_path or surface.request_path
        else
            Surfaces[name], Surface_Funcs[name] = nil, nil
        end
    end
    planetary_surfaces = Surfaces
    surface_funcs = Surface_Funcs

    return game
end

local math_exp = math.exp
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_random = math.random
local math_sqrt = math.sqrt
local pairs = pairs
local table_insert = table.insert
local table_size = table_size

local CHUNK_SIZE = Constants.CHUNK_SIZE
local CHUNK_LEVELS = Constants.CHUNK_LEVELS
local NTH_TICK = 60
local MODULO = NTH_TICK * 60

local defines = defines
local defines_command = defines.command
local command_attack_area = defines_command.attack_area
local command_compound = defines_command.compound
local compound_command_return_last = defines.compound_command.return_last
local command_go_to_location = defines_command.go_to_location

local defines_distraction = defines.distraction
local distraction_by_enemy = defines_distraction.by_enemy

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
local modulo = NTH_TICK
for _, planet in pairs(Planets) do
    local idx = i % modulo + 1
    planets[idx] = planets[idx] or {}
    table_insert(planets[idx], planet)
    i = i + 1
end

local conductor_styles = {
    ["None"] = 0,
    ["Random"] = 1,
    ["Adaptive"] = 2,
    ["Omni-mind"] = 3,
}
local selected_style = Data_Utils.get_startup_setting({ setting = Startup_Settings_Constants.settings.CONDUCTOR_STYLE.name, })

local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
local get_enemy = Attack_Group_Utils.get_enemy
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template
local Quadtree_Service = require("scripts.service.quadtree-service")
local propagate_node_metrics_iteratively = Quadtree_Service.propagate_node_metrics_iteratively
local find_closest_iteratively = Quadtree_Service.find_closest_iteratively
local Requesting_Unit_Group = require("scripts.data.requesting-unit-group")
local new_Requesting_Unit_Group = Requesting_Unit_Group.new

local STATES = require("scripts.constants.conductor-state-constants")

local BOUNDING_BOXES = {
    [UNIT] = {{-0.25, -0.25}, {0.25, 0.25},},
    [SPIDER_UNIT] = {{-0.05, -0.05}, {0.05, 0.05}},
}

local COLLISION_MASKS = {
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

local PATHFINDER_FLAGS = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, cache = true, }
local PATHFINDER_FLAGS_LOW_PRIORITY = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, cache = true, low_priority = true }

local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, }) or 30

local conductor_controller = {}
conductor_controller.name = "conductor_controller"
conductor_controller.set_game = set_game

local DEFAULT_EMPTY_METRIC = { w = 0, fx = 0, p = 1, }

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
local BASE_DELAY = 60*SIGN_OF_THE_BEAST

local function request_scouting_party(surface_name, tick)
    if (not surface_name or not tick) then return end

    conductors = conductors or set_game()
    conductors[surface_name] = conductors[surface_name] or {}
    local  conductor = conductors[surface_name]

    if ((conductor.next_scoutng_tick or 0) >= tick) then return end

    force_funcs = force_funcs or set_game() and force_funcs

    local z = force_funcs[ENEMY] and force_funcs[ENEMY].get_evolution_factor(surface_name) or 0.0

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])
    local x = difficulties[surface_name].value or 1
    local inverse_evolution = 1 - z

    local left_horizon = (BASE_DELAY / (math_sqrt(x))) * (0.3 + 0.7 * inverse_evolution)
    local right_horizon = inverse_evolution * (BASE_DELAY / x)

    local final_cooldown_ticks = math_floor(left_horizon + right_horizon)

    if (math_random() > 0.5) then
        conductor.next_scoutng_tick = tick + final_cooldown_ticks
        return true
    else
        conductor.next_scoutng_tick = tick + SIGN_OF_THE_BEAST
        return
    end
end

local pathing_recovery_states = {
    [STATE_PATHFINDING] = STATE_PATHFINDING,
    [STATE_PATH_FOUND] = STATE_PATH_FOUND,
    [STATE_PATH_PROCESSING] = STATE_PATH_PROCESSING,
    [STATE_DISPATCH] = STATE_DISPATCH,
}

local ENEMY = ENEMY
local GLEBA = GLEBA
local SPIDER_UNIT, UNIT = SPIDER_UNIT, UNIT
function conductor_controller.on_nth_tick(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    local tick = event.tick or 0
    local inverse_stress = 1 - (stats_data.meta.last_load or 0)
    local max_steps_allowed_this_tick = 1 + math_floor(4 * inverse_stress)

    scout_registry = scout_registry or set_game() and scout_registry

    post_entity_died_buckets = post_entity_died_buckets or set_game() and post_entity_died_buckets
    local parents_to_propogate = nil
    local propgate_count = 0

    --[[ Phase 1 ]]
    -- for _, surface_name in ipairs(planets[(tick / NTH_TICK ) % NTH_TICK + 1] or {}) do
    for _, surface_name in ipairs(planets[(tick / NTH_TICK ) % NTH_TICK] or {}) do

        post_entity_died_buckets[surface_name] = post_entity_died_buckets[surface_name] or {}
        local buckets = post_entity_died_buckets[surface_name]
        for xy, bucket in pairs(buckets) do
            local chunk = bucket.chunk
            if (chunk.parent_node) then
                local parent_node = chunk.parent_node
                parent_node.chunk = chunk
                parent_node.meta = parent_node.meta or new_template(Quad_Meta_Data, tick)
                local p_meta = parent_node.meta
                local c_meta = chunk.meta

                p_meta.total_weight = p_meta.total_weight + bucket.w
                p_meta.aggregate_fx = p_meta.aggregate_fx + bucket.fx
                p_meta.max_priority = math_max(p_meta.max_priority, bucket.p)

                p_meta.player_deaths = p_meta.player_deaths + c_meta.player_deaths
                p_meta.enemy_deaths = p_meta.enemy_deaths + c_meta.enemy_deaths

                p_meta.total_player_deaths = p_meta.total_player_deaths + c_meta.total_player_deaths
                p_meta.total_enemy_deaths = p_meta.total_enemy_deaths + c_meta.total_enemy_deaths

                p_meta.total_deaths = p_meta.total_deaths + c_meta.total_deaths

                if (c_meta.enemy_deaths > 0 or c_meta.player_deaths > 0) then
                    p_meta.witnessed = 1
                    p_meta.witnessed_tick = tick
                end

                if (p_meta.witnessed) then
                    surface_funcs = surface_funcs or set_game() and surface_funcs
                    p_meta.pollution = surface_funcs[surface_name].get_pollution({ chunk.x * CHUNK_SIZE, chunk.y * CHUNK_SIZE })
                end

                p_meta.updated = tick
                propgate_count = propgate_count + 1

                parents_to_propogate = parents_to_propogate or {}
                parents_to_propogate[propgate_count] = chunk.parent_node
            end
            buckets[xy] = nil
        end

        if (request_scouting_party(surface_name, tick)) then
            local next_idx = scout_registry.last
            scout_registry.last = next_idx + 1
            scout_registry.q[next_idx] = {
                state = STATE_REQUESTING,
                surface_name = surface_name,
                idx = next_idx,
                strictness = inverse_stress,
                --[[ TODO: Better way of determining unit_type; hard-coded for time being ]]
                unit_type = surface_name == GLEBA and SPIDER_UNIT or UNIT,
                created = tick,
                updated = tick,
            }
        end
    end

    if (propgate_count > 0 and parents_to_propogate and parents_to_propogate[1]) then
        for _, node in ipairs(parents_to_propogate or {}) do
            propagate_node_metrics_iteratively(node, tick)
        end
    end

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
            if (ctx.state == STATE_REQUESTING) then

                spawner_maps = spawner_maps or set_game() and spawner_maps
                spawner_maps[ctx.surface_name] = spawner_maps[ctx.surface_name] or {}

                scout_registry.surfaces = scout_registry.surfaces or {}
                scout_registry.surfaces[ctx.surface_name] = scout_registry.surfaces[ctx.surface_name] or {}

                local xy, chunk = next(spawner_maps[ctx.surface_name], scout_registry.surfaces[ctx.surface_name].xy)

                scout_registry.surfaces[ctx.surface_name].xy = xy
                ctx.source_chunk = chunk
                if (ctx.source_chunk) then
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_SCANTREE
                else
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_RECOVERY
                end

                requeue(ctx)
            elseif (ctx.state == STATE_SCANTREE) then
                ctx.search_checkpoint = ctx.search_checkpoint or {
                    current_node = nil,
                    best_leaf = nil,
                    best_score = -1,
                    iterations = 0,
                    state = ctx.state
                }

                find_closest_iteratively({
                    tick = tick,
                    checkpoint = ctx.search_checkpoint,
                    surface_name = ctx.surface_name,
                    source_chunk = ctx.source_chunk,
                    min_distance = 64,
                })

                if (ctx.state ~= ctx.search_checkpoint.state) then
                    ctx.prev_state = ctx.state
                    ctx.state = ctx.search_checkpoint.state or STATE_RECOVERY
                    ctx.target_chunk = ctx.search_checkpoint.final_target
                    if (not ctx.target_chunk) then ctx.state = STATE_RECOVERY end
                    ctx.search_checkpoint = nil
                else
                    ctx.prev_state = ctx.state
                    ctx.state = STATE_SCANTREE
                end

                requeue(ctx)
            elseif (ctx.state == STATE_REQUESTING_PATH) then
                planetary_surfaces = planetary_surfaces or set_game and planetary_surfaces
                if (    planetary_surfaces[ctx.surface_name]
                    and planetary_surfaces[ctx.surface_name].valid
                ) then
                    ctx.request_attempts = ctx.request_attempts or 0
                    --[[ TODO: determine these more appropriately ]]
                    local start = { x = (ctx.source_chunk.x + 0.5) * CHUNK_SIZE, y = (ctx.source_chunk.y + 0.5) * CHUNK_SIZE, }
                    local goal  = { x = (ctx.target_chunk.x + math_random()) * CHUNK_SIZE, y = (ctx.target_chunk.y + math_random()) * CHUNK_SIZE, }

                    local path_request = {
                        bounding_box = BOUNDING_BOXES[ctx.unit_type],
                        collision_mask = COLLISION_MASKS[ctx.unit_type],
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
                        ctx.request_attempts = ctx.request_attempts + 1
                        if (ctx.request_attempts > 1 + 2 * inverse_stress) then
                            ctx.prev_state = ctx.state
                            ctx.state = STATE_RECOVERY
                        end

                        requeue(ctx)
                    else
                        ctx.prev_state = ctx.state
                        ctx.state = STATE_PATHFINDING
                        ctx.path_id = path_id
                        ctx.path_request = path_request
                        ctx.request_attempts = nil
                        ctx.idx = nil

                        difficulties = difficulties or set_game() and difficulties
                        difficulties[ctx.surface_name] = difficulties[ctx.surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[ctx.surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])
                        local selected_difficulty = difficulties[ctx.surface_name]

                        unit_groups = unit_groups or set_game() and unit_groups
                        unit_groups[path_id] = new_Requesting_Unit_Group(Requesting_Unit_Group, {
                            enemies = {},
                            surface_name = ctx.surface_name,
                            start_position  = path_request.start,
                            target_position = path_request.goal,
                            xy = ctx.source_chunk.xy or (ctx.source_chunk.x .. FORWARD_SLASH .. ctx.source_chunk.y),
                            limit = math_min(max_unit_group_size, 12 + selected_difficulty.value + selected_difficulty.value * selected_difficulty.radius_modifier * (1 + selected_difficulty.radius_modifier * math_random(1 + selected_difficulty.value))),
                            path_id = path_id,
                            path_request = path_request,
                            --[[ TODO: make configurable ]]
                            attempts = 0,
                            --[[ TODO: make configurable ]]
                            retries = (selected_difficulty.retries or (function (selected_difficulty)
                                selected_difficulty.retries = selected_difficulty.retries or math_floor((selected_difficulty.value * 3) ^ 0.5)
                                return selected_difficulty.retries
                            end)(selected_difficulty)) + 1,
                            spider_unit = ctx.unit_type == SPIDER_UNIT or nil,
                            member_count = 0,
                        })
                        ctx.requesting_unit_group = unit_groups[path_id]

                        scout_path_registry = scout_path_registry or set_game() and scout_path_registry
                        scout_path_registry[path_id] = ctx
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
                            local group = surface_funcs[ctx.surface_name].create_unit_group({
                                position = spawn_pos,
                                force = ctx.force or ENEMY,
                            })

                            if (group and group.valid) then
                                unit_groups.count = (unit_groups.count or 0) + 1
                                unit_groups.surface_count[ctx.surface_name] = (unit_groups.surface_count[ctx.surface_name] or 0) + 1

                                local unique_id = group.unique_id
                                ctx.unique_id = unique_id
                                local reg_tbl = { tick = event.tick, group = group, unique_id = unique_id, starting_pos = group.position, surface_name = ctx.surface_name, }
                                reg_tbl.registration_number, reg_tbl.useful_id, reg_tbl.target_type = register_on_object_destroyed(group)

                                groups = groups or set_game() and groups
                                groups[unique_id] = reg_tbl

                                on_object_destroyed = on_object_destroyed or set_game() and on_object_destroyed
                                on_object_destroyed[reg_tbl.registration_number] = reg_tbl

                                local requesting_unit_group = ctx.requesting_unit_group
                                requesting_unit_group.unique_id = unique_id

                                unique_ids = unique_ids or set_game() and unique_ids
                                unique_ids[unique_id] = requesting_unit_group

                                requesting_unit_group.attempts = nil
                                requesting_unit_group.retries = nil
                                requesting_unit_group.path_id = nil
                                requesting_unit_group.path_request = nil

                                requesting_unit_group.member_count = requesting_unit_group.member_count or 0

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
                                for i = 1, num_enemies, 1 do
                                    if (i >= limit or i >= max_unit_group_size) then break end
                                    if (enemies[i] and enemies[i].valid) then
                                        enemies_added = enemies_added + 1
                                        unit_group_enemies[enemies_added] = enemies[i].unit_number
                                    end
                                end
                                ctx.requesting_unit_group.num_enemies = enemies_added

                                ctx.prev_state = ctx.state
                                ctx.state = STATE_FINALIZE
                                ctx.unit_group = group
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
                local group = ctx.unit_group
                if (group and group.valid) then
                    local idx = ctx.unique_id % 60 + 1

                    game.print("STATE_FINALIZE")
                    game.print("source")
                    game.print({ "messages.entity-gps", "", ctx.requesting_unit_group.start_position.x, ctx.requesting_unit_group.start_position.y, ctx.requesting_unit_group.surface_name })
                    game.print("target")
                    game.print({ "messages.entity-gps", "", ctx.requesting_unit_group.target_position.x, ctx.requesting_unit_group.target_position.y, ctx.requesting_unit_group.surface_name })

                    pathables = pathables or set_game() and pathables
                    pathables[idx] = pathables[idx] or new_Simple_Queue(Simple_Queue)

                    local next_idx = pathables[idx].last or 1
                    pathables[idx].q[next_idx] = ctx.requesting_unit_group
                    pathables[idx].last = next_idx + 1
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
    end
end
if (    conductor_styles[selected_style]
    and conductor_styles[selected_style] > 0
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
        local chunk = chunk_maps[surface_name][requesting_unit_group.xy or ""]

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
if (    conductor_styles[selected_style]
    and conductor_styles[selected_style] > 0
) then
    Event_Handler:register_event({
        event_name = "on_script_path_request_finished",
        source_name = "conductor_controller.on_script_path_request_finished",
        func_name = "conductor_controller.on_script_path_request_finished",
        func = conductor_controller.on_script_path_request_finished,
    })
end

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name] = function (event, params) max_unit_groups = params.setting_value end
update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name] = function (event, params) max_unit_group_size = params.setting_value end

for _, surface_name in ipairs(Planets or {}) do
    update_settings[Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"]] = function (event, params) attack_group_probability_modifiers[surface_name] = params.setting_value end
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