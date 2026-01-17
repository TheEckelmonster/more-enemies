-- If already defined, return
if _explosive_biter_settings_constants and _explosive_biter_settings_constants.more_enemies then
    return _explosive_biter_settings_constants
end

local Explosive_Biters_Constants = require("libs.constants.mods.explosive-biters-constants")

local explosive_biter_settings_constants = {}

explosive_biter_settings_constants.settings = {}

-- { Biters } --
explosive_biter_settings_constants.settings.EXPLOSIVE_BITER_MAX_COUNT_OF_OWNED_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-explosive-biter-max-count-of-owned-units-biter",
    setting_type = "startup",
    order = "bca",
    default_value = Explosive_Biters_Constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_UNITS,
    minimum_value = 0,
}

explosive_biter_settings_constants.settings.EXPLOSIVE_BITER_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
    type = "int-setting",
    name = "more-enemies-spawner-explosive-biter-max-count-of-owned-defensive-units-biter",
    setting_type = "startup",
    order = "bcb",
    default_value = Explosive_Biters_Constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS,
    minimum_value = 0,
}

explosive_biter_settings_constants.settings.EXPLOSIVE_BITER_MAX_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-explosive-biter-max-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "bcc",
    default_value = Explosive_Biters_Constants.nauvis.biter_explosive.MAX_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}
explosive_biter_settings_constants.settings.EXPLOSIVE_BITER_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
    type = "int-setting",
    name = "more-enemies-spawner-explosive-biter-max-defensive-friends-around-to-spawn-biter",
    setting_type = "startup",
    order = "bcd",
    default_value = Explosive_Biters_Constants.nauvis.biter_explosive.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN,
    minimum_value = 0,
}

explosive_biter_settings_constants.settings.EXPLOSIVE_BITER_MAX_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-explosive-biter-max-spawning-cooldown-biter",
    setting_type = "startup",
    order = "bce",
    default_value = Explosive_Biters_Constants.nauvis.biter_explosive.MAX_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

explosive_biter_settings_constants.settings.EXPLOSIVE_BITER_MIN_SPAWNING_COOLDOWN = {
    type = "int-setting",
    name = "more-enemies-explosive-biter-min-spawning-cooldown-biter",
    setting_type = "startup",
    order = "bcf",
    default_value = Explosive_Biters_Constants.nauvis.biter_explosive.MIN_SPAWNING_COOLDOWN,
    minimum_value = 0,
}

explosive_biter_settings_constants.more_enemies = true

local _explosive_biter_settings_constants = explosive_biter_settings_constants

return explosive_biter_settings_constants