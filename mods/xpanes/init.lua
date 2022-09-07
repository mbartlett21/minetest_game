
local function is_pane(node)
	return minetest.get_item_group(node.name, "pane") > 0
end

local function connects_dir(pos, name, dir)
	local aside = vector.add(pos, minetest.facedir_to_dir(dir))
	if is_pane(minetest.get_node(aside)) then
		return true
	end

	local connects_to = minetest.registered_nodes[name].connects_to
	if not connects_to then
		return false
	end
	local list = minetest.find_nodes_in_area(aside, aside, connects_to)

	if #list > 0 then
		return true
	end

	return false
end

local function swap_pane(pos, node, param2)
	if node.param2 == param2 then
		return
	end

	minetest.swap_node(pos, {name = node.name, param2 = param2})
end

local function update_pane(pos, node)
	if not is_pane(node) then
		return
	end
	local node = minetest.get_node(pos)
	local name = node.name

	local any = node.param2
	local c = {}
	local count = 0
	for dir = 0, 3 do
		c[dir] = connects_dir(pos, name, dir)
		if c[dir] then
			any = dir
			count = count + 1
		end
	end

	if count ~= 0 then
        swap_pane(pos, node, (any + 1) % 2)
	end
end

minetest.register_on_placenode(function(pos, node)
	if minetest.get_item_group(node, "pane") > 0 then
		update_pane(pos, node)
	end
	for i = 0, 3 do
		local dir = minetest.facedir_to_dir(i)
        local new_pos = vector.add(pos, dir)
		update_pane(new_pos, minetest.get_node(new_pos))
	end
end)

minetest.register_on_dignode(function(pos)
	for i = 0, 3 do
		local dir = minetest.facedir_to_dir(i)
        local new_pos = vector.add(pos, dir)
		update_pane(new_pos, minetest.get_node(new_pos))
	end
end)

xpanes = {}
function xpanes.register_pane(name, def)

	local flatgroups = table.copy(def.groups)
	flatgroups.pane = 1
	minetest.register_node(":xpanes:" .. name, {
		description = def.description,
		drawtype = "nodebox",
		paramtype = "light",
		is_ground_content = false,
		sunlight_propagates = true,
		inventory_image = def.inventory_image,
		wield_image = def.wield_image,
		paramtype2 = "facedir",
		tiles = {def.textures[2], def.textures[2], def.textures[1]},
		groups = flatgroups,
		sounds = def.sounds,
		use_texture_alpha = def.use_texture_alpha or false,
		node_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}
		},
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/32, 1/2, 1/2, 1/32}
		},
		connect_sides = { "left", "right" },
	})

	minetest.register_craft({
		output = "xpanes:" .. name .. " 16",
		recipe = def.recipe
	})
end

xpanes.register_pane("glass", {
	description = "Glass Pane",
	textures = {"default_glass.png","xpanes_edge.png"},
	inventory_image = "default_glass.png",
	wield_image = "default_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = {snappy = 2, cracky = 3, oddly_breakable_by_hand = 3, creative = 1},
	recipe = {
		{"default:glass", "default:glass", "default:glass"},
		{"default:glass", "default:glass", "default:glass"}
	}
})

xpanes.register_pane("obsidian_glass", {
	description = "Obsidian Glass Pane",
	textures = {"default_obsidian_glass.png","xpanes_edge_obsidian.png"},
	inventory_image = "default_obsidian_glass.png",
	wield_image = "default_obsidian_glass.png",
	sounds = default.node_sound_glass_defaults(),
	groups = {snappy = 2, cracky = 3},
	recipe = {
		{"default:obsidian_glass", "default:obsidian_glass", "default:obsidian_glass"},
		{"default:obsidian_glass", "default:obsidian_glass", "default:obsidian_glass"}
	}
})

--[[xpanes.register_pane("bar", {
	description = "Steel Bars",
	textures = {"xpanes_bar.png","xpanes_bar_top.png"},
	inventory_image = "xpanes_bar.png",
	wield_image = "xpanes_bar.png",
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
	}
})]]
