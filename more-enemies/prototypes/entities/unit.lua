local data = data

local flag_to_add = "get-by-unit-number"

for _, unit in pairs(data.raw.unit or {}) do
    local found = false
    for _, flag in ipairs(unit.flags or {}) do
        if (flag == flag_to_add) then
            found = true
            break
        end
    end

    if (not found) then
        unit.flags = unit.flags or {}
        unit.flags[#unit.flags+1] = flag_to_add
    end
end