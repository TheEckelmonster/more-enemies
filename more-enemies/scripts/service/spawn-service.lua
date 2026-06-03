local storage
local stats_data
local attack_groups
local chunks_arr
local chunk_maps
local entities
local entity_chunks
local entity_maps
local groups
local limits
local num_clones
local opts
local pathables
local settings_map
local spawner_maps
local surfaces
local unique_ids
local unit_groups

local game
local get_entity_by_unit_number
local game_print
local surface_funcs

local Set_Num_Clones = Set_Num_Clones
local Surfaces = Surfaces

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local string_find = string.find

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.attack_groups = storage.attack_groups or {}
    attack_groups = storage.attack_groups

    storage.entities = storage.entities or {}
    entities = storage.entities

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.limits = storage.limits or {}
    limits = storage.limits

    storage.opts = storage.opts or {}
    opts = storage.opts

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
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_map
    end

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    storage.unique_ids = storage.unique_ids or {}
    unique_ids = storage.unique_ids

    --[[ game ]]
    game = __game or _ENV.game
    get_entity_by_unit_number = game.get_entity_by_unit_number
    game_print = game.print

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
            Surface_Funcs[name].find_entities_filtered = Surface_Funcs[name].find_entities_filtered or surface.find_entities_filtered
            Surface_Funcs[name].find_non_colliding_position = Surface_Funcs[name].find_non_colliding_position or surface.find_non_colliding_position
            Surface_Funcs[name].request_path = Surface_Funcs[name].request_path or surface.request_path
        else
            Surfaces[name], Surface_Funcs[name] = nil, nil
        end
    end
    surface_funcs = Surface_Funcs

    num_clones = Set_Num_Clones()

    return game
end

local ipairs = ipairs

local math_floor = math.floor
local math_huge = math.huge
local math_max = math.max
local math_min = math.min
local table_insert = table.insert
local type = type

local defines = defines
local command_attack_area = defines.command.attack_area
local command_build_base = defines.command.build_base

local Clone_Unit_Setting = Clone_Unit_Setting
local Clone_Unit_Group_Setting = Clone_Unit_Group_Setting
local Constants = Constants or require("scripts.constants.constants")
local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants
local Valid_Sources = Valid_Sources
local Valid_Surfaces = Valid_Surfaces

local Attack_Group_Constants = require("scripts.constants.attack-group-constants")
local attack_group_type_blacklist = Attack_Group_Constants.type_blacklist
local Leaf_Data = require("scripts.data.leaf-data")
local new_Leaf_Data = Leaf_Data.new
local Quadtree_Service = require("scripts.service.quadtree-service")
local add_node = Quadtree_Service.add_node
local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new
local Settings_Utils = require("scripts.utils.settings-utils")
local Spawn_Utils = require("scripts.utils.spawn-utils")
local clone_entity = Spawn_Utils.clone_entity

local blacklist_names = Settings_Utils.get_attack_group_blacklist_names()

local names = {}

if (blacklist_names) then
    for _, v in pairs(blacklist_names) do
        table_insert(names, v)
    end
end

local clones_per_tick = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK.name, }) or Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK.default_value
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

local requesting_unit_group_placeholder = { member_count = math_huge, }

local spawn_service = {}
spawn_service.name = "spawn_service"
spawn_service.set_game = set_game

spawn_service.entity_list = {}
spawn_service.entity_list_index = {}

spawn_service.entity = {}
spawn_service.entity_index = {}

spawn_service.BREAM = {}
spawn_service.BREAM.unit_group = nil
spawn_service.BREAM.clones_index = nil
spawn_service.BREAM.last_ran = 0

local CHUNK_SIZE = Constants.CHUNK_SIZE
local ME_PREFIX = ME_PREFIX
local ENEMY, GROUP, SPAWNED, UNIT, UNIT_GROUP = ENEMY, GROUP, SPAWNED, UNIT, UNIT_GROUP
local CONTINUE, SKIP, REMOVE = 1, 2, 3

local show_attack_group_targets = Runtime_Global_Settings_Constants.settings.DEBUG_SHOW_ATTACK_GROUP_TARGETS

local clone_count = 0
local gotos = {
    [CONTINUE] = CONTINUE,
    [SKIP] = SKIP,
    [REMOVE] = REMOVE,
}
function spawn_service.on_tick(event)
    -- log_error("spawn_service.on_tick")
    -- Log.info(event)

    game = game or set_game()

    event = event or { tick = game and game.tick or set_game().tick, }

    num_clones = num_clones or set_game() and num_clones

    clone_count = 0
    local idx = event.tick % 60 + 1
    if (    pathables[idx]
        and pathables[idx].q
    ) then
        pathables[idx].first = pathables[idx].first or 1
        pathables[idx].last = pathables[idx].last or 1

        if (pathables[idx].last - pathables[idx].first < 0) then
            pathables[idx] = nil
        else
            local pathable_queue = pathables[idx]
            unit_groups.i, unit_groups.cap = pathable_queue.first, pathable_queue.last - pathable_queue.first + 1
            unit_groups.loop_cap, unit_groups.loops = 1 + unit_groups.cap * 1.5, 0

            local requesting_unit_group, release = nil, false
            local group, unit_group = nil, nil
            local to = nil
            local group_queue
            local enemy_idx = 0

            while unit_groups.i <= unit_groups.cap and unit_groups.loops <= unit_groups.loop_cap do
                if (((stats_data or set_game() and stats_data).current.total or 1) > 512) then break end

                release = false
                local first = pathable_queue.first
                requesting_unit_group = pathable_queue.q[first]
                if (not requesting_unit_group) then break end

                local grp = groups[requesting_unit_group.unique_id]
                if (    not grp
                    or  not grp.group
                    or  not grp.group.valid
                ) then
                    if (pathable_queue.first >= pathable_queue.last) then
                        pathable_queue.first, pathable_queue.last = 1, 1
                    end
                    to = REMOVE
                    goto remove
                end

                do
                    requesting_unit_group.j = requesting_unit_group.j or #requesting_unit_group.enemies
                    local unit_number = requesting_unit_group.enemies[requesting_unit_group.j]
                    requesting_unit_group.enemies[requesting_unit_group.j] = nil

                    if (    not unit_number
                        and requesting_unit_group.j <= 0
                    ) then
                        release = true
                        goto release_group
                    else
                        local unit_group_limit = requesting_unit_group.num_enemies or requesting_unit_group.limit or 42
                        local add_member = groups[requesting_unit_group.unique_id].group.add_member
                        local enemy, uidx = nil, unit_number % 60 + 1

                        requesting_unit_group.j = requesting_unit_group.j or enemy_idx or #requesting_unit_group.enemies
                        requesting_unit_group.enemies_added = requesting_unit_group.enemies_added or 0

                        if (requesting_unit_group.enemies_added >= unit_group_limit) then
                            unit_groups.loop_cap = unit_groups.loop_cap - 1
                            goto skip
                        end

                        while requesting_unit_group.j >= 0 do
                            if (requesting_unit_group.enemies_added >= math_min(unit_group_limit, max_unit_group_size)) then
                                release = true
                                goto release_group
                            end

                            enemy = get_entity_by_unit_number(unit_number)
                            if (enemy and enemy.valid) then

                                if (num_clones[GROUP][requesting_unit_group.surface_name][enemy.name] > (limits[GROUP] and limits[GROUP][requesting_unit_group.surface_name] and (limits[GROUP][requesting_unit_group.surface_name][enemy.name] or limits[GROUP][requesting_unit_group.surface_name].fallback) or 400)) then
                                    unit_groups.loop_cap = unit_groups.loop_cap - 1
                                    goto skip
                                end

                                enemy.release_from_spawner()
                                enemy.ai_settings.allow_try_return_to_spawner = false
                                enemy.ai_settings.join_attacks = true
                                add_member(enemy)

                                clone_count = clone_count + 1
                                requesting_unit_group.enemies_added = requesting_unit_group.enemies_added + 1

                                uidx = unit_number % 60 + 1

                                group_queue = entities[uidx] or (function (arr)
                                    arr[1][arr[2]] = new_Simple_Queue(Simple_Queue)
                                    return arr[1][arr[2]]
                                end)({ entities, uidx, })

                                local next_idx = group_queue.last or 1
                                group_queue.last = next_idx + 1
                                group_queue.q[next_idx] = {
                                    source = GROUP,
                                    unique_id = requesting_unit_group.unique_id,
                                    tick = event.tick,
                                    unit_number = unit_number,
                                    surface_name = requesting_unit_group.surface_name,
                                }

                                if (    requesting_unit_group.enemies_added >= (requesting_unit_group.num_enemies or max_unit_group_size)
                                    or  not requesting_unit_group.enemies[1]
                                ) then
                                    release = true
                                    goto release_group
                                end
                            end

                            enemy_idx = requesting_unit_group.j
                            unit_number = requesting_unit_group.enemies[enemy_idx]
                            requesting_unit_group.enemies[enemy_idx] = nil
                            requesting_unit_group.j = enemy_idx - 1
                            if (not unit_number) then
                                unit_groups.loop_cap = unit_groups.loop_cap - 1
                                goto skip
                            end
                        end

                        goto continue
                    end
                end

                ::release_group::

                if (release) then
                    group = nil
                    group = groups[requesting_unit_group.unique_id]

                    if (    not group
                        or  not group.group
                        or  not group.group.valid
                    ) then
                        to = REMOVE
                        goto remove
                    else
                        unit_group = group.group
                        unit_group.set_command({
                            type = command_attack_area,
                            destination = requesting_unit_group.target_position,
                            radius = 21,
                        })
                        if (unit_group.valid) then unit_group.release_from_spawner() end
                        if (unit_group.valid) then unit_group.start_moving() end

                        pathable_queue.first = pathable_queue.first or 1
                        local remove_idx = pathable_queue.first
                        pathable_queue.first = remove_idx + 1
                        pathable_queue.q[remove_idx] = nil
                        unit_groups.cap = unit_groups.cap - 1
                        unit_groups.loop_cap = unit_groups.loop_cap - 1

                        unique_ids[requesting_unit_group.unique_id or 0] = nil
                        groups[requesting_unit_group.unique_id or 0] = nil

                        clone_count = clone_count + 1

                        unit_groups = unit_groups or set_game() and unit_groups
                        unit_groups.surface_count[requesting_unit_group.surface_name] = (unit_groups.surface_count[requesting_unit_group.surface_name] or 0) - 1
                        if (unit_groups.surface_count[requesting_unit_group.surface_name] < 0) then unit_groups.surface_count[requesting_unit_group.surface_name] = 0 end

                        settings_map = settings_map or set_game() and settings_map
                        settings_map.runtime_global = settings_map.runtime_global or {}
                        if (settings_map.runtime_global[show_attack_group_targets.name]) then  game_print({ "messages.entity-gps", "", requesting_unit_group.target_position.x, requesting_unit_group.target_position.y, requesting_unit_group.surface_name }) end

                        to = REMOVE
                    end
                end

                ::continue::
                if (to and gotos[to] == CONTINUE) then to = 0 end
                unit_groups.i = unit_groups.i + 1

                ::remove::
                if (to and gotos[to] == REMOVE) then
                    pathable_queue.first = pathable_queue.first or 1
                    local remove_idx = pathable_queue.first
                    pathable_queue.first = remove_idx + 1
                    pathable_queue.q[remove_idx] = nil

                    groups[requesting_unit_group.unique_id] = nil
                    unit_groups.count = (unit_groups.count or 1) - 1
                    if (unit_groups.count < 0) then unit_groups.count = 0 end

                    unit_groups.surface_count[requesting_unit_group.surface_name] = (unit_groups.surface_count[requesting_unit_group.surface_name] or 1) - 1
                    if (unit_groups.surface_count[requesting_unit_group.surface_name] < 0) then unit_groups.surface_count[requesting_unit_group.surface_name] = 0 end

                    to = 0
                end

                ::skip::
                unit_groups.loops = unit_groups.loops + 1
                to = 0
            end
        end
    else
        pathables[idx] = nil
    end

    if (((stats_data or set_game() and stats_data).current.total or 1) > 1024) then return end
    local skip = nil
    local entity_queue = entities[idx]
    if (    not entity_queue
        or  not entity_queue.first
        or  not entity_queue.last
        or  not entity_queue.q
        or  entity_queue.first > entity_queue.last
    ) then
        entity_queue, entities[idx] = nil, nil
        skip = 1
        goto skip
    end

    do
        local entity_tbl, entity = nil, nil
        local source, surface_name = nil, nil
        local clones, group = nil, nil

        local queue_size = entity_queue.last - entity_queue.first
        if (queue_size < 0) then goto skip end
        for i = 1, queue_size, 1 do
            if ((stats_data.current.total or 1) > 8 * clones_per_tick) then
                skip = 1
                goto skip
            end
            if (clone_count > clones_per_tick or  i > clones_per_tick) then
                skip = 1
                goto skip
            end
            if ((entity_queue.last - entity_queue.first) < 0) then
                skip = 1
                goto skip
            end

            entity_tbl, entity = entity_queue.q[entity_queue.first], nil
            entity_queue.q[entity_queue.first] = nil
            entity_queue.first = entity_queue.first + 1
            if (    not entity_tbl
                or  not entity_tbl.unit_number
                or  not entity_tbl.surface_name
                or  not entity_tbl.name
            ) then
                if ((stats_data.current.total or 1) > 1024) then
                    skip = 1
                    goto skip
                end
                goto continue
            else
                if ((entity_queue.last - entity_queue.first) < 0) then
                    entities[idx] = nil
                    goto skip
                end
                if (not entity_tbl.source or not Valid_Sources[entity_tbl.source]) then goto continue end
                if (not entity_tbl.surface_name or not Valid_Surfaces[entity_tbl.surface_name]) then goto continue end

                source, surface_name = entity_tbl.source, entity_tbl.surface_name

                num_clones[source] = num_clones[source] or {}
                num_clones[source][surface_name] = num_clones[source][surface_name] or {}
                num_clones[source][surface_name][entity_tbl.name] = num_clones[source][surface_name][entity_tbl.name] or 0

                if (num_clones[source][surface_name][entity_tbl.name] > (limits[source] and limits[source][surface_name] and (limits[GROUP][surface_name][entity_tbl.name] or limits[GROUP][surface_name].fallback) or 400)) then goto continue end

                opts = opts or set_game() and opts
                opts.clone_settings = opts.clone_settings or {}
                opts.clone_settings.unit = Clone_Unit_Setting[surface_name] or 1
                opts.clone_settings.unit_group = Clone_Unit_Group_Setting[surface_name] or 1
                opts.type = entity_tbl.source == GROUP and UNIT_GROUP or UNIT

                entity = game and get_entity_by_unit_number(entity_tbl.unit_number) or set_game().get_entity_by_unit_number(entity_tbl.unit_number)
                if (not entity or not entity.valid) then goto continue end
                if (entity_tbl.unique_id and groups[entity_tbl.unique_id]) then
                    if (groups[entity_tbl.unique_id].valid) then
                        local requesting_unit_group = unique_ids[entity_tbl.unique_id]
                        -- if (((requesting_unit_group or requesting_unit_group_placeholder).member_count or math_huge) > (limits[GROUP][surface_name] or 400)) then goto continue end
                        if (    ((requesting_unit_group or requesting_unit_group_placeholder).member_count or max_unit_group_size) >= max_unit_group_size
                            or  ((requesting_unit_group or requesting_unit_group_placeholder).member_count or math_huge) >= (requesting_unit_group or { limit = 0, }).limit or 0
                            or  requesting_unit_group and not requesting_unit_group.enemies[1]
                        ) then
                            if (requesting_unit_group) then
                                group = groups[requesting_unit_group.unique_id] and groups[requesting_unit_group.unique_id].group or nil
                                if (group) then
                                    if (group.valid) then
                                        group.set_command({
                                            type = command_attack_area,
                                            destination = requesting_unit_group.target_position,
                                            radius = 21,
                                        })
                                        group.release_from_spawner()
                                        group.start_moving()

                                        unique_ids[requesting_unit_group.unique_id] = nil
                                        groups[requesting_unit_group.unique_id] = nil

                                        unit_groups = unit_groups or set_game() and attack_groups
                                        unit_groups.count = (unit_groups.count or 1) - 1
                                        if (unit_groups.count < 0) then unit_groups.count = 0 end

                                        settings_map = settings_map or set_game() and settings_map
                                        settings_map.runtime_global = settings_map.runtime_global or {}
                                        if (settings_map.runtime_global[show_attack_group_targets.name]) then game_print({ "messages.entity-gps", "", requesting_unit_group.target_position.x, requesting_unit_group.target_position.y, requesting_unit_group.surface_name }) end
                                    else
                                        groups[requesting_unit_group.unique_id] = nil
                                        unique_ids[requesting_unit_group.unique_id] = nil
                                        unit_groups.count = (unit_groups.count or 1) - 1
                                        if (unit_groups.count < 0) then unit_groups.count = 0 end
                                        -- goto continue
                                    end
                                end
                            end
                        end
                    end
                end

                opts.tick = event.tick
                opts.surface_name = surface_name
                clones = clone_entity(entity, opts)

                if (clones) then
                    num_clones[source][surface_name][entity_tbl.name] = num_clones[source][surface_name][entity_tbl.name] + #clones
                    clone_count = clone_count + #clones
                    group = groups[entity_tbl.unique_id] or nil

                    if (source and group and group.valid) then
                        local add_member = group.add_member
                        for k = 1, #clones, 1 do add_member(clones[k].clone) end

                        if (unique_ids[entity_tbl.unique_id]) then
                            local group_data = unique_ids[entity_tbl.unique_id]
                            if (#(group_data.enemies or {}) > 0) then
                                unique_ids[entity_tbl.unique_id] = nil

                                attack_groups = attack_groups or set_game() and attack_groups
                                attack_groups.unit_group_count = (attack_groups.unit_group_count or 1) - 1
                                if (attack_groups.unit_group_count < 0) then attack_groups.unit_group_count = 0 end
                            end
                        end
                    end
                end
            end

            ::continue::
        end
    end

    ::skip::
    if (entity_queue) then
        entity_queue.first = entity_queue.first or 1
        entity_queue.last = entity_queue.last or 1

        if (entity_queue.first >= entity_queue.last) then
            if ((entity_queue.last - entity_queue.first) == 0) then
                entity_queue.q[1] = entity_queue.q[entity_queue.first]
                entity_queue.q[entity_queue.first] = nil
                entity_queue.first, entity_queue.last = 1, 2
            else
                entities[idx] = nil
            end
        end
    end

    return not skip and (clone_count < clones_per_tick)
end

local FORWARD_SLASH = FORWARD_SLASH
local function find_overlapping_chunks(entity)
    if (not entity or not entity.valid) then return {} end

    local position = entity.position

    local min_chunk_x, min_chunk_y = math_floor((position.x - 2.5) / CHUNK_SIZE), math_floor((position.y - 2.5) / CHUNK_SIZE)
    local max_chunk_x, max_chunk_y = math_floor((position.x + 2.5) / CHUNK_SIZE), math_floor((position.y + 2.5) / CHUNK_SIZE)

    local seen = {}
    local collides = {}
    local collides_count = 0

    for x = min_chunk_x, max_chunk_x, 1 do
        for y = min_chunk_y, max_chunk_y, 1 do
            local xy = x .. FORWARD_SLASH .. y
            if (not seen[xy]) then
                seen[xy] = 1
                collides_count = collides_count + 1
                collides[collides_count] = { x = x, y = y, xy = xy, }
            end
        end
    end

    return collides
end

local SPIDER_UNIT = SPIDER_UNIT
local UNIT_SPAWNER = UNIT_SPAWNER
local entity_types = {
    [UNIT] = true,
    [SPIDER_UNIT] = true,
    [UNIT_SPAWNER] = true,
}
function spawn_service.on_entity_died(event)
    if (not event) then return end
    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local surface = entity.surface
    if (not surface or not surface.valid or not Valid_Surfaces[surface.name]) then return end
    local surface_name = surface.name

    local force = entity.force
    if (not force or not force.valid) then return end

    if (force.name == ENEMY) then
        if (not entity_types[entity.type]) then return end

        if (entity.type == UNIT_SPAWNER) then

            spawner_maps = spawner_maps or set_game() and spawner_maps
            local spawner_map = spawner_maps[surface_name]
            if (not spawner_map) then return end

            local decremented_chunks = {}
            for _, chunk in ipairs(find_overlapping_chunks(entity)) do
                if (spawner_map[chunk.xy]) then
                    spawner_map[chunk.xy].spawner_count = (spawner_map[chunk.xy].spawner_count or 1) - 1
                    decremented_chunks[#decremented_chunks+1] = chunk
                end
            end

            for _, chunk in ipairs(decremented_chunks) do
                if (    chunk.xy
                    and spawner_map[chunk.xy]
                    and (not spawner_map[chunk.xy].spawner_count or spawner_map[chunk.xy].spawner_count < 1)
                ) then
                    spawner_map[chunk.xy] = nil
                end
            end
        end
    else
        chunk_maps = chunk_maps or set_game() and chunk_maps
        local chunk_map = chunk_maps[surface_name]
        local xy = math_floor(entity.position.x / CHUNK_SIZE) .. FORWARD_SLASH .. math_floor(entity.position.y / CHUNK_SIZE)
        local chunk = chunk_map[xy]
        if (not chunk) then return end

        chunk.entity_count = chunk.entity_count or 1
        chunk.entity_count = chunk.entity_count - 1

        if (chunk.entity_count < 1) then
            surfaces = surfaces or set_game() and surfaces
            surfaces[surface_name] = surfaces[surface_name] or {}
            surfaces[surface_name].chunks = surfaces[surface_name].chunks or {}
            local chunks = surfaces[surface_name].chunks

            if (chunk.i) then
                local count = #chunks
                local temp = chunks[count]

                chunks[chunk.i] = temp
                chunks[count] = nil

                if (temp) then temp.i = chunk.i end
            else
                local count = #chunks
                for i = 1, count, 1 do chunks[i].i = i end

                chunk = chunk_map[xy]
                if (chunk and chunk.i) then
                    local temp = chunks[count]

                    chunks[chunk.i] = temp
                    chunks[count] = nil

                    if (temp) then temp.i = chunk.i end
                end
            end

            entity_maps = entity_maps or set_game() and entity_maps
            local entity_map = entity_maps[surface_name]

            entity_map[xy] = nil
            chunk_map[xy] = nil
        end
    end
end


local unit_spawner_type_tbl = { UNIT_SPAWNER, }
local enemy_force_tbl = { ENEMY, }
local player_force_tbl = { ENEMY, NEUTRAL }

local SPAWNED = SPAWNED
function spawn_service.on_entity_spawned(event)
    -- Log.debug("spawn_service.on_entity_spawned")
    -- Log.info(event)

    if (not event or not event.tick) then return end

    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    local surface_name = surface.name
    if (not Valid_Surfaces[surface.name]) then return end

    if (not event.spawner or not event.spawner.valid) then return end

    chunk_maps = chunk_maps or set_game() and chunk_maps
    chunk_maps[surface_name] = chunk_maps[surface_name] or {}

    local position = event.spawner.position
    local x = math_floor(position.x / CHUNK_SIZE)
    local y = math_floor(position.y / CHUNK_SIZE)
    local xy = x .. FORWARD_SLASH .. y

    if (not chunk_maps[surface_name][xy]) then
        local chunk = new_Leaf_Data(Leaf_Data, { x = x, y = y, }, event.tick)
        chunk.xy = xy
        local area = {
            { x = chunk.x * Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE, },
            { x = chunk.x * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, y = chunk.y * Constants.CHUNK_SIZE + Constants.CHUNK_SIZE, },
        }

        surface_funcs = surface_funcs or set_game() and surface_funcs
        surface_funcs[surface_name] = surface_funcs[surface_name] or set_game() and surface_funcs[surface_name]
        chunk.spawner_count = surface_funcs[surface_name].count_entities_filtered({
            area = area,
            type = unit_spawner_type_tbl,
            force = enemy_force_tbl,
        })

        spawner_maps = spawner_maps or set_game() and spawner_maps
        spawner_maps[surface_name] = spawner_maps[surface_name] or {}
        local spawner_map = spawner_maps[surface_name]
        if (chunk.spawner_count > 0) then spawner_map[chunk.xy] = chunk end

        chunk.entity_count = surface_funcs[surface_name].count_entities_filtered({
            area = area,
            name = names,
            type = attack_group_type_blacklist,
            force = player_force_tbl,
            invert = true,
        })

        chunks_arr = chunks_arr or set_game() and chunks_arr
        local chunks = chunks_arr[surface_name] or {}

        chunk_maps[surface_name][chunk.xy] = chunk
        chunk = chunk_maps[surface_name][chunk.xy]
        chunks[#chunks+1] = chunk

        if (chunk.entity_count > 0) then
            attack_groups = attack_groups or set_game() and attack_groups
            local attack_group = attack_groups[surface_name]
            if (attack_group) then
                attack_group.next_chunks = attack_group.next_chunks or {}
                attack_group.next_chunks[#attack_group.next_chunks+1] = chunk
            end

            entity_chunks = entity_chunks or set_game() and entity_chunks
            entity_chunks[surface_name] = entity_chunks[surface_name] or {}
            local entity_chunk_arr = entity_chunks[surface_name]

            entity_chunk_arr[#entity_chunk_arr+1] = chunk_maps[surface_name][chunk.xy]

            entity_maps = entity_maps or set_game() and entity_maps
            entity_maps[surface_name] = entity_maps[surface_name] or {}
            local entity_map = entity_maps[surface_name]

            entity_map[chunk.xy] = chunk_maps[surface_name][chunk.xy]
        end

        if (    chunk.spawner_count > 0
            or  chunk.entity_count > 0
        ) then
            local node = add_node({
                tick = event.tick or 0,
                source_chunk = chunk,
                surface_name = surface_name,
            })

            chunk.parent_node = node
        end
    end

    num_clones = num_clones or set_game() and num_clones
    if (num_clones[SPAWNED][surface_name][entity.name] > (limits[SPAWNED] and limits[SPAWNED][surface_name] and (limits[SPAWNED][surface_name][entity.name] or limits[SPAWNED][surface_name].fallback) or 400)) then return end

    local unit_number = entity.unit_number
    local idx = unit_number % 60 + 1

    entities = entities or set_game() and entities
    entities[idx] = entities[idx] or new_Simple_Queue(Simple_Queue)
    local entity_queue = entities[idx]
    local next_idx = entity_queue.last or 1
    entity_queue.last = next_idx + 1
    entity_queue.q[next_idx] = {
        source = SPAWNED,
        tick = event.tick,
        unit_number = unit_number,
        surface_name = surface_name,
        type = entity.type or UNIT,
        name = entity.name,
    }
end

local BUILT = BUILT
function spawn_service.entity_built(event)
    -- Log.debug("spawn_service.on_entity_spawned")
    -- Log.info(event)

    if (not event or not event.tick) then return end

    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    if (not Valid_Surfaces[surface.name]) then return end

    local surface_name = surface.name

    local spawner = event.spawner
    if (not spawner or not spawner.valid) then return end

    num_clones = num_clones or set_game() and num_clones
    if (num_clones[BUILT][surface_name][entity.name] > (limits[BUILT] and (limits[BUILT][surface_name] or limits[BUILT][surface_name].fallback) or 400)) then return end

    local unit_number = entity.unit_number
    local idx = unit_number % 60 + 1

    entities = entities or set_game() and entities
    entities[idx] = entities[idx] or new_Simple_Queue(Simple_Queue)
    local entity_queue = entities[idx]
    local next_idx = entity_queue.last or 1
    entity_queue.last = next_idx + 1
    entity_queue.q[next_idx] = {
        source = BUILT,
        tick = event.tick,
        unit_number = unit_number,
        surface_name = surface_name,
        type = entity.type or UNIT,
        name = entity.name,
    }
end


local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK.name] = function (event, params) clones_per_tick = params.setting_value or params.setting_constant.default_value or 12 end

local NAUVIS = NAUVIS
local ESCAPED_DASH = ESCAPED_DASH
local UNDERSCORE = UNDERSCORE
for _, planet in ipairs(Planets or { NAUVIS, }) do
    local idx = planet:gsub(ESCAPED_DASH, UNDERSCORE):upper()
    update_settings[(Runtime_Global_Settings_Constants.settings[idx .. "_CLONE_UNITS"] or {}).name or 0] = function (event, params) Clone_Unit_Setting[params.surface_name or ""] = params.setting_value end
    update_settings[(Runtime_Global_Settings_Constants.settings[idx .. "_CLONE_UNIT_GROUPS"] or {}).name or 0] = function (event, params) Clone_Unit_Group_Setting[params.surface_name or ""] = params.setting_value end
    for unit, _ in pairs(Clonable_Units) do
        local idx = (planet:gsub(ESCAPED_DASH, UNDERSCORE):upper() .. "_" .. (unit:match("[a-z]+%-(.*)") or "")):gsub(ESCAPED_DASH, UNDERSCORE):upper() or EMPTY
        if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"]) then
            update_settings[Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES"].name or 0] = function (event, params)
                limits = limits or set_game() and limits
                for unit_name, _ in pairs(Clonable_Units) do
                    if (unit_name == unit or unit_name:find(unit:match("[a-z]+%-(.*)") or "")) then
                        limits[SPAWNED][params.surface_name][unit_name] = params.setting_value or params.setting_constant.default_value
                    end
                end
            end
        end
        if (Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"]) then
            update_settings[(Runtime_Global_Settings_Constants.settings[idx .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name or 0] = function (event, params)
                limits = limits or set_game() and limits
                for unit_name, _ in pairs(Clonable_Units) do
                    if (unit_name == unit or unit_name:find(unit:match("[a-z]+%-(.*)") or "")) then
                        limits[GROUP][params.surface_name][unit_name] = params.setting_value or params.setting_constant.default_value
                    end
                end
            end
        end
    end
    update_settings[(Runtime_Global_Settings_Constants.settings["FALLBACK_MAXIMUM_NUMBER_OF_SPAWNED_GROUP_CLONES"] or {}).name or 0] = function (event, params)
        limits = limits or set_game() and limits
        limits[SPAWNED] = limits[SPAWNED] or {}
        limits[SPAWNED][params.surface_name] = limits[SPAWNED][params.surface_name] or {}
        limits[SPAWNED][params.surface_name].fallback = params.setting_value or params.setting_constant.default_value
    end
    update_settings[(Runtime_Global_Settings_Constants.settings["FALLBACK_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES"] or {}).name or 0] = function (event, params)
        limits = limits or set_game() and limits
        limits[GROUP] = limits[GROUP] or {}
        limits[GROUP][params.surface_name] = limits[GROUP][params.surface_name] or {}
        limits[GROUP][params.surface_name].fallback = params.setting_value or params.setting_constant.default_value
    end
end
update_settings[0] = nil

local STRING = Types.STRING
function spawn_service.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = spawn_service.on_runtime_mod_setting_changed
})

function spawn_service.init(__storage) storage = __storage or _ENV.storage end

return spawn_service