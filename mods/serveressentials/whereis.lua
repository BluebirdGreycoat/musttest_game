
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round

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

	local pos = vector_round(player:get_pos())
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
		if pn ~= target and vector_distance(player:get_pos(), pos) <= 64 then
			plist[#plist+1] = rename.gpn(pn)
		end
	end

	nearby = "{" .. table.concat(plist, ", ") .. "}"
	local HP = "HP=" .. math.floor((player:get_hp() / pova.get_active_modifier(player, "properties").hp_max) * 100) .. "%"
	local wieldname = serveressentials.get_short_stack_desc(player:get_wielded_item())
	if not wieldname or wieldname == "" then
		wieldname = "nothing"
	else
		wieldname = "'" .. wieldname .. "'"
	end
	local wielding = "wielding " .. wieldname

	minetest.chat_send_player(pname,
		"# Server: Player <" .. rename.gpn(target) .. ">: at " .. rc.pos_to_namestr(pos) .. ", " ..
		HP .. ", " .. wielding .. ", " .. area .. ". Nearby: " .. nearby .. ".")
end
