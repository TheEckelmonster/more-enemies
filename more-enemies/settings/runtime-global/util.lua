local type = type

local Constants = require("scripts.constants.constants")

local util = {}

local prefix = Constants.mod_name .. "-"

function util.make_settings(params)
    params = params or {}
    if (type(params.settings) ~= "table" or type(params.id) ~= "string") then return end

    prefix = params.prefix or prefix
    local settings, id, name = params.settings, params.id, params.name or ""
    local planet = params.planet or id or ""

    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAXIMUM_NUMBER_OF_SPAWNED_CLONES",
        type = "int-setting",
        name = prefix .. id ..  "-maximum-number-of-spawned-clones",
        planet = planet,
        id = id,
        unit_name = name,
        setting_type = "runtime-global",
        order = "c[" .. planet .. "]-c[" .. name .. "]-g[maximum-number-of-spawned-clones]",
        default_value = 150,
        maximum_value = 111111,
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES",
        type = "int-setting",
        name = prefix .. id ..  "-maximum-number-of-unit-group-clones",
        planet = planet,
        id = id,
        unit_name = name,
        setting_type = "runtime-global",
        order = "c[" .. planet .. "]-c[" .. name .. "]-i[maximum-number-of-unit-group-clones]",
        default_value = 150,
        maximum_value = 111111,
        minimum_value = 0,
    }

    return settings
end

function util.make_planet_settings(params)
    params = params or {}
    if (type(params.settings) ~= "table" or type(params.id) ~= "string") then return end

    prefix = params.prefix or prefix
    local settings, id, name = params.settings, params.id, params.name or ""
    local planet = params.planet or id or ""

    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_CLONE_UNITS",
        type = "double-setting",
        name = prefix .. id ..  "-clone-units",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-g-c[clone-units]",
        default_value = 1,
        maximum_value = 11,
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_CLONE_UNIT_GROUPS",
        type = "double-setting",
        name = prefix .. id ..  "-clone-unit-groups",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-g-e[clone-groups]",
        default_value = 1,
        maximum_value = 11,
        minimum_value = 0,
    }

    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_DO_EVOLUTION_FACTOR",
        type = "bool-setting",
        name = prefix .. id .. "-do-evolution-factor",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-k[do-evolution-factor]",
        default_value = true,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_DO_ATTACK_GROUP",
        type = "bool-setting",
        name = prefix .. id .. "-do-attack-group",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-m[do-attack-group]",
        default_value = true,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_ATTACK_GROUP_PEACE_TIME",
        type = "double-setting",
        name = prefix .. id .. "-attack-group-peace-time",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-o[attack-group-peace-time]",
        default_value = 45,
        minimum_value = 0,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER",
        type = "double-setting",
        name = prefix .. id .. "-spawn-attack-group-probability-modifier",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-q[spawn-attack-group-probability-modifier]",
        default_value = 1,
        minimum_value = 0,
        maximum_value = 1111,
    }
    settings[#settings+1] = {
        setting = id:gsub("%-", "_"):upper() .. "_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER",
        type = "bool-setting",
        name = prefix .. id .. "-attack-group-require-nearby-spawner",
        planet = planet,
        id = id,
        setting_type = "runtime-global",
        order = "c[" .. id .. "]-s[attack-group-require-nearby-spawner]",
        default_value = true,
        hidden  = true
    }

    return settings
end

return util