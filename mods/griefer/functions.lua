
--[[
function griefer.get_griefer_count(pos)
	local ents = minetest.get_objects_inside_radius(pos, 10)
	local count = 0
	for k, v in ipairs(ents) do
		if not v:is_player() then
			local tb = v:get_luaentity()
			if tb and tb.mob then
				if tb.name and tb.name == "griefer:griefer" then
					-- Found monster in radius.
					count = count + 1
				end
			end
		end
	end
	return count
end



function griefer.on_stone_construct(pos)
	minetest.get_node_timer(pos):start(math.random(10, 60)
end



function griefer.on_stone_timer(pos, elapsed)
	minetest.get_node_timer(pos):start(math.random(10, 60)
end
--]]



if not griefer.run_functions_once then
	local c = "griefer:functions"
	local f = griefer.modpath .. "/functions.lua"
	reload.register_file(c, f, false)

	griefer.run_functions_once = true
end
