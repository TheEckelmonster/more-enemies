local data = data
local mods = mods

local BREAM_Settings_Constants = require("libs.constants.settings.mods.BREAM.BREAM-settings-constants")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")
local Mod_Settings = require("scripts.constants.settings.mod-settings")

data:extend({
    Mod_Settings.NAUVIS_DIFFICULTY,
    Mod_Settings.GLEBA_DIFFICULTY,
    Mod_Settings.MAX_GATHERING_UNIT_GROUPS,
    Mod_Settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST,
    Mod_Settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST,
    Mod_Settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST,
    Mod_Settings.SHORT_REQUEST_MAX_STEPS,
})

data:extend({
    Global_Settings_Constants.settings.ATTACK_GROUP_BLACKLIST_NAMES,
})

if (mods and (mods["BREAM"])) then

    data:extend({
        BREAM_Settings_Constants.settings.BREAM_DIFFICULTY,
    })
end