local storage

local Log = require("libs.log.log")
local Unit_Group_Service = require("scripts.service.unit-group-service")

local on_unit_group_finished_gathering = Unit_Group_Service.on_unit_group_finished_gathering

local unit_group_controller = {}
unit_group_controller.name = "unit_group_controller"

function unit_group_controller.on_unit_group_finished_gathering(event)
    on_unit_group_finished_gathering(event)
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