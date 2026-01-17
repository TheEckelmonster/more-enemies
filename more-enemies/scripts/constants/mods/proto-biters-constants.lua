-- If already defined, return
if _proto_biter_constants and _proto_biter_constants.more_enemies then
  return _proto_biter_constants
end

local proto_biter_constants = {}

--
-- Biter Spawner
proto_biter_constants.nauvis = {}
proto_biter_constants.nauvis.biter_old = {}
proto_biter_constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_UNITS = 7
proto_biter_constants.nauvis.biter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = 7
proto_biter_constants.nauvis.biter_old.MAX_FRIENDS_AROUND_TO_SPAWN = 5
proto_biter_constants.nauvis.biter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = 5

proto_biter_constants.nauvis.biter_old.MAX_SPAWNING_COOLDOWN = 360
proto_biter_constants.nauvis.biter_old.MIN_SPAWNING_COOLDOWN = 150

--
-- Spitter Spawner
proto_biter_constants.nauvis.spitter_old = {}
proto_biter_constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_UNITS = 7
proto_biter_constants.nauvis.spitter_old.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = 7
proto_biter_constants.nauvis.spitter_old.MAX_FRIENDS_AROUND_TO_SPAWN = 5
proto_biter_constants.nauvis.spitter_old.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = 5

proto_biter_constants.nauvis.spitter_old.MAX_SPAWNING_COOLDOWN = 360
proto_biter_constants.nauvis.spitter_old.MIN_SPAWNING_COOLDOWN = 150

proto_biter_constants.nauvis.categories = {
    SMALL = { name = "small", value = 0.5 },
    MEDIUM = { name = "medium", value = 1 },
    BIG = { name = "big", value = 2 },
    BEHEMOTH = { name = "behemoth", value = 4 },
}

proto_biter_constants.more_enemies = true

local _proto_biter_constants = proto_biter_constants

return proto_biter_constants