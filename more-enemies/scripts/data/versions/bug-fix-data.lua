local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local bug_fix_data = {}
local Bug_Fix_Data = {}

bug_fix_data.value = 0
bug_fix_data.warned = false
bug_fix_data.valid = true

function bug_fix_data:new(o)
    Log.debug("bug_fix_data:new")
    Log.info(o)

    local defaults = {
        value = bug_fix_data.value,
        warned = bug_fix_data.warned,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj)

    setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    self.__index = self

    return obj
end

-- bug_fix_data = bug_fix_data:new(bug_fix_data)
Bug_Fix_Data = bug_fix_data:new(Bug_Fix_Data)

-- return bug_fix_data
return Bug_Fix_Data