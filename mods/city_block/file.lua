
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME
local time_active = city_block.time_active



function city_block:save()
	local datastring = minetest.serialize(self.blocks)
	if not datastring then
		return
	end

	minetest.safe_file_write(self.filename, datastring)

	--[[
	local file, err = io.open(self.filename, "w")
	if err then
		return
	end
	file:write(datastring)
	file:close()
	--]]
end



function city_block:load()
	local file, err = io.open(self.filename, "r")
	if err then
		self.blocks = {}
		return
	end
	self.blocks = minetest.deserialize(file:read("*all"))
	if type(self.blocks) ~= "table" then
		self.blocks = {}
	end
	file:close()
end
