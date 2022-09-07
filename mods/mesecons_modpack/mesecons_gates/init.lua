

local nodebox = {
	type = "fixed",
	fixed = {-8/16, -8/16, -8/16, 8/16, -7/16, 8/16 },
}

local function get_output_rules(node)
    local rules = {{ x = 1, y = 0, z = 0 }}
	for rotations = 0, node.param2 - 1 do
		rules = mesecons.rules.rotate_left(rules)
	end
    return rules
end

local function get_one_input_rules(node)
    local rules = {{ x = -1, y = 0, z = 0 }}
	for rotations = 0, node.param2 - 1 do
		rules = mesecons.rules.rotate_left(rules)
	end
    return rules
end

local function get_two_input_rules(node)
    local rules = {
            {x = 0, y = 0, z =  1, name = "input1" },
            {x = 0, y = 0, z = -1, name = "input2" }
        }
	for rotations = 0, node.param2 - 1 do
		rules = mesecons.rules.rotate_left(rules)
	end
    return rules
end

local function set_gate(pos, node, state)
	local gate = minetest.registered_nodes[node.name]

	if state then
		minetest.swap_node(pos, {name = gate.onstate, param2 = node.param2})
		mesecons.receptor_on(pos, get_output_rules(node))
	else
		minetest.swap_node(pos, {name = gate.offstate, param2 = node.param2})
		mesecons.receptor_off(pos, get_output_rules(node))
	end
end

local function update_gate(pos, node, link, newstate)
	local gate = minetest.registered_nodes[node.name]

	if gate.gate_inputnumber == 1 then
		set_gate(pos, node, gate.assess(newstate == "on"))

	elseif gate.gate_inputnumber == 2 then
		local meta = minetest.get_meta(pos)
		meta:set_int(link.name, newstate == "on" and 1 or 0)

		local val1 = meta:get_int("input1") == 1
		local val2 = meta:get_int("input2") == 1
		set_gate(pos, node, gate.assess(val1, val2))
	end
end

local function register_gate(name, inputnumber, assess, recipe, description)
	local get_inputrules = inputnumber == 2 and get_two_input_rules or get_one_input_rules

	local basename = "mesecons_gates:" .. name
	mesecons.register_node(basename, {
            description = description,
            inventory_image = "jeija_gate_off.png^jeija_gate_" .. name .. ".png",
            paramtype = "light",
            paramtype2 = "facedir",
            is_ground_content = false,
            drawtype = "nodebox",
            drop = basename.."_off",
            selection_box = nodebox,
            node_box = nodebox,
            walkable = true,
            sounds = default.node_sound_stone_defaults(),
            assess = assess,
            onstate = basename.."_on",
            offstate = basename.."_off",
            gate_inputnumber = inputnumber,
        },{
            tiles = { "jeija_microcontroller_bottom.png^jeija_gate_off.png^jeija_gate_" .. name .. ".png" },
            groups = { dig_immediate = 2, creative = 1 },
            mesecons = {
                receptor = {
                    state = "off",
                    rules = get_output_rules
                },
                effector = {
                    rules = get_inputrules,
                    action_change = update_gate
                }
            }
        },{
            tiles = { "jeija_microcontroller_bottom.png^jeija_gate_on.png^jeija_gate_" .. name .. ".png" },
            groups = { dig_immediate = 2, not_in_creative_inventory = 1 },
            mesecons = { 
                receptor = {
                    state = "on",
                    rules = get_output_rules
                },
                effector = {
                    rules = get_inputrules,
                    action_change = update_gate
                }
            },
            light_source = 3
	})

	minetest.register_craft({output = basename.."_off", recipe = recipe})
end

register_gate("diode", 1, function (input) return input end,
	{{"mesecons:wire", "mesecons:torch_on", "mesecons:torch_on"}},
	"Diode")

register_gate("not", 1, function (input) return not input end,
	{{"mesecons:wire", "mesecons:torch_on", "mesecons:wire"}},
	"NOT Gate")

register_gate("and", 2, function (val1, val2) return val1 and val2 end,
	{{"mesecons:wire", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons:wire"},
	 {"mesecons:wire", "", ""}},
	"AND Gate")

register_gate("nand", 2, function (val1, val2) return not (val1 and val2) end,
	{{"mesecons:wire", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons:torch_on"},
	 {"mesecons:wire", "", ""}},
	"NAND Gate")

register_gate("xor", 2, function (val1, val2) return (val1 or val2) and not (val1 and val2) end,
	{{"mesecons:wire", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons_materials:silicon"},
	 {"mesecons:wire", "", ""}},
	"XOR Gate")

register_gate("or", 2, function (val1, val2) return (val1 or val2) end,
	{{"mesecons:wire", "", ""},
	 {"", "mesecons:wire", "mesecons:wire"},
	 {"mesecons:wire", "", ""}},
	"OR Gate")

register_gate("nor", 2, function (val1, val2) return not (val1 or val2) end,
	{{"mesecons:wire", "", ""},
	 {"", "mesecons:wire", "mesecons:torch_on"},
	 {"mesecons:wire", "", ""}},
	"NOR Gate")
