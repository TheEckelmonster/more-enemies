local storage
local stats_data
local attack_groups
local chunks_arr
local chunk_maps
local difficulties
local entity_chunks
local entity_maps
local groups
local on_object_destroyed
local pathables
local settings_map
local spawner_maps
local surfaces
local target_registries
local unit_groups
local unique_ids

local forces
local force_funcs

local game
local get_surface
local planetary_surfaces
local surface_funcs

local Set_Game_Funcs = Set_Game_Funcs

local Set_Num_Clones = Set_Num_Clones

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local Planets = Planets
local Surfaces = Surfaces

local ipairs = ipairs
local pairs = pairs

local string_find = string.find

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new
local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.attack_groups = storage.attack_groups or {}
    attack_groups = storage.attack_groups

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.on_object_destroyed = storage.on_object_destroyed or new_Simple_Queue(Simple_Queue)
    on_object_destroyed = storage.on_object_destroyed

    storage.pathables = storage.pathables or {}
    pathables = storage.pathables

    storage.settings_map = storage.settings_map or {}
    settings_map = storage.settings_map

    storage.settings_map.runtime_global = storage.settings_map.runtime_global or {}
    storage.settings_map.startup = storage.settings_map.startup or {}

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.chunks_arr = storage.chunks_arr or {}
    chunks_arr = storage.chunks_arr

    storage.chunk_maps = storage.chunk_maps or {}
    chunk_maps = storage.chunk_maps

    storage.entity_chunks = storage.entity_chunks or {}
    entity_chunks = storage.entity_chunks

    storage.entity_maps = storage.entity_maps or {}
    entity_maps = storage.entity_maps

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

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

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    storage.unique_ids = storage.unique_ids or {}
    unique_ids = storage.unique_ids

    game = __game or _ENV.game
    get_surface = game.get_surface

    -- Forces = Forces or {}
    -- Force_Funcs = Force_Funcs or {}
    -- for name, force in pairs(game.forces) do
    --     if (force.valid) then
    --         Forces[name] = force
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

local type = type

local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_random = math.random
local math_sqrt = math.sqrt

local defines = defines
local command_attack_area = defines.command.attack_area
local command_build_base = defines.command.build_base

local script = script
local register_on_object_destroyed = script.register_on_object_destroyed

local Data_Utils = Data_Utils
local Constants = Constants
local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Log = Log

local Attack_Group_Data = require("scripts.data.attack-group-data")
local new_Attack_Group_Data = Attack_Group_Data.new
local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
local get_enemy = Attack_Group_Utils.get_enemy
local get_target_entity = Attack_Group_Utils.get_target_entity
local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack
local Requesting_Unit_Group = require("scripts.data.requesting-unit-group")
local new_Requesting_Unit_Group = Requesting_Unit_Group.new
local Settings_Service = require("scripts.service.settings-service")
local get_startup_setting = Settings_Service.get_startup_setting
local Simple_Queue = Simple_Queue or require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new
local Quadtree_Service = require("scripts.service.quadtree-service")
local register_highest_chunk = Quadtree_Service.register_highest_chunk
local Target_Registry_Data = require("scripts.data.target-registry-data")
local new_Target_Registry_Data = Target_Registry_Data.new

local delay_min = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name, }) or Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.default_value
local delay_max = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name, }) or Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.default_value
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, }) or 30

local attack_group_probability_modifiers = {}
for _, surface_name in ipairs(Planets or {}) do
    attack_group_probability_modifiers[surface_name] = Data_Utils.get_runtime_global_setting({ setting = (Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"] or {}).name, }) or 0
end

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

local CHUNK = 32
local MINUTES_2 = 60*60*2

local SIGN_OF_THE_BEAST = 666
local BASE_DELAY = 60*SIGN_OF_THE_BEAST

local PATHFINDER_FLAGS = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, cache = true, }

local attack_group_service = {}
attack_group_service.name = "attack_group_service"
attack_group_service.set_game = set_game

local function flatcopy(src)
    if (not src) then return end

    local copy = {}

    for k, v in pairs(src or {}) do copy[k] = v end

    return copy
end

local function flatcopy_array(src, dst)
    if (not src) then return end
    dst = dst or {}
    for i = 1, #dst, 1 do dst[i] = nil end
    for i = 1, #src, 1 do dst[i] = flatcopy(src[i]) end
    return dst
end

-- function attack_group_service.do_random_attack_group(params)
function attack_group_service.do_random_attack_group(surface_name, tick)
    -- Log.debug("attack_group_service.do_random_attack_group")
    -- Log.info(params)
    -- if (not params) then return end

    -- local surface_name = params.surface_name
    if (not surface_name) then return end

    -- local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not planetary_surfaces) then set_game() end
    local surface = planetary_surfaces[surface_name] or set_game().get_surface(surface_name)
    -- log(serpent.block(surface))
    if (not surface or not surface.valid) then return end

    -- local tick = params.tick or (game and set_game()).tick
    tick = tick or (game and set_game()).tick

    surface_funcs = surface_funcs or set_game() and surface_funcs
    surface_funcs[surface_name] = surface_funcs[surface_name] or {}
    surface_funcs[surface_name].request_path = surface_funcs[surface_name].request_path or surface.request_path

    attack_groups = attack_groups or set_game()
    attack_groups[surface_name] = attack_groups[surface_name] or new_Attack_Group_Data(Attack_Group_Data, { surface_name = surface_name, current_chunks = flatcopy_array(surfaces[surface_name].entity_chunks, {}), })
    attack_groups[surface_name].tick = attack_groups[surface_name].tick or tick
    if (    attack_groups[surface_name].tick
        and attack_groups[surface_name].tick > (tick or 0)
        or  attack_groups[surface_name].sleep_until
        and attack_groups[surface_name].sleep_until > (tick or 0)
    ) then
        return
    end

    surfaces = surfaces or set_game() and surfaces
    if (not surfaces[surface_name]) then return end

    if (not attack_groups[surface_name]) then return end
    local attack_group = attack_groups[surface_name]

    local skip = false

    attack_group.prev_delay = attack_group.cur_delay or 30
    attack_group.cur_delay = 30
    unit_groups = unit_groups or set_game() and unit_groups
    unit_groups.surface_count = unit_groups.surface_count or {}
    unit_groups.surface_count[surface_name] = unit_groups.surface_count[surface_name] or 0
    if (unit_groups.surface_count[surface_name] > max_unit_groups) then
        local curr_fail_count = (attack_group.fail_count or 0) + 1
        attack_group.fail_count = curr_fail_count

        attack_group.sleep_until = tick + math_min(2 * curr_fail_count, 180)
        skip = true
        goto skip
    end

    do
        attack_group.current_chunks = attack_group.current_chunks or {}
        attack_group.next_chunks = attack_group.next_chunks or {}

        if (#attack_group.current_chunks == 0 and #attack_group.next_chunks == 0) then
            attack_group.current_chunks = flatcopy_array(surfaces[surface_name].entity_chunks, attack_group.current_chunks)
        end

        local chunks = attack_group.current_chunks
        if (not chunks or #chunks < 1) then
            local temp = attack_group.current_chunks
            attack_group.current_chunks = attack_group.next_chunks
            attack_group.next_chunks = temp

            chunks = attack_group.current_chunks

            if (not chunks or #chunks < 1) then
                attack_group.current_chunks = flatcopy_array(surfaces[surface_name].entity_chunks, attack_group.current_chunks)
                chunks = attack_group.current_chunks

                if (not chunks or #chunks < 1) then
                    skip = true
                    goto skip
                end
            end
        end

        local count = #chunks
        local rand = math_random(count)
        local chunk = chunks[rand]

        chunks[rand] = chunks[count]
        chunks[count] = nil

        entity_maps = entity_maps or set_game() and entity_maps
        local entity_map = entity_maps[surface_name]

        if (not entity_map or not entity_map[chunk.xy or 0]) then
            if (entity_map) then entity_map[chunk.xy or 0] = chunk end
        end
        attack_group.next_chunks[#attack_group.next_chunks+1] = chunk

        if (    not chunk
            or
                chunk.timeout
            and chunk.timeout > tick
        ) then
            attack_group.invalid_chunks = (attack_group.invalid_chunks or 0) + 1
            -- attack_group.tick = (tick or 0) + 10 * (attack_group.invalid_chunks ^ 1.75)
            attack_group.tick = (tick or 0) + math_min(MINUTES_2, 10 * (attack_group.invalid_chunks ^ 1.75))
            skip = true
            goto skip
        else
            attack_group.invalid_chunks = (attack_group.invalid_chunks or 1) ^ 0.6
        end

        difficulties = difficulties or set_game() and difficulties
        difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])

        local selected_difficulty = difficulties[surface_name]
        if (not selected_difficulty) then
            skip = true
            goto skip
        end

        local meta = chunk.meta
        if (not meta or not meta.witnessed or meta.witnessed <= 0) then goto skip end

        -- -- local witnessed_delta = tick - meta.witnessed_tick
        -- local witnessed_delta = (tick - meta.witnessed_tick)
        -- local rand_2 = math_random(SIGN_OF_THE_BEAST, BASE_DELAY)
        -- -- log(serpent.block(witnessed_delta))
        -- -- log(serpent.block(rand_2))
        -- if (witnessed_delta > rand_2) then goto skip end
        local witnessed_delta = (tick - meta.witnessed_tick)
        local rand_2 = math_random(1, 1 + witnessed_delta)
        local priority_scalar = 1

        target_registries = target_registries or set_game() and target_registries
        target_registries[surface_name] = target_registries[surface_name] or new_Target_Registry_Data(Target_Registry_Data, {}, selected_difficulty.value or nil)
        local target_registry = target_registries[surface_name]

        -- if (rand_2 > BASE_DELAY) then goto skip end
        if (rand_2 > BASE_DELAY) then
            if (not target_registry.pool_count or target_registry.pool_count < 1) then goto skip end

            chunk = target_registry.pool[target_registry.pool_count == 1 and 1 or math_random(target_registry.pool_count)]
            priority_scalar = 2.25
        else
            if (not target_registry.mapped_idx[chunk.xy] or tick - (chunk.value_tick or 0) > BASE_DELAY) then
                register_highest_chunk(chunk, surface_name, chunk.value or 0, tick)
            end

            if (target_registry.mapped_idx[chunk.xy]) then
                chunk = target_registry.pool[target_registry.mapped_idx[chunk.xy]]
                if (chunk.meta) then
                    priority_scalar = (chunk.meta.max_priority or 0) + 1
                end
            end
        end

        local limit = math_min(max_unit_group_size, priority_scalar * 12 + selected_difficulty.value + selected_difficulty.value * selected_difficulty.radius_modifier * (1 + selected_difficulty.radius_modifier * math_random(1 + selected_difficulty.value)))

        local enemies = get_enemy({ surface_name = surface_name, xy = chunk.xy, tick = tick or 0, limit = limit }) or {}
        local num_enemies = #enemies
        if (not enemies[1] or not enemies[1].valid) then
            skip = true
            goto skip
        end

        local evolution_factor = enemies[1].force.get_evolution_factor(surface)
        evolution_factor = evolution_factor ^ (1 / selected_difficulty.value)

        -- Maximum probability of an attack group spawning at 100% (1) evolution factor
        local max_probability = 1 - (selected_difficulty.inverse_value or (function (arr)
            arr[1].inverse_value = arr[2]
            return arr[2]
        end)({ selected_difficulty, (1 / selected_difficulty.value), }))

        if (max_probability < 0) then max_probability = 0 end

        settings_map = settings_map or set_game() and settings_map
        max_probability = max_probability * (attack_group_probability_modifiers[surface_name] or 0)
        local threshold = max_probability * evolution_factor
        selected_difficulty.retries = selected_difficulty.retries or math_floor((selected_difficulty.value * 3) ^ 0.5)

        local proceed = false
        rand = math_random()
        for i = 1, selected_difficulty.retries, 1 do
            if (rand < threshold) then
                proceed = true
                break
            end
            threshold = threshold ^ (0.95 * (1 - math_max((1 - selected_difficulty.inverse_value) * evolution_factor, 1.0)))
        end

        if (not proceed) then return end

        local target_entities = get_target_entity({
            chunk = chunk,
            surface_name = surface_name,
            limit = 1 + selected_difficulty.value,
        }) or {}

        local target_entity = nil
        if (#target_entities > 0) then
            target_entity = target_entities[math_random(#target_entities)]
            if (not target_entity or not target_entity.valid) then
                skip = true
                goto skip
            end
        else
            skip = true
            goto skip
        end

        local target_position = target_entity.position
        local path_request = {
            bounding_box = BOUNDING_BOXES[enemies[1].type],
            collision_mask = COLLISION_MASKS[enemies[1].type],
            start = enemies[1].position,
            goal = target_position,
            force = enemies[1].force,
            radius = 12,
            pathfind_flags = PATHFINDER_FLAGS,
            can_open_gates = false,
            path_resolution_modifier = -1,
            max_gap_distance = enemies[1].type == SPIDER_UNIT and 4 or 0,
        }

        local path_id = surface_funcs[surface_name].request_path(path_request)

        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups[path_id] = new_Requesting_Unit_Group(Requesting_Unit_Group, {
            enemies = {},
            surface_name = surface_name,
            force_name = enemies[1].force or ENEMY,
            start_position = enemies[1].position,
            target_position = target_position,
            -- xy = math_floor(enemies[1].position.x / CHUNK) .. FORWARD_SLASH .. math_floor(enemies[1].position.y / CHUNK),
            xy = pack_coordinates(math_floor(enemies[1].position.x / CHUNK), math_floor(enemies[1].position.y / CHUNK)),
            limit = math_floor(limit),
            path_id = path_id,
            path_request = path_request,
            --[[ TODO: make configurable ]]
            attempts = 0,
            --[[ TODO: make configurable ]]
            retries = selected_difficulty.retries + 1,
            spider_unit = enemies[1].type == SPIDER_UNIT or nil,
        })

        local unit_group_enemies = unit_groups[path_id].enemies
        local enemies_added = 0
        for i = 1, num_enemies, 1 do
            if (i >= limit or i >= max_unit_group_size) then break end
            if (enemies[i] and enemies[i].valid) then
                enemies_added = enemies_added + 1
                unit_group_enemies[enemies_added] = enemies[i].unit_number
            end
        end
        unit_groups[path_id].num_enemies = enemies_added

        if (delay_min > delay_max) then delay_min = delay_max end
        if (delay_max < delay_min ) then delay_max = delay_min end

        attack_group.cur_delay = delay_min > 0 and delay_max >= delay_min and math_random(delay_min, delay_max) or 0

        if (selected_difficulty and selected_difficulty.value and selected_difficulty.value > 0) then
            attack_group.cur_delay = attack_group.cur_delay / ((selected_difficulty.radius_modifier ^ 1.5) * (0.5 + ((evolution_factor ^ 0.75) / 2)))
        end
    end

    if (attack_group.fail_count and attack_group.fail_count > 1) then
        attack_group.fail_count = math_sqrt(attack_group.fail_count )
    end

    ::skip::
    -- log(serpent.block(skip))
    if (skip) then attack_group.cur_delay = attack_group.cur_delay * 0.95 end

    attack_group.tick = (tick or 0) + attack_group.cur_delay
end

-- function attack_group_service.do_targeted_attack_group(params)
function attack_group_service.do_targeted_attack_group(surface_name, tick)
    -- Log.debug("attack_group_service.do_targeted_attack_group")
    -- Log.info(params)
    -- if (not params) then return end

    -- local surface_name = params.surface_name
    if (not surface_name) then return end

    if (not planetary_surfaces) then set_game() end
    local surface = planetary_surfaces[surface_name] or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    -- local tick = params.tick or (game and set_game()).tick
    tick = tick or (game and set_game()).tick

    surface_funcs = surface_funcs or set_game() and surface_funcs
    surface_funcs[surface_name] = surface_funcs[surface_name] or {}
    surface_funcs[surface_name].request_path = surface_funcs[surface_name].request_path or surface.request_path

    attack_groups = attack_groups or set_game()
    attack_groups[surface_name] = attack_groups[surface_name] or new_Attack_Group_Data(Attack_Group_Data, { surface_name = surface_name, current_chunks = flatcopy_array(surfaces[surface_name].entity_chunks, {}), })
    attack_groups[surface_name].tick = attack_groups[surface_name].tick or tick
    if (    attack_groups[surface_name].tick
        and attack_groups[surface_name].tick > (tick or 0)
        or  attack_groups[surface_name].sleep_until
        and attack_groups[surface_name].sleep_until > (tick or 0)
    ) then
        return
    end

    surfaces = surfaces or set_game() and surfaces
    if (not surfaces[surface_name]) then return end

    if (not attack_groups[surface_name]) then return end
    local attack_group = attack_groups[surface_name]

    local skip = false

    attack_group.prev_delay = attack_group.cur_delay or 30
    attack_group.cur_delay = 30
    unit_groups = unit_groups or set_game() and unit_groups
    unit_groups.surface_count = unit_groups.surface_count or {}
    unit_groups.surface_count[surface_name] = unit_groups.surface_count[surface_name] or 0
    if (unit_groups.surface_count[surface_name] > max_unit_groups) then
        local curr_fail_count = (attack_group.fail_count or 0) + 1
        attack_group.fail_count = curr_fail_count

        attack_group.sleep_until = tick + math_min(2 * curr_fail_count, 180)
        skip = true
        goto skip
    end

    do
        difficulties = difficulties or set_game() and difficulties
        difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or Startup_Settings_Constants.settings["FALLBACK_DIFFICULTY"]).name, reindex = true, }) or "Vanilla"]])

        local selected_difficulty = difficulties[surface_name]
        if (not selected_difficulty) then
            skip = true
            goto skip
        end

        target_registries = target_registries or set_game() and target_registries
        target_registries[surface_name] = target_registries[surface_name] or new_Target_Registry_Data(Target_Registry_Data, {}, selected_difficulty.value or nil)
        local target_registry = target_registries[surface_name]

        local chunk = nil
        local priority_scalar = 1

        local rand = math_random()
        if (rand < 0.42) then
            chunk = target_registry.pool[target_registry.pool_count <= 1 and 1 or math_random(target_registry.pool_count)]
            priority_scalar = 1.25
        else
            rand = math_random()
            if (target_registry.nw and rand < 0.25) then
                chunk = target_registry.nw.pool[target_registry.nw.pool_count <= 1 and 1 or math_random(target_registry.nw.pool_count)]
            elseif (target_registry.sw and rand < 0.5) then
                chunk = target_registry.sw.pool[target_registry.sw.pool_count <= 1 and 1 or math_random(target_registry.sw.pool_count)]
            elseif (target_registry.se and rand < 0.75) then
                chunk = target_registry.se.pool[target_registry.se.pool_count <= 1 and 1 or math_random(target_registry.se.pool_count)]
            elseif (target_registry.ne and rand < 1.0) then
                chunk = target_registry.ne.pool[target_registry.ne.pool_count <= 1 and 1 or math_random(target_registry.ne.pool_count)]
            else
                chunk = target_registry.pool[target_registry.pool_count == 1 and 1 or math_random(target_registry.pool_count)]
                priority_scalar = 1.25
            end
        end
        if (not chunk) then goto skip end

        local meta = chunk.meta
        if (not meta or not meta.witnessed or meta.witnessed <= 0) then goto skip end

        priority_scalar = math_max(10, (chunk.meta.max_priority or 1) * priority_scalar)

        local witnessed_delta = (tick - meta.witnessed_tick)
        local rand_2 = math_random(1, 1 + witnessed_delta)

        if (rand_2 > BASE_DELAY) then goto skip end

        local limit = math_min(max_unit_group_size, priority_scalar * 12 + selected_difficulty.value + selected_difficulty.value * selected_difficulty.radius_modifier * (1 + selected_difficulty.radius_modifier * math_random(1 + selected_difficulty.value)))

        local enemies = get_enemy({ surface_name = surface_name, xy = chunk.xy, tick = tick or 0, limit = limit }) or {}
        local num_enemies = #enemies
        if (not enemies[1] or not enemies[1].valid) then
            skip = true
            goto skip
        end

        local evolution_factor = enemies[1].force.get_evolution_factor(surface)
        evolution_factor = evolution_factor ^ (1 / selected_difficulty.value)

        -- Maximum probability of an attack group spawning at 100% (1) evolution factor
        local max_probability = 1 - (selected_difficulty.inverse_value or (function (arr)
            arr[1].inverse_value = arr[2]
            return arr[2]
        end)({ selected_difficulty, (1 / selected_difficulty.value), }))

        if (max_probability < 0) then max_probability = 0 end

        settings_map = settings_map or set_game() and settings_map
        max_probability = max_probability * (attack_group_probability_modifiers[surface_name] or 0)
        local threshold = max_probability * evolution_factor
        selected_difficulty.retries = selected_difficulty.retries or math_floor((selected_difficulty.value * 3) ^ 0.5)

        local proceed = false
        local rand = math_random()
        for i = 1, selected_difficulty.retries, 1 do
            if (rand < threshold) then
                proceed = true
                break
            end
            threshold = threshold ^ (0.95 * (1 - math_max((1 - selected_difficulty.inverse_value) * evolution_factor, 1.0)))
        end

        if (not proceed) then return end

        local target_entities = get_target_entity({
            chunk = chunk,
            surface_name = surface_name,
            limit = 1 + selected_difficulty.value,
        }) or {}

        local target_entity = nil
        if (#target_entities > 0) then
            target_entity = target_entities[math_random(#target_entities)]
            if (not target_entity or not target_entity.valid) then
                skip = true
                goto skip
            end
        else
            skip = true
            goto skip
        end

        local target_position = target_entity.position
        local path_request = {
            bounding_box = BOUNDING_BOXES[enemies[1].type],
            collision_mask = COLLISION_MASKS[enemies[1].type],
            start = enemies[1].position,
            goal = target_position,
            force = enemies[1].force,
            radius = 12,
            pathfind_flags = PATHFINDER_FLAGS,
            can_open_gates = false,
            path_resolution_modifier = -1,
            max_gap_distance = enemies[1].type == SPIDER_UNIT and 4 or 0,
        }

        local path_id = surface_funcs[surface_name].request_path(path_request)

        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups[path_id] = new_Requesting_Unit_Group(Requesting_Unit_Group, {
            enemies = {},
            surface_name = surface_name,
            force_name = enemies[1].force or ENEMY,
            start_position = enemies[1].position,
            target_position = target_position,
            xy = pack_coordinates(math_floor(enemies[1].position.x / CHUNK), math_floor(enemies[1].position.y / CHUNK)),
            limit = math_floor(limit),
            path_id = path_id,
            path_request = path_request,
            scalar = priority_scalar,
            --[[ TODO: make configurable ]]
            attempts = 0,
            --[[ TODO: make configurable ]]
            retries = selected_difficulty.retries + 1,
            spider_unit = enemies[1].type == SPIDER_UNIT or nil,
        })

        local unit_group_enemies = unit_groups[path_id].enemies
        local enemies_added = 0
        for i = 1, num_enemies, 1 do
            if (i >= limit or i >= max_unit_group_size) then break end
            if (enemies[i] and enemies[i].valid) then
                enemies_added = enemies_added + 1
                unit_group_enemies[enemies_added] = enemies[i].unit_number
            end
        end
        local i = 0
        while enemies_added < limit and enemies_added < max_unit_group_size do
            i = i + 1
            if (i > num_enemies) then i = 1 end
            enemies_added = enemies_added + 1
            unit_group_enemies[enemies_added] = unit_group_enemies[i]
        end
        unit_groups[path_id].num_enemies = enemies_added

        if (delay_min > delay_max) then delay_min = delay_max end
        if (delay_max < delay_min ) then delay_max = delay_min end

        attack_group.cur_delay = delay_min > 0 and delay_max >= delay_min and math_random(delay_min, delay_max) or 0

        if (selected_difficulty and selected_difficulty.value and selected_difficulty.value > 0) then
            attack_group.cur_delay = attack_group.cur_delay / ((selected_difficulty.radius_modifier ^ 1.5) * (0.5 + ((evolution_factor ^ 0.75) / 2)))
        end
    end

    if (attack_group.fail_count and attack_group.fail_count > 1) then
        attack_group.fail_count = math_sqrt(attack_group.fail_count )
    end

    ::skip::
    if (skip) then attack_group.cur_delay = attack_group.cur_delay * 0.95 end

    attack_group.tick = (tick or 0) + attack_group.cur_delay
end

function attack_group_service.on_script_path_request_finished(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1

    if (not event) then return end
    process_event(stats_data, event.name, event.tick)

    if (not event.id) then return end
    local id = event.id

    unit_groups = unit_groups or set_game() and unit_groups

    local requesting_unit_group = unit_groups[id]
    if (not requesting_unit_group) then return end
    local surface_name = requesting_unit_group.surface_name
    unit_groups[id] = nil

    if (event.try_again_later) then
        requesting_unit_group.attempts = requesting_unit_group.attempts or 0
        requesting_unit_group.retries = requesting_unit_group.retries or 0
        if (requesting_unit_group.attempts > requesting_unit_group.retries) then return end
        requesting_unit_group.attempts = requesting_unit_group.attempts + 1

        --[[ TODO: make configurable ]]
        requesting_unit_group.path_request.radius = (requesting_unit_group.path_request.radius or 12) * 1.25
        --[[ TODO: make configurable ]]
        requesting_unit_group.path_request.path_resolution_modifier = (requesting_unit_group.path_request.path_resolution_modifier or -1) / 0.8
        if (requesting_unit_group.path_request.path_resolution_modifier < -8) then requesting_unit_group.path_request.path_resolution_modifier = -8 end

        requesting_unit_group.path_request.max_gap_distance = requesting_unit_group.spider_unit and requesting_unit_group.path_request.max_gap_distance / 0.8 or 0

        -- local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
        local surface = (planetary_surfaces or set_game() and planetary_surfaces) and planetary_surfaces[surface_name] or game and get_surface(surface_name) or set_game().get_surface(surface_name)
        if (not surface or not surface.valid) then return end

        surface_funcs = surface_funcs or set_game() and surface_funcs
        surface_funcs[surface_name] = surface_funcs[surface_name] or {}
        surface_funcs[surface_name].request_path = surface_funcs[surface_name].request_path or surface.request_path

        -- local path_id = surface.request_path(requesting_unit_group.path_request)
        local path_id = surface_funcs[requesting_unit_group.surface_name].request_path(requesting_unit_group.path_request)
        requesting_unit_group.path_id = path_id

        unit_groups[path_id] = requesting_unit_group
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
            return
        else
            if (chunk) then chunk.no_path = math_max(1, math_floor((chunk.no_path or 0) ^ 0.5)) end
        end
    end

    unit_groups.surface_count = unit_groups.surface_count or {}
    unit_groups.surface_count[surface_name] = (unit_groups.surface_count[surface_name] or 0)
    if (unit_groups.surface_count[surface_name] >= max_unit_groups) then return end

    local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    surface_funcs = surface_funcs or set_game() and surface_funcs
    surface_funcs[surface_name] = surface_funcs[surface_name] or {}
    surface_funcs[surface_name].create_unit_group = surface_funcs[surface_name].create_unit_group or surface.create_unit_group

    local unit_group = surface_funcs[surface_name].create_unit_group({ position = requesting_unit_group.start_position, })
    if (not unit_group or not unit_group.valid) then return end

    unit_groups.count = unit_groups.count + 1
    unit_groups.surface_count[surface_name] = unit_groups.surface_count[surface_name] + 1

    local tick = event.tick
    local unique_id = unit_group.unique_id
    local reg_tbl = { created = tick, updated = tick, refreshed_tick = tick, group = unit_group, unique_id = unique_id, starting_pos = unit_group.position, surface_name = surface_name, force_name = unit_group.force.name, }
    reg_tbl.xy = pack_coordinates(reg_tbl.starting_pos.x, reg_tbl.starting_pos.y)
    reg_tbl.registration_number, reg_tbl.useful_id, reg_tbl.reg_target_type = register_on_object_destroyed(unit_group)

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

    requesting_unit_group.unique_id = unique_id

    unique_ids = unique_ids or set_game() and unique_ids
    unique_ids[unique_id] = requesting_unit_group

    requesting_unit_group.attempts = nil
    requesting_unit_group.retries = nil
    requesting_unit_group.path_id = nil
    requesting_unit_group.path_request = nil

    local idx = unique_id % 60 + 1
    pathables[idx] = pathables[idx] or new_Simple_Queue(Simple_Queue)
    local next_idx = pathables[idx].last or 1
    pathables[idx].q[next_idx] = requesting_unit_group
    pathables[idx].last = next_idx + 1
end
Event_Handler:register_event({
    event_name = "on_script_path_request_finished",
    source_name = "attack_group_service.on_script_path_request_finished",
    func_name = "attack_group_service.on_script_path_request_finished",
    func = attack_group_service.on_script_path_request_finished,
})

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name] = function (event, params) delay_max = params.setting_value end
update_settings[Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name] = function (event, params) delay_min = params.setting_value end
update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name] = function (event, params) max_unit_groups = params.setting_value end
update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name] = function (event, params) max_unit_group_size = params.setting_value end

for _, surface_name in ipairs(Planets or {}) do
    local setting = Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"]
    if (setting and setting.name) then
        update_settings[setting.name] = function (event, params) attack_group_probability_modifiers[surface_name] = params.setting_value end
    end
end

local ME_PREFIX = ME_PREFIX
local STRING = Types.STRING
function attack_group_service.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = attack_group_service.on_runtime_mod_setting_changed
})

function attack_group_service.init(__storage) storage = __storage or _ENV.storage end

return attack_group_service