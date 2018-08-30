
local callbacks = {}
local interval = tonumber(minetest.settings:get("server_map_save_interval"))
assert(type(interval) == "number" and interval >= 0)

assert(type(minetest.register_on_mapsave) == "nil")
function minetest.register_on_mapsave(func)
	callbacks[#callbacks+1] = func
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer >= interval then
		timer = 0
		local c = #callbacks
		for i = 1, c, 1 do
			local f = callbacks[i]
			f()
		end
	end
end)
