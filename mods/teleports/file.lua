


teleports.save = function()
	local datastring = xban.serialize(teleports.teleports)
	if not datastring then
		return
	end

	minetest.safe_file_write(teleports.datafile, datastring)

	--[[
	local file, err = io.open(teleports.datafile, "w")
	if err then
			return
	end
	file:write(datastring)
	file:close()
	--]]
end



teleports.load = function()
	local file, err = io.open(teleports.datafile, "r")
	if err then
		teleports.teleports = {}
		return
	end
	teleports.teleports = minetest.deserialize(file:read("*all"))
	if type(teleports.teleports) ~= "table" then
		teleports.teleports = {}
	end
	file:close()
end
