--Column Nodes designed by Arthemis ( from the Middle-Ages Mod)
--Licensed: WTFPL
--
--base code is from default minetest stairs mod
--Licensed under GPLv3 or later, see http://www.gnu.org/licenses/gpl-3.0.html

function lapis.register_column(modname, item, groups, images, description)
  local recipeitem = modname..":"..item
  local itemname = modname..":column_"..item
	minetest.register_node(itemname, {
		description = description.." Column",
		drawtype = "nodebox",
		tiles = images,
		--inventory_image = "lapis_column.png^lapis_"..item..".png^lapis_column.png^[makealpha:255,126,126",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.3125, -0.5, -0.3125, 0.3125, 0.5, 0.3125}, -- NodeBox1
				{-0.25, -0.5, -0.375, 0.25, 0.5, 0.375}, -- NodeBox2
				{-0.375, -0.5, -0.25, 0.375, 0.5, 0.25}, -- NodeBox3
				{-0.1875, -0.5, -0.4375, 0.1875, 0.5, 0.4375}, -- NodeBox4
				{-0.4375, -0.5, -0.1875, 0.4375, 0.5, 0.1875}, -- NodeBox5
			},
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
		},
		on_place = minetest.rotate_node,
	})

	minetest.register_craft({
		output = itemname .. ' 6',
	recipe = {
	   { "", recipeitem, ""},
    { "", recipeitem, ""},
    { "", recipeitem, ""},
		},
	})

  itemname=modname..":base_" .. item

	minetest.register_node(itemname, {
		description = description.." Column Base",
		drawtype = "nodebox",
		tiles = images,
		--inventory_image = "lapis_base.png^lapis_"..item..".png^lapis_base.png^[makealpha:255,126,126",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = groups,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.3125, -0.5, -0.3125, 0.3125, 0.5, 0.3125}, -- NodeBox2
				{-0.25, -0.5, -0.375, 0.25, 0.5, 0.375}, -- NodeBox3
				{-0.3125, -0.5, -0.25, 0.25, 0.5, 0.3125}, -- NodeBox4
				{-0.25, -0.5, -0.375, 0.1875, 0.5, 0.375}, -- NodeBox5
				{-0.4375, -0.5, -0.1875, 0.4375, 0.5, 0.1875}, -- NodeBox6
				{-0.375, -0.5, -0.25, 0.375, 0.5, 0.25}, -- NodeBox7
				{-0.1875, -0.5, -0.4375, 0.1875, 0.5, 0.4375}, -- NodeBox8
				{-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5}, -- NodeBox9
				{-0.4375, -0.5, -0.4375, 0.4375, -0.1875, 0.4375}, -- NodeBox10
				{-0.375, -0.5, -0.375, 0.375, -0.0625, 0.375}, -- NodeBox11
			}
		},
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
			},
		},
		on_place = minetest.rotate_node,
	})

	minetest.register_craft({
		output = itemname .. ' 2',
		recipe = {
   {recipeitem},
			{recipeitem},
		},
	})
end

----------
-- Items
----------

lapis.register_column("lapis", "lapis_block",
   {cracky=3},
   {"lapis_block.png"},
   "Lapis"
)

lapis.register_column("lapis", "lapis_brick",
   {cracky=3},
   {"lapis_brick.png"},
   "Lapis Brick"
)

lapis.register_column("lapis", "lapis_cobble",
		{cracky=3},
		{"lapis_cobble.png"},
		"Lapis Cobble"
		)

lapis.register_column("lapis", "lazurite_block",
   {cracky= 3},
   {"lapis_lazurite_block.png"},
   "Lazurite"
)

lapis.register_column("lapis",  "lazurite_brick",
   {cracky=3},
   {"lapis_lazurite_brick.png"},
   "Lazurite Brick"
)
