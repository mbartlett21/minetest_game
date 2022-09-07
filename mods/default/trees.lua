local random = math.random

--
-- Grow trees from saplings
--

-- 'can grow' function

function default.can_grow(pos)
	local node_under = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
	if not node_under then
		return false
	end
	local name_under = node_under.name
	local is_soil = minetest.get_item_group(name_under, "soil")
	if is_soil == 0 then
		return false
	end
	local light_level = minetest.get_node_light(pos)
	if not light_level or light_level < 13 then
		return false
	end
	return true
end


-- 'is snow nearby' function

local function is_snow_nearby(pos)
	return minetest.find_node_near(pos, 1, {"group:snowy"})
end


-- Grow sapling

function default.grow_sapling(pos)
	if not default.can_grow(pos) then
		-- try again 1 min later
		minetest.get_node_timer(pos):start(60)
		return
	end

    local worked = true
	local node = minetest.get_node(pos)
	if node.name == "default:sapling" then
        default.grow_new_apple_tree(pos)
	elseif node.name == "default:junglesapling" then
		default.grow_new_jungle_tree(pos)
	elseif node.name == "default:pine_sapling" then
		local snow = is_snow_nearby(pos)
		if snow then
			default.grow_new_snowy_pine_tree(pos)
		else
			default.grow_new_pine_tree(pos)
		end
	elseif node.name == "default:acacia_sapling" then
		default.grow_new_acacia_tree(pos)
	elseif node.name == "default:aspen_sapling" then
		default.grow_new_aspen_tree(pos)
	elseif node.name == "default:bush_sapling" then
		default.grow_bush(pos)
	elseif node.name == "default:blueberry_bush_sapling" then
		default.grow_blueberry_bush(pos)
	elseif node.name == "default:acacia_bush_sapling" then
		default.grow_acacia_bush(pos)
	elseif node.name == "default:pine_bush_sapling" then
		default.grow_pine_bush(pos)
	elseif node.name == "default:emergent_jungle_sapling" then
		default.grow_new_emergent_jungle_tree(pos)
    else
        worked = false
        minetest.log("warning", "[default] Invalid use of default.grow_sapling for " .. node.name)
	end
    if worked then
        minetest.log("action", "[default] " .. node.name .. " grows at "..
			minetest.pos_to_string(pos))
    end
end

minetest.register_lbm({
	name = "default:convert_saplings_to_node_timer",
	nodenames = {"default:sapling", "default:junglesapling",
			"default:pine_sapling", "default:acacia_sapling",
			"default:aspen_sapling"},
	action = function(pos)
		minetest.get_node_timer(pos):start(math.random(300, 1500))
	end
})

--
-- Tree generation
--


-- Apple tree

function default.grow_new_apple_tree(pos)
	local path = default.modpath ..
		"/schematics/apple_tree_from_sapling.mts"
	minetest.place_schematic({x = pos.x - 3, y = pos.y - 1, z = pos.z - 3},
		path, "random", nil, false)
end


-- Jungle tree

function default.grow_new_jungle_tree(pos)
	local path = default.modpath ..
		"/schematics/jungle_tree_from_sapling.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, "random", nil, false)
end


-- Emergent jungle tree

function default.grow_new_emergent_jungle_tree(pos)
	local path = default.modpath ..
		"/schematics/emergent_jungle_tree_from_sapling.mts"
	minetest.place_schematic({x = pos.x - 3, y = pos.y - 5, z = pos.z - 3},
		path, "random", nil, false)
end


-- Pine tree

function default.grow_new_pine_tree(pos)
	local path
	if math.random() > 0.5 then
		path = default.modpath ..
			"/schematics/pine_tree_from_sapling.mts"
	else
		path = default.modpath ..
			"/schematics/small_pine_tree_from_sapling.mts"
	end
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, "0", nil, false)
end


-- Snowy pine tree

function default.grow_new_snowy_pine_tree(pos)
	local path
	if math.random() > 0.5 then
		path = default.modpath ..
			"/schematics/snowy_pine_tree_from_sapling.mts"
	else
		path = default.modpath ..
			"/schematics/snowy_small_pine_tree_from_sapling.mts"
	end
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, "random", nil, false)
end


-- Acacia tree

function default.grow_new_acacia_tree(pos)
	local path = default.modpath ..
		"/schematics/acacia_tree_from_sapling.mts"
	minetest.place_schematic({x = pos.x - 4, y = pos.y - 1, z = pos.z - 4},
		path, "random", nil, false)
end


-- Aspen tree

function default.grow_new_aspen_tree(pos)
	local path = default.modpath ..
		"/schematics/aspen_tree_from_sapling.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, "0", nil, false)
end


-- Bushes do not need 'from sapling' schematic variants because
-- only the stem node is force-placed in the schematic.

-- Bush

function default.grow_bush(pos)
	local path = default.modpath ..
		"/schematics/bush.mts"
	minetest.place_schematic({x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		path, "0", nil, false)
end

-- Blueberry bush

function default.grow_blueberry_bush(pos)
	local path = default.modpath ..
		"/schematics/blueberry_bush.mts"
	minetest.place_schematic({x = pos.x - 1, y = pos.y, z = pos.z - 1},
		path, "0", nil, false)
end


-- Acacia bush

function default.grow_acacia_bush(pos)
	local path = default.modpath ..
		"/schematics/acacia_bush.mts"
	minetest.place_schematic({x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		path, "0", nil, false)
end


-- Pine bush

function default.grow_pine_bush(pos)
	local path = default.modpath ..
		"/schematics/pine_bush.mts"
	minetest.place_schematic({x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		path, "0", nil, false)
end


-- Large cactus

function default.grow_large_cactus(pos)
	local path = default.modpath ..
		"/schematics/large_cactus.mts"
	minetest.place_schematic({x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		path, "random", nil, false)
end


--
-- Sapling 'on place' function to check protection of node and resulting tree volume
--

function default.sapling_on_place(itemstack, placer, pointed_thing,
		sapling_name, minp_relative, maxp_relative, interval)
	-- Position of sapling
	local pos = pointed_thing.under
	local node = minetest.get_node_or_nil(pos)
	local pdef = node and minetest.registered_nodes[node.name]

	if pdef and pdef.on_rightclick and
			not (placer and placer:is_player() and
			placer:get_player_control().sneak) then
		return pdef.on_rightclick(pos, node, placer, itemstack, pointed_thing)
	end

	if not pdef or not pdef.buildable_to then
		pos = pointed_thing.above
		node = minetest.get_node_or_nil(pos)
		pdef = node and minetest.registered_nodes[node.name]
		if not pdef or not pdef.buildable_to then
			return itemstack
		end
	end

	local player_name = placer and placer:get_player_name() or ""
	-- Check sapling position for protection
	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return itemstack
	end
	-- Check tree volume for protection
	if minetest.is_area_protected(
			vector.add(pos, minp_relative),
			vector.add(pos, maxp_relative),
			player_name,
			interval) then
		minetest.record_protection_violation(pos, player_name)
		-- Print extra information to explain
		minetest.chat_send_player(player_name,
			itemstack:get_definition().description .. " will intersect protection " ..
			"on growth")
		return itemstack
	end

	minetest.log("action", "[default] " .. player_name .. " places node "
			.. sapling_name .. " at " .. minetest.pos_to_string(pos))

	local take_item = not creative.is_enabled_for(player_name)
	local newnode = {name = sapling_name}
	local ndef = minetest.registered_nodes[sapling_name]
	minetest.set_node(pos, newnode)

	-- Run callback
	if ndef and ndef.after_place_node then
		-- Deepcopy place_to and pointed_thing because callback can modify it
		if ndef.after_place_node(table.copy(pos), placer,
				itemstack, table.copy(pointed_thing)) then
			take_item = false
		end
	end

	-- Run script hook
	for _, callback in ipairs(minetest.registered_on_placenodes) do
		-- Deepcopy pos, node and pointed_thing because callback can modify them
		if callback(table.copy(pos), table.copy(newnode),
				placer, table.copy(node or {}),
				itemstack, table.copy(pointed_thing)) then
			take_item = false
		end
	end

	if take_item then
		itemstack:take_item()
	end

	return itemstack
end
