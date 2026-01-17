local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local Log = require("libs.log.log")
local Max_Distance_Data = require("scripts.data.max-distance-data")
-- local Queue_Data = require("scripts.data.structures.queue-data")
local Weighted_Chunk_Data = require("scripts.data.chunk-data.weighted-chunk-data")

local Queue_Data = require("__TheEckelmonster-core-library__.libs.data.structures.queue-data")

local overmind_data = {}

overmind_data.aggression = 0
overmind_data.controller_data = {}
-- overmind_data.chunks = { queue = Queue_Data:new(), }
-- overmind_data.chunks_2 = { queue = Queue_Data:new(), }
-- overmind_data.chunks_4 = { queue = Queue_Data:new(), }
-- overmind_data.chunks_8 = { queue = Queue_Data:new(), }
-- overmind_data.chunks_16 = { queue = Queue_Data:new(), }
-- overmind_data.chunks_32 = { queue = Queue_Data:new(), }
overmind_data.chunks = {}

overmind_data.chunks_deaths = Queue_Data:new()
overmind_data.chunks_pollution = Queue_Data:new()
overmind_data.chunks_priority_high = Queue_Data:new()
overmind_data.chunks_priority_low = Queue_Data:new()
overmind_data.chunks_priority_medium = Queue_Data:new()
overmind_data.chunks_update = Queue_Data:new()
overmind_data.chunks_weight = Queue_Data:new()
overmind_data.max_distance = Max_Distance_Data:new()
overmind_data.peace_time_tick = nil
overmind_data.radius = 1
overmind_data.spawners = {}
overmind_data.spawner_count = 0
-- overmind_data.staged_chunks = Data:new({
--     -- queue = {},
--     first = nil,
--     last = nil,
--     count = 0,
-- })
overmind_data.staged_chunks = Queue_Data:new()
overmind_data.surface = nil
overmind_data.surface_name = nil
overmind_data.tick = 0
overmind_data.unit_groups = {}
overmind_data.weighted_chunks = Weighted_Chunk_Data:new()

local locals = {
    ["get_default_chunks"] = function (data)
        Log.debug("locals.default_chunks")
        Log.info(data)

        if (data ~= nil and type(data) ~= "table") then return -1 end
        if (data ~= nil and data.queue and type(data.queue) ~= "table") then return -1 end

        local chunks = data or {}

        for k, _ in pairs(Constants.chunk_sizes) do
            if (k < Constants.CHUNK_LEVELS) then
                chunks["chunks_" .. k] = { queue = Queue_Data:new({ name = "chunks_" .. k, limit = 16 + (2.5 * 4) * (60 - k) }), }
            end
        end

        return chunks
    end,
}

function overmind_data:new(o)
    Log.debug("overmind_data:new")
    Log.info(o)

    local chunks = locals.get_default_chunks({})

    local defaults = {
        aggression = self.aggression,
        controller_data = {},
        -- chunks = { queue = Queue_Data:new({ name = "chunks", limit = 2 ^ 8 --[[TODO: Make limit configurable]] }, { include_meta_data = true }), },
        -- chunks_2 = { queue = Queue_Data:new({ name = "chunks_2", limit = 2 ^ 7 --[[TODO: Make limit configurable]] }, { include_meta_data = true }), },
        -- chunks_4 = { queue = Queue_Data:new({ name = "chunks_4", limit = 2 ^ 6 --[[TODO: Make limit configurable]] }, { include_meta_data = true }), },
        -- chunks_8 = { queue = Queue_Data:new({ name = "chunks_8", limit = 2 ^ 5 --[[TODO: Make limit configurable]] }, { include_meta_data = true }), },
        -- chunks_16 = { queue = Queue_Data:new({ name = "chunks_16", limit = 2 ^ 4 --[[TODO: Make limit configurable]] }, { include_meta_data = true }), },
        -- chunks_32 = { queue = Queue_Data:new({ name = "chunks_32", limit = 2 ^ 3 --[[TODO: Make limit configurable]] }, { include_meta_data = true }), },
        chunks = chunks,
        -- chunks_deaths = Queue_Data:new({ name = "chunks_deaths" }, { include_meta_data = true }),
        -- chunks_pollution = Queue_Data:new({ name = "chunks_pollution" }, { include_meta_data = true }),
        -- chunks_priority_high = Queue_Data:new({ name = "chunks_priority_high", limit = 2 ^ 9 --[[TODO: Make limit configurable]]}, { include_meta_data = true }),
        -- chunks_priority_low = Queue_Data:new({ name = "chunks_priority_low", limit = 2 ^ 6 --[[TODO: Make limit configurable]] }, { include_meta_data = true }),
        -- chunks_priority_medium = Queue_Data:new({ name = "chunks_priority_medium", limit = 2 ^ 7 --[[TODO: Make limit configurable]] }, { include_meta_data = true }),
        -- chunks_update = Queue_Data:new({ name = "chunks_update" }, { include_meta_data = true }),
        -- chunks_weight = Queue_Data:new({ name = "chunks_weight" }, { include_meta_data = true }),
        chunks_deaths = Queue_Data:new({ name = "chunks_deaths" }),
        chunks_pollution = Queue_Data:new({ name = "chunks_pollution" }),
        chunks_priority_high = Queue_Data:new({ name = "chunks_priority_high", limit = 2 ^ 9 --[[TODO: Make limit configurable]]}),
        chunks_priority_low = Queue_Data:new({ name = "chunks_priority_low", limit = 2 ^ 6 --[[TODO: Make limit configurable]] }),
        chunks_priority_medium = Queue_Data:new({ name = "chunks_priority_medium", limit = 2 ^ 7 --[[TODO: Make limit configurable]] }),
        chunks_update = Queue_Data:new({ name = "chunks_update" }),
        chunks_weight = Queue_Data:new({ name = "chunks_weight" }),
        max_distance = Max_Distance_Data:new(_, { include_meta_data = true }),
        peace_time_tick = nil,
        radius = self.radius,
        spawners = {},
        spawner_count = self.spawner_count,
        -- staged_chunks = Queue_Data:new({ name = "staged_chunks", limit = 2 ^ 8 --[[TODO: Make limit configurable]] }, { include_meta_data = true }),
        staged_chunks = Queue_Data:new({ name = "staged_chunks", limit = 2 ^ 8 --[[TODO: Make limit configurable]] }),
        surface = nil,
        surface_name = nil,
        tick = self.tick,
        unit_groups = {},
        weighted_chunks = Weighted_Chunk_Data:new(_, { include_meta_data = true }),
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj, { include_meta_data = true })

    -- setmetatable(overmind_data, Data)
    setmetatable(obj, self)
    self.__index = self

    obj.valid = false

    return obj
end

function overmind_data:reinit(obj)
    Log.debug("overmind_data:reinit")
    Log.info(obj)

    obj = obj or Data:new(_, { include_meta_data = true })

    local chunks = locals.get_default_chunks({})

    local defaults = Data:new({
        aggression = self.aggression,
        controller_data = {},
        -- chunks = { queue = Queue_Data:new({ name = "chunks" }), },
        -- chunks_2 = { queue = Queue_Data:new({ name = "chunks_2" }), },
        -- chunks_4 = { queue = Queue_Data:new({ name = "chunks_4" }), },
        -- chunks_8 = { queue = Queue_Data:new({ name = "chunks_8" }), },
        -- chunks_16 = { queue = Queue_Data:new({ name = "chunks_16" }), },
        -- chunks_32 = { queue = Queue_Data:new({ name = "chunks_32" }), },
        chunks = chunks,
        chunks_deaths = Queue_Data:new({ name = "chunks_deaths" }),
        chunks_pollution = Queue_Data:new({ name = "chunks_pollution" }),
        chunks_priority_high = Queue_Data:new({ name = "chunks_priority_high" }),
        chunks_priority_low = Queue_Data:new({ name = "chunks_priority_low" }),
        chunks_priority_medium = Queue_Data:new({ name = "chunks_priority_medium" }),
        chunks_update = Queue_Data:new({ name = "chunks_update" }),
        chunks_weight = Queue_Data:new({ name = "chunks_weight" }),
        max_distance = Max_Distance_Data:new(),
        peace_time_tick = nil,
        radius = self.radius,
        spawners = {},
        spawner_count = self.spawner_count,
        staged_chunks = Queue_Data:new(),
        surface = nil,
        surface_name = nil,
        tick = self.tick,
        unit_groups = {},
        weighted_chunks = Weighted_Chunk_Data:new(),
    }, { include_meta_data = true })

    for k, v in pairs(defaults) do obj[k] = v end

    -- setmetatable(overmind_data, Data)
    setmetatable(obj, self)
    self.__index = self

    return obj
end


setmetatable(overmind_data, Data)
overmind_data.__index = overmind_data

return overmind_data

-- local Overmind_Data = overmind_data:new(Overmind_Data)

-- return Overmind_Data