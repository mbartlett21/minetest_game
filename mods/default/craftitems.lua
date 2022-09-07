-- mods/default/craftitems.lua

minetest.register_craftitem("default:stick", {
	description = "Stick",
	inventory_image = "default_stick.png",
	groups = {stick = 1, flammable = 2, creative = 1},
})

minetest.register_craftitem("default:paper", {
	description = "Paper",
	inventory_image = "default_paper.png",
	groups = {flammable = 3, creative = 1},
})

minetest.register_craftitem("default:skeleton_key", {
	description = "Skeleton Key",
	inventory_image = "default_key_skeleton.png",
	groups = {key = 1},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = pointed_thing.under
		local node = minetest.get_node(pos)

		if not node then
			return itemstack
		end

		local on_skeleton_key_use = minetest.registered_nodes[node.name].on_skeleton_key_use
		if not on_skeleton_key_use then
			return itemstack
		end

		-- make a new key secret in case the node callback needs it
		local random = math.random
		local newsecret = string.format(
			"%04x%04x%04x%04x",
			random(2^16) - 1, random(2^16) - 1,
			random(2^16) - 1, random(2^16) - 1)

		local secret, _, _ = on_skeleton_key_use(pos, user, newsecret)

		if secret then
			local inv = minetest.get_inventory({type ="player", name = user:get_player_name()})

			-- update original itemstack
			itemstack:take_item()

			-- finish and return the new key
			local new_stack = ItemStack("default:key")
			local meta = new_stack:get_meta()
			meta:set_string("secret", secret)
			meta:set_string("description", "Key to "..user:get_player_name().."'s "
				..minetest.registered_nodes[node.name].description)

			if itemstack:get_count() == 0 then
				itemstack = new_stack
			else
				if inv:add_item("main", new_stack):get_count() > 0 then
					minetest.add_item(user:get_pos(), new_stack)
				end -- else: added to inventory successfully
			end

			return itemstack
		end
	end
})

minetest.register_craftitem("default:coal_lump", {
	description = "Coal Lump",
	inventory_image = "default_coal_lump.png",
	groups = {coal = 1, flammable = 1, creative = 1}
})

minetest.register_craftitem("default:iron_lump", {
	description = "Iron Lump",
	inventory_image = "default_iron_lump.png",
})

minetest.register_craftitem("default:copper_lump", {
	description = "Copper Lump",
	inventory_image = "default_copper_lump.png",
})

minetest.register_craftitem("default:tin_lump", {
	description = "Tin Lump",
	inventory_image = "default_tin_lump.png",
})

minetest.register_craftitem("default:mese_crystal", {
	description = "Mese Crystal",
	inventory_image = "default_mese_crystal.png",
})

minetest.register_craftitem("default:gold_lump", {
	description = "Gold Lump",
	inventory_image = "default_gold_lump.png",
})

minetest.register_craftitem("default:diamond", {
	description = "Diamond",
	inventory_image = "default_diamond.png",
})

minetest.register_craftitem("default:clay_lump", {
	description = "Clay Lump",
	inventory_image = "default_clay_lump.png",
})

minetest.register_craftitem("default:steel_ingot", {
	description = "Steel Ingot",
	inventory_image = "default_steel_ingot.png",
})

minetest.register_craftitem("default:copper_ingot", {
	description = "Copper Ingot",
	inventory_image = "default_copper_ingot.png",
})

minetest.register_craftitem("default:tin_ingot", {
	description = "Tin Ingot",
	inventory_image = "default_tin_ingot.png",
})

minetest.register_craftitem("default:gold_ingot", {
	description = "Gold Ingot",
	inventory_image = "default_gold_ingot.png"
})

minetest.register_craftitem("default:clay_brick", {
	description = "Clay Brick",
	inventory_image = "default_clay_brick.png",
})

minetest.register_craftitem("default:obsidian_shard", {
	description = "Obsidian Shard",
	inventory_image = "default_obsidian_shard.png",
})

minetest.register_craftitem("default:flint", {
	description = "Flint",
	inventory_image = "default_flint.png"
})

minetest.register_craftitem("default:blueberries", {
	description = "Blueberries",
	inventory_image = "default_blueberries.png",
	on_use = minetest.item_eat(2),
    groups = {creative = 1}
})
