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
	{name="red", desc="Red", wool="red", mask="#FF0000"},
	{name="brown", desc="Brown", wool="brown", mask="#572C00"},
	{name="black", desc="Black", wool="black", mask="#101010"},
	{name="yellow", desc="Yellow", wool="yellow", mask="#FFDF11"},
	{name="green", desc="Green", wool="green", mask="#5ED91C"},
	{name="pink", desc="Pink", wool="pink", mask="#FF7E7E"},
	{name="orange", desc="Orange", wool="orange", mask="#D65215"},
	{name="violet", desc="Violet", wool="violet", mask="#5C00AB"},
	{name="magenta", desc="Magenta", wool="magenta", mask="#CA036F"},
	{name="dark_green", desc="Dark Green", wool="dark_green", mask="#226800"},
	{name="cyan", desc="Cyan", wool="cyan", mask="#00848C"},
	{name="blue", desc="Blue", wool="blue", mask="#004891"},
	{name="dark_grey", desc="Dark Gray", wool="dark_grey", mask="#3B3B3B"},
	{name="grey", desc="Gray", wool="grey", mask="#848484"},
	{name="white", desc="White", wool="white", mask="#DCDCDC"},
}

for k, v in ipairs(beds.bed_colors) do
	local name = v.name
	local desc = v.desc
	local wool = v.wool
	local mask = v.mask

	beds.register_bed("beds:fancy_bed_" .. name, {
		description = "Fancy Bed (" .. desc .. ")\n\nSleep once to set or refresh your home position.\nHold 'E' when placing to make public.",
		inventory_image = "beds_bed_fancy.png^(beds_bed_fancy_mask.png^[multiply:" .. mask .. ")",
		wield_image = "beds_bed_fancy.png^(beds_bed_fancy_mask.png^[multiply:" .. mask .. ")",
		tiles = {
			bottom = {
				"beds_bed_top1.png^(beds_bed_top1_mask.png^[multiply:" .. mask .. ")",
				"default_wood.png",
				"beds_bed_side1.png^(beds_bed_side1_mask.png^[multiply:" .. mask .. ")",
				"(beds_bed_side1.png^[transformFX)^((beds_bed_side1_mask.png^[multiply:" .. mask .. ")^[transformFX)",
				"default_wood.png",
				"beds_bed_foot.png^(beds_bed_foot_mask.png^[multiply:" .. mask .. ")",
			},
			top = {
				"beds_bed_top2.png^(beds_bed_top2_mask.png^[multiply:" .. mask .. ")",
				"default_wood.png",
				"beds_bed_side2.png^(beds_bed_side2_mask.png^[multiply:" .. mask .. ")",
				"(beds_bed_side2.png^[transformFX)^((beds_bed_side2_mask.png^[multiply:" .. mask .. ")^[transformFX)",
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
		inventory_image = "beds_bed.png^(beds_bed_mask.png^[multiply:" .. mask .. ")",
		wield_image = "beds_bed.png^(beds_bed_mask.png^[multiply:" .. mask .. ")",
		tiles = {
			bottom = {
				"(beds_bed_top_bottom.png^[transformR90)^((beds_bed_top_bottom_mask.png^[multiply:" .. mask .. ")^[transformR90)",
				"default_wood.png",
				"beds_bed_side_bottom_r.png^(beds_bed_side_bottom_r_mask.png^[multiply:" .. mask .. ")",
				"(beds_bed_side_bottom_r.png^[transformfx)^((beds_bed_side_bottom_r_mask.png^[multiply:" .. mask .. ")^[transformfx)",
				"beds_transparent.png",
				"beds_bed_side_bottom.png^(beds_bed_side_bottom_mask.png^[multiply:" .. mask .. ")",
			},
			top = {
				"(beds_bed_top_top.png^[transformR90)^((beds_bed_top_top_mask.png^[multiply:" .. mask .. ")^[transformR90)",
				"default_wood.png",
				"beds_bed_side_top_r.png^(beds_bed_side_top_r_mask.png^[multiply:" .. mask .. ")",
				"(beds_bed_side_top_r.png^[transformfx)^((beds_bed_side_top_r_mask.png^[multiply:" .. mask .. ")^[transformfx)",
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
