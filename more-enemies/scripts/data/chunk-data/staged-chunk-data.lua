local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local staged_chunk_data = {}

--[[
    Area or Position are required, but are not mutually exclusive
]]
staged_chunk_data.area = nil
staged_chunk_data.position = nil

staged_chunk_data.event = nil
staged_chunk_data.next = nil
staged_chunk_data.prev = nil
staged_chunk_data.surface = nil
staged_chunk_data.surface_name = nil
staged_chunk_data.x = nil
staged_chunk_data.y = nil

function staged_chunk_data:new(obj)
    Log.debug("staged_chunk_data:new")
    Log.info(obj)

    obj = Data:new(obj)

    local defaults = {
        event = self.event,
        next = self.next,
        prev = self.prev,
        surface = self.surface,
        surface_name = self.surface_name,
        x = self.x,
        y = self.y,
    }

    for k, v in pairs(defaults) do
        if (obj[k] == nil) then obj[k] = v end
    end

    setmetatable(obj, self)
    self.__index = self

    obj.valid = obj:is_valid()

    return obj
end

function staged_chunk_data:is_valid()
    return  (
                (
                    type(self.area) == "table"
                and type(self.area.left_top) == "table"
                and type(self.area.left_top.x) == "number"
                and type(self.area.left_top.y) == "number"
                and type(self.area.right_bottom) == "table"
                and type(self.area.right_bottom.x) == "number"
                and type(self.area.right_bottom.y) == "number")
            or  (
                    type(self.position) == "table"
                and type(self.position.x) == "number"
                and type(self.position.y) == "number")
            )
        and
            (
                type(self.surface_name) == "string"
            and type(self.surface) == "userdata"
            and self.surface.valid
            )
        and (type(self.event) == "number")
        and (type(self.x) == "number")
        and (type(self.y) == "number")
end

setmetatable(staged_chunk_data, Data)
staged_chunk_data.__index = staged_chunk_data

return staged_chunk_data