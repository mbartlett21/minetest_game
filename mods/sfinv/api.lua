sfinv = {
	pages = {},
	pages_unordered = {},
	contexts = {}
}

function sfinv.register_page(name, def)
	assert(name, "Invalid page. Requires a name")
	assert(def, "Invalid page. Requires a def[inition] table")
	assert(def.get, "Invalid page. Def requires a get function")
	assert(not sfinv.pages[name], "Attempt to register registered page " .. dump(name))

	sfinv.pages[name] = def
	def.name = name
	table.insert(sfinv.pages_unordered, def)
end

function sfinv.override_page(name, def)
	assert(name, "Invalid page override. Requires a name")
	assert(def, "Invalid page override. Requires a def[inition] table")

	local page = sfinv.pages[name]
	assert(page, "Attempt to override page " .. dump(name) .. " which does not exist")

	for key, value in pairs(def) do
		page[key] = value
	end
end

function sfinv.get_nav_fs(nav, current_idx)
	-- Only show tabs if there is more than one page
	if #nav > 1 then
		return "tabheader[0,0;sfinv_nav_tabs;" .. table.concat(nav, ",") .. ";" .. current_idx .. ";true;false]"
	else
		return ""
	end
end

local theme_inv =  [[
    image[0,5.2;1,1;gui_hb_bg.png]
    image[1,5.2;1,1;gui_hb_bg.png]
    image[2,5.2;1,1;gui_hb_bg.png]
    image[3,5.2;1,1;gui_hb_bg.png]
    image[4,5.2;1,1;gui_hb_bg.png]
    image[5,5.2;1,1;gui_hb_bg.png]
    image[6,5.2;1,1;gui_hb_bg.png]
    image[7,5.2;1,1;gui_hb_bg.png]
    list[current_player;main;0,5.2;8,1;]
    list[current_player;main;0,6.35;8,3;8]
]]

function sfinv.make_formspec(player, context, content, show_inv)
	local tmp = {
		"size[8,9.1]",
		sfinv.get_nav_fs(context.nav_titles, context.nav_idx),
        show_inv ~= false and theme_inv or "",
		content
	}
	return table.concat(tmp, "")
end

-- This is on the global so that it can be overridden
function sfinv.get_homepage_name(player)
	return "sfinv:crafting"
end

function sfinv.get_formspec(player, context)
	-- Generate navigation tabs
	local nav = {}
	local nav_ids = {}
	local current_idx = 1
	for i, pdef in pairs(sfinv.pages_unordered) do
		if not pdef.is_in_nav or
           pdef:is_in_nav(player, context) then
			nav[#nav + 1] = pdef.title
			nav_ids[#nav_ids + 1] = pdef.name
			if pdef.name == context.page then
				current_idx = #nav_ids
			end
		end
	end
	context.nav = nav_ids
	context.nav_titles = nav
	context.nav_idx = current_idx

	-- Generate formspec
	local page = sfinv.pages[context.page] or sfinv.pages["404"]
	if page and (not page.is_in_nav or page:is_in_nav(player, context)) then
        local page_formspec, show_inv = page:get(player, context);
		return sfinv.make_formspec(player, context, page_formspec, show_inv)
	elseif sfinv.pages[context.page] then
		local old_page = context.page
		local home_page = sfinv.get_homepage_name(player)

		if old_page == home_page then
			minetest.log("error", "[sfinv] Couldn't access " .. dump(old_page) ..
					", which is also the home page")

			return ""
		end

		context.page = home_page
		assert(sfinv.pages[context.page], "Invalid homepage")
		minetest.log("warning", "[sfinv] Couldn't access " .. dump(old_page) ..
				" so switching to homepage")

		return sfinv.get_formspec(player, context)
    else
		local old_page = context.page
		local home_page = sfinv.get_homepage_name(player)

		if old_page == home_page then
			minetest.log("error", "[sfinv] Couldn't find " .. dump(old_page) ..
					", which is also the home page")

			return ""
		end

		context.page = home_page
		assert(sfinv.pages[context.page], "Invalid homepage")
		minetest.log("warning", "[sfinv] Couldn't find " .. dump(old_page) ..
				" so switching to homepage")

		return sfinv.get_formspec(player, context)
	end
end

function sfinv.get_or_create_context(player)
	local name = player:get_player_name()
	local context = sfinv.contexts[name]
	if not context then
		context = {
			page = sfinv.get_homepage_name(player)
		}
		sfinv.contexts[name] = context
	end
	return context
end

function sfinv.set_context(player, context)
	sfinv.contexts[player:get_player_name()] = context
end

function sfinv.set_player_inventory_formspec(player, context)
    local fs = sfinv.get_formspec(player,
            context or sfinv.get_or_create_context(player))
    player:set_inventory_formspec(fs)
end

function sfinv.set_page(player, pagename)
	local context = sfinv.get_or_create_context(player)
	local oldpage = sfinv.pages[context.page]
	if oldpage and oldpage.on_leave then
		oldpage:on_leave(player, context)
	end
	context.page = pagename
	local page = sfinv.pages[pagename]
	if page.on_enter then
		page:on_enter(player, context)
	end
	sfinv.set_player_inventory_formspec(player, context)
end

function sfinv.get_page(player)
	local context = sfinv.contexts[player:get_player_name()]
	return context and context.page or sfinv.get_homepage_name(player)
end

minetest.register_on_joinplayer(function(player)
        sfinv.set_player_inventory_formspec(player)
    end)

minetest.register_on_leaveplayer(function(player)
        sfinv.contexts[player:get_player_name()] = nil
    end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
        if formname ~= "" then return false end

        -- Get Context
        local name = player:get_player_name()
        local context = sfinv.contexts[name]
        if not context then
            sfinv.set_player_inventory_formspec(player)
            return false
        end

        -- Was a tab selected?
        if fields.sfinv_nav_tabs and context.nav then
            local tid = tonumber(fields.sfinv_nav_tabs)
            if tid and tid > 0 then
                local id = context.nav[tid]
                local page = sfinv.pages[id]
                if id and page then
                    sfinv.set_page(player, id)
                end
            end
        else
            local page = sfinv.pages[context.page]
            
            if page and
                -- Check that the player can access the page
                (not page.is_in_nav or page:is_in_nav(player, context)) and
                page.on_player_receive_fields then
                -- Pass event to page
                return page:on_player_receive_fields(player, context, fields)
            end
        end
    end)
