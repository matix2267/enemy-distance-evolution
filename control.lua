local max_level = 10
local distance_per_level = 320
local distance_first_level_offset = 0

local function calculate_level(position)
    local distance = math.sqrt(position.x * position.x + position.y * position.y)
    local level = (distance - distance_first_level_offset) / distance_per_level + 1
    return math.floor(math.min(math.max(level, 1), max_level))
end

local function safe_replace_spawner(spawner)
    if prototypes.entity[spawner.name .. "-lv1"] == nil then
        return
    end

    local level = calculate_level(spawner.position)

    local name = spawner.name .. "-lv" .. level
    local surface = spawner.surface
    local position = spawner.position
    local force = spawner.force
    spawner.destroy()
    surface.create_entity {
        name = name,
        position = position,
        force = force,
    }
end

-- New game or mod installed
script.on_init(function()
    for _, surface in pairs(game.surfaces) do
        local spawners = surface.find_entities_filtered { force = "enemy", type = "unit-spawner" }
        for _, spawner in pairs(spawners) do
            safe_replace_spawner(spawner)
        end
    end
end)

-- New chunk generated
script.on_event(defines.events.on_chunk_generated, function(event)
    local spawners = event.surface.find_entities_filtered { area = event.area, force = "enemy", type = "unit-spawner" }
    for _, spawner in pairs(spawners) do
        safe_replace_spawner(spawner)
    end
end)

-- A script spawned a new nest, doesn't seem to work for enemy expansions.
script.on_event(defines.events.on_entity_spawned, function(event)
    if event.entity.type == "unit-spawner" then
        safe_replace_spawner(event.entity)
    end
end)
