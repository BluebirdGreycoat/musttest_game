
-- The current location of the Outback's gateway exit.
-- Note: this is updated to the correct position (as stored in mod-storage)
-- on first load or whenever the mod is reloaded.
serveressentials.gateway_exit_position = {x=0, y=0, z=0}

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round

-- Called by the protector mod to determine if a protector can be placed here,
-- with respect to the Outback gateway's current exit location.
local PROTECTOR_DISTANCE_FROM_EXIT = 50
function serveressentials.protector_can_place(pos)
	local p2 = serveressentials.gateway_exit_position
	if vector_distance(pos, p2) > PROTECTOR_DISTANCE_FROM_EXIT then
		return true
	end
	return false
end

local function get_exit_location()
	local meta = serveressentials.modstorage
	local s = meta:get_string("outback_exit_location")
	if s and s ~= "" then
		local p = minetest.string_to_pos(s)
		if p then
			return s
		end
	end

	-- Fallback.
	return "(0,-7,0)"
end
serveressentials.get_exit_location = get_exit_location
serveressentials.gateway_exit_position = minetest.string_to_pos(get_exit_location())

function serveressentials.get_current_exit_location()
	-- Also need to update the gate itself, right away.
	local m2 = minetest.get_meta({x=-9164, y=4101+400, z=5780})
	local s2 = m2:get_string("obsidian_gateway_destination_ew")
	return s2
end

function serveressentials.update_exit_location(pos)
	pos = vector_round(pos)

	-- Update position stored in memory.
	local p = serveressentials.gateway_exit_position
	p.x = pos.x
	p.y = pos.y
	p.z = pos.z

	-- Update the location stored in mod-storage.
	local meta = serveressentials.modstorage
	local s = minetest.pos_to_string(pos)
	meta:set_string("outback_exit_location", s)

	-- Also need to update the gate itself, right away.
	local m2 = minetest.get_meta({x=-9164, y=4101+400, z=5780})
	m2:set_string("obsidian_gateway_destination_ew", s)
end

local nodes = {
	-- Replace torches with real lanterns in front of the gate.
	{pos={x=-9167, y=4103, z=5779}, node={name="xdecor:lantern", param2=1}},
	{pos={x=-9167, y=4103, z=5785}, node={name="xdecor:lantern", param2=1}},

	-- Add a chair to the miner's hut.
	{pos={x=-9177, y=4176, z=5745}, node={name="xdecor:chair", param2=3}},

	-- Graveyard protector.
	{pos={x=-9266, y=4170, z=5724}, node={name="protector:protect3", param2=0}},

	-- Farm protectors.
	{pos={x=-9082, y=4179, z=5720}, node={name="protector:protect3", param2=0}},
	{pos={x=-9139, y=4168, z=5795}, node={name="protector:protect3", param2=0}},
	{pos={x=-9199, y=4169, z=5836}, node={name="protector:protect3", param2=0}},

	-- Protector in the miner's hut.
	{pos={x=-9176, y=4175, z=5745}, node={name="protector:protect3", param2=0}},

	-- Spawn protectors.
	{pos={x=-9223, y=4167, z=5861}, node={name="protector:protect", param2=0}},
	{pos={x=-9228, y=4172, z=5851}, node={name="protector:protect", param2=0}},
	{pos={x=-9227, y=4172, z=5861}, node={name="protector:protect", param2=0}},

	-- Extra signs at spawn.
	{pos={x=-9221, y=4169, z=5861}, node={name="signs:sign_wall_brass", param2=2}},
	{pos={x=-9221, y=4169, z=5860}, node={name="signs:sign_wall_brass", param2=2}},
	{pos={x=-9221, y=4170, z=5861}, node={name="signs:sign_wall_brass", param2=2}},
	{pos={x=-9221, y=4170, z=5860}, node={name="signs:sign_wall_brass", param2=2}},

	-- Extra pillar between Oerkki spawn point and the gate.
	{pos={x=-9169, y=4104, z=5782}, node={name="pillars:rackstone_cobble_top", param2=3}},
	{pos={x=-9169, y=4103, z=5782}, node={name="walls:rackstone_cobble_noconnect", param2=0}},
	{pos={x=-9169, y=4102, z=5782}, node={name="walls:rackstone_cobble_noconnect", param2=0}},
	{pos={x=-9169, y=4101, z=5782}, node={name="walls:rackstone_cobble_noconnect", param2=0}},
	{pos={x=-9169, y=4100, z=5782}, node={name="pillars:rackstone_cobble_bottom", param2=3}},

	-- Beacon protectors.
	{pos={x=-9176, y=4191, z=5745}, node={name="protector:protect", param2=0}},
	{pos={x=-9176, y=4185, z=5745}, node={name="protector:protect", param2=0}},

	-- Signs in miner's hut.
	{pos={x=-9177, y=4177, z=5744}, node={name="signs:sign_wall_wood", param2=3}},
	{pos={x=-9177, y=4176, z=5744}, node={name="signs:sign_wall_wood", param2=3}},
	{pos={x=-9177, y=4177, z=5745}, node={name="signs:sign_wall_wood", param2=3}},
	{pos={x=-9175, y=4177, z=5746}, node={name="signs:sign_wall_wood", param2=4}},
	{pos={x=-9175, y=4176, z=5746}, node={name="signs:sign_wall_wood", param2=4}},
}

local function rebuild_nodes()
	for k, v in ipairs(nodes) do
		minetest.set_node(vector.add(v.pos, {x=0, y=400, z=0}), v.node)
	end
end

local OWNERNAME = minetest.settings:get("name") or "singleplayer"
local metadata = {
	-- Gate room, protection on floor.
	{pos={x=-9174, y=4099, z=5782}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Gate room, protection on ceiling.
	{pos={x=-9174, y=4106, z=5782}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Gate protection, left side.
	{pos={x=-9165, y=4103, z=5785}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Gate protection, right side.
	{pos={x=-9165, y=4103, z=5779}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Poem, left side.
	{pos={x=-9172, y=4100, z=5783}, meta={fields={
		infotext = "Make your choice, adventurous Stranger,\nStrike the Gate and bide the Danger!",
		author = OWNERNAME,
		text = "Make your choice, adventurous Stranger,%nStrike the Gate and bide the Danger!"
	}}},
	-- Poem, right side.
	{pos={x=-9172, y=4100, z=5781}, meta={fields={
		infotext = "Or else wonder, till it drives you mad,\nWhat would have followed, if you had.",
		author = OWNERNAME,
		text = "Or else wonder, till it drives you mad,%nWhat would have followed, if you had."
	}}},
	-- Door on the miner's hut.
	{pos={x=-9174, y=4175, z=5744}, meta={fields={
		state = "1",
	}}},
	-- Door on the calico stash (safe from Indians!).
	{pos={x=-9090, y=4182, z=5869}, meta={fields={
		state = "0",
	}}},
	-- The gateway portal itself.
	{pos={x=-9164, y=4101, z=5780}, meta={fields={
		obsidian_gateway_success_ew = "yes",
		obsidian_gateway_return_gate_ew = "0",
		obsidian_gateway_owner_ew = OWNERNAME,
		obsidian_gateway_destination_ew = get_exit_location(),
	}}},
	-- Gravesite sign, left.
	{pos={x=-9265, y=4172, z=5724}, meta={fields={
		infotext = "Henry D. Miner\nApril 13, 1821 - October 3, 1890\n\"An ardent Abolitionist, a true Republican, and a determined teetotaler.\"",
		author = OWNERNAME,
		text = "Henry D. Miner%nApril 13, 1821 - October 3, 1890%n\"An ardent Abolitionist, a true Republican, and a determined teetotaler.\""
	}}},
	-- Gravesite sign, right.
	{pos={x=-9267, y=4172, z=5724}, meta={fields={
		infotext = "Martha Ann Lee Miner\nNovember 2, 1829 - February 19, 1897",
		author = OWNERNAME,
		text = "Martha Ann Lee Miner%nNovember 2, 1829 - February 19, 1897"
	}}},
	-- Spawn sign, left.
	{pos={x=-9221, y=4170, z=5861}, meta={fields={
		infotext = "Use /spawn to get back here.",
		author = OWNERNAME,
		text = "Use /spawn to get back here."
	}}},
	-- Spawn sign, right.
	{pos={x=-9221, y=4170, z=5860}, meta={fields={
		infotext = "Use /info to get help.",
		author = OWNERNAME,
		text = "Use /info to get help."
	}}},
	-- Spawn sign, bottom left.
	{pos={x=-9221, y=4169, z=5861}, meta={fields={
		infotext = "See \"http://arklegacy.duckdns.org\" for important info.",
		author = OWNERNAME,
		text = "See \"http://arklegacy.duckdns.org\" for important info."
	}}},
	-- Spawn sign, bottom right.
	{pos={x=-9221, y=4169, z=5860}, meta={fields={
		infotext = "Take care, don't rush!",
		author = OWNERNAME,
		text = "Take care, don't rush!"
	}}},
	-- Graveyard protector.
	{pos={x=-9266, y=4170, z=5724}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Farm protectors.
	{pos={x=-9082, y=4179, z=5720}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	{pos={x=-9139, y=4168, z=5795}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	{pos={x=-9199, y=4169, z=5836}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Protector in the miner's hut.
	{pos={x=-9176, y=4175, z=5745}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Spawn protectors.
	{pos={x=-9223, y=4167, z=5861}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	{pos={x=-9228, y=4172, z=5851}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	{pos={x=-9227, y=4172, z=5861}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2020/02/12 UTC",
		owner = OWNERNAME,
		placedate = "2020/02/12 UTC",
		rename = OWNERNAME,
	}}},
	-- Beacon protectors.
	{pos={x=-9176, y=4185, z=5745}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2024/05/26 UTC",
		owner = OWNERNAME,
		placedate = "2024/05/26 UTC",
		rename = OWNERNAME,
	}}},
	{pos={x=-9176, y=4191, z=5745}, meta={fields={
		infotext = "Protection (Owned by <" .. OWNERNAME .. ">!)\nPlaced on 2024/05/26 UTC",
		owner = OWNERNAME,
		placedate = "2024/05/26 UTC",
		rename = OWNERNAME,
	}}},
	-- Signs in miner's hut.
	{pos={x=-9177, y=4177, z=5744}, meta={fields={
		infotext = "Find the Dimensional Gate at the bottom of this rope.\nThe gate is guarded.\nPrepare for combat!",
		author = OWNERNAME,
		text = "Find the Dimensional Gate at the bottom of this rope.%nThe gate is guarded.%nPrepare for combat!"
	}}},
	{pos={x=-9177, y=4177, z=5745}, meta={fields={
		infotext = "If you skipped reading /info, be sure to read it now.",
		author = OWNERNAME,
		text = "If you skipped reading /info, be sure to read it now."
	}}},
	{pos={x=-9177, y=4176, z=5744}, meta={fields={
		infotext = "There is NO WAY BACK BUT DEATH.",
		author = OWNERNAME,
		text = "There is NO WAY BACK BUT DEATH."
	}}},
	{pos={x=-9175, y=4177, z=5746}, meta={fields={
		infotext = "I hope, for your sake, you brought a bed and mutton.\nIf you didn't bring a bed, you'll wish you had ...\nAnd you'll find yourself standing in morde poo.",
		author = OWNERNAME,
		text = "I hope, for your sake, you brought a bed and mutton.%nIf you didn't bring a bed, you'll wish you had ...%nAnd you'll find yourself standing in morde poo."
	}}},
	{pos={x=-9175, y=4176, z=5746}, meta={fields={
		infotext = "Fortune favors the bold. Death finds the stupid.\nUsing a gate at night is stupid.\nDon't be that guy.",
		author = OWNERNAME,
		text = "Fortune favors the bold. Death finds the stupid.%nUsing a gate at night is stupid.%nDon't be that guy."
	}}},
}

local function rebuild_metadata()
	for k, v in ipairs(metadata) do
		local meta = minetest.get_meta(vector.add(v.pos, {x=0, y=400, z=0}))
		meta:from_table(v.meta)
	end
end

local timers = {
	-- First farm.
	{x=-9139, y=4172, z=5796},
	{x=-9140, y=4172, z=5796},

	-- Hilltop farm.
	{x=-9083, y=4183, z=5721},
	{x=-9082, y=4183, z=5721},
	{x=-9081, y=4183, z=5721},
	{x=-9083, y=4183, z=5719},
	{x=-9082, y=4183, z=5719},
	{x=-9081, y=4183, z=5719},
}

local function restart_timers()
	for k, v in ipairs(timers) do
		local timer = minetest.get_node_timer(vector.add(v, {x=0, y=400, z=0}))
		timer:start(1)
	end
end



-- Find outback surface under sunlight.
local function find_ground(pos)
	local n1 = minetest.get_node(pos)
	local p2 = vector.offset(pos, 0, -1, 0)
	local n2 = minetest.get_node(p2)
	local count = 0
	while n2.name == "air" and count < 32 do
		pos = p2
		n1 = minetest.get_node(pos)
		p2 = vector.offset(pos, 0, -1, 0)
		n2 = minetest.get_node(p2)
		count = count + 1
	end
	if n2.name == "rackstone:cobble" and n1.name == "air" then
		if (minetest.get_node_light(pos, 0.5)) or 0 == 15 then
			return pos
		end
	end
end



local function place_random_farms(minp, maxp)
	for count = 1, 50 do
		local p = {
			x = math.random(minp.x + 10, maxp.x - 10),
			y = maxp.y,
			z = math.random(minp.z + 10, maxp.z - 10),
		}
		local g = find_ground(p)
		if g then
			-- Check corners.
			local c1 = find_ground(vector.offset(g, -2, 16, -2))
			local c2 = find_ground(vector.offset(g, 2, 16, -2))
			local c3 = find_ground(vector.offset(g, -2, 16, 2))
			local c4 = find_ground(vector.offset(g, 2, 16, 2))

			local b1, b2, b3, b4 = false, false, false, false

			-- Make sure ground is mostly flat.
			if c1 and math.abs(c1.y - g.y) < 2 then b1 = true end
			if c2 and math.abs(c2.y - g.y) < 2 then b2 = true end
			if c3 and math.abs(c3.y - g.y) < 2 then b3 = true end
			if c4 and math.abs(c4.y - g.y) < 2 then b4 = true end

			-- Can't be protected. This relies on protectors and protector meta being
			-- set *before* we place the farms!
			if minetest.test_protection(c1, "") then b1 = false end
			if minetest.test_protection(c2, "") then b2 = false end
			if minetest.test_protection(c3, "") then b3 = false end
			if minetest.test_protection(c4, "") then b4 = false end

			if b1 and b2 and b3 and b4 then
				local schematic = rc.modpath .. "/outback_small_farm.mts"
				local d = vector.offset(g, -2, -2, -2)
				minetest.place_schematic(d, schematic, "random", {}, true, "")
			end
		end
	end
end



local function callback(blockpos, action, calls_remaining, param)
	-- We don't do anything until the last callback.
	if calls_remaining ~= 0 then
		return
	end

	-- Check if there was an error on the LAST call.
	-- Note: this will usually fail if the area to emerge intersects the map edge.
	-- But usually we don't try to do that, here.
	if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
		return
	end

	-- Locate all nodes with metadata.
	local minp = table.copy(rc.get_realm_data("abyss").minp)
	local maxp = table.copy(rc.get_realm_data("abyss").maxp)
	local pos_metas = minetest.find_nodes_with_meta(minp, maxp)

	-- Locate all bones and load their meta into memory.
	local bones = {}
	for k, v in ipairs(pos_metas) do
		local node = minetest.get_node(v)
		if node.name == "bones:bones" then
			local meta = minetest.get_meta(v)
			local data = {}
			data.pos = v
			data.meta = meta:to_table()
			data.node = node
			bones[#bones + 1] = data
		end
	end

	-- Place schematic. This overwrites all nodes, but not necessarily their meta.
	local schematic = rc.modpath .. "/outback_map.mts"
	local apron_schematic = rc.modpath .. "/outback_apron.mts"
	local beacon_schem = rc.modpath .. "/outback_beacon.mts"
	local spawn_cave_schem = rc.modpath .. "/outback_spawn_cave.mts"
	local pos = {x=-9274, y=4000+400, z=5682}
	local apron_pos = {x=-9314, y=4141+400, z=5642}
	local beacon_pos = {x=-9180, y=4580, z=5741}
	local spawn_cave_pos = {x=-9233, y=4568, z=5851}
	local replacements = {}

	if minetest.registered_nodes["basictrees:acacia_branch"] then
		replacements = {
			["stairs:slope_acacia_trunk_outer"] = "basictrees:acacia_branch",
		}
	end

	minetest.place_schematic(apron_pos, apron_schematic, "0", replacements, true, "")
	minetest.place_schematic(pos, schematic, "0", replacements, true, "")
	minetest.place_schematic(beacon_pos, beacon_schem, "0", replacements, true, "")
	minetest.place_schematic(spawn_cave_pos, spawn_cave_schem, "0", replacements, true, "")

	-- Erase all stale metadata.
	for k, v in ipairs(pos_metas) do
		local meta = minetest.get_meta(v)
		meta:from_table(nil)
	end

	-- Erase the rope.
	for k = 4500, 4577, 1 do
		local p = {x=-9177, y=k, z=5746}
		minetest.set_node(p, {name="air"})
	end

	-- Rebuild the rope, with self-constructing nodes.
	do
		local p = {x=-9177, y=4577, z=5746}
		local n = minetest.get_node(p)
		if n.name == "air" then
			minetest.add_node(p, {name="vines:rope_bottom"})
			local meta = minetest.get_meta(p)
			meta:set_int("length_remaining", 80)
			meta:mark_as_private("length_remaining")
		end
	end

	teleports.delete_blocks_from_area(minp, maxp)
	city_block.delete_blocks_from_area(minp, maxp)

	-- Restore all bones.
	for k, v in ipairs(bones) do
		local np = vector.add(v.pos, {x=0, y=0, z=0})
		minetest.set_node(np, v.node)
		minetest.get_meta(np):from_table(v.meta)
		minetest.get_node_timer(np):start(10)
	end

	-- Finally, rebuild the core metadata and node structure.
	rebuild_nodes()
	rebuild_metadata()
	restart_timers()
	place_random_farms(minp, maxp)
end

-- This API may be called to completely reset the Outback realm.
-- It will restore the realm's map and metadata.
function serveressentials.rebuild_outback()
	local p1 = table.copy(rc.get_realm_data("abyss").minp)
	local p2 = table.copy(rc.get_realm_data("abyss").maxp)

	minetest.emerge_area(p1, p2, callback, {})
end
