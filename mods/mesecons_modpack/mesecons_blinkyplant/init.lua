-- The BLINKY_PLANT

local toggle_timer = function (pos)
	local timer = minetest.get_node_timer(pos)
	if timer:is_started() then
		timer:stop()
	else
		timer:start(tonumber(minetest.settings:get("mesecons_blinky_plant_interval") or 3))
	end
end

local on_timer = function (pos)
	local node = minetest.get_node(pos)
	if mesecons.flipstate(pos, node) == "on" then
		mesecons.receptor_on(pos)
	else
		mesecons.receptor_off(pos)
	end
	toggle_timer(pos)
end

mesecons.register_node(":mesecons:blinky_plant", {
	description ="Blinky Plant",
	drawtype = "plantlike",
	inventory_image = "jeija_blinky_plant_off.png",
	paramtype = "light",
	is_ground_content = false,
	walkable = false,
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, -0.5+0.7, 0.3},
	},
	on_timer = on_timer,
	on_rightclick = toggle_timer,
	on_construct = toggle_timer,
    drop = "mesecons:blinky_plant_off"
},{
	tiles = {"jeija_blinky_plant_off.png"},
	groups = {dig_immediate = 3, creative = 1},
	mesecons = {receptor = { state = mesecons.state.off }}
},{
	tiles = {"jeija_blinky_plant_on.png"},
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	mesecons = {receptor = { state = mesecons.state.on }},
	light_source = 5
})

minetest.register_alias("mesecons:blinky_plant", "mesecons:blinky_plant_off")

minetest.register_craft({
	output = "mesecons:blinky_plant_off 1",
	recipe = {
            {"",              "group:mesecon_conductor_craftable", ""},
			{"",              "group:mesecon_conductor_craftable", ""},
			{"group:sapling", "group:sapling",                     "group:sapling"}
        }
})
