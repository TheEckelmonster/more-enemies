local storage
local game
local get_surface

local pairs = pairs

local function set_game(__game)
    game = __game or _ENV.game
    get_surface = game.get_surface
    return game
end

local Constants = Constants
local Log = Log

local Valid_Planets = {}
for _, planet in pairs(Constants.DEFAULTS.planets) do Valid_Planets[planet.string_val] = 1 end

local planet_service = {}

function planet_service.on_surface_created(event)
    -- Log.debug("planet_service.on_surface_created")
    -- Log.info(event)

    if (not event) then return end
    if (not event.surface_index or event.surface_index < 1) then return end

    game = game or set_game()

    local surface = get_surface(event.surface_index)
    if (not surface or not surface.valid) then return end

    local surface_name = surface.name
    if (not Valid_Planets[surface_name]) then return end

    storage.surface_creation = storage.surface_creation or {}
    storage.surface_creation[surface_name] = event.tick
end

function planet_service.init(__storage)
    storage = __storage
end

return planet_service