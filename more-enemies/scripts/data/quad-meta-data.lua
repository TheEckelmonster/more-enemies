local setmetatable = setmetatable

local quad_meta_data = {}

function quad_meta_data:new_template(tick)
    return setmetatable({
        created = tick,
        updated = tick,
    }, self)
end

quad_meta_data.__index = quad_meta_data

return quad_meta_data