
local Log = require("libs.log.log")

local entity_validations = {}

local check_for_mod_name = function(entity)
    return entity.mod_name and true or false
end

function entity_validations.get_mod_name(entity)
    local return_val = nil

    if (pcall(check_for_mod_name, entity)) then
        return_val = entity.mod_name
    end

    return return_val
end

return entity_validations