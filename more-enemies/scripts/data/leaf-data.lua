local storage

local game

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage
    game = __game or _ENV.game
    return game
end

local setmetatable = setmetatable

local Constants = Constants or require("scripts.constants.constants")
local CHUNK_LEVELS = Constants.CHUNK_LEVELS

local Quad_Meta_Data = Quad_Meta_Data or require("scripts.data.quad-meta-data")
local new_template = Quad_Meta_Data.new_template

local leaf_data = {}
leaf_data.name = "leaf_data"
leaf_data.set_game = set_game

leaf_data.node_level = CHUNK_LEVELS
leaf_data.parent_node = nil
leaf_data.player_data = nil
leaf_data.enemy_data = nil
leaf_data.created = nil
leaf_data.updated = nil

function leaf_data:new(o, tick)
    local obj = o or {}
    tick = tick or (game or set_game()).tick

    obj.node_level = obj.node_level or CHUNK_LEVELS
    obj.player_data = obj.player_data or { created = tick, updated = tick, }
    obj.enemy_data = obj.enemy_data or { created = tick, updated = tick, }

    obj.meta = obj.meta or new_template(Quad_Meta_Data, tick)

    obj.created = tick
    obj.updated = tick

    self.__index = self
    return setmetatable(obj, self)
end

function leaf_data.init(__storage) storage = __storage or _ENV.storage end

leaf_data.__index = leaf_data

return leaf_data