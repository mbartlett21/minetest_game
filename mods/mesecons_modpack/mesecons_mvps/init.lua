--register stoppers for movestones/pistons

local mvps = {}
mesecons.mvps = mvps
mvps.fixed = {
    -- Nodes & Entities that cannot move
    nodes = {},
    entities = {}
}

local function make_registration()
	local t = {}
	local registerfunc = function(func)
		t[#t + 1] = func
	end
	return t, registerfunc
end

mvps.registered_on_move, mvps.register_on_move = make_registration()

function mvps.fixed.register_entity(entityname)
    mvps.fixed.entities[entityname] = true
end

function mvps.fixed.register_node(nodename, check_func)
    if not check_func then
        check_func = true
    end
    mvps.fixed.nodes[nodename] = check_func
end

function mvps.fixed.is_fixed_node(node, pushdir, stack, stackid)
    if not minetest.registered_nodes[node.name] then return true end
    if minetest.get_item_group(node.name, "fixed") == 1 then return true end
    local is_stopper = mvps.fixed.nodes[node.name]
    if type(is_stopper) == "function" then
        is_stopper = is_stopper(node, pushdir, stack, stackid)
    end
    return is_stopper
end

function mvps.fixed.is_fixed_entity(entityname)
	return mvps.fixed.entities[objectname]
end

local function on_mvps_move(moved_nodes)
	for _, callback in ipairs(mvps.registered_on_move) do
		callback(moved_nodes)
	end
end

function mvps.process_stack(stack)
	-- update mesecons for placed nodes ( has to be done after all nodes have been added )
	for _, n in ipairs(stack) do
		mesecons.on_placenode(n.pos, minetest.get_node(n.pos))
	end
end

-- tests if the node can be pushed into, e.g. air, water, grass
local function node_replaceable(name)
	return minetest.registered_nodes[name] and minetest.registered_nodes[name].buildable_to
end

function mvps.get_stack(pos, dir, maximum, all_pull_sticky)
	-- determine the number of nodes to be pushed
	local nodes = {}
	local frontiers = {pos}

	while #frontiers > 0 do
		local np = frontiers[1]
		local nn = minetest.get_node(np)

		if not node_replaceable(nn.name) then
			table.insert(nodes, {node = nn, pos = np})
			if #nodes > maximum then return nil end

			-- add connected nodes to frontiers, connected is a vector list
			-- the vectors must be absolute positions
			local connected = {}
			if minetest.registered_nodes[nn.name]
			and minetest.registered_nodes[nn.name].mvps_sticky then
				connected = minetest.registered_nodes[nn.name].mvps_sticky(np, nn)
			end

			table.insert(connected, vector.add(np, dir))

			-- If adjacent node is sticky block and connects add that
			-- position to the connected table
			for _, r in ipairs(mesecons.rules.alldirs) do
				local adjpos = vector.add(np, r)
				local adjnode = minetest.get_node(adjpos)
				if minetest.registered_nodes[adjnode.name]
				and minetest.registered_nodes[adjnode.name].mvps_sticky then
					local sticksto = minetest.registered_nodes[adjnode.name]
						.mvps_sticky(adjpos, adjnode)

					-- connects to this position?
					for _, link in ipairs(sticksto) do
						if vector.equals(link, np) then
							table.insert(connected, adjpos)
						end
					end
				end
			end

			if all_pull_sticky then
				table.insert(connected, vector.subtract(np, dir))
			end

			-- Make sure there are no duplicates in frontiers / nodes before
			-- adding nodes in "connected" to frontiers
			for _, cp in ipairs(connected) do
				local duplicate = false
				for _, rp in ipairs(nodes) do
					if vector.equals(cp, rp.pos) then
						duplicate = true
					end
				end
				for _, fp in ipairs(frontiers) do
					if vector.equals(cp, fp) then
						duplicate = true
					end
				end
				if not duplicate then
					table.insert(frontiers, cp)
				end
			end
		end
		table.remove(frontiers, 1)
	end

	return nodes
end

function mvps.push(pos, dir, maximum)
	return mvps.push_or_pull(pos, dir, dir, maximum)
end

function mvps.pull_all(pos, dir, maximum)
	return mvps.push_or_pull(pos, vector.multiply(dir, -1), dir, maximum, true)
end

function mvps.pull_single(pos, dir, maximum)
	return mvps.push_or_pull(pos, vector.multiply(dir, -1), dir, maximum)
end

-- pos: pos of mvps; stackdir: direction of building the stack
-- movedir: direction of actual movement
-- maximum: maximum nodes to be pushed
-- all_pull_sticky: All nodes are sticky in the direction that they are pulled from
function mvps.push_or_pull(pos, stackdir, movedir, maximum, all_pull_sticky)
	local nodes = mvps.get_stack(pos, movedir, maximum, all_pull_sticky)

	if not nodes then return end
	-- determine if one of the nodes blocks the push / pull
	for id, n in ipairs(nodes) do
		if mvps.fixed.is_fixed_node(n.node, movedir, nodes, id) then
			return
		end
	end

	-- remove all nodes
	for _, n in ipairs(nodes) do
		n.meta = minetest.get_meta(n.pos):to_table()
		local node_timer = minetest.get_node_timer(n.pos)
		if node_timer:is_started() then
			n.node_timer = {node_timer:get_timeout(), node_timer:get_elapsed()}
		end
		minetest.remove_node(n.pos)
	end

	-- update mesecons for removed nodes ( has to be done after all nodes have been removed )
	for _, n in ipairs(nodes) do
		mesecons.on_dignode(n.pos, n.node)
	end

	-- add nodes
	for _, n in ipairs(nodes) do
		local np = vector.add(n.pos, movedir)

		minetest.set_node(np, n.node)
		minetest.get_meta(np):from_table(n.meta)
		if n.node_timer then
			minetest.get_node_timer(np):set(unpack(n.node_timer))
		end
	end

	local moved_nodes = {}
	local oldstack = table.copy(nodes)
	for i in ipairs(nodes) do
		moved_nodes[i] = {}
		moved_nodes[i].oldpos = nodes[i].pos
		nodes[i].pos = vector.add(nodes[i].pos, movedir)
		moved_nodes[i].pos = nodes[i].pos
		moved_nodes[i].node = nodes[i].node
		moved_nodes[i].meta = nodes[i].meta
		moved_nodes[i].node_timer = nodes[i].node_timer
	end

	on_mvps_move(moved_nodes)

	return true, nodes, oldstack
end

function mvps.move_objects(pos, dir, nodestack, movefactor)
	local objects_to_move = {}
	local dir_k
	local dir_l
	for k, v in pairs(dir) do
		if v ~= 0 then
			dir_k = k
			dir_l = v
			break
		end
	end
	movefactor = movefactor or 1
	dir = vector.multiply(dir, movefactor)
	for id, obj in pairs(minetest.object_refs) do
		local obj_pos = obj:get_pos()
		local cbox = obj:get_properties().collisionbox
		local min_pos = vector.add(obj_pos, vector.new(cbox[1], cbox[2], cbox[3]))
		local max_pos = vector.add(obj_pos, vector.new(cbox[4], cbox[5], cbox[6]))
		local ok = true
		for k, v in pairs(pos) do
			local edge1, edge2
			if k ~= dir_k then
				edge1 = v - 0.51 -- More than 0.5 to move objects near to the stack.
				edge2 = v + 0.51
			else
				edge1 = v - 0.5 * dir_l
				edge2 = v + (#nodestack + 0.5 * movefactor) * dir_l
				-- Make sure, edge2 is bigger than edge1
				if edge1 > edge2 then
					edge1, edge2 = edge2, edge1
				end
			end
			if min_pos[k] > edge2 or max_pos[k] < edge1 then
				ok = false
				break
			end
		end
		if ok then
			local ent = obj:get_luaentity()
			if obj:is_player() or
                (ent and not mvps.fixed.is_fixed_entity(ent.name)) then
				local np = vector.add(obj_pos, dir)
				-- Move only if destination is not solid or object is inside stack:
				local nn = minetest.get_node(np)
				local node_def = minetest.registered_nodes[nn.name]
				local obj_offset = dir_l * (obj_pos[dir_k] - pos[dir_k])
				if (node_def and not node_def.walkable) or
						(obj_offset >= 0 and
						obj_offset <= #nodestack - 0.5) then
					obj:move_to(np)
				end
			end
		end
	end
end

-- Never push into unloaded blocks. Don’t try to pull from them, either.
-- TODO: load blocks instead, as with wires.
mvps.fixed.register_node("ignore")

mvps.fixed.register_node("default:chest_locked")
mvps.register_on_move(function(moved_nodes)
	for i = 1, #moved_nodes do
		local moved_node = moved_nodes[i]
		mesecons.on_placenode(moved_node.pos, moved_node.node)
		minetest.after(0, function()
			minetest.check_for_falling(moved_node.oldpos)
			minetest.check_for_falling(moved_node.pos)
		end)
		local node_def = minetest.registered_nodes[moved_node.node.name]
		if node_def and
           node_def.mesecon and
           node_def.mesecons.on_mvps_move then
			node_def.mesecons.on_mvps_move(moved_node.pos, moved_node.node,
					moved_node.oldpos, moved_node.meta)
		end
	end
end)
