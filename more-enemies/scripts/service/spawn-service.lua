local storage
local game
local get_entity_by_unit_number
local num_clones

local function set_game(__game)
    game = __game or _ENV.game
    get_entity_by_unit_number = game.get_entity_by_unit_number

    return game
end

local Set_Num_Clones = Set_Num_Clones

local ipairs = ipairs

local math_floor = math.floor

local table_insert = table.insert
local table_remove = table.remove
local type = type

local Constants = Constants
local Forces = Forces
local Mod_Settings = Mod_Settings
local Valid_Surfaces = Valid_Surfaces

local _Settings_Service = Settings_Service
local Settings_Service = require("scripts.service.settings-service")
local get_clone_unit_group_setting = Settings_Service.get_clone_unit_group_setting

local Spawn_Utils = require("scripts.utils.spawn-utils")
local clone_entity = Spawn_Utils.clone_entity

local Clone_Unit_Setting = Clone_Unit_Setting
local Clone_Unit_Group_Setting = Clone_Unit_Group_Setting
local Max_Num_Unit_Clones = Max_Num_Unit_Clones
local Max_Num_Unit_Group_Clones = Max_Num_Unit_Group_Clones

local Limits = Limits

local Valid_Sources = Valid_Sources

local clones_per_tick = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.CLONES_PER_TICK.name, }) or Mod_Settings.CLONES_PER_TICK.default_value
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

local spawn_service = {}

spawn_service.entity_list = {}
spawn_service.entity_list_index = {}

spawn_service.entity = {}
spawn_service.entity_index = {}

spawn_service.BREAM = {}
spawn_service.BREAM.unit_group = nil
spawn_service.BREAM.clones_index = nil
spawn_service.BREAM.last_ran = 0

function spawn_service.on_tick(event)
    -- log_error("spawn_service.on_tick")
    -- Log.info(event)

    event = event or { tick = game and game.tick or set_game().tick, }
    local tick = event.tick

    storage.entities = storage.entities or {}
    local entities = storage.entities

    num_clones = num_clones or Set_Num_Clones()
    local idx = tick % 60 + 1
    if (not entities[idx]) then return end
    if (not entities[idx][1]) then
        entities[idx] = nil
        return
    end
    local entity_tbl, entity = nil, nil
    local source, surface_name = nil, nil
    local clones = nil
    local opts = {}
    for i = 1, #entities, 1 do
        if (i > clones_per_tick) then break end

        entity_tbl, entity = table_remove(entities[idx], i), nil
        if (    not entity_tbl
            or  not entity_tbl.unit_number
            or  not entity_tbl.surface_name
        ) then
            goto continue
        else
            if (not entity_tbl.source or not Valid_Sources[entity_tbl.source]) then goto continue end
            if (not entity_tbl.surface_name or not Valid_Surfaces[entity_tbl.surface_name]) then goto continue end

            source, surface_name = entity_tbl.source, entity_tbl.surface_name

            num_clones[source] = num_clones[source] or {}
            num_clones[source][surface_name] = num_clones[source][surface_name] or 0

            if (num_clones[source][surface_name] > (Limits[source] and Limits[source][surface_name] or 400)) then goto continue end

            opts.clone_settings = {
                unit = Clone_Unit_Setting[surface_name] or 1,
                unit_group = Clone_Unit_Group_Setting[surface_name] or 1,
                type = entity_tbl.source == "group" and "unit-group" or "unit"
            }

            entity = game and get_entity_by_unit_number(entity_tbl.unit_number) or set_game().get_entity_by_unit_number(entity_tbl.unit_number)
            if (not entity or not entity.valid) then goto continue end
            if (entity_tbl.group and entity_tbl.group.valid and #entity_tbl.group.commandable_members >= max_unit_group_size) then goto continue end

            opts.tick = tick
            opts.surface_name = surface_name
            clones = clone_entity(entity, opts)

            if (clones) then
                num_clones[source][surface_name] = num_clones[source][surface_name] + #clones

                if (source and entity_tbl.group and entity_tbl.group.valid) then
                    local add_member = entity_tbl.group.add_member
                    for k = 1, #clones, 1 do
                        add_member(clones[k].clone)
                    end
                end
            end
        end

        ::continue::
    end
end

function spawn_service.on_entity_died(event)
    if (not event) then return end
    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local force = entity.force
    if (not force or not force.valid) then return end

    local surface = entity.surface
    if (not surface or not surface.valid or not Valid_Surfaces[surface.name]) then return end
    local surface_name = surface.name

    if (force.name == "enemy") then
        local source = entity.commandable and "group" or "unit"

        num_clones = num_clones or Set_Num_Clones()
        num_clones[source] = num_clones[source] or {}
        num_clones[source][surface_name] = num_clones[source][surface_name] or 0
        if (num_clones[source][surface_name] > 0) then
            num_clones[source][surface_name] = num_clones[source][surface_name] - 1
        else
            num_clones[source][surface_name] = 0
        end
    elseif (not Forces[force.name]) then
        storage.surfaces = storage.surfaces or {}
        storage.surfaces[surface_name] = storage.surfaces[surface_name] or {}
        storage.surfaces[surface_name].chunk_map = storage.surfaces[surface_name].chunk_map or {}

        local chunk_map = storage.surfaces[surface_name].chunk_map
        local chunk = chunk_map[math_floor(entity.position.x / Constants.CHUNK_SIZE) .. "/" .. math_floor(entity.position.y / Constants.CHUNK_SIZE)]

        if (not chunk) then return end
        if (chunk.entity.count > 1) then
            chunk.entity_count = chunk.entity_count - 1
        else
            local chunks = storage.surfaces[surface_name].chunks or storage.surfaces[surface_name].chunks or {}
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

    if (not event or not event.name) then return end

    local entity = event.entity
    if (not entity or not entity.valid) then return end

    local surface = entity.surface
    if (not surface or not surface.valid) then return end
    if (not Valid_Surfaces[surface.name]) then return end

    local surface_name = surface.name

    local spawner = event.spawner
    if (not spawner or not spawner.valid) then return end

    num_clones = num_clones or Set_Num_Clones()
    if (num_clones[SPAWNED][surface_name] > (Limits[SPAWNED] and Limits[SPAWNED][surface_name] or 400)) then return end

    game = game or set_game()
    local tick = event.tick or game.tick
    if (not tick) then return end

    local unit_number = entity.unit_number
    local idx = unit_number % 60 + 1

    storage.entities = storage.entities or {}
    storage.entities[idx] = storage.entities[idx] or {}
    table_insert(storage.entities[idx],
        {
            source = SPAWNED,
            tick = tick,
            unit_number = unit_number,
            position = entity.position.x .. "/" .. entity.position.y,
            surface_name = surface_name,
            spawner_unit_number = spawner.unit_number,
            spawner_position = spawner.position.x .. "/" .. spawner.position.y,
        }
    )
end

local BUILT = "built"
function spawn_service.entity_built(event)
    -- Log.debug("spawn_service.on_entity_spawned")
    -- Log.info(event)

    if (not event or not event.name) then return end

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

    game = game or set_game()
    local tick = event.tick or game.tick
    if (not tick) then return end

    local unit_number = entity.unit_number
    local idx = unit_number % 60 + 1

    storage.entities = storage.entities or {}
    storage.entities[idx] = storage.entities[idx] or {}
    table_insert(storage.entities[idx],
        {
            source = BUILT,
            tick = tick,
            unit_number = unit_number,
            position = entity.position.x .. "/" .. entity.position.y,
            surface_name = surface_name,
            spawner_unit_number = spawner.unit_number,
            spawner_position = spawner.position.x .. "/" .. spawner.position.y,
        }
    )
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
        Max_Num_Unit_Clones[Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA.name) then
        Max_Num_Unit_Clones[Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS.name) then
        Max_Num_Unit_Group_Clones[Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA.name) then
        Max_Num_Unit_Group_Clones[Constants.DEFAULTS.planets.gleba.string_val] = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings["MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA"].name, reindex = true, }) or 1
    elseif (event.setting == Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name) then
        max_unit_group_size = _Settings_Service.get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, reindex = true, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
    end
end
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "spawn_service.on_runtime_mod_setting_changed",
    func_name = "spawn_service.on_runtime_mod_setting_changed",
    func = spawn_service.on_runtime_mod_setting_changed,
})

function spawn_service.init(__storage)
    storage = __storage
end

return spawn_service