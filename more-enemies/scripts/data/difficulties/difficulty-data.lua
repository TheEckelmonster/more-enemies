local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Log = require("libs.log.log")

local difficulty_data = {}

difficulty_data.order = nil
difficulty_data.name = "VANILLA"
difficulty_data.string_val = "Vanilla"
difficulty_data.type = "difficulty_data"
difficulty_data.value = 1
difficulty_data.radius = 30
difficulty_data.radius_modifier = 1

function difficulty_data:new(o)
    Log.debug("difficulty_data:new")
    Log.info(o)

    local defaults = {
        -- order = self.order,
        order = nil,
        name = self.name,
        string_val = self.string_val,
        value = self.value,
        radius = self.radius,
        radius_modifier = self.radius_modifier,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    obj.valid = obj:is_valid()

    return obj
end

setmetatable(difficulty_data, Data)
difficulty_data.__index = difficulty_data

return difficulty_data