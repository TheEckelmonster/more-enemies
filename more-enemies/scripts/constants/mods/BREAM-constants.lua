-- If already defined, return
if _BREAM_constants and _BREAM_constants.more_enemies then
  return _BREAM_constants
end

local BREAM_constants = {}

BREAM_constants.name = "BREAM"
BREAM_constants.do_clone = false

BREAM_constants.more_enemies = true

local _BREAM_constants = BREAM_constants

return BREAM_constants