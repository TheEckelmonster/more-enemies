local prefix = "more-enemies-"

local settings = {}

settings[#settings+1] = {
    setting = "CUSTOM_DIFFICULTIES",
    type = "string-setting",
    name = prefix .. "custom-difficulties",
    setting_type = "startup",
    order = "abc[custom]-c[difficulty]",
    default_value = "",
    auto_trim = true,
    allow_blank = true,
}
settings[#settings+1] = {
    setting = "CONDUCTOR_STYLE",
    type = "string-setting",
    name = prefix .. "conductor-style",
    setting_type = "startup",
    order = "bbc[conductor]-c[difficulty]",
    default_value = "None",
    allowed_values = {
        "None",
        "Random",
        "Adaptive",
        "Omni-mind",
    },
}
settings[#settings+1] = {
    setting = "MAX_UNIT_GROUP_SIZE_STARTUP",
    type = "int-setting",
    name = prefix .. "max-unit-group-size-startup",
    setting_type = "startup",
    order = "xda[clone]-c[unspecified]-g[unit-group-szie]",
    default_value = 200,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "MAX_GATHERING_UNIT_GROUPS",
    type = "int-setting",
    name = prefix .. "max-gathering-unit-groups",
    setting_type = "startup",
    order = "xdb",
    default_value = 30,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "MAX_CLIENTS_TO_ACCEPT_ANY_NEW_REQUEST",
    type = "int-setting",
    name = prefix .. "max-clients-to-accept-any-new-request",
    setting_type = "startup",
    order = "xdc",
    default_value = 10,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "MAX_CLIENTS_TO_ACCEPT_SHORT_NEW_REQUEST",
    type = "int-setting",
    name = prefix .. "max-clients-to-accept-short-new-request",
    setting_type = "startup",
    order = "xdd",
    default_value = 100,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "DIRECT_DISTANCE_TO_CONSIDER_SHORT_REQUEST",
    type = "int-setting",
    name = prefix .. "direct-distance-to-consider-short-request",
    setting_type = "startup",
    order = "xde",
    default_value = 100,
    maximum_value = 1111,
    minimum_value = 0,
}
settings[#settings+1] = {
    setting = "SHORT_REQUEST_MAX_STEPS",
    type = "int-setting",
    name = prefix .. "short-request-max-steps",
    setting_type = "startup",
    order = "xdf",
    default_value = 1000,
    maximum_value = 11111,
    minimum_value = 0,
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