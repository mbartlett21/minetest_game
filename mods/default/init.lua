-- Definitions made by this mod that other mods can use too
default = {}

-- GUI related stuff
minetest.register_on_joinplayer(function(player)
	player:set_formspec_prepend([[
			bgcolor[#080808BB;true]
			background[5,5;1,1;gui_formbg.png;true]
			listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF] ]])
	player:hud_set_hotbar_image("gui_hotbar.png")
	player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")
end)

function default.get_hotbar_bg(x,y)
	local out = ""
	for i = 0,7,1 do
		out = out .."image["..x+i..","..y..";1,1;gui_hb_bg.png]"
	end
	return out
end

default.gui_survival_form = "size[8,8.5]"..
			"list[current_player;main;0,4.25;8,1;]"..
			"list[current_player;main;0,5.5;8,3;8]"..
			"list[current_player;craft;1.75,0.5;3,3;]"..
			"list[current_player;craftpreview;5.75,1.5;1,1;]"..
			"image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
			"listring[current_player;main]"..
			"listring[current_player;craft]"..
			default.get_hotbar_bg(0,4.25)

-- Load files
default.modpath = minetest.get_modpath("default")
local default_path = default.modpath

dofile(default_path.."/functions.lua")
dofile(default_path.."/trees.lua")
dofile(default_path.."/nodes.lua")
dofile(default_path.."/chests.lua")
dofile(default_path.."/furnace.lua")
dofile(default_path.."/torch.lua")
dofile(default_path.."/tools.lua")
dofile(default_path.."/item_entity.lua")
dofile(default_path.."/craftitems.lua")
dofile(default_path.."/crafting.lua")
dofile(default_path.."/mapgen.lua")
dofile(default_path.."/shadows.lua")

print("[default] Loaded!")
