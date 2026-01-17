-- If already defined, return
if _proto_settings_constants and _proto_settings_constants.more_enemies then
    return _proto_settings_constants
end

local Proto_Biters_Constants = require("libs.constants.mods.proto-biters-constants")

local proto_settings_constants = {}

proto_settings_constants.settings = {}

-- { Biters } --
proto_settings_constants.settings.OLD_BITER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-count-of-owned-units-old-biter",
    setting_type = "startup",
    order = "bda",
    default_value = Proto_Biters_Constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_UNITS,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_BITER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-count-of-owned-defensive-units-old-biter",
    setting_type = "startup",
    order = "bdb",
    default_value = Proto_Biters_Constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_BITER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-friends-around-to-spawn-old-biter",
    setting_type = "startup",
    order = "bdc",
    default_value = Proto_Biters_Constants.nauvis.biter_old.MAX_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}
proto_settings_constants.settings.OLD_BITER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-defensive-friends-around-to-spawn-old-biter",
    setting_type = "startup",
    order = "bdd",
    default_value = Proto_Biters_Constants.nauvis.biter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_BITER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-max-spawning-cooldown-old-biter",
    setting_type = "startup",
    order = "bde",
    default_value = Proto_Biters_Constants.nauvis.biter_old.MAX_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_BITER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-min-spawning-cooldown-old-biter",
    setting_type = "startup",
    order = "bdf",
    default_value = Proto_Biters_Constants.nauvis.biter_old.MIN_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

-- { Spitters } --
proto_settings_constants.settings.OLD_SPITTER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-count-of-owned-units-old-spitter",
    setting_type = "startup",
    order = "bea",
    default_value = Proto_Biters_Constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_UNITS,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_SPITTER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-count-of-owned-defensive-units-old-spitter",
    setting_type = "startup",
    order = "beb",
    default_value = Proto_Biters_Constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_SPITTER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-friends-around-to-spawn-old-spitter",
    setting_type = "startup",
    order = "bec",
    default_value = Proto_Biters_Constants.nauvis.spitter_old.MAX_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_SPITTER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-nauvis-max-defensive-friends-around-to-spawn-old-spitter",
    setting_type = "startup",
    order = "bed",
    default_value = Proto_Biters_Constants.nauvis.spitter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}

proto_settings_constants.settings.OLD_SPITTER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-max-spawning-cooldown-old-spitter",
    setting_type = "startup",
    order = "bee",
    default_value = Proto_Biters_Constants.nauvis.spitter_old.MAX_SPAWNING_COOLDOWN,
    minimum_value = 1,
}

proto_settings_constants.settings.OLD_SPITTER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-min-spawning-cooldown-old-spitter",
    setting_type = "startup",
    order = "bef",
    default_value = Proto_Biters_Constants.nauvis.spitter_old.MIN_SPAWNING_COOLDOWN,
    minimum_value = 1,
}

proto_settings_constants.more_enemies = true

local _proto_settings_constants = proto_settings_constants

return proto_settings_constants