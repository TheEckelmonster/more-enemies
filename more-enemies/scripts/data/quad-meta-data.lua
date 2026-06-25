local setmetatable = setmetatable

local quad_meta_data = {}

function quad_meta_data:new_template(tick)
    return setmetatable({
        spawner_count = 0,
        entity_count = 0,

        created = tick,
        updated = tick,
    }, self)
end

quad_meta_data.__index = quad_meta_data

return quad_meta_data