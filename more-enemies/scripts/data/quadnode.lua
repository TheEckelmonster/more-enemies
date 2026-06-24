local storage

local game

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage
    game = __game or _ENV.game
    return game
end

local setmetatable = setmetatable

local Constants = Constants or require("scripts.constants.constants")
local HALF_MAP_SIZE = Constants.HALF_MAP_SIZE

local Coodinate_Utils = require("scripts.utils.coordinate-utils")
local pack_coordinates = Coodinate_Utils.pack
local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template

local quadnode = {}

quadnode.size = HALF_MAP_SIZE
quadnode.node_level = 1
quadnode.x = 0
quadnode.y = 0

function quadnode:new(o, tick)
    local obj = o or {}
    tick = tick or (game or set_game()).tick

    obj.size = obj.size or self.size or HALF_MAP_SIZE
    obj.nw = obj.nw or self.nw or nil
    obj.ne = obj.ne or self.ne or nil
    obj.sw = obj.sw or self.sw or nil
    obj.se = obj.se or self.se or nil
    obj.node_level = obj.node_level or self.node_level or 1

    if (obj.x and obj.y) then obj.xy = pack_coordinates(obj.x, obj.y) end

    obj.meta = obj.meta or new_template(Quad_Meta_Data, tick)

    self.__index = self
    return setmetatable(obj, self)
end

quadnode.__index = quadnode

return quadnode