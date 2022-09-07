craftguide = {}

local function update_sfinv(name)
	minetest.after(0, function()
		local player = minetest.get_player_by_name(name)
		if player then
			if sfinv.get_page(player):sub(1, 9) == "craftguide:" then
				sfinv.set_page(player, sfinv.get_homepage_name(player))
			else
				sfinv.set_player_inventory_formspec(player)
			end
		end
	end)
end

minetest.register_privilege("craftguide", {
	description = "Allow player to use crafting guide",
	give_to_singleplayer = false,
	give_to_admin = false,
	on_grant = update_sfinv,
	on_revoke = update_sfinv
})

local craftguide_cache = minetest.settings:get_bool("craftguide")

function craftguide.is_enabled_for(name)
	return craftguide_cache or minetest.check_player_privs(name, { craftguide = true })
end

dofile(minetest.get_modpath("craftguide") .. "/guide.lua")