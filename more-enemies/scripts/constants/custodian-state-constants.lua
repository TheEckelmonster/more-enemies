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
local EVALUATION = states()
local PROCESSING = states()
local REMOVING = states()
local FINALIZE = states()
local COMMAND_COMPLETED = states()

STATES = {
    RECOVERY = RECOVERY,
    EVALUATION = EVALUATION,
    PROCESSING = PROCESSING,
    REMOVING = REMOVING,
    FINALIZE = FINALIZE,
    COMMAND_COMPLETED = COMMAND_COMPLETED,
}

return STATES