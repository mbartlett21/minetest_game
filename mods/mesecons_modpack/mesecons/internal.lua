-- Internal.lua - The core of mesecons
--
-- For more practical developer resources see http://mesecons.net/developers.php

--[[
Function overview
mesecons.get_effector(nodename)	--> Returns the mesecons.effector -specification in the nodedef by the nodename
mesecons.get_receptor(nodename)	--> Returns the mesecons.receptor -specification in the nodedef by the nodename
mesecons.get_conductor(nodename)    --> Returns the mesecons.conductor-specification in the nodedef by the nodename
mesecons.get_any_inputrules (node)  --> Returns the rules of a node if it is a conductor or an effector
mesecons.get_any_outputrules (node) --> Returns the rules of a node if it is a conductor or a receptor

RECEPTORS
mesecons.is_receptor(nodename)     --> Returns true if nodename is a receptor
mesecons.is_receptor_on(nodename)  --> Returns true if nodename is an receptor with state = mesecons.state.on
mesecons.is_receptor_off(nodename) --> Returns true if nodename is an receptor with state = mesecons.state.off
mesecons.receptor_get_rules(node)  --> Returns the rules of the receptor (mesecons.rules.default if none specified)

EFFECTORS
mesecons.is_effector(nodename)     --> Returns true if nodename is an effector
mesecons.is_effector_on(nodename)  --> Returns true if nodename is an effector with nodedef.mesecons.effector.action_off
mesecons.is_effector_off(nodename) --> Returns true if nodename is an effector with nodedef.mesecons.effector.action_on
mesecons.effector_get_rules(node)  --> Returns the input rules of the effector (mesecons.rules.default if none specified)

SIGNALS
mesecons.activate(pos, node, depth) --> Activates the effector node at the specific pos (calls nodedef.mesecons.effector.action_on), higher depths are executed later
mesecons.deactivate(pos, node, depth) --> Deactivates the effector node at the specific pos (calls nodedef.mesecons.effector.action_off), higher depths are executed later
mesecons.changesignal(pos, node, rulename, newstate, depth) --> Changes the effector node at the specific pos (calls nodedef.mesecons.effector.action_change), higher depths are executed later

CONDUCTORS
mesecons.is_conductor(nodename)  --> Returns true if nodename is a conductor
mesecons.is_conductor_on(node)   --> Returns true if node is a conductor with state = mesecons.state.on
mesecons.is_conductor_off(node)  --> Returns true if node is a conductor with state = mesecons.state.off
mesecons.get_conductor_on(node_off)  --> Returns the onstate  nodename of the conductor
mesecons.get_conductor_off(node_on)  --> Returns the offstate nodename of the conductor
mesecons.conductor_get_rules(node)   --> Returns the input+output rules of a conductor (mesecons.rules.default if none specified)

HIGH-LEVEL Internals
mesecons.is_power_on(pos)  --> Returns true if pos emits power in any way
mesecons.is_power_off(pos) --> Returns true if pos does not emit power in any way
mesecons.is_powered(pos)   --> Returns true if pos is powered by a receptor or a conductor
            
RULES ROTATION helpers
mesecons.rules.rotate_right(rules)
mesecons.rules.rotate_left(rules)
mesecons.rules.rotate_up(rules)
mesecons.rules.rotate_down(rules)
These functions return rules that have been rotated in the specific direction
]]

-- General
function mesecons.get_effector(nodename)
	return (minetest.registered_nodes[nodename]
        and minetest.registered_nodes[nodename].mesecons
        and minetest.registered_nodes[nodename].mesecons.effector) or nil
end

function mesecons.get_receptor(nodename)
	return (minetest.registered_nodes[nodename]
        and minetest.registered_nodes[nodename].mesecons
        and minetest.registered_nodes[nodename].mesecons.receptor) or nil
end

function mesecons.get_conductor(nodename)
	return (minetest.registered_nodes[nodename]
        and minetest.registered_nodes[nodename].mesecons
        and minetest.registered_nodes[nodename].mesecons.conductor) or nil
end

function mesecons.get_any_outputrules(node)
	if not node then return nil end

	if mesecons.is_conductor(node.name) then
		return mesecons.conductor_get_rules(node)
	elseif mesecons.is_receptor(node.name) then
		return mesecons.receptor_get_rules(node)
	end
end

function mesecons.get_any_inputrules(node)
	if not node then return nil end

	if mesecons.is_conductor(node.name) then
		return mesecons.conductor_get_rules(node)
	elseif mesecons.is_effector(node.name) then
		return mesecons.effector_get_rules(node)
	end
end

function mesecons.get_any_rules(node)
	return mesecons.mergetable(mesecons.get_any_inputrules(node) or {},
		mesecons.get_any_outputrules(node) or {})
end

-- Receptors
-- Nodes that can power mesecons
function mesecons.is_receptor_on(nodename)
	local receptor = mesecons.get_receptor(nodename)
	if receptor and receptor.state == mesecons.state.on then
		return true
	end
	return false
end

function mesecons.is_receptor_off(nodename)
	local receptor = mesecons.get_receptor(nodename)
	if receptor and receptor.state == mesecons.state.off then
		return true
	end
	return false
end

function mesecons.is_receptor(nodename)
	local receptor = mesecons.get_receptor(nodename)
	if receptor then
		return true
	end
	return false
end

function mesecons.receptor_get_rules(node)
	local receptor = mesecons.get_receptor(node.name)
	if receptor then
		local rules = receptor.rules
		if type(rules) == 'function' then
			return rules(node)
		elseif rules then
			return rules
		end
	end

	return mesecons.rules.default
end

-- Effectors
-- Nodes that can be powered by mesecons
function mesecons.is_effector_on(nodename)
	local effector = mesecons.get_effector(nodename)
	if effector and effector.action_off then
		return true
	end
	return false
end

function mesecons.is_effector_off(nodename)
	local effector = mesecons.get_effector(nodename)
	if effector and effector.action_on then
		return true
	end
	return false
end

function mesecons.is_effector(nodename)
	local effector = mesecons.get_effector(nodename)
	if effector then
		return true
	end
	return false
end

function mesecons.effector_get_rules(node)
	local effector = mesecons.get_effector(node.name)
	if effector then
		local rules = effector.rules
		if type(rules) == 'function' then
			return rules(node)
		elseif rules then
			return rules
		end
	end
	return mesecons.rules.default
end

-- #######################
-- # Signals (effectors) #
-- #######################

-- Activation:
mesecons.queue.add_function("activate", function (pos, rulename)
	local node = mesecons.get_node_force(pos)
	if not node then return end

	local effector = mesecons.get_effector(node.name)

	if effector and effector.action_on then
		effector.action_on(pos, node, rulename)
	end
end)

function mesecons.activate(pos, node, rulename, depth)
	if rulename == nil then
		for _,rule in ipairs(mesecons.effector_get_rules(node)) do
			mesecons.activate(pos, node, rule, depth + 1)
		end
		return
	end
	mesecons.queue.add_action(pos, "activate", {rulename}, nil, rulename, 1 / depth)
end


-- Deactivation
mesecons.queue.add_function("deactivate", function (pos, rulename)
	local node = mesecons.get_node_force(pos)
	if not node then return end

	local effector = mesecons.get_effector(node.name)

	if effector and effector.action_off then
		effector.action_off(pos, node, rulename)
	end
end)

function mesecons.deactivate(pos, node, rulename, depth)
	if rulename == nil then
		for _,rule in ipairs(mesecons.effector_get_rules(node)) do
			mesecons.deactivate(pos, node, rule, depth + 1)
		end
		return
	end
	mesecons.queue.add_action(pos, "deactivate", {rulename}, nil, rulename, 1 / depth)
end


-- Change
mesecons.queue.add_function("change", function (pos, rulename, changetype)
	local node = mesecons.get_node_force(pos)
	if not node then return end

	local effector = mesecons.get_effector(node.name)

	if effector and effector.action_change then
		effector.action_change(pos, node, rulename, changetype)
	end
end)

function mesecons.changesignal(pos, node, rulename, newstate, depth)
	if rulename == nil then
		for _,rule in ipairs(mesecons.effector_get_rules(node)) do
			mesecons.changesignal(pos, node, rule, newstate, depth + 1)
		end
		return
	end

	-- Include "change" in overwritecheck so that it cannot be overwritten
	-- by "active" / "deactivate" that will be called upon the node at the same time.
	local overwritecheck = {"change", rulename}
	mesecons.queue.add_action(pos, "change", {rulename, newstate}, nil, overwritecheck, 1 / depth)
end

-- Conductors

function mesecons.is_conductor_on(node, rulename)
	if not node then return false end

	local conductor = mesecons.get_conductor(node.name)
	if conductor then
		if conductor.state then
			return conductor.state == mesecons.state.on
		end
		if conductor.states then
			if not rulename then
				return mesecons.getstate(node.name, conductor.states) ~= 1
			end
			local bit = mesecons.rules.to_bit(rulename, mesecons.conductor_get_rules(node))
			local binstate = mesecons.getbinstate(node.name, conductor.states)
			return mesecons.get_bit(binstate, bit)
		end
	end

	return false
end

function mesecons.is_conductor_off(node, rulename)
	if not node then return false end

	local conductor = mesecons.get_conductor(node.name)
	if conductor then
		if conductor.state then
			return conductor.state == mesecons.state.off
		end
		if conductor.states then
			if not rulename then
				return mesecons.getstate(node.name, conductor.states) == 1
			end
			local bit = mesecons.rules.to_bit(rulename, mesecons.conductor_get_rules(node))
			local binstate = mesecons.getbinstate(node.name, conductor.states)
			return not mesecons.get_bit(binstate, bit)
		end
	end

	return false
end

function mesecons.is_conductor(nodename)
	local conductor = mesecons.get_conductor(nodename)
	if conductor then
		return true
	end
	return false
end

function mesecons.get_conductor_on(node_off, rulename)
	local conductor = mesecons.get_conductor(node_off.name)
	if conductor then
		if conductor.onstate then
			return conductor.onstate
		end
		if conductor.states then
			local bit = mesecons.rules.to_bit(rulename, mesecons.conductor_get_rules(node_off))
			local binstate = mesecons.getbinstate(node_off.name, conductor.states)
			binstate = mesecons.set_bit(binstate, bit, "1")
			return conductor.states[tonumber(binstate,2)+1]
		end
	end
	return offstate
end

function mesecons.get_conductor_off(node_on, rulename)
	local conductor = mesecons.get_conductor(node_on.name)
	if conductor then
		if conductor.offstate then
			return conductor.offstate
		end
		if conductor.states then
			local bit = mesecons.rules.to_bit(rulename, mesecons.conductor_get_rules(node_on))
			local binstate = mesecons.getbinstate(node_on.name, conductor.states)
			binstate = mesecons.set_bit(binstate, bit, "0")
			return conductor.states[tonumber(binstate,2)+1]
		end
	end
	return onstate
end

function mesecons.conductor_get_rules(node)
	local conductor = mesecons.get_conductor(node.name)
	if conductor then
		local rules = conductor.rules
		if type(rules) == 'function' then
			return rules(node)
		elseif rules then
			return rules
		end
	end
	return mesecons.rules.default
end

-- some more general high-level stuff

function mesecons.is_power_on(pos, rulename)
	local node = mesecons.get_node_force(pos)
	if node and (mesecons.is_conductor_on(node, rulename) or mesecons.is_receptor_on(node.name)) then
		return true
	end
	return false
end

function mesecons.is_power_off(pos, rulename)
	local node = mesecons.get_node_force(pos)
	if node and (mesecons.is_conductor_off(node, rulename) or mesecons.is_receptor_off(node.name)) then
		return true
	end
	return false
end

-- Turn off an equipotential section starting at `pos`, which outputs in the direction of `link`.
-- Breadth-first search. Map is abstracted away in a voxelmanip.
-- Follow all all conductor paths replacing conductors that were already
-- looked at, activating / changing all effectors along the way.
function mesecons.turnon(pos, link)
	local frontiers = {{pos = pos, link = link}}

	local depth = 1
	while frontiers[1] do
		local f = table.remove(frontiers, 1)
		local node = mesecons.get_node_force(f.pos)

		if not node then
			-- Area does not exist; do nothing
		elseif mesecons.is_conductor_off(node, f.link) then
			local rules = mesecons.conductor_get_rules(node)

			-- Call turnon on neighbors
			for _, r in ipairs(mesecons.rules.to_meta(f.link, rules)) do
				local np = vector.add(f.pos, r)
				for _, l in ipairs(mesecons.rules_link_rule_all(f.pos, r)) do
					table.insert(frontiers, {pos = np, link = l})
				end
			end

			mesecons.swap_node_force(f.pos, mesecons.get_conductor_on(node, f.link))
		elseif mesecons.is_effector(node.name) then
			mesecons.changesignal(f.pos, node, f.link, mesecons.state.on, depth)
			if mesecons.is_effector_off(node.name) then
				mesecons.activate(f.pos, node, f.link, depth)
			end
		end
		depth = depth + 1
	end
end

-- Turn on an equipotential section starting at `pos`, which outputs in the direction of `link`.
-- Breadth-first search. Map is abstracted away in a voxelmanip.
-- Follow all all conductor paths replacing conductors that were already
-- looked at, deactivating / changing all effectors along the way.
-- In case an onstate receptor is discovered, abort the process by returning false, which will
-- cause `receptor_off` to discard all changes made in the voxelmanip.
-- Contrary to turnon, turnoff has to cache all change and deactivate signals so that they will only
-- be called in the very end when we can be sure that no conductor was found along the path.
--
-- Signal table entry structure:
-- {
--	pos = position of effector,
--	node = node descriptor (name, param1 and param2),
--	link = link the effector is connected to,
--	depth = indicates order in which signals wire fired, higher is later
-- }
function mesecons.turnoff(pos, link)
	local frontiers = {{pos = pos, link = link}}
	local signals = {}

	local depth = 1
	while frontiers[1] do
		local f = table.remove(frontiers, 1)
		local node = mesecons.get_node_force(f.pos)

		if not node then
			-- Area does not exist; do nothing
		elseif mesecons.is_conductor_on(node, f.link) then
			local rules = mesecons.conductor_get_rules(node)
			for _, r in ipairs(mesecons.rules.to_meta(f.link, rules)) do
				local np = vector.add(f.pos, r)

				-- Check if an onstate receptor is connected. If that is the case,
				-- abort this turnoff process by returning false. `receptor_off` will
				-- discard all the changes that we made in the voxelmanip:
				for _, l in ipairs(mesecons.rules_link_rule_all_inverted(f.pos, r)) do
					if mesecons.is_receptor_on(mesecons.get_node_force(np).name) then
						return false
					end
				end

				-- Call turnoff on neighbors
				for _, l in ipairs(mesecons.rules_link_rule_all(f.pos, r)) do
					table.insert(frontiers, {pos = np, link = l})
				end
			end

			mesecons.swap_node_force(f.pos, mesecons.get_conductor_off(node, f.link))
		elseif mesecons.is_effector(node.name) then
			table.insert(signals, {
				pos = f.pos,
				node = node,
				link = f.link,
				depth = depth
			})
		end
		depth = depth + 1
	end

	for _, sig in ipairs(signals) do
		mesecons.changesignal(sig.pos, sig.node, sig.link, mesecons.state.off, sig.depth)
		if mesecons.is_effector_on(sig.node.name) and not mesecons.is_powered(sig.pos) then
			mesecons.deactivate(sig.pos, sig.node, sig.link, sig.depth)
		end
	end

	return true
end

-- Get all linking inputrules of inputnode (effector or conductor) that is connected to
-- outputnode (receptor or conductor) at position `output` and has an output in direction `rule`
function mesecons.rules_link_rule_all(output, rule)
	local input = vector.add(output, rule)
	local inputnode = mesecons.get_node_force(input)
	local inputrules = mesecons.get_any_inputrules(inputnode)
	if not inputrules then
		return {}
	end
	local rules = {}

	for _, inputrule in ipairs(mesecons.rules.flatten(inputrules)) do
		-- Check if input accepts from output
		if  vector.equals(vector.add(input, inputrule), output) then
			table.insert(rules, inputrule)
		end
	end

	return rules
end

-- Get all linking outputnodes of outputnode (receptor or conductor) that is connected to
-- inputnode (effector or conductor) at position `input` and has an input in direction `rule`
function mesecons.rules_link_rule_all_inverted(input, rule)
	local output = vector.add(input, rule)
	local outputnode = mesecons.get_node_force(output)
	local outputrules = mesecons.get_any_outputrules(outputnode)
	if not outputrules then
		return {}
	end
	local rules = {}

	for _, outputrule in ipairs(mesecons.rules.flatten(outputrules)) do
		if  vector.equals(vector.add(output, outputrule), input) then
			table.insert(rules, mesecons.rules.invert(outputrule))
		end
	end
	return rules
end

function mesecons.is_powered(pos, rule)
	local node = mesecons.get_node_force(pos)
	local rules = mesecons.get_any_inputrules(node)
	if not rules then return false end

	-- List of nodes that send out power to pos
	local sourcepos = {}

	if not rule then
		for _, rule in ipairs(mesecons.rules.flatten(rules)) do
			local rulenames = mesecons.rules_link_rule_all_inverted(pos, rule)
			for _, rname in ipairs(rulenames) do
				local np = vector.add(pos, rname)
				local nn = mesecons.get_node_force(np)

				if (mesecons.is_conductor_on(nn, mesecons.rules.invert(rname))
				or mesecons.is_receptor_on(nn.name)) then
					table.insert(sourcepos, np)
				end
			end
		end
	else
		local rulenames = mesecons.rules_link_rule_all_inverted(pos, rule)
		for _, rname in ipairs(rulenames) do
			local np = vector.add(pos, rname)
			local nn = mesecons.get_node_force(np)
			if (mesecons.is_conductor_on (nn, mesecons.rules.invert(rname))
			or mesecons.is_receptor_on (nn.name)) then
				table.insert(sourcepos, np)
			end
		end
	end

	-- Return FALSE if not powered, return list of sources if is powered
	if (#sourcepos == 0) then return false
	else return sourcepos end
end
