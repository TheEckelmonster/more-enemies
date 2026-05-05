local Constants = require("libs.constants.constants")
local Data = require("scripts.data.data")
local List_Data = require("scripts.data.structures.list-data")
local Log = require("libs.log.log")

local locals = {}
locals = {
    ["defaults"] = function (self, obj, data)
        Log.debug("data.locals:defaults")
        Log.info(data)

        return locals:new_cache_data(obj, data)
    end,
    ["new_cache_data"] = function (self, obj, data)
        Log.debug("data.locals:new_cache_data")
        Log.info(data)

        if (obj ~= nil and type(obj) ~= "table") then return -1 end
        if (data ~= nil and type(data) ~= "table") then return -1 end
        if (data ~= nil and data.index and (type(data.index) ~= "number" or data.index < 0)) then return -1 end
        if (game == nil and data == nil) then return -1 end

        local index = data and data.index or game and game.tick or 1

        local include_meta_data = { include_meta_data = data and data.include_meta_data }

        local entries = {}
        local indices = {}
        -- setmetatable(indices, { __mode = "kv" })

        return {
            type = "cache_data",
            name = "cache_data",
            entries = entries,
            indices = indices,
            entries_list = List_Data:new({ name = "entries_list_" .. index, index = index, limit = 2 ^ 3 --[[TODO: Make limit configurable]] }, include_meta_data),
        }
    end,
    ["new_cache_entry"] = function (self, obj, data)
        Log.debug("data.locals:new_cache_entry")
        Log.info(data)

        if (obj ~= nil and type(obj) ~= "table") then return -1 end
        if (data ~= nil and type(data) ~= "table") then return -1 end
        if (data ~= nil and data.index and (type(data.index) ~= "number" or data.index < 0)) then return -1 end
        if (game == nil and data == nil) then return -1 end

        local index = data and data.index or game and game.tick or 1
        local include_meta_data = { include_meta_data = data and data.include_meta_data }

        return Data:new({
            type = "cache_entry",
            name = "cache_entry_" .. index,
            list = List_Data:new({ name = "cache_entry_list_" .. index, index = index, limit = 2 ^ 5 --[[TODO: Make limit configurable]] }, include_meta_data),
            index = index,
            cache = locals:new_cache(),
        }, include_meta_data)
    end,
    ["new_cache"] = function (self, data)
        Log.debug("data.locals:new_cache")
        Log.info(data)

        if (data ~= nil and type(data) ~= "table") then return -1 end
        if (data ~= nil and data.index and (type(data.index) ~= "number" or data.index < 0)) then return -1 end
        if (game == nil and data == nil) then return -1 end

        local index = data and data.index or game and game.tick or 1
        local include_meta_data = { include_meta_data = data and data.include_meta_data }

        return Data:new({
            index = index,
            name = "cache_" .. index,
            type = "cache",
            t = {},
        }, include_meta_data)
    end,
    ["new_cache_object"] = function (self, data)
        Log.debug("data.locals:new_cache")
        Log.info(data)

        if (data ~= nil and type(data) ~= "table") then return { valid = false } end
        if (game == nil and data == nil) then return { valid = false } end

        local include_meta_data = { include_meta_data = data and data.include_meta_data }

        return Data:new({
            -- TODO: Make the tick_valid_until value configurable
            tick_valid_until = data and data.tick_valid_until and data.tick_valid_until + 0
                            or game and game.tick and game.tick + math.random(1, math.random(2,666))
                            or -1,
            tick_valid_until_original = tick_valid_until,
            type = "cache_object",
        }, include_meta_data)
    end,
}

local cache_data = {}

local Cache_Data = {
    mt = cache_data
}

function cache_data:new(o, data)
    Log.debug("cache_data:new")
    Log.info(o)

    local defaults = game and locals:defaults() or {}
    if (defaults.valid ~= nil and not defaults.valid) then return { valid = false } end

    local obj = o or defaults

    for k, v in pairs(defaults) do if (obj[k] == nil and type(v) ~= "function") then obj[k] = v end end

    obj = Data:new(obj, data)

    -- setmetatable(cache_data, Data)
    setmetatable(obj, self)
    self.__index = self

    obj.valid = obj:is_valid()

    return obj
end

function cache_data:get(data)
    Log.debug("cache_data:get")
    Log.info(data)

    -- if (not storage.cache_data) then storage.cache_data = cache_data:new(locals:defaults({ index = game.tick }), { include_meta_data = true }) end
    if (not storage.cache_data) then storage.cache_data = cache_data:new(locals:defaults({ index = game.tick })) end
    local _cache_data = storage.cache_data

    if (not getmetatable(_cache_data)) then
        log("found no meta table")
        setmetatable(_cache_data, cache_data)
    end

    _cache_data.valid = _cache_data:is_valid()
    -- _cache_data.meta.ticks.retrieved = game.tick
    -- _cache_data.meta.counts.retrieved = _cache_data.meta.counts.retrieved + 1

    -- _cache_data:update()

    return _cache_data
end

function cache_data:add(data)
    Log.debug("cache_data:add")
    Log.info(data)

    -- log(serpent.block(data))

    if (not data or type(data) ~= "table") then return -1 end
    if (data.key == nil or type(data.key) == "function") then return -1 end
    if (data.value == nil or type(data.value) == "function") then return -1 end
    if (data.tick_valid_until == nil or type(data.tick_valid_until) ~= "number") then data.tick_valid_until = Constants.BIG_NUM end

    local _cache_data = cache_data:get()
    if (not _cache_data.valid) then return -1 end

    if (not _cache_data.entries or type(_cache_data.entries) ~= "table") then return -1 end
    if (not _cache_data.entries_list or type(_cache_data.entries_list) ~= "table") then return -1 end
    if (_cache_data.entries_list.last ~= nil and (not _cache_data.entries_list.data_array or type(_cache_data.entries_list.data_array) ~= "table")) then return -1 end
    if (_cache_data.entries_list.last ~= nil and (not _cache_data.entries_list.data_table or type(_cache_data.entries_list.data_table) ~= "table")) then return -1 end
    local most_recent_entry = _cache_data.entries_list.last

    local rand = math.random(1,5)
    local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Constants.difficulty.difficulties_array[rand]]]

    -- rand = (math.random(2 ^ 8) + math.random(2 ^ 8)) / 2 --[[TODO: Make this configurable]]
    rand = (math.random(2 ^ 10) + math.random(2 ^ 10)) / 2 --[[TODO: Make this configurable]]
    if (    (most_recent_entry == nil or type(most_recent_entry) ~= "table")
        -- or  (most_recent_entry ~= nil and type(most_recent_entry) == "table" and most_recent_entry.created + (2 ^ 6) * selected_difficulty.value --[[TODO: Make this configurable]] + rand <= game.tick))
        or  (most_recent_entry ~= nil and type(most_recent_entry) == "table" and most_recent_entry.created + (2 ^ 8) * selected_difficulty.value --[[TODO: Make this configurable]] + rand <= game.tick))
    then
        local index = _cache_data.entries_list.count + 1

        local new_entry = locals:new_cache_entry( _, { index = index, include_meta_data = data.include_meta_data })
        new_entry = _cache_data.enlist(_cache_data.entries_list, { source = "cache_data:add_" .. game.tick, data = new_entry})

        if (table_size(_cache_data.entries) > 5 or table_size(_cache_data.indices) > 5) then
            Constants.table.traverse_print(new_entry, "cache_data-new_entry_" .. game.tick)
            Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
            Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
            error("too many entries")
        end

        if (type(new_entry) == "table" and new_entry.index and new_entry.created) then
            _cache_data.entries[new_entry.created] = new_entry
            _cache_data.indices[new_entry.created] = 1
            most_recent_entry = _cache_data.entries[new_entry.created]
        else
            Log.error("How in the world?", true)
            log(serpent.block(new_entry))
        end
    end


    if (type(_cache_data.entries_list.count) == "number" and _cache_data.entries_list.count > 4 --[[TODO: Make this configurable]]) then
        log("too many entries in cache")
        if (table_size(_cache_data.entries) > 5 or table_size(_cache_data.indices) > 5) then
            Constants.table.traverse_print(_cache_data.entries_list.first, "cache_data.entries_list.first_" .. game.tick)
            Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
            Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
            error("too many entries")
        end
        if (_cache_data.entries_list.first ~= nil) then
            local to_remove = _cache_data.entries_list.first
            if (to_remove ~= nil and type(to_remove) == "table" and to_remove.created) then
                log("removing")
                while next(_cache_data.entries) and next(_cache_data.entries) <= to_remove.created do
                    local index = next(_cache_data.entries)
                    if (index == nil) then break end
                    local temp = _cache_data.remove(_cache_data.entries_list, { data = _cache_data.entries[index] })
                    -- log(serpent.block(temp))
                    _cache_data.entries[index] = nil
                    _cache_data.indices[index] = nil
                end
                _cache_data.remove(_cache_data.entries_list, { data = to_remove, })
                _cache_data.entries[to_remove.created] = nil
                _cache_data.indices[to_remove.created] = nil
            end
        else
            -- Couldn't find the entry, so just try to remove the oldest object in the list

            local oldest = math.huge

            -- TODO: Make this the configurable cache size
            for k, _ in pairs(_cache_data.indices) do if (k < oldest) then oldest = k end end

            if (oldest < math.huge) then
                local entry = _cache_data.entries[oldest]
                if (entry ~= nil and type(entry) == "table") then
                    log("removing oldest cache entry 2")

                    while next(_cache_data.entries) and next(_cache_data.entries) <= entry.created do
                        local index = next(_cache_data.entries)
                        if (index == nil) then break end
                        _cache_data.remove(_cache_data.entries_list, { data = _cache_data.entries[index] })
                        _cache_data.entries[index] = nil
                        _cache_data.indices[index] = nil
                    end
                end
            end
        end
        if (table_size(_cache_data.entries) > 4 or table_size(_cache_data.indices) > 4) then
            Constants.table.traverse_print(most_recent_entry, "cache_data-add-most_recent_entry_" .. game.tick)
            Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
            Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
            error("too many entries")
        end
        if (table_size(_cache_data.entries) ~= _cache_data.entries_list.count or table_size(_cache_data.indices) ~= _cache_data.entries_list.count) then
            Constants.table.traverse_print(data, "cache_data-get_by_key-data_" .. game.tick)
            Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
            Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
            Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
            error("counts don't match")
        end
    end

    if (table_size(_cache_data.entries) > 4 or table_size(_cache_data.indices) > 4) then
        Constants.table.traverse_print(most_recent_entry, "cache_data-add-most_recent_entry_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
        error("too many entries")
    end

    if (most_recent_entry == nil) then return end

    local cache_obj = locals:new_cache_object(data.obj, { include_meta_data = data.include_meta_data })

    cache_obj.value = data.value
    cache_obj.key = data.key
    cache_obj.tick_valid_until = data.tick_valid_until

    cache_obj = Data:new({
        value = cache_obj.value,
        key = cache_obj.key,
        type = cache_obj.type,
        index = most_recent_entry.list.count + 1,
        tick_valid_until = cache_obj.tick_valid_until,
        tick_valid_until_original = cache_obj.tick_valid_until,
    })
    most_recent_entry.cache.t[cache_obj.key] = cache_obj

    -- log("enlisting 1")
    cache_data.enlist(most_recent_entry.list,  { source = most_recent_entry.list.name, data = cache_obj})

    local to_remove = {}
    for k, v in pairs(most_recent_entry.cache.t) do
        -- log(serpent.block(k))
        -- if (v.tick_valid_until <= entry.cache.t[data.key].tick_valid_until) then
        if (v.tick_valid_until <= game.tick) then
            -- log("removing old cache object")
            local removed = cache_data.remove(most_recent_entry.list, { data = v })
            -- log(serpent.block(removed))
            if (type(removed) == "table") then
                to_remove[k] = k
            end
        end
    end

    for k, _ in pairs(to_remove) do
        most_recent_entry.cache.t[k] = nil
    end

    if (most_recent_entry.cache.t ~= nil and type(most_recent_entry.cache.t) == "table") then
        local i = 1
        for _, v in pairs(most_recent_entry.cache.t) do
            if (type(v) == "table") then
                v.index = i
                i = i + 1
            end
        end
        most_recent_entry.list.first = most_recent_entry.list.data_array[1]
        most_recent_entry.list.last = most_recent_entry.list.data_array[i - 1]
        most_recent_entry.list.count = i - 1
    end

    -- self:update()
    -- return most_recent_entry
    return cache_obj
end

-- function cache_data:remove_by_key(data)
--     Log.debug("cache_data:remove_by_key")
--     Log.info(data)

--     if (data == nil or type(data) ~= "table") then return -1 end
--     if (data.key == nil or type(data.key) == "function") then return -1 end

--     local _cache_data = cache_data:get()
--     if (not _cache_data.valid) then return -1 end

--     local entry_found = false

--     -- Get the most recently added entry to the cache
--     local entry, _ = List_Data.next(_cache_data.entries_list, { source = "cache_data:remove_by_key", order = "last", maintain = true })
--     local data_to_remove = nil

--     while entry ~= nil and type(entry) == "table" do
--         if (entry.valid and entry.data[data.key]) then
--             data_to_remove = entry.data[data.key]
--             entry_found = true
--             break
--         end

--         entry = entry.prev
--     end

--     if (entry and entry_found and data_to_remove ~= nil and type(data_to_remove) == "table") then
--         if (data_to_remove ~= nil and type(data_to_remove) == "table" and data_to_remove.index) then
--             _cache_data.entries[data_to_remove.index] = nil
--             _cache_data.indices[data_to_remove.index] = nil
--             List_Data.remove(_cache_data.entries_list, { data = data_to_remove, mode = "single" })
--             List_Data.remove(entry.list, { data = data_to_remove })
--         end
--     end

--     Data.update(self)
-- end

function cache_data:get_entries(data)
    Log.debug("cache_data:get")
    Log.info(data)

    local _cache_data = cache_data:get()
    if (not _cache_data.valid) then return -1 end

    -- Data.update(self)
    return _cache_data.entries
end

function cache_data:get_entry(data)
    Log.debug("cache_data:get")
    Log.info(data)

    if (data == nil or type(data) ~= "table") then return -1 end
    if (data.key == nil or type(data.key) == "function") then return -1 end

    local _cache_data = cache_data:get()
    if (not _cache_data.valid) then return -1 end

    -- Data.update(self)
    return _cache_data.entries[data.key]
end

function cache_data:get_by_key(data)
    Log.debug("cache_data:get_by_key")
    Log.info(data)

    local _t_return = Data:new({ type = "return_data", name = "cache_data.default.return_data", return_code = -1, valid = false })

    if (data == nil or type(data) ~= "table") then return nil, _t_return end
    if (data.key == nil or type(data.key) == "function") then return nil, _t_return end
    if (data.tick == nil or type(data.tick) ~= "number") then data.tick = game.tick end
    --[[ data.fallback is expected to be a function that returns a key/value table, and optionally a tick_valid_until value ]]
    if (data.fallback ~= nil and type(data.fallback) ~= "function") then return nil, _t_return end
    if (data.tick_valid_until == nil or type(data.tick_valid_until) ~= "number") then data.tick_valid_until = Constants.INT_MAX - 1 end
    if (data.tick_valid_until_modifier == nil or type(data.tick_valid_until_modifier) ~= "number") then data.tick_valid_until_modifier = 2 end

    local _cache_data = cache_data:get()
    if (not _cache_data.valid) then return nil, _t_return end

    if (table_size(_cache_data.entries) > 4 or table_size(_cache_data.indices) > 4) then
        Constants.table.traverse_print(data, "cache_data-get_by_key-data_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
        error("too many entries")
    end

    _t_return.return_code = 0

    -- Getting the last object in the list, i.e. the most recently added object
    local entry = _cache_data.entries_list.last
    if (not entry and (_cache_data.entries_list.count > 0 or table_size(_cache_data.entries) > 0 or table_size(_cache_data.indices) > 0)) then
        log(serpent.block(_cache_data.entries_list))

        Constants.table.traverse_print(data, "cache_data-get_by_key-data_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)

        error("entries_list has no last")
    end

    local return_data = nil

    local depth = 0
    local num_removed_cache = 0
    local num_removed_entry = 0

    while entry do
        depth = depth + 1

        -- TODO: Make this configurable
        -- local rand_val = 32 + math.random(32)
        local rand = math.random(1,5)
        local selected_difficulty = Constants.difficulty[Constants.difficulty.difficulties[Constants.difficulty.difficulties_array[rand]]]

        -- rand = (math.random(2 ^ 6) + math.random(2 ^ 6)) / 2 --[[TODO: Make this configurable]]
        -- rand = (math.random(2 ^ 7) + math.random(2 ^ 7)) / 2 --[[TODO: Make this configurable]]
        rand = (math.random(2 ^ 10) + math.random(2 ^ 10)) / 2 --[[TODO: Make this configurable]]
        -- if (entry.created + (2 ^ 6) * selected_difficulty.value --[[TODO: Make this configurable]] + rand <= game.tick) then
        if (entry.created + (2 ^ 8) * selected_difficulty.value --[[TODO: Make this configurable]] + rand <= game.tick) then
            num_removed_entry = num_removed_entry + 1

            -- log("found old entry; removing")

            while   next(_cache_data.entries)
                and next(_cache_data.entries) <= entry.created
                and next(_cache_data.indices)
                and next(_cache_data.indices) <= entry.created
            do
                -- log("removing old entry")
                local index = next(_cache_data.entries)
                if (index == nil) then break end
                local removed = _cache_data.remove(_cache_data.entries_list, { data = _cache_data.entries[index] })
                _cache_data.entries[removed and removed.created or index] = nil
                _cache_data.indices[removed and removed.created or index] = nil
            end

            if (table_size(_cache_data.entries) ~= _cache_data.entries_list.count or table_size(_cache_data.indices) ~= _cache_data.entries_list.count) then
                Constants.table.traverse_print(data, "cache_data-get_by_key-data_" .. game.tick)
                Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
                Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
                Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
                Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
                error("counts don't match")
            end
            if (table_size(_cache_data.entries) > 4 or table_size(_cache_data.indices) > 4) then
                Constants.table.traverse_print(data, "cache_data-get_by_key-data_" .. game.tick)
                Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
                Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
                Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
                Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
                error("too many entries")
            end
        else
            if (entry.cache.t and entry.cache.t[data.key]) then
                if (entry.cache.t[data.key].tick_valid_until and entry.cache.t[data.key].tick_valid_until > game.tick) then
                    return_data = entry.cache.t[data.key]
                    return_data.tick_valid_until = return_data.created + (return_data.tick_valid_until_original - return_data.created) / data.tick_valid_until_modifier
                    _t_return.return_code = 1
                    break
                else
                    -- Found the key/value, but it is too old
                    -- local index = entry.list.data_table.t[entry.cache.t[data.key]]

                    num_removed_cache = num_removed_cache + 1

                    local to_remove = {}
                    local i = 1
                    for k, v in pairs(entry.cache.t) do
                        if (v.tick_valid_until <= game.tick) then
                            local removed = cache_data.remove(entry.list, { data = v })
                            if (type(removed) == "table") then
                                to_remove[k] = k
                            end
                        else
                            v.index = i
                            i = i + 1
                        end
                    end

                    for k, _ in pairs(to_remove) do entry.cache.t[k] = nil end

                    if (entry.cache and entry.cache.t ~= nil and type(entry.cache.t) == "table") then
                        local i = 1
                        for k, v in pairs(entry.cache.t) do
                            if (type(v) == "table") then
                                v.index = i
                                i = i + 1
                            end
                        end
                        entry.list.first = entry.list.data_array[1]
                        entry.list.last = entry.list.data_array[i - 1]
                        entry.list.count = i - 1
                    end

                    if (entry.cache and (entry.list.count ~= table_size(entry.cache.t) or entry.list.count ~= #entry.list.data_array or entry.list.count ~= table_size(entry.list.data_table.t))) then
                        Constants.table.traverse_print(data, "cache_data-remove_" .. game.tick)
                        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
                        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
                        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
                        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
                        error("counts don't match")
                    end
                end
            end
        end

        if (entry) then entry = entry.prev end
    end

    -- Key wasn't found in cache, or was no longer valid in existing cache
    -- -> Either way, recalculate the data and store it in cache
    if ((entry == nil or type(entry) ~= "table") and data.fallback) then
        -- log("fallback called - " .. game.tick)
        local new_data = data.fallback()

        -- log(serpent.block(new_data))

        -- log(depth)
        -- log(_cache_data.entries_list.count)
        -- log(num_removed_cache)
        -- log(num_removed_entry)
        -- log(serpent.block(_cache_data.entries))
        -- Constants.table.traverse_print(_cache_data.entries, "cache_data.entries-fallback_" .. game.tick)

        -- log(serpent.block(_cache_data.indices))
        if (new_data == nil or type(new_data) ~= "table") then return nil, _t_return end
        new_data = _cache_data:add({ key = new_data.key, value = new_data.value, tick_valid_until = new_data.tick_valid_until, })
        if (new_data == nil or type(new_data) ~= "table") then return nil, _t_return end
        return_data = new_data
    end

    -- self:update()

    -- Returns the stored value, when it was created/stored, and the tick at which it is no longer valid
    if (return_data ~= nil and type(return_data) == "table") then
        return return_data.value, return_data.created or -1, return_data.tick_valid_until or -1, _t_return
    else
        return nil, -1, -1, _t_return
    end
end

function cache_data:remove(data)
    Log.debug("cache_data:remove")
    Log.info(data)

    local _cache_data = storage.cache_data

    if (self.cache and (self.count ~= table_size(self.cache.t) or self.count ~= #self.data_array or self.count ~= table_size(self.data_table.t))) then
        Constants.table.traverse_print(data, "cache_data-remove_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
        error("counts don't match")
    end

    if (self == nil or type(self) ~= "table") then return -1 end
    if (data == nil or type(data) ~= "table") then return -1 end
    if (data.data == nil or type(data.data) ~= "table") then return -1 end
    if (data.data.created == nil or type(data.data.created) ~= "number" or data.data.created < 0) then return -1 end
    if (not data.mode or data.mode and type(data.mode) ~= "string") then data.mode = "single" end

    local _data = data.data
    local _cache_data = storage.cache_data

    local data_to_remove = nil
    if (((      self.name and type(self.name) == "string" and self.name:find("entries_list", 1, true))
            and
                _cache_data.entries[_data.created]
        )
        or
        ((      self.data_table.t[_data] ~= nil)
            and (
                    self.data_table.t[_data] and self.data_array[self.data_table.t[_data]] ~= nil
                or
                    self.data_table.t[_data] and self.data_array[self.data_table.t[_data]] ~= nil
            )
        ))
    then

        data_to_remove =    self.data_table.t[_data] and  self.data_array[self.data_table.t[_data]]
                        or  _cache_data.indices[_data.created] and _cache_data.entries[_data.created]

        local index =       self.data_table.t[_data] and self.data_table.t[_data]
                        or _cache_data.indices[_data.created] and _cache_data.entries[_data.created].index

        local prev = data_to_remove.prev
        local _next = data_to_remove.next

        if (prev ~= nil and type(prev) == "table") then prev.next = _next end
        if (_next ~= nil and type(_next) == "table") then _next.prev = prev end

        if (data_to_remove == self.first and data_to_remove == self.last) then
            self.first.prev = nil
            self.last.next = nil

            self.first = nil
            self.last = nil

            self.data_array = {}
            self.data_table.t = {}

            self.count = 0
        end
        if (data_to_remove == self.first and type(self.first) == "table") then
            if (self.first.next) then self.first = self.first.next end
        elseif (data_to_remove == self.last and type(self.last) == "table") then
            if (self.last.prev) then self.last = self.last.prev end
        end

        if (self.data_array[index] and self.data_table.t[data_to_remove]) then
            self.data_table.t[data_to_remove] = nil
            table.remove(self.data_array, index)

            if (self.count >= 1) then self.count = self.count - 1 end
        end

        if (self.name:find("entries_list", 1, true)) then
            _cache_data.entries[data_to_remove.created] = nil
            _cache_data.indices[data_to_remove.created] = nil
        end

        local i = 1

        self.data_table.t = {}
        while i <= #self.data_array do
            if (i < 1) then break end
            self.data_array[i].index = i
            self.data_table.t[self.data_array[i]] = i
            i = i + 1
        end
    end

    if (self.cache and (self.count ~= table_size(self.cache.t) or self.count ~= #self.data_array or self.count ~= table_size(self.data_table.t))) then
        Constants.table.traverse_print(data, "cache_data-remove_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
        error("counts don't match")
    end

    -- Data.update(self)

    return data_to_remove
end

function cache_data:enlist(data)
    Log.debug("cache_data:enlist")
    Log.info(data)

    local _cache_data = storage.cache_data

    if (self.cache and (self.count ~= table_size(self.cache.t) or self.count ~= #self.data_array or self.count ~= table_size(self.data_table.t))) then
        Constants.table.traverse_print(data, "cache_data-remove_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
        error("counts don't match")
    end

    if (self.limit and self.count >= 1 + self.limit * 1.5 --[[TODO: Make this configurable]]) then return { valid = false } end

    if (type(data) ~= "table") then return -1 end
    -- if (game.tick % 16 == 0) then if (data.source) then if (self.count > 0) then log(data.source) end end end
    if (game.tick % 1 == 0) then if (data.source and not data.source:find("cache", 1, true)) then if (self.count > 0) then log(data.source) end end end
    if (data.source) then Log.debug(data.source) end
    if (data.data == nil or type(data.data) == "function") then return -1 end

    local _data = data.data

    if (self.first == nil or self.last == nil or self.count == 0) then
        self.first = _data
        self.last = _data
        self.data_array = {}
        self.data_table = Data:new({ type = "list_data_table", name = "list_data_table_" .. game.tick, t = {},})
        self.count = 1
    else
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
            self.last = _data
            self.first.next = _data
            data.prev = self.first

            self.last.next = nil
            self.first.prev = nil
        end
        self.count = self.count + 1
    end

    local index = nil

    if (self.name and self.name:find("entries_list", 1, true)) then
        _data.index = _data.index
        index = _data.index
    elseif (self.type and self.type:find("cache_object", 1, true)) then
        _data.index = self.count
        index = self.count
    end
    table.insert(self.data_array, _data)

    index = index or self.count

    if (self.data_table.t[_data]) then
        if (self.count > 1) then
            if (self.data_table.t[_data] and self.data_array[self.data_table.t[_data]]) then
                table.remove(self.data_array, self.data_array[self.data_table.t[_data]])
            else
                log("couldn't find _ to remove")
            end
        end

        local found = nil
        local i = 1
        for k, v in pairs(self.data_table.t) do
            if (not found and k == _data) then found = k end
            if (found) then self.data_table.t[k] = i end
            i = i + 1
        end
    end

    self.data_table.t[_data] = index

    if (self.cache and (self.count ~= table_size(self.cache.t) or self.count ~= #self.data_array or self.count ~= table_size(self.data_table.t))) then
        Constants.table.traverse_print(data, "cache_data-remove_" .. game.tick)
        Constants.table.traverse_print(_cache_data, "cache_data_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries_list, "cache_data.entries_list_" .. game.tick)
        Constants.table.traverse_print(_cache_data.entries, "cache_data.entries_" .. game.tick)
        Constants.table.traverse_print(_cache_data.indices, "cache_data.indices_" .. game.tick)
        error("counts don't match")
    end

    -- Data.update(self)

    return _data, 1
end

function cache_data:is_valid()
    Log.debug("cache_data:is_valid")
    return  self.created ~= nil
        and type(self.created) == "number"
        and self.created >= 0
        -- and self.created > 0
        and self.updated ~= nil
        and type(self.updated) == "number"
        and self.updated >= self.created
        -- and self.tick_invalid ~= nil
        -- and type(self.tick_invalid) == "number"
        -- and game and game.tick and game.tick < self.tick_invalid
end

setmetatable(cache_data, Data)
cache_data.__index = cache_data
return cache_data
-- Cache_Data = cache_data:new(Cache_Data)

-- return Cache_Data