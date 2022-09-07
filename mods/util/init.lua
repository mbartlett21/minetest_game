
-- WARNING: This function does not work properly for keys that are tables
-- This function
function table.equals(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end
    for k, v1 in pairs(t1) do
        if not table.equals(v1, t2[k]) then
            return false
        end
    end
    -- This round is simpler because we are only checking the keys
    for k, _ in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end
    return true
end

function table.contains(t, element)
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

if minetest.settings:get_bool("enable_sneak_glitch") ~= false then
    minetest.register_on_joinplayer(function(player)
           local override_table = player:get_physics_override()
           override_table.sneak_glitch = true
           player:set_physics_override(override_table)
    end)
end