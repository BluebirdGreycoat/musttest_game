
mailall = mailall or {}
mailall.modpath = minetest.get_modpath("hb4")
mailall.worldpath = minetest.get_worldpath()

function mailall.get_registered_players()
	if mailall.registered_players then
		return mailall.registered_players
	end

	-- Read data, if it hasn't been loaded for this session yet.
	local file = io.open(mailall.worldpath .. "/registered-players.txt", "r")
	if not file then
		return {}
	end

	local data = file:read("*all")
	file:close()

	local players = {}

	if data and data ~= "" then
		local lines = string.split(data, "\n")
		for _, line in pairs(lines) do
			local name = string.trim(line)
			players[#players+1] = name
		end
	end

	mailall.registered_players = players
	return players
end

function mailall.send_mail(name, subj, msg)
	local players = mailall.get_registered_players()

	local from = string.trim(name)
	local subject = string.trim(subj)
	local message = string.trim(msg)

	-- Insert line breaks.
	message = string.gsub(message, "%%[nN]", "\n")

	--minetest.chat_send_player(name, "# Server: Would send: \"" .. message .. "\".")
	--do return 0, 0 end

	local good, bad = email.send_mail_multi(from, players, subject, message)
	minetest.chat_send_player(name, "# Server: Email sent to " .. #good ..
		" of " .. #players .. " total registered players. " ..
		"Failed to send message to " .. #bad .. " players.")

	return #good, #bad
end

function mailall.run_command(name, param)
	mailall.send_mail(name, "Public Announcement", param)
end

if not mailall.registered then
	minetest.register_chatcommand("mailall", {
		params = "<message>",
		description = "Send an in-game email to all registered players on the server.",
		privs = {shout=true, interact=true},
		func = function(...)
			return mailall.run_command(...)
		end
	})

	mailall.registered = true
end
