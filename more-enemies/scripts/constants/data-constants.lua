
local Log = require("libs.log.log")

local data_constants = {}

data_constants.DEFAULTS = {}


data_constants.DEFAULTS.planets = {
    nauvis = {
        string_val = "nauvis"
    },
    gleba = {
        string_val = "gleba"
    },
}

data_constants.CHUNK_SIZE = 32
data_constants.CHUNK_LEVELS = 6

for i = 1, data_constants.CHUNK_LEVELS - 1 do
    data_constants["CHUNK_SIZE_" .. 2 ^ i] = data_constants.CHUNK_SIZE * (2 ^ i)
end

data_constants.BIG_INTEGER = (2 ^ data_constants.CHUNK_SIZE) - 1
data_constants.BIG_NUM = data_constants.BIG_INTEGER
data_constants.INT_MAX = (2 ^ (data_constants.CHUNK_SIZE * 2)) - 1
data_constants.SMALL_NUM = 0.000001
data_constants.SMALL_NUM = 2 ^ - (data_constants.CHUNK_SIZE - 1)

data_constants.time = {}
data_constants.time.SECONDS_PER_MINUTE = 60
data_constants.time.MINUTES_PER_HOUR = 60
data_constants.time.TICKS_PER_SECOND = 60
data_constants.time.TICKS_PER_MINUTE = data_constants.time.TICKS_PER_SECOND * data_constants.time.SECONDS_PER_MINUTE
data_constants.time.TICKS_PER_HOUR = data_constants.time.TICKS_PER_MINUTE * data_constants.time.MINUTES_PER_HOUR

data_constants.time.TICKS = {}
for i=0, 16 do table.insert(data_constants.time.TICKS, 2 ^ i) end

return data_constants