data:extend({
    {
        type = "int-setting",
        name = "max-level",
        setting_type = "startup",
        default_value = 10,
        minimum_value = 3,
        maximum_value = 100,
    },
    {
        type = "double-setting",
        name = "max-level-hp-scale",
        setting_type = "startup",
        default_value = 10,
        minimum_value = 1,
    },
    {
        type = "double-setting",
        name = "distance-to-max-level",
        setting_type = "runtime-global",
        default_value = 3000,
        minimum_value = 1,
    },
    {
        type = "double-setting",
        name = "distance-first-level-offset",
        setting_type = "runtime-global",
        default_value = 0,
        minimum_value = 0,
    },
})
