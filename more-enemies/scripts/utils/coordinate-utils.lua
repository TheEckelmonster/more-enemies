local math_floor = math.floor

local coordinate_utils = {}

local OFFSET = 2^15
local SHIFT_16 = 2^16

function coordinate_utils.pack(x, y) return ((math_floor(x) + OFFSET) * SHIFT_16) + (math_floor(y) + OFFSET) end
function coordinate_utils.unpack(xy) return math_floor(xy / SHIFT_16) - OFFSET, xy % SHIFT_16 - OFFSET end

return coordinate_utils