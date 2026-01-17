local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local Log = require("libs.log.log")

local locals = {}
locals = {
    ["defaults"] = function (self, data)
        Log.debug("queue-data.locals:defaults")
        Log.info(data)

        local _t_return = { source = "queue-data.locals:defaults", return_code = -1, valid = false }

        if (data ~= nil and type(data) ~= "table") then return _t_return end
        if (data ~= nil and data.index and (type(data.index) ~= "number" or data.index < 1)) then
            if (game and game.tick) then data.index = game.tick else return _t_return end
        end
        if (game == nil and data == nil) then return _t_return end

        local index = data and (data.index or data.tick) or 1

        return {
            type = data and data.type or "queue_data",
            name = data and data.name or "queue_data",
            count = 0,
            data_array = {},
            data_table = Data:new({
                name = data and data.name or "queue_data_table_" .. index,
                type = data and data.type or "queue_data_table",
                t = {},
            }),
            first = nil,
            index = index,
            last = nil,
            limit = data and data.limit or 2 ^ 8,
        }
    end,
}

local queue_data = {}

function queue_data:new(o, data)
    Log.debug("queue_data:new")
    Log.info(o)
    Log.info(data)

    local index = data and (data.index or data.tick) or 1

    local defaults = {
        type = data and data.type or "queue_data",
        name = data and data.name or "queue_data",
        count = 0,
        data_array = {},
        data_table = Data:new({
            name = data and data.name or "queue_data_table_" .. index,
            type = data and data.type or "queue_data_table",
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

    -- obj = Data:new(obj, data)
    obj = Data.new(obj, data)

    -- setmetatable(queue_data, Data)
    setmetatable(obj, self)
    self.__index = self

    return obj
end

function queue_data:next(data)
    Log.debug("queue_data:next")

    if (data == nil or type(data) ~= "table") then return nil, Data:do_return({ error_data = return_t }) end
    local return_t = Data:new({ return_code = -1, source = data.source and data.source .. ".queue_data:next" or "queue_data:next", level = 1 })
    if (game.tick % 16 == 0) then if (data and data.source) then if (self.count > 0) then log(data.source) end end end
    if (not data.order or type(data.order) ~= "string") then data.order = "last" end
    if (data.maintain == nil or type(data.maintain) ~= "boolean") then data.maintain = true end

    local return_val = nil
    local first = function (data)
        if (type(self.first) == "table") then
            return_val = self.first
            if (not data.maintain) then

                self.first = return_val.next
                if (self.first == self.last) then self.last = return_val.prev end
                if (self.first) then self.first.prev = nil end

                if (not data.maintain) then
                    return_val.next = nil
                    return_val.prev = nil
                end

                if (self.count > 0) then self.count = self.count - 1 end
                table.remove(self.data_array, return_val.index)

                local i = return_val.index or 1
                while i <= #self.data_array do
                    if (i < 1) then break end
                    self.data_array[i].index = self.data_array[i].index and self.data_array[i].index - 1 or i or 1
                    i = i + 1
                end

                self.data_table.t[return_val.index or 1] = nil
            end
        end
    end

    local last = function (data)
        if (type(self.last) == "table") then
            return_val = self.last
            if (not data.maintain) then
                if (not return_val.index) then
                    Log.error("mundo")
                    log(return_val)
                    log(return_val.index)
                end
                self.last = return_val.prev
                if (self.last == self.first) then self.first = return_val.next end
                if (self.last) then self.last.next = nil end

                return_val.next = nil
                return_val.prev = nil

                if (self.count > 0) then self.count = self.count - 1 end
                table.remove(self.data_array, return_val.index)

                local i = return_val.index or self.count
                while i <= #self.data_array do
                    if (i < 1) then break end
                    self.data_array[i].index = self.data_array[i].index and self.data_array[i].index - 1 or i or self.count or #self.data_array
                    i = i + 1
                end

                self.data_table.t[return_val.index or self.count] = nil
            end
        end
    end

    if (type(data.order) == "string") then
        if (data.order == "last") then
            last(data)
        else
            first(data)
        end
    else
        first(data)
    end

    -- Data.update(self)
    return return_val
end

function queue_data:remove(data)
    Log.debug("queue_data:remove")
    Log.info(data)

    log(serpent.block(data))
    log(serpent.block(self))

    log("1")
    if (self == nil or type(self) ~= "table") then return -1 end
    log("2")
    if (data == nil or type(data) ~= "table") then return -1 end
    log("3")
    if (data.data == nil or type(data.data) ~= "table") then return -1 end
    log("4")
    if (data.data.created == nil or type(data.data.created) ~= "number" or data.data.created < 0) then return -1 end
    log("5")
    if (not data.mode or data.mode and type(data.mode) ~= "string") then data.mode = "single" end
    log("6")

    local _data = data.data
    local _cache_data = storage.cache_data

    local data_to_remove = nil
    if (((      self.name and type(self.name) == "string" and self.name:find("entries_queue", 1, true))
            and
                _cache_data.entries[_data.created]
        )
        or
        ((      self.data_table.t[_data.created] ~= nil or self.data_table.t[_data.index] ~= nil)
            and (
                    self.data_table.t[_data.created] and self.data_array[self.data_table.t[_data.created].index] ~= nil
                or
                    self.data_table.t[_data.index] and self.data_array[self.data_table.t[_data.index].index] ~= nil
            )
        ))
    then

        log("7")

        data_to_remove =    self.data_table.t[_data.index] and  self.data_array[self.data_table.t[_data.index].index]
                        or  _cache_data.indices[_data.created] and _cache_data.entries[_data.created]


        local index =       self.data_table.t[_data.index] and self.data_table.t[_data.index].index
                        or _cache_data.indices[_data.created] and _cache_data.entries[_data.created].index

        log("index = " .. index)
        log("count = " .. self.count)

        if (self.count <= 1) then
            -- Log.error("I happened")
            -- log(serpent.block(self))
            --[[
                There was only one element
                -> Nothing will remain after removing it
                -> Hence setting first & last to nil
            ]]
            self.first = nil
            self.last = nil

            -- if (self.count >= 1) then self.count = self.count - 1 end

            -- self.data_array = {}
            -- self.data_table = {}

            -- _cache_data.entries[data_to_remove.created] = nil
            -- _cache_data.indices[data_to_remove.created] = nil

            -- return
        end

        local prev = data_to_remove.prev
        local _next = data_to_remove.next

        if (prev ~= nil and type(prev) == "table") then prev.next = _next end
        if (_next ~= nil and type(_next) == "table") then _next.prev = prev end
        -- if (prev ~= nil and type(prev) == "table" and _next ~= nil and type(_next) == "table") then _next.prev = prev end

        -- if (data_to_remove == self.first and data_to_remove == self.last) then -- Do nothing?
        -- if (data_to_remove == self.first and data_to_remove == self.last) then self.first.prev = nil; self.last.next = nil
        -- elseif (data_to_remove == self.first and type(self.first) == "table") then self.first = self.first.next
        if (data_to_remove == self.first and type(self.first) == "table") then
            -- log("setting self.first")
            -- log(serpent.block(self.first))
            -- if (self.first.next == nil) then log("found nil self.first.next") end
            if (self.first.next == nil) then
                Log.error("found nil self.first.next")
                log(serpent.block(self.first))
            end
            self.first = self.first.next
            -- if (self.first.next) then self.first = self.first.next end
            -- log(serpent.block(self.first))
        elseif (data_to_remove == self.last and type(self.last) == "table") then
            -- log("setting self.last")
            if (self.last.prev == nil) then
                log("found nil self.last.prev")
                log(serpent.block(self.last))
            end
            self.last = self.last.prev
            -- if (self.last.prev) then self.last = self.last.prev end
            -- log(serpent.block(self.last))
        end

        log(serpent.block(self.data_table.t))
        log(serpent.block(self.data_array))
        if (self.data_array[index] and self.data_table.t[index]) then
            self.data_table.t[index] = nil
            table.remove(self.data_array, index)

            if (self.count >= 1) then self.count = self.count - 1 end
        end
        log(serpent.block(self.data_table.t))
        log(serpent.block(self.data_array))

        if (self.name:find("entries_queue", 1, true)) then
            _cache_data.entries[data_to_remove.created] = nil
            _cache_data.indices[data_to_remove.created] = nil
        end

        local i = index

        while i <= #self.data_array do
            if (i < 1) then break end
            self.data_array[i].index = i

            i = i + 1
        end

        i = index

        local new_t = {}

        i = 1
        for _, v in pairs(self.data_table.t) do
            -- if (i == 1 and self.last) then self.last.prev = new_t[i] end
            new_t[i] = v
            new_t[i].index = i
            new_t[i].data.index = i
            i = i + 1
        end
        self.first = new_t[1]
        self.last = new_t[i]

        self.data_table.t = new_t
    end

    -- Data.update(self)

    return data_to_remove
end

function queue_data:enqueue(data)
    Log.debug("queue_data:enqueue")
    Log.info(data)

    if (self.limit and self.count >= 1 + self.limit * 1.5 --[[TODO: Make this configurable]]) then return { valid = false } end

    if (type(data) ~= "table") then return -1 end
    -- if (game.tick % 16 == 0) then if (data.source) then if (self.count > 0) then log(data.source) end end end
    if (game.tick % 1 == 0) then if (data.source and not data.source:find("cache", 1, true)) then if (self.count > 0) then log(data.source) end end end
    if (data.source) then Log.debug(data.source) end
    if (data.data == nil or type(data.data) == "function") then return -1 end

    local _data = data.data

    if (self.first == nil or self.last == nil or self.count == 0) then
        -- log(serpent.block(self.first))
        -- log(serpent.block(self.last))
        -- log(serpent.block(self.count))
        -- log(serpent.block(self.data))
        self.first = _data
        self.last = _data
        self.data_array = {}
        self.data_table = Data:new({ type = "queue_data_table", name = "queue_data_table_" .. game.tick, t = {},})
        self.count = 1
    else
        -- Enqueue the data

        if (self.first ~= self.last) then
            local last_prev = self.last
            last_prev.next = _data
            _data.prev = last_prev
            self.last = _data
            _data.next = nil

            if (self.last.next) then
                self.last.next = nil
            end
            if (self.first.prev) then
                self.first.prev = nil
            end
        else
            self.last.next = _data
            _data.prev = self.last
            self.last = _data

            if (self.last.next) then
                self.last.next = nil
            end
            if (self.first.prev) then
                self.first.prev = nil
            end
        end
        self.count = self.count + 1
    end

    local index = nil

    if (self.name and self.name:find("entries_queue", 1, true)) then
        _data.index = _data.index
        index = _data.index
    elseif (self.name and self.name:find("cache", 1, true)) then
        _data.index = self.count
        index = self.count
    end
    table.insert(self.data_array, _data)

    index = index or self.count

    if (self.data_table.t[index]) then
        local k, v = next(self.data_table.t, index - 1)

        while k or (not k and v) do
            if (type(k) == "number") then
                if (k and k < 1) then break end
                if (self.data_array[k] ~= nil and type(self.data_array[k]) == "table" and self.data_array[k].index) then
                    self.data_array[k].index = self.data_array[k].index - 1
                end
            end

            if (k) then k, v = next(self.data_table.t, k) end
        end

        if (self.count > 1) then
            table.remove(self.data_array, self.data_array[index] and self.data_array[index].index or index)
        end
    end

    self.data_table.t[index] = { index = index, data = _data, }

    -- Data.update(self)

    return _data, 1
end

function queue_data:dequeue(data)
    Log.debug("queue_data:dequeue")
    Log.info(data)

    if (data and data.source) then Log.debug(data.source) end

    -- Data.update(self)

    -- return queue_data.next(self, data)
    return self:next(data)
end

setmetatable(queue_data, Data)
local Queue_Data = queue_data:new(Queue_Data)

return Queue_Data