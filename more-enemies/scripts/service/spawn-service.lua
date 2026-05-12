local storage
local difficulties
local entities
local groups
local num_clones
local pathables
local stats
local surfaces
local unique_ids
local unit_groups

local game
local get_entity_by_unit_number
local game_print

local function set_game(__game, __storage)
    storage = __storage or _ENV.storage

    storage.stats = storage.stats or {}
    stats = storage.stats

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.entities = storage.entities or {}
    entities = storage.entities

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.pathables = storage.pathables or {}
    pathables = storage.pathables

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    storage.unique_ids = storage.unique_ids or {}
    unique_ids = storage.unique_ids

    --[[ game ]]
    game = __game or _ENV.game
    get_entity_by_unit_number = game.get_entity_by_unit_number
    game_print = game.print

    Set_Num_Clones()

    return game
end

local Set_Num_Clones = Set_Num_Clones

local ipairs = ipairs

local math_floor = math.floor
local math_huge = math.huge

local table_insert = table.insert
local table_remove = table.remove
local type = type

local defines = defines
local command_attack_area = defines.command.attack_area
local command_build_base = defines.command.build_base

local Constants = Constants
local Mod_Settings = Mod_Settings
local Valid_Surfaces = Valid_Surfaces

local _Settings_Service = Settings_Service
local Settings_Service = require("scripts.service.settings-service")
local get_clone_unit_group_setting = Settings_Service.get_clone_unit_group_setting
local get_difficulty = Settings_Service.get_difficulty
local get_do_evolution_factor = Settings_Service.get_do_evolution_factor

local Spawn_Utils = require("scripts.utils.spawn-utils")
local calc_evolution_multiplier = Spawn_Utils.calc_evolution_multiplier
local clone_entity = Spawn_Utils.clone_entity

local Limits = Limits

local Valid_Sources = Valid_Sources

local clones_per_tick = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.CLONES_PER_TICK.name, }) or Mod_Settings.CLONES_PER_TICK.default_value
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
local use_evolution_factor = {}

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

local ENEMY, GROUP, UNIT, UNIT_GROUP = "enemy", "group", "unit", "unit-group"

local clone_count = 0
function spawn_service.on_tick(event)
    -- log_error("spawn_service.on_tick")
    -- Log.info(event)

    game = game or set_game()

    event = event or { tick = game and game.tick or set_game().tick, }

    num_clones = num_clones or Set_Num_Clones()

    clone_count = 0
    local idx = event.tick % 60 + 1
    if (pathables[idx]) then
        if (not pathables[idx][1]) then
            pathables[idx] = nil
        else
            unit_groups.i, unit_groups.cap = 1, 8
            unit_groups.loop_cap, unit_groups.loops = unit_groups.cap * 1.5, 0

            local pathable = pathables[idx]

            local requesting_unit_group, release = nil, false
            local unit_group = nil

            while unit_groups.i < unit_groups.cap and unit_groups.loops < unit_groups.loop_cap do
                release = false
                requesting_unit_group = pathable[unit_groups.i]
                if (not requesting_unit_group) then break end

                if (not requesting_unit_group.surface_name) then
                    table_remove(pathable, unit_groups.i)
                    unit_groups.loop_cap = unit_groups.loop_cap - 1
                    goto skip
                end

                if (not groups[requesting_unit_group.unique_id] or not groups[requesting_unit_group.unique_id].valid) then
                    table_remove(pathable, unit_groups.i)
                    unit_groups.loop_cap = unit_groups.loop_cap - 1
                    goto skip
                end

                do
                    local unit_number = table_remove(requesting_unit_group.enemies)
                    if (not unit_number) then
                        table_remove(pathable, unit_groups.i)
                        release = true
                        goto release_group
                    else
                        local limit = requesting_unit_group.limit or 0
                        local add_member = groups[requesting_unit_group.unique_id].add_member
                        local enemy, uidx = nil, unit_number % 60 + 1
                        unit_groups.j = 1

                        local num_entities = #(entities[uidx] or (function (uidx) entities[uidx] = {}; return entities[uidx] end)(uidx))
                        if (num_entities >= (Limits[GROUP] and Limits[GROUP][requesting_unit_group.surface_name] or 400)) then
                            table_remove(pathable, unit_groups.i)
                            unit_groups.loop_cap = unit_groups.loop_cap - 1
                            goto skip
                        end

                        while unit_groups.j < unit_groups.cap do
                            if (unit_groups.j >= limit or (unit_groups.j + requesting_unit_group.member_count) >= max_unit_group_size) then
                                table_remove(pathable, unit_groups.i)
                                release = true
                                goto release_group
                            end

                            if (num_clones[GROUP][requesting_unit_group.surface_name] > (Limits[GROUP] and Limits[GROUP][requesting_unit_group.surface_name] or 400)) then
                                table_remove(pathable, unit_groups.i)
                                unit_groups.loop_cap = unit_groups.loop_cap - 1
                                goto skip
                            end

                            enemy = get_entity_by_unit_number(unit_number)
                            if (enemy and enemy.valid) then
                                enemy.release_from_spawner()
                                enemy.ai_settings.allow_try_return_to_spawner = false
                                enemy.ai_settings.join_attacks = true
                                add_member(enemy)
                                requesting_unit_group.member_count = requesting_unit_group.member_count + 1

                                clone_count = clone_count + 1
                                num_entities = num_entities + 1

                                uidx = unit_number % 60 + 1

                                table_insert(entities[uidx] or (function (arr)
                                        arr[1][arr[2]] = {}
                                        return arr[1][arr[2]]
                                    end)({ entities, uidx, }),
                                    {
                                        source = GROUP,
                                        unique_id = requesting_unit_group.unique_id,
                                        tick = event.tick,
                                        unit_number = unit_number,
                                        surface_name = requesting_unit_group.surface_name,
                                    }
                                )

                                if (    num_entities >= (Limits[GROUP] and Limits[GROUP][requesting_unit_group.surface_name] or 400)
                                    or  requesting_unit_group.member_count >= (requesting_unit_group.limit or max_unit_group_size or 0)
                                    or  not requesting_unit_group.enemies[1]
                                ) then
                                    table_remove(pathable, unit_groups.i)
                                    release = true
                                    goto release_group
                                end
                            end

                            unit_number = table_remove(requesting_unit_group.enemies)
                            unit_groups.j = unit_groups.j + 1
                            if (not unit_number) then
                                table_remove(pathable, unit_groups.i)
                                unit_groups.loop_cap = unit_groups.loop_cap - 1
                                goto skip
                            end
                        end

                        goto continue
                    end
                end

                ::release_group::

                if (release) then
                    unit_group = nil
                    unit_group = groups[requesting_unit_group.unique_id]

                    if (not unit_group or not unit_group.valid) then
                        unit_groups.loop_cap = unit_groups.loop_cap - 1
                        goto skip
                    else
                        unit_group.set_command({
                            type = command_attack_area,
                            destination = requesting_unit_group.target_position,
                            radius = 21,
                        })
                        if (unit_group.valid) then unit_group.release_from_spawner() end
                        if (unit_group.valid) then unit_group.start_moving() end

                        table_remove(pathable, unit_groups.i)
                        unit_groups.cap = unit_groups.cap - 1
                        unit_groups.loop_cap = unit_groups.loop_cap - 1

                        unique_ids[requesting_unit_group.unique_id or 0] = nil
                        groups[requesting_unit_group.unique_id or 0] = nil

                        clone_count = clone_count + 1

                        --[[ TODO: make configurable ]]
                        -- game_print({ "messages.entity-gps", "", requesting_unit_group.target_position.x, requesting_unit_group.target_position.y, requesting_unit_group.surface_name })
                    end

                    goto skip
                end

                ::continue::
                unit_groups.i = unit_groups.i + 1

                ::skip::
                unit_groups.loops = unit_groups.loops + 1
            end
        end
    end

    if (not entities[idx]) then return end
    if (not entities[idx][1]) then
        entities[idx] = nil
        return
    end
    local entity_arr = entities[idx]
    local entity_tbl, entity = nil, nil
    local source, surface_name = nil, nil
    local clones = nil
    local opts = {}
    local evolution_factors = {}
    local evolution_multipliers = {}
    for i = 1, (entity_arr.count or (function (arr)
        arr[1].count = arr[2]
        return arr[2]
    end)({ entity_arr, #entity_arr, })), 1 do
        if (i > clones_per_tick or clone_count > clones_per_tick) then return end

        entity_tbl, entity = table_remove(entity_arr, 1), nil
        entity_arr.count = entity_arr.count - 1
        if (    not entity_tbl
            or  not entity_tbl.unit_number
            or  not entity_tbl.surface_name
        ) then
            goto continue
        else
            if (entity_arr.count < 1) then entities[idx] = nil end
            if (not entity_tbl.source or not Valid_Sources[entity_tbl.source]) then goto continue end
            if (not entity_tbl.surface_name or not Valid_Surfaces[entity_tbl.surface_name]) then goto continue end

            source, surface_name = entity_tbl.source, entity_tbl.surface_name

            num_clones[source] = num_clones[source] or {}
            num_clones[source][surface_name] = num_clones[source][surface_name] or 0

            if (num_clones[source][surface_name] > (Limits[source] and Limits[source][surface_name] or 400)) then goto continue end

            opts.clone_settings = {
                unit = Clone_Unit_Setting[surface_name] or 1,
                unit_group = Clone_Unit_Group_Setting[surface_name] or 1,
                type = entity_tbl.source == GROUP and UNIT_GROUP or UNIT
            }

            entity = game and get_entity_by_unit_number(entity_tbl.unit_number) or set_game().get_entity_by_unit_number(entity_tbl.unit_number)
            if (not entity or not entity.valid) then goto continue end
            if (entity_tbl.unique_id and groups[entity_tbl.unique_id]) then
                if (groups[entity_tbl.unique_id].valid) then
                    local requesting_unit_group = unique_ids[entity_tbl.unique_id]
                    if (((requesting_unit_group or requesting_unit_group_placeholder).member_count or math_huge) > (Limits[GROUP][surface_name] or 400)) then goto continue end
                    if (    ((requesting_unit_group or requesting_unit_group_placeholder).member_count or max_unit_group_size) >= max_unit_group_size
                        or  ((requesting_unit_group or requesting_unit_group_placeholder).member_count or math_huge) >= (requesting_unit_group or { limit = 0, }).limit or 0
                        or  requesting_unit_group and not requesting_unit_group.enemies[1]
                    ) then
                        if (requesting_unit_group) then
                            if (groups[requesting_unit_group.unique_id] and groups[requesting_unit_group.unique_id].valid) then
                                groups[requesting_unit_group.unique_id].set_command({
                                    type = command_attack_area,
                                    destination = requesting_unit_group.target_position,
                                    radius = 21,
                                })
                                groups[requesting_unit_group.unique_id].release_from_spawner()
                                groups[requesting_unit_group.unique_id].start_moving()

                                unique_ids[requesting_unit_group.unique_id] = nil
                                groups[requesting_unit_group.unique_id] = nil

                                --[[ TODO: make configurable ]]
                                -- game_print({ "messages.entity-gps", "", requesting_unit_group.target_position.x, requesting_unit_group.target_position.y, requesting_unit_group.surface_name })
                            end
                        end
                    end
                end
            end

            opts.tick = event.tick
            opts.surface_name = surface_name
            evolution_factors[surface_name] = evolution_factors[surface_name] or entity.force.get_evolution_factor(surface_name)
            evolution_multipliers[surface_name] = evolution_multipliers[surface_name] or calc_evolution_multiplier(difficulties[surface_name], use_evolution_factor and (use_evolution_factor[surface_name] or (function (arr)
                    arr[1][arr[2]] = arr[3]
                    return arr[3]
                end)({ use_evolution_factor, surface_name, get_do_evolution_factor(surface_name), }))
                and  (evolution_factors[surface_name] or (function (arr)
                        arr[1][arr[2]] = arr[3]
                        return arr[3]
                    end)({ evolution_factors, surface_name, get_do_evolution_factor(surface_name), }))
                or 0
            )

            difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])
            opts.evolution_multiplier = evolution_multipliers[surface_name]
            opts.use_evolution_factor = use_evolution_factor[surface_name]
            clones = clone_entity(entity, opts)

            if (clones) then
                num_clones[source][surface_name] = num_clones[source][surface_name] + #clones
                clone_count = clone_count + #clones

                if (source and groups[entity_tbl.unique_id] and groups[entity_tbl.unique_id].valid) then
                    local add_member = groups[entity_tbl.unique_id].add_member
                    for k = 1, #clones, 1 do
                        add_member(clones[k].clone)
                    end
                end
            end
        end

        ::continue::
    end

    return clone_count < clones_per_tick
end

local entity_types = {
    ["unit"] = true,
    ["spider-unit"] = true,
    ["unit-spawner"] = true,
}
function spawn_service.on_entity_died(event)
    if (not event) then return end
    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local force = entity.force
    if (not force or not force.valid) then return end

    if (force.name == ENEMY) then
        if (not entity_types[entity.type]) then return end

        local surface = entity.surface
        if (not surface or not surface.valid) then return end
        local surface_name = surface.name

        if (entity.type == "unit-spawner") then
            surfaces = surfaces or set_game() and surfaces
            surfaces[surface_name] = surfaces[surface_name] or {}
            surfaces[surface_name].chunks = surfaces[surface_name].chunks or {}
            local chunks = surfaces[surface_name].chunks

            surfaces[surface_name].spawner_map = surfaces[surface_name].spawner_map or {}
            local spawner_map = surfaces[surface_name].spawner_map

            local xy = math_floor(entity.position.x / Constants.CHUNK_SIZE) .. "/" .. math_floor(entity.position.y / Constants.CHUNK_SIZE)

            local chunk = spawner_map[xy]
            if (not chunk) then return end

            chunk.spawner_count = chunk.spawner_count or 1
            chunk.spawner_count = chunk.spawner_count - 1

            if (chunk.spawner_count < 1) then
                for i, v in ipairs(chunks) do
                    v.xy = v.xy or (v.x .. "/" .. v.y)
                    if (v.xy == xy) then
                        spawner_map[v.xy] = nil
                        break
                    end
                end
            end
        else
            local source = entity.commandable and entity.commandable.valid and not entity.commandable.spawner and GROUP or UNIT

            num_clones = num_clones or Set_Num_Clones()
            num_clones[source] = num_clones[source] or {}
            num_clones[source][surface_name] = num_clones[source][surface_name] or 0
            if (num_clones[source][surface_name] > 0) then
                num_clones[source][surface_name] = num_clones[source][surface_name] - 1
            else
                num_clones[source][surface_name] = 0
            end
        end
    else
        local surface = entity.surface
        if (not surface or not surface.valid) then return end
        local surface_name = surface.name

        surfaces[surface_name] = surfaces[surface_name] or {}
        surfaces[surface_name].chunk_map = surfaces[surface_name].chunk_map or {}

        local chunk_map = surfaces[surface_name].chunk_map
        local chunk = chunk_map[math_floor(entity.position.x / Constants.CHUNK_SIZE) .. "/" .. math_floor(entity.position.y / Constants.CHUNK_SIZE)]
        if (not chunk) then return end

        if (chunk.entity_count and chunk.entity_count >= 1) then
            chunk.entity_count = chunk.entity_count - 1
        else
            local chunks = surfaces[surface_name].chunks or surfaces[surface_name].chunks or {}
            chunk.xy = chunk.xy or (chunk.x .. "/" .. chunk.y)
            for i, v in ipairs(chunks) do
                v.xy = v.xy or (v.x .. "/" .. v.y)
                if (v.xy == chunk.xy) then
                    chunk_map[v.xy] = nil
                    table_remove(chunks, i)
                    break
                end
            end
        end
    end
end

local SPAWNED = "spawned"
function spawn_service.on_entity_spawned(event)
    -- Log.debug("spawn_service.on_entity_spawned")
    -- Log.info(event)

    if (not event or not event.tick) then return end

    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    if (not Valid_Surfaces[surface.name]) then return end

    local surface_name = surface.name

    if (not event.spawner or not event.spawner.valid) then return end

    num_clones = num_clones or Set_Num_Clones()
    if (num_clones[SPAWNED][surface_name] > (Limits[SPAWNED] and Limits[SPAWNED][surface_name] or 400)) then return end

    local unit_number = entity.unit_number
    local idx = unit_number % 60 + 1

    game = game or set_game()
    entities[idx] = entities[idx] or {}
    table_insert(entities[idx],
        {
            source = SPAWNED,
            tick = event.tick,
            unit_number = unit_number,
            surface_name = surface_name,
            type = entity.type or "unit",
        }
    )
    entities[idx].count = (entities[idx].count or 0) + 1
end

local BUILT = "built"
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

    num_clones = num_clones or Set_Num_Clones()
    if (num_clones[BUILT][surface_name] > (Limits[BUILT] and Limits[BUILT][surface_name] or 400)) then return end

    local unit_number = entity.unit_number
    local idx = unit_number % 60 + 1

    game = game or set_game()
    entities[idx] = entities[idx] or {}
    table_insert(entities[idx],
        {
            source = BUILT,
            tick = event.tick,
            unit_number = unit_number,
            surface_name = surface_name,
            type = entity.type or "unit",
        }
    )
    entities[idx].count = (entities[idx].count or 0) + 1
end

function spawn_service.on_runtime_mod_setting_changed(event)
    -- Log.debug("spawn_service.on_runtime_mod_setting_changed")
    -- Log.info(event)

    if (not event.setting or type(event.setting) ~= "string") then return end
    if (not event.setting_type or type(event.setting_type) ~= "string") then return end

    if (not (event.setting:find("more-enemies-", 1, true) == 1)) then return end

    if (event.setting == Mod_Settings.CLONES_PER_TICK.name) then
        clones_per_tick = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.CLONES_PER_TICK.name, reindex = true, })
    elseif (event.setting == Mod_Settings.CLONE_NAUVIS_UNITS.name) then
        Clone_Unit_Setting[Constants.DEFAULTS.planets.nauvis.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["CLONE_NAUVIS_UNITS"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.CLONE_GLEBA_UNITS.name) then
        Clone_Unit_Setting[Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["CLONE_GLEBA_UNITS"].name, reindex = true, }) or 1
    elseif (event.setting:find("CLONE_", 1, true) and event.setting:find("_UNIT_GROUPS", -12, true)) then
        local name = event.setting:match("CLONE_([%w%_]+)_UNIT_GROUPS")
        if (name) then
            Clone_Unit_Group_Setting[name:lower()] = get_clone_unit_group_setting(name:lower()) or 1
        end
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS.name) then
        Limits[SPAWNED][Constants.DEFAULTS.planets.nauvis.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA.name) then
        Limits[SPAWNED][Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS.name) then
        Limits[GROUP][Constants.DEFAULTS.planets.nauvis.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA.name) then
        Limits[GROUP][Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name) then
        max_unit_group_size = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, reindex = true, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name) then
        Limits[BUILT] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name, reindex = true, }) or Mod_Settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.default_value
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_MODDED_CLONES.name) then
        local name = event.setting:match("([%w%_]+)_DO_EVOLUTION_FACTOR")
        if (name) then
            use_evolution_factor[name:lower()] = get_do_evolution_factor(name:lower())
        end
    end
end
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "spawn_service.on_runtime_mod_setting_changed",
    func_name = "spawn_service.on_runtime_mod_setting_changed",
    func = spawn_service.on_runtime_mod_setting_changed,
})

function spawn_service.init(__storage) storage = __storage end

return spawn_service