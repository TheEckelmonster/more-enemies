local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local pollution_data = Data:new()
local pollution_data = {}

pollution_data.pollution = 0
pollution_data.tick_current = 0
pollution_data.tick_next = 0
pollution_data.tick_past = 0

function pollution_data:new(obj)
    Log.debug("pollution_data:new")
    Log.info(obj)

    local defaults = {
        pollution = self.pollution,
        tick_current = self.tick_current,
        tick_next = self.tick_next,
        tick_past = self.tick_past,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    -- setmetatable(pollution_data, Data)
    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(pollution_data, Data)
pollution_data.__index = pollution_data

return pollution_data
-- local Pollution_Data = pollution_data:new(Pollution_Data)

-- return Pollution_Data