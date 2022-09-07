-- WALL LEVER
-- Basically a switch that can be attached to a wall
-- Powers the block 2 nodes behind (using a receiver)
mesecons.register_node("mesecons_walllever:wall_lever", {
	description ="Lever",
	drawtype = "mesh",
	inventory_image = "jeija_wall_lever_inv.png",
	wield_image = "jeija_wall_lever_inv.png",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, 3/16, 8/16, 8/16, 8/16 },
	},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function (pos, node)
		if mesecons.flipstate(pos, node) == "on" then
			mesecons.receptor_on(pos, mesecons.rules.buttonlike_get(node))
		else
			mesecons.receptor_off(pos, mesecons.rules.buttonlike_get(node))
		end
		minetest.sound_play("mesecons_lever", {pos = pos})
	end
},{
	tiles = {
		"jeija_wall_lever_lever_light_off.png",
		"jeija_wall_lever_front.png",
		"jeija_wall_lever_front_bump.png",
		"jeija_wall_lever_back_edges.png"
	},
	mesh ="jeija_wall_lever_off.obj",
	on_rotate = mesecons.buttonlike_onrotate,
	mesecons = {receptor = {
		rules = mesecons.rules.buttonlike_get,
		state = mesecons.state.off
	}},
	groups = {dig_immediate = 2, mesecon_needs_receiver = 1, creative = 1}
},{
	tiles = {
		"jeija_wall_lever_lever_light_on.png",
		"jeija_wall_lever_front.png",
		"jeija_wall_lever_front_bump.png",
		"jeija_wall_lever_back_edges.png"
	},
	mesh ="jeija_wall_lever_on.obj",
	on_rotate = false,
	mesecons = {receptor = {
		rules = mesecons.rules.buttonlike_get,
		state = mesecons.state.on
	}},
	groups = {dig_immediate = 2, mesecon_needs_receiver = 1, not_in_creative_inventory = 1}
})

minetest.register_craft({
	output = "mesecons_walllever:wall_lever_off 2",
	recipe = {
	    {"group:mesecon_conductor_craftable"},
		{"group:stone"},
		{"group:stick"},
	}
})
