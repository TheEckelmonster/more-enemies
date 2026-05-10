local data = data
local mods = mods

local Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

local Constants = require("scripts.constants.constants")
local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")

local Mod_Settings = require("scripts.constants.settings.mod-settings")

for _, setting in pairs(Runtime_Global_Settings_Constants.settings) do
    data:extend({ setting, })
end

if (mods and (mods["BREAM"])) then
    data:extend({
        Mod_Settings.MAXIMUM_NUMBER_OF_MODDED_CLONES,
    })

    data:extend({
        Mod_Settings.BREAM_DO_CLONE,
        Mod_Settings.BREAM_USE_EVOLUTION_FACTOR,
        Mod_Settings.BREAM_CLONE_UNITS,
    })
end

data:extend(Log_Settings.create({ prefix = Constants.mod_name, settings_array = Runtime_Global_Settings_Constants.settings }))