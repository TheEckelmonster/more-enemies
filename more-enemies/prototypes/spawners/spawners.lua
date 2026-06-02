local unit_spawner = "unit-spawner"

local type = type
local TABLE = "table"
if (type(data) ~= TABLE or  type(data.raw) ~= TABLE or type(data.raw[unit_spawner]) ~= TABLE) then return end

local data = data
local mods = mods

local spawner_settings_constants = {}

do
    local difficulty = require("settings.startup.planets.nauvis-settings-constants")
    local spawners_names = { "biter-spawner", "spitter-spawner", }
    local settings = require("settings.startup.biters-constants")
    for i, _ in ipairs(spawners_names) do
        spawner_settings_constants[#spawner_settings_constants+1] = {
            unit_settings = settings,
            difficulty_settings = difficulty,
            spawner_name = spawners_names[i],
        }
    end
end

if (mods) then
    if (mods["space-age"]) then
        local difficulty = require("settings.startup.planets.gleba-settings-constants")
        local spawners_names = { "gleba-spawner", "gleba-spawner-small", }
        local settings = require("settings.startup.compatibility.pentapods-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["Arachnids_enemy"]) then
        local difficulty = require("settings.startup.planets.nauvis-settings-constants")
        local spawners_names = { "arachnid-spawner-unitspawner", }
        local settings = require("settings.startup.compatibility.ArmouredBiters-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["ArmouredBiters"]) then
        local difficulty = require("settings.startup.planets.nauvis-settings-constants")
        local spawners_names = { "armoured-biter-spawner", }
        local settings = require("settings.startup.compatibility.ArmouredBiters-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["Cold_biters"]) then
        local difficulty = require("settings.startup.planets.aquilo-settings-constants")
        local spawners_names = { "cb-cold-spawner", }
        local settings = require("settings.startup.compatibility.Cold_biters-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["Electric_flying_enemies"]) then
        local difficulty = require("settings.startup.planets.fulgora-settings-constants")
        local spawners_names = { "flying-electric-unit-spawner", "walker-electric-unit-spawner", }
        local settings = require("settings.startup.compatibility.Electric_flying_enemies-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["Explosive_biters"]) then
        local difficulty = require("settings.startup.planets.vulcanus-settings-constants")
        local spawners_names = { "explosive-biter-spawner", }
        local settings = require("settings.startup.compatibility.Explosive_biters-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["old_biters_remastered"]) then
        local difficulty = require("settings.startup.planets.nauvis-settings-constants")
        local spawners_names = { "old-biter-spawner", "old-spitter-spawner", }
        local settings = require("settings.startup.compatibility.old_biters_remastered-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
    if (mods["Toxic_biters"]) then
        local difficulty = require("settings.startup.planets.nauvis-settings-constants")
        local spawners_names = { "toxic-biter-spawner", "tb_infected_ship", "tb_infected_ship_boss", "tb_infected_radar", }
        local settings = require("settings.startup.compatibility.Toxic_biters-constants")
        for i, _ in ipairs(spawners_names) do
            spawner_settings_constants[#spawner_settings_constants+1] = {
                unit_settings = settings,
                difficulty_settings = difficulty,
                spawner_name = spawners_names[i],
            }
        end
    end
end

---

local next = next
local pairs = pairs
local Data_Utils = require("__TheEckelmonster-core-library__.libs.utils.data-utils")
local Constants = require("scripts.constants.constants")
local Startup_Settings_Constants = require("settings.startup.startup-settings-constants")

---

local function perform(action, base, modifier)
    base = base or 1
    modifier = modifier or 1

    if (action == "multiply") then
        base = base * modifier + 1
    elseif (action == "divide") then
        base = base / modifier
    end

    return base
end

local actions = {
    ["multiply"] = function (base, modifier) return perform("multiply", base, modifier) end,
    ["divide"] = function (base, modifier) return perform("divide", base, modifier) end,
}

---

local VANILLA = "VANILLA"
local difficulty_map = {
    ["Easy"] = "EASY",
    ["Vanilla"] = "VANILLA",
    ["Vanilla+"] = "VANILLA_PLUS",
    ["Hard"] = "HARD",
    ["Insanity"] = "INSANITY",
}

---

local function process_unit_spawner(params)
    params = params or {}
    if (not next(params)) then return end

    local settings = {}
    local settings_dictionary = {}

    local difficulty = Data_Utils.get_startup_setting({ setting = (params.difficulty_settings and params.difficulty_settings[1] or {}).name, })
    local selected_difficulty = Constants.difficulty[type(difficulty) == "string" and difficulty_map[difficulty] or VANILLA]

    for _, setting in ipairs(params.unit_settings) do
        settings_dictionary[setting.setting] = setting
        settings[setting.setting] = Data_Utils.get_startup_setting({ setting = setting.name, })
    end

    local difficulty_val = selected_difficulty.value
    local spawner_prototype = data.raw[unit_spawner][params.spawner_name]
    if (type(spawner_prototype) ~= TABLE) then return end

    for _, setting in pairs(settings_dictionary) do
        if (setting.setting_name and setting.action) then
            spawner_prototype[setting.setting_name] = spawner_prototype[setting.setting_name] or setting.default_value

            if (setting.setting_name:find("spawning_cooldown")) then
                if (setting.setting_name:find("min")) then
                    spawner_prototype.spawning_cooldown[1] = actions[setting.action] and actions[setting.action](settings[setting.setting], difficulty_val) or spawner_prototype.spawning_cooldown[1]
                elseif (setting.setting_name:find("max")) then
                    spawner_prototype.spawning_cooldown[2] = actions[setting.action] and actions[setting.action](settings[setting.setting], difficulty_val) or spawner_prototype.spawning_cooldown[2]
                end
            else
                if (settings[setting.setting_name] ~= setting.default_value or difficulty ~= VANILLA) then
                    spawner_prototype[setting.setting_name] = actions[setting.action] and actions[setting.action](settings[setting.setting], difficulty_val) or spawner_prototype[setting.setting_name]
                end
            end
        end
    end

    data:extend({ spawner_prototype, })
end

local spawners = data.raw["unit-spawner"] or {}

local spawner_names = {}
for _, params in ipairs(spawner_settings_constants) do
    if (type(params.spawner_name) == "string") then
        spawner_names[params.spawner_name] = 1
    end
end

local fallback_difficulty = require("settings.startup.planets.fallback-settings-constants")
local fallback_settings = require("settings.startup.compatibility.fallback-constants")

local fallbacks = {}
for _, spawner in pairs(spawners) do
    if (not spawner_names[spawner.name]) then
        spawner_settings_constants[#spawner_settings_constants+1] = {
            unit_settings = fallback_settings,
            difficulty_settings = fallback_difficulty,
            spawner_name = spawner.name,
        }
    end
end
spawner_settings_constants[#spawner_settings_constants+1] = fallbacks

for _, params in ipairs(spawner_settings_constants or {}) do
    process_unit_spawner({
        spawner_name = params.spawner_name,
        difficulty_settings = params.difficulty_settings,
        unit_settings = params.unit_settings,
    })
end