-- If already defined, return
if _global_settings_constants and _global_settings_constants.more_enemies then
    return _global_settings_constants
end

local prefix = "more-enemies-"

local global_settings_constants = {}

global_settings_constants.settings = {}

global_settings_constants.settings.MAX_UNIT_GROUP_SIZE_RUNTIME = {
    type = "int-setting",
    name = prefix .. "max-unit-group-size-runtime",
    setting_type = "runtime-global",
    order = "dcc",
    default_value = 200,
    maximum_value = 1111,
    minimum_value = 0,
}

global_settings_constants.settings.MAX_GATHERING_UNIT_GROUPS = {
    type = "int-setting",
    name = prefix .. "max-gathering-unit-groups",
    setting_type = "startup",
    order = "eda",
    default_value = 30,
    maximum_value = 1111,
    minimum_value = 0,
}

global_settings_constants.settings.MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST = {
    type = "int-setting",
    name = prefix .. "max-clients-to-accept-any-new-request",
    setting_type = "startup",
    order = "edb",
    default_value = 10,
    maximum_value = 1111,
    minimum_value = 0,
}

global_settings_constants.settings.MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST = {
    type = "int-setting",
    name = prefix .. "max-clients-to-accept-short-new-request",
    setting_type = "startup",
    order = "edb",
    default_value = 100,
    maximum_value = 1111,
    minimum_value = 0,
}

global_settings_constants.settings.DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST = {
    type = "int-setting",
    name = prefix .. "direct-distance-to-consider-short-request",
    setting_type = "startup",
    order = "edc",
    default_value = 100,
    maximum_value = 1111,
    minimum_value = 0,
}

global_settings_constants.settings.SHORT_REQUEST_MAX_STEPS = {
    type = "int-setting",
    name = prefix .. "short-request-max-steps",
    setting_type = "startup",
    order = "edd",
    default_value = 1000,
    maximum_value = 11111,
    minimum_value = 0,
}

global_settings_constants.settings.NTH_TICK = {}
global_settings_constants.settings.NTH_TICK.name = prefix .. "nth-tick"
global_settings_constants.settings.NTH_TICK.value = 5
global_settings_constants.settings.NTH_TICK.setting = {
    type = "int-setting",
    name = prefix .. "nth-tick",
    setting_type = "runtime-global",
    order = "edd",
    default_value = global_settings_constants.settings.NTH_TICK.value,
    maximum_value = 111,
    minimum_value = 0,
}

global_settings_constants.settings.CLONES_PER_TICK = {
    type = "int-setting",
    name = prefix .. "clones-per-tick",
    setting_type = "runtime-global",
    order = "edd",
    default_value = 25,
    maximum_value = 111,
    minimum_value = 0,
}

global_settings_constants.settings.MAXIMUM_NUMBER_OF_CLONES = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-clones",
    setting_type = "runtime-global",
    order = "ddd",
    default_value = 1500,
    maximum_value = 111111,
    minimum_value = 0,
}

global_settings_constants.settings.MAXIMUM_NUMBER_OF_SPAWNED_CLONES = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-spawned-clones",
    setting_type = "runtime-global",
    order = "dde",
    default_value = 1000,
    maximum_value = 111111,
    minimum_value = 0,
}

global_settings_constants.settings.MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-unit-group-clones",
    setting_type = "runtime-global",
    order = "ddf",
    default_value = 1000,
    maximum_value = 111111,
    minimum_value = 0,
}

global_settings_constants.settings.MAXIMUM_NUMBER_OF_MODDED_CLONES = {
    type = "int-setting",
    name = prefix .. "maximum-number-of-modded-clones",
    setting_type = "runtime-global",
    order = "eea",
    default_value = 500,
    maximum_value = 111111,
    minimum_value = 0,
}

global_settings_constants.settings.MAXIMUM_ATTACK_GROUP_DELAY = {
    type = "int-setting",
    name = prefix .. "maximum-attack-group-delay",
    setting_type = "runtime-global",
    order = "efa",
    default_value = 1800,
    maximum_value = 2 ^ 42,
    minimum_value = 0,
}

global_settings_constants.settings.MINIMUM_ATTACK_GROUP_DELAY = {
    type = "int-setting",
    name = prefix .. "minimum-attack-group-delay",
    setting_type = "runtime-global",
    order = "efb",
    default_value = 900,
    maximum_value = 2 ^ 42,
    minimum_value = 0,
}

global_settings_constants.settings.ATTACK_GROUP_BLACKLIST_NAMES = {
    type = "string-setting",
    name = prefix .. "attack-group-blacklist-names",
    setting_type = "startup",
    order = "efd",
    default_value = "",
    allow_blank = true,
    auto_trim = true,
}

global_settings_constants.more_enemies = true

---@diagnostic disable-next-line: lowercase-global
_global_settings_constants = global_settings_constants

return global_settings_constants