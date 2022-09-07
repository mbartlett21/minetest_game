
cooking.initial_formspec = "size[8,9]"..
    -- Button selection
        "button[0,0;2,1;temp0;Off]"..
        "button[2,0;2,1;temp1;Low]"..
        "button[4,0;2,1;temp2;Med]"..
        "button[6,0;2,1;temp3;High]"..
    
    -- Sources
		"list[context;src1;2.75,1.5;1,1;]"..
		"list[context;src2;2.75,2.5;1,1;]"

cooking.end_formspec = 
    -- Destinations
        "list[context;dst1;4.75,1.5;2,1;]"..
		"list[context;dst2;4.75,2.5;2,1;]"..

    -- Player's inventory
		"list[current_player;main;0,4.75;8,1;]"..
		"list[current_player;main;0,6;8,3;8]"

cooking.auto_off_on_formspec =  "label[2.75,3.75;Auto turn-off:]button[4,3.6;1,1;auto_off_off;On]"

cooking.auto_off_off_formspec = "label[2.75,3.75;Auto turn-off:]button[4,3.6;1,1;auto_off_on;Off]"

function cooking.get_oven_active_formspec(item_percent1, item_percent2, temp, auto_off)
	return cooking.initial_formspec..
    -- Arrows
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent1)..":gui_furnace_arrow_fg.png^[transformR270]"..
		"image[3.75,2.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent2)..":gui_furnace_arrow_fg.png^[transformR270]"..
    
    -- Temp
		"image[0.5,1.125;1,3;cooking_temp_bg.png^[lowpart:"..
        (temp / 3)..":cooking_temp_fg.png]]"..
    
        (auto_off and cooking.auto_off_on_formspec or cooking.auto_off_off_formspec) ..

		cooking.end_formspec..
--		"listring[context;dst]"..
--		"listring[current_player;main]"..
--		"listring[context;src]"..
--		"listring[current_player;main]"..
--		"listring[context;fuel]"..
--		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.75)
end

function cooking.get_oven_inactive_formspec(auto_off)
	return cooking.initial_formspec..

    -- Arrows
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
		"image[3.75,2.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
    
    -- Temp
		"image[0.5,1.125;1,3;cooking_temp_bg.png]"..
    
        (auto_off and cooking.auto_off_on_formspec or cooking.auto_off_off_formspec) ..

        cooking.end_formspec..
--		"listring[context;dst]"..
--		"listring[current_player;main]"..
--		"listring[context;src]"..
--		"listring[current_player;main]"..
--		"listring[context;fuel]"..
--		"listring[current_player;main]"..
		default.get_hotbar_bg(0, 4.75)
end
