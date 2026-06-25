local pairs = pairs
local type = type

local Coordinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coordinate_Utils.pack

local storage = storage

local ctr = (function (start)
    local self = {}

    local mt = { count = start, }
    mt.__call = function ()
            mt.count = mt.count + 1
            return mt.count
        end
    mt.__index = mt

    return setmetatable(self, mt)
end)(0)

local found = {}

local function recurse(tbl)
    if (type(tbl) ~= "table") then return tbl end
    if (type(tbl.x) == "number" and type(tbl.y) == "number") then tbl.xy = pack_coordinates(tbl.x, tbl.y) end
    for k, v in pairs(tbl or {}) do
        if (type(v) == "table" and not found[v]) then
            found[v] = ctr()
            recurse(v)
        end
    end
end
recurse(storage)