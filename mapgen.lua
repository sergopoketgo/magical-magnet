-- Barite Ore
minetest.register_ore({
        ore_type       = "scatter",
        ore            = "magical_magnet:sandstone_with_barite",
        wherein        = "default:sandstone",
        clust_scarcity = 15 * 15 * 15,
        clust_num_ores = 1,
        clust_size     = 3,
        y_max          = -0,
        y_min          = -63,
})

minetest.register_ore({
        ore_type       = "scatter",
        ore            = "magical_magnet:sandstone_with_barite",
        wherein        = "default:sandstone",
        clust_scarcity = 14 * 14 * 14,
        clust_num_ores = 2,
        clust_size     = 3,
        y_max          = -64,
        y_min          = -255,
})
