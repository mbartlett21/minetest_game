
cooking = {}
cooking.path = minetest.get_modpath("cooking")


-- Load files

dofile(cooking.path .. "/craft.lua")
dofile(cooking.path .. "/functions.lua")
dofile(cooking.path .. "/oven.lua")
dofile(cooking.path .. "/recipes.lua")
