-- Fancy shaped bed
-- (multiple colours)

local dyes = dye.dyes

for i = 1, #dyes do
	local name, desc = unpack(dyes[i])

    if name ~= "white" then
        beds.register_bed("beds:fancy_bed_" .. name, {
            description = "Fancy " .. desc .. " Bed",
            inventory_image = "beds_bed_fancy.png^(wool_" .. name .. ".png^beds_bed_overlay.png^[makealpha:255,126,126)",
            wield_image = "beds_bed_fancy.png^(wool_" .. name .. ".png^beds_bed_overlay.png^[makealpha:255,126,126)",
            tiles = {
                bottom = {
                    "beds_bed_top1.png^(wool_" .. name .. ".png^[transformR90^beds_bed_top1_overlay.png^[makealpha:255,126,126)",
                    "beds_bed_under.png",
                    "beds_bed_side1.png^(wool_" .. name .. ".png^beds_bed_side1_overlay.png^[makealpha:255,126,126)",
                    "beds_bed_side1.png^(wool_" .. name .. ".png^beds_bed_side1_overlay.png^[makealpha:255,126,126)^[transformFX",
                    "beds_bed_foot.png^(wool_" .. name .. ".png^beds_bed_foot_overlay.png^[makealpha:255,126,126)",
                    "beds_bed_foot.png^(wool_" .. name .. ".png^beds_bed_foot_overlay.png^[makealpha:255,126,126)",
                },
                top = {
                    "beds_bed_top2.png^(wool_" .. name .. ".png^[transformR90^beds_bed_top2_overlay.png^[makealpha:255,126,126)",
                    "beds_bed_under.png",
                    "beds_bed_side2.png^(wool_" .. name .. ".png^beds_bed_side2_overlay.png^[makealpha:255,126,126)",
                    "beds_bed_side2.png^(wool_" .. name .. ".png^beds_bed_side2_overlay.png^[makealpha:255,126,126)^[transformFX",
                    "beds_bed_head.png",
                    "beds_bed_head.png",
                }
            },
            nodebox = {
                bottom = {
                    {-0.5, -0.5, -0.5, -0.375, -0.065, -0.4375},
                    {0.375, -0.5, -0.5, 0.5, -0.065, -0.4375},
                    {-0.5, -0.375, -0.5, 0.5, -0.125, -0.4375},
                    {-0.5, -0.375, -0.5, -0.4375, -0.125, 0.5},
                    {0.4375, -0.375, -0.5, 0.5, -0.125, 0.5},
                    {-0.4375, -0.3125, -0.4375, 0.4375, -0.0625, 0.5},
                },
                top = {
                    {-0.5, -0.5, 0.4375, -0.375, 0.1875, 0.5},
                    {0.375, -0.5, 0.4375, 0.5, 0.1875, 0.5},
                    {-0.5, 0, 0.4375, 0.5, 0.125, 0.5},
                    {-0.5, -0.375, 0.4375, 0.5, -0.125, 0.5},
                    {-0.5, -0.375, -0.5, -0.4375, -0.125, 0.5},
                    {0.4375, -0.375, -0.5, 0.5, -0.125, 0.5},
                    {-0.4375, -0.3125, -0.5, 0.4375, -0.0625, 0.4375},
                }
            },
            selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.06, 1.5},
            recipe = {
                {"",                "",                 "group:stick"},
                {"wool:" .. name,   "wool:" .. name,    "wool:white"},
                {"group:wood",      "group:wood",       "group:wood"},
            },
            groups = name == "red" and { creative = 1 } or {}
        })

        minetest.register_craft({
            type = "fuel",
            recipe = "beds:fancy_bed_" .. name .. "_bottom",
            burntime = 13,
        })
    end
end

minetest.register_alias("beds:fancy_bed", "beds:fancy_bed_red_bottom")
