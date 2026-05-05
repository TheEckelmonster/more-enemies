local prefix = "more-enemies-"

local settings = {}

-- { Cloning } --
settings[#settings+1] = {
    setting = "CLONE_NAUVIS_UNITS",
    type = "double-setting",
    name = prefix .. "clone-nauvis-units",
    setting_type = "runtime-global",
    order = "daa",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "CLONE_NAUVIS_UNIT_GROUPS",
    type = "double-setting",
    name = prefix .. "clone-nauvis-groups",
    setting_type = "runtime-global",
    order = "dab",
    default_value = 1,
    maximum_value = 11, -- This one goes up to eleven
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_SPAWNED_CLONES_NAUVIS",
    type = "int-setting",
    name = prefix .. "maximum-number-of-spawned-clones-nauvis",
    setting_type = "runtime-global",
    order = "dyd",
    default_value = 400,
    maximum_value = 111111,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "MAXIMUM_NUMBER_OF_UNIT_GROUP_CLONES_NAUVIS",
    type = "int-setting",
    name = prefix .. "maximum-number-of-unit-group-clones-nauvis",
    setting_type = "runtime-global",
    order = "dye",
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
    order = "caa",
    default_value = true,
}

settings[#settings+1] = {
    setting = "NAUVIS_DO_ATTACK_GROUP",
    type = "bool-setting",
    name = prefix .. "nauvis-do-attack-group",
    setting_type = "runtime-global",
    order = "cab",
    default_value = true,
}

settings[#settings+1] = {
    setting = "NAUVIS_ATTACK_GROUP_PEACE_TIME",
    type = "double-setting",
    name = prefix .. "nauvis-attack-group-peace-time",
    setting_type = "runtime-global",
    order = "cad",
    default_value = 45,
    minimum_value = 0,
}

settings[#settings+1] = {
    setting = "NAUVIS_SPAWN_ATTACK_GROUP_PROBABILITY_MODIFIER",
    type = "double-setting",
    name = prefix .. "nauvis-spawn-attack-group-probability-modifier",
    setting_type = "runtime-global",
    order = "cae",
    default_value = 1,
    minimum_value = 0,
    maximum_value = 1111,
}

settings[#settings+1] = {
    setting = "NAUVIS_ATTACK_GROUP_REQUIRE_NEARBY_SPAWNER",
    type = "bool-setting",
    name = prefix .. "nauvis-attack-group-require-nearby-spawner",
    setting_type = "runtime-global",
    order = "cac",
    default_value = true,
}

return settings