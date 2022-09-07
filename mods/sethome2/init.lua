
sethome = {}

function sethome.get_homes(player)
    return minetest.parse_json(player.get_meta and player:get_meta():get("sethome:homes") or "{}")
end

function sethome.set_homes(player, homes)
    player:get_meta():set_string("sethome:homes", minetest.write_json(homes))
end

function sethome.set(player, pos, number)
    if not type(number) == 'number' or number < 1 or number > 100 or number % 1 ~= 0 then
        return false, "Number must be an integer between 1 and 100"
    end

    local home_pos = vector.round(pos)
    -- Make sure that the player will go on the ground.
    home_pos.y = home_pos.y - 0.5

    local homes = sethome.get_homes(player)
    homes[number] = minetest.pos_to_string(home_pos)

    sethome.set_homes(player, homes)
    sethome.update_hud(player)
	return true, "Home " .. number .. " set!"
end

function sethome.get(player, number)
    local pos_string = sethome.get_homes(player)[number];
    if pos_string then
        local pos = minetest.string_to_pos(pos_string)
        if pos then
            return pos
        end
    end
    return false
end

function sethome.go(player, number)
	local pos = sethome.get(player, number)
	if pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("home", {
        description = "Can use /sethome, /home and /homehud",
        give_to_singleplayer = true
})

minetest.register_chatcommand("home", {
        description = "Teleport you to your home point",
        privs = { home = true },
        func = function(name, param)
            name = name or "" -- fallback to blank name if nil
            local number = param and tonumber(param) or 1
            local player = minetest.get_player_by_name(name)
            if not player then
                return false, "Player not found!"
            end
            if sethome.go(player, number) then
                return true, "Teleported to home " .. number .. "!"
            end
            return false, "Set home " .. number .. " using /sethome " .. number
        end,
})

minetest.register_chatcommand("sethome", {
        description = "Set your home point",
        privs = { home = true },
        func = function(name, param)
            name = name or "" -- fallback to blank name if nil
            local number = param and tonumber(param) or 1
            local player = minetest.get_player_by_name(name)
            if not player then
                return false, "Player not found!"
            end
            return sethome.set(player, player:get_pos(), number)
        end,
})

local function set_hud_on(player_meta, hud_on)
    player_meta:set_string("sethome:hud", hud_on and "on" or "off")
    return true
end

minetest.register_chatcommand("homehud", {
        description = "Turn home HUD on or off",
        params = "on | off",
        privs = {home = true},
        func = function(name, param)
            local is_on = param ~= "off"
            name = name or "" -- fallback to blank name if nil
            local player = minetest.get_player_by_name(name)
            if not player then
                return false, "Player not found!"
            end

            local meta = player:get_meta()
            set_hud_on(meta, is_on)
            sethome.update_hud(player)
            return true, is_on and "Home HUD on!" or "Home HUD off!"
        end,
})

minetest.register_on_joinplayer(function(player)
        sethome.update_hud(player)
end)

sethome.hud_player_ids = {}

local function add_hud(player)
    local name = player:get_player_name()
    sethome.hud_player_ids[name] = {}
    local ids = sethome.hud_player_ids[name]
    local homes = sethome.get_homes(player)
    for num,home in ipairs(homes) do
        local pos = minetest.string_to_pos(home)
        pos.y = pos.y + 1.5
        ids[#ids + 1] = player:hud_add({
                hud_elem_type = "waypoint",
                name = "Home " .. num,
                text = "",
                world_pos = pos,
                number = 0xFFFFFF
            })
    end
end

local function remove_hud(player)
    local name = player:get_player_name()
    for _,home_hud in ipairs(sethome.hud_player_ids[name]) do
        player:hud_remove(home_hud)
    end
    sethome.hud_player_ids[name] = nil
end

local function is_hud_on(player_meta)
    return player_meta:get_string("sethome:hud") ~= "off"
end

function sethome.update_hud(player)
    local meta = player:get_meta()
    -- Remove HUD
    local name = player:get_player_name()
    if sethome.hud_player_ids[name] then
        remove_hud(player)
    end
    if is_hud_on(meta) then
        -- Re-add HUD
        add_hud(player)
    end
end