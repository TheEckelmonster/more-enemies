local Data = require("scripts.data.data")
local Max_Distance_Data = require("scripts.data.max-distance-data")
local Log = require("libs.log.log")

local attack_group_data = Data:new()

attack_group_data.chunks = {}
attack_group_data.max_distance = Max_Distance_Data:new()
attack_group_data.peace_time_tick = nil
attack_group_data.surface = nil
attack_group_data.surface_name = nil
attack_group_data.radius = 1
attack_group_data.tick = 0
attack_group_data.unit_group = nil

function attack_group_data:new(obj, data)
    Log.debug("attack_group_data:new")
    Log.info(obj)
    Log.info(data)

    obj = Data:new(obj, data) or Data:new(_, data)

    local defaults = {
        chunks = self.chunks,
        max_distance = self.max_distance,
        peace_time_tick = self.peace_time_tick,
        surface = self.surface,
        surface_name = self.surface_name,
        radius = self.radius,
        tick = self.tick,
        unit_group = self.unit_group,
    }

    for k, v in pairs(defaults) do
        if (obj[k] == nil) then obj[k] = v end
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

return attack_group_data