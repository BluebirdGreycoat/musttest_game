
scaffolding = scaffolding or {}



function scaffolding.wrench_on_use(itemstack, user, pt)
	if pt.type ~= "node" then
		return
	end
	local pname = user:get_player_name()
	local pos = pt.under
	local node = minetest.get_node(pos)
	if string.find(node.name, "^scaffolding:") then
		local def = minetest.registered_items[node.name]
		if def and def.on_punch then
			return def.on_punch(pos, node, user)
		end
		return
	end
	if minetest.get_item_group(node.name, "chest") ~= 0 then
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:get_size("main") > 0 then
			scaffolding.sort_inventory(pname, pos, inv)
		end
	end
end



function scaffolding.sort_inventory(pname, pos, inv)
	if minetest.test_protection(pos, pname) then
		minetest.chat_send_player(pname, "# Server: Cannot sort protected chest!")
		return
	end

	local inlist = inv:get_list("main")
	local typecnt = {}
	local typekeys = {}

	for _, st in ipairs(inlist) do
		if not st:is_empty() then
			local n = st:get_name()
			local k = string.format("%s", n)
			if not typecnt[k] then
				typecnt[k] = {st}
				table.insert(typekeys, k)
			else
				table.insert(typecnt[k], st)
			end
		end
	end

	table.sort(typekeys)
	inv:set_list("main", {})
	for _, k in ipairs(typekeys) do
		for _, item in ipairs(typecnt[k]) do
			inv:add_item("main", item)
		end
	end

	minetest.chat_send_player(pname, "# Server: Successfully sorted chest at " .. rc.pos_to_namestr(pos) .. "!")
end
