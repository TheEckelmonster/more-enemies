local defines = defines
local prototypes = defines and defines.prototypes
local entity = prototypes and prototypes.entity
local data = data

local Settings_Utils = require("scripts.utils.settings-utils")

local names = Settings_Utils.get_attack_group_blacklist_names()

for _, v in pairs(names) do
    local name = nil

    if (type(v) == "string" and #v > 0) then
        for k, _ in pairs(entity or {}) do
            if (data and data.raw and data.raw[k] and data.raw[k][v]) then
                name = v
                break
            end
        end

        if (not name) then error("Could not find entity with name: " .. v) end
    end
end