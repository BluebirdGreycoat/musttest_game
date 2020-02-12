
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
		infotext = "Make your choice, adventurous Stranger,\nStrike the Gate and bide the danger!",
		author = "MustTest",
		text = "Make your choice, adventurous Stranger,%nStrike the Gate and bide the danger!"
	}}},
	-- Poem, right side.
	{pos={x=-9172, y=4100, z=5781}, meta={fields={
		infotext = "Or else wonder, till it drives you mad,\nWhat would have happened, if you had.",
		author = "MustTest",
		text = "Or else wonder, till it drives you mad,%nWhat would have happened, if you had."
	}}},
	-- Door on the miner's hut.
	{pos={x=-9174, y=4175, z=5744}, meta={fields={
		state = "1",
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
