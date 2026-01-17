local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local event_data = {}
-- local Event_data = {
--     mt = event_data
-- }



function event_data:get(data)
    Log.debug("event_data:get")
    Log.info(data)

    if (not storage.event_data) then storage.event_data = event_data:new() end
    local _event_data = storage.event_data
    -- if (not storage.Event_Data) then storage.Event_Data = event_data:new() end
    -- local _event_data = storage.Event_Data
    -- log(serpent.block(_event_data))

    if (not getmetatable(_event_data)) then
        log("found no meta table")
        setmetatable(_event_data, event_data)
    end
    -- _event_data.valid = _event_data:is_valid()
    _event_data.valid = event_data.is_valid(_event_data)
    _event_data.tick_retrieved = game.tick

    if (_event_data.tick_times_retrieved and _event_data.tick_retrieved == game.tick) then
        _event_data.tick_times_retrieved = _event_data.tick_times_retrieved + 1
    else
        _event_data.tick_times_retrieved = 1
    end

    return _event_data
end

function event_data:new(o, data)
    Log.debug("event_data:new")
    Log.info(o)

    local defaults = {
        deviation_average = Constants.SMALL_NUM,
        deviation_average_1 = Constants.SMALL_NUM,
        deviation_average_2 = 0,
        deviation_average_3 = 0,
        deviation_1 = 0,
        deviation_2 = 0,
        deviation_3 = 0,
        deviation_4 = 0,
        deviation_5 = 0,
        deviation_6 = 0,
        deviation_7 = 0,
        deviation_8 = 0,
    }

    for _, v in pairs(Constants.time.TICKS) do defaults[v] = { name = v, count = 0, tick = 0, } end

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    -- setmetatable(event_data, Data)
    setmetatable(obj, self)
    self.__index = self

    return obj
end

function event_data:get_deviation(data)
    Log.debug("event_data:get_deviation")
    Log.info(data)

    local return_val = 0

    if (not data or type(data) ~= "table") then return return_val end
    if (not data.count or type(data.count) ~= "number" or data.count < 1) then data.count = 2 end
    if (data.count < 2) then data.count = 2 end

    local _event_data = event_data:get()

    _event_data:update(data)

    return _event_data.deviation_1
end

function event_data:get_deviation_average(data)
    Log.debug("event_data:get_deviation_average")
    Log.info(data)

    if (data and type(data) ~= "table") then return end

    local _event_data = event_data:get()

    _event_data:update(data)

    return _event_data.deviation_average
end

function event_data:reset(data)
    Log.debug("event_data:reset")
    Log.info(data)

    if (data and type(data) ~= "table") then return end
    if (data.type and type(data.index) ~= "number") then return end

    local _event_data = event_data:get()

    if (not getmetatable(_event_data)) then
        log("found no meta table")
        setmetatable(_event_data, event_data)
    end

    _event_data[data.index].count = 0
    _event_data[data.index].tick = game.tick
    -- _event_data[data.index].updated = game.tick
    -- Data.update(_event_data[data.index])
end

function event_data:increment(data)
    Log.debug("event_data:increment")
    Log.info(data)

    if (data and type(data) ~= "table") then return end

    local _event_data = event_data:get()

    for _, v in pairs(Constants.time.TICKS) do
        _event_data[v].count = _event_data[v].count + 1
        _event_data[v].tick = game.tick
        -- Data.update(_event_data[v])
    end

    -- Data.update(_event_data)
end

function event_data:update(data)
    Log.debug("event_data:update")
    Log.info(data)

    if (data == nil or type(data) ~= "table") then data = {} end

    if (not data.count or type(data.count) ~= "number" or data.count < 1) then data.count = 2 end
    if (data.count < 2) then data.count = 2 end

    local mean = 0
    local variance = 0

    local _event_data = event_data:get()

    local count = 1
    for _, v in pairs(_event_data) do
        if (type(v) == "table") then
            mean = mean + (v.count / v.name)
            count = count + 1
            if (count > data.count) then break end
        end
    end

    mean = mean / data.count

    count = 1
    for _, v in pairs(_event_data) do
        if (type(v) == "table") then
            variance = variance + ((v.count / v.name) - mean) ^ 2
            count = count + 1
            if (count > data.count) then break end
        end
    end

    local return_val = (variance / (data.count - 1)) ^ 0.5

    _event_data.deviation_8 = _event_data.deviation_7
    _event_data.deviation_7 = _event_data.deviation_6
    _event_data.deviation_6 = _event_data.deviation_5
    _event_data.deviation_5 = _event_data.deviation_4
    _event_data.deviation_4 = _event_data.deviation_3
    _event_data.deviation_3 = _event_data.deviation_2
    _event_data.deviation_2 = _event_data.deviation_1
    _event_data.deviation_1 = return_val
    _event_data.deviation_average_3 = _event_data.deviation_average_2
    _event_data.deviation_average_2 = _event_data.deviation_average_1
    _event_data.deviation_average_1 = Constants.SMALL_NUM + (
          _event_data.deviation_1
        + _event_data.deviation_2
        + _event_data.deviation_3
        + _event_data.deviation_4
        + _event_data.deviation_5
        + _event_data.deviation_6
        + _event_data.deviation_7
        + _event_data.deviation_8
    ) / 8

    _event_data.deviation_average = (
          _event_data.deviation_average_1
        + _event_data.deviation_average_2
        + _event_data.deviation_average_3
    ) / 3


    -- if (data.index and type(data.index) == "number" and data.index >= 0) then
    --     _event_data[data.index].count = _event_data[data.index].count + 1
    --     _event_data[data.index].tick = game.tick

    --     Data.update(_event_data[data.index])
    -- else
    --     Data.update(_event_data)
    -- end
end

function event_data:is_valid()
    Log.debug("event_data:is_valid")
    return  self.created ~= nil
        and type(self.created) == "number"
        and self.created >= 0
        and self.updated ~= nil
        and type(self.updated) == "number"
        and self.updated >= self.created
end

setmetatable(event_data, Data)
event_data.__index = event_data
return event_data

-- Event_data = event_data:new(Event_data)

-- return Event_data