local data = data

local Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

local Constants = require("scripts.constants.constants")
local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")

for _, setting in pairs(Runtime_Global_Settings_Constants.settings) do data:extend({ setting, }) end

data:extend(Log_Settings.create({ prefix = Constants.mod_name, settings_array = {} }))