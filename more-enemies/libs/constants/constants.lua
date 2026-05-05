-- If already defined, return
if _constants and _constants.more_enemies then
  return _constants
end

local Log = require("libs.log.log")
local Easy_Difficulty_Data = require("scripts.data.difficulties.easy-difficulty-data")
local Hard_Difficulty_Data = require("scripts.data.difficulties.hard-difficulty-data")
local Insanity_Difficulty_Data = require("scripts.data.difficulties.insanity-difficulty-data")
local Vanilla_Plus_Difficulty_Data = require("scripts.data.difficulties.vanilla-plus-difficulty-data")
local Vanilla_Difficulty_Data = require("scripts.data.difficulties.vanilla-difficulty-data")

local constants = {}

constants.difficulty = {}

constants.difficulty.EASY = Easy_Difficulty_Data:new()
constants.difficulty.EASY.order = 1
constants.difficulty.EASY.valid = true

constants.difficulty.VANILLA = Vanilla_Difficulty_Data:new()
constants.difficulty.VANILLA.order = constants.difficulty.EASY.order + 1
constants.difficulty.VANILLA.valid = true

constants.difficulty.VANILLA_PLUS = Vanilla_Plus_Difficulty_Data:new()
constants.difficulty.VANILLA_PLUS.order = constants.difficulty.VANILLA.order + 1
constants.difficulty.VANILLA_PLUS.valid = true

constants.difficulty.HARD = Hard_Difficulty_Data:new()
constants.difficulty.HARD.order = constants.difficulty.VANILLA_PLUS.order + 1
constants.difficulty.HARD.valid = true

constants.difficulty.INSANITY = Insanity_Difficulty_Data:new()
constants.difficulty.INSANITY.order = constants.difficulty.HARD.order + 1
constants.difficulty.INSANITY.valid = true

local difficulties = {}
local difficulties_array = {}

for k,v in pairs(constants.difficulty) do
  if (v and v.string_val) then difficulties[v.string_val] = k end
  if (v and v.string_val) then difficulties_array[v.order] = v.string_val end
end

constants.difficulty.difficulties = difficulties
constants.difficulty.difficulties_array = difficulties_array

constants.DEFAULTS = {}

-- Settings taken from vanilla
--   -> See base/prototypes/map-settings.lua
constants.DEFAULTS.unit_group = {
  max_group_radius = 30.0,
  min_group_radius = 5.0,

  -- Maximum size of an attack unit group. This only affects automatically-created unit groups;
  -- manual groups created through the API are unaffected.
  max_unit_group_size = 200
}

constants.settings = {}

constants.DEFAULTS.planets = {
    nauvis = {
        string_val = "nauvis"
    },
    gleba = {
        string_val = "gleba"
    },
}

constants.CHUNK_SIZE = 32
-- constants.CHUNK_LEVELS = 6
constants.CHUNK_LEVELS = 59

constants.chunk_sizes = {}
constants.chunk_sizes_map = {}
-- for i = 1, constants.CHUNK_LEVELS - 1 do
for i = 0, constants.CHUNK_LEVELS - 1 do
    -- constants["CHUNK_SIZE_" .. 2 ^ i] = constants.CHUNK_SIZE * (2 ^ i)
    constants.chunk_sizes[i + 1] = constants.CHUNK_SIZE * (2 ^ i)
    constants.chunk_sizes_map[constants.CHUNK_SIZE * (2 ^ i)] = i + 1
end

-- constants.CHUNK_SIZE_2 = constants.CHUNK_SIZE * 2
-- constants.CHUNK_SIZE_4 = constants.CHUNK_SIZE_2 * 2
-- constants.CHUNK_SIZE_8 = constants.CHUNK_SIZE_4 * 2
-- constants.CHUNK_SIZE_16 = constants.CHUNK_SIZE_8 * 2
-- constants.CHUNK_SIZE_32 = constants.CHUNK_SIZE_16 * 2

-- constants.BIG_INTEGER = (2 ^ 32) - 1
constants.BIG_INTEGER = (2 ^ constants.CHUNK_SIZE) - 1
constants.BIG_NUM = constants.BIG_INTEGER
constants.INT_MAX = (2 ^ (constants.CHUNK_SIZE * 2)) - 1
-- constants.SMALL_NUM = 0.000001
constants.SMALL_NUM = 2 ^ - (constants.CHUNK_SIZE - 1)

-- 2.71828182845904523536028747135266249775724709369995957496696762772407663035
-- constants.e = 2.71828182
constants.e = math.exp(1)

constants.time = {}
constants.time.TICKS_PER_SECOND = 60
constants.time.SECONDS_PER_MINUTE = 60
constants.time.TICKS_PER_MINUTE = constants.time.TICKS_PER_SECOND * constants.time.SECONDS_PER_MINUTE

constants.time.TICKS = {}
for i=0, 16 do table.insert(constants.time.TICKS, 2 ^ i) end


local depth = function ()
    local self = { depth = 0 }
    local get = function () return self.depth end
    local increment = function () self.depth = self.depth + 1 end
    local decrement = function () self.depth = self.depth - 1 end
    local reset = function () self.depth = 0 end

    return {
        get = get,
        increment = increment,
        decrement = decrement,
        reset = reset,
    }
end
-- depth = depth()

constants.table = {
    calls = 0,
    file = {
        prefix = "more-enemies/",
        postfix = ".json",
    },
    depth = depth(),
    SPACING = "    ",
    -- traverse  = function (data, found_data)
    --     if (constants.table.depth.get() == 0) then
    --         constants.table.calls = 0
    --     end
    --     if (constants.table.calls > 2 ^ 16) then return end
    --     constants.table.calls = constants.table.calls + 1
    --     -- log("calls = " .. constants.table.calls)
    --     constants.table.depth.increment()
    --     if (data == nil or type(data) ~= "table") then return nil end
    --     if (found_data == nil or type(found_data) ~= "table") then found_data = {} end

    --     local t = nil
    --     -- if (not found_data[data] or found_data[data] < depth.get()) then
    --     if (not found_data[data] or found_data[data] and found_data[data].depth > depth.get()) then
    --         if (not found_data[data]) then found_data[data] = {} end
    --         found_data[data].depth = depth.get()
    --         t = {}

    --         for k, v in pairs(data) do
    --             if (type(v) ~= "table") then
    --                 t["" .. k .. ""] = { data = v, depth = depth.get() }
    --             else
    --                 t["" .. k .. ""] = constants.table.traverse(v, found_data)
    --             end
    --         end
    --     else
    --         -- log("found existing table at depth " .. depth.get())

    --         t = {}

    --         for k, v in pairs(data) do
    --             if (type(v) ~= "table") then
    --                 t["" .. k .. ""] = { data = v, depth = depth.get() }
    --             else
    --                 t["" .. k .. ""] = "more-enemies_placeholder"
    --             end
    --         end
    --     end

    --     constants.table.depth.decrement()
    --     return t
    -- end,
    traverse_find  = function (t_name, data, found_data, path, optionals)
        Log.debug("constants.table.traverse_find")
        Log.info(t_name)
        Log.info(data)
        Log.info(found_data)
        Log.info(path)
        Log.info(optionals)

        if (t_name == nil or type(t_name) ~= "string" or #(string.gsub(t_name, " ", "")) <= 0) then return end
        if (data == nil or type(data) ~= "table") then data = storage end
        if (found_data == nil or type(found_data) ~= "table") then found_data = {} end
        if (path == nil or type(path) ~= "string") then path = "storage" end

        constants.table.calls = 0
        local depth = depth()

        -- log(type(optionals.max_depth))
        -- log(tostring(optionals.max_depth))

        local do_traverse; do_traverse = function (t_name, data, found_data, path, optionals)
            if (constants.table.calls > 2 ^ 16) then return end

            -- if (type(optionals.max_depth) == "number" and depth.get() > optionals.max_depth) then return else log("depth = " .. depth.get()) end

            constants.table.calls = constants.table.calls + 1
            -- log("calls = " .. constants.table.calls)
            depth.increment()


            local t_return = { data = nil, name = path, return_val = 0, depth = 2 ^ 8 - 1 }

            local should_return; should_return = function (_t_return, optionals)
                -- if (type(optionals.max_depth) == "number" and depth.get() > optionals.max_depth) then return else log("depth = " .. depth.get()) end

                if (type(_t_return) == "table") then
                    if (_t_return.do_return) then
                        -- log("1")
                        depth.reset()
                        return _t_return
                    elseif (_t_return.return_val and t_return.return_val and _t_return.return_val > t_return.return_val) then
                        -- log("2")
                        -- log(serpent.block(_t_return))
                        t_return = _t_return
                        -- log(serpent.block(_t_return))
                        return false
                    elseif (not t_return.return_val) then
                        t_return = _t_return
                        return false
                    end
                end
                return false
            end

            -- if (not found_data[data]) then
            if (not found_data[data] or found_data[data] and found_data[data].depth > depth.get()) then
                if (not found_data[data]) then found_data[data] = {} end
                found_data[data].depth = depth.get()

                for k, v in pairs(data) do
                    if (type(v) == "table") then
                        if (optionals.parsed_name) then
                            -- if (path .. "." .. tostring(k) == t_name or (path .. "." .. tostring(k)):find(t_name, 1, true)) then
                            if (path .. "." .. tostring(k)):find(t_name, 1, true) then
                                depth.reset()
                                -- log("1.1")
                                return { data = v, name = path .. "." .. tostring(k), do_return = true }
                            end
                            -- if (   optionals.parsed_name.reversed.t[tostring(k)]
                            -- log(serpent.block(k))
                            if (  (optionals.parsed_name.step.t[tostring(k)] and depth.get() == optionals.parsed_name.step.a[optionals.parsed_name.step.t[tostring(k)]])
                                or optionals.parsed_name.t[path .. "." .. tostring(k)]
                                or optionals.parsed_name.reversed.t[path .. "." .. tostring(k)]) then

                                -- log(tostring(k))
                                -- log("2.1")

                                -- local _t_return = constants.table.traverse_find(t_name, v, found_data, path .. "." .. tostring(k), optionals)
                                local _t_return = do_traverse(t_name, v, found_data, path .. "." .. tostring(k), optionals)
                                if (should_return(_t_return, optionals)) then return should_return(_t_return, optionals) end

                                -- log(serpent.block(k))
                                -- log(serpent.block(optionals.parsed_name.reversed.t))
                                -- log(serpent.block(optionals.parsed_name.reversed.t[k]))
                                return { data = v, name = path .. "." .. tostring(k), return_val = optionals.parsed_name.reversed.t[k], depth = depth.get() }
                            end
                        end
                        if (tostring(k) == t_name or path .. "." .. tostring(k) == t_name) then depth.reset(); return { data = v, name = path .. "." .. tostring(k) , do_return = true, depth = depth.get() } end
                        -- local _t_return = constants.table.traverse_find(t_name, v, found_data, path .. "." .. tostring(k), optionals)
                        local _t_return = do_traverse(t_name, v, found_data, path .. "." .. tostring(k), optionals)
                        if (should_return(_t_return, optionals)) then return should_return(_t_return, optionals) end
                    end
                end
            end

            depth.decrement()
            return t_return
        end
        return do_traverse(t_name, data, found_data, path, optionals)
    end,
    traverse_print  = function (data, file_name, found_data, optionals)
        Log.debug("constants.table.traverse_print")
        Log.info(data)
        Log.info(file_name)
        Log.info(found_data)
        Log.info(optionals)

        if (data == nil or type(data) ~= "table") then return -1 end
        if (file_name == nil or type(file_name) ~= "string") then return -1 end
        if (found_data == nil or type(found_data) ~= "table") then found_data = {} end

        optionals = type(optionals) == "table" and optionals or { max_depth = 4 }

        constants.table.calls = 0
        local depth = depth()
        -- depth.reset()
        if (not file_name:find(constants.table.file.prefix, 1)) then file_name = constants.table.file.prefix .. file_name end
        if (not file_name:find(constants.table.file.postfix, -5)) then file_name = file_name .. constants.table.file.postfix end

        -- log(type(optionals.max_depth))
        -- log(tostring(optionals.max_depth))

        local do_traverse; do_traverse = function(data, file_name, found_data, optionals)

            if (type(optionals.max_depth) == "number" and depth.get() > optionals.max_depth) then return --[[else log("depth = " .. depth.get())]] end

            if (depth.get() == 0) then
                -- constants.table.calls = 0
                helpers.write_file(file_name, "{")
            end
            if (constants.table.calls > 2 ^ 16) then return end
            constants.table.calls = constants.table.calls + 1
            -- log("calls = " .. constants.table.calls)
            depth.increment()
            if (data == nil or type(data) ~= "table") then return nil end
            if (found_data == nil or type(found_data) ~= "table") then found_data = {} end

            local t = nil

            if (not found_data[data] or found_data[data] and found_data[data].depth > depth.get()) then
                if (not found_data[data]) then found_data[data] = {} end
                found_data[data].depth = depth.get()
                t = {}

                for k, v in pairs(data) do
                    if (type(v) ~= "table") then
                        if (next(data, k)) then
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "\"" .. tostring(k) .. "\": " .. serpent.block(v) .. ",", true)
                        else
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "\"" .. tostring(k) .. "\": " .. serpent.block(v), true)
                        end
                    else
                        local func; func = function (data, file_name, found_data, optionals)
                            if (type(optionals.max_depth) == "number" and depth.get() > optionals.max_depth) then return --[[else log("depth = " .. depth.get())]] end

                            if (constants.table.calls > 2 ^ 16) then return end
                            constants.table.calls = constants.table.calls + 1

                            -- local traversed_t = constants.table.traverse_print(data, file_name, found_data)
                            local traversed_t = do_traverse(data, file_name, found_data, optionals)

                            for i, j in pairs(traversed_t) do
                                if (type(j) ~= "table") then
                                    if (next(traversed_t, i)) then
                                        helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get() - 1) .. "\"" .. tostring(i) .. "\": " .. serpent.block(j) .. ",", true)
                                    else
                                        helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get() - 1) .. "\"" .. tostring(i) .. "\": " .. serpent.block(j), true)
                                    end
                                else
                                    helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "\"" .. tostring(i) .. "\" : {", true)
                                    depth.increment()
                                    func(j, file_name, found_data, optionals)
                                    depth.decrement()
                                    if (next(traversed_t, i)) then
                                        helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "},", true)
                                    else
                                        helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "}", true)
                                    end
                                end
                            end
                        end

                        helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "\"" .. tostring(k) .. "\": {", true)

                        func(v, file_name, found_data, optionals)

                        if (next(data, k)) then
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "},", true)
                        else
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "}", true)
                        end
                    end
                end
            else
                -- log("found existing table at depth " .. depth.get())

                t = {}

                depth.increment()
                for k, v in pairs(data) do
                    if (type(v) ~= "table") then
                        if (next(data, k)) then
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get() - 1) .. "\"" .. tostring(k) .. "\" : " .. serpent.block(v) .. ",", true)
                        else
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get() - 1) .. "\"" .. tostring(k) .. "\" : " .. serpent.block(v), true)
                        end
                    else
                        if (next(data, k)) then
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get() - 1) .. "\"" .. tostring(k) .. "\" : \"more-enemies_placeholder\",", true)
                        else
                            helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get() - 1) .. "\"" .. tostring(k) .. "\" : \"more-enemies_placeholder\"", true)
                        end
                    end
                end
                depth.decrement()
            end

            depth.decrement()
            if (depth.get() == 0) then helpers.write_file(file_name, "\n" .. string.rep(constants.table.SPACING, depth.get()) .. "}", true) end

            return t
        end
        return do_traverse(data, file_name, found_data, optionals)
    end,
}


constants.more_enemies = true

local _constants = constants

return constants