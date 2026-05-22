local mods = mods or script and script.active_mods

local __Data_Utils = require("data-utils")

local startup_settings_constants = {}

startup_settings_constants.settings = {}

---

__Data_Utils.foreach(function(params)
    if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.startup.biters-constants")))
__Data_Utils.foreach(function(params)
    if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.startup.planets.nauvis-settings-constants")))

if (mods) then
    if (mods["space-age"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.pentapods-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.planets.gleba-settings-constants")))
    end
    if (mods["Arachnids_enemy"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.Arachnid_enemy-constants")))
    end
    if (mods["ArmouredBiters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.ArmouredBiters-constants")))
    end
    if (mods["Cold_biters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.Cold_biters-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.planets.aquilo-settings-constants")))
    end
    if (mods["Electric_flying_enemies"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.Electric_flying_enemies-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.planets.fulgora-settings-constants")))
    end
    if (mods["Explosive_biters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.Explosive_biters-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.planets.vulcanus-settings-constants")))
    end
    if (mods["Toxic_biters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.startup.compatibility.Toxic_biters-constants")))
    end
end

__Data_Utils.foreach(function(params)
    if (params and params.setting) then startup_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.startup.global")))

return startup_settings_constants