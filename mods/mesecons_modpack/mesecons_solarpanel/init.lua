-- Solar Panel
minetest.register_node("mesecons_solarpanel:on", {
	drawtype = "nodebox",
	tiles = { "jeija_solar_panel.png", },
	inventory_image = "jeija_solar_panel.png",
	wield_image = "jeija_solar_panel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	is_ground_content = false,
	node_box = {
		type = "wallmounted",
		wall_bottom = { -7/16, -8/16, -7/16,  7/16, -7/16, 7/16 },
		wall_top    = { -7/16,  7/16, -7/16,  7/16,  8/16, 7/16 },
		wall_side   = { -8/16, -7/16, -7/16, -7/16,  7/16, 7/16 },
	},
	selection_box = {
		type = "wallmounted",
		wall_bottom = { -7/16, -8/16, -7/16,  7/16, -7/16, 7/16 },
		wall_top    = { -7/16,  7/16, -7/16,  7/16,  8/16, 7/16 },
		wall_side   = { -8/16, -7/16, -7/16, -7/16,  7/16, 7/16 },
	},
	drop = "mesecons_solarpanel:off",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	sounds = default.node_sound_glass_defaults(),
	mesecons = {receptor = {
		state = mesecons.state.on,
		rules = mesecons.rules.wallmounted_get,
	}},
	on_blast = mesecons.on_blastnode,
})

-- Solar Panel
minetest.register_node("mesecons_solarpanel:off", {
	drawtype = "nodebox",
	tiles = { "jeija_solar_panel.png", },
	inventory_image = "jeija_solar_panel.png",
	wield_image = "jeija_solar_panel.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	is_ground_content = false,
	node_box = {
		type = "wallmounted",
		wall_bottom = { -7/16, -8/16, -7/16,  7/16, -7/16, 7/16 },
		wall_top    = { -7/16,  7/16, -7/16,  7/16,  8/16, 7/16 },
		wall_side   = { -8/16, -7/16, -7/16, -7/16,  7/16, 7/16 },
	},
	selection_box = {
		type = "wallmounted",
		wall_bottom = { -7/16, -8/16, -7/16,  7/16, -7/16, 7/16 },
		wall_top    = { -7/16,  7/16, -7/16,  7/16,  8/16, 7/16 },
		wall_side   = { -8/16, -7/16, -7/16, -7/16,  7/16, 7/16 },
	},
	groups = {dig_immediate = 3, creative = 1},
	description = "Solar Panel",
	sounds = default.node_sound_glass_defaults(),
	mesecons = {receptor = {
		state = mesecons.state.off,
		rules = mesecons.rules.wallmounted_get,
	}},
	on_blast = mesecons.on_blastnode,
})

minetest.register_alias("mesecons:solarpanel", "mesecons_solarpanel:off")

minetest.register_craft({
	output = "mesecons_solarpanel:off 1",
	recipe = {
		{"mesecons_materials:silicon", "mesecons_materials:silicon"},
		{"mesecons_materials:silicon", "mesecons_materials:silicon"},
	}
})

minetest.register_abm(
	{nodenames = {"mesecons_solarpanel:off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local light = minetest.get_node_light(pos, nil)

		if light >= 12 then
			node.name = "mesecons_solarpanel:on"
			minetest.swap_node(pos, node)
			mesecons.receptor_on(pos, mesecons.rules.wallmounted_get(node))
		end
	end,
})

minetest.register_abm(
	{nodenames = {"mesecons_solarpanel:on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local light = minetest.get_node_light(pos, nil)

		if light < 12 then
			node.name = "mesecons_solarpanel:off"
			minetest.swap_node(pos, node)
			mesecons.receptor_off(pos, mesecons.rules.wallmounted_get(node))
		end
	end,
})
