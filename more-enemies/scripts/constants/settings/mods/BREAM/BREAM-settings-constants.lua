-- If already defined, return
if _BREAM_settings_constants and _BREAM_settings_constants.more_enemies then
  return _BREAM_settings_constants
end

local BREAM_Constants = require("libs.constants.mods.BREAM-constants")
local Constants = require("libs.constants.constants")

BREAM_settings_constants = {}

BREAM_settings_constants.settings = {}

BREAM_settings_constants.settings.BREAM_DIFFICULTY = {
  type = "string-setting",
  name = "more-enemies-BREAM-difficulty",
  setting_type = "startup",
  order = "aac",
  default_value = "Vanilla",
  allowed_values = Constants.difficulty.difficulties_array
}

BREAM_settings_constants.settings.BREAM_DO_CLONE = {
  type = "bool-setting",
  name = "more-enemies-BREAM-do-clone",
  setting_type = "runtime-global",
  order = "eeb",
  default_value = BREAM_Constants.do_clone,
}

BREAM_settings_constants.settings.BREAM_USE_EVOLUTION_FACTOR = {
  type = "bool-setting",
  name = "more-enemies-BREAM-use-evolution-factor",
  setting_type = "runtime-global",
  order = "eec",
  default_value = true,
}

BREAM_settings_constants.settings.BREAM_CLONE_UNITS = {
  type = "double-setting",
  name = "more-enemies-BREAM-clone-units",
  setting_type = "runtime-global",
  order = "eed",
  default_value = 1,
  maximum_value = 11, -- This one goes up to eleven
  minimum_value = 0,
}


BREAM_settings_constants.more_enemies = true

local _BREAM_settings_constants = BREAM_settings_constants

return BREAM_settings_constants