-- If already defined, return
if _gleba_constants and _gleba_constants.more_enemies then
  return _gleba_constants
end

local gleba_constants = {}

--
-- { Gleba } --

gleba_constants.gleba = {}

gleba_constants.gleba.string_val = "gleba"

gleba_constants.gleba.categories = {
    SMALL = { name = "small", value = 10 },
    MEDIUM = { name = "medium", value = 20 },
    BIG = { name = "big", value = 40 },
}

--
-- Small
gleba_constants.gleba.small = {}
gleba_constants.gleba.small.MAX_COUNT_OF_OWNED_UNITS = 1
gleba_constants.gleba.small.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = 1
gleba_constants.gleba.small.MAX_FRIENDS_AROUND_TO_SPAWN = 2
gleba_constants.gleba.small.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = 2

gleba_constants.gleba.small.MAX_SPAWNING_COOLDOWN = 360
gleba_constants.gleba.small.MIN_SPAWNING_COOLDOWN = 150

--
-- Regular
gleba_constants.gleba.regular = {}
gleba_constants.gleba.regular.MAX_COUNT_OF_OWNED_UNITS = 2
gleba_constants.gleba.regular.MAX_COUNT_OF_OWNED_DEFENSIVE_UNITS = 1
gleba_constants.gleba.regular.MAX_FRIENDS_AROUND_TO_SPAWN = 3
gleba_constants.gleba.regular.MAX_DEFENSIVE_FRIENDS_AROUND_TO_SPAWN = 2

gleba_constants.gleba.regular.MAX_SPAWNING_COOLDOWN = 360
gleba_constants.gleba.regular.MIN_SPAWNING_COOLDOWN = 150

gleba_constants.more_enemies = true

local _gleba_constants = gleba_constants

return gleba_constants