local setmetatable = setmetatable

local Data = require("__TheEckelmonster-core-library__.libs.data.data")
local new_Data = Data.new

local Simple_Queue = require("scripts.data.simple-queue")
local new_Simple_Queue = Simple_Queue.new

local math_ceil = math.ceil
local math_max = math.max
local math_min = math.min

local defines = defines
local BASELINES = {
    [defines.events.on_entity_spawned] = 2^10,
    -- [defines.events.on_entity_died] = 512,
    [defines.events.on_post_entity_died] = 2^10,
    [defines.events.script_raised_built] = 2^8,
    [defines.events.on_unit_group_finished_gathering] = 2^5,
}

local stats_data = {}

stats_data.tick = 0
stats_data.pause = 0
stats_data.pause_duration = 1
stats_data.limits = nil
stats_data.current =  nil
stats_data.previous = nil
stats_data.activity_history = nil
stats_data.stress_history = nil
stats_data.welford_variance = nil
stats_data.surface_group_stress = nil

function stats_data:new(o)
    local obj = o or {}

    obj.tick = obj.tick or 0
    obj.pause = obj.pause or 0
    obj.pause_duration = obj.pause_duration or 1
    obj.limits = obj.limits or {}
    obj.current = obj.current or { total = 0, }
    obj.previous = obj.previous or { total = 0, }
    obj.activity_history = obj.activity_history or {
        last_1s = 0, last_2s = 0, last_4s = 0, last_8s = 0,
           v_1s = 0,    v_2s = 0,    v_4s = 0,    v_8s = 0,
        acceleration = 0,
    }
    obj.stress_history = obj.stress_history or {
        last_1s = 0, last_2s = 0, last_4s = 0, last_8s = 0,
           v_1s = 0,    v_2s = 0,    v_4s = 0,    v_8s = 0,
        acceleration = 0,
    }
    obj.welford_variance = obj.welford_variance or {
        count = 0,
        mean = 0,
        M2 = 0,
        sd = 0,
    }
    obj.event_governors = obj.event_governors or new_Simple_Queue(Simple_Queue, {})
    obj.event_gov_map = obj.event_gov_map or {}
    obj.surface_group_stress = obj.surface_group_stress or {}
    obj.meta = obj.meta or {}

    self.__index = self
    return setmetatable(new_Data(Data, obj), self)
end

--[[
    TODO: Include source filename to distinguish identical events handled across multiple event handlers
]]
function stats_data:process_event(event_id, tick)
    if (not self or not event_id or not tick) then return end

    self.current = self.current or {}
    self.current[event_id] = (self.current[event_id] or 0) + 1

    if (self.pause_until and tick < self.pause_until) then return false end

    self.event_governors = self.event_governors or new_Simple_Queue(Simple_Queue, {})
    local govs = self.event_governors
    local gov_map = self.event_gov_map or {}

    local gov = nil
    local mapped_idx = gov_map[event_id]
    if (not mapped_idx) then
        govs.first = govs.first or 1
        govs.last = govs.last or 1

        local write_idx = govs.last
        govs.q[write_idx] = {
            event_id = event_id,
            baseline = BASELINES[event_id] or 48,
            current_limit = BASELINES[event_id] or 48,
            fail_streak = 0,
            idx = write_idx
        }

        gov_map[event_id] = write_idx
        gov = govs.q[write_idx]

        govs.last = write_idx + 1
    else
        gov = govs.q[mapped_idx]
    end
    if (not gov) then return end

    self.meta = self.meta or {}
    local blended_x = self.meta.last_load or 0

    local contracted_limit = math_ceil(gov.baseline * (1 - (0.75 * blended_x)))
    if (self.current[event_id] > contracted_limit) then
        local streak = (gov.fail_streak or 0) + 1
        gov.fail_streak = streak

        local total_penalty = math_min((self.pause_duration or 8) * 2, 120)
        self.pause_duration = total_penalty

        local hard_sleep = total_penalty * blended_x
        local soft_sleep = total_penalty * (1 - blended_x)

        self.pause_until = tick + math_ceil(hard_sleep + (soft_sleep * 0.5 ))
        self.pause = math_ceil(hard_sleep + soft_sleep)

        gov.current_limit = math_max(1 + math_ceil(contracted_limit ^ 0.9), 4)
        return false
    end

    return true
end

setmetatable(stats_data, Data)
stats_data.__index = stats_data

return stats_data