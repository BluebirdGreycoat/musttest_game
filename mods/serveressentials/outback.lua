
local nodes = {
	-- Replace torches with real lanterns in front of the gate.
	{pos={x=-9167, y=4103, z=5779}, node={name="xdecor:lantern", param2=1}},
	{pos={x=-9167, y=4103, z=5785}, node={name="xdecor:lantern", param2=1}},

	-- Add a furnace to the miner's hut.
	{pos={x=-9177, y=4176, z=5745}, node={name="redstone_furnace:inactive", param2=3}},
}

local function rebuild_nodes()
	for k, v in ipairs(nodes) do
		minetest.set_node(v.pos, v.node)
	end
end

local metadata = {
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
	-- Door on the secret beer stash.
	{pos={x=-9090, y=4182, z=5869}, meta={fields={
		state = "0",
	}}},
	-- The gateway portal itself.
	{pos={x=-9164, y=4101, z=5780}, meta={fields={
		obsidian_gateway_success_ew = "yes",
		obsidian_gateway_return_gate_ew = "0",
		obsidian_gateway_owner_ew = "MustTest",
		obsidian_gateway_destination_ew = "(-1530,23,2633)",
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
}

local function rebuild_metadata()
	for k, v in ipairs(metadata) do
		local meta = minetest.get_meta(v.pos)
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

	local schematic = rc.modpath .. "/outback_map.mts"
	local pos = {x=-9274, y=4000, z=5682}
	minetest.place_schematic(pos, schematic, "0", {}, true, "")

	-- Finally, rebuild the metadata.
	rebuild_nodes()
	rebuild_metadata()
	restart_timers()
end

-- This API may be called to completely reset the Outback realm.
-- It will restore the realm's map and metadata.
function serveressentials.rebuild_outback()
	local p1 = table.copy(rc.realms[4].minp)
	local p2 = table.copy(rc.realms[4].maxp)

	minetest.emerge_area(p1, p2, callback, {})
end
