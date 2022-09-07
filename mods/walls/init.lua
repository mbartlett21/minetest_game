walls = {}

local collision_extra = minetest.settings:get_bool("enable_fence_tall") and 3/8 or 0

walls.register = function(name, desc, texture_table, mat, sounds, w_groups)
    w_groups = w_groups or {}
    -- Common wall groups
	w_groups.wall = 1
	w_groups.cracky = 3
    
    -- For a single texture
	if type(texture_table) ~= "table" then
		texture_table = { texture_table }
	end
    
	-- Inventory node, and pole-type wall start item
	minetest.register_node(":walls:" .. name, {
		description = desc,
		drawtype = "nodebox",
		node_box = {
			type = "connected",
			fixed =         { -1/4,  -1/2, -1/4,   1/4,  1/2,  1/4  },
			connect_front = { -3/16, -1/2, -1/2,   3/16, 3/8, -1/4  },
			connect_left =  { -1/2,  -1/2, -3/16, -1/4,  3/8,  3/16 },
			connect_back =  { -3/16, -1/2,  1/4,   3/16, 3/8,  1/2  },
			connect_right = {  1/4,  -1/2, -3/16,  1/2,  3/8,  3/16 }
		},
		collision_box = {
			type = "connected",
			fixed =         { -1/4, -1/2, -1/4,  1/4, 1/2 + collision_extra,  1/4 },
			connect_front = { -1/4, -1/2, -1/2,  1/4, 1/2 + collision_extra, -1/4 },
			connect_left =  { -1/2, -1/2, -1/4, -1/4, 1/2 + collision_extra,  1/4 },
			connect_back =  { -1/4, -1/2,  1/4,  1/4, 1/2 + collision_extra,  1/2 },
			connect_right = {  1/4, -1/2, -1/4,  1/2, 1/2 + collision_extra,  1/4 }
		},
		connects_to = { "group:wall", "group:stone", "group:wood", "group:fence" },
		paramtype = "light",
		is_ground_content = false,
		tiles = texture_table,
		walkable = true,
		groups = w_groups,
		sounds = sounds,
	})

	-- crafting recipe
	minetest.register_craft({
		output = "walls:" .. name .. " 6",
		recipe = {
			{ '', '', '' },
			{ mat, mat, mat},
			{ mat, mat, mat},
		}
	})
end