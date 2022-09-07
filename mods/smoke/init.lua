smoke = {}
local smoke_defaults = {
    spread = 0,
    cutoff_y = 31000,
    update_interval = 1.2,
    persist = 0.8,
	drawtype = "glasslike",
	paramtype = "light",
	use_texture_alpha = true,
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = ""
}
local get_node = minetest.get_node_or_nil
local swap_node = minetest.swap_node

local find_node = minetest.find_node_near

local air = { name = "air" }

local h_possible_positions = {
    -1, 0,
    0, -1,
    1,  0,
    0,  1
}
function smoke.register(name, def)
    assert(name, "Requires name")
    assert(def, "Requires def table")

    for key,val in pairs(smoke_defaults) do
        if def[key] == nil then def[key] = val end
    end


    local smoke_name = "smoke:" .. name
    local smoke_table = { name = smoke_name }
    
    assert(def.sources)
    local sources = def.sources
    local spread = def.spread
    local cutoff_y = def.cutoff_y
    local update_interval = def.update_interval
    local persist = def.persist
    
    def.spread = nil
    def.cutoff_y = nil
    def.sources = nil
    def.update_interval = nil
    def.persist = nil
    
    -- Register node, abms, etc.
    minetest.register_node(":" .. smoke_name, def)
    minetest.register_abm{
        label = smoke_name .. "_sources",
        nodenames = sources,
        neighbors = { "air" },
        interval = update_interval,
        chance = 2,
        action = function(pos)
            local p = find_node(pos, 1, "air")
            if p then swap_node(p, smoke_table) end
        end
    }
    minetest.register_abm{
        label = smoke_name,
        nodenames = { smoke_name },
        neighbors = { "air" },
        interval = update_interval,
        chance = 1,
        action = function(pos)
            if pos.y > cutoff_y then
                swap_node(pos, air)
                return
            end
            if math.random() < 0.9 then
                minetest.after(0, function()
                        -- Smoke disappearing
                        if math.random() > persist then
                            swap_node(pos, air)
                            return
                        end

                        local new_pos = { x = pos.x, y = pos.y + 1, z = pos.z }
                        local above_node = get_node(new_pos)

                        -- Don't move around below an unloaded block
                        if above_node == nil then
                            swap_node(pos, air)
                            return
                        end

                        -- Moving up
                        if above_node.name == "air" and math.random() > spread then
                            swap_node(pos, air)
                            swap_node(new_pos, smoke_table)
                            return
                        end

                        -- Moving sideways
                        new_pos.y = new_pos.y - 1
                        local new_positions = {}
                        for i = 1, 8, 2 do
                            new_pos.x = new_pos.x + h_possible_positions[i]
                            new_pos.z = new_pos.z + h_possible_positions[i + 1]
                            local node = get_node(new_pos)
                            if node and node.name == "air" then
                                new_pos.y = new_pos.y + 1
                                node = get_node(new_pos)
                                if node and node.name == "air" then
                                    new_positions[#new_positions + 1] = {
                                        x = new_pos.x,
                                        y = new_pos.y,
                                        z = new_pos.z
                                    }
                                else
                                    new_positions[#new_positions + 1] = {
                                        x = new_pos.x,
                                        y = new_pos.y - 1,
                                        z = new_pos.z
                                    }
                                end
                                new_pos.y = new_pos.y - 1
                            end
                            new_pos.x = new_pos.x - h_possible_positions[i]
                            new_pos.z = new_pos.z - h_possible_positions[i + 1]
                        end

                        if #new_positions == 0 then
                            return
                        end

                        local choice = new_positions[math.ceil(math.random() * #new_positions)]

                        swap_node(choice, smoke_table)
                        swap_node(pos, air)
                end)
            end
        end
    }
end

smoke.register("smoke", {
        spread = 0,
        update_interval = 1,
        persist = 0.93,
        cutoff_y = 25,
        description = 'Smoke',
        tiles = {{
            name = "smoke.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 6,
            },
        }},
        inventory_image = "smoke.png^[verticalframe:16:1",
        wield_image =  "smoke.png^[verticalframe:16:1",
        damage_per_second = 1,
        drowning = 1,
        post_effect_color = {a = 200, r = 177, g = 177, b = 177},
        sources = { "group:generates_smoke" },
    })