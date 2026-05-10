local Difficulty_Data = require("scripts.data.difficulties.difficulty-data")
local Log = require("libs.log.log")

local insanity_difficulty_data = {}

insanity_difficulty_data.order = nil
insanity_difficulty_data.name = "INSANITY"
insanity_difficulty_data.string_val = "Insanity"
insanity_difficulty_data.value = 11
insanity_difficulty_data.radius = 58.59375
insanity_difficulty_data.radius_modifier = 1.953125

function insanity_difficulty_data:new(o)
    Log.debug("insanity_difficulty_data:new")
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

setmetatable(insanity_difficulty_data, Difficulty_Data)
insanity_difficulty_data.__index = insanity_difficulty_data

return insanity_difficulty_data