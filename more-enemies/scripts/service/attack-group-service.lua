local storage
local attack_groups
local chunks_arr
local chunk_maps
local difficulties
local groups
local pathables
local settings_map
local spawner_maps
local surfaces
local unit_groups
local unique_ids

local game
local get_surface

local ipairs = ipairs

local Planets = Planets
local Settings_Map = Settings_Map
local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.attack_groups = storage.attack_groups or {}
    attack_groups = storage.attack_groups

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.groups = storage.groups or {}
    groups = storage.groups

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

    storage.spawner_maps = storage.spawner_maps or {}
    spawner_maps = storage.spawner_maps

    for _, planet in ipairs(Planets or {}) do
        surfaces[planet] = surfaces[planet] or {}
        surfaces[planet].chunks = surfaces[planet].chunks or {}
        surfaces[planet].chunk_map = surfaces[planet].chunk_map or {}
        surfaces[planet].spawner_map = surfaces[planet].spawner_map or {}

        chunks_arr[planet] = chunks_arr[planet] or surfaces[planet].chunks
        chunk_maps[planet] = chunk_maps[planet] or surfaces[planet].chunk_map
        spawner_maps[planet] = spawner_maps[planet] or surfaces[planet].spawner_map
    end

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
local math_max = math.max
local math_min = math.min
local math_random = math.random
local math_sqrt = math.sqrt
local table_insert = table.insert

local defines = defines
local command_attack_area = defines.command.attack_area
local command_build_base = defines.command.build_base

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
local Requesting_Unit_Group = require("scripts.data.requesting-unit-group")
local new_Requesting_Unit_Group = Requesting_Unit_Group.new
local Settings_Service = require("scripts.service.settings-service")
local get_runtime_global_setting = Settings_Service.get_runtime_global_setting
local get_startup_setting = Settings_Service.get_startup_setting

local delay_min = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.name, }) or Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY.default_value
local delay_max = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.name, }) or Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY.default_value
local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, })

local attack_group_probability_modifiers = {}
for _, surface_name in ipairs(Planets or {}) do
    attack_group_probability_modifiers[surface_name] = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"].name, })
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

function attack_group_service.do_random_attack_group(params)
    -- Log.debug("attack_group_service.do_random_attack_group")
    -- Log.info(params)

    if (not params) then return end

    local surface_name = params.surface_name
    if (not surface_name) then return end

    local surface = game and get_surface(surface_name) or set_game().get_surface(surface_name)
    if (not surface or not surface.valid) then return end

    attack_groups[surface_name] = attack_groups[surface_name] or new_Attack_Group_Data(Attack_Group_Data, { surface_name = surface_name, })
    attack_groups[surface_name].tick = attack_groups[surface_name].tick or params.tick
    if (    attack_groups[surface_name].tick
        and attack_groups[surface_name].tick > (params.tick or 0)
        or  attack_groups[surface_name].sleep_until
        and attack_groups[surface_name].sleep_until > (params.tick or 0)
    ) then
        return
    end

    surfaces = surfaces or set_game() and surfaces
    if (not surfaces[surface_name]) then return end

    attack_groups = attack_groups or set_game()

    local attack_group = attack_groups[surface_name]
    if (not attack_group) then return end

    attack_group.prev_delay = attack_group.cur_delay or 30
    attack_group.cur_delay = 30
    unit_groups = unit_groups or set_game() and unit_groups
    if (not unit_groups.count or unit_groups.count >= max_unit_groups) then
        local curr_fail_count = (attack_group.fail_count or 0) + 1
        attack_group.fail_count = curr_fail_count

        attack_group.sleep_until = params.tick + math_min(2 * curr_fail_count, 180)
        goto skip
    end

    do
        attack_group.current_chunks = attack_group.current_chunks or {}
        attack_group.next_chunks = attack_group.next_chunks or {}

        if (#attack_group.current_chunks == 0 and #attack_group.next_chunks == 0) then
            attack_group.current_chunks = flatcopy_array(surfaces[surface_name].chunks, attack_group.current_chunks)
        end

        local chunks = attack_group.current_chunks
        if (not chunks or #chunks < 1) then
            local temp = attack_group.current_chunks
            attack_group.current_chunks = attack_group.next_chunks
            attack_group.next_chunks = temp

            chunks = attack_group.current_chunks

            if (not chunks or #chunks < 1) then return end
        end

        local count = #chunks
        local rand = math_random(count)
        local chunk = chunks[rand]

        chunks[rand] = chunks[count]
        chunks[count] = nil

        chunk_maps = chunk_maps or set_game() and chunk_maps
        local chunk_map = chunk_maps[surface_name]

        if (not chunk_map or not chunk_map[chunk.xy or 0]) then return end
        attack_group.next_chunks[#attack_group.next_chunks+1] = chunk

        if (    not chunk
            or
                chunk.timeout
            and chunk.timeout > params.tick
        ) then
            attack_group.invalid_chunks = (attack_group.invalid_chunks or 1) + 1
            attack_group.tick = (params.tick or 0) + 10 * (attack_group.invalid_chunks ^ 1.75)
            return
        else
            attack_group.invalid_chunks = (attack_group.invalid_chunks or 1) ^ 0.6
        end

        local enemies = get_enemy({ surface_name = surface_name, chunk = chunk, tick = params.tick or 0, }) or {}
        local num_enemies = #enemies
        if (not enemies[1] or not enemies[1].valid) then return end

        difficulties[surface_name] = (difficulties or set_game() and difficulties) and difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"]])

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

        local limit = math_min(max_unit_group_size, 1 + selected_difficulty.value + selected_difficulty.value * selected_difficulty.radius_modifier * (1 + selected_difficulty.radius_modifier * math_random(1 + selected_difficulty.value)))

        local target_entities = get_target_entity({
            chunk = chunk,
            surface = surface,
            limit = 1 + selected_difficulty.value,
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
            max_gap_distance = enemies[1].type == SPIDER_UNIT and 4 or 0,
        }

        local path_id = enemies[1].surface.request_path(path_request)

        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups[path_id] = new_Requesting_Unit_Group(Requesting_Unit_Group, {
            enemies = {},
            surface_name = enemies[1].surface.name,
            start_position = enemies[1].position,
            target_position = target_position,
            xy = math_floor(enemies[1].position.x / CHUNK) .. FORWARD_SLASH .. math_floor(enemies[1].position.y / CHUNK),
            limit = limit,
            path_id = path_id,
            path_request = path_request,
            --[[ TODO: make configurable ]]
            attempts = 0,
            --[[ TODO: make configurable ]]
            retries = selected_difficulty.retries + 1,
            spider_unit = enemies[1].type == SPIDER_UNIT or nil,
            member_count = num_enemies or 0,
        })

        local unit_group_enemies = unit_groups[path_id].enemies
        for i = 1, num_enemies, 1 do
            if (i >= limit or i >= max_unit_group_size) then break end
            if (enemies[i] and enemies[i].valid) then
                unit_group_enemies[i] = enemies[i].unit_number
            end
        end

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

    attack_group.tick = (params.tick or 0) + attack_group.cur_delay
end

function attack_group_service.on_script_path_request_finished(event)

    if (not event) then return end

    local id = event.id
    if (not id) then return end

    unit_groups = unit_groups or set_game() and unit_groups

    local requesting_unit_group = unit_groups[id]
    if (not requesting_unit_group) then return end
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

        local surface = game and get_surface(requesting_unit_group.surface_name) or set_game().get_surface(requesting_unit_group.surface_name)
        if (not surface or not surface.valid) then return end

        local path_id = surface.request_path(requesting_unit_group.path_request)
        requesting_unit_group.path_id = path_id

        unit_groups[path_id] = requesting_unit_group
        return
    else
        chunk_maps[requesting_unit_group.surface_name] = chunk_maps[requesting_unit_group.surface_name] or set_game() and chunk_maps[requesting_unit_group.surface_name]
        local chunk = chunk_maps[requesting_unit_group.surface_name][requesting_unit_group.xy or ""]

        if (not event.path) then
            if (chunk) then
                chunk.no_path = (chunk.no_path or 1) + 1
                chunk.timeout = event.tick + 60 * (4 ^ chunk.no_path)
            end
            return
        else
            if (chunk) then chunk.no_path = (chunk.no_path or 1) ^ 0.4 end
        end
    end

    unit_groups = unit_groups or set_game() and unit_groups
    unit_groups.count = (unit_groups.count or 0)

    if (unit_groups.count >= max_unit_groups) then return end

    local surface = (game or set_game()).get_surface(requesting_unit_group.surface_name)
    if (not surface or not surface.valid) then return end

    local unit_group = surface.create_unit_group({ position = requesting_unit_group.start_position, })
    if (not unit_group or not unit_group.valid) then return end

    unit_groups.count = unit_groups.count + 1

    local unique_id = unit_group.unique_id
    groups = groups or set_game() and groups
    groups[unique_id] = { tick = event.tick, group = unit_group, starting_pos = unit_group.position, }

    requesting_unit_group.unique_id = unique_id
    unique_ids[unique_id] = requesting_unit_group

    requesting_unit_group.attempts = nil
    requesting_unit_group.retries = nil
    requesting_unit_group.path_id = nil
    requesting_unit_group.path_request = nil

    requesting_unit_group.member_count = requesting_unit_group.member_count or 0

    local idx = unique_id % 60 + 1
    pathables[idx] = pathables[idx] or {}
    --[[ TODO: Convert this to a Simple_Queue ]]
    table_insert(pathables[idx], requesting_unit_group)
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
    update_settings[Runtime_Global_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER"]] = function (event, params) attack_group_probability_modifiers[surface_name] = params.setting_value end
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