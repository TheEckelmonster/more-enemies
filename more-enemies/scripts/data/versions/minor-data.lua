local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Log = require("libs.log.log")

local minor_data = {}

minor_data.value = 0

function minor_data:new(o)
    Log.debug("minor_data:new")
    Log.info(o)

    local defaults = {
        value = minor_data.value,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(minor_data, Data)
minor_data.__index = minor_data

return minor_data