local mods = mods or script and script.active_mods

local __Data_Utils = require("data-utils")

local runtime_global_settings_constants = {}

runtime_global_settings_constants.settings = {}

---

__Data_Utils.foreach(function(params)
    if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.runtime-global.biter-constants")))
__Data_Utils.foreach(function(params)
    if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.runtime-global.planets.nauvis-settings-constants")))

if (mods) then
    if (mods["space-age"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.pentapod-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.planets.gleba-settings-constants")))
    end
    if (mods["Arachnids_enemy"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.Arachnid_enemy-constants")))
    end
    if (mods["ArmouredBiters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.ArmouredBiters-constants")))
    end
    if (mods["Cold_biters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.Cold_biters-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.planets.aquilo-settings-constants")))
    end
    if (mods["Electric_flying_enemies"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.Electric_flying_enemies-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.planets.fulgora-settings-constants")))
    end
    if (mods["Explosive_biters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.Explosive_biters-constants")))
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.planets.vulcanus-settings-constants")))
    end
    if (mods["old_biters_remastered"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.old_biters_remastered-constants")))
    end
    if (mods["Toxic_biters"]) then
        __Data_Utils.foreach(function(params)
            if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
        end, __Data_Utils.unpack(require("settings.runtime-global.compatibility.Toxic_biters-constants")))
    end
end

__Data_Utils.foreach(function(params)
    if (params and params.setting) then runtime_global_settings_constants.settings[params.setting] = params end
end, __Data_Utils.unpack(require("settings.runtime-global.global")))

return runtime_global_settings_constants