local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local locals = {}
locals = {
    ["defaults"] = function (self, data)
        Log.debug("list-data.locals:defaults")
        Log.info(data)

        local _t_return = { source = "list-data.locals:defaults", return_code = -1, valid = false }

        if (data ~= nil and type(data) ~= "table") then return _t_return end
        if (data ~= nil and data.index and (type(data.index) ~= "number" or data.index < 1)) then
            if (game and game.tick) then data.index = game.tick else return _t_return end
        end
        if (game == nil and data == nil) then return _t_return end

        local index = data and (data.index or data.tick) or 1

        return {
            type = data and data.type or "list_data",
            name = data and data.name or "list_data",
            count = 0,
            data_array = {},
            data_table = Data:new({
                name = data and data.name or "list_data_table_" .. index,
                type = data and data.type or "list_data_table",
                t = {},
            }),
            first = nil,
            index = index,
            last = nil,
            limit = data and data.limit or 2 ^ 8,
        }
    end,
}

local list_data = {}
local List_Data = {}

function list_data:new(o, data)
    Log.debug("list_data:new")
    Log.info(o)
    Log.info(data)

    local index = data and (data.index or data.tick) or 1

    local defaults = {
        type = data and data.type or "list_data",
        name = data and data.name or "list_data",
        count = 0,
        data_array = {},
        data_table = Data:new({
            name = data and data.name or "list_data_table_" .. index,
            type = data and data.type or "list_data_table",
            t = {},
        }),
        first = nil,
        index = index,
        last = nil,
        limit = data and data.limit or 2 ^ 8,
    }

    local obj = o or defaults

    for k, v in pairs(defaults) do
        if (obj[k] == nil and type(v) ~= "function") then
            obj[k] = v end end

    obj = Data:new(obj, data)

    setmetatable(list_data, Data)
    setmetatable(obj, self)
    self.__index = self

    return obj
end

function list_data:remove(data)
    Log.debug("list_data:remove")
    Log.info(data)

    log(serpent.block(data))
    log(serpent.block(self))

    -- Data.update(self)

    return data_to_remove
end

List_Data = list_data:new(List_Data)

return List_Data