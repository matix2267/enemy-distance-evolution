local function shallow_copy(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[k] = v
    end
    return ret
end

local function clone_spawner(orig)
    local ret = shallow_copy(orig)
    ret.name = orig.name .. "-2"
    ret.max_health = 400
    ret.localised_name = { "", orig.localised_name or { "entity-name." .. orig.name }, " lvl 2" }
    ret.localised_description = { "", orig.localised_description or { "entity-description." .. orig.name }, " lvl 2" }
    ret.factoriopedia_alternative = orig.factoriopedia_alternative or orig.name
    return ret
end

data:extend({
    clone_spawner(data.raw["unit-spawner"]["biter-spawner"]),
})
