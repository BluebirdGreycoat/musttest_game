
recall = recall or {}
recall.modpath = minetest.get_modpath("recall")

-- Recalls are now constructed/managed by players.
-- See teleports mod and passport mod.

--[[
local function central(player)
	local pos = {x=0, y=-3, z=0}
	if player:get_pos().y < -25000 then
		pos.y = -30788
	end
	return pos
end

local function north(player)
	local pos = {x=0, y=-3, z=198}
	if player:get_pos().y < -25000 then
		pos.y = -30788
	end
	return pos
end

local function south(player)
	local pos = {x=0, y=-3, z=-198}
	if player:get_pos().y < -25000 then
		pos.y = -30788
	end
	return pos
end

local function east(player)
	local pos = {x=198, y=-3, z=0}
	if player:get_pos().y < -25000 then
		pos.y = -30788
	end
	return pos
end

local function west(player)
	local pos = {x=-198, y=-3, z=0}
	if player:get_pos().y < -25000 then
		pos.y = -30788
	end
	return pos
end



local recalls = {
	{name="Central Square", position=central,    	min_dist=20},
	{name="West Quarter",   position=west,    		min_dist=20},
	{name="East Quarter",   position=east,    		min_dist=20},
	{name="North Quarter",  position=north,  			min_dist=20},
	{name="South Quarter",  position=south, 			min_dist=20},
}
--]]

--[[
for k, v in pairs(recalls) do
    passport.register_recall(v)
end
--]]

