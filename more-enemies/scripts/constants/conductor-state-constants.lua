local states = (function (start)
    local self = {}

    local mt = { count = start, }
    mt.__call = function ()
            mt.count = mt.count + 1
            return mt.count
        end
    mt.__index = mt

    return setmetatable(self, mt)
end)(0)

local RECOVERY = states()
local IDLE = states()
local REQUESTING = states()
local SCANTREE = states()
local REQUESTING_PATH = states()
local PATHFINDING = states()
local PATH_FOUND = states()
local PATH_PROCESSING = states()
local DISPATCH = states()
local FINALIZE = states()

STATES = {
    RECOVERY = RECOVERY,
    IDLE = IDLE,
    REQUESTING = REQUESTING,
    SCANTREE = SCANTREE,
    REQUESTING_PATH = REQUESTING_PATH,
    PATHFINDING = PATHFINDING,
    PATH_FOUND = PATH_FOUND,
    PATH_PROCESSING = PATH_PROCESSING,
    DISPATCH = DISPATCH,
    FINALIZE = FINALIZE,
}

return STATES