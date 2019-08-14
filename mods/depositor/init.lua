
depositor = depositor or {}
depositor.modpath = minetest.get_modpath("depositor")
depositor.datafile = minetest.get_worldpath() .. "/shops.txt"
depositor.shops = depositor.shops or {}



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
		if #data >= 3 then
			local x = tonumber(data[1])
			local y = tonumber(data[2])
			local z = tonumber(data[3])
			if x and y and z then
				table.insert(depositor.shops, {pos={x=x, y=y, z=z}})
			end
		end
	end
end



function depositor.save()
	-- Custom file format. minetest.serialize() is unusable for large tables.
	local datastring = ""
	for k, v in ipairs(depositor.shops) do
		datastring = datastring ..
			v.pos.x .. "," .. v.pos.y .. "," .. v.pos.z .. "\n"
	end
	local file, err = io.open(depositor.datafile, "w")
	if err then
		return
	end
	file:write(datastring)
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
	depositor.save()
end



-- Called for vending & delivery booths.
function depositor.on_construct(pos)
	pos = vector.round(pos)
	table.insert(depositor.shops, {pos={x=pos.x, y=pos.y, z=pos.z}})
	depositor.save()
end



-- Called for vending & delivery booths.
function depositor.on_destruct(pos)
	pos = vector.round(pos)
	for i, dep in ipairs(depositor.shops) do
		if vector.equals(dep.pos, pos) then
			table.remove(depositor.shops, i)
			depositor.save()
		end
	end
end



function depositor.update_info(pos, owner, itemname, cost, bsb)
end



if not depositor.run_once then
	depositor.load()

	local c = "depositor:core"
	local f = depositor.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	depositor.run_once = true
end
