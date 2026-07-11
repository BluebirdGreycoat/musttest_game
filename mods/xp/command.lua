
function xp.do_chatcommand(pname, param)
	local tokens = param:split(" ")
	if #tokens < 2 then
		minetest.chat_send_player(pname, "# Server: Wrong number of arguments.")
		return
	end

	local verb = tokens[1]
	local target = rename.grn(tokens[2])

	if verb == "get" then
		if not minetest.player_exists(target) then
			minetest.chat_send_player(pname, "# Server: No such player.")
			return
		end
		local amount = xp.get_xp(target, "digxp")
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> has " .. amount .. " XP.")
	elseif verb == "set" then
		if #tokens ~= 3 then
			minetest.chat_send_player(pname, "# Server: Wrong number of arguments.")
			return
		end
		if not minetest.player_exists(target) then
			minetest.chat_send_player(pname, "# Server: No such player.")
			return
		end
		local amount = tonumber(tokens[3])
		if type(amount) == "nil" then
			minetest.chat_send_player(pname, "# Server: Couldn't parse amount.")
			return
		end
		if amount > xp.digxp_max then
			amount = xp.digxp_max
		end
		if amount < 0 then
			amount = 0
		end
		xp.set_xp(target, "digxp", amount)
		amount = xp.get_xp(target, "digxp")
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> now has " .. amount .. " XP.")
	elseif verb == "add" then
		if #tokens ~= 3 then
			minetest.chat_send_player(pname, "# Server: Wrong number of arguments.")
			return
		end
		if not minetest.player_exists(target) then
			minetest.chat_send_player(pname, "# Server: No such player.")
			return
		end
		local amount = tonumber(tokens[3])
		if type(amount) == "nil" then
			minetest.chat_send_player(pname, "# Server: Couldn't parse amount.")
			return
		end
		local total = xp.get_xp(target, "digxp")
		total = total + amount
		if total > xp.digxp_max then
			total = xp.digxp_max
		end
		if total < 0 then
			total = 0
		end
		xp.set_xp(target, "digxp", total)
		amount = xp.get_xp(target, "digxp")
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> now has " .. amount .. " XP.")
	else
		minetest.chat_send_player(pname, "# Server: Invalid operation.")
		return
	end
end
