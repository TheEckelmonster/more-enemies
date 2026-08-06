local array_utils = {}
array_utils.name = "array_utils"

function array_utils.swap_remove_chunk(chunk, chunks)
    if (chunk.i) then
        local count = #chunks
        local temp = chunks[count]

        chunks[chunk.i] = temp
        chunks[count] = nil

        if (temp) then temp.i = chunk.i end
        chunk.i = nil
    else
        local count = #chunks
        local limit, loops = count * 2, 0
        local idx, i = 0, 0
        while idx < count do
            loops, i = loops + 1, i + 1
            if (loops > limit) then break end
            local entry = chunks[i]
            if (entry) then
                idx = idx + 1
                entry.i = idx
                if (idx ~= i) then
                    chunks[idx] = entry
                    chunks[i] = nil
                end
            else
                chunks[i] = chunks[count]
                chunks[count] = nil
                count, i = count - 1, i - 1
            end
        end

        if (chunk and chunk.i) then
            count = #chunks
            local temp = chunks[count]

            chunks[chunk.i] = temp
            chunks[count] = nil

            if (temp) then temp.i = chunk.i end
            chunk.i = nil
        end
    end
end

return array_utils