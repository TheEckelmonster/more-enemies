-- If already defined, return
if _cold_biter_settings_constants and _cold_biter_settings_constants.more_enemies then
    return _cold_biter_settings_constants
end

local Cold_Biters_Constants = require("libs.constants.mods.cold-biters-constants")

local cold_biter_settings_constants = {}

cold_biter_settings_constants.settings = {}

-- { Biters } --
cold_biter_settings_constants.settings.COLD_BITER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-cold-biter-max-count-of-owned-units-biter",
    setting_type = "startup",
    order = "bba",
    default_value = Cold_Biters_Constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_UNITS,
    minimum_value = 0,
}

cold_biter_settings_constants.settings.COLD_BITER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-cold-biter-max-count-of-owned-defensive-units-biter",
    setting_type = "startup",
    order = "bbb",
    default_value = Cold_Biters_Constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS,
    minimum_value = 0,
}

cold_biter_settings_constants.settings.COLD_BITER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-cold-biter-max-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "bbc",
    default_value = Cold_Biters_Constants.nauvis.biter_cold.MAX_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}
cold_biter_settings_constants.settings.COLD_BITER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-cold-biter-max-defensive-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "bbd",
    default_value = Cold_Biters_Constants.nauvis.biter_cold.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}

cold_biter_settings_constants.settings.COLD_BITER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-cold-biter-max-spawning-cooldown-biter",
    setting_type = "startup",
    order = "bbe",
    default_value = Cold_Biters_Constants.nauvis.biter_cold.MAX_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

cold_biter_settings_constants.settings.COLD_BITER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-cold-biter-min-spawning-cooldown-biter",
    setting_type = "startup",
    order = "bbf",
    default_value = Cold_Biters_Constants.nauvis.biter_cold.MIN_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

cold_biter_settings_constants.more_enemies = true

local _cold_biter_settings_constants = cold_biter_settings_constants

return cold_biter_settings_constants