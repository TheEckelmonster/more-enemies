local mods = mods

local Runtime_Global_Settings_Constants = require("settings.runtime-global.runtime-global-settings-constants")

local Constants = require("scripts.constants.constants")
local Log_Settings = require("__TheEckelmonster-core-library__.libs.log.log-settings")

local BREAM_Settings_Constants = require("libs.constants.settings.mods.BREAM.BREAM-settings-constants")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")

-- data:extend({
--     Runtime_Global_Settings_Constants.settings.CLONES_PER_TICK,
--     Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME,
--     Runtime_Global_Settings_Constants.settings.NTH_TICK,
-- })

-- data:extend({
--     Runtime_Global_Settings_Constants.settings.MINIMUM_ATTACK_GROUP_DELAY,
--     Runtime_Global_Settings_Constants.settings.MAXIMUM_ATTACK_GROUP_DELAY,
-- })

for _, setting in pairs(Runtime_Global_Settings_Constants.settings) do
    data:extend({ setting, })
end

if (mods and (mods["BREAM"])) then
    data:extend({
        Global_Settings_Constants.settings.MAXIMUM_NUMBER_OF_MODDED_CLONES,
    })

    data:extend({
        BREAM_Settings_Constants.settings.BREAM_DO_CLONE,
        BREAM_Settings_Constants.settings.BREAM_USE_EVOLUTION_FACTOR,
        BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS,
    })
end


data:extend(Log_Settings.create({ prefix = Constants.mod_name, settings_array = Runtime_Global_Settings_Constants.settings }))