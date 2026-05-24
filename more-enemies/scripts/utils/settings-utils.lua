local storage
local difficulties
local settings_map

local game

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.difficulties = storage.difficulties or {}
    difficulties = storage.difficulties

    storage.settings_map = storage.settings_map or {}
    settings_map = storage.settings_map

    storage.settings_map.runtime_global = storage.settings_map.runtime_global or {}
    storage.settings_map.startup = storage.settings_map.startup or {}

    game = __game or _ENV.game

    return game
end

local script = script
local active_mods = script and script.active_mods

local Constants = Constants

local Startup_Settings_Constants = Startup_Settings_Constants or require("settings.startup.startup-settings-constants")
local Runtime_Global_Settings_Constants = Runtime_Global_Settings_Constants or require("settings.runtime-global.runtime-global-settings-constants")

local Utils = require("__core__.lualib.util")
local deepcopy = Utils.table.deepcopy

local Settings_Map = Settings_Map

local Settings_Service = require("scripts.service.settings-service")
local Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")

local settings_utils = {}
settings_utils.name = "settings_utils"
settings_utils.set_game = set_game

local VANILLA = Vanilla_Difficulty_Data.string_val

function settings_utils.is_vanilla(surface_name)
    local return_val = true

    difficulties = difficulties or set_game() and difficulties
    difficulties[surface_name] = difficulties[surface_name] or deepcopy(Constants.difficulty[Constants.difficulty.difficultiesget_startup_setting({ setting = (Startup_Settings_Constants.settings[surface_name:gsub("%-", "_"):upper() .. "_DIFFICULTY"] or {}).name, reindex = true, }) or "Vanilla"])

    local selected_difficulty = difficulties[surface_name]
    if (not selected_difficulty or selected_difficulty.string_val ~= VANILLA) then return_val = false end

    settings_map = settings_map or set_game() and settings_map
    settings_map.runtime_global = settings_map.runtime_global or {}
    if (return_val and (settings_map.runtime_global[ME_PREFIX .. surface_name:gsub("%-", "_"):upper() .. "_CLONE_UNITS"] or 1) ~= 1) then return_val = false end
    if (return_val and (settings_map.runtime_global[ME_PREFIX .. surface_name:gsub("%-", "_"):upper() .. "_CLONE_UNIT_GROUPS"] or 1) ~= 1) then return_val = false end
    if (return_val and (settings_map.runtime_global[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.name] or Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value) ~= Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME.default_value) then return_val = false end

    -- Mod added
    -- if (return_val and active_mods and active_mods["BREAM"]) then
    --     if (return_val and Settings_Service.get_BREAM_difficulty() ~= Vanilla_Difficulty_Data.string_val) then return_val = false end
    --     if (return_val and Settings_Service.get_BREAM_clone_units() ~= BREAM_Settings_Constants.settings.BREAM_CLONE_UNITS.default_value) then return_val = false end
    -- end

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

function settings_utils.init(__storage) storage = __storage or _ENV.storage end

return settings_utils