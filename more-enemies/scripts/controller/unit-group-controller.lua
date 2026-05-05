local storage

local Log = require("libs.log.log")
local Initialization = require("scripts.initialization")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Settings_Service = require("scripts.service.settings-service")
local Unit_Group_Service = require("scripts.service.unit-group-service")

local unit_group_controller = {}
unit_group_controller.name = "unit_group_controller"

-- function unit_group_controller.unit_group_created(event)
function unit_group_controller.on_unit_group_created(event)
    Log.debug("unit_group_controller.on_unit_group_created")
    Log.info(event)

    if (not event) then return end

    local group = event.group
    if (not group or not group.valid) then return end
    local surface = group.surface
    if (not surface or not surface.valid or not surface.name) then return end

    -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
    if (not more_enemies_data.do_nth_tick) then return end

    local max_num_clones = Settings_Service.get_maximum_number_of_unit_group_clones(surface.name)
    if (max_num_clones ~= nil and more_enemies_data.clone[surface.name].unit_group > max_num_clones) then
        Log.debug("Tried to clone more than the unit limit: " .. serpent.block(max_num_clones))
        Log.debug("Currently " .. serpent.block(more_enemies_data.clone[surface.name].unit_group) .. " unit-group clones")
        -- return
        if (not group or not group.valid or not group.is_script_driven) then
            return
        end
    end

    Unit_Group_Service.unit_group_created({ event = event, more_enemies_data = more_enemies_data })
end
Event_Handler:register_event({
    event_name = "on_unit_group_created",
    source_name = "unit_group_controller.on_unit_group_created",
    func_name = "unit_group_controller.on_unit_group_created",
    func = unit_group_controller.on_unit_group_created,
})

-- function unit_group_controller.unit_group_finished_gathering(event)
function unit_group_controller.on_unit_group_finished_gathering(event)
    Log.debug("unit_group_controller.on_unit_group_finished_gathering")
    Log.info(event)

    if (not event) then return end

    local group = event.group
    if (not group or not group.valid) then return end
    local surface = group.surface
    if (not surface or not surface.valid or not surface.name) then return end

    local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
    if (not more_enemies_data.do_nth_tick) then return end

    local max_num_clones = Settings_Service.get_maximum_number_of_unit_group_clones(surface.name)
    if (max_num_clones ~= nil and more_enemies_data.clone[surface.name].unit_group > max_num_clones) then
        Log.debug("Tried to clone more than the unit limit: " .. serpent.block(max_num_clones))
        Log.debug("Currently " .. serpent.block(more_enemies_data.clone[surface.name].unit_group) .. " unit-group clones")
        -- return
        if (not group or not group.valid or not group.is_script_driven) then
            return
        end
    end

    Unit_Group_Service.unit_group_finished_gathering({ event = event, more_enemies_data = more_enemies_data })
end
Event_Handler:register_event({
    event_name = "on_unit_group_finished_gathering",
    source_name = "unit_group_controller.on_unit_group_finished_gathering",
    func_name = "unit_group_controller.on_unit_group_finished_gathering",
    func = unit_group_controller.on_unit_group_finished_gathering,
})

function unit_group_controller.init(__storage)
    storage = __storage
end

return unit_group_controller