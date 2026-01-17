-- require("libs.log.log-settings")
require("settings.nauvis.nauvis")
require("settings.global")

if (mods) then
    if (mods["space-age"]) then require("settings.gleba.gleba") end
    if (mods["ArmouredBiters"]) then require("settings.mods.armoured-biters") end
    if (mods["Cold_biters"]) then require("settings.mods.cold-biters") end
    if (mods["Explosive_biters"]) then require("settings.mods.explosive-biters") end
    if (mods["old_biters_remastered"]) then require("settings.mods.proto-biters") end
    if (mods["Toxic_biters"]) then require("settings.mods.toxic-biters") end
end

-- local Settings_Utils = require("__TheEckelmonster-core-library__.libs.utils.settings-utils")
-- local Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

-- data:extend(Settings_Utils.order_settings({ settings = Runtime_Global_Settings_Constants.settings }).array)

local Constants = require("scripts.constants.constants")
local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")

data:extend(Log_Settings.create({ prefix = Constants.mod_name, settings_array = {} }))