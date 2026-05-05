local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local Log = require("libs.log.log")
local Pollution_Data = require("scripts.data.chunk-data.pollution-data")
local Recent_Death_Data = require("scripts.data.chunk-data.recent-deaths-data")

local chunk_data = Data:new()

chunk_data.above = nil
chunk_data.below = nil
chunk_data.chunk_size = Constants.CHUNK_SIZE
chunk_data.deaths = 0
chunk_data.entities = {}
chunk_data.entity_count = 0
chunk_data.nearby_spawners = {}
chunk_data.pollution_data = Pollution_Data:new()
chunk_data.recent_deaths = Recent_Death_Data:new()
chunk_data.rocket_launches = 0
chunk_data.spawners = {}
chunk_data.spawner_count = 0
chunk_data.surface = nil
chunk_data.surface_name = nil
chunk_data.tick_current = 0
chunk_data.tick_attack = 0
chunk_data.tick_attack_next = 0
chunk_data.tick_next = 0
chunk_data.tick_past = 0
chunk_data.tick_rocket_launch_witnessed = nil
chunk_data.tick_witnessed = nil
chunk_data.weight = 0
chunk_data.witnessed = false
chunk_data.witnessed_data = {
    oldest = nil,
    newest = nil,
}
-- chunk_data.witnessed_count = 0
chunk_data.x = 0
chunk_data.y = 0

function chunk_data:new(obj)
    Log.debug("chunk_data:new")
    Log.info(obj)

    -- obj = obj and Data:new(obj) or Data:new()
    obj = Data:new(obj) or Data:new()

    local defaults = {
        above = self.above,
        below = self.below,
        chunk_size = self.chunk_size,
        entities = {},
        entity_count = self.entity_count,
        deaths = self.deaths,
        nearby_spawners = {},
        pollution_data = Pollution_Data:new(),
        recent_deaths = Recent_Death_Data:new(),
        rocket_launches = self.rocket_launches,
        spawners = {},
        spawner_count = self.spawner_count,
        surface = self.surface,
        surface_name = self.surface_name,
        tick_attack = self.tick_attack,
        tick_attack_next = self.tick_attack_next,
        tick_current = self.tick_current,
        tick_next = self.tick_next,
        tick_past = self.tick_past,
        tick_rocket_launch_witnessed = self.tick_rocket_launch_witnessed,
        tick_witnessed = self.tick_witnessed,
        weight = self.weight,
        witnessed = self.witnessed,
        witnessed_data = Data:new({
            -- queue = {},
            oldest = nil,
            newest = nil,
            count = 0,
        }),
        -- witnessed_count = self.witnessed_count,
        x = self.x,
        y = self.y,
    }

    for k, v in pairs(defaults) do
        if (obj[k] == nil) then obj[k] = v end
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

setmetatable(chunk_data, Data)
chunk_data.__index = chunk_data

return chunk_data