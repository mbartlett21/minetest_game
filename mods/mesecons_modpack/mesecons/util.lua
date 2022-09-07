function mesecons.move_node(pos, newpos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos):to_table()
	minetest.remove_node(pos)
	minetest.set_node(newpos, node)
	minetest.get_meta(pos):from_table(meta)
end

-- Rules functions

mesecons.rules = {}
-- Rules rotation Functions:
function mesecons.rules.rotate_right(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x = -rule.z,
			y =  rule.y,
			z =  rule.x,
			name = rule.name})
	end
	return nr
end

function mesecons.rules.rotate_left(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x =  rule.z,
			y =  rule.y,
			z = -rule.x,
			name = rule.name})
	end
	return nr
end

function mesecons.rules.rotate_down(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x = -rule.y,
			y =  rule.x,
			z =  rule.z,
			name = rule.name})
	end
	return nr
end

function mesecons.rules.rotate_up(rules)
	local nr = {}
	for i, rule in ipairs(rules) do
		table.insert(nr, {
			x =  rule.y,
			y = -rule.x,
			z =  rule.z,
			name = rule.name})
	end
	return nr
end
--

function mesecons.rules.flatten(allrules)
--[[
	{
		{
			{xyz},
			{xyz},
		},
		{
			{xyz},
			{xyz},
		},
	}
--]]
	if allrules[1] and
	   allrules[1].x then
		return allrules
	end

	local shallowrules = {}
	for _, metarule in ipairs( allrules) do
	for _,     rule in ipairs(metarule ) do
		table.insert(shallowrules, rule)
	end
	end
	return shallowrules
--[[
	{
		{xyz},
		{xyz},
		{xyz},
		{xyz},
	}
--]]
end

function mesecons.rules.invert(r)
	return vector.multiply(r, -1)
end

function mesecons.rules.to_bit(findrule, allrules)
	--get the bit of the metarule the rule is in, or bit 1
	if (allrules[1] and
	    allrules[1].x) or
	    not findrule then
		return 1
	end
	for m,metarule in ipairs( allrules) do
	for _,    rule in ipairs(metarule ) do
		if vector.equals(findrule, rule) then
			return m
		end
	end
	end
end

function mesecons.rules.to_meta_index(findrule, allrules)
	--get the metarule the rule is in, or allrules
	if allrules[1].x then
		return nil
	end

	if not(findrule) then
		return mesecons.rules.flatten(allrules)
	end

	for m, metarule in ipairs( allrules) do
	for _,     rule in ipairs(metarule ) do
		if vector.equals(fixndrule, rule) then
			return m
		end
	end
	end
end

function mesecons.rules.to_meta(findrule, allrules)
	if #allrules == 0 then return {} end

	local index = mesecons.rules.to_meta_index(findrule, allrules)
	if index == nil then
		if allrules[1].x then
			return allrules
		else
			return {}
		end
	end
	return allrules[index]
end

function mesecons.dec2bin(n)
	local x, y = math.floor(n / 2), n % 2
	if (n > 1) then
		return mesecons.dec2bin(x)..y
	else
		return ""..y
	end
end

function mesecons.getstate(nodename, states)
	for state, name in ipairs(states) do
		if name == nodename then
			return state
		end
	end
	error(nodename.." doesn't mention itself in "..dump(states))
end

function mesecons.getbinstate(nodename, states)
	return mesecons.dec2bin(mesecons.getstate(nodename, states)-1)
end

function mesecons.get_bit(binary,bit)
	bit = bit or 1
	local c = binary:len()-(bit-1)
	return binary:sub(c,c) == "1"
end

function mesecons.set_bit(binary,bit,value)
	if value == "1" then
		if not mesecons.get_bit(binary,bit) then
			return mesecons.dec2bin(tonumber(binary,2)+2^(bit-1))
		end
	elseif value == "0" then
		if mesecons.get_bit(binary,bit) then
			return mesecons.dec2bin(tonumber(binary,2)-2^(bit-1))
		end
	end
	return binary

end

-- does not overwrite values; number keys (ipairs) are appended, not overwritten
function mesecons.mergetable(source, dest)
	local rval = table.copy(dest)

    -- Do numeric first otherwise it won't work  properly if the source has more numeric keys than the dest
	for i, v in ipairs(source) do
        if type(v) == "table" then
            table.insert(rval, table.copy(v))
        else
            table.insert(rval, v)
        end
	end
	for k, v in pairs(source) do
		rval[k] = dest[k] or (type(v) == "table" and table.copy(v) or v)
	end

	return rval
end

function mesecons.register_node(name, spec_common, spec_off, spec_on)
	spec_common.drop = spec_common.drop or name .. "_off"
	spec_common.on_blast = spec_common.on_blast or mesecons.on_blastnode
	spec_common.__mesecon_basename = name
	spec_on.__mesecon_state = "on"
	spec_off.__mesecon_state = "off"

	spec_on = mesecons.mergetable(spec_common, spec_on);
	spec_off = mesecons.mergetable(spec_common, spec_off);

	minetest.register_node(name .. "_on", spec_on)
	minetest.register_node(name .. "_off", spec_off)
end

-- swap onstate and offstate nodes, returns new state
function mesecons.flipstate(pos, node)
	local nodedef = minetest.registered_nodes[node.name]
	local newstate
	if (nodedef.__mesecon_state == "on") then newstate = "off" end
	if (nodedef.__mesecon_state == "off") then newstate = "on" end

	minetest.swap_node(pos, {name = nodedef.__mesecon_basename .. "_" .. newstate,
		param2 = node.param2})

	return newstate
end

-- Block position "hashing" (convert to integer) functions for voxelmanip cache
local BLOCKSIZE = 16

-- convert node position --> block hash
local function hash_blockpos(pos)
	return minetest.hash_node_position({
		x = math.floor(pos.x/BLOCKSIZE),
		y = math.floor(pos.y/BLOCKSIZE),
		z = math.floor(pos.z/BLOCKSIZE)
	})
end

-- Maps from a hashed mapblock position (as returned by hash_blockpos) to a
-- table.
--
-- Contents of the table are:
-- “vm” → the VoxelManipulator
-- “va” → the VoxelArea
-- “data” → the data array
-- “param1” → the param1 array
-- “param2” → the param2 array
-- “dirty” → true if data has been modified
--
-- Nil if no VM-based transaction is in progress.
local vm_cache = nil

local mesecon_vm = {}
-- This is in the global object so other internal functions can use it.
-- It is cleared when init.lua finishes
mesecons.vm = mesecon_vm

-- Starts a VoxelManipulator-based transaction.
--
-- During a VM transaction, calls to get_node and swap_node operate on a
-- cached copy of the world loaded via VoxelManipulators. That cache can later
-- be committed to the real map by means of commit or discarded by means of
-- abort.
function mesecon_vm.begin()
	vm_cache = {}
end

-- Finishes a VoxelManipulator-based transaction, freeing the VMs and map data
-- and writing back any modified areas.
function mesecon_vm.commit()
	for hash, tbl in pairs(vm_cache) do
		if tbl.dirty then
			local vm = tbl.vm
			vm:set_data(tbl.data)
			vm:write_to_map()
			vm:update_map()
		end
	end
	vm_cache = nil
end

-- Finishes a VoxelManipulator-based transaction, freeing the VMs and throwing
-- away any modified areas.
function mesecon_vm.abort()
	vm_cache = nil
end

-- Gets the cache entry covering a position, populating it if necessary.
local function vm_get_or_create_entry(pos)
	local hash = hash_blockpos(pos)
	local tbl = vm_cache[hash]
	if not tbl then
		local vm = minetest.get_voxel_manip(pos, pos)
		local min_pos, max_pos = vm:get_emerged_area()
		local va = VoxelArea:new{MinEdge = min_pos, MaxEdge = max_pos}
		tbl = {
            vm = vm,
            va = va,
            data = vm:get_data(),
            param1 = vm:get_light_data(),
            param2 = vm:get_param2_data(),
            dirty = false
        }
		vm_cache[hash] = tbl
	end
	return tbl
end

-- Gets the node at a given position during a VoxelManipulator-based
-- transaction.
function mesecon_vm.get_node(pos)
	local tbl = vm_get_or_create_entry(pos)
	local index = tbl.va:indexp(pos)
	local node_value = tbl.data[index]
	if node_value == core.CONTENT_IGNORE then
		return nil
	else
		local node_param1 = tbl.param1[index]
		local node_param2 = tbl.param2[index]
		return {
            name = minetest.get_name_from_content_id(node_value),
            param1 = node_param1,
            param2 = node_param2
        }
	end
end

-- Sets a node’s name during a VoxelManipulator-based transaction.
--
-- Existing param1, param2, and metadata are left alone.
function mesecon_vm.swap_node(pos, name)
	local tbl = vm_get_or_create_entry(pos)
	local index = tbl.va:indexp(pos)
	tbl.data[index] = minetest.get_content_id(name)
	tbl.dirty = true
end

-- Gets the node at a given position, regardless of whether it is loaded or
-- not, respecting a transaction if one is in progress.
--
-- Outside a VM transaction, if the mapblock is not loaded, it is pulled into
-- the server’s main map data cache and then accessed from there.
--
-- Inside a VM transaction, the transaction’s VM cache is used.
function mesecons.get_node_force(pos)
	if vm_cache then
		return mesecon_vm.get_node(pos)
	else
		local node = minetest.get_node_or_nil(pos)
		if node == nil then
			-- Node is not currently loaded; use a VoxelManipulator to prime
			-- the mapblock cache and try again.
			minetest.get_voxel_manip(pos, pos)
			node = minetest.get_node_or_nil(pos)
		end
		return node
	end
end

-- Swaps the node at a given position, regardless of whether it is loaded or
-- not, respecting a transaction if one is in progress.
--
-- Outside a VM transaction, if the mapblock is not loaded, it is pulled into
-- the server’s main map data cache and then accessed from there.
--
-- Inside a VM transaction, the transaction’s VM cache is used.
--
-- This function can only be used to change the node’s name, not its parameters
-- or metadata.
function mesecons.swap_node_force(pos, name)
	if vm_cache then
		return mesecon_vm.swap_node(pos, name)
	else
		-- This serves to both ensure the mapblock is loaded and also hand us
		-- the old node table so we can preserve param2.
		local node = mesecons.get_node_force(pos)
		node.name = name
		minetest.swap_node(pos, node)
	end
end
