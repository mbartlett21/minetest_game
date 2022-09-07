-- Dig and place services

mesecons.on_placenode = function(pos, node)
	mesecons.execute_autoconnect_hooks_now(pos, node)

	-- Receptors: Send on signal when active
	if mesecons.is_receptor_on(node.name) then
		mesecons.receptor_on(pos, mesecons.receptor_get_rules(node))
	end

	-- Conductors: Send turnon signal when powered or replace by respective offstate conductor
	-- if placed conductor is an onstate one
	if mesecons.is_conductor(node.name) then
		local sources = mesecons.is_powered(pos)
		if sources then
			-- also call receptor_on if itself is powered already, so that neighboring
			-- conductors will be activated (when pushing an on-conductor with a piston)
			for _, s in ipairs(sources) do
				local rule = vector.subtract(pos, s)
				mesecons.turnon(pos, rule)
			end
			--mesecons.receptor_on (pos, mesecons.conductor_get_rules(node))
		elseif mesecons.is_conductor_on(node) then
			node.name = mesecons.get_conductor_off(node)
			minetest.swap_node(pos, node)
		end
	end

	-- Effectors: Send changesignal and activate or deactivate
	if mesecons.is_effector(node.name) then
		local powered_rules = {}
		local unpowered_rules = {}

		-- for each input rule, check if powered
		for _, r in ipairs(mesecons.effector_get_rules(node)) do
			local powered = mesecons.is_powered(pos, r)
			if powered then table.insert(powered_rules, r)
			else table.insert(unpowered_rules, r) end

			local state = powered and mesecons.state.on or mesecons.state.off
			mesecons.changesignal(pos, node, r, state, 1)
		end

		if (#powered_rules > 0) then
			for _, r in ipairs(powered_rules) do
				mesecons.activate(pos, node, r, 1)
			end
		else
			for _, r in ipairs(unpowered_rules) do
				mesecons.deactivate(pos, node, r, 1)
			end
		end
	end
end

mesecons.on_dignode = function(pos, node)
	if mesecons.is_conductor_on(node) then
		mesecons.receptor_off(pos, mesecons.conductor_get_rules(node))
	elseif mesecons.is_receptor_on(node.name) then
		mesecons.receptor_off(pos, mesecons.receptor_get_rules(node))
	end

	mesecons.execute_autoconnect_hooks_queue(pos, node)
end

function mesecons.on_blastnode(pos, intensity)
	local node = minetest.get_node(pos)
	minetest.remove_node(pos)
	mesecons.on_dignode(pos, node)
	return minetest.get_node_drops(node.name, "")
end

minetest.register_on_placenode(mesecons.on_placenode)
minetest.register_on_dignode(mesecons.on_dignode)
