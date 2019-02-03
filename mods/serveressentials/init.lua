
serveressentials = serveressentials or {}
serveressentials.modpath = minetest.get_modpath("serveressentials")

function serveressentials.get_short_stack_desc(stack)
	local def = minetest.registered_items[stack:get_name()]
	local meta = stack:get_meta()
	local description = meta:get_string("description")
	if description ~= "" then
		return utility.get_short_desc(description):trim()
	elseif def and def.description then
		return utility.get_short_desc(def.description):trim()
	end
end

function serveressentials.whereis(pname, param)
	local target
	if param and param ~= "" then
		target = param
	else
		-- If no argument given, run function for all players.
		local players = minetest.get_connected_players()
		for _, player in ipairs(players) do
			local param = player:get_player_name()
			serveressentials.whereis(pname, param)
		end
		return
	end

	local player = minetest.get_player_by_name(target)
	if not player then
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> is not online!")
		return
	end

	local pos = vector.round(player:get_pos())
	local owner = protector.get_node_owner(pos) or ""

	local area = "in unclaimed territory"
	if owner ~= "" then
		area = "on land claimed by <" .. rename.gpn(owner) .. ">"
	end

	local nearby = ""
	local plist = {}

	local allplayers = minetest.get_connected_players()
	for _, player in ipairs(allplayers) do
		local pn = player:get_player_name() or ""
		if pn ~= target and vector.distance(player:get_pos(), pos) <= 64 then
			plist[#plist+1] = rename.gpn(pn)
		end
	end

	nearby = "{" .. table.concat(plist, ", ") .. "}"
	local HP = "with HP=" .. player:get_hp()
	local wieldname = serveressentials.get_short_stack_desc(player:get_wielded_item())
	if not wieldname or wieldname == "" then
		wieldname = "nothing"
	else
		wieldname = "'" .. wieldname .. "'"
	end
	local wielding = "wielding " .. wieldname

	minetest.chat_send_player(pname,
		"# Server: Player <" .. rename.gpn(target) .. ">: in the " .. rc.realm_description_at_pos(pos) .. " Realm at " .. minetest.pos_to_string(pos) .. ", " ..
		HP .. ", " .. wielding .. ", " .. area .. ".")
	minetest.chat_send_player(pname, "# Server: Nearby players: " .. nearby .. ".")
end

if not serveressentials.registered then
	minetest.register_privilege("whereis", {
		description = "Player may use the /whereis command to locate other players.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("whereis", {
		params = "[<player>]",
		description = "Locate a player or the caller.",
		privs = {whereis=true},

		func = function(...)
			return serveressentials.whereis(...)
		end
	})

	local c = "serveressentials:core"
	local f = serveressentials.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	serveressentials.registered = true
end





