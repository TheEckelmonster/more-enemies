-- local Data = require("scripts.data.data")
local Difficulty_Data = require("scripts.data.difficulties.difficulty-data")
local Log = require("libs.log.log")

-- local easy_difficulty_data = Difficulty_Data:new()
local easy_difficulty_data = {}

easy_difficulty_data.order = nil
easy_difficulty_data.name = "EASY"
easy_difficulty_data.string_val = "Easy"
-- easy_difficulty_data.type = "difficulty_data"
easy_difficulty_data.value = 0.1
easy_difficulty_data.radius = 15
easy_difficulty_data.radius_modifier = 0.5

function easy_difficulty_data:new(o)
    Log.debug("easy_difficulty_data:new")
    Log.info(o)

    local defaults = {
        -- order = self.order,
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

    -- setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self

    return obj
end

-- easy_difficulty_data = easy_difficulty_data:new(easy_difficulty_data)
setmetatable(easy_difficulty_data, Difficulty_Data)
easy_difficulty_data.__index = easy_difficulty_data

return easy_difficulty_data