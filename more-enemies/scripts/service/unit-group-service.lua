local storage
local game
local num_clones

local type = type

local function set_game(__game)
    game = __game or _ENV.game
    return game
end

local set_num_clones = Set_Num_Clones

local table_insert = table.insert

local Valid_Surfaces = Valid_Surfaces

local Settings_Service = Settings_Service
local get_runtime_global_setting = Settings_Service.get_runtime_global_setting

local unit_group_service = {}

local max_unit_group_size = Data_Utils.get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value

local Limits = Limits

local GROUP = "group"
function unit_group_service.on_unit_group_finished_gathering(event)
    -- Log.debug("unit_group_service.on_unit_group_finished_gathering")
    -- Log.info(event)

    if (not event or not event.name) then return end
    local group = event.group

    if (not group or not group.valid) then return end
    local surface = group.surface

    if (not surface or not surface.valid) then return end
    if (not Valid_Surfaces[surface.name]) then return end
    local surface_name = surface.name

    num_clones = num_clones or set_num_clones()
    if (num_clones[GROUP][surface_name] > (Limits[GROUP] and Limits[GROUP][surface_name] or 400)) then return end

    game = game or set_game()
    local tick = event.tick or game.tick
    if (not tick) then return end

    local unique_id = group.unique_id
    local idx = unique_id % 60 + 1

    local members = group.commandable_members or {}
    local member, unit_number, entity = nil, nil, nil

    storage.entities = storage.entities or {}
    storage.entities[idx] = storage.entities[idx] or {}

    for i = 1, #members, 1 do
        if (i > max_unit_group_size) then return end
        member = members[i]
        if (not member or not member.valid or not member.is_entity) then goto continue end
        entity = member.entity
        if (not entity or not entity.valid or not entity.unit_number) then goto continue end
        unit_number = entity.unit_number

        table_insert(storage.entities[idx],
            {
                source = "group",
                group = group,
                unique_id = unique_id,
                tick = tick,
                unit_number = unit_number,
                position = member.position.x .. "/" .. member.position.y,
                surface_name = surface_name,
            }
        )

        ::continue::
    end
end


function unit_group_service.on_runtime_mod_setting_changed(event)
    Log.debug("spawn_service.on_runtime_mod_setting_changed")
    Log.info(event)

    if (not event.setting or type(event.setting) ~= "string") then return end
    if (not event.setting_type or type(event.setting_type) ~= "string") then return end

    if (not (event.setting:find("more-enemies-", 1, true) == 1)) then return end

    if (event.setting == Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name) then
        max_unit_group_size = get_runtime_global_setting({ setting = Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name, }) or Mod_Settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value
    end
end
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "unit_group_service.on_runtime_mod_setting_changed",
    func_name = "unit_group_service.on_runtime_mod_setting_changed",
    func = unit_group_service.on_runtime_mod_setting_changed,
})

function unit_group_service.init(__storage)
    storage = __storage
end

return unit_group_service
