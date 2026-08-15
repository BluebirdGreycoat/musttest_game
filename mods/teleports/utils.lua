
-- Admin API function, refills ALL teleports with fuel (if fuel is empty).
function teleports.refill_all()
	local tps = teleports.teleports

	for k, v in ipairs(tps) do
		local meta = minetest.get_meta(v.pos)
		if meta then
			local inv = meta:get_inventory()
			if inv then
				if inv:is_empty("price") then
					inv:set_stack("price", 1, ItemStack("flowers:waterlily 64"))
				else
					local stack = inv:get_stack("price", 1)
					if stack:get_name() == "default:mossycobble" then
						stack:set_count(64)
						inv:set_stack("price", 1, stack)
					elseif stack:get_name() == "flowers:waterlily" then
						stack:set_count(64)
						inv:set_stack("price", 1, stack)
					elseif stack:get_name() == "default:mese_crystal_fragment" then
						stack:set_count(64)
						inv:set_stack("price", 1, stack)
					end
				end
			end
		end
	end
end
