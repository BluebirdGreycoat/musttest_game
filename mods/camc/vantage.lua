
local function get_player_pos(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref then
		return pref:get_pos()
	end
end

function camc.add_vantage_point(pname, vantage_name)
	local pos = get_player_pos(pname)
	if not pos then
		return
	end
end

function camc.remove_vantage_point(pname)
	local pos = get_player_pos(pname)
	if not pos then
		return
	end
end
