local next = next
local pairs = pairs

local entity_black_list, entity_white_list = require("scripts.constants.on-entity-died-filters")()

local filter = {}

for k, v in pairs(entity_black_list) do
    if (next(entity_black_list, k)) then
        filter[#filter+1] = { filter = "type", type = k, invert = true, mode = "and" }
    else
        filter[#filter+1] = { filter = "type", type = k, invert = true, }
    end
end

for k, v in pairs(entity_white_list) do
    filter[#filter+1] = { filter = "type", type = k, }
end

return filter