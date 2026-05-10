local storage
local attack_groups

local game
local get_surface

local function set_game(__game)
    storage.attack_groups = storage.attack_groups or {}
    attack_groups = storage.attack_groups

    game = __game or _ENV.game
    get_surface = game.get_surface

    return game
end

local pairs = pairs
local ipairs = ipairs

local UINT64 = 2^64-1

local Log = Log

local Mod_Settings = Mod_Settings

local Constants = Constants
local planets = {}

local i = #planets
for k, _ in pairs(Constants.DEFAULTS.planets) do
    local idx = i % 12
    planets[idx] = planets[idx] or {}
    table.insert(planets[idx], k)
    i = #planets + 1
end

local Attack_Group_Data = require("scripts.data.attack-group-data")
local new_Attack_Group_Data = Attack_Group_Data.new
local Attack_Group_Service = require("scripts.service.attack-group-service")
local do_random_attack_group = Attack_Group_Service.do_random_attack_group

local Spawn_Service = require("scripts.service.spawn-service")
local on_entity_died = Spawn_Service.on_entity_died
local on_entity_spawned = Spawn_Service.on_entity_spawned
local on_tick = Spawn_Service.on_tick

local _Settings_Service = Settings_Service
local get_runtime_global_setting = _Settings_Service.get_runtime_global_setting
local Settings_Service = require("scripts.service.settings-service")
local get_attack_group_peace_time = Settings_Service.get_attack_group_peace_time

local spawn_controller = {}
spawn_controller.name = "spawn_controller"

local on_mined_entity

local do_attack_group = {}
local attack_group_peace_time = {}

for name, _ in pairs(Constants.DEFAULTS.planets) do
    do_attack_group[name] = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings[name:upper() .. "_DO_ATTACK_GROUP"].name, })
    attack_group_peace_time[name] = get_attack_group_peace_time(name) * Constants.time.TICKS_PER_MINUTE + 1
end

function spawn_controller.on_tick(event)
    -- Log.debug("spawn_controller.on_tick")
    -- Log.info(event)

    if (storage and event and event.tick) then storage.tick = event.tick end

    on_tick(event)
    if (not planets[event.tick % 12] or not planets[event.tick % 12][1]) then return end

    for _, name in ipairs(planets[event.tick % 12]) do
        if (do_attack_group[name] and (attack_group_peace_time[name] < event.tick)) then
            if (not (game and get_surface(name) or set_game().get_surface(name) or {}).valid) then goto continue end

            attack_groups[name] = attack_groups[name] or new_Attack_Group_Data(Attack_Group_Data, { surface_name = name, })
            attack_groups[name].tick = attack_groups[name].tick or event.tick
            if (attack_groups[name].tick > event.tick) then goto continue end

            storage.surface_creation = storage.surface_creation or {}
            if (not storage.surface_creation[name]) then
                if (get_surface(name).index == 1) then
                    storage.surface_creation[name] = 0
                else
                    storage.surface_creation[name] = event.tick
                end
            end

            if (((attack_group_peace_time[name] or UINT64) + (storage.surface_creation[name] or UINT64)) >= event.tick ) then return end

            do_random_attack_group({
                attack_group = attack_groups[name],
                surface_name = name,
                tick = event.tick,
            })
        end
        ::continue::
    end
end
Event_Handler:register_event({
    event_name = "on_tick",
    source_name = "spawn_controller.on_tick",
    func_name = "spawn_controller.on_tick",
    func = spawn_controller.on_tick,
})

function spawn_controller.on_entity_died(event)
    -- Log.debug("spawn_controller.on_entity_died")
    -- Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end

    if (Filters.on_entity_died[event.entity.name]) then
        on_entity_died(event)
    else
        on_mined_entity = on_mined_entity or spawn_controller.Entity_Controller.on_mined_entity
        on_mined_entity(event)
    end
end
Event_Handler:register_event({
    event_name = "on_entity_died",
    -- filter = Filters.on_entity_died,
    source_name = "spawn_controller.on_entity_died",
    func_name = "spawn_controller.on_entity_died",
    func = spawn_controller.on_entity_died,
})

function spawn_controller.on_entity_spawned(event)
    -- Log.debug("spawn_controller.on_entity_spawned")
    -- Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (event.entity.force.name ~= "enemy") then return end

    on_entity_spawned(event)
end
Event_Handler:register_event({
    event_name = "on_entity_spawned",
    source_name = "spawn_controller.on_entity_spawned",
    func_name = "spawn_controller.on_entity_spawned",
    func = spawn_controller.on_entity_spawned,
})

function spawn_controller.script_raised_built(event)
    Log.debug("spawn_controller.script_raised_built")
    Log.info(event)

    if (not event) then return end
    if (not event.tick) then return end
    if (not event.entity or not event.entity.valid) then return end
    if (not event.entity.force or not event.entity.force.valid) then return end
    if (event.entity.force ~= "enemy") then return end

    if (not Settings_Service.get_BREAM_do_clone()) then return end

    Spawn_Service.entity_built(event)
end
Event_Handler:register_event({
    event_name = "script_raised_built",
    filter = Filters.script_raised_built,
    source_name = "spawn_controller.script_raised_built",
    func_name = "spawn_controller.script_raised_built",
    func = spawn_controller.script_raised_built,
})

function spawn_controller.on_runtime_mod_setting_changed(event)
    -- Log.debug("spawn_controller.on_runtime_mod_setting_changed")
    -- Log.info(event)

    if (not event.setting or type(event.setting) ~= "string") then return end
    if (not event.setting_type or type(event.setting_type) ~= "string") then return end

    if (not (event.setting:find("more-enemies-", 1, true) == 1)) then return end

    if (event.setting:find("-do-attack-group", -16, true)) then
        local name = event.setting:match("more%-enemies%-([%w]+)%-do%-attack%-group")
        if (name and do_attack_group[name:lower()] ~= nil) then
            do_attack_group[name:lower()] = get_runtime_global_setting({ setting = Mod_Settings[event.setting].name, reindex = true, })
        end
    elseif (event.setting:find("-attack-group-peace-time", -24, true)) then
        local name = event.setting:match("more%-enemies%-([%w]+)%-attack%-group%-peace%-time")
        if (name and attack_group_peace_time[name:lower()] ~= nil) then
            attack_group_peace_time[name:lower()] = get_attack_group_peace_time(name:lower()) * Constants.time.TICKS_PER_MINUTE + 1
        end
    end
end
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "spawn_controller.on_runtime_mod_setting_changed",
    func_name = "spawn_controller.on_runtime_mod_setting_changed",
    func = spawn_controller.on_runtime_mod_setting_changed,
})

function spawn_controller.init(__storage)
    storage = __storage
end

return spawn_controller