local GET_COMMAND = "GET"

-- Object detector
-- Detects players in a certain radius
-- The radius can be specified with mesecons_player_detector_radius

local function object_detector_make_formspec(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", "size[9,2.5]" ..
		"field[0.3,  0;9,2;scanname;Name of player to scan for (empty for any):;${scanname}]"..
		"button_exit[7,0.75;2,3;;Save]")
end

local function object_detector_on_receive_fields(pos, formname, fields, sender)
	if not fields.scanname then return end

	if minetest.is_protected(pos, sender:get_player_name()) then return end

	local meta = minetest.get_meta(pos)
	meta:set_string("scanname", fields.scanname or "")
	object_detector_make_formspec(pos)
end

-- returns true if player was found, false if not
local function object_detector_scan(pos)
	local objs = minetest.get_objects_inside_radius(pos, tonumber(minetest.settings:get("mesecons_player_detector_radius") or 6))

	-- abort if no scan results were found
	if next(objs) == nil then return false end

	local scanname = minetest.get_meta(pos):get_string("scanname")
	local scan_for = {}
	for _, str in pairs(string.split(scanname:gsub(" ", ""), ",")) do
		scan_for[str] = true
	end

	local every_player = scanname == ""
	for _, obj in pairs(objs) do
		-- "" is returned if it is not a player; "" ~= nil; so only handle objects with foundname ~= ""
		local foundname = obj:get_player_name()
		if foundname ~= "" then
			if every_player or scan_for[foundname] then
				return true
			end
		end
	end

	return false
end

minetest.register_node("mesecons_detector:object_detector_off", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "jeija_object_detector_off.png", "jeija_object_detector_off.png", "jeija_object_detector_off.png", "jeija_object_detector_off.png"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3},
	description ="Player Detector",
	mesecons = {receptor = {
		state = mesecons.state.off,
		rules = mesecons.rules.pplate
	}},
	on_construct = object_detector_make_formspec,
	on_receive_fields = object_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	on_blast = mesecons.on_blastnode,
})

minetest.register_node("mesecons_detector:object_detector_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "jeija_object_detector_on.png", "jeija_object_detector_on.png", "jeija_object_detector_on.png", "jeija_object_detector_on.png"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky = 3,not_in_creative_inventory = 1},
	drop = 'mesecons_detector:object_detector_off',
	mesecons = {receptor = {
		state = mesecons.state.on,
		rules = mesecons.rules.pplate
	}},
	on_construct = object_detector_make_formspec,
	on_receive_fields = object_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	on_blast = mesecons.on_blastnode,
})

local microc = "mesecons:microcontroller"
minetest.register_craft({
	output = 'mesecons_detector:object_detector_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", microc, "default:steel_ingot"},
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = 'mesecons_detector:object_detector_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", microc, "default:steel_ingot"},
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
	}
})

minetest.register_abm({
	nodenames = {"mesecons_detector:object_detector_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if not object_detector_scan(pos) then return end

		node.name = "mesecons_detector:object_detector_on"
		minetest.swap_node(pos, node)
		mesecons.receptor_on(pos, mesecons.rules.pplate)
	end,
})

minetest.register_abm({
	nodenames = {"mesecons_detector:object_detector_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if object_detector_scan(pos) then return end

		node.name = "mesecons_detector:object_detector_off"
		minetest.swap_node(pos, node)
		mesecons.receptor_off(pos, mesecons.rules.pplate)
	end,
})

minetest.register_alias("mesecons:object_detector", "mesecons_detector:object_detector_off")
