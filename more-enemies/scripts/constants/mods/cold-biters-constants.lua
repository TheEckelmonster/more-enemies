-- If already defined, return
if _cold_biters_constants and _cold_biters_constants.more_enemies then
  return _cold_biters_constants
end

local cold_biters_constants = {}

cold_biters_constants.nauvis = {}
cold_biters_constants.nauvis.biter_cold = {}
cold_biters_constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_UNITS = 10
cold_biters_constants.nauvis.biter_cold.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = 10
cold_biters_constants.nauvis.biter_cold.MAX_FRIENDS_AROUND_TO_SPAWN = 7
cold_biters_constants.nauvis.biter_cold.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = 7

cold_biters_constants.nauvis.biter_cold.MAX_SPAWNING_COOLDOWN = 360
cold_biters_constants.nauvis.biter_cold.MIN_SPAWNING_COOLDOWN = 150

cold_biters_constants.nauvis.categories = {
    SMALL = { name = "small", value = 0.5 },
    MEDIUM = { name = "medium", value = 1 },
    BIG = { name = "big", value = 2 },
    BEHEMOTH = { name = "behemoth", value = 4 },
    LEVIATHAN = { name = "leviathan", value = 6 },
}

cold_biters_constants.more_enemies = true

local _cold_biters_constants = cold_biters_constants

return cold_biters_constants