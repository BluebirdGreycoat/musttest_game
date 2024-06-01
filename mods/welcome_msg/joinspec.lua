
if not minetest.global_exists("joinspec") then joinspec = {} end
joinspec.modpath = minetest.get_modpath("welcome_msg")

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local PRIORITY_MESSAGE = "Fight Big Tech Censorship!"
local PRIORITY_X_OFFSET = 1.4



local function get_text(pname)
	local text = "Welcome to the frontier, <" .. rename.gpn(pname) .. ">! You have arrived in the Enyekala Realms. This text provides you with basic information about Enyekala. Type /info in the chat to reshow this page.\n\n" ..
		"This is a hardcore survival game, with the occasional PvP, and with many materials and shapes to build with. Find greatness by working to master travel between the Realms!\n\n" ..
		"=== HOW TO BEGIN ===\n\n" ..
		"As a new adventurer, you start in a dry and dreary place the old-timers call “The Outback”. Leaving the dark cave in which you awoke, you quickly learn that nothing lasts in this tiny Realm. Escape this place ... or stay asleep in an endlessly repeating dream. You, O Adventuring Stranger, must make your choice.\n\n" ..
		"Your first order of business is to craft a stone pick. You need black stone. Pluck the dry shrubs to get sticks. Once you have a stone pick, you should locate some iron and build an iron pick. Craft yourself some armor while you’re at it, and the best sword you can lay hands on.\n\n" ..
		"Finally, you must find the Dimensional Gate, which is your way out. The portal chamber is well-guarded by Black-Hearted Oerkki, so you will need to fight your way through. In order to activate the portal, stand inside of it and strike the obsidian with your flint and steel. The dimensional shift takes a little time, and more Oerkki may appear while you wait, so you must time yourself carefully, and when you commit, be quick.\n\n" ..
		"If you get stuck somewhere in the Outback without a pick, you can use /spawn to return yourself to the dark cave.\n\n" ..
		"=== ADVICE ===\n\n" ..
		"Survival in the snowy stone-world of Enyekala is much harder than making a living in the Outback. The better the supplies that you bring with you through the Dimensional Gate, the better your chances in the snowy Overworld will be. Bring food, weapons, rare items, farming materials, and most importantly, a BED. Be very careful not to sleep in your bed in the open air. You will be mobbed! Build a shelter, even if it’s an ugly cobble shack.\n\n" ..
		"The Dimensional Gate is UNSTABLE. The portal’s exit coordinates change once every " .. randspawn.min_days .. " to " .. randspawn.max_days .. " realtime days, and you cannot rely on there being any city near you to protect you from mobs once you arrive in Enyekala proper! Until you can make it to civilization (or build your own), your fight is with the untamed wilderness.\n\n" ..
		"=== WEBSITE ===\n\n" ..
		"You can visit the server’s webpage at http://arklegacy.duckdns.org/. " ..
		"You can find here chatlogs, maps, news and tips.\n\n" ..
		"=== REGISTERING YOUR ACCOUNT ===\n\n" ..
		"To prevent your server account from being erased during a weekly purge, " ..
		"you must obtain a Proof of Citizenship. Find the recipe in the craft guide. Once you have crafted your Proof of Citizenship (PoC) you must keep it in your MAIN inventory at all times. The server purge happens every Sunday at the nightly restart.\n\n" ..
		"Later, when you have progressed, you can swap out your PoC for a Key, which provides useful features for expert adventurers, and which ALSO protects your account, as long as you hold it in your MAIN inventory."
	return text
end

joinspec.data = {
	version = minetest.get_version(),
}

local COLOR_ORANGE = core.get_color_escape_sequence("#ff3621")



function joinspec.on_joinplayer(player)
	-- Do not show joinspec to players who are dead on join.
	-- It causes the 'respawn' formspec (shown automatically by the client)
	-- to disappear, and the player can never respawn.
	local pname = player:get_player_name()
	local pos = player:get_pos()

	if player:get_hp() > 0 then
		local result = passport.player_registered(pname)
		local haskey = passport.player_has_key(pname)
		joinspec.show_formspec(pname, result, haskey)
	else
		minetest.log("error", "Player " .. pname .. " joined while dead! Not showing welcome formspec.")

		-- Force respawn player in Outback (bypass bed code for simplicity's sake)
		-- if player joins while dead. This nixes a 'disconnect on death' hack.
		-- An uncracked client will still display the respawn formspec, and the
		-- player will respawn again in their bed after pressing the button.
		randspawn.reposition_player(pname, pos)
	end

	local currealmname = rc.current_realm_at_pos(pos)

	if currealmname == "abyss" then
		-- If player logs in (or spawns) in the Outback, then show them the reset
		-- timeout after 30 seconds.
		minetest.after(30, function()
			local days1 = math_floor(serveressentials.get_outback_timeout() / (60*60*24))
			local days2 = math_floor(randspawn.get_spawn_reset_timeout() / (60*60*24))

			days1 = math.max(days1, 0)
			days2 = math.max(days2, 0)

			local s1 = "s"
			local s2 = "s"

			if days1 == 1 then s1 = "" end
			if days2 == 1 then s2 = "" end

			minetest.chat_send_player(pname,
				core.get_color_escape_sequence("#ffff00") ..
				"# Server: In " .. days1 .. " day" .. s1 ..", the dry winds of the Outback will cease. Then all begins again.")

			minetest.chat_send_player(pname,
				core.get_color_escape_sequence("#ffff00") ..
				"# Server: The unstable Dimensional Gate shifts in " .. days2 .. " day" .. s2 .. ".")
		end)
	end

	if currealmname == "midfeld" then
		-- If player logs in (or spawns) in Midfeld, then show them the reset
		-- timeout after 30 seconds.
		minetest.after(30, function()
			local days1 = math_floor(serveressentials.get_midfeld_timeout() / (60*60*24))
			days1 = math.max(days1, 0)

			local s1 = "s"

			if days1 == 1 then s1 = "" end

			minetest.chat_send_player(pname,
				core.get_color_escape_sequence("#ffff00") ..
				"# Server: Midfeld's fog falls in " .. days1 .. " day" .. s1 ..".")
		end)
	end
end



function joinspec.generate_formspec(pname, returningplayer, haskey)
	local formspec = ""

	if returningplayer then
		-- Returning player.
		formspec = formspec ..
			"size[7,4.9]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots

		formspec = formspec ..
			"box[0,0;6.8,2;#101010FF]" ..
			"image[0.4,0.1;7.3,2.1;musttest_game_logo.png]"

		formspec = formspec ..
			"label[0,2.1;Server: ‘Enyekala’ @ minetest:arklegacy.duckdns.org:30000]"

		formspec = formspec ..
			"label[0,2.6;Greetings <" .. rename.gpn(pname) .. ">. Welcome back to the frontier!]"

		local logintime = "Your last login time is unknown!"
		local pauth = core.get_auth_handler().get_auth(pname)
		if pauth and pauth.last_login then
			local days = math_floor((os.time() - pauth.last_login) / (60 * 60 * 24))
			logintime = "Your last login was on " .. os.date("!%Y/%m/%d, %H:%M UTC", pauth.last_login) .. " "

			if days <= 0 then
				logintime = logintime .. "(Today)"
			elseif days == 1 then
				logintime = logintime .. "(Yesterday)"
			else
				logintime = logintime .. "(" .. days .. " Days Ago)"
			end
		end
		logintime = minetest.formspec_escape(logintime)

		formspec = formspec ..
			"label[0,3.1;" .. logintime .. "]"

		-- Exit buttons.
		formspec = formspec ..
			"button[0,3.8;2,1;wrongserver;Not Now]" ..
			"button[2,3.8;2,1;trading;Trading]" ..
			"button[5,3.8;2,1;playgame;Proceed!]"

		if haskey then
			formspec = formspec ..
				"button[4,3.8;1,1;passport;Key]"
		end

		formspec = formspec ..
			"label[" .. PRIORITY_X_OFFSET .. ",4.7;" .. minetest.formspec_escape(COLOR_ORANGE ..
				"Priority: " .. PRIORITY_MESSAGE) .. "]"
	else
		-- New player.
		formspec = formspec ..
			"size[7,8.3]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots

		formspec = formspec ..
			"box[0,0;6.8,2;#101010FF]" ..
			"image[0.4,0.1;7.3,2.1;musttest_game_logo.png]"

		local warning = minetest.formspec_escape(get_text(pname))
		formspec = formspec ..
			"textarea[0.3,2.3;7,5.6;warning;;" .. warning .. "]"

		-- Exit buttons.
		formspec = formspec ..
			"button[0,7.3;2,1;wrongserver;" .. minetest.formspec_escape("I’m Scared ...") .. "]" ..
			"button[2,7.3;2,1;trading;Tradernet]" ..
			"button[4,7.3;3,1;playgame;Accept Challenge!]" ..
			"tooltip[wrongserver;Cowards will be kicked!]" ..
			"tooltip[playgame;You are either brave, or stupid.]"

		formspec = formspec ..
			"label[" .. PRIORITY_X_OFFSET .. ",8.1;" .. minetest.formspec_escape(COLOR_ORANGE ..
				"Priority: " .. PRIORITY_MESSAGE) .. "]"
	end

	return formspec
end



function joinspec.show_formspec(pname, returningplayer, haskey)
	local formspec = joinspec.generate_formspec(pname, returningplayer, haskey)
	minetest.show_formspec(pname, "joinspec:main", formspec)
end



function joinspec.on_receive_fields(player, formname, fields)
	if formname ~= "joinspec:main" then
		return
	end
	local pname = player:get_player_name()

	if fields.playgame then
		minetest.close_formspec(pname, "joinspec:main")
	end

	if fields.wrongserver then
		minetest.kick_player(pname, "You pressed the 'Leave Server' button. ;-)")
		minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> was kicked off the server.")
	end

	if fields.passport then
		passport.open_keys[pname] = true
		ambiance.sound_play("fancy_chime1", player:get_pos(), 1.0, 20, "", false)
		passport.show_formspec(pname)
	end

	if fields.trading then
		local pos = vector_round(player:get_pos())
		ads.show_formspec(pos, pname, false)
	end

	return true
end



function joinspec.show_info(pname, param)
	joinspec.show_formspec(pname, false)
end



if not joinspec.run_once then
	minetest.register_on_joinplayer(function(...)
		return joinspec.on_joinplayer(...)
	end)
	minetest.register_on_player_receive_fields(function(...)
		return joinspec.on_receive_fields(...)
	end)

	minetest.register_chatcommand("info", {
		params = "",
		description = "(Re)show the server's welcome formspec, with basic server information.",
		privs = {},
		func = function(...)
			joinspec.show_info(...)
			return true
		end,
	})

	local c = "joinspec:core"
	local f = joinspec.modpath .. "/joinspec.lua"
	reload.register_file(c, f, false)

	joinspec.run_once = true
end
