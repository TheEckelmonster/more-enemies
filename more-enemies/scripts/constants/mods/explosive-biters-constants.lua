-- If already defined, return
if _explosive_biters_constants and _explosive_biters_constants.more_enemies then
  return _explosive_biters_constants
end

local explosive_biters_constants = {}

explosive_biters_constants.nauvis = {}
explosive_biters_constants.nauvis.biter_explosive = {}
explosive_biters_constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_UNITS = 10
explosive_biters_constants.nauvis.biter_explosive.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = 10
explosive_biters_constants.nauvis.biter_explosive.MAX_FRIENDS_AROUND_TO_SPAWN = 7
explosive_biters_constants.nauvis.biter_explosive.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = 7

explosive_biters_constants.nauvis.biter_explosive.MAX_SPAWNING_COOLDOWN = 360
explosive_biters_constants.nauvis.biter_explosive.MIN_SPAWNING_COOLDOWN = 150

explosive_biters_constants.nauvis.categories = {
    SMALL = { name = "small", value = 0.5 },
    MEDIUM = { name = "medium", value = 1 },
    BIG = { name = "big", value = 2 },
    BEHEMOTH = { name = "behemoth", value = 4 },
    LEVIATHAN = { name = "leviathan", value = 6 },
}

explosive_biters_constants.more_enemies = true

local _explosive_biters_constants = explosive_biters_constants

return explosive_biters_constants