local setmetatable = setmetatable

local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local new_Data = Data.new

local attack_group_data = {}

attack_group_data.peace_time_tick = nil
attack_group_data.surface = nil
attack_group_data.surface_name = nil
attack_group_data.tick = 0
attack_group_data.fail_count = 0
attack_group_data.unit_group = nil
attack_group_data.current_chunks = nil
attack_group_data.next_chunks = nil

function attack_group_data:new(o)
    local obj = o or {}

    obj.peace_time_tick = obj.peace_time_tick or self.peace_time_tick
    obj.surface_name = obj.surface_name or self.surface_name
    obj.tick = obj.tick or self.tick
    obj.unit_group = obj.unit_group or self.unit_group
    obj.current_chunks = obj.current_chunks or {}
    obj.next_chunks = obj.next_chunks or {}

    self.__index = self
    return setmetatable(new_Data(Data, obj), self)
end

setmetatable(attack_group_data, Data)
attack_group_data.__index = attack_group_data

return attack_group_data