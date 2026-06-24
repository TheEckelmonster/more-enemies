local storage

local game

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage
    game = __game or _ENV.game
    return game
end

local setmetatable = setmetatable

local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local new_Data = Data.new

-- local target_registry_data = {
--     { max = 1, elements = {}, },
--     { max = 2, elements = {}, },
--     { max = 3, elements = {}, },
--     { max = 4, elements = {}, },
-- }
local target_registry_data = {}

for i = 1, 4, 1 do target_registry_data[i] = { max = i, elements = {}, } end

local function generate_registry(self, n, obj)
    obj = obj or setmetatable(new_Data(Data, {}), self)

    n = n or 1
    local i = 0
    while i < n do i = i + 1; obj[i] = { max = i, elements = {}, } end

    obj.pool = obj.pool or {}
    obj.pool_count = obj.pool_count or 0
    obj.mapped_idx = obj.mapped_idx or {}

    return obj
end

function target_registry_data:new(o, n)
    local obj = o or {}

    n = n or 1
    obj = generate_registry(self, n, obj)

    obj.nw = obj.nw or generate_registry(self, n)
    obj.ne = obj.ne or generate_registry(self, n)
    obj.sw = obj.sw or generate_registry(self, n)
    obj.se = obj.se or generate_registry(self, n)

    self.__index = self
    return setmetatable(new_Data(Data, obj), self)
end

function target_registry_data.merge_data(target_registry, chunk, surface_name, value, tick)
    if (not chunk or not chunk.xy) then return end
    if (not surface_name or not Valid_Surfaces[surface_name]) then return end
    value = value or 0
    tick = tick or (game or set_game()).tick

    local temp_container = chunk
    local current_value = value
    local found = {
        [chunk] = 0
    }

    for i = 1, #target_registry, 1 do
        local registry = target_registry[i]
        if (registry and registry.elements) then
            local element = nil
            local element_count = #registry.elements
            local elements = registry.elements
            local j = element_count
            local iterations = 0
            local slotted = false

            while j > 0 and iterations <= (registry.max or 0) do
                iterations = iterations + 1
                element = elements[j]
                if (element and not found[element]) then found[element] = (i * 10) + (j % 10) end
                if (element) then
                    if (current_value > (element.value or 0)) then
                        elements[j] = temp_container
                        temp_container = element
                        current_value = (element.value or 0)
                        slotted = true
                    end
                end

                j = j - 1
            end

            if (not slotted and (element_count < (registry.max or 0))) then
                elements[element_count + 1] = temp_container
                temp_container = nil
            end

            if (not temp_container) then break end
        end
    end

    if (not target_registry.mapped_idx[chunk.xy]) then
        local pool_count = (target_registry.pool_count or 0) + 1
        target_registry.pool[pool_count] = chunk
        target_registry.pool_count = pool_count
        target_registry.mapped_idx[chunk.xy] = pool_count
    end
end

function target_registry_data.init(__storage) storage = __storage or _ENV.storage end

setmetatable(target_registry_data, Data)
target_registry_data.__index = target_registry_data

return target_registry_data