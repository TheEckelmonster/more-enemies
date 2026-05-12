local storage
local difficulties
local groups
local pathables
local surfaces
local unit_groups
local unique_ids

local game
local get_surface

local function set_game(__game, __storage)
    storage = __storage or _ENV.storage

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

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

    game = __game or _ENV.game
    get_surface = game.get_surface

    return game
end

local type = type

local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local defines = defines
local command_attack_area = defines.command.attack_area
local command_build_base = defines.command.build_base

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

local BOUNDING_BOXES = {
    ["unit"] = {{-0.25, -0.25}, {0.25, 0.25},},
    ["spider-unit"] = {{-0.05, -0.05}, {0.05, 0.05}},
}

local COLLISION_MASKS = {
    ["unit"] = {
        layers = {
            ["water_tile"] = true,
            ["object"] = true,
            ["empty_space"] = true,
            ["lava_tile"] = true,
            ["cliff"] = true,
            ["out_of_map"] = true,
        },
    },
    ["spider-unit"] = {
        layers={
            ["player"] = true,
            ["train"] = true,
            ["is_object"] = true
        },
    },
}

local PATHFINDER_FLAGS = { allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true, cache = true, }

local attack_group_service = {}
attack_group_service.name = "attack_group_service"
attack_group_service.set_game = set_game

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

    local surface_name = params.surface_name
    if (not surface_name) then return end

    local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    surfaces[surface_name] = surfaces and surfaces[surface_name] or set_game() and surfaces[surface_name] or {}
    attack_group.chunks = attack_group.chunks or deepcopy(surfaces[surface_name].chunks)

    local chunks = attack_group.chunks or {}
    if (#chunks < 1) then
        attack_group.chunks = deepcopy(surfaces[surface_name].chunks)
        return
    end
    local chunk = table_remove(chunks, math_random(#chunks))
    if (not chunk) then return end

    local enemies = get_enemy({ surface_name = surface_name, chunk = chunk, tick = params.tick or 0, }) or {}
    local num_enemies = #enemies
    if (not enemies[1] or not enemies[1].valid) then return end

    difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty) then return end

    local evolution_factor = enemies[1].force.get_evolution_factor(enemies[1].surface)
    evolution_factor = evolution_factor ^ (1 / selected_difficulty.value)

    -- Maximum probability of an attack group spawning at 100% (1) evolution factor
    local max_probability = 1 - (selected_difficulty.inverse_value or (function (arr)
        arr[1].inverse_value = arr[2]
        return arr[2]
    end)({ selected_difficulty, (1 / selected_difficulty.value), }))

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

    local limit = 2 + 2 * (selected_difficulty.attack_group_limit or (function (arr)
        arr[1].attack_group_limit = arr[2]
        return arr[2]
    end)({ selected_difficulty, selected_difficulty.value * selected_difficulty.radius_modifier, })) * (evolution_factor ^ (selected_difficulty.inverse_value or 1)) + math_random(num_enemies) * (selected_difficulty.radius_modifier * (evolution_factor ^ (selected_difficulty.inverse_value or 1)))

    local target_entities = get_target_entity({
        chunk = chunk,
        surface = surface,
        limit = 1 + limit * evolution_factor,
    }) or {}

    local target_entity = nil
    if (#target_entities > 0) then
        target_entity = target_entities[math_random(#target_entities)]
        if (not target_entity or not target_entity.valid) then return end
    else
        return
    end

    local target_position = target_entity.position
    local path_request = {
        bounding_box = BOUNDING_BOXES[enemies[1].type],
        collision_mask = COLLISION_MASKS[enemies[1].type],
        start = enemies[1].position,
        goal = target_position,
        force = enemies[1].force,
        radius = 12,
        pathfinder_flags = PATHFINDER_FLAGS,
        can_open_gates = false,
        path_resolution_modifier = -1,
        max_gap_distance = enemies[1].type == "spider-unit" and 4 or 0,
    }

    local path_id = enemies[1].surface.request_path(path_request)

    unit_groups[path_id] = {
        enemies = {},
        surface_name = enemies[1].surface.name,
        start_position = enemies[1].position,
        target_position = target_position,
        limit = #target_entities,
        path_id = path_id,
        path_request = path_request,
        --[[ TODO: make configurable ]]
        attempts = 0,
        --[[ TODO: make configurable ]]
        retries = selected_difficulty.retries + 1,
        spider_unit = enemies[1].type == "spider-unit" or nil,
        member_count = num_enemies or 0,
    }

    local unit_group_enemies = unit_groups[path_id].enemies
    for i = 1, num_enemies, 1 do
        if (i >= limit or i >= max_unit_group_size) then break end
        if (enemies[i] and enemies[i].valid) then
            table_insert(unit_group_enemies, enemies[i].unit_number)
        end
    end

    if (delay_min > delay_max) then delay_min = delay_max end
    if (delay_max < delay_min ) then delay_max = delay_min end

    local delay = math_random(delay_min, delay_max)

    if (selected_difficulty and selected_difficulty.value and selected_difficulty.value > 0) then
        delay = delay / ((selected_difficulty.radius_modifier ^ 1.5) * (0.5 + ((evolution_factor ^ 0.75) / 2)))
    end

    attack_group.tick = (params.tick or 0) + delay
end

function attack_group_service.on_script_path_request_finished(event)

    if (not event) then return end

    local id = event.id
    if (not id) then return end

    unit_groups = unit_groups or set_game() and unit_groups or {}

    local requesting_unit_group = unit_groups[id]
    if (not requesting_unit_group) then return end
    unit_groups[id] = nil

    if (not event.path and event.try_again_later or event.try_again_later) then
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

        local surface = game and get_surface(requesting_unit_group.surface_name) or set_game().get_surface(requesting_unit_group.surface_name)
        if (not surface or not surface.valid) then return end

        local path_id = surface.request_path(requesting_unit_group.path_request)
        requesting_unit_group.path_id = path_id

        unit_groups[path_id] = requesting_unit_group
        return
    end

    local surface = (game or set_game()).get_surface(requesting_unit_group.surface_name)
    if (not surface or not surface.valid) then return end

    local unit_group = surface.create_unit_group({ position = requesting_unit_group.start_position, })
    if (not unit_group or not unit_group.valid) then return end

    local unique_id = unit_group.unique_id
    groups[unique_id] = unit_group

    requesting_unit_group.unique_id = unique_id
    unique_ids[unique_id] = requesting_unit_group

    requesting_unit_group.member_count = requesting_unit_group.member_count or 0

    requesting_unit_group.attempts = nil
    requesting_unit_group.retries = nil
    requesting_unit_group.path_id = nil
    requesting_unit_group.path_request = nil

    local idx = unique_id % 60 + 1
    pathables[idx] = pathables[idx] or {}
    table_insert(pathables[idx], requesting_unit_group)
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