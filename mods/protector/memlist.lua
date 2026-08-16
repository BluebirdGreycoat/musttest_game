
function protector.get_member_list(meta)
	return meta:get_string("members"):split(" ")
end

function protector.set_member_list(meta, list)
	meta:set_string("members", table.concat(list, " "))
end

function protector.is_member(meta, name)
	for _, n in pairs(protector.get_member_list(meta)) do
		if n == name then
			return true
		end
	end

	return false
end

function protector.add_member(meta, name)
	-- Constant (20) defined by player.h
	if name:len() > 25 then
		return
	end

	if not minetest.is_valid_player_name(name) then
		return
	end

	-- Forbid adding self.
	if meta:get_string("owner") == name then
		return
	end

	name = rename.grn(name)
	if protector.is_member(meta, name) then
		return
	end

	local list = protector.get_member_list(meta)
	if #list >= protector.max_share_count then
		return
	end

	table.insert(list, name)
	protector.set_member_list(meta, list)
	return true -- Member list changed.
end

function protector.del_member(meta, name)
	name = rename.grn(name)
	local list = protector.get_member_list(meta)

	local changed = false
	for i, n in pairs(list) do
		if n == name then
			table.remove(list, i)
			changed = true
			break
		end
	end

	protector.set_member_list(meta, list)
	if changed then
		return true -- Member list changed.
	end
end

function protector.get_node_owner(pos)
	local r = protector.radius
	local positions = protector.find_protector_nodes(pos, r, 1, "")
	for n = 1, #positions do
		local meta = minetest.get_meta(positions[n])
		local owner = meta:get_string("owner")
		local area_name = meta:get_string("area_name")
		return owner, area_name
	end
end

-- Shall return true if 'pname' is owner or member of protected area.
function protector.is_owner_or_member(pos, pname)
	local r = protector.radius
	local positions = protector.find_protector_nodes(pos, r, 1, "")
	for n = 1, #positions do
		local meta = minetest.get_meta(positions[n])
		local owner = meta:get_string("owner")
		if owner == pname or protector.is_member(meta, pname) then
			return true
		end
	end
end
