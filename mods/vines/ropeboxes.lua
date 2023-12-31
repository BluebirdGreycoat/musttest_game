
local rope_timer_rate = 0.2

local function register_rope_block(multiple, pixels)
	minetest.register_node(string.format("vines:%irope_block", multiple), {
		description = string.format("Rope (%i Meters)", vines.ropeLength*multiple),
		drawtype="nodebox",
		sunlight_propagates = true,
		paramtype = "light",
		paramtype2 = "wallmounted",

		tiles = {
			string.format("default_wood.png^vines_%irope.png", multiple),
			string.format("default_wood.png^vines_%irope.png", multiple),
			"default_wood.png^vines_side.png",
			"default_wood.png^vines_side.png",
			string.format("default_wood.png^vines_%irope_frontback.png", multiple),
			string.format("default_wood.png^vines_%irope_frontback.png", multiple),
		},

		node_box = {
			type = "fixed",
			fixed = {
				{-0.375, -0.1875, -0.3125, 0.375, 0.375, 0.3125}, -- Spool
				{-0.5, -0.5, -0.1875, -0.375, 0.25, 0.1875}, -- Support_arm
				{0.375, -0.5, -0.1875, 0.5, 0.25, 0.1875}, -- Support_arm
				{-0.375, -0.5, -0.1875, 0.375, -0.375, 0.1875}, -- Base
				{-0.0625*(pixels/2), -0.1875, -0.5, 0.0625*(pixels/2), 0.375, 0.5}, -- Longitudinal_rope
				{-0.0625*(pixels/2), -0.3125, -0.375, 0.0625*(pixels/2), 0.5, 0.375}, -- Vertical_rope
			},
		},

		selection_box = {type="regular"},
		collision_box = {type="regular"},
		groups = utility.dig_groups("furniture", {flammable=2}),

		after_place_node = function(pos)
			local p = {x=pos.x, y=pos.y-1, z=pos.z}
			local n = minetest.get_node(p)
			if n.name == "air" then
				minetest.add_node(p, {name="vines:rope_bottom"})
				local meta = minetest.get_meta(p)
				meta:set_int("length_remaining", vines.ropeLength*multiple)
				meta:mark_as_private("length_remaining")
			end
		end,

		on_punch = function(pos, node, puncher, pt)
			local p = {x=pos.x, y=pos.y-1, z=pos.z}
			local n = minetest.get_node(p)
			if n.name == "air" then
				minetest.add_node(p, {name="vines:rope_bottom"})
				local meta = minetest.get_meta(p)
				meta:set_int("length_remaining", vines.ropeLength*multiple)
				meta:mark_as_private("length_remaining")
			end
		end,

		after_destruct = function(pos)
			local p = {x=pos.x, y=pos.y-1, z=pos.z}
			vines.destroy_rope_starting(p, 'vines:rope', 'vines:rope_bottom', 'vines:rope_top')
		end
	})

	if (multiple == 1) then
		minetest.register_craft({
			output = "vines:1rope_block",
			recipe =  {
				{'vines:ropesegment', 'group:wood', 'vines:ropesegment'},
				{'vines:ropesegment', 'vines:ropesegment', 'vines:ropesegment'},
				{'vines:ropesegment', 'vines:ropesegment', 'vines:ropesegment'},
			}
		})
	--
	else
		local rec = {}
		for i=1, multiple, 1 do
			rec[i] = "vines:1rope_block"
		end

		minetest.register_craft({
			output = string.format("vines:%irope_block", multiple),
			type = "shapeless",
			recipe = rec
		})

		minetest.register_craft({
			output = string.format("vines:1rope_block %i", multiple),
			recipe =  {
				{string.format('vines:%irope_block', multiple)}
			}
		})
	end
	--]]
end

--creates rope blocks with length multiples 1-5.
--second parameter sets how many pixels wide the rope texture is
register_rope_block(1, 4)
register_rope_block(2, 8)
register_rope_block(3, 10)
register_rope_block(4, 10)
register_rope_block(5, 12)

minetest.register_node("vines:rope", {
	description = "Rope",
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	drop = "",
	tiles = { "vines_rope.png" },
	drawtype = "plantlike",
	groups = utility.dig_groups("ignore", {flammable=2, not_in_creative_inventory=1, always_stable=1}),
	sounds =  default.node_sound_leaves_defaults(),
	light_source = 1,

	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},

	movement_speed_multiplier = default.ROPE_SPEED,
	_no_collapse_on_walkover = true,

	-- If rope has broken (middle rope piece with no middle or bottom piece below)
	-- then repair rope on punch.
	on_punch = function(pos, node, puncher, pt)
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
		local n = minetest.get_node(above)
		if (string.find(n.name, "^vines:") and string.find(n.name, "rope_block$")) or n.name == "vines:rope" then
			-- Nothing.
		else
			-- No ropeblock above and no rope-middle-section, need to destroy rope!
			vines.destroy_rope_starting(pos, 'vines:rope', 'vines:rope_bottom', 'vines:rope_top')
			return
		end

		local under = {x=pos.x, y=pos.y-1, z=pos.z}
		local n = minetest.get_node(under)

		if n.name ~= "vines:rope" and n.name ~= "vines:rope_bottom" then
			minetest.swap_node(pos, {name="vines:rope_bottom"}) -- Do not erase meta.
			local timer = minetest.get_node_timer( pos )
			timer:start( rope_timer_rate )
			return
		end
	end,

	-- This is not called when rope is destroyed via voxelmanip.
	after_destruct = function(pos, oldnode)
		local p = {x=pos.x, y=pos.y-1, z=pos.z}
		vines.destroy_rope_starting(p, 'vines:rope', 'vines:rope_bottom', 'vines:rope_top')
	end,
})

minetest.register_node("vines:rope_bottom", {
	description = "Rope",
	walkable = true,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	drop = "",
	tiles = { "vines_rope_bottom.png" },
	drawtype = "plantlike",
	groups = utility.dig_groups("ignore", {flammable=2, not_in_creative_inventory=1, always_stable=1}),
	sounds =  default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},
	light_source = 1,

	-- The bottom node has a collision box so that the player doesn't fall off the
	-- end when sliding downwards in darkness.
	collision_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, -0.4, 0.3},
	},

	movement_speed_multiplier = default.ROPE_SPEED,
	_no_collapse_on_walkover = true,

	on_construct = function( pos )
		local timer = minetest.get_node_timer( pos )
		timer:start( rope_timer_rate )
	end,

	on_timer = function( pos, elapsed )
		local currentend = minetest.get_node(pos)
		local currentmeta = minetest.get_meta(pos)
		local currentlength = currentmeta:get_int("length_remaining")
		local p = {x=pos.x, y=pos.y-1, z=pos.z}
		local n = minetest.get_node(p)
		if n.name == "air" and (currentlength > 1) then
			minetest.add_node(p, {name="vines:rope_bottom"})
			local newmeta = minetest.get_meta(p)
			newmeta:set_int("length_remaining", currentlength-1)
			newmeta:mark_as_private("length_remaining")
			minetest.swap_node(pos, {name="vines:rope"}) -- Do not erase meta.

			-- Check if there is another rope-middle node below, if so, combine ropes.
			local p2 = {x=pos.x, y=pos.y-2, z=pos.z}
			local n2 = minetest.get_node(p2)
			if n2.name == "vines:rope" then
				-- We have to swap the bottom node for a middle node, otherwise
				-- there will be a strangely collision box blockage in the middle of the rope
				-- for no apparent reason.
				minetest.swap_node(p, {name="vines:rope"}) -- Do not erase meta.
			end
		end
	end,

	-- If rope has fallen asleep, you can wake it up with a punch.
	on_punch = function(pos, node, puncher, pt)
		if not puncher or not puncher:is_player() then
			return
		end

		-- If the rope is protected, don't extend the rope any further.
		-- This lets players use ropes as secure entrances to forts.
		-- That is, only owner can let rope down, others cannot let it down.
		local pname = puncher:get_player_name()
		if minetest.test_protection(pos, pname) then
			return
		end

		local timer = minetest.get_node_timer( pos )
		timer:start( rope_timer_rate )
	end,
})

-- The top-rope-node is placed only when rope is being destroyed!
minetest.register_node("vines:rope_top", {
	description = "Rope",
	walkable = false,
	climbable = true,
	sunlight_propagates = true,
	paramtype = "light",
	drop = "",
	tiles = { "vines_rope_top.png" },
	drawtype = "plantlike",
	groups = utility.dig_groups("ignore", {not_in_creative_inventory=1, always_stable=1}),
	sounds =  default.node_sound_leaves_defaults(),
	light_source = 1,

	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},

	movement_speed_multiplier = default.ROPE_SPEED,
	_no_collapse_on_walkover = true,

	on_construct = function( pos )
		local timer = minetest.get_node_timer( pos )
		timer:start( rope_timer_rate )
	end,

	on_timer = function( pos, elapsed )
		local p = {x=pos.x, y=pos.y-1, z=pos.z}
		local n = minetest.get_node(p)

		if (n.name ~= "ignore") then
			vines.destroy_rope_starting(p, 'vines:rope', 'vines:rope_bottom', 'vines:rope_top')
			minetest.add_node(pos, {name="air"})
		else
			local timer = minetest.get_node_timer( pos )
			timer:start( 3.0 )
		end
	end
})
