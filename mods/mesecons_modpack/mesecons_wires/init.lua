-- naming scheme: wire:(xp)(zp)(xm)(zm)(xpyp)(zpyp)(xmyp)(zmyp)_on/off
-- where x = x direction, z = z direction, y = y direction, p = +1, m = -1, e.g. xpym = {x = 1, y = -1, z = 0}
-- The (xp)/(zpyp)/.. statements shall be replaced by either 0 or 1
-- Where 0 means the wire has no visual connection to that direction and
-- 1 means that the wire visually connects to that other node.

-- #######################
-- ## Update wire looks ##
-- #######################

-- self_pos = pos of any mesecon node, from_pos = pos of conductor to getconnect for
local wire_getconnect = function (from_pos, self_pos)
	local node = minetest.get_node(self_pos)
	if minetest.registered_nodes[node.name]
	and minetest.registered_nodes[node.name].mesecons then
		-- rules of node to possibly connect to
		local rules = mesecons.get_any_rules(node)

		for _, r in ipairs(mesecons.rules.flatten(rules)) do
			if vector.equals(vector.add(self_pos, r), from_pos) then
				return true
			end
		end
	end
	return false
end

-- Update this node
local wire_updateconnect = function (pos)
	local connections = {}

	for _, r in ipairs(mesecons.rules.default) do
		if wire_getconnect(pos, vector.add(pos, r)) then
			table.insert(connections, r)
		end
	end

	local nid = {}
	for _, vec in ipairs(connections) do
		-- flat component
		if vec.x ==  1 then nid[1] = "1" end
		if vec.z ==  1 then nid[2] = "1" end
		if vec.x == -1 then nid[3] = "1" end
		if vec.z == -1 then nid[4] = "1"  end

		-- slopy component
		if vec.y == 1 then
			if vec.x ==  1 then nid[5] = "1" end
			if vec.z ==  1 then nid[6] = "1" end
			if vec.x == -1 then nid[7] = "1" end
			if vec.z == -1 then nid[8] = "1" end
		end
	end

	local nodeid =
    (nid[1] or "0")..
    (nid[2] or "0")..
    (nid[3] or "0")..
    (nid[4] or "0")..
    (nid[5] or "0")..
    (nid[6] or "0")..
    (nid[7] or "0")..
    (nid[8] or "0")

	local state_suffix = string.find(minetest.get_node(pos).name, "_on") and "_on" or "_off"
	minetest.set_node(pos, {name = "mesecons:wire_"..nodeid..state_suffix})
end

local update_on_place_dig = function (pos, node)
	-- Update placed node (get_node again as it may have been dug)
	local nn = minetest.get_node(pos)
	if minetest.registered_nodes[nn.name]
	and (minetest.registered_nodes[nn.name].mesecon_wire) then
		wire_updateconnect(pos)
	end

	-- Update nodes around it
	local rules = {}
	if minetest.registered_nodes[node.name]
	and minetest.registered_nodes[node.name].mesecon_wire then
		rules = mesecons.rules.default
	else
		rules = mesecons.get_any_rules(node)
	end
	if not rules then return end

	for _, r in ipairs(mesecons.rules.flatten(rules)) do
		local np = vector.add(pos, r)
        local node = minetest.registered_nodes[minetest.get_node(np).name]
		if node	and node.mesecon_wire then
			wire_updateconnect(np)
		end
	end
end

mesecons.register_autoconnect_hook("wire", update_on_place_dig)

-- ############################
-- ## Wire node registration ##
-- ############################
-- Nodeboxes:
local box_center = { -1/16, -1/2,  -1/16, 1/16,  -7/16, 1/16 }
local box_bump1 =  { -2/16, -8/16, -2/16, 2/16, -13/32, 2/16 }

local nbox_nid =
{
	{  1/16, -1/2,  -1/16,  8/16, -7/16,  1/16 }, -- x positive
	{ -1/16, -1/2,   1/16,  1/16, -7/16,  8/16 }, -- z positive
	{ -8/16, -1/2,  -1/16, -1/16, -7/16,  1/16 }, -- x negative
	{ -1/16, -1/2,  -8/16,  1/16, -7/16, -1/16 }, -- z negative

	{  7/16, -7/16, -1/16,  1/2,   9/16,  1/16 }, -- x positive up
	{ -1/16, -7/16,  7/16,  1/16,  9/16,  1/2  }, -- z positive up
	{ -1/2,  -7/16, -1/16, -7/16,  9/16,  1/16 }, -- x negative up
	{ -1/16, -7/16, -1/2,   1/16,  9/16, -7/16 }  -- z negative up
}

local tiles_off = { "mesecons_wire_off.png" }
local tiles_on = { "mesecons_wire_on.png" }

local selectionbox =
{
	type = "fixed",
	fixed = {-1/2, -1/2, -1/2, 1/2, -3/8, 1/2}
}

-- go to the next nodeid (ex.: 01000011 --> 01000100)
local function nid_inc(nid)
	local i = 1
	while not nid[i-1] do
        if nid[i] then
            nid[i] = false
        else
            nid[i] = true
        end
		i = i + 1
	end

	-- BUT: Skip impossible ids
	if (not nid[1] and nid[5]) or (not nid[2] and nid[6]) or
       (not nid[3] and nid[7]) or (not nid[4] and nid[8]) then
		return nid_inc(nid)
	end

	return i <= 8
end

local rules = {
    vector.new( 1,  0,  0),
    vector.new( 0,  0,  1),
    vector.new(-1,  0,  0),
    vector.new( 0,  0, -1),

    vector.new( 1, -1,  0),
    vector.new( 0, -1,  1),
    vector.new(-1, -1,  0),
    vector.new( 0, -1, -1),

    vector.new( 1,  1,  0),
    vector.new( 0,  1,  1),
    vector.new(-1,  1,  0),
    vector.new( 0,  1, -1)
}

local function register_wires()
	local nid = {}
	while true do
		-- Create group specifiction and nodeid string (see note above for details)
		local nodeid = (nid[1] and 1 or 0)
                    .. (nid[2] and 1 or 0)
                    .. (nid[3] and 1 or 0)
                    .. (nid[4] and 1 or 0)
                    .. (nid[5] and 1 or 0)
                    .. (nid[6] and 1 or 0)
                    .. (nid[7] and 1 or 0)
                    .. (nid[8] and 1 or 0)

		-- Calculate nodebox
		local nodebox = {type = "fixed", fixed ={box_center}}
		for i = 1,8 do
			if nid[i] then
				table.insert(nodebox.fixed, nbox_nid[i])
			end
		end

		-- Add bump to nodebox if curved
		if (nid[1] and nid[2]) or (nid[2] and nid[3])
            or (nid[3] and nid[4]) or (nid[4] and nid[1]) then
			table.insert(nodebox.fixed, box_bump1)
		end

		-- If nothing to connect to, still make a nodebox of a straight wire
		if nodeid == "00000000" then
			nodebox.fixed = {-8/16, -.5, -1/16, 8/16, -.5+1/16, 1/16}
		end

		local meseconspec_off = {conductor = {
			rules = rules,
			state = mesecons.state.off,
			onstate = "mesecons:wire_"..nodeid.."_on"
		}}

		local meseconspec_on = {conductor = {
			rules = rules,
			state = mesecons.state.on,
			offstate = "mesecons:wire_"..nodeid.."_off"
		}}

		local groups_on =  {
            dig_immediate = 3,
            mesecon_conductor_craftable = 1,
			not_in_creative_inventory = 1
        }
		local groups_off = {
            dig_immediate = 3,
            mesecon_conductor_craftable = 1,
			not_in_creative_inventory = 1
        }

		mesecons.register_node(":mesecons:wire_"..nodeid, {
                description = "Mesecon",
                drawtype = "nodebox",
                inventory_image = "mesecons_wire_inv.png",
                wield_image = "mesecons_wire_inv.png",
                paramtype = "light",
                paramtype2 = "facedir",
                is_ground_content = false,
                sunlight_propagates = true,
                selection_box = selectionbox,
                node_box = nodebox,
                walkable = false,
                drop = "mesecons:wire",
                mesecon_wire = true,
                sounds = default.node_sound_defaults(),
                on_rotate = false,
            },
            {
                tiles = tiles_off,
                mesecons = meseconspec_off,
                groups = groups_off
            },
            {
                tiles = tiles_on,
                mesecons = meseconspec_on,
                groups = groups_on,
                light_source = 3
            })

		if not nid_inc(nid) then return end
	end
end
register_wires()

minetest.register_node(":mesecons:wire", {
        description = "Mesecon",
        drawtype = "nodebox",
        inventory_image = "mesecons_wire_inv.png",
        wield_image = "mesecons_wire_inv.png",
        paramtype = "light",
        paramtype2 = "facedir",
        is_ground_content = false,
        sunlight_propagates = true,
        selection_box = selectionbox,
        node_box = {type = "fixed", fixed = {-8/16, -.5, -1/16, 8/16, -.5+1/16, 1/16}},
        walkable = false,
        drop = "mesecons:wire",
        mesecon_wire = true,
        sounds = default.node_sound_defaults(),
        on_rotate = false,
        tiles = tiles_off,
        mesecons = {conductor = {
			rules = rules,
			state = mesecons.state.off,
			onstate = "mesecons:wire_00000000_on"
		}},
        groups = {
            dig_immediate = 3,
            mesecon_conductor_craftable = 1,
			creative = 1
        }
    })

minetest.register_alias("mesecons:mesecon", "mesecons:wire")

-- ##############
-- ## Crafting ##
-- ##############

minetest.register_craft({
	type = "cooking",
	output = "mesecons:wire 18",
	recipe = "default:mese_crystal",
	cooktime = 15,
})

minetest.register_craft({
	type = "cooking",
	output = "mesecons:wire 162",
	recipe = "default:mese",
	cooktime = 30,
})
