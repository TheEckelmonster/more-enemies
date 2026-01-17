-- If already defined, return
if _toxic_biter_settings_constants and _toxic_biter_settings_constants.more_enemies then
    return _toxic_biter_settings_constants
end

local Toxic_Biters_Constants = require("libs.constants.mods.toxic-biters-constants")

local toxic_biter_settings_constants = {}

toxic_biter_settings_constants.settings = {}

-- { Biters } --
toxic_biter_settings_constants.settings.TOXIC_BITER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-toxic-biter-max-count-of-owned-units-biter",
    setting_type = "startup",
    order = "bfa",
    default_value = Toxic_Biters_Constants.nauvis.biter_toxic.MAX_COUNT_OF_OWNED_UNITS,
    minimum_value = 0,
}

toxic_biter_settings_constants.settings.TOXIC_BITER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-toxic-biter-max-count-of-owned-defensive-units-biter",
    setting_type = "startup",
    order = "bfb",
    default_value = Toxic_Biters_Constants.nauvis.biter_toxic.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS,
    minimum_value = 0,
}

toxic_biter_settings_constants.settings.TOXIC_BITER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-toxic-biter-max-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "bfc",
    default_value = Toxic_Biters_Constants.nauvis.biter_toxic.MAX_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}
toxic_biter_settings_constants.settings.TOXIC_BITER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-toxic-biter-max-defensive-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "bfd",
    default_value = Toxic_Biters_Constants.nauvis.biter_toxic.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}

toxic_biter_settings_constants.settings.TOXIC_BITER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-toxic-biter-max-spawning-cooldown-biter",
    setting_type = "startup",
    order = "bfe",
    default_value = Toxic_Biters_Constants.nauvis.biter_toxic.MAX_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

toxic_biter_settings_constants.settings.TOXIC_BITER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-toxic-biter-min-spawning-cooldown-biter",
    setting_type = "startup",
    order = "bff",
    default_value = Toxic_Biters_Constants.nauvis.biter_toxic.MIN_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

toxic_biter_settings_constants.more_enemies = true

local _toxic_biter_settings_constants = toxic_biter_settings_constants

return toxic_biter_settings_constants