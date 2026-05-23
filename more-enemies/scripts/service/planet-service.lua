local storage
local surface_creation

local game
local get_surface

local function set_game(event, __game, __storage)
    storage = __storage or _ENV.storage
    storage.surface_creation = storage.surface_creation or {}
    surface_creation = storage.surface_creation

    game = __game or _ENV.game
    get_surface = game.get_surface

    return game
end

local Log = Log

local planet_service = {}
planet_service.name = "planet_service"
planet_service.set_game = set_game

function planet_service.on_surface_created(event)
    -- Log.debug("planet_service.on_surface_created")
    -- Log.info(event)

    if (not event) then return end
    if (not event.surface_index or event.surface_index < 1) then return end

    game = game or set_game()

    local surface = get_surface(event.surface_index)
    if (not surface or not surface.valid) then return end

    local surface_name = surface.name

    surface_creation = surface_creation or set_game() and surface_creation
    surface_creation[surface_name] = event.tick
end

function planet_service.init(__storage) storage = __storage or _ENV.storage end

return planet_service