local max_level = settings.startup["mx-ede-max-level"].value
local max_level_hp_scale = settings.startup["mx-ede-max-level-hp-scale"].value

local health_factors = (function()
    local res = {}
    for i = 1, max_level do
        res[i] = math.exp(math.log(max_level_hp_scale) * (i - 1) / (max_level - 1))
    end
    return res
end)()

local function shallow_copy(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[k] = v
    end
    return ret
end

-- maps t such that t = x -> a, t = y -> b linearly interpolated
local function interpolate(t, x, y, a, b)
    return a + (t - x) * (b - a) / (y - x)
end

local function compute_spawndef_at_level(spawndef, level)
    local lower_evo = math.max((level - 1) / max_level, 0)
    local upper_evo = math.min(level / max_level, 1)
    -- boundary conditions
    if upper_evo <= 0 then
        local spawnpoint = spawndef[1]
        return { { 0, spawnpoint[2] or spawnpoint.spawn_weight } }
    end
    if lower_evo >= 1 then
        local spawnpoint = spawndef[#spawndef]
        return { { 0, spawnpoint[2] or spawnpoint.spawn_weight } }
    end
    -- calculate average spawn weight in range [lower_evo, upper_evo]
    local weight = 0
    for idx, left_spawnpoint in pairs(spawndef) do
        local left_evo = left_spawnpoint[1] or left_spawnpoint.evolution_factor
        local left_weight = left_spawnpoint[2] or left_spawnpoint.spawn_weight
        local right_spawnpoint = spawndef[idx + 1] or { 1, left_weight }
        local right_evo = right_spawnpoint[1] or right_spawnpoint.evolution_factor
        local right_weight = right_spawnpoint[2] or right_spawnpoint.spawn_weight
        -- skip if range [left_evo, right_evo] is outside of [lower_evo, upper_evo] or has zero length
        if left_evo >= upper_evo or right_evo <= lower_evo or left_evo >= right_evo then
            goto continue
        end
        -- crop to [lower_evo, upper_evo]
        local left_lim = math.max(left_evo, lower_evo)
        local right_lim = math.min(right_evo, upper_evo)
        local left_val = interpolate(left_lim, left_evo, right_evo, left_weight, right_weight)
        local right_val = interpolate(right_lim, left_evo, right_evo, left_weight, right_weight)
        weight = weight + (right_lim - left_lim) / (upper_evo - lower_evo) * (left_val + right_val) / 2
        ::continue::
    end
    return { { 0, weight } }
end

local function compute_result_units_at_level(result_units, level)
    local ret = {}
    for idx, spawndef in pairs(result_units) do
        ret[idx] =
        { spawndef[1] or spawndef.unit, compute_spawndef_at_level(spawndef[2] or spawndef.spawn_points, level) }
    end
    return ret
end

-- local result_units_biters = {
--     { "small-biter",    { { 0, 0.3 }, { 0.6, 0 } } },
--     { "medium-biter",   { { 0.2, 0 }, { 0.6, 0.3 }, { 0.7, 0.1 } } },
--     { "big-biter",      { { 0.5, 0 }, { 1, 0.4 } } },
--     { "behemoth-biter", { { 0.9, 0 }, { 1, 0.3 } } },
-- }

-- local result_units_biters_expanded = {
--     {
--         unit = "small-biter",
--         spawn_points = {
--             { evolution_factor = 0,   spawn_weight = 0.3 },
--             { evolution_factor = 0.6, spawn_weight = 0 },
--         },
--     },
--     {
--         unit = "medium-biter",
--         spawn_points = {
--             { evolution_factor = 0.2, spawn_weight = 0 },
--             { evolution_factor = 0.6, spawn_weight = 0.3 },
--             { evolution_factor = 0.7, spawn_weight = 0.1 },
--         },
--     },
--     {
--         unit = "big-biter",
--         spawn_points = {
--             { evolution_factor = 0.5, spawn_weight = 0 },
--             { evolution_factor = 1,   spawn_weight = 0.4 },
--         },
--     },
--     {
--         unit = "behemoth-biter",
--         spawn_points = {
--             { evolution_factor = 0.9, spawn_weight = 0 },
--             { evolution_factor = 1,   spawn_weight = 0.3 },
--         },
--     },
-- }

-- local result_units_gleba = {
--     { "small-wriggler-pentapod",  { { 0, 0.9 }, { 0.3, 0.9 }, { 0.35, 0 } } },
--     { "medium-wriggler-pentapod", { { 0.3, 0 }, { 0.35, 0.9 }, { 0.6, 0.9 }, { 0.65, 0 } } },
--     { "big-wriggler-pentapod",    { { 0.6, 0 }, { 0.65, 0.9 }, { 1, 0.9 } } },
-- }

-- for i = 1, max_level do
--     print('level: ' .. i)
--     local res = compute_result_units_at_level(result_units_biters, i)
--     for _, unit in pairs(res) do
--         print(unit[1], unit[2][1][2])
--     end
-- end

local function compute_spawning_cooldown_at_level(cooldown, level)
    local cd = interpolate(level, 1, max_level, cooldown[1], cooldown[2])
    return { cd, cd }
end

local function create_leveled_spawner(orig, level)
    local ret = shallow_copy(orig)
    ret.name = orig.name .. "-lv" .. level
    ret.max_health = (orig.max_health or 10) * health_factors[level]
    ret.localised_name = { "", orig.localised_name or { "entity-name." .. orig.name }, " lvl " .. level }
    ret.localised_description = orig.localised_description or { "entity-description." .. orig.name }
    ret.factoriopedia_alternative = orig.factoriopedia_alternative or orig.name
    ret.result_units = compute_result_units_at_level(orig.result_units, level)
    ret.spawning_cooldown = compute_spawning_cooldown_at_level(orig.spawning_cooldown, level)
    -- Do not autoplace leveled spawners. Event listeners replace the original spawners dynamically.
    ret.autoplace = nil
    return ret
end

data:extend((function()
    local ret = {}
    for _, unit in pairs(data.raw["unit-spawner"]) do
        for level = 1, max_level do
            table.insert(ret, create_leveled_spawner(unit, level))
        end
    end
    return ret
end
)())

local function add_leveled_spawners_to_list(list)
    if list == nil then
        return
    end
    local leveled_list = {}
    for _, orig_name in pairs(list) do
        if data.raw["unit-spawner"][orig_name] ~= nil then
            for level = 1, max_level do
                local leveled_name = orig_name .. "-lv" .. level
                if data.raw["unit-spawner"][leveled_name] ~= nil then
                    table.insert(leveled_list, leveled_name)
                end
            end
        end
    end
    for _, new_name in pairs(leveled_list) do
        table.insert(list, new_name)
    end
end

for _, achievement in pairs(data.raw["kill-achievement"]) do
    add_leveled_spawners_to_list(achievement.to_kill)
end

for _, achievement in pairs(data.raw["dont-kill-manually-achievement"]) do
    add_leveled_spawners_to_list(achievement.to_kill)
end

for _, ammo in pairs(data.raw["ammo"]) do
    if ammo.ammo_type ~= nil then
        add_leveled_spawners_to_list(ammo.ammo_type.target_filter)
    end
end

-- TODO: Find all triggers that create spawners.
-- TODO: Make it configurable whether the created spawner is leveled by distance or has fixed level.
if data.raw["assembling-machine"]["captive-biter-spawner"] ~= nil and
    data.raw["assembling-machine"]["captive-biter-spawner"].dying_trigger_effect ~= nil then
    data.raw["assembling-machine"]["captive-biter-spawner"].dying_trigger_effect.trigger_created_entity = true
end
