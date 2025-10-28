
fortress.v2.FORTINFO_FILE = minetest.get_worldpath() .. "/fortinfo.v2.txt"
fortress.v2.FORTRESS_INFO = fortress.v2.FORTRESS_INFO or {} -- Don't clobber.



function fortress.v2.save_fort_information()
	local datastring = xban.serialize(fortress.v2.FORTRESS_INFO)
	if not datastring then
		return
	end

	minetest.safe_file_write(fortress.v2.FORTINFO_FILE, datastring)
end



function fortress.v2.load_fort_information()
	local file, err = io.open(fortress.v2.FORTINFO_FILE, "r")

	if not file or err then
		fortress.v2.FORTRESS_INFO = {}
		return
	end

	fortress.v2.FORTRESS_INFO = minetest.deserialize(file:read("*all"))
	file:close()

	if type(fortress.v2.FORTRESS_INFO) ~= "table" then
		fortress.v2.FORTRESS_INFO = {}
	end
end



function fortress.v2.add_new_fort_entry(info)
	if not info or not type(info) == "table" then return end
	if not info.pos or not info.minp or not info.maxp then return end

	local copy = table.copy(info) -- Should be a deep copy per docs.
	copy.time = os.time() -- Timestamp it.

	local t = fortress.v2.FORTRESS_INFO
	t[#t + 1] = copy
end



function fortress.v2.get_fortinfo_at_pos(pos)
	local i = {}

	for _, info in ipairs(fortress.v2.FORTRESS_INFO) do
		local minp = info.minp
		local maxp = info.maxp

		-- Minimum critical parameters.
		if not minp or not maxp or not info.pos then goto skip end

		if pos.x >= minp.x and pos.x <= maxp.x
				and pos.y >= minp.y and pos.y <= maxp.y
					and pos.z >= minp.z and pos.z <= maxp.z then
			i[#i + 1] = table.copy(info) -- Should be deep copy per docs.
		end

		::skip::
	end

	return i
end



function fortress.v2.confirm_fort_entry(pos)
	for k, v in ipairs(fortress.v2.FORTRESS_INFO) do
		if vector.equals(v.pos, pos) then
			v.spawned = true
			break
		end
	end
end
