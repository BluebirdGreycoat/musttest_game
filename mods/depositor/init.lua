
depositor = depositor or {}
depositor.modpath = minetest.get_modpath("depositor")
depositor.datafile = minetest.get_worldpath() .. "/shops.txt"
depositor.dropfile = minetest.get_worldpath() .. "/drops.txt"
depositor.shops = depositor.shops or {} -- Shop data. Indexed array format.
depositor.drops = depositor.drops or {} -- Dropsite data. Indexed by player name.
depositor.dirty = true



function depositor.set_drop_location(pos, pname)
	pos = vector.round(pos)
	depositor.drops[pname] = {
		pos = {x=pos.x, y=pos.y, z=pos.z},
	}
end



function depositor.unset_drop_location(pname)
	depositor.drops[pname] = nil
end



-- Return `pos` or nil.
function depositor.get_drop_location(pname)
	if depositor.drops[pname] then
		return depositor.drops[pname].pos
	end
end



-- Return error string in case of error, otherwise nil.
function depositor.execute_trade(vend_pos, user_name, vendor_name, user_drop, vendor_drop, item, number, cost, currency, type)
	local user = minetest.get_player_by_name(user_name)
	if not user or not user:is_player() then
		return "Invalid user!"
	end

	if type ~= 1 and type ~= 2 then
		return "Unknown vendor type!"
	end

	local meta = minetest.get_meta(user_drop)
	local inv = meta:get_inventory()
	if not inv then
		return "Could not obtain user inventory!"
	end

	local meta2 = minetest.get_meta(vendor_drop)
	local inv2 = meta2:get_inventory()
	if not inv2 then
		return "Could not obtain vendor inventory!"
	end

	if meta2:get_string("owner") ~= vendor_name or
		meta2:get_string("itemname") ~= item or
		meta2:get_string("machine_currency") ~= currency or
		meta2:get_int("number") ~= number or
		meta2:get_int("cost") ~= cost
	then
		return "Vendor information unexpectedly changed! Refusing to trade items."
	end

	easyvend.execute_trade(vend_pos, user, inv, "storage", inv2, "storage")

	local meta = minetest.get_meta(vend_pos)
	local status = meta:get_string("status")
	local msg = meta:get_string("message")

	if status ~= "" and msg ~= "" then
		return "Remote status: " .. status .. " Remote message: " .. msg
	else
		if status ~= "" then
			return "Remote status: " .. status
		end
		if msg ~= "" then
			return "Remote message: " .. msg
		end
	end
end



function depositor.load()
	-- Custom file format. minetest.serialize() is unusable for large tables.
	depositor.shops = {}
	local file, err = io.open(depositor.datafile, "r")
	if not file or err then
		return
	end
	local datastring = file:read("*all")
	if not datastring or datastring == "" then
		return
	end
	file:close()

	local records = string.split(datastring, "\n")
	for _, record in ipairs(records) do
		local data = string.split(record, ",")
		if #data >= 10 then
			local x = tonumber(data[1])
			local y = tonumber(data[2])
			local z = tonumber(data[3])
			local o = tostring(data[4])
			local i = tostring(data[5])
			local c = tonumber(data[6])
			local t = tonumber(data[7])
			local a = tonumber(data[8])
			local n = tonumber(data[9])
			local r = tostring(data[10])

			if a == 0 then
				a = false
			elseif a == 1 then
				a = true
			else
				a = false
			end

			if x and y and z and o and i and c and t and a and n and r then
				table.insert(depositor.shops, {pos={x=x, y=y, z=z}, owner=o, item=i, number=n, cost=c, currency=r, type=t, active=a})
			end
		end
	end

	depositor.drops = {}
	local file, err = io.open(depositor.dropfile, "r")
	if not file or err then
		return
	end
	local datastring = file:read("*all")
	if not datastring or datastring == "" then
		return
	end
	file:close()
	local drops = minetest.deserialize(datastring)
	if drops and type(drops) == "table" then
		depositor.drops = drops
	end
end



function depositor.save()
	-- Custom file format. minetest.serialize() is unusable for large tables.
	local datastring = ""
	for k, v in ipairs(depositor.shops) do
		if v.pos then
			local x = v.pos.x
			local y = v.pos.y
			local z = v.pos.z
			local t = v.type
			local o = v.owner
			local i = v.item
			local n = v.number
			local r = v.currency
			local c = v.cost
			local a = v.active

			if a then
				a = 1
			else
				a = 0
			end

			if x and y and z and t and o and i and c and a and r and n then
				-- x,y,z,owner,item,cost,type
				datastring = datastring ..
					x .. "," .. y .. "," .. z .. "," .. o .. "," .. i .. "," .. c .. "," .. t .. "," .. a .. "," .. n .. "," .. r .. "\n"
			end
		end
	end
	local file, err = io.open(depositor.datafile, "w")
	if err then
		return
	end
	file:write(datastring)
	file:close()

	local file, err = io.open(depositor.dropfile, "w")
	if err then
		return
	end
	local datastring = minetest.serialize(depositor.drops)
	if datastring then
		file:write(datastring)
	end
	file:close()
end



-- Called for vending & delivery booths.
function depositor.check_machine(pos)
	pos = vector.round(pos)
	for i, dep in ipairs(depositor.shops) do
		if vector.equals(dep.pos, pos) then
			return
		end
	end
	table.insert(depositor.shops, {pos={x=pos.x, y=pos.y, z=pos.z}})
	depositor.dirty = true
	--depositor.save()
end



-- Called for vending & delivery booths.
function depositor.on_construct(pos)
	pos = vector.round(pos)
	table.insert(depositor.shops, {pos={x=pos.x, y=pos.y, z=pos.z}})
	depositor.dirty = true
	--depositor.save()
end



-- Called for vending & delivery booths.
function depositor.on_destruct(pos)
	pos = vector.round(pos)
	for i, dep in ipairs(depositor.shops) do
		if vector.equals(dep.pos, pos) then
			table.remove(depositor.shops, i)
			depositor.dirty = true
			--depositor.save()
		end
	end
end



function depositor.update_info(pos, owner, itemname, number, cost, currency, bsb, active)
	pos = vector.round(pos)
	local needsave = false

	for k, dep in ipairs(depositor.shops) do
		if vector.equals(dep.pos, pos) then
			dep.owner = owner or "server"
			dep.item = itemname or "none"
			dep.cost = cost or 0
			dep.number = number or 0
			dep.currency = currency or "none"
			dep.active = active

			dep.type = 0
			if bsb == "sell" then
				dep.type = 1
			elseif bsb == "buy" then
				dep.type = 2
			elseif bsb == "info" then
				dep.type = 3
			end

			needsave = true
			break
		end
	end

	if needsave then
		depositor.dirty = true
	end
end



function depositor.on_mapsave()
	if depositor.dirty then
		depositor.save()
	end
	depositor.dirty = false
end



if not depositor.run_once then
	depositor.load()

	minetest.register_on_shutdown(function() depositor.on_mapsave() end)
	minetest.register_on_mapsave(function() depositor.on_mapsave() end)

	local c = "depositor:core"
	local f = depositor.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	depositor.run_once = true
end
