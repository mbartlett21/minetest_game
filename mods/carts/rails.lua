local default_rail_rules = {
	{x = 0,  y = 0,  z = -1},
	{x = 1,  y = 0,  z = 0},
	{x = -1, y = 0,  z = 0},
	{x = 0,  y = 0,  z = 1},
    -- Conduct directly above if there is a button there
	{x = 0,  y = 1, z = 0},
}

carts:register_rail("carts:rail", {
        description = "Rail",
        tiles = {
            "carts_rail_straight.png", "carts_rail_curved.png",
            "carts_rail_t_junction_left.png", "carts_rail_crossing.png"
        },
        inventory_image = "carts_rail_straight.png",
        wield_image = "carts_rail_straight.png",
        groups = carts:get_rail_groups({ creative = 1 }),
        mesecons = {effector = {
                rules = default_rail_rules,
                action_on = function (pos, node)
                    node.name = "carts:rail_on"
                    minetest.swap_node(pos, node)
                end,
        }},
}, {t_left = true})

carts:register_rail("carts:rail_on", {
        description = "Rail",
        tiles = {
            "carts_rail_straight.png", "carts_rail_curved.png",
            "carts_rail_t_junction_right.png", "carts_rail_crossing.png"
        },
        inventory_image = "carts_rail_straight.png",
        wield_image = "carts_rail_straight.png",
        groups = carts:get_rail_groups({ not_in_creative_inventory = 1 }),
        drop = "carts:rail",
        mesecons = {effector = {
                rules = default_rail_rules,
                action_off = function (pos, node)
                    node.name = "carts:rail_on"
                    minetest.swap_node(pos, node)
                end,
        }},
}, {t_right = true})

minetest.register_craft({
	output = "carts:rail 18",
	recipe = {
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
	}
})

local powerrail_rules = {
    -- Standard rules and directly above
	{x = 0,  y = 0,  z = -1},
	{x = 1,  y = 0,  z = 0},
	{x = -1, y = 0,  z = 0},
	{x = 0,  y = 0,  z = 1},

	{x = 0,  y = 1,  z = -1},
	{x = 1,  y = 1,  z = 0},
	{x = -1, y = 1,  z = 0},
	{x = 0,  y = 1,  z = 1},

	{x = 0,  y = -1,  z = -1},
	{x = 1,  y = -1,  z = 0},
	{x = -1, y = -1,  z = 0},
	{x = 0,  y = -1,  z = 1},

	{x = 0,  y = 1, z = 0},
}

carts:register_rail("carts:powerrail_off", {
	description = "Powered Rail",
	tiles = {
		"carts_rail_straight_pwr_off.png", "carts_rail_curved_pwr_off.png",
		"carts_rail_straight_pwr_off.png", "carts_rail_crossing_pwr_off.png"
	},
	groups = carts:get_rail_groups({ creative = 1 }),
    mesecons = {conductor = {
		state = mesecons.state.off,
		onstate = "carts:powerrail_on",
		rules = powerrail_rules
	}},
    on_blast = mesecons.on_blastnode,
}, {acceleration = -3})

carts:register_rail("carts:powerrail_on", {
	description = "Powered Rail",
	tiles = {
		"carts_rail_straight_pwr.png", "carts_rail_curved_pwr.png",
		"carts_rail_straight_pwr.png", "carts_rail_crossing_pwr.png"
	},
	light_source = 5,
	groups = carts:get_rail_groups({ not_in_creative_inventory = 1 }),
    drop = "carts:powerrail_off",
    mesecons = {conductor = {
		state = mesecons.state.on,
		offstate = "carts:powerrail_off",
		rules = powerrail_rules
	}},
    on_blast = mesecons.on_blastnode,
}, {acceleration = 5})

minetest.register_craft({
	output = "carts:powerrail_off 18",
	recipe = {
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
		{"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
	}
})