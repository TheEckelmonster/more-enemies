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

    local obj = o or {}

    obj.difficulty = obj.difficulty or Vanilla_Difficulty_Data:new()
    obj.surface = obj.surface or nil
    obj.entities_spawned = obj.entities_spawned or 0

    self.__index = self
    return setmetatable(Data:new(obj), self)
end

setmetatable(difficulty_data, Data)
difficulty_data.__index = difficulty_data

return difficulty_data