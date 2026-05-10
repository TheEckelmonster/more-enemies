local storage
local game
local get_surface

local function set_game(__game)
    game = __game or _ENV.game
    get_surface = game.get_surface

    return game
end

local ipairs = ipairs
local type = type

local defines = defines
local command_attack_area = defines.command.attack_area
local command_build_base = defines.command.build_base
local distraction_by_damage = defines.distraction.by_damage

local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local Data_Utils = Data_Utils
local Constants = Constants
local Mod_Settings = Mod_Settings

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Log = Log

local Attack_Group_Utils = require("scripts.utils.attack-group-utils")
local get_enemy = Attack_Group_Utils.get_enemy
local get_target_entity = Attack_Group_Utils.get_target_entity
local _Settings_Service = Settings_Service
local get_runtime_global_setting = _Settings_Service.get_runtime_global_setting
local Settings_Service = require("scripts.service.settings-service")
local get_attack_group_peace_time = Settings_Service.get_attack_group_peace_time
local get_difficulty = Settings_Service.get_difficulty
local get_maximum_attack_group_delay = Settings_Service.get_maximum_attack_group_delay
local get_minimum_attack_group_delay = Settings_Service.get_minimum_attack_group_delay
local get_spawn_attack_group_probability_modifier = Settings_Service.get_spawn_attack_group_probability_modifier

local attack_group_peace_time = {}
for name, _ in pairs(Constants.DEFAULTS.planets) do
    attack_group_peace_time[name] = get_attack_group_peace_time(name) * Constants.time.TICKS_PER_MINUTE
end

local delay_min = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MINIMUM_ATTACK_GROUP_DELAY.name, }) or Mod_Settings.MINIMUM_ATTACK_GROUP_DELAY.default_value
local delay_max = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MAXIMUM_ATTACK_GROUP_DELAY.name, }) or Mod_Settings.MAXIMUM_ATTACK_GROUP_DELAY.default_value
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

local BOUNDING_BOX = {{-0.5, -0.5}, {0.5, 0.5},}
local COLLISION_MASK = {
    layers = {
        ["water_tile"] = true,
        ["object"] = true,
        ["empty_space"] = true,
        ["lava_tile"] = true,
        ["cliff"] = true,
        ["out_of_map"] = true,
    }
}
local PATHFINDER_FLAGS = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, }

local attack_group_service = {}

function attack_group_service.do_random_attack_group(params)
    -- Log.debug("attack_group_service.do_random_attack_group")
    -- Log.info(params)

    if (not params) then return end
    if (not params.attack_group) then return end
    local attack_group = params.attack_group
    if (not attack_group.tick) then
        attack_group.tick = params.tick or 0
        return
    end

    if (not params.surface_name) then return end
    local surface_name = params.surface_name

    local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    storage.surfaces = storage.surfaces or {}
    storage.surfaces[surface_name] = storage.surfaces[surface_name] or {}
    attack_group.chunks = attack_group.chunks or deepcopy(storage.surfaces[surface_name].chunks)

    local chunks = attack_group.chunks or {}
    if (#chunks < 1) then
        attack_group.chunks = deepcopy(storage.surfaces[surface_name].chunks)
        return
    end
    local chunk = table_remove(chunks, math_random(#chunks))
    if (not chunk) then return end

    local enemies = get_enemy({ surface_name = surface_name, chunk = chunk, tick = params.tick or 0, }) or {}
    if (not enemies[1] or not enemies[1].valid) then return end

    storage.difficulties = storage.difficulties or {}
    storage.difficulties[surface_name] = storage.difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])

    local selected_difficulty = storage.difficulties[surface_name]
    if (not selected_difficulty) then return end

    local evolution_factor = enemies[1].force.get_evolution_factor(enemies[1].surface)
    evolution_factor = evolution_factor ^ (1 / selected_difficulty.value)

    -- Maximum probability of an attack group spawning at 100% (1) evolution factor
    local max_probability = 1 - (1 / selected_difficulty.value)

    if (max_probability < 0) then max_probability = 0 end
    max_probability = max_probability * get_spawn_attack_group_probability_modifier(surface_name)

    local threshold = max_probability * evolution_factor
    selected_difficulty.retries = selected_difficulty.retries or math_floor((selected_difficulty.value * 3) ^ 0.5)

    local proceed = false
    for i = 1, selected_difficulty.retries, 1 do
        if (math_random() < threshold) then
            proceed = true
            break
        end
        threshold = threshold ^ 0.9
    end

    if (not proceed) then return end

    local limit = 2 * (selected_difficulty.attack_group_limit or (function (param)
        selected_difficulty.attack_group_limit = param
        return param
    end)(selected_difficulty.value * selected_difficulty.radius_modifier)) * evolution_factor + math_random(#enemies)

    local target_entities = get_target_entity({
        chunk = chunk,
        surface = surface,
        limit = 1 + limit * evolution_factor,
    }) or {}

    local target_entity = nil
    if (#target_entities > 0) then
        -- Log.error("target_entities = " .. #target_entities)
        target_entity = target_entities[math_random(#target_entities)]
        if (not target_entity or not target_entity.valid) then return end
    else
        return
    end

    local target_position = target_entity.position

    local path_id = enemies[1].surface.request_path({
        bounding_box = BOUNDING_BOX,
        collision_mask = COLLISION_MASK,
        start = enemies[1].position,
        goal = target_position,
        force = enemies[1].force,
        radius = 12,
        pathfinder_flags = PATHFINDER_FLAGS,
        can_open_gates = false,
        path_resolution_modifier = -1,
        max_gap_distance = 0,

    })

    -- log(serpent.block(path_id))

    storage.unit_groups = storage.unit_groups or {}
    local unit_groups = storage.unit_groups
    unit_groups[path_id] = { enemies = {}, target_position = target_position, limit = limit, path_id = path_id, }

    local unit_group_enemies = unit_groups[path_id].enemies
    for i = 1, #enemies, 1 do
        if (i >= limit or i >= max_unit_group_size) then break end
        if (enemies[i] and enemies[i].valid) then
            table_insert(unit_group_enemies, enemies[i].unit_number)
        else
            table_remove(enemies, i)
        end
    end


    -- -- Log.error("random: target_entity")
    -- -- Log.error(target_entity)
    -- -- game.print({ "messages.entity-gps", target_entity.name, target_entity.position.x, target_entity.position.y, target_entity.surface.name })

    -- local unit_group = enemies[1].surface.create_unit_group({ position = enemies[1].position})
    -- if (not unit_group or not unit_group.valid) then return end

    -- if (target_entity and target_entity.valid) then
    --     local add_member = unit_group.add_member
    --     for i, v in ipairs(enemies) do
    --         if (v and v.valid) then
    --             v.release_from_spawner()
    --             v.ai_settings.allow_try_return_to_spawner = false
    --             v.ai_settings.join_attacks = true
    --             add_member(v)
    --         end
    --         if (i >= limit or i >= max_unit_group_size) then break end
    --     end

    --     unit_group.set_command({
    --         type = command_attack_area,
    --         destination = target_position,
    --         radius = 21,
    --         distraction = distraction_by_damage,
    --     })
    --     unit_group.release_from_spawner()
    --     unit_group.start_moving()
    --     -- Log.error("unit group released")
    -- else
    --     Log.error("no target; destroying")
    --     unit_group.destroy()
    -- end

    -- attack_group.radius = attack_group.radius ^ 0.5

    if (delay_min > delay_max) then delay_min = delay_max end
    if (delay_max < delay_min ) then delay_max = delay_min end

    local delay = math_random(delay_min, delay_max)

    if (selected_difficulty and selected_difficulty.value and selected_difficulty.value > 0) then
        delay = delay / ((selected_difficulty.radius_modifier ^ 1.5) * (0.5 + ((evolution_factor ^ 0.75) / 2)))
    end

    attack_group.tick = (params.tick or 0) + delay
end

function attack_group_service.on_script_path_request_finished(event)
    -- log(serpent.block(event))

    if (not event) then return end

    -- log(serpent.block(event.id))
    -- log(serpent.block(event.try_again_later))
    if (event.try_again_later) then return end

    local id = event.id
    if (not id) then return end

    storage.unit_groups = storage.unit_groups or {}

    local requesting_unit_group = storage.unit_groups[id]
    if (not requesting_unit_group) then return end

    storage.unit_groups[id] = nil
    if (not event.path) then return end

    local get_entity_by_unit_number = (game or set_game()).get_entity_by_unit_number

    local enemy = get_entity_by_unit_number(requesting_unit_group.enemies[1])

    if (not enemy or not enemy.valid) then
        local enemies = requesting_unit_group.enemies
        for i = 2, #enemies, 1 do
            enemy = enemies[i]
            if (enemy and enemy.valid) then goto continue end
        end
        if (not enemy or not enemy.valid) then return end
        ::continue::
    end

    local unit_group = enemy.surface.create_unit_group({ position = enemy.position})
    if (not unit_group or not unit_group.valid) then return end

    local limit = requesting_unit_group.limit or 0
    local add_member = unit_group.add_member
    for i, unit_number in ipairs(requesting_unit_group.enemies or {}) do
        enemy = get_entity_by_unit_number(unit_number)

        if (enemy and enemy.valid) then
            enemy.release_from_spawner()
            enemy.ai_settings.allow_try_return_to_spawner = false
            enemy.ai_settings.join_attacks = true
            add_member(enemy)
        end
        if (i >= limit or i >= max_unit_group_size) then break end
    end

    unit_group.set_command({
        type = command_attack_area,
        destination = requesting_unit_group.target_position,
        radius = 21,
        distraction = distraction_by_damage,
    })
    unit_group.release_from_spawner()
    unit_group.start_moving()
    -- Log.error("unit group released")

    -- Log.error("random: target_entity")
    -- -- Log.error(target_entity)
    -- game.print({ "messages.entity-gps", "", requesting_unit_group.target_position.x, requesting_unit_group.target_position.y, unit_group.surface.name })
end
Event_Handler:register_event({
    event_name = "on_script_path_request_finished",
    source_name = "attack_group_service.on_script_path_request_finished",
    func_name = "attack_group_service.on_script_path_request_finished",
    func = attack_group_service.on_script_path_request_finished,
})

function attack_group_service.on_runtime_mod_setting_changed(event)
    -- Log.debug("spawn_service.on_runtime_mod_setting_changed")
    -- Log.info(event)

    if (not event.setting or type(event.setting) ~= "string") then return end
    if (not event.setting_type or type(event.setting_type) ~= "string") then return end

    if (not (event.setting:find("more-enemies-", 1, true) == 1)) then return end

    if (event.setting == Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name) then
        max_unit_group_size = get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, reindex = true, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
    elseif (event.setting == Mod_Settings.MAXIMUM_ATTACK_GROUP_DELAY.name) then
        delay_min = get_minimum_attack_group_delay()
    elseif (event.setting == Mod_Settings.MINIMUM_ATTACK_GROUP_DELAY.name) then
        delay_max = get_maximum_attack_group_delay()
    elseif (event.setting:find("-attack-group-peace-time", -24, true)) then
        local name = event.setting:match("more%-enemies%-([%w]+)%-attack%-group%-peace%-time")
        if (name and attack_group_peace_time[name:lower()] ~= nil) then
            attack_group_peace_time[name:lower()] = get_attack_group_peace_time(name:lower()) * Constants.time.TICKS_PER_MINUTE
        end
    end
end
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "attack_group_service.on_runtime_mod_setting_changed",
    func_name = "attack_group_service.on_runtime_mod_setting_changed",
    func = attack_group_service.on_runtime_mod_setting_changed,
})

function attack_group_service.init(__storage)
    storage = __storage
end

return attack_group_service