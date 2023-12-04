
-- This is a cleanroom reimplementation of the GPL "anvil" mod commonly found
-- lying around. This reimplementation is developed from memory and in-game
-- (loose) behavior testing. It is provided under the MIT license.

if not minetest.global_exists("anvil") then anvil = {} end
anvil.modpath = minetest.get_modpath("anvil")

if not anvil.registered then
	anvil.registered = true

	-- Display entity.
	minetest.register_entity("anvil:item", {
		initial_properties = {
			visual = "item",
			wield_item = "default:coal_lump",
			visual_size = {x=0.4, y=0.4, z=0.4},
			collide_with_objects = false,
			pointable = false,
			collisionbox = {0},
		},
	})

	-- The node.
	minetest.register_node("anvil:anvil", {
		description = "Blacksmithing Anvil",
		tiles = {
			{name="nope.png"},
			{name="nope.png"},
			{name="nope.png"},
			{name="nope.png"},
			{name="nope.png"},
			{name="nope.png"},
		},

		groups = utility.dig_groups("bigitem", {falling_node=1}),
		drop = 'anvil:anvil',
		sounds = default.node_sound_metal_defaults(),
	})

	-- Hammering tool.
	minetest.register_tool("anvil:hammer", {
		description = "Blacksmithing Hammer",
		inventory_image = "anvil_tool_steelhammer.png",
		wield_image = "anvil_tool_steelhammer.png",
		tool_capabilities = tooldata["hammer_hammer"],
		sound = {
			breaks = "basictools_tool_breaks",
		},
		groups = {},
	})

	-- Register mod reloadable.
	local c = "anvil:core"
	local f = anvil.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
