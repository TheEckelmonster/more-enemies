local array_util = {}

local function swap_remove_chunk(chunk, chunks)
    if (chunk.i) then
        -- fast path as chunk has stored its index
        local count = #chunks
        local temp = chunks[count]

        chunks[chunk.i] = temp
        chunks[count] = nil

        if (temp) then temp.i = chunk.i end
    else
        -- slow path, scan through all chunks and re assert indexes
        local count = #chunks
        for i = 1, count, 1 do
            local entry = chunks[i]
            if (entry) then
                entry.i = i
            else
                Log.warn("chunks array has nil slot")
            end
        end

        if (chunk and chunk.i) then
            local temp = chunks[count]

            chunks[chunk.i] = temp
            chunks[count] = nil

            if (temp) then temp.i = chunk.i end
        end
    end
end

array_util.swap_remove_chunk = swap_remove_chunk

return array_util;
