
function plants.register_flower_mapgen(seed, flower_name)
	minetest.register_decoration({
		name = "plants:"..flower_name,
		deco_type = "simple",
		place_on = {"default:dirt_with_grass"},
		sidelen = 16,
		noise_params = {
			offset = -0.02,
			scale = 0.04,
			spread = {x = 200, y = 200, z = 200},
			seed = seed,
			octaves = 3,
			persist = 0.6
		},
		biomes = {"grassland", "deciduous_forest"},
		y_max = 31000,
		y_min = 1,
		decoration = "plants:"..flower_name,
	})
end

function plants.register_mushroom_mapgen(mushroom_name)
	minetest.register_decoration({
		name = "plants:"..mushroom_name,
		deco_type = "simple",
		place_on = {"default:dirt_with_grass", "default:dirt_with_coniferous_litter"},
		sidelen = 16,
		noise_params = {
			offset = 0,
			scale = 0.006,
			spread = {x = 250, y = 250, z = 250},
			seed = 2,
			octaves = 3,
			persist = 0.66
		},
		biomes = {"deciduous_forest", "coniferous_forest"},
		y_max = 31000,
		y_min = 1,
		decoration = "plants:"..mushroom_name,
	})
end
