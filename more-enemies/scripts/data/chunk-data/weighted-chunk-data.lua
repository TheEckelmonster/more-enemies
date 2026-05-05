local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local weighted_chunk_data = {}

weighted_chunk_data.chunks_weighted = {}
weighted_chunk_data.highest = nil
weighted_chunk_data.size = 0

function weighted_chunk_data:new(o)
    Log.debug("weighted_chunk_data:new")
    Log.info(o)

    local defaults = {
        chunks_weighted = {},
        -- highest = self.highest,
        size = self.size,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

-- weighted_chunk_data = weighted_chunk_data:new(weighted_chunk_data)
setmetatable(weighted_chunk_data, Data)
weighted_chunk_data.__index = weighted_chunk_data

return weighted_chunk_data