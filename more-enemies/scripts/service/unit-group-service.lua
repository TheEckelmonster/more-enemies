local storage
local game
local entities
local limits
local num_clones
local groups
local on_object_destroyed
local unit_groups
local unique_ids

local Set_Num_Clones = Set_Num_Clones

local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.entities = storage.entities or {}
    entities = storage.entities

    storage.groups = storage.groups or {}
    groups = storage.groups

    storage.limits = storage.limits or {}
    limits = storage.limits

    storage.on_object_destroyed = storage.on_object_destroyed or new_Simple_Queue(Simple_Queue)
    on_object_destroyed = storage.on_object_destroyed

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    storage.unique_ids = storage.unique_ids
    unique_ids = storage.unique_ids

    game = __game or _ENV.game

    num_clones = Set_Num_Clones()

    return game
end

local type = type

local script = script
local register_on_object_destroyed = script.register_on_object_destroyed

local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants
local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new

local unit_group_service = {}
unit_group_service.name = "unit_group_service"
unit_group_service.set_game = set_game

local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

local GROUP = GROUP
local UNIT  = "unit"
function unit_group_service.on_unit_group_finished_gathering(event)
    -- Log.debug("unit_group_service.on_unit_group_finished_gathering")
    -- Log.info(event)

    if (not event or not event.tick) then return end
    local group = event.group

    if (not group or not group.valid) then return end
    local surface = group.surface

    if (not surface or not surface.valid) then return end
    local surface_name = surface.name

    local unique_id = group.unique_id

    local members = group.commandable_members or {}
    if (not members[1]) then return end
    local member, unit_number, entity = nil, nil, nil

    -- groups = groups or set_game() and groups
    -- if (not groups[unique_id]) then return end

    num_clones = num_clones or set_game() and num_clones

    unit_groups = unit_groups or set_game() and unit_groups
    unit_groups.unit_nums = unit_groups.unit_nums or {}
    local unit_nums = unit_groups.unit_nums

    local tick = event.tick
    local idx = ""
    limits = limits or set_game() and limits
    for i = 1, #members, 1 do
        if (i > max_unit_group_size) then return end
        member = members[i]
        if (not member or not member.valid or not member.is_entity) then goto continue end
        entity = member.entity
        if (not entity or not entity.valid or not entity.unit_number) then goto continue end
        num_clones[GROUP] = num_clones[GROUP] or {}
        num_clones[GROUP][surface_name] = num_clones[GROUP][surface_name] or {}
        num_clones[GROUP][surface_name][entity.name] = num_clones[GROUP][surface_name][entity.name] or 0
        -- if (num_clones[GROUP][surface_name][entity.name] > (limits[GROUP] and limits[GROUP][surface_name] and (limits[GROUP][surface_name][entity.name] or limits[GROUP][surface_name].fallback) or 400)) then return end
        if (num_clones[GROUP][surface_name][entity.name] > (limits[GROUP] and limits[GROUP][surface_name] and (limits[GROUP][surface_name][entity.name] or limits[GROUP][surface_name].fallback) or 400)) then break end

        unit_number = entity.unit_number
        unit_nums[unit_number] = tick
        idx = unit_number % 60 + 1

        entities = entities or set_game() and entities
        entities[idx] = entities[idx] or new_Simple_Queue(Simple_Queue)
        local entity_queue = entities[idx]
        local next_idx = entity_queue.last or 1
        entity_queue.q[next_idx] = {
            source = GROUP,
            unique_id = unique_id or nil,
            tick = tick,
            unit_number = unit_number,
            surface_name = surface_name,
            type = entity.type or UNIT,
        }
        entity_queue.last = next_idx + 1

        ::continue::
    end
end

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name] = function (event, params) max_unit_group_size = params.setting_value end

local ME_PREFIX = ME_PREFIX
local STRING = Types.STRING
function unit_group_service.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = unit_group_service.on_runtime_mod_setting_changed
})

function unit_group_service.init(__storage) storage = __storage or _ENV.storage end

return unit_group_service
