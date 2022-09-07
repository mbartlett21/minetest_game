--[[
 |\    /| ____ ____  ____ _____   ____         _____
 | \  / | |    |     |    |      |    | |\   | |
 |  \/  | |___ ____  |___ |      |    | | \  | |____
 |      | |        | |    |      |    | |  \ |     |
 |      | |___ ____| |___ |____  |____| |   \| ____|
 by Jeija, Uberi (Temperest), sfan5, VanessaE, Hawk777 and contributors



 This mod adds mesecons[=minecraft redstone] and different receptors/effectors to minetest.
 See the documentation on the forum for additional information, especially about crafting


 For basic development resources, see http://mesecons.net/developers.html



Quick draft for the mesecons array in the node's definition
mesecons =
{
	receptor =
	{
		state = mesecons.state.on/off
		rules = rules/get_rules
	},
	effector =
	{
		action_on = function
		action_off = function
		action_change = function
		rules = rules/get_rules
	},
	conductor =
	{
		state = mesecons.state.on/off
		offstate = opposite state (for state = on only)
		onstate = opposite state (for state = off only)
		rules = rules/get_rules
	}
}

]]
-- This has been partly modified by Morgan B

-- PUBLIC VARIABLES
mesecons = {} -- contains all functions and all global variables
mesecons.modpath = minetest.get_modpath("mesecons")

local storage = minetest.get_mod_storage()
function mesecons.storage(store_name)
    local get = function()
        local store = storage:get_string(store_name)
        if store == "" then return {} end
        return minetest.deserialize(store)
    end
    local set = function(table)
        storage:set_string(store_name, minetest.serialize(table))
    end
    return get, set
end

-- Utilities like comparing positions,
-- adding positions and rules,
-- mostly things that make the source look cleaner
dofile(mesecons.modpath.."/util.lua");

-- Presets (eg default rules)
dofile(mesecons.modpath.."/presets.lua");

-- The ActionQueue
-- Saves all the actions that have to be executed in the future
dofile(mesecons.modpath.."/actionqueue.lua");

-- Autoconnect utility
-- This has to be done adter actionqueue because it uses one of the functions in there
dofile(mesecons.modpath.."/autoconnect.lua");

-- Internal stuff
-- This is the most important file
-- it handles signal transmission and basically everything else
-- It is also responsible for managing the nodedef things,
-- like calling action_on/off/change
dofile(mesecons.modpath.."/internal.lua");

-- API
-- these are the only functions you need to remember

local vm = mesecons.vm
mesecons.queue.add_function("receptor_on", function (pos, rules)
	vm.begin()

	rules = rules or mesecons.rules.default

	-- Call turnon on all linking positions
	for _, rule in ipairs(mesecons.rules.flatten(rules)) do
		local np = vector.add(pos, rule)
		local rulenames = mesecons.rules_link_rule_all(pos, rule)
		for _, rulename in ipairs(rulenames) do
			mesecons.turnon(np, rulename)
		end
	end

	vm.commit()
end)

function mesecons.receptor_on(pos, rules)
	mesecons.queue.add_action(pos, "receptor_on", {rules}, nil, rules)
end

mesecons.queue.add_function("receptor_off", function (pos, rules)
	rules = rules or mesecons.rules.default

	-- Call turnoff on all linking positions
	for _, rule in ipairs(mesecons.rules.flatten(rules)) do
		local np = vector.add(pos, rule)
		local rulenames = mesecons.rules_link_rule_all(pos, rule)
		for _, rulename in ipairs(rulenames) do
			vm.begin()
			mesecons.changesignal(np, minetest.get_node(np), rulename, mesecons.state.off, 2)

			-- Turnoff returns true if turnoff process was successful, no onstate receptor
			-- was found along the way. Commit changes that were made in voxelmanip. If turnoff
			-- returns false, an onstate receptor was found, abort voxelmanip transaction.
			if (mesecons.turnoff(np, rulename)) then
				vm.commit()
			else
				vm.abort()
			end
		end
	end
end)

function mesecons.receptor_off(pos, rules)
	mesecons.queue.add_action(pos, "receptor_off", {rules}, nil, rules)
end

--Services like turnoff receptor on dignode and so on
dofile(mesecons.modpath.."/services.lua");

-- Disallow other mods using local stuff
mesecons.storage = nil
mesecons.vm = nil
mesecons.queue.add_function = nil
mesecons.modpath = nil
print("[mesecons] Loaded!")
