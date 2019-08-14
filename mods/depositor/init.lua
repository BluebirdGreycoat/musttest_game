
depositor = depositor or {}
depositor.modpath = minetest.get_modpath("depositor")
depositor.datafile = minetest.get_worldpath() .. "/shops.txt"
depositor.shops = depositor.shops or {}



function depositor.load()
	local file, err = io.open(depositor.datafile, "r")
	if err then
		depositor.shops = {}
		return
	end
	depositor.shops = minetest.deserialize(file:read("*all"))
	if type(depositor.shops) ~= "table" then
		depositor.shops = {}
	end
	file:close()
end



function depositor.save()
	local datastring = xban.serialize(depositor.shops)
	if not datastring then
		return
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



if not depositor.run_once then
	depositor.load()

	local c = "depositor:core"
	local f = depositor.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	depositor.run_once = true
end
