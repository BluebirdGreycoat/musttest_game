
schematic_find = schematic_find or {}
schematic_find.modpath = minetest.get_modpath("schematic_find")

-- Test data.
local o = "default:obsidian"
local a = "air"

local ts = {
	data = {
		{p={x=0, y=0, z=0}, n=o},
		{p={x=1, y=0, z=0}, n=o},
		{p={x=2, y=0, z=0}, n=o},
		{p={x=3, y=0, z=0}, n=o},
		{p={x=0, y=1, z=0}, n=o},
		{p={x=0, y=2, z=0}, n=o},
		{p={x=0, y=3, z=0}, n=o},
		{p={x=0, y=4, z=0}, n=o},
		{p={x=1, y=4, z=0}, n=o},
		{p={x=2, y=4, z=0}, n=o},
		{p={x=3, y=4, z=0}, n=o},
		{p={x=3, y=1, z=0}, n=o},
		{p={x=3, y=2, z=0}, n=o},
		{p={x=3, y=3, z=0}, n=o},
		{p={x=1, y=1, z=0}, n=a},
		{p={x=2, y=1, z=0}, n=a},
		{p={x=1, y=2, z=0}, n=a},
		{p={x=2, y=2, z=0}, n=a},
		{p={x=1, y=3, z=0}, n=a},
		{p={x=2, y=3, z=0}, n=a},
	},
	minp = {x=0, y=0, z=0},
	maxp = {x=3, y=4, z=0},
}

local os = {x=-2, y=-4, z=100}
for k, v in ipairs(ts.data) do
	v.p = vector.add(v.p, os)
end
ts.minp = vector.add(ts.minp, os)
ts.maxp = vector.add(ts.maxp, os)



-- API function.
-- Returns boolean success, table of schematic positions,
-- table of node counts, and schematic origin.
function schematic_find.detect_schematic(pos, schematic)
	local data = schematic.data
	local minp = schematic.minp
	local maxp = schematic.maxp

	local w = {x=0, y=0, z=0}
	local getn = minetest.get_node

	-- The extents of the schematic, min and max positions.
	for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			for z = minp.z, maxp.z do
				local total = 0
				local positions = {}
				local counts = {}

				-- For each point defined in the schematic.
				for i = 1, #data do
					-- Point in model space.
					local p = data[i].p

					-- Adjust point relative to current position in schematic.
					w.x = p.x - x
					w.y = p.y - y
					w.z = p.z - z

					-- Convert to world-space coordinates.
					w.x = w.x + pos.x
					w.y = w.y + pos.y
					w.z = w.z + pos.z

					local n = data[i].n
					local nn = getn(w).name
					local yes = false

					if type(n) == "string" and nn == n then
						yes = true
					elseif type(n) == "table" then
						for j = 1, #n do
							if n[j] == nn then
								yes = true
								break
							end
						end
					elseif type(n) == "function" then
						if n(nn) then
							yes = true
						end
					end

					if yes then
						total = total + 1
						positions[#positions+1] = {x=w.x, y=w.y, z=w.z}
						local c = counts[nn] or 0
						c = c + 1
						counts[nn] = c
						goto nextpoint
					end
					goto nextextent
					::nextpoint::
				end

				if total == #data then
					-- We have found the structure.
					local origin = {x=pos.x-x+minp.x, y=pos.y-y+minp.y, z=pos.z-z+minp.z}
					return true, positions, counts, origin
				end
				::nextextent::
			end
		end
	end
end



function schematic_find.test_tool_on_use(itemstack, user, pointed_thing)
	if not user or not user:is_player() then
		return
	end
	if pointed_thing.type ~= "node" then
		return
	end
	local pname = user:get_player_name()
	local under = pointed_thing.under
	minetest.chat_send_player(pname, "# Server: Searching!")
	local result, points, counts, origin = schematic_find.detect_schematic(under, ts)
	if result then
		minetest.chat_send_player(pname, "# Server: Found test schematic!")
		local getn = minetest.get_node
		local setn = minetest.set_node
		local dk = {name="cavestuff:dark_obsidian"}
		--for i = 1, #points do
		--	if getn(points[i]).name == "default:obsidian" then
		--		setn(points[i], dk)
		--	end
		--end
		for k, v in pairs(counts) do
			minetest.chat_send_player(pname, "# Server: Found " .. v .. " '" .. k .. "'!")
		end
		minetest.chat_send_player(pname, "# Server: Origin @ " .. rc.pos_to_namestr(origin) .. "!")
	end
end



if not schematic_find.run_once then
	minetest.register_tool("schematic_find:test_tool", {
		description = "Schematic Search Test Tool",
		inventory_image = "default_tool_steelaxe.png",
		on_use = function(...)
			return schematic_find.test_tool_on_use(...)
		end,
	})

	local c = "schematic_find:core"
	local f = schematic_find.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	schematic_find.run_once = true
end
