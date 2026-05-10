local Difficulty_Data = require("scripts.data.difficulties.difficulty-data")
local Log = require("libs.log.log")

local hard_difficulty_data = {}

hard_difficulty_data.order = nil
hard_difficulty_data.name = "HARD"
hard_difficulty_data.string_val = "Hard"
hard_difficulty_data.type = "difficulty_data"
hard_difficulty_data.value = 4
hard_difficulty_data.radius = 46.875
hard_difficulty_data.radius_modifier = 1.5625

function hard_difficulty_data:new(o)
    Log.debug("hard_difficulty_data:new")
    Log.info(o)

    local defaults = {
        order = nil,
        name = self.name,
        string_val = self.string_val,
        value = self.value,
        radius = self.radius,
        radius_modifier = self.radius_modifier,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Difficulty_Data:new(obj)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(hard_difficulty_data, Difficulty_Data)
hard_difficulty_data.__index = hard_difficulty_data

return hard_difficulty_data