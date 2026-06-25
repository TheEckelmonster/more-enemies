local storage
local attack_groups
local groups
local surface_creation
local stats_data
local unique_ids
local unit_groups

local game
local get_surface

local Stats_Data = require("scripts.data.stats-data")
local process_event = Stats_Data.process_event
local new_Stats_Data = Stats_Data.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.attack_groups = storage.attack_groups or {}
    attack_groups = storage.attack_groups

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.surface_creation = storage.surface_creation or {}
    surface_creation = storage.surface_creation

    storage.unique_ids = storage.unique_ids
    unique_ids = storage.unique_ids

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    game = __game or _ENV.game

    get_surface = game.get_surface

    return game
end

local math_ceil = math.ceil
local math_min = math.min
local math_sqrt = math.sqrt

local math_max = math.max
local next = next
local pairs = pairs
local ipairs = ipairs
local type = type

local table_size = table_size

local defines = defines
local defines_command = defines.command
local valid_commands = {
    [defines_command.attack] = defines_command.attack,
    [defines_command.attack_area] = defines_command.attack_area,
    [defines_command.compound] = defines_command.compound,
    [defines_command.go_to_location] = defines_command.go_to_location,
}
local defines_moving_state = defines.moving_state
local valid_moving_state = {
    [defines_moving_state.moving] = defines_moving_state.moving,
    [defines_moving_state.adaptive] = defines_moving_state.adaptive
}

local moving_state_stuck = defines_moving_state.stuck

local UINT64 = 2^64-1

local Clonable_Units = Clonable_Units
local Filters = Filters
local Log = Log

local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants
local Settings_Map = Settings_Map

local Constants = Constants or require("scripts.constants.constants")
local Planets = Planets
local planets = {}

local i = 0
local modulo = math.ceil(10 + table_size(Planets) / 2) % 60 + 1
for _, planet in pairs(Planets) do
    local idx = i % (modulo) + 1
    planets[idx] = planets[idx] or {}
    table.insert(planets[idx], planet)
    i = i + 1
end

local Attack_Group_Data = require("scripts.data.attack-group-data")
local new_Attack_Group_Data = Attack_Group_Data.new
local Attack_Group_Service = require("scripts.service.attack-group-service")
local do_random_attack_group = Attack_Group_Service.do_random_attack_group
local Spawn_Service = require("scripts.service.spawn-service")
local entity_built = Spawn_Service.entity_built
local on_entity_died = Spawn_Service.on_entity_died
local on_entity_spawned = Spawn_Service.on_entity_spawned
local on_tick = Spawn_Service.on_tick

local spawn_controller = {}
spawn_controller.name = "spawn_controller"

spawn_controller.set_game = set_game

local do_attack_group = {}
local attack_group_peace_time = {}
local max_age = Constants.time.TICKS_PER_MINUTE * Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_AGE.name, })
local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, })

for _, surface_name in pairs(Planets) do
    local idx = surface_name:gsub("%-", "_"):upper()
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_DO_ATTACK_GROUP"]
    if (setting and setting.name) then
        do_attack_group[surface_name] = Data_Utils.get_runtime_global_setting({ setting = setting.name, }) or false
    end
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_ATTACK_GROUP_PEACE_TIME"]
    if (setting and setting.name) then
        attack_group_peace_time[surface_name] = Data_Utils.get_runtime_global_setting({ setting = setting.name, }) * Constants.time.TICKS_PER_MINUTE
    end
end

local MAX_AGE = 10 * Constants.time.TICKS_PER_MINUTE

function spawn_controller.on_tick(event)
    -- Log.debug("spawn_controller.on_tick")
    -- Log.info(event)

    stats_data = stats_data or set_game() and stats_data
    stats_data.previous = stats_data.current
    stats_data.current = { total = 0, }

    local tick = event.tick
    stats_data.current.total = (stats_data.current.total or 0) + 1
    stats_data.tick = event and tick or set_game().tick or UINT64
    stats_data.current[event.name] = (stats_data.current[event.name] or 0) + 1

    local wv = stats_data.welford_variance
    wv.count = wv.count + 1

    if (wv.count > 1) then wv.sd = math_sqrt(wv.M2 / (wv.count - 1)) end

    if (tick % 60 == 0) then
        wv.count = math_max(wv.count * 0.5, 10)
        wv.M2 = wv.M2 * 0.5
    end

    if (stats_data.pause_until and event and tick < stats_data.pause_until) then goto skip end

    on_tick(event)

    if (not planets[tick % modulo]) then goto skip end
    for _, surface_name in ipairs(planets[tick % modulo]) do
        if (do_attack_group[surface_name] and (attack_group_peace_time[surface_name] < tick)) then
            if (not (game and get_surface(surface_name) or set_game().get_surface(surface_name) or {}).valid) then goto continue end

            if (surface_creation and not surface_creation[surface_name]) then
                if (get_surface(surface_name).index == 1) then
                    surface_creation[surface_name] = 0
                else
                    surface_creation[surface_name] = tick
                end
            end

            if (((attack_group_peace_time[surface_name] or UINT64) + (surface_creation and surface_creation[surface_name] or UINT64)) >= tick ) then goto continue end

            attack_groups[surface_name] = attack_groups[surface_name] or new_Attack_Group_Data(Attack_Group_Data, { surface_name = surface_name, })
            attack_groups[surface_name].tick = attack_groups[surface_name].tick or tick
            if (attack_groups[surface_name].tick > tick) then goto continue end

            do_random_attack_group(surface_name, tick)
        end
        ::continue::
    end

    ::skip::

    if (tick % 12 == 1) then
        if (stats_data.group_idx and not groups[stats_data.group_idx]) then stats_data.group_idx = nil end
        local k, unit_group = next(groups or set_game() and groups, stats_data.group_idx)
        stats_data.group_idx = k
        if (k and unit_group) then
            unique_ids = unique_ids or set_game() and unique_ids
            unit_groups = unit_groups or set_game() and unit_groups

            local group = unit_group.group or nil
            if (not group or not group.valid) then
                groups[k] = nil
                unique_ids[k] = nil
                unit_groups.count = (unit_groups.count or 1) - 1
                if (unit_groups.count < 0) then unit_groups.count = 0 end
                stats_data.current.group_stress = (unit_groups.count + 1) / (max_unit_groups + 1)
            else
                unit_groups.count = unit_groups.count or 1
                stats_data.current.group_stress = (unit_groups.count + 1) / (max_unit_groups + 1)
                stats_data.group_allowed_age = (max_age or MAX_AGE) * (1.0 - (0.75 * stats_data.current.group_stress))
                if (group.moving_state == moving_state_stuck or unit_group.tick < (tick - stats_data.group_allowed_age)) then
                    if ((valid_moving_state[group.moving_state] or valid_commands[group.state]) and stats_data.current.group_stress < 0.98) then
                        unit_group.resets = (unit_group.resets or -1) + 1
                        unit_group.tick = tick - (stats_data.group_allowed_age * (unit_group.resets * math_max(stats_data.current.group_stress, 0.001)))
                    else
                        if (unit_group.group.valid) then unit_group.group.destroy() end
                        groups[k] = nil
                        unique_ids[k] = nil
                        unit_groups.count = (unit_groups.count or 1) - 1
                        if (unit_groups.count < 0) then unit_groups.count = 0 end
                    end
                end
            end
        end
    elseif (tick % 12 == 7) then
        if (stats_data.unique_idx and not unique_ids[stats_data.unique_idx]) then stats_data.unique_idx = nil end
        local k, v = next(unique_ids or set_game() and unique_ids, stats_data.unique_idx)
        stats_data.unique_idx = k
        if (k and v) then
            groups = groups or set_game() and groups
            if (not groups[k]) then unique_ids[k] = nil end
        end
    end

    stats_data.activity_velocity = stats_data.current.total - stats_data.previous.total

    if (tick % 60 == 0) then
        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups.count = unit_groups.count or 0
        local curr_stress = (unit_groups.count + 1) / (max_unit_groups + 1)
        local curr_activity = stats_data.current.total

        local hist_a = stats_data.activity_history
        local hist_s = stats_data.stress_history

        local new_activity_velocity = curr_activity - hist_a.last_1s
        local new_stress_velocity = curr_stress - hist_s.last_1s

        hist_a.acceleration = new_activity_velocity - hist_a.v_1s
        hist_s.acceleration = new_stress_velocity - hist_s.v_1s

        hist_a.last_1s = curr_activity
        hist_a.v_1s = new_activity_velocity
        hist_s.last_1s = curr_stress
        hist_s.v_1s = new_stress_velocity

        if (tick % 120 == 0) then
            hist_a.last_2s = curr_activity
            hist_a.v_2s = new_activity_velocity - hist_a.v_2s
            hist_s.last_2s = curr_stress
            hist_s.v_2s = new_stress_velocity - hist_s.v_2s

            if (tick % 240 == 0) then
                hist_a.last_4s = curr_activity
                hist_a.v_4s = new_activity_velocity - hist_a.v_4s
                hist_s.last_4s = curr_stress
                hist_s.v_4s = new_stress_velocity - hist_s.v_4s

                if (tick % 480 == 0) then
                    hist_a.last_8s = curr_activity
                    hist_a.v_8s = new_activity_velocity - hist_a.v_8s
                    hist_s.last_8s = curr_stress
                    hist_s.v_8s = new_stress_velocity - hist_s.v_8s
                end
            end
        end
    end

    if (stats_data.pause > 1) then stats_data.pause = stats_data.pause - 1 end

    local govs = stats_data.event_governors
    if (govs and govs.first and govs.last and govs.q) then
        local meta = stats_data.meta
        local blended_x = meta.last_load or 0
        local recovery_speed = blended_x > 0.5 and 1 or 2
        local gov = nil
        for i = govs.first, govs.last - 1, 1 do
            gov = govs.q[i]
            if (gov) then
                if (gov.fail_streak > 0) then gov.fail_streak = math_max(gov.fail_streak - 0.1, 0) end
                if (gov.current_limit < gov.baseline) then gov.current_limit = math_min(gov.current_limit + recovery_speed, gov.baseline) end
            end
        end
    end
end
Event_Handler:register_event({
    event_name = "on_tick",
    source_name = "spawn_controller.on_tick",
    func_name = "spawn_controller.on_tick",
    func = spawn_controller.on_tick,
})

local types = {
    ["unit"] = true,
    ["spider-unit"] = true,
    -- ["unit-spawner"] = true,
}
function spawn_controller.on_entity_died(event)
    -- Log.debug("spawn_controller.on_entity_died")
    -- Log.info(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end

    if (not process_event(stats_data, event.name, event.tick)) then
        if (event.entity and event.entity.valid) then
            if (types[event.entity.type]) then
                return
            end
        else
            return
        end
    end

    on_entity_died(event)
end
Event_Handler:register_event({
    event_name = "on_entity_died",
    filter = Filters.on_entity_died,
    source_name = "spawn_controller.on_entity_died",
    func_name = "spawn_controller.on_entity_died",
    func = spawn_controller.on_entity_died,
})

function spawn_controller.on_entity_spawned(event)
    -- Log.debug("spawn_controller.on_entity_spawned")
    -- Log.info(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end

    if (not process_event(stats_data, event.name, event.tick)) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not Clonable_Units[event.entity.name]) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    -- if (event.entity.force.name ~= ENEMY) then return end
    if (not event.entity.surface or not event.entity.surface.valid or not Valid_Surfaces[event.entity.surface.name]) then return end

    on_entity_spawned(event)
end
Event_Handler:register_event({
    event_name = "on_entity_spawned",
    source_name = "spawn_controller.on_entity_spawned",
    func_name = "spawn_controller.on_entity_spawned",
    func = spawn_controller.on_entity_spawned,
})

function spawn_controller.script_raised_built(event)
    -- Log.debug("spawn_controller.script_raised_built")
    -- Log.info(event)
    stats_data = stats_data or set_game() and stats_data
    stats_data.current.total = (stats_data.current.total or 0) + 1
    if (not event) then return end

    if (not process_event(stats_data, event.name, event.tick)) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not Clonable_Units[event.entity.name]) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    -- if (event.entity.force ~= ENEMY) then return end

    -- if (not Settings_Service.get_BREAM_do_clone()) then return end

    entity_built(event)
end
Event_Handler:register_event({
    event_name = "script_raised_built",
    filter = Filters.script_raised_built,
    source_name = "spawn_controller.script_raised_built",
    func_name = "spawn_controller.script_raised_built",
    func = spawn_controller.script_raised_built,
})

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_AGE.name] = function (event, params) max_age = params.setting_value end
update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name] = function (event, params) max_unit_groups = params.setting_value end

for _, surface_name in ipairs(Planets or {}) do
    local idx = surface_name:gsub("%-", "_"):upper()
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_DO_ATTACK_GROUP"] or Runtime_Global_Settings_Constants.settings["FALLBACK_DO_ATTACK_GROUP"]
    if (setting and setting.name) then
        update_settings[setting.name] = function (event, params) do_attack_group[surface_name] = params.setting_value end
    end
    local setting = Runtime_Global_Settings_Constants.settings[idx .. "_ATTACK_GROUP_PEACE_TIME"] or Runtime_Global_Settings_Constants.settings["FALLBACK_ATTACK_GROUP_PEACE_TIME"]
    if (setting and setting.name) then
        update_settings[setting.name] = function (event, params) attack_group_peace_time[surface_name] = params.setting_value end
    end
end

local ME_PREFIX = ME_PREFIX
local STRING = Types.STRING
function spawn_controller.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = spawn_controller.on_runtime_mod_setting_changed
})

function spawn_controller.init(__storage) storage = __storage or _ENV.storage end

return spawn_controller