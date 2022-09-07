dofile(minetest.get_modpath("player_api") .. "/api.lua")

-- Default player appearance
player_api.register_model("character.b3d", {
	animation_speed = 30,
	textures = {"character.png", },
	animations = {
		-- Standard animations.
		stand     = {x = 0,   y = 79},
		lay       = {x = 162, y = 166},
		walk      = {x = 168, y = 187},
		mine      = {x = 189, y = 198},
		walk_mine = {x = 200, y = 219},
		sit       = {x = 81,  y = 160},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	stepheight = 0.6,
	eye_height = 1.47
})

player_api.register_model("sheep.b3d", {
	animation_speed = 30,
	textures = {"sheep_fur.png", },
	animations = {
		stand = {x = 111, y = 129},
		lay = {x = 90, y = 99},
		walk = {x = 0, y = 40},
		mine = {x = 47, y = 75},
		walk_mine = {x = 47, y = 75},
		sit = {x = 111, y = 129},
	},
	collisionbox = {-0.3, -0.5, -0.3, 0.3, 0.3, 0.3},
	stepheight = 0.6,
	eye_height = 0.3
})

-- Update appearance when the player joins
minetest.register_on_joinplayer(function(player)
	player_api.player_attached[player:get_player_name()] = false
	player_api.set_model(player, "character.b3d")
end)
