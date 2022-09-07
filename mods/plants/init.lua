-- Minetest mod: Plants

-- Main namespace

plants = {}

-- Map Generation

dofile(minetest.get_modpath("plants") .. "/mapgen.lua")


-- Flower registration

-- Adds a flower plants:<name>
function plants.add_simple_flower(name, desc, box, f_groups, seed)
	-- Common flower groups
	f_groups.snappy = 3
	f_groups.flower = 1
	f_groups.flora = 1
	f_groups.attached_node = 1
    f_groups.creative = 1

	minetest.register_node(":plants:" .. name, {
		description = desc,
		drawtype = "plantlike",
		waving = 1,
		tiles = {"flowers_" .. name .. ".png"},
		inventory_image = "flowers_" .. name .. ".png",
		wield_image = "flowers_" .. name .. ".png",
		sunlight_propagates = true,
		paramtype = "light",
		walkable = false,
		buildable_to = true,
		stack_max = 99,
		groups = f_groups,
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = box
		}
	})
    plants.register_flower_mapgen(seed, name)
    minetest.register_alias("flowers:" .. name, "plants:" .. name)
end

local flower_datas = {
	{
		"rose",
		"Red Rose",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
		{color_red = 1, flammable = 1},
        436
	},
	{
		"tulip",
		"Orange Tulip",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
		{color_orange = 1, flammable = 1},
        19822
	},
	{
		"dandelion_yellow",
		"Yellow Dandelion",
		{-4 / 16, -0.5, -4 / 16, 4 / 16, -2 / 16, 4 / 16},
		{color_yellow = 1, flammable = 1},
        1220999
	},
	{
		"chrysanthemum_green",
		"Green Chrysanthemum",
		{-4 / 16, -0.5, -4 / 16, 4 / 16, -1 / 16, 4 / 16},
		{color_green = 1, flammable = 1},
        800081
	},
	{
		"geranium",
		"Blue Geranium",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 2 / 16, 2 / 16},
		{color_blue = 1, flammable = 1},
        36662
	},
	{
		"viola",
		"Viola",
		{-5 / 16, -0.5, -5 / 16, 5 / 16, -1 / 16, 5 / 16},
		{color_violet = 1, flammable = 1},
        1133
	},
	{
		"dandelion_white",
		"White Dandelion",
		{-5 / 16, -0.5, -5 / 16, 5 / 16, -2 / 16, 5 / 16},
		{color_white = 1, flammable = 1},
        73133
	},
	{
		"tulip_black",
		"Black Tulip",
		{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
		{color_black = 1, flammable = 1},
        42
	},
}

for _,item in pairs(flower_datas) do
	plants.add_simple_flower(unpack(item))
end


-- Plant spread
-- Public function to enable override by mods

function plants.flower_spread(pos, node)
	pos.y = pos.y - 1
	local under = minetest.get_node(pos)
	pos.y = pos.y + 1
	-- Replace flora with dry shrub in desert sand and silver sand,
	-- as this is the only way to generate them.
	-- However, preserve grasses in sand dune biomes.
	if minetest.get_item_group(under.name, "sand") == 1 and
			under.name ~= "default:sand" then
		minetest.set_node(pos, {name = "default:dry_shrub"})
		return
	end

	if minetest.get_item_group(under.name, "soil") == 0 then
		return
	end

	local light = minetest.get_node_light(pos)
	if not light or light < 13 then
		return
	end

	local pos0 = vector.subtract(pos, 4)
	local pos1 = vector.add(pos, 4)
	-- Testing shows that a threshold of 3 results in an appropriate maximum
	-- density of approximately 7 flora per 9x9 area.
	if #minetest.find_nodes_in_area(pos0, pos1, "group:flora") > 3 then
		return
	end

	local soils = minetest.find_nodes_in_area_under_air(
		pos0, pos1, "group:soil")
	local num_soils = #soils
	if num_soils >= 1 then
		for si = 1, math.min(3, num_soils) do
			local soil = soils[math.random(num_soils)]
			local soil_name = minetest.get_node(soil).name
			local soil_above = {x = soil.x, y = soil.y + 1, z = soil.z}
			light = minetest.get_node_light(soil_above)
			if light and light >= 13 and
					-- Only spread to same surface node
					soil_name == under.name and
					-- Desert sand is in the soil group
					soil_name ~= "default:desert_sand" then
				minetest.set_node(soil_above, {name = node.name})
			end
		end
	end
end

minetest.register_abm({
	label = "Flower spread",
	nodenames = {"group:flora"},
	interval = 13,
	chance = 300,
	action = function(...)
		plants.flower_spread(...)
	end,
})


-- Adds a mushroom plants:<name>
function plants.add_simple_mushroom(name, desc, box, f_groups, hp)
    -- Common mushroom groups
	f_groups.snappy = 3
	f_groups.flammable = 1
	f_groups.attached_node = 1
    f_groups.mushroom = 1
    f_groups.creative = 1

	minetest.register_node(":plants:" .. name, {
		description = desc,
		tiles = {"flowers_" .. name .. ".png"},
		inventory_image = "flowers_" .. name .. ".png",
		wield_image = "flowers_" .. name .. ".png",
		drawtype = "plantlike",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		buildable_to = true,
		groups = f_groups,
		sounds = default.node_sound_leaves_defaults(),
        on_use = minetest.item_eat(hp),
		selection_box = {
			type = "fixed",
			fixed = box
		}
	})
    plants.register_mushroom_mapgen(name)
    minetest.register_alias("flowers:" .. name, "plants:" .. name)
end

local mushroom_datas = {
	{
		"mushroom_red",
		"Red Mushroom",
		{-4 / 16, -0.5, -4 / 16, 4 / 16, -1 / 16, 4 / 16},
		{color_red = 1},
        -5
	},
	{
		"mushroom_brown",
		"Brown Mushroom",
		{-3 / 16, -0.5, -3 / 16, 3 / 16, -2 / 16, 3 / 16},
		{food_mushroom = 1, color_brown = 1},
        1
	}
}


for _,item in pairs(mushroom_datas) do
	plants.add_simple_mushroom(unpack(item))
end


-- Mushroom spread and death
-- Public to enable override

function plants.mushroom_spread(pos, node)
	if minetest.get_node_light(pos, nil) == 15 then
		minetest.remove_node(pos)
		return
	end
	local positions = minetest.find_nodes_in_area_under_air(
		{x = pos.x - 1, y = pos.y - 2, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:soil", "group:tree"})
	if #positions == 0 then
		return
	end
	local pos2 = positions[math.random(#positions)]
	pos2.y = pos2.y + 1
	if minetest.get_node_light(pos, 0.5) <= 3 and
			minetest.get_node_light(pos2, 0.5) <= 3 then
		minetest.set_node(pos2, {name = node.name})
	end
end

minetest.register_abm({
	label = "Mushroom spread",
	nodenames = {"group:mushroom"},
	interval = 11,
	chance = 150,
	action = function(...)
		plants.mushroom_spread(...)
	end,
})