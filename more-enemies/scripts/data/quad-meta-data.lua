local storage

local game

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage
    game = __game or _ENV.game
    return game
end

local type = type
local setmetatable = setmetatable

local math_min = math.min
local math_max = math.max
local math_exp = math.exp

local CREATED = "created"
local MAX = "max"
local MIN = "min"
local SKIP = "skip"
local SUM = "sum"
local TABLE = "table"

local UINT64 = 2^64-1

local schema_types = {
    SUM = 1,
    MAX = 1,
    MIN = 1,
    TABLE = 1,
}

local DECAY_CONSTANT = 0.0001
local NEGATIVE_DECAY = -1 * DECAY_CONSTANT

local METRIC_SCHEMA = {
    total_weight = SUM,
    aggregate_fx = SUM,
    max_priority = MAX,

    spawner_count = SUM,
    entity_count  = SUM,
    enemy_heat    = SUM,
    player_heat   = SUM,

    player_deaths = SUM,
    enemy_deaths = SUM,

    total_player_deaths = SUM,
    total_enemy_deaths = SUM,

    witnessed = MAX,
    witnessed_tick = MAX,

    pollution = SUM,

    total_deaths = SUM,
    death_weight = SUM,

    last_death_tick = MAX,
    last_decayed_tick = MAX,

    created = MIN,
    updated = MAX,
}

local quad_meta_data = {}

function quad_meta_data:new_template(tick)
    return setmetatable({
        total_weight = 0,
        aggregate_fx = 0,
        max_priority = 1,

        spawner_count = 0,
        entity_count = 0,

        enemy_heat = 0,
        player_heat = 0,

        player_deaths = 0,
        enemy_deaths = 0,

        total_player_deaths = 0,
        total_enemy_deaths = 0,

        witnessed = 0,
        witnessed_tick = 0,

        pollution = 0,

        total_deaths = 0,
        death_weight = 0,

        last_death_tick = 0,
        last_decayed_tick = tick,

        created = tick,
        updated = tick,
    }, self)
end

function quad_meta_data:merge_data(source, tick)
    tick = tick or (game or set_game()).tick
    self.updated = tick

    if (not source) then return end

    self.total_weight = (self.total_weight or 0) + (source.total_weight or 0)
    self.aggregate_fx = (self.aggregate_fx or 0) + (source.fx or source.aggregate_fx or 0)
    self.max_priority = math_max(self.max_priority or 1, 1, source.p or source.max_priority or 1)
end

local new_template = quad_meta_data.new_template
function quad_meta_data:aggregate_leaf_nodes(tick, nw, ne, sw, se)
    tick = tick or (game or set_game()).tick
    nw, ne, sw, se = nw or new_template(quad_meta_data, tick), ne or new_template(quad_meta_data, tick), sw or new_template(quad_meta_data, tick), se or new_template(quad_meta_data, tick)

    local ldt_nw, ldt_ne, ldt_sw, ldt_se =
        nw.last_death_tick and nw.last_death_tick > 0 and nw.last_death_tick or tick,
        ne.last_death_tick and ne.last_death_tick > 0 and ne.last_death_tick or tick,
        sw.last_death_tick and sw.last_death_tick > 0 and sw.last_death_tick or tick,
        se.last_death_tick and se.last_death_tick > 0 and se.last_death_tick or tick

    self.prev_death_tick = math_max(tick, ldt_nw, ldt_ne, ldt_sw, ldt_se)

    for key, property in pairs(METRIC_SCHEMA or {}) do
        if (property == SUM) then
            self[key] = (nw[key] or 0) + (ne[key] or 0) + (sw[key] or 0) + (se[key] or 0)
        elseif (property == MAX) then
            self[key] = math_max(0, nw[key], ne[key], sw[key], se[key])
        elseif (property == MIN) then
            if (key == CREATED) then
                local c_nw, c_ne, c_sw, c_se =
                    nw[key] and nw[key] > 0 and nw[key] or tick,
                    ne[key] and ne[key] > 0 and ne[key] or tick,
                    sw[key] and sw[key] > 0 and sw[key] or tick,
                    se[key] and se[key] > 0 and se[key] or tick
                    self[key] = math_min(tick, c_nw, c_ne, c_sw, c_se)
                else
                local c_nw, c_ne, c_sw, c_se =
                    nw[key] or UINT64,
                    ne[key] or UINT64,
                    sw[key] or UINT64,
                    se[key] or UINT64
                self[key] = math_min(c_nw, c_ne, c_sw, c_se)
            end
        else
            if (property == SKIP) then goto skip end
            if (type(property) == TABLE) then
                ---@diagnostic disable-next-line: param-type-mismatch
                for k, v in pairs(property) do
                    if (v == SUM) then
                        self[k] = (nw[k] or 0) + (ne[k] or 0) + (sw[k] or 0) + (se[k] or 0)
                    elseif (v == MAX) then
                        self[k] = math_max(0, nw[k], ne[k], sw[k], se[k])
                    elseif (v == MIN) then
                        local c_nw, c_ne, c_sw, c_se =
                            nw[k] and nw[k] > 0 and nw[k] or tick,
                            ne[k] and ne[k] > 0 and ne[k] or tick,
                            sw[k] and sw[k] > 0 and sw[k] or tick,
                            se[k] and se[k] > 0 and se[k] or tick

                        self[key] = math_min(tick, c_nw, c_ne, c_sw, c_se)
                    else
                        --[[ ??? ]]
                    end
                end
            end
        end
        ::skip::
    end
end

function quad_meta_data:apply_time_delay(delta_t, scar_threshold, floors)
    if (delta_t <= 0) then return end

    local decay_factor = math_exp(NEGATIVE_DECAY * delta_t)

    if ((self.death_weight or 0) >= scar_threshold) then
        self.total_weight = math_max((floors.w or floors.total_weight or 0), self.total_weight * decay_factor)
        self.aggregate_fx = math_max((floors.fx or floors.aggregate_fx or 1), self.aggregate_fx * decay_factor)
        self.max_priority = math_max(floors.p, self.max_priority * decay_factor)
        return true
    else
        self.total_weight = self.total_weight * decay_factor
        self.aggregate_fx = self.aggregate_fx * decay_factor
        return false
    end
end

function quad_meta_data.get_schema() return METRIC_SCHEMA end

quad_meta_data.__index = quad_meta_data

return quad_meta_data