local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local max_distance_data = Data:new()
local max_distance_data = {}

max_distance_data.pos_x = 0
max_distance_data.pos_y = 0
max_distance_data.neg_x = 0
max_distance_data.neg_y = 0

function max_distance_data:new(o)
    Log.debug("max_distance_data:new")
    Log.info(o)

    local defaults = {
        pos_x = self.pos_x,
        pos_y = self.pos_y,
        neg_x = self.neg_x,
        neg_y = self.neg_y,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self

    return obj
end

function max_distance_data:is_valid()
    return  type(self.pos_x) == "number"
        and type(self.pos_y) == "number"
        and type(self.neg_x) == "number"
        and type(self.neg_y) == "number"
end

max_distance_data = max_distance_data:new(max_distance_data)

return max_distance_data