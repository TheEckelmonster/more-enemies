local pairs = pairs
local setmetatable = setmetatable
local type = type

local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local Data_new = Data.new

local quadtree = {}

quadtree.surface_name = nil
quadtree.count = 0

local NAUVIS = NAUVIS or "nauvis"
function quadtree:new(o)
    local obj = o or {}

    obj.surface_name = obj.surface_name or self.surface_name or NAUVIS
    obj.count = obj.count or 0

    self.__index = self
    return setmetatable(Data_new(Data, obj), self)
end

setmetatable(quadtree, Data)
quadtree.__index = quadtree

return quadtree