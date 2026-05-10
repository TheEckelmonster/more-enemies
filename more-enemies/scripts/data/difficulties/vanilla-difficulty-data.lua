local Difficulty_Data = require("scripts.data.difficulties.difficulty-data")
local Log = require("libs.log.log")

local vanilla_difficulty_data = {}

vanilla_difficulty_data.order = nil
vanilla_difficulty_data.name = "VANILLA"
vanilla_difficulty_data.string_val = "Vanilla"
vanilla_difficulty_data.type = "difficulty_data"
vanilla_difficulty_data.value = 1
vanilla_difficulty_data.radius = 30
vanilla_difficulty_data.radius_modifier = 1

function vanilla_difficulty_data:new(o)
    Log.debug("vanilla_difficulty_data:new")
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

    setmetatable(obj, self)
    self.__index = self

    return obj
end

setmetatable(vanilla_difficulty_data, Difficulty_Data)
vanilla_difficulty_data.__index = vanilla_difficulty_data

return vanilla_difficulty_data