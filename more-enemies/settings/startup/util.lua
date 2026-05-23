local type = type

local Constants = require("scripts.constants.constants")

local util = {}

local prefix = Constants.mod_name .. "-"

local planets = {
    ["fulgora"] = true,
    ["gleba"] = true,
}

function util.make_difficulty_settings(params)
    params = params or {}
    if (type(params.settings) ~= "table" or type(params.id) ~= "string") then return end

    prefix = params.prefix or prefix
    local settings, id = params.settings, params.id
    local planet = params.planet or id or ""

    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_DIFFICULTY",
        type = "string-setting",
        name = prefix .. planet .. "-difficulty",
        planet = planet,
        setting_type = "startup",
        order = "aab[" .. planet .. "]-c[difficulty]",
        default_value = "Vanilla",
        allowed_values = Constants.difficulty.difficulties_array
    }

    return settings
end
function util.make_planet_settings(params)
    params = params or {}
    if (type(params.settings) ~= "table" or type(params.id) ~= "string") then return end

    prefix = params.prefix or prefix
    local settings, id = params.settings, params.id
    local planet = params.planet or id or ""

    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAX_COUNT_OF_OWNED_UNITS",
        setting_name = "max_count_of_owned_units",
        type = "int-setting",
        name = prefix .. id .. "-max-count-of-owned-units",
        setting_type = "startup",
        order = "c[".. id .. "]-c[max-count-of-owned-units]",
        default_value = planets[planet] and 2 or 7,
        action = "multiply",
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS",
        setting_name = "max_count_of_owned_defensive_units",
        type = "int-setting",
        name = prefix .. id .. "-max-count-of-owned-defensive-units",
        setting_type = "startup",
        order = "c[".. id .. "]-e[max-count-of-owned-defensive-units]",
        default_value = planets[planet] and 1 or 7,
        action = "multiply",
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAX_FRIENDS_AROUND_TO_SPAWN",
        setting_name = "max_friends_around_to_spawn",
        type = "int-setting",
        name = prefix .. id .. "-max-friends-around-to-spawn",
        setting_type = "startup",
        order = "c[".. id .. "]-g[max-friends-around-to-spawn]",
        default_value = planets[planet] and 3 or 5,
        action = "multiply",
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN",
        setting_name = "max_defensive_friends_around_to_spawn",
        type = "int-setting",
        name = prefix .. id .. "-max-defensive-friends-around-to-spawn",
        setting_type = "startup",
        order = "c[".. id .. "]-i[max-defensive-friends-around-to-spawn]",
        default_value = planets[planet] and 2 or 5,
        action = "multiply",
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAX_SPAWNING_COOLDOWN",
        setting_name = "max_spawning_cooldown",
        type = "int-setting",
        name = prefix .. id .. "-max-spawning-cooldown",
        setting_type = "startup",
        order = "c[".. id .. "]-k[max-spawning-cooldown]",
        default_value = 360,
        action = "divide",
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MIN_SPAWNING_COOLDOWN",
        setting_name = "min_spawning_cooldown",
        type = "int-setting",
        name = prefix .. id .. "-min-spawning-cooldown",
        setting_type = "startup",
        order = "c[".. id .. "]-m[min-spawning-cooldown]",
        default_value = 150,
        action = "divide",
        minimum_value = 0,
    }

    return settings
end

return util