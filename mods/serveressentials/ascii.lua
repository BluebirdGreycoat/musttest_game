
-- My Little Pony is a Racist, Colonialist Monarchy.
-- Cool stuff!
-- https://www.youtube.com/watch?v=QV7SHnKSgs0

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

-- Colors.
local cblack = "cavestuff:dark_obsidian"
local cwhite = "default:snow"

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

local function place_node_floor(pos)
	pos = vector.new(pos)
	pos.y = pos.y + 90
	local starty = pos.y
	local nn = minetest.get_node(pos)
	local fail = false
	while not fail and nn.name == "air" do
		pos.y = pos.y - 1
		nn = minetest.get_node(pos)
		if pos.y < starty - 180 then
			fail = true
			break
		end
	end
	-- Only replace snow.
	if not fail and nn.name == cwhite then
		minetest.set_node(pos, {name=cblack})
	end
end

function serveressentials.textblit(pname, param)
	local user = minetest.get_player_by_name(pname)
	if not user or not user:is_player() then return end

	param = param:trim()
	if #param == 0 then
		minetest.chat_send_player(pname, "# Server: Nothing to blit.")
		return
	end

	local pos = vector.round(user:get_pos())
	local target = vector.new(pos)

	-- Cursor pos.
	local cx = 0
	local cz = 0

	-- Pixel positions.
	local textbitmap = {}

	local i = 1
	while i <= #param do
		local b = string.byte(param, i)

		local sx = (b % 16) * gwidth
		local sz = floor(b / 16) * gheight

		for x = 0, gwidth - 1, 1 do -- Column
			for z = 0, gheight - 1, 1 do -- Row
				-- Calculate array index. 8-bit RGBA format. Also flip the glyphs vertical.
				local idx = 4 * ((sz + z * -1 + gheight - 1) * 160 + (sx + x))
				local r = buffer[idx]
				local a = buffer[idx + 3]

				if a >= 255 and r >= 128 then
					textbitmap[#textbitmap + 1] = {
						x = pos.x + cx + x,
						z = pos.z + cz + z
					}
				end
			end
		end

		cx = cx + gwidth

		local ch1 = param:sub(i, i)
		local ch2 = param:sub(i + 1, i + 1)
		if ch2 == " " and (ch1 == '.' or ch1 == ',' or ch1 == "!" or ch1 == "?" or ch1 == ":") then
			cx = 0
			cz = cz - gheight
			i = i + 1 -- Skip the space.
		end

		-- Advance counter manually.
		i = i + 1
	end

	local function do_it()
		local user = minetest.get_player_by_name(pname)
		if not user or not user:is_player() then
			return
		end

		local dir = minetest.dir_to_facedir(user:get_look_dir())
		rotate_bitmap(pos, textbitmap, dir)

		for i = 1, #textbitmap, 1 do
			target.x = textbitmap[i].x
			target.z = textbitmap[i].z
			target.y = pos.y
			place_node_floor(target)
		end

		minetest.chat_send_player(pname, "# Server: Text blit done.")
	end

	local function callback(blockpos, action, calls_remaining, param)
		if calls_remaining == 0 then
			do_it()
		end
	end

	local minp, maxp = cuboid_bounds(textbitmap)
	minp.y = pos.y - 100
	maxp.y = pos.y + 100
	minetest.emerge_area(minp, maxp, callback)
end

if not serveressentials.ascii_registered then
	serveressentials.ascii_registered = true

	minetest.register_chatcommand("textblit", {
		privs = {server=true},

		func = function(...)
			return serveressentials.textblit(...)
		end
	})
end
