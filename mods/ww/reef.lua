
local vm_data = {}
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")
local c_bedrock = minetest.get_content_id("bedrock:bedrock")
local c_skeleton = minetest.get_content_id("default:coral_skeleton")
local c_sand = minetest.get_content_id("default:sand")
local c_pickle = minetest.get_content_id("decorations_sea:sea_cucumber")

local TAN_OF_1 = math.tan(1)

local abs = math.abs
local floor = math.floor
local max = math.max
local min = math.min
local tan = math.tan

local CORAL_PLANT_CIDS = {
	minetest.get_content_id("default:coral_green"),
	minetest.get_content_id("default:coral_pink"),
	minetest.get_content_id("default:coral_cyan"),
	minetest.get_content_id("decorations_sea:plant_coral_1"),
	minetest.get_content_id("decorations_sea:plant_coral_2"),
	minetest.get_content_id("decorations_sea:plant_coral_3"),
	minetest.get_content_id("decorations_sea:plant_coral_4"),
	minetest.get_content_id("decorations_sea:plant_coral_5"),
}

local CORAL_BLOCK_CIDS = {
	minetest.get_content_id("default:coral_brown"),
	minetest.get_content_id("default:coral_orange"),
	minetest.get_content_id("decorations_sea:node_coral_1"),
	minetest.get_content_id("decorations_sea:node_coral_2"),
	minetest.get_content_id("decorations_sea:node_coral_3"),
	minetest.get_content_id("decorations_sea:node_coral_4"),
	minetest.get_content_id("decorations_sea:node_coral_5"),
	minetest.get_content_id("decorations_sea:node_coral_6"),
	minetest.get_content_id("decorations_sea:node_coral_7"),
	minetest.get_content_id("decorations_sea:node_coral_8"),
}

local KELP_CIDS = {
	minetest.get_content_id("default:sand_with_kelp"),
	minetest.get_content_id("decorations_sea:sand_with_seagrass_1"),
	minetest.get_content_id("decorations_sea:sand_with_seagrass_2"),
	minetest.get_content_id("decorations_sea:sand_with_seagrass_3"),
}

local SEAGRASS_CIDS = {
	minetest.get_content_id("decorations_sea:sand_with_seagrass_4"),
	minetest.get_content_id("decorations_sea:sand_with_seagrass_5"),
	minetest.get_content_id("decorations_sea:sand_with_seagrass_6"),
}

local SAND_DECO_CIDS = {
	minetest.get_content_id("decorations_sea:sand_decoration_1"),
	minetest.get_content_id("decorations_sea:sand_decoration_2"),
	minetest.get_content_id("decorations_sea:sand_decoration_3"),
	minetest.get_content_id("decorations_sea:sand_decoration_4"),
	minetest.get_content_id("decorations_sea:sand_decoration_5"),
}

function ww.generate_reefs(vm, minp, maxp, seed, ystart, yend, yground)
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
	local area2d = VoxelArea2D:new({MinEdge={x=emin.x, y=emin.z}, MaxEdge={x=emax.x, y=emax.z}})
	local pr = PseudoRandom(seed + 3343)

	vm:get_data(vm_data)

	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z

	-- Compute side lengths.
	-- Note: noise maps use overgeneration coordinates/sizes.
	-- This is to support horizontal shearing.
	local side_len_x = ((emax.x-emin.x)+1)
	local side_len_y = ((emax.y-emin.y)+1)
	local side_len_z = ((emax.z-emin.z)+1)
	local sides2D = {x=side_len_x, y=side_len_z}
	local sides3D = {x=side_len_x, y=side_len_y, z=side_len_z}
	local bp2d = {x=emin.x, y=emin.z}
	local bp3d = {x=emin.x, y=emin.y, z=emin.z}

	for z = z0, z1 do
		for x = x0, x1 do
			for y = y0, y1 do
				if y >= ystart and y <= yend then
					local vp = area:index(x, y, z)
				end
			end
		end
	end

	vm:set_data(vm_data)
end
