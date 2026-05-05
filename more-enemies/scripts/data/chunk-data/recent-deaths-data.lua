local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local recent_deaths_data = Data:new()
local recent_deaths_data = {}

recent_deaths_data.average_deaths_per_second = 0
recent_deaths_data.average_deaths_per_tick = 0
recent_deaths_data.deaths = 0
recent_deaths_data.modifier = 1
recent_deaths_data.tick_current = nil
recent_deaths_data.tick_next = nil
recent_deaths_data.tick_past = nil

function recent_deaths_data:new(o)
    Log.debug("recent_deaths_data:new")
    Log.info(o)

    local defaults = {
        average_deaths_per_second = self.average_deaths_per_second,
        average_deaths_per_tick = self.average_deaths_per_tick,
        deaths = self.deaths,
        modifier = self.modifier,
        tick_current = game and game.tick,
        tick_next = game and game.tick,
        tick_past = game and game.tick,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    -- setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self

    return obj
end

-- recent_deaths_data = recent_deaths_data:new(recent_deaths_data)
setmetatable(recent_deaths_data, Data)
recent_deaths_data.__index = recent_deaths_data

return recent_deaths_data