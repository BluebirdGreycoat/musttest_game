
if not minetest.global_exists("torches") then torches = {} end
torches.modpath = minetest.get_modpath("torches")



function torches.node_supports_torch(name, def)
	if name == "protector:protect" or name == "protector:protect3" then
		return true
	end
	local dt = def.drawtype
	if dt == "normal" or dt == "glasslike" or dt == "glasslike_framed" or
		dt == "glasslike_framed_optional" or dt == "allfaces" or
		dt == "allfaces_optional" then
		return true
	elseif minetest.get_item_group(name, "tree") ~= 0 then
		return true
	elseif string.find(name, "^maptools:") then
		return true
	end
	return false
end



function torches.put_torch(itemstack, placer, pt, only_wall)
	local under = pt.under
	local above = pt.above
	local node = minetest.get_node(under)
	local ndef = minetest.reg_ns_nodes[node.name]

	-- Call on_rightclick if target node defines it.
	if ndef and ndef.on_rightclick and
		((not placer) or (placer and not placer:get_player_control().sneak)) then
		return ndef.on_rightclick(under, node, placer, itemstack, pt) or itemstack
	end

	local def = minetest.reg_ns_nodes[itemstack:get_name()]
	local good = false
	if def then
		if def._torches_node_ceiling and def._torches_node_floor and def._torches_node_wall then
			good = true
		end
	end
	if not good then
		return itemstack
	end

	-- If node under is buildable_to, place into it instead (eg. snow)
	local place_to = above
	if ndef and ndef.buildable_to then
		place_to = under
	end
	local place_in_non_air = (minetest.get_node(place_to).name ~= "air")
	local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))

	if only_wall then
		if wdir == 0 or wdir == 1 then
			return itemstack
		end
	end

	local fakestack = itemstack
	local torch
	if wdir == 0 then
		torch = def._torches_node_ceiling
	elseif wdir == 1 then
		torch = def._torches_node_floor
	else
		torch = def._torches_node_wall
	end
	fakestack:set_name(torch)

	itemstack = minetest.item_place_node(fakestack, placer, pt, wdir)
	itemstack:set_name(def._torches_node_floor)
	return itemstack
end



function torches.on_use(itemstack, user, pointed_thing)
	if not user or not user:is_player() then return end
	if pointed_thing.type ~= "node" then return end

	local torchtype = nil
	local ndef = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
	if not ndef or not ndef.drop then return end
	if type(ndef.drop) == "string" then torchtype = ndef.drop end
	if not torchtype then return end

	local fakestack = ItemStack("dusts:coal")
	fakestack = real_torch.relight(fakestack, user, pointed_thing)
	if not fakestack or fakestack:get_count() ~= 0 then return end

	-- Add unlit torch to player's inventory OUTSIDE this function's stack frame.
	local pname = user:get_player_name()
	local pos = pointed_thing.under

	minetest.after(0, function()
		local user = minetest.get_player_by_name(pname)
		if not user then return end
		local inv = user:get_inventory()
		local leftover = inv:add_item("main", ItemStack(torchtype))
		if not leftover:is_empty() then minetest.add_item(pos, leftover) end
	end)

	itemstack:take_item()
	return itemstack
end



if not torches.run_once then
	dofile(torches.modpath .. "/iron_torch.lua")
	dofile(torches.modpath .. "/cave_torch.lua")
	dofile(torches.modpath .. "/kalite_torch.lua")

	local c = "torches:core"
	local f = torches.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	torches.run_once = true
end

