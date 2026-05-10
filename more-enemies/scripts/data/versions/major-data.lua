local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Log = require("libs.log.log")

local major_data = {}

major_data.value = 0

function major_data:new(o)
    Log.debug("major_data:new")
    Log.info(o)

    local defaults = {
        value = major_data.value,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(major_data, Data)
major_data.__index = major_data

return major_data