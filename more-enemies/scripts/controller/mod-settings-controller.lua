
local Attack_Group_Repository = require("scripts.repositories.attack-group-repository")
local Constants = require("libs.constants.constants")
local Difficulty_Utils = require("scripts.utils.difficulty-utils")
local Gleba_Constants = require("libs.constants.gleba-constants")
local Gleba_Settings_Constants = require("libs.constants.settings.gleba-settings-constants")
local Log = require("libs.log.log")
local Nauvis_Constants = require("libs.constants.nauvis-constants")
local Nauvis_Settings_Constants = require("libs.constants.settings.nauvis-settings-constants")
local Settings_Service = require("scripts.service.settings-service")

local locals = {}

local mod_settings_controller = {}
mod_settings_controller.name = "mod_settings_controller"

function mod_settings_controller.mod_setting_changed(event)
    Log.debug("mod_settings_controller.mod_setting_changed")
    Log.info(event)

    if (event and event.setting) then
        if ( event.setting == Gleba_Settings_Constants.settings.CLONE_GLEBA_UNITS.name
            or event.setting == Gleba_Settings_Constants.settings.CLONE_GLEBA_UNIT_GROUPS.name)
        then
            locals.invoke(event, Difficulty_Utils.get_difficulty, { planet = Gleba_Constants.gleba.string_val, reindex = true })
        end

        if ( event.setting == Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNITS.name
            or event.setting == Nauvis_Settings_Constants.settings.CLONE_NAUVIS_UNIT_GROUPS.name)
        then
            locals.invoke(event, Difficulty_Utils.get_difficulty, { planet = Nauvis_Constants.nauvis.string_val, reindex = true})
        end

        local attack_group_data = nil

        if ( event.setting == Gleba_Settings_Constants.settings.GLEBA_ATTACK_GROUP_PEACE_TIME.name) then
            if (game.surfaces[Constants.DEFAULTS.planets.gleba.string_val] and game.surfaces[Constants.DEFAULTS.planets.gleba.string_val].valid) then
                attack_group_data = Attack_Group_Repository.get_attack_group_data(Constants.DEFAULTS.planets.gleba.string_val)
            end
        elseif( event.setting == Nauvis_Settings_Constants.settings.NAUVIS_ATTACK_GROUP_PEACE_TIME.name) then
            if (game.surfaces[Constants.DEFAULTS.planets.nauvis.string_val] and game.surfaces[Constants.DEFAULTS.planets.nauvis.string_val].valid) then
                attack_group_data = Attack_Group_Repository.get_attack_group_data(Constants.DEFAULTS.planets.nauvis.string_val)
            end
        end

        if (type(attack_group_data) == "table" and attack_group_data.surface and attack_group_data.surface.valid) then
            local peace_time_tick = Settings_Service.get_attack_group_peace_time(attack_group_data.surface.name) * Constants.time.TICKS_PER_MINUTE
            if (type(attack_group_data.surface) == "table" and attack_group_data.surface.index == 1) then
                attack_group_data.peace_time_tick = peace_time_tick
                attack_group_data.tick = peace_time_tick
            else
                attack_group_data.peace_time_tick = peace_time_tick
                attack_group_data.tick = attack_group_data.created + peace_time_tick
            end
        end
    end
end
Event_Handler:register_event({
    event_name = "on_runtime_mod_setting_changed",
    source_name = "mod_settings_controller.on_runtime_mod_setting_changed",
    func_name = "mod_settings_controller.on_runtime_mod_setting_changed",
    func = mod_settings_controller.on_runtime_mod_setting_changed,
})

function locals.invoke(event, fun, params)
    Log.debug("Mod settings changed")
    Log.info(event)
    Log.info(params)

    if (type(fun) == "function") then
        if (fun == Difficulty_Utils.get_difficulty) then fun(params.planet, params.reindex) end
    end
end

return mod_settings_controller