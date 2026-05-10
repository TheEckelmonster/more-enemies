-- If already defined, return
if _behemoth_enemies_constants and _behemoth_enemies_constants.more_enemies then
  return _behemoth_enemies_constants
end

local behemoth_enemies_constants = {}

behemoth_enemies_constants.prefix = "behemoth"

behemoth_enemies_constants.more_enemies = true

local _behemoth_enemies_constants = behemoth_enemies_constants

return behemoth_enemies_constants