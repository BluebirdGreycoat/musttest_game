
function xp.on_punch_sign(pos, node, pname)
	local function system_response(msg)
		minetest.chat_send_player(pname, "# Server: " .. msg)
	end

	local nn = minetest.get_node(pos)
	if nn.name ~= node.name then
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref or not pref:is_player() then
		return
	end

	-- Only for rune slabs.
	if not nn.name:find("stone") then
		return
	end

	local meta = minetest.get_meta(pos)
	local info = minetest.deserialize(meta:get_string("xp_storage")) or
		{owner="", total={dig=0, build=0}}

	if info.owner == "" then
		-- Imbue XP.
		local total = {dig=xp.get_xp(pname, "digxp"), build=xp.get_xp(pname, "buildxp")}
		if total.dig >= 1000 and total.build >= 1000 then
			total.dig = 1000
			total.build = 1000
			xp.subtract_xp(pname, "digxp", 1000)
			xp.subtract_xp(pname, "buildxp", 1000)
			info.total = total
			info.owner = pname
			system_response("You imbue some of your experience points into the Rune Slab.")
			-- Serialize at end of function.
		else
			system_response("You need at least 1k experience points in both categories in order to imbue.")
			return
		end
	elseif info.owner == pname then
		-- Retrieve XP.
		local loss_scalar = 0.98

		local get_dig = info.total.dig * loss_scalar
		local get_build = info.total.build * loss_scalar

		xp.add_xp(pname, "digxp", get_dig)
		xp.add_xp(pname, "buildxp", get_build)

		info.total = {dig=0, build=0}
		info.owner = ""

		system_response("The stored experience points return to your person.")
		system_response("You gain: " .. get_dig .. " / " .. get_build .. ".")
		-- Serialize at end of function.
	else
		-- Steal XP.
		local loss_scalar = 0.75

		local get_dig = info.total.dig * loss_scalar
		local get_build = info.total.build * loss_scalar

		xp.add_xp(pname, "digxp", get_dig)
		xp.add_xp(pname, "buildxp", get_build)

		info.total = {dig=0, build=0}
		info.owner = ""

		system_response("The stolen experience points are added to your person.")
		system_response("You gain: " .. get_dig .. " / " .. get_build .. ".")
	end

	meta:set_string("xp_storage", minetest.serialize(info))
	meta:mark_as_private("xp_storage")
end

minetest.after(0, function()
	signs.register_callback("on_punch_sign", "xp", xp.on_punch_sign)
end)
