--[[crafter ={
  crafts ={},
  empty ={item = ItemStack(nil),time = 0}
}]]

cooking._methods = {
    cook_low = {},
    cook_med = {},
    cook_high = {}
}

cooking._empty = { item = ItemStack(nil), time = 0 }

function cooking._register_recipe(type, time, input, out)
    cooking._methods[type][#cooking._methods[type] + 1] = {
        time = time,
        recipe = input,
        output = out
    }
end

function cooking.register_recipe(input, output)
    assert(input and output)
    minetest.register_craft({
            type = "shapeless",
            output = output,
            recipe = input
        })
end

function cooking._get_craft_result(data)
    assert(data.method ~= nil and type(data.items) == "table" and #data.items == 1, "[cooking] Invalid call to cooking._get_craft_result")
    local r = nil
    local type = data.method
    local item = data.items[1]
    for _,craft in ipairs(cooking._methods[type]) do
        r = (craft.recipe == item:get_name())
        if r then
            local items_left = ItemStack(item:to_string())
            items_left:take_item(1)
            local items_created = ItemStack(craft.output)
            return {
                item = items_created,
                time = craft.time
            },
            {
                items ={items_left}
            }
                
        end
    end
    return cooking._empty
end

function cooking.register_cook(opts)
    local types = opts.types
    local out = opts.output
    local input = opts.recipe
    
    if types.cooking then
        minetest.register_craft({
            type = "cooking",
            cooktime = types.cooking,
            output = out,
            recipe = input
        })
    end
    
    if types.low then
        cooking._register_recipe("cook_low", types.low, input, out)
    end
    
    if types.med then
        cooking._register_recipe("cook_med", types.med, input, out)
    end
    
    if types.high then
        cooking._register_recipe("cook_high", types.high, input, out)
    end
end

function cooking.register_food(name, shared_def, uncook, cook, cooktimes)
    local uncook_def = table.copy(shared_def)
    uncook_def.groups = uncook_def.groups or {}
    uncook_def.groups.uncooked = 1
    local cook_def = table.copy(shared_def)
    cook_def.groups = cook_def.groups or {}
    cook_def.groups.cooked = 1
    if shared_def.description then
        uncook_def.description = shared_def.description .. " (Uncooked)"
        cook_def.description = shared_def.description .. " (Cooked)"
    end
    for k, v in pairs(uncook) do
		uncook_def[k] = uncook[k]
	end
    for k, v in pairs(cook) do
		cook_def[k] = cook[k]
	end
    minetest.register_craftitem(":cooking:" .. name .. "_uncooked", uncook_def)
    minetest.register_craftitem(":cooking:" .. name, cook_def)
    if cooktimes then
        cooking.register_cook({
                types = cooktimes,
                output = "cooking:" .. name,
                recipe = "cooking:" .. name .. "_uncooked"
            })
    end
end