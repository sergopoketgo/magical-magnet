-- Common Craft Recipes
minetest.register_craft({
    output = "magical_magnet:inert_gravity_core",
    recipe = {
        {"stardust:stardust", "basic_materials:energy_crystal_simple", "stardust:stardust"},
        {"magical_magnet:magnet_ingot", "magic_materials:void_rune", "magical_magnet:magnet_ingot"},
        {"stardust:stardust", "basic_materials:energy_crystal_simple", "stardust:stardust"},
    }
})

minetest.register_craft({
    output = "magical_magnet:magnet_off",
    recipe = {
        {"magical_magnet:magnet_ingot", "magical_magnet:inert_gravity_core", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
    },
    on_craft = function(itemstack, player, old_craft_grid, craft_inv)
        itemstack:get_meta():set_int("magnet_radius", 3)
        return itemstack
    end,
})

minetest.register_craft({
    output = "magical_magnet:magnet_on",
    recipe = {
        {"magical_magnet:magnet_ingot", "magical_magnet:charged_gravity_core", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
        {"magical_magnet:magnet_ingot", "", "magical_magnet:magnet_ingot"},
    },
    on_craft = function(itemstack, player, old_craft_grid, craft_inv)
        itemstack:get_meta():set_int("magnet_radius", 3)
        return itemstack
    end,
})

-- Technic Craft Recipes
technic.register_alloy_recipe({
    input = {
        "magical_magnet:barite",
        "default:steel_ingot"
    },
    output = "magical_magnet:magnet_ingot",
    time = 4,
})


minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
    if itemstack:get_name() == "magical_magnet:magnet_off" or itemstack:get_name() == "magical_magnet:magnet_on" then
        local meta = itemstack:get_meta()
        meta:set_int("magnet_radius", 3)
        if itemstack:get_name() == "magical_magnet:magnet_off" then
            itemstack:set_wear(65535)
        end
    end
    return itemstack
end)
