local storage

local BREAM_Settings_Constants = require("libs.constants.settings.mods.BREAM.BREAM-settings-constants")
local Difficulty_Utils = require("scripts.utils.difficulty-utils")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")
local Initialization = require("scripts.initialization")
local Log = require("libs.log.log")
local More_Enemies_Repository = require("scripts.repositories.more-enemies-repository")
local Settings_Service = require("scripts.service.settings-service")
local Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")

local settings_utils = {}

function settings_utils.is_vanilla(surface_name)
    local return_val = true

    -- local more_enemies_data = More_Enemies_Repository.get_more_enemies_data()
    storage.more_enemies = storage.more_enemies or More_Enemies_Repository.get_more_enemies_data()
    local more_enemies_data = storage.more_enemies

    -- if (not more_enemies_data.valid) then more_enemies_data = Initialization.reinit() end
    if (not more_enemies_data.difficulties) then Difficulty_Utils.get_difficulty(surface_name, true) end

    if (
            not more_enemies_data
        or not more_enemies_data.difficulties
        or not more_enemies_data.difficulties[surface_name]
        or not more_enemies_data.difficulties[surface_name].difficulty
        or not more_enemies_data.difficulties[surface_name].difficulty.selected_difficulty
        or more_enemies_data.difficulties[surface_name].difficulty.selected_difficulty.string_val ~= Vanilla_Difficulty_Data.string_val
    ) then
        return_val = false
    end

    if (return_val and Settings_Service.get_clone_unit_setting(surface_name) ~= 1) then return_val = false end
    if (return_val and Settings_Service.get_clone_unit_group_setting(surface_name) ~= 1) then return_val = false end
    if (return_val and Settings_Service.get_maximum_group_size() ~= Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value) then return_val = false end

    -- Mod added
    if (return_val and script and script.active_mods and (script.active_mods["BREAM"])) then
        if (return_val and Settings_Service.get_BREAM_difficulty() ~= Vanilla_Difficulty_Data.string_val) then return_val = false end
        if (return_val and Settings_Service.get_BREAM_clone_units() ~= BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS.default_value) then return_val = false end
    end

    -- Log.debug(return_val)
    return return_val
end

function settings_utils.get_attack_group_blacklist_names()
    Log.debug("settings_utils.get_attack_group_blacklist_names")

    local return_val = {}

    local raw_setting_string = Settings_Service.get_attack_group_blacklist_names()

    if (mods and mods["more-enemies"]) then
        log(raw_setting_string)
    end

    local setting_string_stripped = raw_setting_string:gsub(" ", "")

    local i = setting_string_stripped:find(",", 1, true)
    local j = 1

    while i ~= nil do
        local name = setting_string_stripped:sub(j, i - 1)
        if (type(name) == "string" and #name > 0) then
            table.insert(return_val, name)
        end
        j = i + 1
        i = setting_string_stripped:find(",", i + 1, true)
    end

    local name = setting_string_stripped:sub(j)
    if (type(name) == "string" and #name > 0) then
        table.insert(return_val, name)
    end

    return return_val
end

function settings_utils.init(__storage)
    storage = __storage
end

return settings_utils