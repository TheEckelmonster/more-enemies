-- If already defined, return
if _overmind_taget_priorities and _overmind_taget_priorities.more_enemies then
  return _overmind_taget_priorities
end

local overmind_taget_priorities = {}
overmind_taget_priorities.target_priorities = {
    ["cargo-landing-pad"] = {
        priority = 1,
        weight = 256000,
    },
    ["rocket-silo"] = {
        priority = 1,
        weight = 128000,
    },
    -- ["rocket-silo-rocket"] = {
    --     priority = 1,
    --     weight = 300,
    -- },
    ["character"] = {
        priority = 2,
        weight = 196000,
    },
    ["character-corpse"] = {
        priority = 3,
        weight = 96000,
    },
    ["small-electric-pole"] = {
        priority = 0,
        weight = 400,
    },
    ["medium-electric-pole"] = {
        priority = 0,
        weight = 800,
    },
    ["big-electric-pole"] = {
        priority = 0,
        weight = 2400,
    },
    ["substation"] = {
        priority = 0,
        weight = 1600,
    },
    ["curved-rail-a"] = {
        priority = 0,
        weight = 9600,
    },
    ["curved-rail-b"] = {
        priority = 0,
        weight = 9600,
    },
    ["elevated-curved-rail-a"] = {
        priority = 0,
        weight = 9600,
    },
    ["elevated-curved-rail-b"] = {
        priority = 0,
        weight = 9600,
    },
    ["elevated-half-diagonal-rail"] = {
        priority = 0,
        weight = 9600,
    },
    ["elevated-straight-rail"] = {
        priority = 0,
        weight = 9600,
    },
    ["half-diagonal-rail"] = {
        priority = 0,
        weight = 9600,
    },
    ["rail-ramp"] = {
        priority = 0,
        weight = 18000,
    },
    ["rail-signal"] = {
        priority = 0,
        weight = 1200,
    },
    ["rail-chain-signal"] = {
        priority = 0,
        weight = 1200,
    },
    ["rail-support"] = {
        priority = 0,
        weight = 24000,
    },
    ["straight-rail"] = {
        priority = 0,
        weight = 9600,
    },
    ["train-stop"] = {
        priority = 0,
        weight = 24000,
    },
    ["artillery-wagon"] = {
        priority = 0,
        weight = 48000,
    },
    ["cargo-wagon"] = {
        priority = 0,
        weight = 0,
    },
    ["fluid-wagon"] = {
        priority = 0,
        weight = 36000,
    },
    ["locomotive"] = {
        priority = 0,
        weight = 18000,
    },
    ["radar"] = {
        priority = 0,
        weight = 34000,
    },
    ["solar-panel"] = {
        priority = 0,
        weight = 12000,
    },
    ["accumulator"] = {
        priority = 0,
        weight = 12000,
    },
    ["arithmetic-combinator"] = {
        priority = 0,
        weight = 24000,
    },
    ["constant-combinator"] = {
        priority = 0,
        weight = 24000,
    },
    ["decider-combinator"] = {
        priority = 0,
        weight = 24000,
    },
    ["selector-combinator"] = {
        priority = 0,
        weight = 24000,
    },
    ["small-lamp"] = {
        priority = 0,
        weight = 6400,
    },
    ["power-switch"] = {
        priority = 0,
        weight = 32000,
    },
    ["assembling-machine-1"] = {
        priority = 0,
        weight = 18000,
    },
    ["assembling-machine-2"] = {
        priority = 0,
        weight = 24000,
    },
    ["assembling-machine-3"] = {
        priority = 0,
        weight = 32000,
    },
    ["chemical-plant"] = {
        priority = 0,
        weight = 26000,
    },
    ["oil-refinery"] = {
        priority = 0,
        weight = 26000,
    },
    ["centrifuge"] = {
        priority = 0,
        weight = 48000,
    },
    ["boiler"] = {
        priority = 0,
        weight = 36000,
    },
    ["wooden-chest"] = {
        priority = 0,
        weight = 100,
    },
    ["iron-chest"] = {
        priority = 0,
        weight = 250,
    },
    ["steam-engine"] = {
        priority = 0,
        weight = 42000,
    },
    ["offshore-pump"] = {
        priority = 0,
        weight = 36000,
    },
    ["inserter"] = {
        priority = 0,
        weight = 800,
    },
    ["fast-inserter"] = {
        priority = 0,
        weight = 2400,
    },
    ["long-handed-inserter"] = {
        priority = 0,
        weight = 1800,
    },
    ["burner-inserter"] = {
        priority = 0,
        weight = 1200,
    },
    ["pipe"] = {
        priority = 0,
        weight = 400,
    },
    ["pipe-to-ground"] = {
        priority = 0,
        weight = 700,
    },
    ["stone-wall"] = {
        priority = 0,
        weight = 12,
    },
    ["lab"] = {
        priority = 0,
        weight = 72000,
    },
    ["car"] = {
        priority = 0,
        weight = 64000,
    },
    ["stone-furnace"] = {
        priority = 0,
        weight = 3600,
    },
    ["electric-furnace"] = {
        priority = 0,
        weight = 9600,
    },
    ["steel-furnace"] = {
        priority = 0,
        weight = 7200,
    },
    ["gate"] = {
        priority = 0,
        weight = 36,
    },
    ["steel-chest"] = {
        priority = 0,
        weight = 500,
    },
    ["bulk-inserter"] = {
        priority = 0,
        weight = 3600,
    },
    ["stack-inserter"] = {
        priority = 0,
        weight = 4800,
    },
    -- ["land-mine"] = {
    --     priority = 0,
    --     weight = 0,
    -- },
    ["passive-provider-chest"] = {
        priority = 42000,
        weight = 0,
    },
    ["active-provider-chest"] = {
        priority = 48000,
        weight = 0,
    },
    ["storage-chest"] = {
        priority = 0,
        weight = 44000,
    },
    ["buffer-chest"] = {
        priority = 0,
        weight = 56000,
    },
    ["requester-chest"] = {
        priority = 0,
        weight = 64000,
    },
    ["storage-tank"] = {
        priority = 0,
        weight = 12000,
    },
    ["pump"] = {
        priority = 0,
        weight = 7200,
    },
    ["beacon"] = {
        priority = 0,
        weight = 1000,
    },
    ["tank"] = {
        priority = 0,
        weight = 72000,
    },
    ["heat-exchanger"] = {
        priority = 0,
        weight = 12000,
    },
    ["steam-turbine"] = {
        priority = 0,
        weight = 42000,
    },
    ["heat-pipe"] = {
        priority = 0,
        weight = 600,
    },
    ["spidertron"] = {
        priority = 0,
        weight = 84000,
    },
    -- ["burner-generator"] = {
    --     priority = 0,
    --     weight = 0,
    -- },
}

overmind_taget_priorities.overmind_taget_priorities_filter = {}

for k, _ in pairs(overmind_taget_priorities.target_priorities) do
    table.insert(overmind_taget_priorities.overmind_taget_priorities_filter, { filter = "name", name = k})
end

overmind_taget_priorities.more_enemies = true

local _overmind_taget_priorities = overmind_taget_priorities

return overmind_taget_priorities