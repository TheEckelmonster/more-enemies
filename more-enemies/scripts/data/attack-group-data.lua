local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Log = require("__TheEckelmonster-core-library__.libs.log.log")

local attack_group_data = {}

attack_group_data.peace_time_tick = nil
attack_group_data.surface = nil
attack_group_data.surface_name = nil
attack_group_data.radius = 1
attack_group_data.tick = 0
attack_group_data.unit_group = nil

function attack_group_data:new(o)
    -- Log.debug("attack_group_data:new")
    -- Log.info(o)

    local defaults = {
        peace_time_tick = self.peace_time_tick,
        surface_name = self.surface_name,
        radius = self.radius,
        tick = self.tick,
        unit_group = self.unit_group,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(attack_group_data, Data)
attack_group_data.__index = attack_group_data

return attack_group_data