local prefix = "more-enemies-"

local settings  = {}

settings[#settings+1] = {
    setting = "MAX_UNIT_GROUP_SIZE_RUNTIME",
    type = "int-setting",
    name = prefix .. "max-unit-group-size-runtime",
    setting_type = "runtime-global",
    order = "e[clone]-c[unspecified]-g[unit-group-szie]",
    default_value = 200,
    maximum_value = 1111,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "CLONES_PER_TICK",
    type = "int-setting",
    name = prefix .. "clones-per-tick",
    setting_type = "runtime-global",
    order = "e[clone]-c[unspecified]-g[clones-per-tick]",
    default_value = 25,
    maximum_value = 111,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_MODDED_CLONES",
    type = "int-setting",
    name = prefix .. "maximum-number-of-modded-clones",
    setting_type = "runtime-global",
    order = "e[clone]-c[unspecified]-c[maximum-clones-unit]",
    default_value = 500,
    maximum_value = 111111,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_ATTACK_GROUP_DELAY",
    type = "int-setting",
    name = prefix .. "maximum-attack-group-delay",
    setting_type = "runtime-global",
    order = "e[clone]-c[unspecified]-g[attack-group]-e[delay-max]",
    default_value = 1800,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MINIMUM_ATTACK_GROUP_DELAY",
    type = "int-setting",
    name = prefix .. "minimum-attack-group-delay",
    setting_type = "runtime-global",
    order = "e[clone]-c[unspecified]-g[attack-group]-e[delay-min]",
    default_value = 900,
    minimum_value = 0,
}

return settings