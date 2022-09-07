local cart_entity = {
	initial_properties = {
		physical = false, -- otherwise going uphill breaks
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "mesh",
		mesh = "carts_cart.b3d",
		visual_size = {x = 1, y = 1},
		textures = {"carts_cart.png"},
	},

	driver = nil,
--	punched = false, -- used to re-send velocity and position
--	velocity = {x = 0, y = 0, z = 0}, -- only used on punch
--	old_dir = {x = 1, y = 0, z = 0}, -- random value to start the cart on punch
--	old_pos = nil,
--	railtype = nil,
	attached_items = {}
}

function cart_entity:on_rightclick(clicker)
    if not clicker or not clicker:is_player() then
        return
    end

	local player_name = clicker:get_player_name()

	if self.driver and player_name == self.driver then
		self.driver = nil
		carts:manage_attachment(clicker, nil)

	elseif not self.driver then
		self.driver = player_name
		carts:manage_attachment(clicker, self.object)

		-- player_api does not update the animation
		-- when the player is attached, reset to default animation
		player_api.set_animation(clicker, "stand")
	end
end

function cart_entity:on_activate()
    self.object:set_armor_groups({immortal = 1})
	if string.sub(staticdata, 1, string.len("return")) ~= "return" then
		return
	end
	local data = minetest.deserialize(staticdata)
	if type(data) ~= "table" then
		return
	end
	self.railtype = data.railtype
	if data.old_dir then
		self.old_dir = data.old_dir
	end
end

function cart_entity:get_staticdata()
	return minetest.serialize({
		railtype = self.railtype,
		old_dir = self.old_dir
	})
end

function cart_entity:on_detach_child(child)
    if child and child:get_player_name() == self.driver then
        self.driver = nil
    end
end

function cart_entity:on_punch(puncher)
    if not puncher or not puncher:is_player() then
        return
    end

    -- Player can only pick it up if no-one is inside
    if not self.driver then
        -- Move to inventory
        creative.add_to_inventory(puncher, "carts:cart", self.object:get_pos())
        minetest.after(0, function()
            self.object:remove()
        end)
    end
end

function cart_entity:on_step()
--    local object_v = self.object:get_velocity()
--
--    local vx_acc = -object_v.x * friction
--    local vz_acc = -object_v.z * friction
--
--    local curr_yaw = self.object:getyaw()
--    local new_yaw = curr_yaw
--
--    local vx_acc_mult = -math.sin(curr_yaw)
--    local vz_acc_mult =  math.cos(curr_yaw)
--
--    local vy_acc = -object_v.y * friction_y
--    
--    local horiz_stop = math.abs(object_v.x) < 0.1 and math.abs(object_v.z) < 0.1

    -- Controls
    if self.driver then
        local driver_objref = minetest.get_player_by_name(self.driver)
        if driver_objref then
            local ctrl = driver_objref:get_player_control()
        end
    end

--    if horiz_stop then
--        vx_acc = 0
--        vz_acc = 0
--        self.object:set_velocity({ x = 0, y = object_v.y, z = 0 })
--    end

    local new_acce = { x = vx_acc, y = vy_acc, z = vz_acc }

    self.object:set_acceleration(new_acce)
    if new_yaw ~= curr_yaw then
        self.object:set_yaw(new_yaw)
    end
end

minetest.register_entity("carts:cart", cart_entity)

minetest.register_craftitem("carts:cart", {
        description = "Cart",
        inventory_image = minetest.inventorycube("carts_cart_top.png", "carts_cart_side.png", "carts_cart_side.png"),
        wield_image = "carts_cart_side.png",
        on_place = function(itemstack, placer, pointed_thing)
            local under = pointed_thing.under
            local node = minetest.get_node(under)
            local udef = minetest.registered_nodes[node.name]
            if udef and udef.on_rightclick and
                    not (placer and placer:is_player() and
                    placer:get_player_control().sneak) then
                return udef.on_rightclick(under, node, placer, itemstack,
                    pointed_thing) or itemstack
            end

            if not pointed_thing.type == "node" then
                return
            end
            if carts:is_rail(pointed_thing.under) then
                minetest.add_entity(pointed_thing.under, "carts:cart")
            elseif carts:is_rail(pointed_thing.above) then
                minetest.add_entity(pointed_thing.above, "carts:cart")
            else
                return
            end

            minetest.sound_play({name = "default_place_node_metal", gain = 0.5},
                {pos = pointed_thing.above})


            creative.take_from_inventory(placer, itemstack)
            return itemstack
        end,
        groups = {creative = 1}
})

minetest.register_craft({
	output = "carts:cart",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})
