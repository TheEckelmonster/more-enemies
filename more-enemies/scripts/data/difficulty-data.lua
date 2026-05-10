local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Log = require("libs.log.log")
local Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")

local difficulty_data = {}

difficulty_data.difficulty = Vanilla_Difficulty_Data:new()
difficulty_data.surface = nil
difficulty_data.entities_spawned = 0

function difficulty_data:new(o)
    Log.debug("difficulty_data:new")
    Log.info(o)

    local defaults = {
        difficulty = self.difficulty,
        surface = self.surface,
        entities_spawned = self.entities_spawned,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(difficulty_data, Data)
difficulty_data.__index = difficulty_data

return difficulty_data