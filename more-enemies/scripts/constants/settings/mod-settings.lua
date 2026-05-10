if (_mod_settings and _mod_settings.more_enemies) then
    return _mod_settings
end

local mod_settings = {
    ["Armoured_Biters_Settings"] = require("scripts.constants.settings.mods.armoured-biters.armoured-biters-settings-constants"),
    ["BREAM_Settings"] = require("scripts.constants.settings.mods.BREAM.BREAM-settings-constants"),
    ["Cold_Biters_Settings"] = require("scripts.constants.settings.mods.cold-biters-settings-constants"),
    ["Explosive_Biters_Settings"] = require("scripts.constants.settings.mods.explosive-biters-settings-constants"),
    ["Proto_Biters_Settings"] = require("scripts.constants.settings.mods.proto-biters-settings-constants"),
    ["Toxic_Biters_Settings"] = require("scripts.constants.settings.mods.toxic-biters-settings-constants"),
    ["Gleba_Settings"] = require("scripts.constants.settings.gleba-settings-constants"),
    ["Global_Settings"] = require("scripts.constants.settings.global-settings-constants"),
    ["Nauvis_Settings"] = require("scripts.constants.settings.nauvis-settings-constants"),
}

local settings_table = {}

for k, v in pairs(mod_settings) do
    if (type(k) == "string" and type(v) == "table" and type(v.settings) == "table") then
        for i, j in pairs(v.settings) do
            settings_table[i] = j
        end
    end
end

---@diagnostic disable-next-line: lowercase-global
_mod_settings = settings_table

return settings_table