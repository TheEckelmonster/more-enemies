local data = data

local Startup_Settings_Constants = require("settings.startup.startup-settings-constants")

for _, setting in pairs(Startup_Settings_Constants.settings) do data:extend({ setting, }) end