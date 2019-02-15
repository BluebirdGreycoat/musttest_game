-- Fancy shaped bed

beds.nodebox = {
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
}
beds.nodebox_simple = {
	bottom = {-0.5, -0.5, -0.5, 0.5, 0.06, 0.5},
	top = {-0.5, -0.5, -0.5, 0.5, 0.06, 0.5},
}
beds.selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.06, 1.5}

beds.bed_colors = {
	{name="red", desc="Red", wool="red"},
}

for k, v in ipairs(beds.bed_colors) do
	local name = v.name
	local desc = v.desc
	local wool = v.wool

	beds.register_bed("beds:fancy_bed_" .. name, {
		description = "Fancy Bed (" .. desc .. ")\n\nSleep once to set or refresh your home position.\nHold 'E' when placing to make public.",
		inventory_image = "beds_bed_fancy.png",
		wield_image = "beds_bed_fancy.png",
		tiles = {
			bottom = {
				"beds_bed_top1.png",
				"default_wood.png",
				"beds_bed_side1.png",
				"beds_bed_side1.png^[transformFX",
				"default_wood.png",
				"beds_bed_foot.png",
			},
			top = {
				"beds_bed_top2.png",
				"default_wood.png",
				"beds_bed_side2.png",
				"beds_bed_side2.png^[transformFX",
				"beds_bed_head.png",
				"default_wood.png",
			}
		},
		nodebox = beds.nodebox,
		selectionbox = beds.selectionbox,
		recipe = {
			{"", "", "group:stick"},
			{"wool:" .. wool, "wool:" .. wool, "wool:white"},
			{"group:wood", "group:wood", "group:wood"},
		},
	})

	-- Simple shaped bed

	beds.register_bed("beds:bed_" .. name, {
		description = "Simple Bed (" .. desc .. ")\n\nSleep once to set or refresh your home position.\nHold 'E' when placing to make public.",
		inventory_image = "beds_bed.png",
		wield_image = "beds_bed.png",
		tiles = {
			bottom = {
				"beds_bed_top_bottom.png^[transformR90",
				"default_wood.png",
				"beds_bed_side_bottom_r.png",
				"beds_bed_side_bottom_r.png^[transformfx",
				"beds_transparent.png",
				"beds_bed_side_bottom.png"
			},
			top = {
				"beds_bed_top_top.png^[transformR90",
				"default_wood.png",
				"beds_bed_side_top_r.png",
				"beds_bed_side_top_r.png^[transformfx",
				"beds_bed_side_top.png",
				"beds_transparent.png",
			}
		},
		nodebox = beds.nodebox_simple,
		selectionbox = beds.selectionbox,
		recipe = {
			{"wool:" .. wool, "wool:" .. wool, "wool:white"},
			{"group:wood", "group:wood", "group:wood"},
		},
	})
end

minetest.register_alias("beds:fancy_bed_bottom", "beds:fancy_bed_red_bottom")
minetest.register_alias("beds:fancy_bed_top", "beds:fancy_bed_red_top")

-- Aliases for PilzAdam's beds mod

minetest.register_alias("beds:bed_bottom", "beds:bed_red_bottom")
minetest.register_alias("beds:bed_top", "beds:bed_red_top")
