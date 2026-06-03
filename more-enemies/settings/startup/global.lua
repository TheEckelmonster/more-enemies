local prefix = "more-enemies-"

local settings = {}

settings[#settings+1] = {
    setting = "MAX_GATHERING_UNIT_GROUPS",
    type = "int-setting",
    name = prefix .. "max-gathering-unit-groups",
    setting_type = "startup",
    order = "xda",
    default_value = 30,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST",
    type = "int-setting",
    name = prefix .. "max-clients-to-accept-any-new-request",
    setting_type = "startup",
    order = "xdb",
    default_value = 10,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST",
    type = "int-setting",
    name = prefix .. "max-clients-to-accept-short-new-request",
    setting_type = "startup",
    order = "xdb",
    default_value = 100,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST",
    type = "int-setting",
    name = prefix .. "direct-distance-to-consider-short-request",
    setting_type = "startup",
    order = "xdc",
    default_value = 100,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "SHORT_REQUEST_MAX_STEPS",
    type = "int-setting",
    name = prefix .. "short-request-max-steps",
    setting_type = "startup",
    order = "xdd",
    default_value = 1000,
    maximum_value = 11111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "CONDUCTOR_STYLE",
    type = "string-setting",
    name = prefix .. "conductor-style",
    setting_type = "startup",
    order = "xomni",
    default_value = "None",
    allowed_values = {
        "None",
        "Random",
        "Adaptive",
        "Omni-mind",
    },
}
settings[#settings+1] = {
    setting = "DIFFICULTY_FORMULA",
    type = "string-setting",
    name = prefix .. "difficulty-formula",
    setting_type = "startup",
    order = "xdy",
    default_value = "(difficulty^(evolution_factor/(difficulty^(evolution_factor/difficulty))))*evolution_factor",
    allow_blank = false,
    auto_trim = true,
}
settings[#settings+1] = {
    setting = "DIFFICULTY_FORMULA_VARIABLES",
    type = "string-setting",
    name = prefix .. "difficulty-formula-variables",
    setting_type = "startup",
    order = "xdz",
    default_value = "difficulty_value=surface,evolution_factor=surface",
    allow_blank = true,
    auto_trim = true,
}
settings[#settings+1] = {
    setting = "ATTACK_GROUP_BLACKLIST_NAMES",
    type = "string-setting",
    name = prefix .. "attack-group-blacklist-names",
    setting_type = "startup",
    order = "xyz",
    default_value = "",
    allow_blank = true,
    auto_trim = true,
}

return settings