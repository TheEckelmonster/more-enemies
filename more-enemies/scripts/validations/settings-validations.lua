local Log = require("libs.log.log")

local settings_validations = {}

function settings_validations.validate_setting_not_equal_to(setting, value)
    if (setting and setting.value and setting.value ~= value) then
        return true
    else
        return false
    end
end

-- function settings_validations.validate_setting_not_equal_to(setting, value)
--   if (setting and value and setting ~= value) then
--     return true
--   else
--     return false
--   end
-- end

return settings_validations
