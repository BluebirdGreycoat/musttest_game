
local function get_player_pos(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		local pos = pref:get_pos()
		local yaw = pref:get_look_horizontal()
		local pitch = pref:get_look_vertical()
		return pos, yaw, pitch
	end
end

local function get_nearest_cityblock(pos)
	pos = vector.round(pos)
	local D = camc.VANTAGE_CITYBLOCK_DIST
	local blocks = city_block:nearest_blocks_to_position(pos, 1, D)
	if #blocks == 1 then
		return blocks[1]
	end
end

local function name_ok(pname, title)
	if anticurse.check(pname, title, "foul") then
		return
	elseif anticurse.check(pname, title, "curse") then
		return
	end
	return true
end

-- Vantage name may be nil.
function camc.add_vantage_point(pname, vantage_name)
	local pos, yaw, pitch = get_player_pos(pname)
	if not pos then
		return false, "Can't get your position."
	end
	if vantage_name and vantage_name ~= "" then
		if not name_ok(vantage_name) then
			return false, "No swearing in vantage names!"
		end
	end
	local block = get_nearest_cityblock(pos)
	local overwrite = ""
	if block.vantage then
		overwrite = " Existing vantage replaced."
	end
	block.vantage = {
		pos = pos,
		yaw = yaw,
		pitch = pitch,
		name = vantage_name,
		creator = pname,
		time = os.time(),
	}
	city_block:save()
	return true, "Vantage point added." .. overwrite
end

function camc.remove_vantage_point(pname)
	local pos = get_player_pos(pname)
	if not pos then
		return false, "Can't get your position."
	end
	local block = get_nearest_cityblock(pos)
	if block.vantage then
		block.vantage = nil
		city_block:save()
		return true, "Vantage point removed."
	end
	return false, "No vantage point. Nothing to be done."
end
