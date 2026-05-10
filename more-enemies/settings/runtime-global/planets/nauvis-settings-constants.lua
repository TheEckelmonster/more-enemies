local prefix = "more-enemies-"

local settings = {}

settings = {}

-- { Cloning } --
settings[#settings+1] = {
    setting = "CLONE_NAUVIS_UNITS",
    type = "double-setting",
    name = prefix .. "clone-nauvis-units",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-c[clone-units]",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "CLONE_NAUVIS_UNIT_GROUPS",
    type = "double-setting",
    name = prefix .. "clone-nauvis-unit-groups",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-c[clone-unit-groups]",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS",
    type = "int-setting",
    name = prefix .. "maximum-number-of-spawned-clones-nauvis",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-c[maximum-clones-unit]",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS",
    type = "int-setting",
    name = prefix .. "maximum-number-of-unit-group-clones-nauvis",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-c[maximum-clones-unit-groups]",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

-- { Difficulty } --
settings[#settings+1] = {
    setting = "NAUVIS_DO_EVOLUTION_FACTOR",
    type = "bool-setting",
    name = prefix .. "nauvis-do-evolution-factor",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-e[evolution]",
    default_value = true,
}

settings[#settings+1] = {
    setting = "NAUVIS_DO_ATTACK_GROUP",
    type = "bool-setting",
    name = prefix .. "nauvis-do-attack-group",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-g[attack-group]",
    default_value = true,
}

settings[#settings+1] = {
    setting = "NAUVIS_ATTACK_GROUP_PEACE_TIME",
    type = "double-setting",
    name = prefix .. "nauvis-attack-group-peace-time",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-g[attack-group]-c[peace-time]",
    default_value = 45,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "NAUVIS_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER",
    type = "double-setting",
    name = prefix .. "nauvis-spawn-attack-group-probability-modifier",
    setting_type = "runtime-global",
    order = "c[clone]-c[nauvis]-g[attack-group]-e[peace-time]",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1111,
}

return settings