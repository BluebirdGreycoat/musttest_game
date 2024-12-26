
minetest.register_node("sw:teststone1", {
	description = "Irx Stone",
	tiles = {{name="sw_teststone_1.png", align_style="world", scale=4}},

	groups = utility.dig_groups("obsidian", {stone = 1, native_stone = 1}),
	drop = 'sw:teststone2',
	sounds = default.node_sound_stone_defaults(),

	-- Informs TNT not to include this in drops.
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},

	-- Collapsed stone breaks up into cobble.
  on_finish_collapse = function(pos, node)
    minetest.swap_node(pos, {name="sw:teststone2"})
  end,

	on_collapse_to_entity = function(pos, node)
		minetest.add_item(pos, {name="sw:teststone2"})
	end,
})

-- This is to surround water pools to prevent leakage.
minetest.register_node("sw:teststone1_hard", {
	description = "Irx Stone (You Hacker)",
	tiles = {{name="sw_teststone_1.png", align_style="world", scale=4}},

  groups = {unbreakable = 1, immovable=1, not_in_creative_inventory = 1},
  drop = "",
  is_ground_content = false, -- This is important!
	sounds = default.node_sound_stone_defaults(),

	diggable = false,
	always_protected = true, -- Protector code handles this.
  on_blast = function(...) end,
  can_dig = function(...) return false end,
})

-- Xen mapgen places this on tunnel floors and ceilings to help decoration placement.
minetest.register_node("sw:teststone2", {
	description = "Fractured Irx",
	tiles = {{name="sw_teststone_2.png", align_style="world", scale=4}},

	groups = utility.dig_groups("stone", {stone = 1, native_stone = 1}),
	drop = 'sw:teststone2',
	sounds = default.node_sound_stone_defaults(),

	-- Informs TNT not to include this in drops.
	_is_bulk_mapgen_stone = true,

	-- Common stone does not count toward tool's dig count.
	_toolranks = {
		ignore = true,
	},
})
