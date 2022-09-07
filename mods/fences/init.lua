fences = {}

local collision_extra = minetest.settings:get_bool("enable_fence_tall") and 3/8 or 0

-- Registers a fence fences:<name>
fences.register = function(name, desc, texture_table, mat, sounds, f_groups, fence_texture)
    -- Common fence groups
	f_groups.fence = 1
    
    -- For a single texture
	if type(texture_table) ~= "table" then
		texture_table = { texture_table }
	end
    
    if not fence_texture then
        fence_texture = "default_fence_overlay.png^" .. texture_table[1] ..
			"^default_fence_overlay.png^[makealpha:255,126,126"
    end
    
	-- Inventory node, and pole-type fence start item
	minetest.register_node(":fences:" .. name, {
		description = desc,
		drawtype = "nodebox",
		node_box = {
			type = "connected",
			fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2, 1/8}},
			-- connect_top =
			-- connect_bottom =
			connect_front = {{-1/16,3/16,-1/2,1/16,5/16,-1/8},
				{-1/16,-5/16,-1/2,1/16,-3/16,-1/8}},
			connect_left = {{-1/2,3/16,-1/16,-1/8,5/16,1/16},
				{-1/2,-5/16,-1/16,-1/8,-3/16,1/16}},
			connect_back = {{-1/16,3/16,1/8,1/16,5/16,1/2},
				{-1/16,-5/16,1/8,1/16,-3/16,1/2}},
			connect_right = {{1/8,3/16,-1/16,1/2,5/16,1/16},
				{1/8,-5/16,-1/16,1/2,-3/16,1/16}},
		},
		collision_box = {
			type = "connected",
			fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2 + collision_extra, 1/8}},
			-- connect_top =
			-- connect_bottom =
			connect_front = {{-1/8,-1/2,-1/2,1/8,1/2 + collision_extra,-1/8}},
			connect_left = {{-1/2,-1/2,-1/8,-1/8,1/2 + collision_extra,1/8}},
			connect_back = {{-1/8,-1/2,1/8,1/8,1/2 + collision_extra,1/2}},
			connect_right = {{1/8,-1/2,-1/8,1/2,1/2 + collision_extra,1/8}},
		},
		connects_to = { "group:wall", "group:stone", "group:wood", "group:fence" },
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		tiles = texture_table,
		walkable = true,
		groups = f_groups,
		sounds = sounds,
		inventory_image = fence_texture,
		wield_image = fence_texture
	})

	-- crafting recipe
	minetest.register_craft({
		output = "fences:" .. name .. " 4",
		recipe = {
			{ mat, 'group:stick', mat },
			{ mat, 'group:stick', mat },
		}
	})
end

-- Registers a fence rail fences:<name>_rail
fences.register_rail = function(name, desc, texture_table, mat, sounds, f_groups, fence_texture)
    -- Common fence groups
	f_groups.fence = 1
    
    -- For a single texture
	if type(texture_table) ~= "table" then
		texture_table = { texture_table }
	end
    
    if not fence_texture then
        fence_texture = "default_fence_rail_overlay.png^" .. texture_table[1] ..
			"^default_fence_rail_overlay.png^[makealpha:255,126,126"
    end
    
	-- Inventory node, and pole-type rail start item
	minetest.register_node(":fences:" .. name .. "_rail", {
		description = desc,
		drawtype = "nodebox",
		node_box = {
			type = "connected",
			fixed = {
				{-1/16,  3/16, -1/16, 1/16,  5/16, 1/16},
				{-1/16, -3/16, -1/16, 1/16, -5/16, 1/16}
			},
			-- connect_top =
			-- connect_bottom =
			connect_front = {
				{-1/16,  3/16, -1/2, 1/16,  5/16, -1/16},
				{-1/16, -5/16, -1/2, 1/16, -3/16, -1/16}},
			connect_left = {
				{-1/2,  3/16, -1/16, -1/16,  5/16, 1/16},
				{-1/2, -5/16, -1/16, -1/16, -3/16, 1/16}},
			connect_back = {
				{-1/16,  3/16, 1/16, 1/16,  5/16, 1/2},
				{-1/16, -5/16, 1/16, 1/16, -3/16, 1/2}},
			connect_right = {
				{1/16,  3/16, -1/16, 1/2,  5/16, 1/16},
				{1/16, -5/16, -1/16, 1/2, -3/16, 1/16}},
		},
		collision_box = {
			type = "connected",
			fixed = {{-1/8, -1/2, -1/8, 1/8, 1/2 + collision_extra, 1/8}},
			-- connect_top =
			-- connect_bottom =
			connect_front = {{-1/8,-1/2,-1/2,1/8,1/2 + collision_extra,-1/8}},
			connect_left = {{-1/2,-1/2,-1/8,-1/8,1/2 + collision_extra,1/8}},
			connect_back = {{-1/8,-1/2,1/8,1/8,1/2 + collision_extra,1/2}},
			connect_right = {{1/8,-1/2,-1/8,1/2,1/2 + collision_extra,1/8}},
		},
		connects_to = { "group:wall", "group:stone", "group:wood", "group:fence" },
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		tiles = texture_table,
		walkable = true,
		groups = f_groups,
		sounds = sounds,
		inventory_image = fence_texture,
		wield_image = fence_texture
	})

	-- crafting recipe
	minetest.register_craft({
		output = "fences:" .. name .. "_rail 16",
		recipe = {
			{ mat, mat },
			{ "", ""},
			{ mat, mat },
		}
	})
end

-- Registers a fence gate fences:<name>_gate_closed, fences:<name>_gate_open
fences.register_gate = function(name, desc, texture_table, mat, sounds, f_groups)
    -- Common fence groups
	f_groups.fence = 1
    
    local gate_table = {
		description = desc,
		drawtype = "mesh",
		tiles = {},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = "fences:" .. name .. "_gate_closed",
		connect_sides = {"left", "right"},
		groups = f_groups,
		sounds = sounds,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			local node_def = minetest.registered_nodes[node.name]
			minetest.swap_node(pos, {name = node_def.gate, param2 = node.param2})
			minetest.sound_play(node_def.sound, {pos = pos, gain = 0.3,
				max_hear_distance = 8})
			return itemstack
		end,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/4, 1/2, 1/2, 1/4},
		},
	}
    
	if type(texture_table) == "string" then
		gate_table.tiles[1] = {name = texture_table, backface_culling = true}
	elseif texture_table.backface_culling == nil then
		gate_table.tiles[1] = table.copy(texture_table)
		gate_table.tiles[1].backface_culling = true
	else
		gate_table.tiles[1] = texture_table
	end

	local fence_closed = table.copy(gate_table)
	fence_closed.mesh = "doors_fencegate_closed.obj"
	fence_closed.gate = "fences:" .. name .. "_gate_open"
	fence_closed.sound = "doors_fencegate_open"
	fence_closed.collision_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/4, 1/2, 1/2 + collision_extra, 1/4},
	}

	local fence_open = table.copy(gate_table)
	fence_open.mesh = "doors_fencegate_open.obj"
	fence_open.gate = "fences:" .. name .. "_gate_closed"
	fence_open.sound = "doors_fencegate_close"
	fence_open.groups.not_in_creative_inventory = 1
	fence_open.collision_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/4, -3/8, 1/2 + collision_extra, 1/4},
            -- The gate is not as tall as the fence, so it can be jumped over when open
			{-1/2, -3/8, -1/2, -3/8, 3/8, 0}},
	}
    

	minetest.register_node(":fences:" .. name .. "_gate_closed", fence_closed)
	minetest.register_node(":fences:" .. name .. "_gate_open", fence_open)

	minetest.register_craft({
		output = "fences:" .. name .. "_gate_closed",
		recipe = {
			{"group:stick", mat, "group:stick"},
			{"group:stick", mat, "group:stick"}
		}
	})
end