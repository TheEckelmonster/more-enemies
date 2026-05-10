local settings_validations = {}

function settings_validations.validate_setting_not_equal_to(setting, value)
    return setting and setting.value and setting.value ~= value
end

return settings_validations
