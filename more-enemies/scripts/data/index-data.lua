local Data = require("scripts.data.data")
local Log = require("libs.log.log")

-- local index_data = Data:new()
local index_data = {
    type = "index_data",
}
-- local Index_Data = {
--     mt = index_data
-- }

-- index_data.__concat = function(t)
--     log("¿hola, como estas?")
--     log(tostring(serpent.block(t)))
--     -- return t.index
--     -- return Index_Data.index
--     return index_data.index
-- end

index_data.index = -1

function index_data:new(o)
    Log.debug("index_data:new")
    Log.info(o)

    local defaults = {
        index = game and game.tick or self.index
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    -- setmetatable(index_data, Data)
    setmetatable(obj, self)
    self.__index = self
    self.__concat = function(l, r)
        if (type(l) == "table") then l = l.index and l.index or "" end
        if (type(r) == "table") then r = r.index and r.index or "" end

        return string.format("%s%s", l, r)
    end

    return obj
end

setmetatable(index_data, Data)
index_data = index_data:new(index_data)
-- Index_Data = index_data:new(Index_Data)

return index_data
-- return Index_Data