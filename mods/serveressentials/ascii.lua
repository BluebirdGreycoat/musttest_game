
-- My Little Pony is a Racist, Colonialist Monarchy.
-- Cool stuff!
-- https://www.youtube.com/watch?v=QV7SHnKSgs0

serveressentials.TEXTBLIT_WRITE_SURF = "default:snow" -- Don't change unless you know what you're doing.
serveressentials.TEXTBLIT_WRITE_NODE = "air"

local floor = math.floor
local tobyte = string.byte
local modpath = minetest.get_modpath("serveressentials")
local vips = require("vips")
if not type(vips) == "table" then return end

-- ASCII bitmap: 160x160 pixel dimensions, 10x10 pixel glyphs, 16x16 characters.
local ascii = vips.Image.new_from_file(modpath .. "/ascii-bitmap-font.png")
local buffer = ascii:write_to_memory() -- CDATA, not string.

-- Glyph dimensions.
local gwidth = 10
local gheight = 10

function cuboid_bounds(points)
	local min_x, max_x = points[1].x, points[1].x
	local min_z, max_z = points[1].z, points[1].z

	for _, point in ipairs(points) do
		min_x = math.min(min_x, point.x)
		max_x = math.max(max_x, point.x)
		min_z = math.min(min_z, point.z)
		max_z = math.max(max_z, point.z)
	end

	return {x=min_x, z=min_z}, {x=max_x, z=max_z}
end

-- Rotate bitmap around origin in-place.
local function rotate_bitmap(pos, bitmap, dir)
	for i = 1, #bitmap, 1 do
		local p = bitmap[i]

		local rx = p.x - pos.x
		local rz = p.z - pos.z
		local nx, nz

		if dir == 0 then
			-- North
			nx = rx
			nz = rz
		elseif dir == 2 then
			-- South.
			nx = -rx
			nz = -rz
		elseif dir == 3 then
			-- West.
			nx = -rz
			nz = rx
		elseif dir == 1 then
			-- East.
			nx = rz
			nz = -rx
		else
			-- Default north.
			nx = rx
			nz = rz
		end

		p.x = pos.x + nx
		p.z = pos.z + nz
	end
end

local function blit_text(pname, minp, maxp, points)
	-- Colors.
	local c_writesurf = minetest.get_content_id(serveressentials.TEXTBLIT_WRITE_SURF)
	local c_writenode = minetest.get_content_id(serveressentials.TEXTBLIT_WRITE_NODE)

	local vm = VoxelManip()
	minp, maxp = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm:get_data()

	-- This simply searches the column downwards starting from the top,
	-- and stops at the first writable node it finds, returning its index.
	local function find_surf(x, z)
		local top = maxp.y
		local bot = minp.y
		for k = top, bot, -1 do
			local vi = area:index(x, k, z)
			if data[vi] == c_writesurf then
				return vi
			end
		end
	end

	for i = 1, #points, 1 do
		local x = points[i].x
		local z = points[i].z

		local vi = find_surf(x, z)
		if vi then data[vi] = c_writenode end
	end

	vm:set_data(data)
	vm:write_to_map()
	minetest.chat_send_player(pname, "# Server: Text blit done.")
end

function serveressentials.textblit(pname, param)
	local user = minetest.get_player_by_name(pname)
	if not user or not user:is_player() then return end

	param = param:trim()
	if #param == 0 then
		minetest.chat_send_player(pname, "# Server: Nothing to blit.")
		return
	end
	if #param > 256 then
		minetest.chat_send_player(pname, "# Server: Text is too long!")
		return
	end

	local pos = vector.round(user:get_pos())
	local dir = minetest.dir_to_facedir(user:get_look_dir())

	-- Cursor pos.
	local cx = 0
	local cz = 0

	-- Debug: Print image properties
	print("Image width: " .. ascii:width())
	print("Image height: " .. ascii:height())
	print("Number of bands: " .. ascii:bands())
	print("Band format: " .. ascii:format())
	print("Interpretation: " .. ascii:interpretation())

	local stride = ascii:bands()
	if stride ~= 3 then
		error("ASCII image stride is NOT RGB!")
	end

	-- Pixel positions.
	local textbitmap = {}

	local i = 1
	while i <= #param do
		local ch1 = param:sub(i, i)
		local ch2 = param:sub(i + 1, i + 1)

		if ch1 == "%" and (ch2 == 'n' or ch2 == 'N') then
			cx = 0
			cz = cz - gheight
			i = i + 1 -- Skip the sequence.
		else
			local b = string.byte(param, i)
			local sx = (b % 16) * gwidth
			local sz = floor(b / 16) * gheight

			for x = 0, gwidth - 1, 1 do -- Column
				for z = 0, gheight - 1, 1 do -- Row
					-- Calculate array index. 8-bit RGB format. Also flip the glyphs vertical.
					local idx = 3 * ((sz + z * -1 + gheight - 1) * 160 + (sx + x))
					local r = buffer[idx]

					if r >= 128 then
						textbitmap[#textbitmap + 1] = {
							x = pos.x + cx + x,
							z = pos.z + cz + z
						}
					end
				end
			end

			cx = cx + gwidth
		end

		-- Advance counter manually.
		i = i + 1
	end

	-- Apply rotation.
	rotate_bitmap(pos, textbitmap, dir)

	-- Compute voxel manipulator cuboid.
	local minp, maxp = cuboid_bounds(textbitmap)
	minp.y = pos.y - 50
	maxp.y = pos.y + 50

	-- Make sure the map is fully generated.
	local function callback(blockpos, action, calls_remaining, param)
		-- Check if there was an error.
		if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
			param.do_it = false
			return
		end

		-- We don't do anything until the last callback.
		if calls_remaining ~= 0 then
			return
		end

		if param.do_it then
			blit_text(pname, minp, maxp, textbitmap)
		end
	end
	minetest.emerge_area(minp, maxp, callback, {do_it=true})
end

if not serveressentials.ascii_registered then
	serveressentials.ascii_registered = true

	minetest.register_chatcommand("textblit", {
		params = "",
		description = "Write text into snow, with your position as the starting point.",
		privs = {server=true},

		func = function(...)
			return serveressentials.textblit(...)
		end
	})
end
