
plastic = plastic or {}
plastic.modpath = minetest.get_modpath("plastic")

-- Important: the ability to oil door/chest hinges does NOT require protection access.
function plastic.oil_extract_on_use(itemstack, user, pt)
	if not user or not user:is_player() then
		return
	end

	if pt.type ~= "node" then
		return
	end

	local under = pt.under
	local node = minetest.get_node(under)
	local ndef = minetest.registered_nodes[node.name]
	if not ndef then
		return
	end

	local groups = ndef.groups or {}
	local success = false

	local oil_hinge = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("oiled_hinge", 1)
		meta:set_int("oiled_time", os.time())
		meta:mark_as_private({"oiled_hinge", "oiled_time"})
	end

	-- Check for `groups.door` or `groups.trapdoor`.
	if (groups.door and groups.door > 0) or (groups.trapdoor and groups.trapdoor > 0) then
		local pname = user:get_player_name()

		oil_hinge(under)

		minetest.chat_send_player(pname, "# Server: Door hinges at " .. rc.pos_to_namestr(under) .. " have been oiled.")
		success = true
	elseif (groups.chest_node and groups.chest_node > 0) then
		local pname = user:get_player_name()

		oil_hinge(under)

		minetest.chat_send_player(pname, "# Server: Chest hinges at " .. rc.pos_to_namestr(under) .. " have been oiled.")
		success = true
	end

	if success then
		itemstack:take_item()
		return itemstack
	end
end

if not plastic.registered then
	minetest.register_craftitem("plastic:oil_extract", {
		description = "Oil Extract",
		inventory_image = "homedecor_oil_extract.png",

		on_use = function(...)
			return plastic.oil_extract_on_use(...)
		end,
	})

	minetest.register_craftitem("plastic:raw_paraffin", {
		description = "Unprocessed Paraffin",
		inventory_image = "homedecor_paraffin.png",
	})

	minetest.register_craftitem("plastic:plastic_sheeting", {
		description = "Plastic Sheet",
		inventory_image = "homedecor_plastic_sheeting.png",
	})

	minetest.register_craft({
		type = "compressing",
		output = "plastic:oil_extract 2",
		recipe = "group:leaves 6",
		time = 6,
	})

	--[[
	minetest.register_craft({
		type = "shapeless",
		output = "plastic:oil_extract 4",
		recipe = {
			"group:leaves",
			"group:leaves",
			"group:leaves",
			"group:leaves",
			"group:leaves",
			"group:leaves",
		},
	})
	--]]

	minetest.register_craft({
		type = "cooking",
		output = "plastic:raw_paraffin",
		recipe = "plastic:oil_extract",
	})

	minetest.register_craft({
		type = "cooking",
		output = "plastic:plastic_sheeting",
		recipe = "plastic:raw_paraffin",
	})

	minetest.register_craft({
		type = "fuel",
		recipe = "plastic:oil_extract",
		burntime = 20,
	})

	minetest.register_craft({
		type = "coalfuel",
		recipe = "plastic:oil_extract",
		burntime = 20,
	})

	minetest.register_craft({
		type = "fuel",
		recipe = "plastic:raw_paraffin",
		burntime = 20,
	})

	minetest.register_craft({
		type = "fuel",
		recipe = "plastic:plastic_sheeting",
		burntime = 20,
	})

	local c = "plastic:core"
	local f = plastic.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	plastic.registered = true
end


