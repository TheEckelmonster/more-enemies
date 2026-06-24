local setmetatable = setmetatable

local Data = Data or require("__TheEckelmonster-core-library__.libs.data.data")
local Data_new = Data.new

local NAUVIS = NAUVIS or "nauvis"
local ENEMY = ENEMY or "enemy"

local scout_group_data = {}

-- scout_group_data.enemies = {}
scout_group_data.surface_name = NAUVIS
scout_group_data.force_name = ENEMY
scout_group_data.start_position = nil
scout_group_data.last_position = nil
scout_group_data.target_position = nil
scout_group_data.xy = nil
scout_group_data.limit = 2^12
scout_group_data.spider_unit = false
scout_group_data.group = nil

function scout_group_data:new(o)

    local obj = o or {}

    -- obj.enemies = obj.enemies or {}
    obj.surface_name = obj.surface_name or NAUVIS
    obj.force_name = obj.force_name or ENEMY
    -- obj.start_position = obj.start_position or self.start_position
    -- obj.last_position = obj.last_position or self.last_position
    -- obj.target_position = obj.target_position or self.target_position
    -- obj.xy = obj.xy or self.xy
    obj.limit = obj.limit or self.limit
    obj.spider_unit = obj.spider_unit or self.spider_unit
    -- obj.group = obj.group or self.group

    self.__index = self
    return setmetatable(Data_new(Data, obj), self)
end

setmetatable(scout_group_data, Data)
scout_group_data.__index = scout_group_data

return scout_group_data