local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local major_data = Data:new()
local major_data = {}
local Major_data = {}

major_data.value = 0
major_data.warned = false
major_data.valid = true

function major_data:new(o)
    Log.debug("major_data:new")
    Log.info(o)

    local defaults = {
        value = major_data.value,
        warned = major_data.warned,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self

    return obj
end

-- major_data = major_data:new(major_data)
Major_data = major_data:new(Major_data)

-- return major_data
return Major_data