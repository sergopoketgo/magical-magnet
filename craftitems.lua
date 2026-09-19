-- Add Translator
local S = minetest.get_translator("magical_magnet")


minetest.register_craftitem("magical_magnet:barite", {
	description = S("Barite"),
	inventory_image = "magical_magnet_barite.png",
})

minetest.register_craftitem("magical_magnet:magnet_ingot", {
	description = S("Magnetic Ingot"),
    inventory_image = "magical_magnet_magnet_ingot.png",
})

minetest.register_craftitem("magical_magnet:gravity_core_uncharged", {
	description = S("Gravity Core"),
	inventory_image = "magical_magnet_gravity_core_uncharged.png",

})

minetest.register_craftitem("magical_magnet:gravity_core_charged", {
	description = S("Gravity Core (charged)"),
    inventory_image = "magical_magnet_gravity_core_charged.png",
    groups = { not_in_creative_inventory = 1 },
	light_source = 14,
})

--minetest.register_craftitem("magical_magnet:barite_dust", {
--	description = "Barite Dust",
--	inventory_image = "magical_magnet_barite_dust.png"
--})
--minetest.register_craftitem("magical_magnet:ferrite_dust", {
--	description = "Ferrite Dust",
--	inventory_image = "magical_magnet_ferrite_dust.png"
--})