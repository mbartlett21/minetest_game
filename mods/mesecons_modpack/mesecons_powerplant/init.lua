-- The POWER_PLANT
-- Just emits power. always.

minetest.register_node("mesecons_powerplant:power_plant", {
	drawtype = "plantlike",
	visual_scale = 1,
	tiles = {"jeija_power_plant.png"},
	inventory_image = "jeija_power_plant.png",
	paramtype = "light",
	is_ground_content = false,
	walkable = false,
	groups = {dig_immediate = 3, mesecon = 2, creative = 1},
	light_source = 5,
    	description ="Power Plant",
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, -0.5+0.7, 0.3},
	},
	sounds = default.node_sound_leaves_defaults(),
	mesecons = {receptor = {
		state = mesecons.state.on
	}},
	on_blast = mesecons.on_blastnode,
})

minetest.register_alias("mesecons:power_plant", "mesecons_powerplant:power_plant")

minetest.register_craft({
	output = "mesecons:power_plant 1",
	recipe = {
		{"group:mesecon_conductor_craftable"},
		{"group:mesecon_conductor_craftable"},
		{"group:sapling"},
	}
})
