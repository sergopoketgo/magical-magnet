-- Add Translator
local S = minetest.get_translator("magical_magnet")


minetest.register_node("magical_magnet:sandstone_with_barite", {
	description = S("Barite Ore"),
	tiles = {"default_sandstone.png^magical_magnet_mineral_barite.png"},
	groups = {cracky = 2},
	drop = "magical_magnet:barite",
	sounds = default.node_sound_stone_defaults(),
})
