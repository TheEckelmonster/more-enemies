local storage
local stats_data
local quadtrees
local surfaces
local unit_groups

local game

local Quadtree = require("scripts.data.quadtree-data")
local new_Quadtree = Quadtree.new

local Stats_Data = require("scripts.data.stats-data")
local new_Stats_Data = Stats_Data.new

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage

    storage.stats_data = new_Stats_Data(Stats_Data, storage.stats_data) or new_Stats_Data(Stats_Data, { tick = (__game or _ENV.game).tick, })
    stats_data = storage.stats_data

    storage.quadtrees = storage.quadtrees or {}
    quadtrees = storage.quadtrees

    storage.surfaces = storage.surfaces or {}
    surfaces = storage.surfaces

    storage.unit_groups = storage.unit_groups or {}
    unit_groups = storage.unit_groups

    game = __game or _ENV.game

    return game
end

local math_floor = math.floor
local math_huge = math.huge
local math_max = math.max
local math_min = math.min
local math_random =  math.random
local math_sqrt = math.sqrt

local Log = Log

local Constants = Constants or require("scripts.constants.constants")

local Quadnode = require("scripts.data.quadnode")
local new_Quadnode = Quadnode.new

local max_unit_groups = Data_Utils.get_runtime_global_setting({ setting = Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name, })

local HALF_MAP_SIZE = Constants.HALF_MAP_SIZE
local CHUNK_LEVELS = Constants.CHUNK_LEVELS

local quadtree_service = {}
quadtree_service.name = "quadtree_service"
quadtree_service.set_game = set_game

local CHUNK_SIZE = Constants.CHUNK_SIZE
local BASE_SEARCH_RADIUS = 1024 * CHUNK_SIZE

function quadtree_service.add_node(params)
    if (not params) then return end

    params.depth = params.depth or 0
    if (params.depth > CHUNK_LEVELS) then return end

    if (not params.surface_name) then return end
    if (not params.source_chunk) then return end

    quadtrees = quadtrees or set_game() and quadtrees

    quadtrees[params.surface_name] = quadtrees[params.surface_name] or new_Quadtree(Quadtree, { surface_name = params.surface_name, })
    local quadtree = quadtrees[params.surface_name]

    local source_chunk = params.source_chunk

    quadtree.base = quadtree.base or new_Quadnode(Quadnode, { count = 0, })
    local base = params.base or quadtree.base
    local parent_node = params.parent_node or base
    if (parent_node.size and parent_node.size < 1) then return end

    local start_position = params.start_position or { x = 0, y = 0, }
    local direction = ""

    if ((source_chunk.x + 0.5) < start_position.x) then
        direction = ((source_chunk.y + 0.5) < start_position.y) and "nw" or "sw"
    else
        direction = ((source_chunk.y + 0.5) < start_position.y) and "ne" or "se"
    end

    if (parent_node[direction] and parent_node.size > 1) then
        local next_base = parent_node
        local target_node = parent_node[direction]

        local shift_factor = 2 ^ (CHUNK_LEVELS - target_node.node_level)
        local pos = {
            x = math_floor(target_node.x * shift_factor) or 0,
            y = math_floor(target_node.y * shift_factor) or 0,
        }

        if (target_node.chunk) then
            local historical_chunk = target_node.chunk
            local new_direction = ""

            if (    historical_chunk == source_chunk
                or  historical_chunk.x == source_chunk.x
                and historical_chunk.y == source_chunk.y
            ) then
                return
            end

            if ((historical_chunk.x + 0.5) < pos.x) then
                new_direction = ((historical_chunk.y + 0.5) < pos.y) and "nw" or "sw"
            else
                new_direction = ((historical_chunk.y + 0.5) < pos.y) and "ne" or "se"
            end

            local next_level = target_node.node_level + 1
            if (next_level <= CHUNK_LEVELS) then
                local next_shift = 2 ^ (CHUNK_LEVELS - next_level)

                target_node[new_direction] = new_Quadnode(Quadnode, {
                    size = target_node.size / 2,
                    node_level = next_level,
                    x = math_floor(historical_chunk.x / next_shift) + 0.5,
                    y = math_floor(historical_chunk.y / next_shift) + 0.5,
                })
                target_node[new_direction].chunk = historical_chunk
                target_node.count = math_max((target_node.count or 0) + 1, 0)
                target_node.chunk = nil
            end
        end

        target_node.count = math_max((target_node.count or 0) + 1, 0)

        quadtree_service.add_node({
            tick = params.tick,
            surface_name = params.surface_name,
            source_chunk = source_chunk,
            parent_node = target_node,
            base = next_base,
            start_position = pos,
            depth = params.depth + 1
        })

        return
    else
        local next_level = parent_node.node_level + 1
        if (next_level <= CHUNK_LEVELS) then
            local next_shift = 2 ^ (CHUNK_LEVELS - next_level)

            parent_node[direction] = new_Quadnode(Quadnode, {
                size = (parent_node.size or HALF_MAP_SIZE) / 2,
                node_level = next_level,
                x = math_floor(source_chunk.x / next_shift) + 0.5,
                y = math_floor(source_chunk.y / next_shift) + 0.5,
            })
            parent_node[direction].chunk = source_chunk
            parent_node.chunk = nil
        end
    end
end

local function is_empty_node(node)
    return  not node
        or  not node.chunk
        and not (
                node.nw
            or  node.ne
            or  node.sw
            or  node.se
        )
end

function quadtree_service.find_closest(params)
    if (not params) then return end
    if (not params.surface_name) then return end
    if (not params.target_chunk) then return end
    local surface_name = params.surface_name

    quadtrees = quadtrees or set_game() and quadtrees
    quadtrees[surface_name] = quadtrees[surface_name] or new_Quadtree(Quadtree, { surface_name = surface_name, })
    local quadtree = quadtrees[surface_name]

    -- Parameters
    local target_chunk = params.target_chunk

    target_chunk.meta = target_chunk.meta or {}
    local meta = target_chunk.meta

    -- Optional parameters
    local max_distance = params.max_distance
    local greedy = params.greedy
    local strictness = params.strictness

    -- Composite system load factor
    local blended_x = 0.0

    if (greedy == nil) then
        unit_groups = unit_groups or set_game() and unit_groups
        unit_groups.count = unit_groups.count or 0

        local curr_stress = (unit_groups.count + 1) / (max_unit_groups + 1)
        local curr_activity = stats_data.current.total or 1
        local activity_stress = math_min(curr_activity / 500, 1.0)

        local hist_a = stats_data.activity_history
        local hist_s = stats_data.stress_history

        local trend_modifier = 0

        if (hist_s.acceleration > 0) then
            trend_modifier = trend_modifier + (hist_s.acceleration * 0.6)
        end
        if (hist_a.acceleration > 0) then
            trend_modifier = trend_modifier + math_min(hist_a.acceleration / 50, 0.3)
        end

        if (hist_s.v_1s > 0) then trend_modifier = trend_modifier + hist_s.v_1s * 0.2 end
        if (hist_s.v_2s > 0) then trend_modifier = trend_modifier + hist_s.v_2s * 0.1 end
        if (hist_s.v_4s > 0) then trend_modifier = trend_modifier + hist_s.v_4s * 0.05 end
        if (hist_s.v_8s > 0) then trend_modifier = trend_modifier + hist_s.v_8s * 0.02 end

        stats_data = stats_data or set_game() and stats_data
        local stats_meta = stats_data.meta
        local wv = stats_data.welford_variance

        local engine_volatility = (wv and wv.sd) or 0
        local volatility_penalty = math_min(engine_volatility / 50, 0.25)

        local base_load = (curr_stress * 0.7) + (activity_stress * 0.3)

        local curr_instant_load = math_min(base_load + trend_modifier + volatility_penalty, 1.0)

        surfaces = surfaces or set_game() and surfaces
        surfaces[surface_name] = surfaces[surface_name] or {}
        surfaces[surface_name].meta = surfaces[surface_name].meta or {}
        local surface_meta = surfaces[surface_name].meta

        local last_local_load, last_surface_load, last_global_load = meta.last_load or 0, surface_meta.last_load or 0, stats_meta.last_load or 0

        blended_x = math_max(curr_instant_load, last_global_load, last_surface_load, last_local_load)
        meta.last_load, surface_meta.last_load, stats_meta.last_load = curr_instant_load, curr_instant_load, curr_instant_load

        strictness = math_min(1.0 - blended_x, 0.97)

        if (strictness < 1 and blended_x >= strictness) then
            local greed_threshold =
                    (0.25 * blended_x) -- Linear
                +   (0.5 * (blended_x * blended_x * blended_x)) -- Polynomial
                +   (0.25 * ((2 ^ blended_x) / (1.01 - blended_x))) -- Exponential

            if (greed_threshold > 1) then
                greed_threshold = 1
            elseif (greed_threshold < 0) then
                greed_threshold = 0
            end

            greedy = math_random() < greed_threshold
        else
            greedy = false
        end
    end

    if (not max_distance) then
        if (meta.last_radius) then
            max_distance = meta.last_radius
        elseif (meta.expanded_radius) then
            max_distance = meta.expanded_radius
        else
            max_distance = BASE_SEARCH_RADIUS * (1.0 - (0.96875 * blended_x))
        end
    end

    meta.last_radius = max_distance

    local best_distance = max_distance
    local best_target = nil

    local math_max = math_max
    local math_sqrt = math_sqrt
    local CHUNK_LEVELS = CHUNK_LEVELS

    local function search(node)
        if (is_empty_node(node) or not node.node_level or node.node_level > CHUNK_LEVELS) then return end

        local shift = 2 ^ (CHUNK_LEVELS - (node.node_level or 0))

        local min_x, min_y = node.x - shift, node.y - shift
        local max_x, max_y = node.x + shift, node.y + shift
        local dx, dy = math_max(min_x - target_chunk.x, 0, target_chunk.x - max_x), math_max(min_y - target_chunk.y, 0, target_chunk.y - max_y)

        local delta = math_sqrt(dx * dx + dy * dy)
        if (delta >= best_distance) then return end

        local chunk = node.chunk
        if (chunk) then
            local distance = math_huge
            distance = math_sqrt((chunk.x - target_chunk.x)^2 + (chunk.y - target_chunk.y)^2)
            if (distance < best_distance) then
                best_target = chunk
                best_distance = distance
            end
        end

        local north = (target_chunk.y + 0.5) < (node.y * shift)
        local west  = (target_chunk.x + 0.5) < (node.x * shift)

        if (north) then
            if (west) then
                if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
                if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
                if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
                if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
            else
                if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
                if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
                if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
                if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
            end
        else
            if (west) then
                if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
                if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
                if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
                if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
            else
                if (greedy and search(node.se)) then return best_target elseif (not greedy) then search(node.se) end
                if (greedy and search(node.sw)) then return best_target elseif (not greedy) then search(node.sw) end
                if (greedy and search(node.ne)) then return best_target elseif (not greedy) then search(node.ne) end
                if (greedy and search(node.nw)) then return best_target elseif (not greedy) then search(node.nw) end
            end
        end

        return best_target
    end

    return search(quadtree.base)
end

local function find_leaf_node(node)
   if (not node) then return end
   if (node.chunk) then return node end

    if (node.nw) then return find_leaf_node(node.nw) end
    if (node.ne) then return find_leaf_node(node.ne) end
    if (node.sw) then return find_leaf_node(node.sw) end
    if (node.se) then return find_leaf_node(node.se) end
end

function quadtree_service.remove_node(params)
    if (not params) then return end
    if (not params.surface_name or not params.source_chunk) then return end

    local surface_name = params.surface_name

    quadtrees = quadtrees or set_game() and quadtrees
    if (not quadtrees[surface_name]) then return end

    local quadtree = quadtrees[surface_name]
    if (    not quadtree.base
        or  not quadtree.base.nw
        and not quadtree.base.ne
        and not quadtree.base.sw
        and not quadtree.base.se
    ) then
        if (quadtree.base) then quadtree.base.count = 0 end
        return
    end

    local root = { x = 0, y = 0, }
    local function remove(parent_node, source_chunk, start_pos)
        if (not parent_node or not source_chunk or not start_pos) then return end

        local direction = ""
        if ((source_chunk.x + 0.5) < start_pos.x) then
            direction = ((source_chunk.y + 0.5) < start_pos.y) and "nw" or "sw"
        else
            direction = ((source_chunk.y + 0.5) < start_pos.y) and "ne" or "se"
        end

        local target_node = parent_node[direction]
        if (not target_node) then return end

        if (target_node.chunk) then
            if (target_node.chunk.x == source_chunk.x and target_node.chunk.y == source_chunk.y) then
                parent_node[direction] = nil
                parent_node.count = math_max((parent_node.count or 1) - 1, 0)
                return true
            end

            return
        end

        local shift_factor = 2 ^ (CHUNK_LEVELS - (target_node.node_level or CHUNK_LEVELS))
        local node_pos = {
            x = math_floor(target_node.x * shift_factor) or 0,
            y = math_floor(target_node.y * shift_factor) or 0,
        }

        local removed = remove(target_node, source_chunk, node_pos)
        if (removed) then
            if (is_empty_node(target_node)) then parent_node[direction] = nil end

            parent_node.count = 0
            if (parent_node.nw) then parent_node.count = math_max((parent_node.count or 0), 0) + (parent_node.nw and parent_node.nw.chunk and 1 or parent_node.nw.count or 0) end
            if (parent_node.ne) then parent_node.count = math_max((parent_node.count or 0), 0) + (parent_node.ne and parent_node.ne.chunk and 1 or parent_node.ne.count or 0) end
            if (parent_node.sw) then parent_node.count = math_max((parent_node.count or 0), 0) + (parent_node.sw and parent_node.sw.chunk and 1 or parent_node.sw.count or 0) end
            if (parent_node.se) then parent_node.count = math_max((parent_node.count or 0), 0) + (parent_node.se and parent_node.se.chunk and 1 or parent_node.se.count or 0) end

            if (parent_node.count == 1) then
                local leaf_node = find_leaf_node(parent_node)
                if (leaf_node and leaf_node.chunk) then
                    parent_node.chunk = leaf_node.chunk
                    parent_node.count = nil
                    parent_node.nw, parent_node.ne, parent_node.sw, parent_node.se = nil, nil, nil, nil
                end
            end
        end

        return removed
    end

    remove(quadtree.base, params.source_chunk, root)

    if (is_empty_node(quadtree.base)) then quadtree.base = new_Quadnode(Quadnode, { count = 0, }) end
end

local update_settings = {}

update_settings[Runtime_Global_Settings_Constants.settings.MAX_UNIT_GROUPS.name] = function (event, params) max_unit_groups = params.setting_value end

local ME_PREFIX = ME_PREFIX
local STRING = Types.STRING
function quadtree_service.on_runtime_mod_setting_changed(event, params)
    if (not event.setting or type(event.setting) ~= STRING) then return end
    if (not event.setting_type or type(event.setting_type) ~= STRING) then return end

    if (not (event.setting:find(ME_PREFIX, 1, true) == 1)) then return end

    if (update_settings[event.setting]) then
        update_settings[event.setting](event, params)
    end
end
Settings_Registry:register_setting({
    func_name = "spawn_service_settings",
    func = quadtree_service.on_runtime_mod_setting_changed
})

function quadtree_service.init(__storage) storage = __storage or _ENV.storage end

return quadtree_service