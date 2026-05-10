-- local Settings_Utils = require("__TheEckelmonster-core-library__.libs.utils.settings-utils")

local __Data_Utils = require("data-utils")

local runtime_global_settings_constants = {}

local prefix = "more-enemies-"

runtime_global_settings_constants.settings = {}

__Data_Utils.foreach(function(params)
    if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.runtime-global.planets.nauvis-settings-constants")))

__Data_Utils.foreach(function(params)
    if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.runtime-global.planets.gleba-settings-constants")))

__Data_Utils.foreach(function(params)
    if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.runtime-global.global")))

-- local order_settings = Settings_Utils.order_settings({ settings = runtime_global_settings_constants.settings })
-- runtime_global_settings_constants.settings_array = order_settings.array
-- runtime_global_settings_constants.settings_dictionary = order_settings.dictionary

return runtime_global_settings_constants