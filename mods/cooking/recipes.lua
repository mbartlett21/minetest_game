minetest.register_craftitem("cooking:flour", {
	description = "Flour",
	inventory_image = "farming_flour.png",
	groups = {food_flour = 1, flammable = 1, creative = 1},
})

cooking.register_recipe({"farming:wheat", "farming:wheat", "farming:wheat", "farming:wheat"}, "cooking:flour")

cooking.register_food("bread", 
    {
        description = "Bread",
        groups = {food_bread = 1, flammable = 2, creative = 1}
    },
    { inventory_image = "farming_bread_dough.png" },
    { inventory_image = "farming_bread.png", on_use = minetest.item_eat(5) },
    {
        low = 20,
        med = 15,
        cooking = 15
    })

cooking.register_recipe({"cooking:flour"}, "cooking:bread_uncooked")