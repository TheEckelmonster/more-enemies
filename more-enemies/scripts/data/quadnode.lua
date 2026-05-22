local setmetatable = setmetatable

local Constants = Constants or require("scripts.constants.constants")
local HALF_MAP_SIZE = Constants.HALF_MAP_SIZE

local quadnode = {}

quadnode.size = HALF_MAP_SIZE
quadnode.node_level = 1
quadnode.x = 0
quadnode.y = 0

function quadnode:new(o)
    local obj = o or {}

    obj.size = obj.size or self.size or HALF_MAP_SIZE
    obj.nw = obj.nw or self.nw or nil
    obj.ne = obj.ne or self.ne or nil
    obj.sw = obj.sw or self.sw or nil
    obj.se = obj.se or self.se or nil
    obj.node_level = obj.node_level or self.node_level or 1

    self.__index = self
    return setmetatable(obj, self)
end

quadnode.__index = quadnode

return quadnode