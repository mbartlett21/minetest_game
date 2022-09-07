creative = {}

local function update_sfinv(name)
	minetest.after(0, function()
		local player = minetest.get_player_by_name(name)
		if player then
			if sfinv.get_page(player):sub(1, 9) == "creative:" then
				sfinv.set_page(player, sfinv.get_homepage_name(player))
			else
				sfinv.set_player_inventory_formspec(player)
			end
		end
	end)
end

-- Creative inventory will show all items with groups not_in_creative_inventory ~= 1 and creative == 1
minetest.register_privilege("creative", {
	description = "Allow player to use creative inventory",
	give_to_singleplayer = false,
	give_to_admin = false,
	on_grant = update_sfinv,
	on_revoke = update_sfinv
})

-- Full creative inventory will show all items with group not_in_creative_inventory ~= 1
minetest.register_privilege("creative_full", {
	description = "Allow player to access full creative inventory.  Cannot be used without creative being granted as well.",
	give_to_singleplayer = false,
	give_to_admin = false,
	on_grant = update_sfinv,
	on_revoke = update_sfinv,
})

minetest.register_privilege("creative_unlimited", {
	description = "Allow player to use unlimited creative inventory without refilling. Cannot be used without creative being granted as well.",
	give_to_singleplayer = false,
	give_to_admin = false,
	on_grant = update_sfinv,
	on_revoke = update_sfinv,
})

local creative_mode_cache = minetest.settings:get_bool("creative_mode")
local creative_mode_full_cache = minetest.settings:get_bool("creative_mode_full")

function creative.is_unlimited_enabled_for(name)
	return creative.is_std_enabled_for(name) and minetest.check_player_privs(name, { creative_unlimited = true })
end

creative.is_enabled_for = creative.is_unlimited_enabled_for

function creative.is_std_enabled_for(name)
	return creative_mode_cache or minetest.check_player_privs(name, { creative = true })
end

function creative.is_full_enabled_for(name)
	return creative.is_std_enabled_for(name) and (creative_mode_full_cache or minetest.check_player_privs(name, { creative_full = true }))
end

function creative.add_to_inventory(player, item, pos)
    local inv = player:get_inventory()
    if creative.is_enabled_for(player:get_player_name()) and not inv:contains_item("main", item) then
        return
    end
    local left = inv:add_item("main", item)
    if not left:is_empty() then
        minetest.add_item(pos, left)
    end
end

function creative.take_from_inventory(player, itemstack)
    local player_name = player and player:get_player_name() or ""
    if not creative.is_enabled_for(player_name) then
        itemstack:take_item()
    end
    return itemstack
end

dofile(minetest.get_modpath("creative") .. "/inventory.lua")

if creative_mode_cache then
	-- Dig time is modified according to difference (leveldiff) between tool
	-- 'maxlevel' and node 'level'. Digtime is divided by the larger of
	-- leveldiff and 1.
	-- To speed up digging in creative, hand 'maxlevel' and 'digtime' have been
	-- increased such that nodes of differing levels have an insignificant
	-- effect on digtime.
	local digtime = 42
	local caps = {times = {digtime, digtime, digtime}, uses = 0, maxlevel = 256}

	minetest.register_item(":", {
		type = "none",
		wield_image = "wieldhand.png",
		wield_scale = {x = 1, y = 1, z = 2.5},
		range = 10,
		tool_capabilities = {
			full_punch_interval = 0.5,
			max_drop_level = 3,
			groupcaps = {
				crumbly = caps,
				cracky  = caps,
				snappy  = caps,
				choppy  = caps,
				oddly_breakable_by_hand = caps,
			},
			damage_groups = {fleshy = 10},
		}
	})
end

-- Unlimited node placement
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack)
	if placer and placer:is_player() then
		return creative.is_unlimited_enabled_for(placer:get_player_name())
	end
end)

-- Don't pick up if the item is already in the inventory
local old_handle_node_drops = minetest.handle_node_drops
function minetest.handle_node_drops(pos, drops, digger)
	if not digger or not digger:is_player() or
		not creative.is_unlimited_enabled_for(digger:get_player_name()) then
		return old_handle_node_drops(pos, drops, digger)
	end
	local inv = digger:get_inventory()
	if inv then
		for _, item in ipairs(drops) do
			if not inv:contains_item("main", item, true) then
				inv:add_item("main", item)
			end
		end
	end
end
