-- If already defined, return
if _gleba_settings_constants and _gleba_settings_constants.more_enemies then
    return _gleba_settings_constants
end

local Constants = require("libs.constants.constants")

local prefix = "more-enemies-"

local gleba_settings_constants = {}

gleba_settings_constants.settings = {}

-- { Cloning } --
gleba_settings_constants.settings.CLONE_GLEBA_UNITS = {
    type = "double-setting",
    name = prefix .. "clone-gleba-units",
    setting_type = "runtime-global",
    order = "dba",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

gleba_settings_constants.settings.CLONE_GLEBA_UNIT_GROUPS = {
    type = "double-setting",
    name = prefix .. "clone-gleba-unit-groups",
    setting_type = "runtime-global",
    order = "dbb",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

gleba_settings_constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-spawned-clones-gleba",
    setting_type = "runtime-global",
    order = "dzd",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

gleba_settings_constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-unit-group-clones-gleba",
    setting_type = "runtime-global",
    order = "dze",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

-- { Difficulty } --
gleba_settings_constants.settings.GLEBA_DIFFICULTY = {
    type = "string-setting",
    name = prefix .. "gleba-difficulty",
    setting_type = "startup",
    order = "aab",
    default_value = "Vanilla",
    allowed_values = Constants.difficulty.difficulties_array
}

gleba_settings_constants.settings.GLEBA_DO_EVOLUTION_FACTOR = {
    type = "bool-setting",
    name = prefix .. "gleba-do-evolution-factor",
    setting_type = "runtime-global",
    order = "cba",
    default_value = true,
}

gleba_settings_constants.settings.GLEBA_DO_ATTACK_GROUP = {
    type = "bool-setting",
    name = prefix .. "gleba-do-attack-group",
    setting_type = "runtime-global",
    order = "cbb",
    default_value = true,
}

gleba_settings_constants.settings.GLEBA_ATTACK_GROUP_PEACE_TIME = {
    type = "double-setting",
    name = prefix .. "gleba-attack-group-peace-time",
    setting_type = "runtime-global",
    order = "cbd",
    default_value = 45,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER = {
    type = "double-setting",
    name = prefix .. "gleba-spawn-attack-group-probability-modifier",
    setting_type = "runtime-global",
    order = "cbe",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1111,
}

gleba_settings_constants.settings.GLEBA_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER = {
    type = "bool-setting",
    name = prefix .. "gleba-attack-group-require-nearby-spawner",
    setting_type = "runtime-global",
    order = "cbc",
    default_value = true,
}

-- { Small } --
gleba_settings_constants.settings.GLEBA_SMALL_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-small-max-count-of-owned-units",
    setting_type = "startup",
    order = "daa",
    default_value = 1,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_SMALL_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-small-max-count-of-owned-defensive-units",
    setting_type = "startup",
    order = "dab",
    default_value = 1,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_SMALL_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-small-max-friends-around-to-spawn",
    setting_type = "startup",
    order = "dac",
    default_value = 2,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_SMALL_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-small-max-defensive-friends-around-to-spawn",
    setting_type = "startup",
    order = "dad",
    default_value = 2,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_SMALL_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "max-spawning-cooldown-gleba-small",
    setting_type = "startup",
    order = "dae",
    default_value = 360,
    minimum_value = 1,
}

gleba_settings_constants.settings.GLEBA_SMALL_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "min-spawning-cooldown-gleba-small",
    setting_type = "startup",
    order = "daf",
    default_value = 150,
    minimum_value = 1,
}

-- { Regular } --
gleba_settings_constants.settings.GLEBA_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-max-count-of-owned-units",
    setting_type = "startup",
    order = "dba",
    default_value = 2,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-max-count-of-owned-defensive-units",
    setting_type = "startup",
    order = "dbb",
    default_value = 1,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-max-friends-around-to-spawn",
    setting_type = "startup",
    order = "dbc",
    default_value = 3,
    minimum_value = 0,
}
gleba_settings_constants.settings.GLEBA_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = prefix .. "spawner-gleba-max-defensive-friends-around-to-spawn",
    setting_type = "startup",
    order = "dbd",
    default_value = 2,
    minimum_value = 0,
}

gleba_settings_constants.settings.GLEBA_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "max-spawning-cooldown-gleba",
    setting_type = "startup",
    order = "dbe",
    default_value = 360,
    minimum_value = 1,
}

gleba_settings_constants.settings.GLEBA_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = prefix .. "min-spawning-cooldown-gleba",
    setting_type = "startup",
    order = "dbf",
    default_value = 150,
    minimum_value = 1,
}

gleba_settings_constants.more_enemies = true

---@diagnostic disable-next-line: lowercase-global
_gleba_settings_constants = gleba_settings_constants

return gleba_settings_constants