-- Common Craft Recipes
minetest.register_craft({
    output = "magical_magnet:gravity_core_uncharged",
    recipe = {
        {"stardust:stardust", "basic_materials:energy_crystal_simple", "stardust:stardust"},
        {"magical_magnet:magnet_ingot", "magic_materials:void_rune", "magical_magnet:magnet_ingot"},
        {"stardust:stardust", "basic_materials:energy_crystal_simple", "stardust:stardust"},
    }
})

minetest.register_craft({
    output = "magical_magnet:magnet_off 1 65535",
    recipe = {
        {"magical_magnet:magnet_ingot", "magical_magnet:gravity_core_uncharged", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
    }
})

minetest.register_craft({
    output = "magical_magnet:magnet_off",
    recipe = {
        {"magical_magnet:magnet_ingot", "magical_magnet:gravity_core_charged", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
    }
})

-- Technic Craft Recipes
technic.register_alloy_recipe({
    input = {
        "magical_magnet:barite",
        "default:steel_ingot"
    },
    output = "magical_magnet:magnet_ingot 2",
    time = 4,
})


minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
    if itemstack:get_name() == "magical_magnet:magnet_off" then
        local meta = itemstack:get_meta()
        meta:set_int("magnet_radius", 3)  -- If you give yourself magnet_on, "magnet_radius" won't be set anyway
    end
    return itemstack
end)

-- /giveme magical_magnet:magnet_off
