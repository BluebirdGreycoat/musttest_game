
-- New tree for Xen. 


 minetest.register_node('firetree:luminoustreetrunk', {
	 description = 'Sunfire Trunk',
	 tiles = {'dvd_treetop.png', 'dvd_treetop.png', 'dvd_luminoustreetrunk.png', 'dvd_luminoustreetrunk.png', 'dvd_luminoustreetrunk.png', 'dvd_luminoustreetrunk.png',
	 },
	 paramtype = "light",
	 light_source = 2,
	 groups = {level = 1, choppy=2, oddly_breakable_by_hand=4},
	 })
 
 minetest.register_node('firetree:luminoustreeleaves', {
	  drawtype = "allfaces",
	  description = 'Sunfire Leaves',
	  tiles = {'dvd_luminousleaves.png'},
	  paramtype = "light",
	  sunlight_propagates = true,
	  light_source = 4,
      groups = {level = 1, snappy=3, oddly_breakable_by_hand=1},
 })
 
 minetest.register_node('firetree:luminoustreesapling', {
	  drawtype = "plantlike",
	  inventory_image = "dvd_luminoussapling.png",
	  weild_image = "dvd_luminoussapling.png",
	  description = 'Sunfire Sapling',
	  tiles = {'dvd_luminoussapling.png'},
	  paramtype = "light",
	  sunlight_propagates = true, 
	  light_source = 2,
	  walkable = false,
      groups = {level = 1, snappy=3, oddly_breakable_by_hand=1},
 })
 
 