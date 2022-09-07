local stuff_to_add = {
    "default:pick_stone",
    "default:axe_stone",
    "default:torch 99"
}

give_initial_stuff = {
	items = {}
}

function give_initial_stuff.give(player)
	minetest.log("action", "[give_initial_stuff] Giving initial stuff to player " .. player:get_player_name())
	local inv = player:get_inventory()
	for _, stack in ipairs(give_initial_stuff.items) do
		inv:add_item("main", stack)
	end
end

function give_initial_stuff.add(stack)
	give_initial_stuff.items[#give_initial_stuff.items + 1] = ItemStack(stack)
end

function give_initial_stuff.clear()
	give_initial_stuff.items = {}
end

function give_initial_stuff.set_list(list)
	give_initial_stuff.items = list
end

function give_initial_stuff.get_list()
	return give_initial_stuff.items
end

for _, itemstack in ipairs(stuff_to_add) do
    give_initial_stuff.add(itemstack)
end
if minetest.settings:get_bool("give_initial_stuff") then
	minetest.register_on_newplayer(give_initial_stuff.give)
end
