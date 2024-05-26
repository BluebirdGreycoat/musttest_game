
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round

local nodes = {}

local function rebuild_nodes()
	for k, v in ipairs(nodes) do
		minetest.set_node(v.pos, v.node)
	end
end

local metadata = {}

local function rebuild_metadata()
	for k, v in ipairs(metadata) do
		local meta = minetest.get_meta(v.pos)
		meta:from_table(v.meta)
	end
end

local timers = {}

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
		local np = vector.add(v.pos, {x=0, y=0, z=0})
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

	minetest.emerge_area(p1, p2, callback, {})
end
