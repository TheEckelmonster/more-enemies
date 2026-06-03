local entity_black_list, entity_white_list = {}, {}

entity_black_list["arrow"] = true
entity_black_list["artillery-flare"] = true
entity_black_list["artillery-projectile"] = true
entity_black_list["beam"] = true
entity_black_list["character-corpse"] = true
entity_black_list["cliff"] = true
entity_black_list["corpse"] = true
entity_black_list["rail-remnants"] = true
entity_black_list["deconstructible-tile-proxy"] = true
entity_black_list["entity-ghost"] = true

entity_white_list["accumulator"] = true
entity_white_list["agricultural-tower"] = true
entity_white_list["artillery-turret"] = true

entity_black_list["asteroid-collector"] = true
entity_black_list["asteroid"] = true

entity_white_list["beacon"] = true
entity_white_list["boiler"] = true
entity_white_list["burner-generator"] = true
entity_white_list["cargo-bay"] = true
entity_white_list["cargo-landing-pad"] = true

entity_black_list["cargo-pod"] = true

entity_white_list["character"] = true
entity_white_list["arithmetic-combinator"] = true
entity_white_list["decider-combinator"] = true
entity_white_list["selector-combinator"] = true
entity_white_list["constant-combinator"] = true
entity_white_list["container"] = true
entity_white_list["logistic-container"] = true
entity_white_list["infinity-container"] = true

entity_black_list["temporary-container"] = true

entity_white_list["assembling-machine"] = true
entity_white_list["rocket-silo"] = true
entity_white_list["furnace"] = true
entity_white_list["display-panel"] = true
entity_white_list["electric-energy-interface"] = true
entity_white_list["electric-pole"] = true
entity_white_list["unit-spawner"] = true

entity_black_list["capture-robot"] = true
entity_black_list["combat-robot"] = true
entity_black_list["construction-robot"] = true
entity_black_list["logistic-robot"] = true

entity_white_list["fusion-generator"] = true
entity_white_list["fusion-reactor"] = true
entity_white_list["gate"] = true
entity_white_list["generator"] = true
entity_white_list["heat-interface"] = true
entity_white_list["heat-pipe"] = true
entity_white_list["inserter"] = true
entity_white_list["lab"] = true
entity_white_list["lamp"] = true
entity_white_list["land-mine"] = true
entity_white_list["lightning-attractor"] = true
entity_white_list["linked-container"] = true
entity_white_list["market"] = true
entity_white_list["mining-drill"] = true
entity_white_list["offshore-pump"] = true
entity_white_list["pipe"] = true
entity_white_list["infinity-pipe"] = true
entity_white_list["pipe-to-ground"] = true
entity_white_list["player-port"] = true
entity_white_list["power-switch"] = true
entity_white_list["programmable-speaker"] = true
entity_white_list["proxy-container"] = true
entity_white_list["pump"] = true
entity_white_list["radar"] = true
entity_white_list["curved-rail-a"] = true
entity_white_list["elevated-curved-rail-a"] = true
entity_white_list["curved-rail-b"] = true
entity_white_list["elevated-curved-rail-b"] = true
entity_white_list["half-diagonal-rail"] = true
entity_white_list["elevated-half-diagonal-rail"] = true
entity_white_list["legacy-curved-rail"] = true
entity_white_list["legacy-straight-rail"] = true
entity_white_list["rail-ramp"] = true
entity_white_list["straight-rail"] = true
entity_white_list["elevated-straight-rail"] = true
entity_white_list["rail-chain-signal"] = true
entity_white_list["rail-signal"] = true
entity_white_list["rail-support"] = true
entity_white_list["reactor"] = true
entity_white_list["roboport"] = true
entity_white_list["segment"] = true
entity_white_list["segmented-unit"] = true
entity_white_list["simple-entity-with-owner"] = true
entity_white_list["simple-entity-with-force"] = true
entity_white_list["solar-panel"] = true
entity_white_list["space-platform-hub"] = true

entity_black_list["spider-leg"] = true

-- entity_white_list["spider-unit"] = true
entity_white_list["storage-tank"] = true
entity_white_list["thruster"] = true
entity_white_list["train-stop"] = true
entity_white_list["lane-splitter"] = true
entity_white_list["linked-belt"] = true
entity_white_list["loader-1x1"] = true
entity_white_list["loader"] = true
entity_white_list["splitter"] = true
entity_white_list["transport-belt"] = true
entity_white_list["underground-belt"] = true
entity_white_list["turret"] = true
entity_white_list["ammo-turret"] = true
entity_white_list["electric-turret"] = true
entity_white_list["fluid-turret"] = true
-- entity_white_list["unit"] = true
entity_white_list["valve"] = true
entity_white_list["car"] = true
entity_white_list["artillery-wagon"] = true
entity_white_list["cargo-wagon"] = true
entity_white_list["infinity-cargo-wagon"] = true
entity_white_list["fluid-wagon"] = true
entity_white_list["locomotive"] = true
entity_white_list["spider-vehicle"] = true
entity_white_list["wall"] = true
entity_white_list["fish"] = true
entity_white_list["simple-entity"] = true
entity_white_list["tree"] = true
entity_white_list["plant"] = true

entity_black_list["explosion"] = true
entity_black_list["fire"] = true
entity_black_list["stream"] = true
entity_black_list["highlight-box"] = true
entity_black_list["item-entity"] = true
entity_black_list["item-request-proxy"] = true
entity_black_list["lightning"] = true
entity_black_list["particle-source"] = true
entity_black_list["projectile"] = true
entity_black_list["resource"] = true
entity_black_list["rocket-silo-rocket"] = true
entity_black_list["rocket-silo-rocket-shadow"] = true
entity_black_list["smoke-with-trigger"] = true
entity_black_list["speech-bubble"] = true
entity_black_list["sticker"] = true
entity_black_list["tile-ghost"] = true

return function () return entity_black_list, entity_white_list end