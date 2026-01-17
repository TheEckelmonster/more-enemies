local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local minor_data = {}
local Minor_Data = {}

minor_data.value = 0
minor_data.warned = false
minor_data.valid = true

function minor_data:new(o)
    Log.debug("minor_data:new")
    Log.info(o)

    local defaults = {
        value = minor_data.value,
        warned = minor_data.warned,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self

    return obj
end

-- minor_data = minor_data:new(minor_data)
Minor_Data = minor_data:new(Minor_Data)

-- return minor_data
return Minor_Data