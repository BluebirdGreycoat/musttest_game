
if not minetest.global_exists("mapgen") then mapgen = {} end

function mapgen.get_blockseed(pos)
	return minetest.hash_node_position(pos)
end
