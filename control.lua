local function replace_spawner(spawner)
    local name = spawner.name .. "-2"
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
        local spawners = surface.find_entities_filtered { force = "enemy", type = "unit-spawner", name = "biter-spawner" }
        for _, spawner in pairs(spawners) do
            replace_spawner(spawner)
        end
    end
end)

-- New chunk generated
script.on_event(defines.events.on_chunk_generated, function(event)
    local spawners = event.surface.find_entities_filtered { area = event.area, force = "enemy", type = "unit-spawner", name = "biter-spawner" }
    for _, spawner in pairs(spawners) do
        replace_spawner(spawner)
    end
end)

-- Enemy expansion
script.on_event(defines.events.on_entity_spawned, function(event)
    if event.entity.name == "biter-spawner" then
        replace_spawner(event.entity)
    end
end)
