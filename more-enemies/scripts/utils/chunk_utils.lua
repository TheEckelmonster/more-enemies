

-- local Chunk_Data = require("scripts.data.chunk-data.chunk-data")
local Constants = require("libs.constants.constants")
-- local Overmind_Repository = require("scripts.repositories.overmind-repository")

local locals = {}

local chunk_utils = {}

function chunk_utils.find_chunk_with(data)
    Log.error("chunk_utils.find_chunk_with")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.with) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end

    local with = data.with
    local overmind = data.overmind

    -- local with_dictionary = {}
    -- for k, v in pairs(with) do
    -- -- for k, v in pairs(data.with) do
    --     if (type (v) == "string" and type(k) == "number") then
    --         with_dictionary[v] = k
    --     end
    -- end

    -- local chunk, _chunk, prev_chunk = nil, nil, nil
    -- local chunk = { x = -1, y = -1 }
    local chunk = nil
    local chunks, _chunk, prev_chunks = nil, nil, {}
    local num_loops = 0
    local lowest_chunk_level = math.huge
    local lowest_chunk = nil
    -- for k, _ in pairs(Constants.chunk_sizes) do
    -- local i, k = next(Constants.chunk_sizes)
    -- local i, _ = next(Constants.chunk_sizes)
    local i = Constants.CHUNK_LEVELS - 1
    log(i)
    while i ~= nil and i >= 1 and i < Constants.CHUNK_LEVELS do
        log(i)
        log(num_loops)
        if (num_loops > 4 * Constants.CHUNK_LEVELS * 4) then break end
        num_loops = num_loops + 1

        -- local overmind_chunks = data.overmind.chunks["chunks_" .. i]

        local found_chunks = {}
        if (chunk or num_loops == 1) then
            -- log(serpent.line(chunk))
            found_chunks = locals.filter_sub_chunk_data({
                chunk_level = i,
                overmind = overmind,
                with = with,
                chunk = chunk,
            })
        end

        if (found_chunks and found_chunks[1]) then
            log("found chunks")
            if (i == 1) then
                -- chunk = found_chunks[1]
                chunk = { x = found_chunks[1].x, y = found_chunks[1].y, parent = found_chunks[1], level = i, chunk_size = 2 ^ (4 + i) }
                break
            end
            prev_chunks[i] = found_chunks
            if (not lowest_chunk or lowest_chunk.chunk_size > found_chunks[1].chunk_size) then
                lowest_chunk = found_chunks[1]
            end
            log(#prev_chunks[i])
            i = i - 1
            chunk = { x = found_chunks[1].x * 2, y = found_chunks[1].y * 2, parent = found_chunks[1], level = i, chunk_size = 2 ^ (4 + i) }
        else
            log("found_chunks is nil or empty")
            if (found_chunks) then
                if (not prev_chunks[i] or #prev_chunks[i] == 0) then
                    i = i + 1
                end
                while prev_chunks[i] do
                    log(#prev_chunks[i])
                    local asdf = table.remove(prev_chunks[i], 1)
                    log(#prev_chunks[i])
                    log(tostring(asdf))
                    log(asdf.x .. " / " .. asdf.y .. ", " .. asdf.chunk_size)
                    if (prev_chunks[i][1]) then
                        chunk = { x = prev_chunks[i][1].x * 2, y = prev_chunks[i][1].y * 2, parent = prev_chunks[i][1], level = i, chunk_size = 2 ^ (4 + i) }
                        break
                    end
                    i = i + 1
                end
            end
        end

        -- if (i < Constants.CHUNK_LEVELS) then
        --     local chunk_level = Constants.CHUNK_LEVELS - i
        --     if (chunk_level < lowest_chunk_level) then lowest_chunk_level = chunk_level end

        --     _chunk = nil
        --     if (prev_chunks[chunk_level + 1] and prev_chunks[chunk_level + 1][1]) then
        --         -- local chunk = table.remove(chunks, 1)
        --         local chunk = table.remove(prev_chunks[chunk_level + 1], 1)
        --         _chunk = {
        --             x = chunk.x * 2,
        --             y = chunk.y * 2
        --         }
        --         log(serpent.line(_chunk))
        --     end

        --     local _chunks = nil
        --     if (i == 1 or _chunk) then
        --         _chunks = locals.filter_sub_chunk_data({
        --             chunk_level = chunk_level,
        --             overmind = overmind,
        --             with = with,
        --             chunk = _chunk,
        --         })
        --     end
        --     if (not _chunks or not _chunks[1]) then
        --         if (i == 1) then break end
        --         i = i - 1
        --         if (prev_chunks[chunk_level]) then log(#prev_chunks[chunk_level]); prev_chunks[chunk_level] = nil end
        --         log(#prev_chunks)
        --         log(#prev_chunks[chunk_level + 1])
        --         -- local asdf = table.remove(prev_chunks[chunk_level + 1], 1)
        --         -- log(tostring(asdf))
        --         -- if (asdf) then
        --         --     log(asdf.x .. " - " .. asdf.y)
        --         -- end
        --         -- chunks = prev_chunks[chunk_level + 1]
        --     else
        --         chunks = _chunks
        --         log("found chunk at chunk_level = " .. chunk_level)
        --         chunk = chunks[1]
        --         if (chunk_level == 1) then
        --             break
        --         end

        --         i, _ = next(Constants.chunk_sizes, i)

        --         -- if (not prev_chunks[chunk_level]) then
        --             log(chunk_level)
        --             log(chunks and #chunks)
        --             prev_chunks[chunk_level] = chunks
        --         -- end
        --     end
        -- end
    end

    -- for k, v in pairs(prev_chunks) do
    --     log(serpent.block(k))
    --     if (next(v)) then
    --         for i, j in pairs(v) do
    --             log(serpent.block(i))
    --             log("chunk_size = " .. j.chunk_size)
    --             log("pollution = " .. j.pollution_data.pollution)
    --             log("entity_count = " .. j.entity_count)
    --             log(j.x .. " - " .. j.y)
    --         end
    --     end
    -- end

    -- return locals.filter_sub_chunk_data({
    --     chunk_level = Constants.CHUNK_LEVELS - 1,
    --     overmind = overmind,
    --     with = with
    -- })
    -- return chunk or prev_chunk

    -- if (chunk) then
    --     log(serpent.line(chunk.level))
    --     local overmind_chunks = data.overmind.chunks["chunks_" .. chunk.level]
    --     log(tostring(overmind_chunks))
    --     log(tostring(overmind_chunks and overmind_chunks[chunk.x]))
    --     log(tostring(overmind_chunks and overmind_chunks[chunk.x] and overmind_chunks[chunk.x][chunk.y]))
    --     local overmind_chunk = overmind_chunks and overmind_chunks[chunk.x] and overmind_chunks[chunk.x][chunk.y]
    --     if (overmind_chunk) then return overmind_chunk end
    -- end

    if (chunk) then
        local parent = chunk.parent
        chunk.parent = nil
        log(serpent.block(chunk))
        log(parent.x .. " / " .. parent.y .. ", chunk_size = " .. parent.chunk_size)
        chunk.parent = parent
    end

    return chunk
end

function locals.filter_sub_chunk_data(data)
    Log.error("locals.filter_sub_chunk_data")
    Log.info(data)

    if (type(data) ~= "table") then return end
    if (type(data.chunk_level) ~= "number" or data.chunk_level < 1 or data.chunk_level > Constants.CHUNK_LEVELS - 1) then return end
    log(data.chunk_level)
    if (type(data.with) ~= "table") then return end
    if (type(data.overmind) ~= "table") then return end
    if (type(data.chunk) ~= "table") then data.chunk = { x = -1, y = -1, } end
    -- if (type(data.num_calls) ~= "number") then data.num_calls = 1 end
    -- if (data.num_calls < 1 or data.num_calls > Constants.CHUNK_LEVELS) then return end

    -- local chunks = {}
    -- local filtered_chunk = data.num_calls > 1 and data.chunk or nil
    -- local filtered_chunk = nil
    local filtered_chunks = {}

    local function filter(data)
        local highest = data.highest or false

        -- local chunk = data.overmind.chunks["chunks_" .. data.chunk_level][i][j]
        local chunk = data.chunk
        log("x = " .. chunk.x .. ", y = " .. chunk.y)
        log("chunk_size = " .. chunk.chunk_size)
        local meets_criteria = true
        local partial = false
        -- local _filtered_chunk = filtered_chunk
        for k, v in pairs(data.with) do
            if (v == "pollution") then
                if (type(chunk.pollution_data) ~= "table" or chunk.pollution_data.pollution <= 0) then
                    meets_criteria = false
                    log("no pollution")
                elseif (highest) then
                    if (not filtered_chunk or filtered_chunk.pollution_data.pollution < chunk.pollution_data.pollution) then
                        log("found higher pollution - x = " .. chunk.x .. ", y = " .. chunk.y)
                        -- filtered_chunk = chunk
                    elseif (k == 1) then
                        meets_criteria = false
                        partial = true
                        log("less pollution")
                    end
                end
            end
            if (v == "entities") then
                if (not next(chunk.entities) or chunk.entity_count <= 0) then
                    meets_criteria = false
                    log("no entities")
                elseif (highest) then
                    if (not filtered_chunk or filtered_chunk.entity_count < chunk.entity_count) then
                        log("found more entities - x = " .. chunk.x .. ", y = " .. chunk.y)
                        -- filtered_chunk = chunk
                    elseif (k == 1) then
                        meets_criteria = false
                        partial = true
                        log("fewer entities")
                    end
                end
            end
        end

        if (meets_criteria) then
            -- table.insert(chunks, data.overmind.chunks["chunks_" .. data.chunk_level][i][j])
            -- table.insert(data.chunks, chunk)
            log("chunk meets criteria - x = " .. chunk.x .. ", y = " .. chunk.y)
            -- filtered_chunk = chunk
            if (chunk.witnessed) then
                table.insert(filtered_chunks, 1, chunk)
            end
        elseif (partial) then
            if (chunk.witnessed) then
                table.insert(filtered_chunks, chunk)
            end
        end

        -- if (highest) then
        --     return filtered_chunk
        -- else
        --     return meets_criteria and chunk or nil
        -- end
    end

    if (data.overmind.chunks["chunks_" .. data.chunk_level]) then
        -- if (data.chunk_level == Constants.CHUNK_LEVELS - 1) then
        --     for i = -1, 0, 1 do
        --         if (data.overmind.chunks["chunks_" .. data.chunk_level][i]) then
        --             for j = -1, 0, 1 do
        --                 if (data.overmind.chunks["chunks_" .. data.chunk_level][i][j]) then
        --                     filter({
        --                         highest = true,
        --                         chunk = data.overmind.chunks["chunks_" .. data.chunk_level][i][j],
        --                         chunks = chunks,
        --                         with = data.with,
        --                     })
        --                 end
        --             end
        --         end
        --     end
        -- else
            local overmind_chunks = data.overmind.chunks["chunks_" .. data.chunk_level]
            local chunk = data.chunk
            if (type(chunk) == "table" and chunk.x and chunk.y) then
                for i = 0, 1, 1 do
                    -- if (overmind_chunks[chunk.x * 2 + i]) then
                    --     log("filtering: x = " .. chunk.x * 2 + i)
                    --     for j = 0, 1, 1 do
                    --         if (overmind_chunks[chunk.x * 2 + i][chunk.y * 2 + j]) then
                    --             log("filtering: x = " .. chunk.x * 2 + i .. ", y = " .. chunk.y * 2 + j)
                    --             filter({
                    --                 highest = true,
                    --                 chunk = overmind_chunks[chunk.x * 2 + i][chunk.y * 2 + j],
                    --                 -- chunks = chunks,
                    --                 with = data.with,
                    --             })
                    --         end
                    --     end
                    -- end
                    if (overmind_chunks[chunk.x + i]) then
                        log("filtering: x = " .. chunk.x + i)
                        for j = 0, 1, 1 do
                            if (overmind_chunks[chunk.x + i][chunk.y + j]) then
                                log("filtering: x = " .. chunk.x + i .. ", y = " .. chunk.y + j)
                                filter({
                                    highest = true,
                                    chunk = overmind_chunks[chunk.x + i][chunk.y + j],
                                    -- chunks = chunks,
                                    with = data.with,
                                })
                            end
                        end
                    end
                end
            end
        -- end
    end

    -- log(serpent.block(type(filtered_chunk)))
    -- if (filtered_chunk) then
    --     log("x = " .. filtered_chunk.x .. ", y = " .. filtered_chunk.y)
    -- end

    -- if (data.chunk_level > 1 and type(filtered_chunk) == "table" and filtered_chunk.x and filtered_chunk.y) then
    --     data.chunk_level = data.chunk_level - 1
    --     data.num_calls = data.num_calls + 1
    --     data.chunk = filtered_chunk
    --     return locals.filter_sub_chunk_data(data)
    -- end

    -- if (not filtered_chunk and data.chunk_level < 58) then
    --     filtered_chunk = data.chunk
    -- end

    -- return filtered_chunk
    log(#filtered_chunks)
    return filtered_chunks
end

return chunk_utils