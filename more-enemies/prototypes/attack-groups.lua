local Settings_Utils = require("scripts.utils.settings-utils")

local names = Settings_Utils.get_attack_group_blacklist_names()

-- log(serpent.block(names))

-- for k, _ in pairs(defines.prototypes["entity"]) do
--     log(serpent.block(k))
-- end

for _, v in pairs(names) do
    local name = nil
    -- log(serpent.block(v))

    if (type(v) == "string" and #v > 0) then
        for k, _ in pairs(defines.prototypes["entity"]) do
            -- log(serpent.block(k))
            if (data and data.raw and data.raw[k] and data.raw[k][v]) then
                name = v
                break
            end
        end

        if (not name) then error("Could not find entity with name: " .. v) end
    end
end