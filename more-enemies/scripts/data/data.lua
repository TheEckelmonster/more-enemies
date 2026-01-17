-- local Data_Constants = require("libs.constants.data-constants")
local Log = require("libs.log.log")

local locals = {}
locals = {
    ["defaults"] = function (self, _, data)
        Log.debug("data.locals:defaults")
        Log.info(data)

        -- local index = game and game.tick or 1
        local index = game and game.tick or 0

        return {
            name = data and data.name,
            type = data and data.type,
            created = index,
            updated = index,
            -- valid = true,
        }
    end,
    ["meta_data"] = {
        ["defaults"] = function (self, data)
            Log.debug("data.locals.meta_data:defaults")
            Log.info(data)
            return locals:new({
                -- funcs = locals:new_data({ name = "funcs" }),
                funcs = locals:new({ name = "funcs" }),
                counts = locals:new({
                    name = "counts",
                    type = "meta_data",
                    retrieved = 0,
                    updated = 0,
                }),
                -- ticks = locals:new_data({
                ticks = locals:new({
                    name = "ticks",
                    type = "meta_data",
                    recent_1 = data and data.tick or game and game.tick,
                    recent_2 = data and data.updated or data and data.created or game and game.tick,
                    recent_3 = data and data.created or game and game.tick,
                    recent_4 = game and game.tick,
                    retrieved = 0,
                }),
                -- data = locals:new_data(data),
                data = locals:new(data),
            })
        end,
        ["new"] = function (self, obj, data)
            Log.debug("data.locals.meta_data:new")
            Log.info(obj)
            Log.info(data)

            if (data and type(data) ~= "table") then return { return_code = -1, source = "data.locals.meta_data:new" } end

            local defaults = self:defaults()

            if (type(obj) ~= "table") then obj = locals:new() end
            if (type(obj.meta) ~= "table") then obj.meta = defaults end

            for k, v in pairs(defaults) do if (obj.meta[k] == nil) then obj.meta[k] = v end end

            return obj
        end,
    },
    ["new"] = function (self, obj, data)
        Log.debug("data.locals:new")
        Log.info(obj)
        Log.info(data)

        if (data and type(data) ~= "table") then return { return_code = -1, source = "data.locals:new" } end

        local defaults = self:defaults()

        if (type(obj) ~= "table") then obj = defaults end

        -- for k, v in pairs(defaults) do if (obj[k] == nil) then obj[k] = v end end
        for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

        if (data and type(data.include_meta_data) == "boolean" and data.include_meta_data) then locals.meta_data:new(obj) end
        -- if (type(obj.include_meta_data) == "boolean" and obj.include_meta_data) then locals.meta_data:new(obj) end

        return obj
    end,
    -- ["new_data"] = function (self, obj, data)
    --     Log.debug("data.locals:new_data")
    --     Log.info(obj)

    --     return type(obj) == "table" and locals:new(obj, data) or locals:new(_, data)
    -- end,
}

local _data = {}

-- local defaults = {}
-- setmetatable(defaults, { __mode = "k" })
-- local mt = {__index = function (t) return defaults[t] end}
-- function setDefault (t, d)
--     defaults[t] = d
--     setmetatable(t, mt)
-- end

local _data = {}
local Data = {}

function _data:new(o, data)
-- function Data:new(o, data)
    Log.debug("data:new")
    Log.info(o)
    Log.info(data)

    local _t_return = locals:new({ return_code = -1, source = "data:new", level = 1, valid = false })

    -- if (data and type(data) ~= "table") then return _data:do_return({ error_data = _t_return }) end
    if (data and type(data) ~= "table") then return self:do_return({ error_data = _t_return }) end

    local defaults = locals:defaults(_, data)

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = locals:new(obj, data)

    -- setmetatable(self, getmetatable(obj))
    setmetatable(obj, self)
    -- self.__index = nil
    self.__index = function (t, k)
        -- log("data")
        -- Log.error("data", true)
        -- log(serpent.block(table))
        -- log(serpent.block(key))
        -- log(serpent.block(self))

        -- if (t ~= nil) then
        --     return t[k]
        -- end
        if (k == nil) then return nil end

        -- log(serpent.block(self[k]))

        return self[k]
    end

    if (game and obj.valid ~= nil) then obj.valid = obj:is_valid() end

    return obj
end

function _data:is_valid()
-- function Data:is_valid()
    Log.debug("data:is_valid")
    return  self.created ~= nil
        and type(self.created) == "number"
        and self.created >= 0
        and self.updated ~= nil
        and type(self.updated) == "number"
        and self.updated >= self.created
end

function _data:do_return(data)
-- function Data:do_return(data)
    Log.debug("data:do_return")
    Log.info(data)

    -- log(serpent.block(data))
    -- Log.error(serpent.block(data), true)

    local _t_return = locals:new({ return_code = -1, source = "data:do_return\n\t", level = 1 })

    if (data == nil or type(data) ~= "table") then return _t_return end
    if (data.error_data == nil or type(data.error_data) ~= "table") then return _t_return end

    _t_return.error_data = data.error_data
    _t_return.level = data.error_data.level and type(data.error_data.level) == "number" and data.error_data.level + _t_return.level or _t_return.level + 1
    _t_return.trace = data.error_data.source and _t_return.source .. "." .. data.error_data.source or _t_return.source .. ".???"

    return _t_return
end

function _data:update(data)
-- function Data:update(data)
    Log.debug("data:update")
    Log.info(self)
    -- log(serpent.block(self))
    Log.info(data)

    if (data and type(data) ~= "table") then return -1 end

    if (data and type(data.data) == "table" and next(data.data)) then for k, v in pairs(data.data) do if (type(v) ~= "function") then self[k] = v end end end

    -- if (type(self.meta) == "table") then _data.update_meta_information(self) end
    if (type(self.meta) == "table") then self:update_meta_information() end
end

function _data:update_meta_information(data)
-- function Data:update_meta_information(data)
    Log.debug("data:update_meta_information")
    Log.info(data)

    if (data and type(data) ~= "table") then return -1 end
    if (data and type(data.meta) ~= "table" and next(data.data)) then return -1 end

    if (type(self.meta) == "table") then
        self.meta.ticks.recent_4 = self.meta.ticks.recent_3
        self.meta.ticks.recent_3 = self.meta.ticks.recent_2
        self.meta.ticks.recent_2 = self.meta.ticks.recent_1
        self.meta.ticks.recent_1 = game.tick
        self.meta.ticks.tick = game.tick
        self.meta.counts.updated = self.meta.counts.updated + 1
        self.meta.updated = game.tick
    end
end

-- return _data

Data = _data:new(Data)

return Data