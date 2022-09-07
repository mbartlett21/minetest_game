mesecons.state = {}

-- These rules are used for standard wire
mesecons.rules.default = {
	{x =  0, y =  0, z = -1},
	{x =  1, y =  0, z =  0},
	{x = -1, y =  0, z =  0},
	{x =  0, y =  0, z =  1},
	{x =  1, y =  1, z =  0},
	{x =  1, y = -1, z =  0},
	{x = -1, y =  1, z =  0},
	{x = -1, y = -1, z =  0},
	{x =  0, y =  1, z =  1},
	{x =  0, y = -1, z =  1},
	{x =  0, y =  1, z = -1},
	{x =  0, y = -1, z = -1},
}

mesecons.rules.floor = mesecons.mergetable(mesecons.rules.default, {{x = 0, y = -1, z = 0}})

-- Pressure plates conduct to the node two below them
mesecons.rules.pplate = mesecons.mergetable(mesecons.rules.floor, {{x = 0, y = -2, z = 0}})

-- Buttons conduct like below:
--[[
Layers:

000
0X0
000

0X0
0X0
XXX

000
0B0
0X0

]]
mesecons.rules.buttonlike = {
	{x = 0,  y =  -1, z =  0},
	{x = 1,  y =  0, z =  0},
	{x = 1,  y =  1, z =  0},
	{x = 1,  y = -1, z =  0},
	{x = 1,  y = -1, z =  1},
	{x = 1,  y = -1, z = -1},
	{x = 2,  y =  0, z =  0},
}

mesecons.rules.flat = {
	{x =  1, y = 0, z =  0},
	{x = -1, y = 0, z =  0},
	{x =  0, y = 0, z =  1},
	{x =  0, y = 0, z = -1},
}

mesecons.rules.alldirs = {
	{x =  1, y =  0,  z =  0},
	{x = -1, y =  0,  z =  0},
	{x =  0, y =  1,  z =  0},
	{x =  0, y = -1,  z =  0},
	{x =  0, y =  0,  z =  1},
	{x =  0, y =  0,  z = -1},
}

local rules_wallmounted = {
	xp = mesecons.rules.rotate_down(mesecons.rules.floor),
	xn = mesecons.rules.rotate_up(mesecons.rules.floor),
	yp = mesecons.rules.rotate_up(mesecons.rules.rotate_up(mesecons.rules.floor)),
	yn = mesecons.rules.floor,
	zp = mesecons.rules.rotate_left(mesecons.rules.rotate_up(mesecons.rules.floor)),
	zn = mesecons.rules.rotate_right(mesecons.rules.rotate_up(mesecons.rules.floor)),
}

local rules_buttonlike = {
	xp = mesecons.rules.buttonlike,
	xn = mesecons.rules.rotate_right(mesecons.rules.rotate_right(mesecons.rules.buttonlike)),
	yp = mesecons.rules.rotate_down(mesecons.rules.buttonlike),
	yn = mesecons.rules.rotate_up(mesecons.rules.buttonlike),
	zp = mesecons.rules.rotate_right(mesecons.rules.buttonlike),
	zn = mesecons.rules.rotate_left(mesecons.rules.buttonlike),
}

local function rules_from_dir(ruleset, dir)
	if dir.x ==  1 then return ruleset.xp end
	if dir.y ==  1 then return ruleset.yp end
	if dir.z ==  1 then return ruleset.zp end
	if dir.x == -1 then return ruleset.xn end
	if dir.y == -1 then return ruleset.yn end
	if dir.z == -1 then return ruleset.zn end
end

mesecons.rules.wallmounted_get = function(node)
	local dir = minetest.wallmounted_to_dir(node.param2)
	return rules_from_dir(rules_wallmounted, dir)
end

mesecons.rules.buttonlike_get = function(node)
	local dir = minetest.facedir_to_dir(node.param2)
	return rules_from_dir(rules_buttonlike, dir)
end

mesecons.state.on = "on"
mesecons.state.off = "off"
