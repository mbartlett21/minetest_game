local player_inventory = {}

minetest.register_on_shutdown(function()
        for player_name, _ in pairs(player_inventory) do
            minetest.remove_detached_inventory("creative_inv_" .. player_name)
        end
    end)
local inventory_cache = {}

local function init_creative_cache(items)
	inventory_cache[items] = {}
	local i_cache = inventory_cache[items]

	for name, def in pairs(items) do
		if def.groups.not_in_creative_inventory ~= 1 and
				def.description and def.description ~= "" then
			i_cache[name] = def
		end
	end
	table.sort(i_cache)
	return i_cache
end

function creative.init_creative_inventory(player_name)
	player_inventory[player_name] = {
		size = 0,
		filter = "",
		start_i = 0
	}

    minetest.create_detached_inventory("creative_inv_" .. player_name, {
            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player2)
                local name = player2 and player2:get_player_name() or ""
                if not creative.is_std_enabled_for(name) or
                        to_list == "main" then
                    return 0
                end
                return count
            end,
            allow_put = function(inv, listname, index, stack, player2)
                return 0
            end,
            allow_take = function(inv, listname, index, stack, player2)
                local name = player2 and player2:get_player_name() or ""
                if not creative.is_std_enabled_for(name) then
                    return 0
                end
                return -1
            end,
            -- Disallow move
            on_move = function(inv, from_list, from_index, to_list, to_index, count, player2)
            end,
            -- Log taking items
            on_take = function(inv, listname, index, stack, player2)
                if stack and stack:get_count() > 0 then
                    minetest.log("action", "[creative] " .. player_name .. " takes " .. stack:get_name().. " from creative inv")
                end
            end,
	}, player_name)

	return player_inventory[player_name]
end

local function match(s, filter)
    if filter == "" then
        return 0
    end
    if s:lower():find(filter, 1, true) then
        return #s - #filter
    end
    return nil
end

function creative.update_creative_inventory(player_name, tab_content)
	local inv = player_inventory[player_name] or
			creative.init_creative_inventory(player_name)
	local player_inv = minetest.get_inventory({type = "detached", name = "creative_inv_" .. player_name})

	local items = inventory_cache[tab_content] or init_creative_cache(tab_content)

    local has_full = creative.is_full_enabled_for(player_name)
    local has_unlimited = creative.is_unlimited_enabled_for(player_name)
    
	local creative_list = {}
    local order = {}
	for name, def in pairs(items) do
        if has_full or def.groups.creative == 1 then
            -- Check filter
            local m = match(def.description, inv.filter) or match(def.name, inv.filter)
            if m then
                local stack_name = name .. " " .. (has_unlimited and 1 or def.stack_max or 99)
                creative_list[#creative_list+1] = stack_name
                -- Sort by description length first so closer matches appear earlier
                order[stack_name] = string.format("%02d", m) .. name
            end
        end
	end
    
    table.sort(creative_list, function(a, b) return order[a] < order[b] end)
	player_inv:set_size("main", #creative_list)
	player_inv:set_list("main", creative_list)
	inv.size = #creative_list
end

-- Create the trash field
local trash = minetest.create_detached_inventory("creative_trash", {
	-- Allow the stack to be placed and remove it in on_put()
	-- This allows the creative inventory to restore the stack
	on_put = function(inv, listname)
		inv:set_list(listname, {})
	end
})
trash:set_size("main", 1)

creative.formspec_add = ""

local esc = minetest.formspec_escape
function creative.register_tab(name, title, items)
    sfinv.register_page("creative:" .. name, {
            title = title,
            is_in_nav = function(self, player, context)
                return creative.is_std_enabled_for(player:get_player_name())
            end,
            get = function(self, player, context)
                local player_name = player:get_player_name()
                creative.update_creative_inventory(player_name, items)
                local inv = player_inventory[player_name]
                local start_i = inv.start_i or 0
                local pagenum = math.floor(start_i / (4 * 8) + 1)
                local pagemax = math.ceil(inv.size / (4 * 8))
                return "label[5.9,4.15;" ..
                minetest.colorize("#FFFF00", tostring(pagenum)) .. " / " ..
                tostring(pagemax) .. "]" ..
                [[
                    image[4.08,4.2;0.8,0.8;creative_trash_icon.png]
                    listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]
                    list[detached:creative_trash;main;4.02,4.1;1,1;]
                    image_button[5,4.05;0.8,0.8;creative_prev_icon.png;creative_prev;]
                    image_button[7.2,4.05;0.8,0.8;creative_next_icon.png;creative_next;]
                    image_button[2.63,4.05;0.8,0.8;creative_search_icon.png;creative_search;]
                    image_button[3.25,4.05;0.8,0.8;creative_clear_icon.png;creative_clear;]
                    tooltip[creative_search;Search]
                    tooltip[creative_clear;Reset]
                    tooltip[creative_prev;Previous page]
                    tooltip[creative_next;Next page]
                    listring[current_player;main]
                    field_close_on_enter[creative_filter;false]
                ]] ..
                -- Search field
                "field[0.3,4.2;2.8,1.2;creative_filter;;" .. esc(inv.filter) .. "]" ..
                -- Creative inventory
                "listring[detached:creative_inv_" .. player_name .. ";main]" ..
                "list[detached:creative_inv_" .. player_name .. ";main;0,0;8,4;" .. tostring(start_i) .. "]" ..
                creative.formspec_add
            end,
            on_enter = function(self, player, context)
                local player_name = player:get_player_name()
                local inv = player_inventory[player_name]
                if inv then
                    inv.start_i = 0
                end
            end,
            on_player_receive_fields = function(self, player, context, fields)
                local player_name = player:get_player_name()
                local inv = player_inventory[player_name]
                assert(inv)

                if fields.creative_clear then
                    inv.start_i = 0
                    inv.filter = ""
                    creative.update_creative_inventory(player_name, items)
                    sfinv.set_player_inventory_formspec(player, context)

                elseif fields.creative_search or
                        fields.key_enter_field == "creative_filter" then
                    inv.start_i = 0
                    inv.filter = fields.creative_filter:lower()
                    creative.update_creative_inventory(player_name, items)
                    sfinv.set_player_inventory_formspec(player, context)

                elseif not fields.quit then
                    local start_i = inv.start_i or 0

                    if fields.creative_prev then
                        start_i = start_i - 4 * 8
                        if start_i < 0 then
                            start_i = inv.size - (inv.size % (4 * 8))
                            if inv.size == start_i then
                                start_i = math.max(0, inv.size - (4 * 8))
                            end
                        end
                    elseif fields.creative_next then
                        start_i = start_i + 4 * 8
                        if start_i >= inv.size then
                            start_i = 0
                        end
                    end

                    inv.start_i = start_i
                    sfinv.set_player_inventory_formspec(player, context)
                end
            end
	})
end

creative.register_tab("all", "All", minetest.registered_items)
creative.register_tab("nodes", "Nodes", minetest.registered_nodes)
creative.register_tab("tools", "Tools", minetest.registered_tools)
creative.register_tab("craftitems", "Items", minetest.registered_craftitems)

local old_homepage_name = sfinv.get_homepage_name
function sfinv.get_homepage_name(player)
	if creative.is_std_enabled_for(player:get_player_name()) then
		return "creative:all"
	else
		return old_homepage_name(player)
	end
end
