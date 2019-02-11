
-- Note: this code only makes sense if the server is restarted on
-- a regular basis, such as 12:00 AM every night. Use a cronjob!
-- This code modifies the `default:snow` definition to create seasons.
snow = {}

function snow.on_player_walk_over(pos, player)
	minetest.swap_node(pos, {name="snow:footprints", param2=math.random(0, 3)})
end

function snow.on_dig(pos, node, digger)
	if digger and digger:is_player() then
		minetest.remove_node(pos)
		core.check_for_falling(pos)
		local inv = digger:get_inventory()
		if inv then
			inv:add_item("main", "default:snow")
		end
	end
end

-- Enable default:snow to bypass protection (MustTest).
-- However, I take pains to prevent griefing by e.g. replacing other nodes than air.
-- This is called whenever snow is placed, even in protected areas.
function snow.on_place(itemstack, placer, pt)
	if pt.above and pt.under then
		local node = minetest.get_node(pt.under)
		local udef = minetest.reg_ns_nodes[node.name]
		if udef and udef.on_rightclick and not (placer and placer:get_player_control().sneak) then
			return udef.on_rightclick(pt.under, node, placer, itemstack, pt) or itemstack
		end

		if minetest.get_node(pt.above).name == "air" then
			local nunder = minetest.get_node(pt.under).name
			-- Don't place snow if already placed.
			if nunder == itemstack:get_name() then
				return itemstack
			end

			-- Don't allow placement on non-walkable nodes. Prevents griefing of non-walkable things like grass, flowers.
			local def = minetest.reg_ns_nodes[nunder]
			if not def or not def.walkable then
				return itemstack
			end

			-- Don't allow placement on slabs or stairs. That just looks ugly.
			if minetest.get_item_group(nunder, "stair") > 0 or
				minetest.get_item_group(nunder, "slab") > 0 or
				minetest.get_item_group(nunder, "wall") > 0 or
				minetest.get_item_group(nunder, "rail") > 0 or
				minetest.get_item_group(nunder, "fence") > 0 then
				return itemstack
			end

			minetest.set_node(pt.above, {name=itemstack:get_name()})
			-- We cannot call minetest.place_node() because that will create an infinite loop.
			minetest.check_for_falling(pt.above)

			itemstack:take_item()
			return itemstack
		end
	end
end

-- Original snowdef.
local origsnowdef = {
	description = "Snow\n\nThis will melt away in warm weather.\nIt comes back in cold weather.\nCan bypass protection.",
	tiles = {"default_snow.png"},
	inventory_image = "default_snowball.png",
	wield_image = "default_snowball.png",
	buildable_to = true,
	use_texture_alpha = true,
	crushing_damage = 0,

	-- These 2 cannot be changed dynamically without creating lighting issues.
	paramtype = "light",
  sunlight_propagates = true,

	floodable = true,
	walkable = true,
	drawtype = "nodebox",
	movement_speed_multiplier = default.SLOW_SPEED,
	_melts_to = "air",

	-- All snow types should become `default:snow`.
	-- These shouldn't ever be gotten directly by players.
	-- The exception is `snow:snowtest_4`, which spawns on trees.
	drop = "default:snow",

	-- Nodebox is set up manually.
	node_box = {
		type = "fixed",
		fixed = {
			{},
		},
	},

	groups = {
		level = 1,
		crumbly = 3,
		falling_node = 1,
		puts_out_fire = 1,
		snow = 1,
		snowy = 1,
		cold = 1,
		melts = 1,

		-- Currently just used to notify thin_ice and torches.
		notify_construct = 1,
	},

	-- Sound info.
	sounds = default.node_sound_snow_defaults(),

	on_construct = function(pos)
	end,

	on_timer = function(pos, elapsed)
		if rc.ice_melts_at_pos(pos) then
			minetest.remove_node(pos)
		end
	end,

	on_dig = function(...)
		return snow.on_dig(...)
	end,

	on_place = function(...)
		return snow.on_place(...)
	end,

	on_player_walk_over = function(...)
		return snow.on_player_walk_over(...)
	end,
}

-- Every snow height must be different (except for the 0's and 16's).
-- This is because footprints-in-snow rely on this table, too.
local snowheight = {
	0,
	0,
	0,
	0,
	2,
	3,
	5,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
	16, -- Footprints won't make indentation. We can assume snow has hard crust.
	16,
}

-- Create 17 snowdef tables.
-- Snowdef #1 is 'invisible', & snowdef #17 is full-block size.
snow.snowdef = {}
-- Must execute exactly 17 times, the code relies on this!
for i = 1, 17, 1 do
	snow.snowdef[i] = table.copy(origsnowdef)

	local fixed = {
		{0, 0, 0, 16, snowheight[i], 16},
	}
	-- Flatten the first few. This is because they are transparent,
	-- and their edges would otherwise create GFX artifacts.
	if i <= 4 then
		fixed[1][5] = 0.1
		-- Hide side tiles.
		for j = 2, 6, 1 do
			snow.snowdef[i].tiles[j] = "invisible.png"
		end
		snow.snowdef[i].drop = ""
	end
	utility.transform_nodebox(fixed)
	snow.snowdef[i].node_box.fixed = fixed

	local str = snow.snowdef[i].tiles[1]
	if i == 3 then
		snow.snowdef[i].tiles[1] = str .. "^[opacity:30"
	elseif i == 4 then
		snow.snowdef[i].tiles[1] = str .. "^[opacity:130"
	else
		snow.snowdef[i].use_texture_alpha = nil
	end

	if i <= 2 then
		-- If `i<=2` then node is invisible and should be as inert as possible.
		snow.snowdef[i].drawtype = "airlike"
		snow.snowdef[i].pointable = false
		snow.snowdef[i].node_box = nil
		snow.snowdef[i].groups.puts_out_fire = nil
		snow.snowdef[i].groups.snow = nil
		snow.snowdef[i].groups.snowy = nil
		snow.snowdef[i].groups.melts = nil
		snow.snowdef[i].groups.dig_immediate = 2
		snow.snowdef[i].no_sound_on_fall = true
		snow.snowdef[i].sounds = nil
	end
	if i == 3 then
		snow.snowdef[i].pointable = false
		snow.snowdef[i].no_sound_on_fall = true
		snow.snowdef[i].groups.dig_immediate = 2
	end
	if i == 4 then
		snow.snowdef[i].groups.dig_immediate = 2
	end

	if i <= 5 then
		snow.snowdef[i].movement_speed_multiplier = default.NORM_SPEED
	end

	if i >= 6 and i <= 10 then
		snow.snowdef[i].movement_speed_multiplier = default.SLOW_SPEED_NETHER
	end
	-- Deeper snow will default to `default.SLOW_SPEED`.

	if i <= 4 then
		snow.snowdef[i].walkable = false
	end

	-- The last 3 nodes are full-blocks.
	if i >= 15 then
		snow.snowdef[i].drawtype = "normal"
		snow.snowdef[i].node_box = nil
	end
	-- Everything else except `i==1` is nodebox.
	-- `i==1` should be invisible and mostly inert.

	-- These shouldn't ever be gotten directly by players.
	minetest.register_node("snow:snowtest_" .. i, snow.snowdef[i])
end

-- Create reverse sequence from the above 17 nodedefs.
do
	local which = 17
	for i = 18, 17*2, 1 do
		assert(which >= 1)
		assert(which <= 17)
		snow.snowdef[i] = snow.snowdef[which]
		which = which - 1
	end
end

-- Choose snow level!
snow.snowlevel = 1
function snow.choose_level()
	local cnt = 17*2 -- 34-day cycle.
	local off = 1 -- Need offset otherwise counting starts from 0.
	local epoch = os.time({year=2016, month=10, day=1})
	local secs = os.time()-epoch
	local day = (((secs/60)/60)/24)
	local which = math.floor(day%cnt)+off
	assert(which >= 1)
	assert(which <= 17*2)
	return which
	--return 5
end
snow.snowlevel = snow.choose_level()
function snow.get_day()
	local day = snow.choose_level()
	local season = "Season of White"
	if day <= 15 or day >= 20 then
		season = "Season of Drifts"
	end
	if day <= 7 or day >= 28 then
		season = "Season of Slush"
	end
	if day <= 3 or day >= 32 then
		season = "Season of Stone"
	end
	return day .. "/34 (" .. season .. ")"
end

function snow.get_snowdef()
	if snow.snowdef[snow.snowlevel] then
		return snow.snowdef[snow.snowlevel]
	end
	return origsnowdef
end

function snow.get_snowfootdef()
	-- The footprints snowdef is a copy of whatever the current snowdef
	-- is, with some minor modifications.
	local def = table.copy(origsnowdef)

	-- Reduce snow-height for footprints.
	local thislevel = snow.snowlevel
	if thislevel >= 3 and thislevel <= 17 then
		thislevel = thislevel - 1
	elseif thislevel <= 32 and thislevel >= 18 then
		thislevel = thislevel + 1
	end
	if snow.snowdef[thislevel] then
		def = table.copy(snow.snowdef[thislevel])
	end

	def.paramtype2 = "facedir"
	def.on_rotate = false -- It would be silly if screwdriver could rotate this.

	def.dumpnodes_tile = "default_snow.png"
	def.tiles = {
		"(default_snow.png^snow_footstep.png)",
		"default_snow.png",
	}

	do
		local i = thislevel
		local str1 = def.tiles[1]
		local str2 = def.tiles[2]
		if i == 2 or i == 33 then
			def.tiles[1] = str1 .. "^[opacity:30"
			def.tiles[2] = str1 .. "^[opacity:30"
		elseif i == 3 or i == 32 then
			def.tiles[1] = str1 .. "^[opacity:130"
			def.tiles[2] = str1 .. "^[opacity:130"
		else
			def.use_texture_alpha = nil
		end
	end

	-- The regular snow already did this.
	def.groups.notify_construct = nil

	-- We do need the 'on_dig' function.
	-- Cannot nil this out.
	--def.on_dig = nil

	-- It should never be possible to place 'snow with footprints'
	-- so this is unnecessary.
	def.on_place = nil

	def.on_construct = function(pos)
		if rc.ice_melts_at_pos(pos) then
			minetest.remove_node(pos)
			return
		end
		local time = 60*60*24*7
		local rand = math.random(60*60*1, 60*60*24)
		minetest.get_node_timer(pos):start(time+rand)
	end
	def.on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name="default:snow"})
	end
	def.on_player_walk_over = function(pos, player)
		local time = 60*60*24*7
		local rand = math.random(60*60*1, 60*60*24)
		minetest.get_node_timer(pos):start(time+rand)
	end
	-- Snow with footprints turns back to snow if it falls.
	def.on_finish_collapse = function(pos, node)
		minetest.swap_node(pos, {name="default:snow"})
	end
	def.on_collapse_to_entity = function(pos, node)
		core.add_item(pos, {name="default:snow"})
	end
	return def
end

function snow.should_spawn_icemen()
	if snow.snowlevel >= 7 and snow.snowlevel <= 28 then
		return true
	end
	return false
end

function snow.get_treedef()
	local def = table.copy(origsnowdef)

	local thislevel = 5
	if snow.snowdef[thislevel] then
		def = table.copy(snow.snowdef[thislevel])
	end

	def.description = "Tree Snow"
	def.groups.dig_immediate = 2
	def.drop = ""
	def.on_dig = nil
	def.on_place = nil
	def.on_player_walk_over = nil

	-- Player should not be able to obtain node.
	def.on_finish_collapse = function(pos, node)
		if math.random(1, 3) == 1 then
			minetest.remove_node(pos)
		end
	end
	def.on_collapse_to_entity = function(pos, node)
		-- Do nothing.
	end

	return def
end

-- The snow definition changes dynamically based on date.
minetest.register_node(":default:snow", snow.get_snowdef())
minetest.register_node("snow:footprints", snow.get_snowfootdef())
minetest.register_node("snow:tree", snow.get_treedef())

-- Should return `true' if name is snow or any variant thereof,
-- (footsteps, treesnow) NOT including default:snowblock.
function snow.is_snow(name)
	if name == "default:snow" or
		name == "snow:tree" or
		name == "snow:footprints" then
		return true
	end
end

-- Should match the names in the above function.
function snow.get_names()
	return {"default:snow", "snow:tree", "snow:footprints"}
end
