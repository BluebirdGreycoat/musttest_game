
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round

local nodes = {
  --[[
	-- Replace torches with real lanterns in front of the gate.
	{pos={x=-9167, y=4103, z=5779}, node={name="xdecor:lantern", param2=1}},
	{pos={x=-9167, y=4103, z=5785}, node={name="xdecor:lantern", param2=1}},

	-- Add a furnace to the miner's hut.
	{pos={x=-9177, y=4176, z=5745}, node={name="redstone_furnace:inactive", param2=3}},

	-- Graveyard protector.
	{pos={x=-9266, y=4170, z=5724}, node={name="protector:protect3", param2=0}},

	-- Farm protectors.
	{pos={x=-9082, y=4179, z=5720}, node={name="protector:protect3", param2=0}},
	{pos={x=-9139, y=4168, z=5795}, node={name="protector:protect3", param2=0}},
	{pos={x=-9199, y=4169, z=5836}, node={name="protector:protect3", param2=0}},

	-- Protector in the miner's hut.
	{pos={x=-9176, y=4175, z=5745}, node={name="protector:protect3", param2=0}},

	-- Spawn protector.
	{pos={x=-9223, y=4168, z=5861}, node={name="protector:protect3", param2=0}},

	-- Extra signs at spawn.
	{pos={x=-9221, y=4169, z=5861}, node={name="signs:sign_wall_wood", param2=2}},
	{pos={x=-9221, y=4169, z=5860}, node={name="signs:sign_wall_wood", param2=2}},

	-- Extra pillar between Oerkki spawn point and the gate.
	{pos={x=-9169, y=4104, z=5782}, node={name="pillars:rackstone_cobble_top", param2=3}},
	{pos={x=-9169, y=4103, z=5782}, node={name="walls:rackstone_cobble_noconnect", param2=0}},
	{pos={x=-9169, y=4102, z=5782}, node={name="walls:rackstone_cobble_noconnect", param2=0}},
	{pos={x=-9169, y=4101, z=5782}, node={name="walls:rackstone_cobble_noconnect", param2=0}},
	{pos={x=-9169, y=4100, z=5782}, node={name="pillars:rackstone_cobble_bottom", param2=3}},
	--]]
}

local function rebuild_nodes()
	for k, v in ipairs(nodes) do
		minetest.set_node(v.pos, v.node)
	end
end

local metadata = {
  --[[
	-- Gate room, protection on floor.
	{pos={x=-9174, y=4099, z=5782}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Gate room, protection on ceiling.
	{pos={x=-9174, y=4106, z=5782}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Gate protection, left side.
	{pos={x=-9165, y=4103, z=5785}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Gate protection, right side.
	{pos={x=-9165, y=4103, z=5779}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Poem, left side.
	{pos={x=-9172, y=4100, z=5783}, meta={fields={
		infotext = "Make your choice, adventurous Stranger,\nStrike the Gate and bide the Danger!",
		author = "MustTest",
		text = "Make your choice, adventurous Stranger,%nStrike the Gate and bide the Danger!"
	}}},
	-- Poem, right side.
	{pos={x=-9172, y=4100, z=5781}, meta={fields={
		infotext = "Or else wonder, till it drives you mad,\nWhat would have followed, if you had.",
		author = "MustTest",
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
		obsidian_gateway_owner_ew = "MustTest",
		obsidian_gateway_destination_ew = get_exit_location(),
	}}},
	-- Gravesite sign, left.
	{pos={x=-9265, y=4172, z=5724}, meta={fields={
		infotext = "Henry D. Miner\nApril 13, 1821 - October 3, 1890\n\"An ardent Abolitionist, a true Republican, and a determined teetotaler.\"",
		author = "MustTest",
		text = "Henry D. Miner%nApril 13, 1821 - October 3, 1890%n\"An ardent Abolitionist, a true Republican, and a determined teetotaler.\""
	}}},
	-- Gravesite sign, right.
	{pos={x=-9267, y=4172, z=5724}, meta={fields={
		infotext = "Martha Ann Lee Miner\nNovember 2, 1829 - February 19, 1897",
		author = "MustTest",
		text = "Martha Ann Lee Miner%nNovember 2, 1829 - February 19, 1897"
	}}},
	-- Spawn sign, left.
	{pos={x=-9221, y=4170, z=5861}, meta={fields={
		infotext = "Use /spawn to get back here.",
		author = "MustTest",
		text = "Use /spawn to get back here."
	}}},
	-- Spawn sign, right.
	{pos={x=-9221, y=4170, z=5860}, meta={fields={
		infotext = "Use /info to get help.",
		author = "MustTest",
		text = "Use /info to get help."
	}}},
	-- Spawn sign, bottom left.
	{pos={x=-9221, y=4169, z=5861}, meta={fields={
		infotext = "See \"http://arklegacy.duckdns.org\" for important info.",
		author = "MustTest",
		text = "See \"http://arklegacy.duckdns.org\" for important info."
	}}},
	-- Spawn sign, bottom right.
	{pos={x=-9221, y=4169, z=5860}, meta={fields={
		infotext = "Take care, don't rush!",
		author = "MustTest",
		text = "Take care, don't rush!"
	}}},
	-- Graveyard protector.
	{pos={x=-9266, y=4170, z=5724}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Farm protectors.
	{pos={x=-9082, y=4179, z=5720}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	{pos={x=-9139, y=4168, z=5795}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	{pos={x=-9199, y=4169, z=5836}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Protector in the miner's hut.
	{pos={x=-9176, y=4175, z=5745}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	-- Spawn protector.
	{pos={x=-9223, y=4168, z=5861}, meta={fields={
		infotext = "Protection (Owned by <MustTest>!)\nPlaced on 2020/02/12 UTC",
		owner = "MustTest",
		placedate = "2020/02/12 UTC",
		rename = "MustTest",
	}}},
	--]]
}

local function rebuild_metadata()
	for k, v in ipairs(metadata) do
		local meta = minetest.get_meta(v.pos)
		meta:from_table(v.meta)
	end
end

local timers = {
  --[[
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
	--]]
}

local function restart_timers()
	for k, v in ipairs(timers) do
		local timer = minetest.get_node_timer(v)
		timer:start(1)
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
	local minp = table.copy(rc.get_realm_data("midfeld").minp)
	local maxp = table.copy(rc.get_realm_data("midfeld").maxp)

	-- TODO: delete me
	minp.y = minp.y - 400
	maxp.y = maxp.y - 400

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
	local schematic = rc.modpath .. "/midfeld.mts"
	local pos = {x=-12381, y=4050+400, z=5575}

	local replacements = {
    --["default:stone_with_tin"] = "moreores:mineral_tin",
  }

	minetest.place_schematic(pos, schematic, "0", replacements, true, "")

	-- Erase all stale metadata.
	for k, v in ipairs(pos_metas) do
		local meta = minetest.get_meta(v)
		meta:from_table(nil)
	end

	teleports.delete_blocks_from_area(minp, maxp)
	city_block.delete_blocks_from_area(minp, maxp)

	-- Restore all bones.
	for k, v in ipairs(bones) do
		-- TODO: zero me.
		local np = vector.add(v.pos, {x=0, y=400, z=0})
		minetest.set_node(np, v.node)
		minetest.get_meta(np):from_table(v.meta)
		minetest.get_node_timer(np):start(10)
	end

	-- Finally, rebuild the core metadata and node structure.
	rebuild_nodes()
	rebuild_metadata()
	restart_timers()
end

-- This API may be called to completely reset the Outback realm.
-- It will restore the realm's map and metadata.
function serveressentials.rebuild_gaterealm()
	local p1 = table.copy(rc.get_realm_data("midfeld").minp)
	local p2 = table.copy(rc.get_realm_data("midfeld").maxp)

	-- TODO: delete me
	p1.y = p1.y - 400

	minetest.emerge_area(p1, p2, callback, {})
end
