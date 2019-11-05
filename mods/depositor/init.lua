
depositor = depositor or {}
depositor.modpath = minetest.get_modpath("depositor")
depositor.datafile = minetest.get_worldpath() .. "/shops.txt"
depositor.dropfile = minetest.get_worldpath() .. "/drops.txt"
depositor.shops = depositor.shops or {} -- Shop data. Indexed array format.
depositor.drops = depositor.drops or {} -- Dropsite data. Indexed by player name.
depositor.dirty = true



function depositor.get_random_vending_or_depositing_machine()
	local data
	if #depositor.shops > 0 then
		local shops = {}
		for k, v in ipairs(depositor.shops) do
			if (v.type == 2 or v.type == 1) and v.active then
				table.insert(shops, v)
			end
		end

		if #shops > 0 then
			local v = shops[math.random(1, #shops)]
			data = table.copy(v) -- Copy the data so it cannot be modified.
		end
	end
	return data
end

-- Get random depositor shop data or nil.
function depositor.get_random_depositing_machine()
	local data
	if #depositor.shops > 0 then
		local shops = {}
		for k, v in ipairs(depositor.shops) do
			if v.type == 2 and v.active then -- Is depositing machine.
				table.insert(shops, v)
			end
		end

		if #shops > 0 then
			local v = shops[math.random(1, #shops)]
			data = table.copy(v) -- Copy the data so it cannot be modified.
		end
	end
	return data
end

function depositor.get_random_vending_machine()
	local data
	if #depositor.shops > 0 then
		local shops = {}
		for k, v in ipairs(depositor.shops) do
			if v.type == 1 and v.active then -- Is vending machine.
				table.insert(shops, v)
			end
		end

		if #shops > 0 then
			local v = shops[math.random(1, #shops)]
			data = table.copy(v) -- Copy the data so it cannot be modified.
		end
	end
	return data
end

-- Returns data for a depositor offering the highest bid for an item, or nil.
-- Will exclude depositors demanding more than the maximum.
function depositor.get_random_depositor_buying_item(item, maximum)
	local data
	if #depositor.shops > 0 then
		local shops = {}
		for k, v in ipairs(depositor.shops) do
			if v.type == 2 and v.active then -- Is ative depositing machine.
				-- Only if depositor is buying item of not more than given max.
				if v.item == item and v.number <= maximum and v.number >= 1 then
					table.insert(shops, v)
				end
			end
		end

		if #shops > 0 then
			-- Sort shops, highest bid first.
			table.sort(shops,
				function(a, b)
					local v1 = currency.get_stack_value(a.currency, a.cost)
					local v2 = currency.get_stack_value(b.currency, b.cost)
					if v1 > v2 then
						return true
					end
				end)

			-- If multiple shops have the same highest bid value,
			-- then get a random shop from these that are bidding highest.
			local last = 0
			local highest_bid = shops[1].cost
			for k, v in ipairs(shops) do
				if v.cost >= highest_bid then
					last = last + 1
				end
			end

			local v = shops[math.random(1, last)]
			data = table.copy(v) -- Copy the data so it cannot be modified.
		end
	end
	return data
end

-- Returns data for a vendor offering the lowest price for an item, or nil.
-- Will exclude vendors selling less than the minimum.
function depositor.get_random_vendor_selling_item(item, minimum)
	local data
	if #depositor.shops > 0 then
		local shops = {}
		for k, v in ipairs(depositor.shops) do
			if v.type == 1 and v.active then -- Is ative vending machine.
				-- Only if vendor is selling item of at least this minimum amount.
				if v.item == item and v.number >= minimum and v.number >= 1 then
					table.insert(shops, v)
				end
			end
		end

		if #shops > 0 then
			-- Sort shops, lowest price first.
			table.sort(shops,
				function(a, b)
					local v1 = currency.get_stack_value(a.currency, a.cost)
					local v2 = currency.get_stack_value(b.currency, b.cost)
					if v1 < v2 then
						return true
					end
				end)

			-- If multiple shops have the same lowest price value,
			-- then get a random shop from these that are priced the lowest.
			local last = 0
			local lowest_price = shops[1].cost
			for k, v in ipairs(shops) do
				if v.cost >= lowest_price then
					last = last + 1
				end
			end

			local v = shops[math.random(1, last)]
			data = table.copy(v) -- Copy the data so it cannot be modified.
		end
	end
	return data
end



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
function depositor.execute_trade(vend_pos, user_name, vendor_name, user_drop, vendor_drop, item, number, cost, tax, currency, type)
	local user = minetest.get_player_by_name(user_name)
	if not user or not user:is_player() then
		return "Invalid user!"
	end

	if type ~= 1 and type ~= 2 then
		return "Unknown vendor type!"
	end

	-- Do not allow player to trade with themselves.
	if vector.equals(user_drop, vendor_drop) or vendor_name == user_name then
		return "Vending and user drop-points cannot be the same (are you trying to trade with yourself?)!"
	end

	-- Security checks and vending use requires map access.
	utility.ensure_map_loaded(vector.add(user_drop, {x=-7, y=-7, z=-7}), vector.add(user_drop, {x=7, y=7, z=7}))
	utility.ensure_map_loaded(vector.add(vendor_drop, {x=-7, y=-7, z=-7}), vector.add(vendor_drop, {x=7, y=7, z=7}))

	if minetest.get_node(user_drop).name ~= "market:booth" or
		minetest.get_node(vendor_drop).name ~= "market:booth"
	then
		return "Error: 0xDEADBEEF 9020 (Please report)."
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

	local meta3 = minetest.get_meta(vend_pos)
	if meta3:get_string("owner") ~= vendor_name or
		meta3:get_string("itemname") ~= item or
		meta3:get_string("machine_currency") ~= currency or
		meta3:get_int("number") ~= number or
		meta3:get_int("cost") ~= cost
	then
		return "Vendor information unexpectedly changed! Refusing to trade items."
	end

	-- The trade function requires map access!
	utility.ensure_map_loaded(vector.add(vend_pos, {x=-7, y=-7, z=-7}), vector.add(vend_pos, {x=7, y=7, z=7}))
	easyvend.execute_trade(vend_pos, user, inv, "storage", inv2, "storage", tax)

	local status = meta3:get_string("status")
	local msg = meta3:get_string("message")

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
	if err then
		minetest.log("error", "Failed to open " .. depositor.datafile .. " for reading: " .. err)
	else
		local datastring = file:read("*all")
		if datastring and datastring ~= "" then
			local records = string.split(datastring, "\n")
			for record_number, record in ipairs(records) do
				local data = string.split(record, ",")
				if type(data) == "table" and #data >= 10 then
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

					if x and y and z and o and i and c and t and a and n and r then
						local act = false
						if a == 0 then
							act = false
						elseif a == 1 then
							act = true
						end

						table.insert(depositor.shops, {pos={x=x, y=y, z=z}, owner=o, item=i, number=n, cost=c, currency=r, type=t, active=act})
					else
						minetest.log("error", "Could not deserialize record #" .. record_number .. " from shops.txt! Data: " .. record)
					end
				else
					minetest.log("error", "Could not load record #" .. record_number .. " from shops.txt! Data: " .. record)
				end
			end
		end
		file:close()
	end

	depositor.drops = {}
	local file, err = io.open(depositor.dropfile, "r")
	if err then
		minetest.log("error", "Failed to open " .. depositor.dropfile .. " for reading: " .. err)
	else
		local datastring = file:read("*all")
		if datastring and datastring ~= "" then
			local drops = minetest.deserialize(datastring)
			if drops and type(drops) == "table" then
				depositor.drops = drops
			end
		end
		file:close()
	end

	depositor.dirty = false
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
				-- x,y,z,owner,item,cost,type,active,number,currency
				datastring = datastring ..
					x .. "," .. y .. "," .. z .. "," .. o .. "," .. i .. "," .. c .. "," .. t .. "," .. a .. "," .. n .. "," .. r .. "\n"
			end
		end
	end
	local file, err = io.open(depositor.datafile, "w")
	if err then
		minetest.log("error", "Failed to open " .. depositor.datafile .. " for writing: " .. err)
	else
		file:write(datastring)
		file:close()
	end

	local file, err = io.open(depositor.dropfile, "w")
	if err then
		minetest.log("error", "Failed to open " .. depositor.dropfile .. " for writing: " .. err)
	else
		local datastring = minetest.serialize(depositor.drops)
		if datastring then
			file:write(datastring)
		end
		file:close()
	end
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
end



-- Called for vending & delivery booths.
function depositor.on_destruct(pos)
	pos = vector.round(pos)
	for i=1, #(depositor.shops), 1 do
		local dep = depositor.shops[i]
		if vector.equals(dep.pos, pos) then
			-- If this was the active drop point, then we must remove it.
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")

			if depositor.drops[owner] then
				if vector.equals(depositor.drops[owner].pos, pos) then
					depositor.drops[owner] = nil
				end
			end

			table.remove(depositor.shops, i)
			depositor.dirty = true
			return
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
