local storage

local script = script
local active_mods = script and script.active_mods

local Constants = Constants

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local BREAM_Settings_Constants = require("libs.constants.settings.mods.BREAM.BREAM-settings-constants")
local Global_Settings_Constants = require("libs.constants.settings.global-settings-constants")
local Settings_Service = require("scripts.service.settings-service")
local get_difficulty = Settings_Service.get_difficulty
local Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")

local settings_utils = {}

function settings_utils.is_vanilla(surface_name)
    local return_val = true

    storage.difficulties = storage.difficulties or {}
    storage.difficulties[surface_name] = storage.difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficulties[get_difficulty(surface_name)]])

    local selected_difficulty = storage.difficulties[surface_name]
    if (not selected_difficulty or selected_difficulty.string_val ~= Vanilla_Difficulty_Data.string_val) then return_val = false end

    if (return_val and Settings_Service.get_clone_unit_setting(surface_name) ~= 1) then return_val = false end
    if (return_val and Settings_Service.get_clone_unit_group_setting(surface_name) ~= 1) then return_val = false end
    if (return_val and Settings_Service.get_maximum_group_size() ~= Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value) then return_val = false end

    -- Mod added
    if (return_val and active_mods and active_mods["BREAM"]) then
        if (return_val and Settings_Service.get_BREAM_difficulty() ~= Vanilla_Difficulty_Data.string_val) then return_val = false end
        if (return_val and Settings_Service.get_BREAM_clone_units() ~= BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS.default_value) then return_val = false end
    end

    return return_val
end

function settings_utils.get_attack_group_blacklist_names()
    -- Log.debug("settings_utils.get_attack_group_blacklist_names")

    local return_val = {}

    local raw_setting_string = Settings_Service.get_attack_group_blacklist_names()

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