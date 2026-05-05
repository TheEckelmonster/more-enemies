local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local nth_tick_data = Data:new()
local nth_tick_data = {}

nth_tick_data.current = true
nth_tick_data.previous = true

function nth_tick_data:new(o)
    Log.debug("nth_tick_data:new")
    Log.info(o)

    local defaults = {
        current = self.current,
        previous = self.previous,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self
    return obj
end

nth_tick_data = nth_tick_data:new(nth_tick_data)

return nth_tick_data