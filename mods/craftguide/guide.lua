
craftguide.group_representatives = {
	dye = "dye:white",
	wool = "wool:white",
	coal = "default:coal_lump",
	vessel = "vessels:glass_bottle",
	flower = "plants:dandelion_yellow"
}

local player_data = {}

-- This is a list of items in the craft guide
local init_items = {}

local recipes_cache = {}
local usages_cache = {}

local function table_replace(t, val, new)
	for k, v in pairs(t) do
		if v == val then
			t[k] = new
		end
	end
end

local function extract_groups(str)
	if str:sub(1, 6) == "group:" then
		return str:sub(7):split()
	end
end

local function item_has_groups(item_groups, groups)
	for _, group in ipairs(groups) do
		if not item_groups[group] then
			return false
		end
	end
	return true
end

-- If item can be used in recipe because recipe takes a `group:` item that item
-- matches, return a copy of recipe with the `group:` item replaced with item.
local function groups_item_in_recipe(item, recipe)
	local item_groups = minetest.registered_items[item].groups

	for _, recipe_item in pairs(recipe.items) do
		local groups = extract_groups(recipe_item)
		if groups and item_has_groups(item_groups, groups) then
			local usage = table.copy(recipe)
			table_replace(usage.items, recipe_item, item)
			return usage
		end
	end
end

local function get_item_usages(item)
	local usages = {}

	for _, recipes in pairs(recipes_cache) do
		for _, recipe in ipairs(recipes) do
			if table.contains(recipe, item) then
				table.insert(usages, recipe)
			else
				recipe = groups_item_in_recipe(item, recipe)
				if recipe then
					table.insert(usages, recipe)
				end
			end
		end
	end

	return #usages > 0 and usages
end

minetest.register_on_mods_loaded(function()
        for name, def in pairs(minetest.registered_items) do
            if def.groups.not_in_craft_guide ~= 1 and def.description ~= "" then
                recipes_cache[name] = minetest.get_all_craft_recipes(name)
            end
        end
        -- These are separated because the get_item_usages command goes throught the recipe cache
        for name, def in pairs(minetest.registered_items) do
            if def.groups.not_in_craft_guide ~= 1 and def.description ~= "" then
                usages_cache[name] = get_item_usages(name)
                if recipes_cache[name] or usages_cache[name] then
                    table.insert(init_items, name)
                end
            end
        end
        table.sort(init_items)
end)

local function groups_to_item(groups)
	if #groups == 1 then
		local group = groups[1]
		if craftguide.group_representatives[group] then
			return craftguide.group_representatives[group]
		elseif minetest.registered_items["default:"..group] then
			return "default:"..group
		end
	end

	for name, def in pairs(minetest.registered_items) do
		if item_has_groups(def.groups, groups) then
			return name
		end
	end

	return ":unknown"
end

local function get_burntime(item)
	return minetest.get_craft_result({method="fuel", width=1, items={item}}).time
end

local function get_tooltip(item, groups, burntime)
	local tooltip
	if groups then
		local groupstr = {}
		for _, group in ipairs(groups) do
			table.insert(groupstr, minetest.colorize("yellow", group))
		end
		groupstr = table.concat(groupstr, ", ")
		tooltip = "Any item belonging to the group(s): "..groupstr
	else
		local itemdef = minetest.registered_items[item]
		tooltip = itemdef and itemdef.description or "Unknown Item"
	end

	if burntime > 0 then
		tooltip = tooltip.."\nBurning time: "..minetest.colorize("yellow", burntime)
	end

	return ("tooltip[%s;%s]"):format(item, tooltip)
end

local function get_recipe_formspec(data)
	local recipe = data.recipes[data.rnum]
	local width = recipe.width
	local cooktime, shapeless

	if recipe.method == "cooking" then
		cooktime, width = width, 1

	elseif width == 0 then
		shapeless = true
		width = #recipe.items <= 4 and 2 or math.min(3, #recipe.items)
	end

    local fs = {
        ("label[5.5,6.6;%s %d of %d]"):format(
            data.show_usages and "Usage" or "Recipe",
            data.rnum,
            #data.recipes
        )
    }

	if #data.recipes > 1 then
		fs[#fs + 1] = [[
			image_button[5.5,7.2;0.8,0.8;creative_prev_icon.png;recipe_prev;]
			image_button[6.2,7.2;0.8,0.8;creative_next_icon.png;recipe_next;]
		]]
	end

	local rows = math.ceil(table.maxn(recipe.items) / width)
	if width > 3 or rows > 3 then
		fs[#fs + 1] = "label[0,6.6;Recipe is too big to be displayed.]"
		return table.concat(fs)
	end

	for i, item in pairs(recipe.items) do
		local x = (i - 1) % width + 3 - width
		local y = math.ceil(i / width + 6 - math.min(2, rows)) + 0.6

		local burntime = get_burntime(item)
		local groups = extract_groups(item)
		if groups then
			item = groups_to_item(groups)
		end
		fs[#fs + 1] = ("item_image_button[%d,%f;1.05,1.05;%s;%s;%s]")
			:format(x, y, item, item, groups and "\nG" or "")

		if groups or burntime > 0 then
			fs[#fs + 1] = get_tooltip(item, groups, burntime)
		end
	end

    if shapeless then
        fs[#fs + 1] = [[
            image[3.2,6.1;0.5,0.5;craftguide_shapeless.png]
            tooltip[3.2,6.1;0.5,0.5;Shapeless]
        ]]
    elseif recipe.method == "cooking" then
        fs[#fs + 1] = "image[3.2,6.1;0.5,0.5;craftguide_furnace.png]"..
            "tooltip[3.2,6.1;0.5,0.5;Cooking (" .. minetest.colorize("yellow", cooktime) .. "s)]"
    end
	fs[#fs + 1] = "image[3,6.6;1,1;gui_furnace_arrow_bg.png^[transformR270]"

	local output_name = recipe.output:match("%S*")
    local output_button_name = "output_" .. string.lower(recipe.output)
	fs[#fs + 1] = ("item_image_button[4,6.6;1.05,1.05;%s;%s;]")
            :format(recipe.output, output_name)
	local burntime = get_burntime(output_name)
	if burntime > 0 then
		fs[#fs + 1] = get_tooltip(output_name, nil, burntime)
	end

	return table.concat(fs)
end

local function execute_search(data)
	local filter = data.filter
	if filter == "" then
		data.items = init_items
		return
	end
	data.items = {}

	for _, item in ipairs(init_items) do
		local itemdef = minetest.registered_items[item]
		local desc = itemdef and itemdef.description:lower() or ""

		if item:find(filter, 1, true) or desc:find(filter, 1, true) then
			table.insert(data.items, item)
		end
	end
end

local function reset_data(data)
	data.filter = ""
	data.pagenum = 1
	data.items = init_items

	data.item = nil
    data.show_usages = nil
    data.recipes = nil
    data.rnum = nil
end

minetest.register_on_joinplayer(function(player)
	player_data[player:get_player_name()] = {
		filter = "",
		pagenum = 1,
		items = init_items
	}
end)

minetest.register_on_leaveplayer(function(player)
	player_data[player:get_player_name()] = nil
end)

sfinv.register_page("craftguide:guide", {
        title = "Craft Guide",
        is_in_nav = function(self, player, context)
            return craftguide.is_enabled_for(player:get_player_name())
        end,
        get = function(self, player, context)
            local player_name = player:get_player_name()
            craftguide.update_craftguide(player_name, items)
            creative.update_creative_inventory(player_name, items)
            local inv = player_inventory[player_name]
            local start_i = inv.start_i or 0
            local pagenum = math.floor(start_i / (4 * 8) + 1)
            local pagemax = math.ceil(inv.size / (4 * 8))
            
            local name = player:get_player_name()
            local data = player_data[name]
            data.pagemax = math.max(1, math.ceil(#data.items / 32))

            local fs = {}
            fs[#fs + 1] = ("field[0.3,0.32;2.5,1;filter;;%s]field_close_on_enter[filter;false]")
                :format(minetest.formspec_escape(data.filter))
            fs[#fs + 1] = ("label[6.2,0.22;%s / %d]")
                :format(minetest.colorize("yellow", data.pagenum), data.pagemax)
            fs[#fs + 1] = [[
                image_button[2.4,0.12;0.8,0.8;craftguide_search_icon.png;search;]
                image_button[3.05,0.12;0.8,0.8;craftguide_clear_icon.png;clear;]
                image_button[5.4,0.12;0.8,0.8;craftguide_prev_icon.png;prev;]
                image_button[7.2,0.12;0.8,0.8;craftguide_next_icon.png;next;]
                tooltip[search;Search]
                tooltip[clear;Reset]
                tooltip[prev;Previous page]
                tooltip[next;Next page]
            ]]

            if #data.items == 0 then
                fs[#fs + 1] = "label[3,2;No items to show.]"
            else
                local first_item = (data.pagenum - 1) * 32
                for i = first_item, first_item + 31 do
                    local item = data.items[i + 1]
                    if not item then
                        break
                    end
                    local x = i % 8
                    local y = (i % 32 - x) / 8 + 1
                    fs[#fs + 1] = ("item_image_button[%d,%d;1.05,1.05;%s;%s_inv;]")
                        :format(x, y, item, item)
                end
            end

            if data.recipes then
                if #data.recipes > 0 then
                    fs[#fs + 1] = get_recipe_formspec(data)
                elseif data.show_usages then
                    fs[#fs + 1] = "label[2,6.6;No usages.\nClick again to show recipes.]"
                else
                    fs[#fs + 1] = "label[2,6.6;No recipes.\nClick again to show usages.]"
                end
            end

            return table.concat(fs)
        end,
        on_player_receive_fields = function(self, player, context, fields)
            
            local name = player:get_player_name()
            local data = player_data[name]

            if fields.clear then
                reset_data(data)

            elseif fields.key_enter_field == "filter" or fields.search then
                local new = fields.filter:lower()
                if new ~= "" and data.filter == new then
                    return
                end
                data.filter = new
                data.pagenum = 1
                execute_search(data)

            elseif fields.prev or fields.next then
                if data.pagemax == 1 then
                    return
                end
                data.pagenum = data.pagenum + (fields.next and 1 or -1)
                if data.pagenum > data.pagemax then
                    data.pagenum = 1
                elseif data.pagenum == 0 then
                    data.pagenum = data.pagemax
                end

            elseif fields.recipe_next or fields.recipe_prev then
                data.rnum = data.rnum + (fields.recipe_next and 1 or -1)
                if data.rnum > #data.recipes then
                    data.rnum = 1
                elseif data.rnum == 0 then
                    data.rnum = #data.recipes
                end

            else
                local item
                for field in pairs(fields) do
                    if field:find(":") then
                        item = field
                        break
                    end
                end
                if not item then
                    return
                end
                if item:sub(-4) == "_inv" then
                    item = item:sub(1, -5)
                end

                if item == data.prev_item then
                    data.show_usages = not data.show_usages
                else
                    data.show_usages = nil
                end
                if data.show_usages then
                    data.recipes = usages_cache[item] or {}
                else
                    data.recipes = recipes_cache[item] or {}
                end
                data.prev_item = item
                data.rnum = 1
            end

            sfinv.set_player_inventory_formspec(player)
        end
})