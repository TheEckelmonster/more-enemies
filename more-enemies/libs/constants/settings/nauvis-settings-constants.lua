-- If already defined, return
if _nauvis_settings_constants and _nauvis_settings_constants.more_enemies then
    return _nauvis_settings_constants
end

local Constants = require("libs.constants.constants")

local prefix = "more-enemies-"

local nauvis_settings_constants = {}

nauvis_settings_constants.settings = {}

-- { Cloning } --
nauvis_settings_constants.settings.CLONE_NAUVIS_UNITS = {
    type = "double-setting",
    name = prefix .. "clone-nauvis-units",
    setting_type = "runtime-global",
    order = "daa",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

nauvis_settings_constants.settings.CLONE_NAUVIS_UNIT_GROUPS = {
    type = "double-setting",
    name = prefix .. "clone-nauvis-groups",
    setting_type = "runtime-global",
    order = "dab",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

nauvis_settings_constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-spawned-clones-nauvis",
    setting_type = "runtime-global",
    order = "dyd",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

nauvis_settings_constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-unit-group-clones-nauvis",
    setting_type = "runtime-global",
    order = "dye",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

-- { Difficulty } --
nauvis_settings_constants.settings.NAUVIS_DIFFICULTY = {
    type = "string-setting",
    name = prefix .. "nauvis-difficulty",
    setting_type = "startup",
    order = "aaa",
    default_value = "Vanilla",
    allowed_values = Constants.difficulty.difficulties_array
}

nauvis_settings_constants.settings.NAUVIS_DO_EVOLUTION_FACTOR = {
    type = "bool-setting",
    name = prefix .. "nauvis-do-evolution-factor",
    setting_type = "runtime-global",
    order = "caa",
    default_value = true,
}

nauvis_settings_constants.settings.NAUVIS_DO_ATTACK_GROUP = {
    type = "bool-setting",
    name = prefix .. "nauvis-do-attack-group",
    setting_type = "runtime-global",
    order = "cab",
    default_value = true,
}

nauvis_settings_constants.settings.NAUVIS_ATTACK_GROUP_PEACE_TIME = {
    type = "double-setting",
    name = prefix .. "nauvis-attack-group-peace-time",
    setting_type = "runtime-global",
    order = "cad",
    default_value = 45,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER = {
    type = "double-setting",
    name = prefix .. "nauvis-spawn-attack-group-probability-modifier",
    setting_type = "runtime-global",
    order = "cae",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1111,
}

nauvis_settings_constants.settings.NAUVIS_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER = {
    type = "bool-setting",
    name = prefix .. "nauvis-attack-group-require-nearby-spawner",
    setting_type = "runtime-global",
    order = "cac",
    default_value = true,
}

-- { Biters } --
nauvis_settings_constants.settings.NAUVIS_BITER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-count-of-owned-units-biter",
    setting_type = "startup",
    order = "caa",
    default_value = 7,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_BITER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-count-of-owned-defensive-units-biter",
    setting_type = "startup",
    order = "cab",
    default_value = 7,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_BITER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "cac",
    default_value = 5,
    minimum_value = 0,
}
nauvis_settings_constants.settings.NAUVIS_BITER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-defensive-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "cad",
    default_value = 5,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_BITER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "max-spawning-cooldown-biter",
    setting_type = "startup",
    order = "cae",
    default_value = 360,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_BITER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "min-spawning-cooldown-biter",
    setting_type = "startup",
    order = "caf",
    default_value = 150,
    minimum_value = 0,
}

-- { Spitters } --
nauvis_settings_constants.settings.NAUVIS_SPITTER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-count-of-owned-units-spitter",
    setting_type = "startup",
    order = "cba",
    default_value = 7,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_SPITTER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-count-of-owned-defensive-units-spitter",
    setting_type = "startup",
    order = "cbb",
    default_value = 7,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_SPITTER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-friends-around-to-spawn-spitter",
    setting_type = "startup",
    order = "cbc",
    default_value = 5,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_SPITTER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-nauvis-max-defensive-friends-around-to-spawn-spitter",
    setting_type = "startup",
    order = "cbd",
    default_value = 5,
    minimum_value = 0,
}

nauvis_settings_constants.settings.NAUVIS_SPITTER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "max-spawning-cooldown-spitter",
    setting_type = "startup",
    order = "cbe",
    default_value = 360,
    minimum_value = 1,
}

nauvis_settings_constants.settings.NAUVIS_SPITTER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "min-spawning-cooldown-spitter",
    setting_type = "startup",
    order = "cbf",
    default_value = 150,
    minimum_value = 1,
}

nauvis_settings_constants.more_enemies = true

local _nauvis_settings_constants = nauvis_settings_constants

return nauvis_settings_constants