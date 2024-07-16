
VoxelArea2D = {}

-- Constructor.
function VoxelArea2D:new(extents)
	local minp = extents.MinEdge
	local maxp = extents.MaxEdge

	minp = {x=minp.x, y=minp.y}
	maxp = {x=maxp.x, y=maxp.y}

	local stride = ((maxp.y - minp.y) + 1)

	local min_x = minp.x
	local min_y = minp.y

	local obj = {}

	function obj:index(x, y)
		local nx = (x - min_x)
		local ny = (y - min_y)

		-- Lua arrays start indexing at 1, not 0. Urrrrgh.
		return (stride * ny + nx) + 1
	end

	setmetatable(obj, {})
	return obj
end
