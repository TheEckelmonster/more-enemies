-- If already defined, return
if _armoured_biters_settings_constants and _armoured_biters_settings_constants.more_enemies then
  return _armoured_biters_settings_constants
end

local Armoured_Biters_Constants = require("libs.constants.mods.armoured-biters-constants")

local armoured_biters_settings_constants = {}

armoured_biters_settings_constants.settings = {}

-- { Armoured Biters } --
armoured_biters_settings_constants.settings.NAUVIS_BITER_ARMOURED_MAX_COUNT_OF_OWNED_UNITS = {
  type = "int-setting",
  name = "more-enemies-spawner-nauvis-max-count-of-owned-units-biter-armoured",
  setting_type = "startup",
  order = "baa",
  default_value = Armoured_Biters_Constants.nauvis.biter_armoured.MAX_COUNT_OF_OWNED_UNITS,
  minimum_value = 0,
}

armoured_biters_settings_constants.settings.NAUVIS_BITER_ARMOURED_MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = {
  type = "int-setting",
  name = "more-enemies-spawner-nauvis-max-count-of-owned-defensive-units-biter-armoured",
  setting_type = "startup",
  order = "bab",
  default_value = Armoured_Biters_Constants.nauvis.biter_armoured.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS,
  minimum_value = 0,
}

armoured_biters_settings_constants.settings.NAUVIS_BITER_ARMOURED_MAX_FRIENDS_AROUND_TO_SPAWN = {
  type = "int-setting",
  name = "more-enemies-spawner-nauvis-max-friends-around-to-spawn-biter-armoured",
  setting_type = "startup",
  order = "bac",
  default_value = Armoured_Biters_Constants.nauvis.biter_armoured.MAX_FRIENDS_AROUND_TO_SPAWN,
  minimum_value = 0,
}

armoured_biters_settings_constants.settings.NAUVIS_BITER_ARMOURED_MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = {
  type = "int-setting",
  name = "more-enemies-spawner-nauvis-max-defensive-friends-around-to-spawn-biter-armoured",
  setting_type = "startup",
  order = "bad",
  default_value = Armoured_Biters_Constants.nauvis.biter_armoured.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN,
  minimum_value = 0,
}

armoured_biters_settings_constants.settings.NAUVIS_ARMOURED_BITER_MAX_SPAWNING_COOLDOWN = {
  type = "int-setting",
  name = "more-enemies-max-spawning-cooldown-biter-armoured",
  setting_type = "startup",
  order = "bae",
  default_value = Armoured_Biters_Constants.nauvis.biter_armoured.MAX_SPAWNING_COOLDOWN,
  minimum_value = 0,
}

armoured_biters_settings_constants.settings.NAUVIS_ARMOURED_BITER_MIN_SPAWNING_COOLDOWN = {
  type = "int-setting",
  name = "more-enemies-min-spawning-cooldown-biter-armoured",
  setting_type = "startup",
  order = "baf",
  default_value = Armoured_Biters_Constants.nauvis.biter_armoured.MIN_SPAWNING_COOLDOWN,
  minimum_value = 0,
}

armoured_biters_settings_constants.more_enemies = true

local _armoured_biters_settings_constants = armoured_biters_settings_constants

return armoured_biters_settings_constants