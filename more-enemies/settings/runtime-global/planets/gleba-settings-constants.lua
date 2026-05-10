local prefix = "more-enemies-"

local settings = {}

settings = {}

-- { Cloning } --
settings[#settings+1] = {
    setting = "CLONE_GLEBA_UNITS",
    type = "double-setting",
    name = prefix .. "clone-gleba-units",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-c[clone-units]",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "CLONE_GLEBA_UNIT_GROUPS",
    type = "double-setting",
    name = prefix .. "clone-gleba-unit-groups",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-c[clone-unit-groups]",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_SPAWNED_CLONES_GLEBA",
    type = "int-setting",
    name = prefix .. "maximum-number-of-spawned-clones-gleba",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-c[maximum-clones-unit]",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_GLEBA",
    type = "int-setting",
    name = prefix .. "maximum-number-of-unit-group-clones-gleba",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-c[maximum-clones-unit-groups]",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

-- { Difficulty } --
settings[#settings+1] = {
    setting = "GLEBA_DO_EVOLUTION_FACTOR",
    type = "bool-setting",
    name = prefix .. "gleba-do-evolution-factor",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-e[evolution]",
    default_value = true,
}

settings[#settings+1] = {
    setting = "GLEBA_DO_ATTACK_GROUP",
    type = "bool-setting",
    name = prefix .. "gleba-do-attack-group",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-g[attack-group]",
    default_value = true,
}

settings[#settings+1] = {
    setting = "GLEBA_ATTACK_GROUP_PEACE_TIME",
    type = "double-setting",
    name = prefix .. "gleba-attack-group-peace-time",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-g[attack-group]-c[peace-time]",
    default_value = 45,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "GLEBA_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER",
    type = "double-setting",
    name = prefix .. "gleba-spawn-attack-group-probability-modifier",
    setting_type = "runtime-global",
    order = "c[clone]-c[gleba]-g[attack-group]-e[peace-time]",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1111,
}

return settings