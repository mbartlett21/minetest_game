-- WALL BUTTON
-- A button that when pressed emits power for 1 second
-- and then turns off again

mesecons.button_turnoff = function (pos)
	local node = minetest.get_node(pos)
	if node.name ~= "mesecons:button_on" then -- has been dug
		return
	end
	minetest.swap_node(pos, {name = "mesecons:button_off", param2 = node.param2})
	minetest.sound_play("mesecons_button_pop", {pos = pos})
	local rules = mesecons.rules.buttonlike_get(node)
	mesecons.receptor_off(pos, rules)
end

minetest.register_node(":mesecons:button_off", {
	drawtype = "nodebox",
	tiles = {
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_off.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = mesecons.buttonlike_onrotate,
	sunlight_propagates = true,
	selection_box = {
	type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
		type = "fixed",
		fixed = {
		{ -6/16, -6/16, 6/16, 6/16, 6/16, 8/16 },	-- the thin plate behind the button
		{ -4/16, -2/16, 4/16, 4/16, 2/16, 6/16 }	-- the button itself
	}
	},
	groups = {dig_immediate = 2, mesecon_needs_receiver = 1, creative = 1},
	description = "Button",
	on_rightclick = function (pos, node)
		minetest.swap_node(pos, {name = "mesecons_button:button_on", param2 = node.param2})
		mesecons.receptor_on(pos, mesecons.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_button_push", {pos = pos})
		minetest.get_node_timer(pos):start(1)
	end,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecons.state.off,
		rules = mesecons.rules.buttonlike_get
	}},
	on_blast = mesecons.on_blastnode,
})

minetest.register_node(":mesecons:button_on", {
	drawtype = "nodebox",
	tiles = {
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_on.png"
		},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = false,
	light_source = 7,
	sunlight_propagates = true,
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
	type = "fixed",
	fixed = {
		{ -6/16, -6/16,  6/16, 6/16, 6/16, 8/16 },
		{ -4/16, -2/16, 11/32, 4/16, 2/16, 6/16 }
	}
    },
	groups = {dig_immediate = 2, not_in_creative_inventory = 1, mesecon_needs_receiver = 1},
	drop = "mesecons:button_off",
	description = "Button",
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecons.state.on,
		rules = mesecons.rules.buttonlike_get
	}},
	on_timer = mesecons.button_turnoff,
	on_blast = mesecons.on_blastnode,
})

minetest.register_alias("mesecons:button", "mesecons:button_off")

minetest.register_alias("mesecons_button:button_off", "mesecons:button_off")
minetest.register_alias("mesecons_button:button_on", "mesecons:button_on")

minetest.register_craft({
	output = "mesecons:button_off 2",
	recipe = {
		{"group:mesecon_conductor_craftable","group:stone"},
	}
})
