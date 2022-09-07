

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("dst1") and inv:is_empty("dst2") and inv:is_empty("src1") and inv:is_empty("src2")
end
local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
    -- Allow the player to place stuff in the source boxes, but not in destination
	if listname == "src1" then
		return stack:get_count()
	elseif listname == "src2" then
		return stack:get_count()
	elseif listname == "dst1" then
		return 0
	elseif listname == "dst2" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

local function oven_button_press(pos, formname, fields, player)
    if fields.quit then return end
    
	local meta = minetest.get_meta(pos)
    
    meta:set_int("idle_counter", 0)

    if fields.temp0 then
        meta:set_int("temp_target", 0)
    elseif fields.temp1 then
        meta:set_int("temp_target", 100)
    elseif fields.temp2 then
        meta:set_int("temp_target", 200)
    elseif fields.temp3 then
        meta:set_int("temp_target", 300)
    elseif fields.auto_off_on then
        meta:set_string("auto_off", "true")
    elseif fields.auto_off_off then
        meta:set_string("auto_off", "false")
    end
    
    -- Start the timer to start changing the temp
    minetest.get_node_timer(pos):start(1.0)
end

local function oven_node_timer(pos, elapsed)
	--
	-- Inizialize metadata
	--
	local meta = minetest.get_meta(pos)
	local auto_off = meta:get_string("auto_off") == "true"
    -- Increment the idle counter on load. It is reset if it is currently cooking
	local idle_counter = (meta:get_int("idle_counter") or 0) + 1
	local temperature = meta:get_int("temp") or 0
	local temp_target = meta:get_int("temp_target") or 0
    
    local is_at_temp = temperature == temp_target
    if temperature < temp_target then
        temperature = temperature + 10
        idle_counter = 0
    elseif temperature > temp_target then
        temperature = temperature - 10
        idle_counter = 0
    end
        
    local cookable1, cookable2
        
    local srclist1, srclist2
    local inv = meta:get_inventory()
    srclist1 = inv:get_list("src1")
    srclist2 = inv:get_list("src2")

    local src_time1 = meta:get_float("src_time1") or 0
    local src_time2 = meta:get_float("src_time2") or 0

    if is_at_temp and temp_target > 0 then
        local method_name
        if temp_target == 300 then
            method_name = "cook_high"
        elseif temp_target == 200 then
            method_name = "cook_med"
        else --if temp_target == 100 then
            method_name = "cook_low"
        end
        
        local output1, output2
        
    	local update = true
        
        local elapsed1, elapsed2 = elapsed, elapsed
        while elapsed1 > 0 and update do
            update = false

    		srclist1 = inv:get_list("src1")

            -- Cooking

    		local aftercooked1
    		cooked1, aftercooked1 = cooking._get_craft_result({method = method_name, width = 1, items = srclist1})
    		cookable1 = cooked1.time ~= 0

            local el1 = math.min(cooked1.time - src_time1, elapsed1)
            if cookable1 then
                src_time1 = src_time1 + el1
                idle_counter = 0
                if src_time1 >= cooked1.time then
                    -- Place result in dst list if possible
                    if inv:room_for_item("dst1", cooked1.item) then
                        inv:add_item("dst1", cooked1.item)
                        inv:set_stack("src1", 1, aftercooked1.items[1])
                        src_time1 = src_time1 - cooked1.time
                        update = true
                    end
                --[[else
                    update = true]]
                end
            end
            
            elapsed1 = elapsed1 - el1
        end

        if srclist1[1]:is_empty() then
    		src_time1 = 0
    	end
        
        update = true
        while elapsed2 > 0 and update do
            update = false

    		srclist2 = inv:get_list("src2")
            
            -- Cooking

    		local aftercooked2
            
    		cooked2, aftercooked2 = cooking._get_craft_result({method = method_name, width = 1, items = srclist2})
    		cookable2 = cooked2.time ~= 0
            
            local el2 = math.min(cooked2.time - src_time2, elapsed2)
            if cookable2 then
                idle_counter = 0
                src_time2 = src_time2 + el2
                if src_time2 >= cooked2.time then
                    -- Place result in dst list if possible
                    if inv:room_for_item("dst2", cooked2.item) then
                        inv:add_item("dst2", cooked2.item)
                        inv:set_stack("src2", 1, aftercooked2.items[1])
                        src_time2 = src_time2 - cooked2.time
                        update = true
                    end
                --[[else
                    update = true]]
                end
            end

            elapsed2 = elapsed2 - el2
        end

        if srclist2[1]:is_empty() then
    		src_time2 = 0
    	end
        
        meta:set_float("src_time1", src_time1)
        meta:set_float("src_time2", src_time2)
    end

    local formspec
    local item_state1, item_state2
    local item_percent1, item_percent2 = 0, 0
    if cookable1 then
        item_percent1 = math.floor(src_time1 / cooked1.time * 100)
        if item_percent1 > 100 then
            item_state1 = "100% (output full)"
        else
            item_state1 = item_percent1 .. "%"
        end
    else
        if srclist1 and srclist1[1]:is_empty() then
            item_state1 = "Empty"
        else
            item_state1 = "Not cooking"
        end
    end
    
    if cookable2 then
        item_percent2 = math.floor(src_time2 / cooked2.time * 100)
        if item_percent2 > 100 then
            item_state2 = "100% (output full)"
        else
            item_state2 = item_percent2 .. "%"
        end
    else
        if srclist2[1]:is_empty() then
            item_state2 = "Empty"
        else
            item_state2 = "Not cooking"
        end
    end

    local active = "inactive"
    local result = false

	if temp_target ~= 0 or temperature ~= 0 then
        if temperature < temp_target then
            active = "heating"
        elseif temperature > temp_target then
            active = "cooling"
        else
            active = "active"
        end
		formspec = cooking.get_oven_active_formspec(item_percent1, item_percent2, temperature, auto_off)
		swap_node(pos, "cooking:oven_active")
		-- make sure timer restarts automatically
		result = true
	else
		formspec = cooking.get_oven_inactive_formspec(auto_off)
		swap_node(pos, "cooking:oven")
		-- stop timer on the inactive oven
		minetest.get_node_timer(pos):stop()
	end
    
	local infotext = "Oven " .. active .. "\n(Item 1: " .. item_state1 ..
		"; Item 2: " .. item_state2 ..
		")"
    
    if auto_off and temp_target > 0 and idle_counter >= 20 then
        -- Start cooling if we have auto_off on
	    meta:set_int("temp_target", 0)
    end

	--
	-- Set meta values
	--
	meta:set_int("temp", temperature)
    meta:set_int("idle_counter", idle_counter)
	meta:set_string("formspec", formspec)
	meta:set_string("infotext", infotext)

	return result
end

-- Oven
minetest.register_node("cooking:oven", {
    description = "Oven",
    drawtype = "nodebox",
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_furnace_side.png", "default_furnace_side.png",
		"default_furnace_side.png", "cooking_oven_front.png"
	},
    node_box = {
            type = "fixed",
            fixed = {
                -- Back
                {-1/2,  -1/2,  1/4,   1/2,   1/2,  1/2},
                -- Left side
                {-1/2,  -1/2, -1/2, -5/16,   1/2,  1/4},
                -- Right side
                {5/16,  -1/2, -1/2,   1/2,   1/2,  1/4},
                -- Bottom
                {-5/16, -1/2, -1/2,  5/16, -5/16,  1/4},
                -- Top
                {-5/16, 1/16, -1/2,  5/16,   1/2,  1/4},
            }
    },
    collision_box = {-1/2, -1/2, -1/2, 1/2, 1/2, 1/2},
	paramtype2 = "facedir",
    paramtype = "light",
    is_ground_content = false,
    walkable = true,
    groups = {cracky = 2, creative = 1, oven = 1},
    sounds = default.node_sound_stone_defaults(),
        
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", cooking.get_oven_inactive_formspec(false))
		local inv = meta:get_inventory()
		inv:set_size('src1', 1)
		inv:set_size('src2', 1)
		inv:set_size('dst1', 2)
		inv:set_size('dst2', 2)
	end,

    on_receive_fields = oven_button_press,
	can_dig = can_dig,
	on_timer = oven_node_timer,

	on_metadata_inventory_move = function(pos)
		-- start timer function, it will sort out whether oven can cook or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_metadata_inventory_put = function(pos)
		-- start timer function, it will sort out whether oven can cook or not.
		minetest.get_node_timer(pos):start(1.0)
	end,
	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "src1", drops)
		default.get_inventory_drops(pos, "src2", drops)
		default.get_inventory_drops(pos, "dst1", drops)
		default.get_inventory_drops(pos, "dst2", drops)
		drops[#drops+1] = "cooking:oven"
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
--    inventory_image = fence_texture,
--    wield_image = fence_texture
})

minetest.register_node("cooking:oven_active", {
    description = "Oven (Active)",
    drawtype = "nodebox",
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_furnace_side.png", "default_furnace_side.png",
		"default_furnace_side.png", "cooking_oven_front_active.png"
	},
    node_box = {
            type = "fixed",
            fixed = {
                -- Back
                {-1/2,  -1/2,  1/4,   1/2,   1/2,  1/2},
                -- Left side
                {-1/2,  -1/2, -1/2, -5/16,   1/2,  1/4},
                -- Right side
                {5/16,  -1/2, -1/2,   1/2,   1/2,  1/4},
                -- Bottom
                {-5/16, -1/2, -1/2,  5/16, -5/16,  1/4},
                -- Top
                {-5/16, 1/16, -1/2,  5/16,   1/2,  1/4},
            }
    },
    collision_box = {-1/2, -1/2, -1/2, 1/2, 1/2, 1/2},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "cooking:oven",
    paramtype = "light",
    is_ground_content = false,
    walkable = true,
    groups = {cracky = 2, not_in_creative_inventory = 1},
    sounds = default.node_sound_stone_defaults(),

    on_receive_fields = oven_button_press,
	on_timer = oven_node_timer,
	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})



-- crafting recipe

minetest.register_craft({
	output = 'cooking:oven',
	recipe = {
		{'group:stone', 'group:stone', 'group:stone'},
		{'group:stone', 'default:glass', 'group:stone'},
		{'group:stone', 'default:mese_crystal', 'group:stone'},
	}
})