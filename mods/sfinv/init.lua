dofile(minetest.get_modpath("sfinv") .. "/api.lua")

sfinv.register_page("sfinv:crafting", {
	title = "Crafting",
	get = function(self, player, context)
		return [[
				list[current_player;craft;1.75,0.5;3,3;]
				list[current_player;craftpreview;5.75,1.5;1,1;]
				image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]
				listring[current_player;main]
				listring[current_player;craft]
			]]
	end
})

if minetest.settings:get_bool("sfinv_admin") then
    local admin_data = {}
    sfinv.register_page("sfinv:admin", {
            title = "Admin",
            is_in_nav = function(self, player, context)
                return minetest.check_player_privs(player:get_player_name(), {server = true})
            end,
            get = function(self, player, context)
                local player_name = player:get_player_name()
                local data = admin_data[player_name]
                if not data then
                    data = {
                        selected = 1,
                        connected = {}
                    }
                    admin_data[player_name] = data
                end
                local connected_players = minetest.get_connected_players()
                local connected = {}
                data.connected = connected
                for i, player in ipairs(connected_players) do
                    local name = player:get_player_name()
                    if name ~= player_name then
                        connected[#connected + 1] = name
                    end
                end

                if #connected == 0 then
                    return "label[2.5,0.5;No players apart from you are connected]button[3,1.5;2,0.5;refresh;Refresh list]"
                end

                local formspec_table = {
                    -- List of players
                    "textlist[0,0;5.8,4;admin_table;",
                    table.concat(connected, ","),
                    ";",
                    data.selected,
                    ";false]",
                    -- Buttons
                    [[
                    button[6,0.3;2,0.4;refresh;Refresh list]
                    button[6,1.3;2,0.4;ban;Ban player]
                    button[6,2.3;2,0.4;kick;Kick player]
                    button[6,3.3;2,0.4;reset_privs;Reset privs]
                    ]]
                }

                return table.concat(formspec_table, "")
            end,
            on_enter = function(self, player, context)
                local name = player:get_player_name()
                admin_data[name] = {
                    selected = 1,
                    connected = {}
                }
            end,
            on_player_receive_fields = function(self, player, context, fields)
                local data = admin_data[player:get_player_name()]
                if not data then
                    data = {
                        selected = 1,
                        connected = {}
                    }
                    admin_data[player:get_player_name()] = data
                end
                local player_name = data.connected[data.selected]
                if fields.admin_table then
                    local event = minetest.explode_textlist_event(fields.admin_table)
                    if event.type == "CHG" or event.type == "DCL" then
                        data.selected = event.index
                    end

                end
                
                if player_name and not minetest.check_player_privs(player_name, {server = true}) then
                    if fields.ban then
                        minetest.ban_player(player_name)
                        
                    elseif fields.kick then
                        minetest.kick_player(player_name)
                        
                    elseif fields.reset_privs then
                        minetest.set_player_privs(name, {})
                    end
                end

                sfinv.set_player_inventory_formspec(player, context)
            end
        })
end