
vpn_lists = {}

local function chat_send(pname, message)
	minetest.chat_send_player(pname, "# Server: " .. message)
end

local function chat_cmd_handler(pname, param)
	param = param:trim()
	local tokens = param:split(" ")

	if #tokens == 2 then
		local action = tokens[1]
		local target = rename.grn(tokens[2])
		local dname = rename.gpn(target)
		if minetest.player_exists(target) then
			if action == "add" or action == "insert" or action == "put" then
				local whitelisted = anti_vpn.whitelist_player(target, true)
				if whitelisted then
					chat_send(pname, "Player <" .. dname .. "> already in whitelist.")
				else
					chat_send(pname, "Player <" .. dname .. "> added to whitelist.")
				end
			elseif action == "del" or action == "rm" or action == "delete" or action == "remove" then
				local whitelisted = anti_vpn.whitelist_player(target, false)
				if whitelisted then
					chat_send(pname, "Player <" .. dname .. "> removed from whitelist.")
				else
					chat_send(pname, "Player <" .. dname .. "> wasn't in whitelist.")
				end
			else
				chat_send(pname, "Unrecognized command: " .. action)
			end
		else
			chat_send(pname, "Player not found.")
		end
	else
		chat_send(pname, "Usage: <command> <playername>")
	end
end

minetest.register_chatcommand('vpn_whitelist', {
    privs = {vpn_control = true},
    description = 'Whitelist or un-whitelist a player from the Anti VPN system.',
    params = '<command> <playername>',
    func = chat_cmd_handler,
})
