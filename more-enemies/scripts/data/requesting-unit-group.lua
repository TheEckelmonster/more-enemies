local setmetatable = setmetatable

local Data = Data or require("__TheEckelmonster-core-library__.libs.data.data")
local Data_new = Data.new

local NAUVIS = NAUVIS or "nauvis"
local ENEMY = ENEMY or "enemy"

local requesting_unit_group = {}

-- requesting_unit_group.count = 0
requesting_unit_group.enemies = {}
requesting_unit_group.surface_name = NAUVIS
requesting_unit_group.force_name = ENEMY
requesting_unit_group.start_position = nil
requesting_unit_group.target_position = nil
requesting_unit_group.xy = nil
requesting_unit_group.limit = 2^12
requesting_unit_group.path_id = -1
requesting_unit_group.path_request = nil
--[[ TODO: make configurable ]]
requesting_unit_group.attempts = 0
--[[ TODO: make configurable ]]
requesting_unit_group.retries = 1
requesting_unit_group.spider_unit = false

function requesting_unit_group:new(o)

    local obj = o or {}

    obj.enemies = obj.enemies or {}
    obj.surface_name = obj.surface_name or NAUVIS
    obj.force_name = obj.force_name or ENEMY
    obj.start_position = obj.start_position or self.start_position
    obj.target_position = obj.target_position or self.target_position
    obj.xy = obj.xy or self.xy
    obj.limit = obj.limit or self.limit
    obj.path_id = obj.path_id or self.path_id
    obj.path_request = obj.path_request or self.path_request
    --[[ TODO: make configurable ]]
    obj.attempts = obj.attempts or self.attempts
    --[[ TODO: make configurable ]]
    obj.retries = obj.retries or self.retries
    obj.spider_unit = obj.spider_unit or self.spider_unit

    self.__index = self
    return setmetatable(Data_new(Data, obj), self)
end

setmetatable(requesting_unit_group, Data)
requesting_unit_group.__index = requesting_unit_group

return requesting_unit_group