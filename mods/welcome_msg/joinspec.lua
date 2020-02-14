
joinspec = joinspec or {}
joinspec.modpath = minetest.get_modpath("welcome_msg")

joinspec.data = {
	warning = "Welcome to the frontier, Stranger! You are on the Must Test Server, an advanced survival-mode game built on top of the Minetest Project (https://www.minetest.net/).\n\n" ..
		"Please read this text, as it contains important information about this server. You will need to scroll this text to read all of it. Once you have closed this formspec, you can reshow it by typing “/info” in the chat, without quotes.\n\n" ..
		"This is a heavily modded, hard-core PvP & PvE survival server. " ..
		"The only way to find greatness is to survive, mine, build, and fight your way up! " ..
		"There is no creative mode.\n\n" ..
		"As a new adventurer, you start in a dry and dreary place the old-timers call “The Outback”. This is the dimension of the Unreal, because nothing here lasts, and in time, all is forgotten …. Leaving this realm, and finding your way to the true world, is a rite of passage. If you can escape this place then it may be that you have a chance to overcome the harder challenges of survival in the natural realm. Many will not make the attempt. For them, the place of the Unreal is reality enough, and there is no need to seek anything else. You, O Adventuring Stranger, must make your choice.\n\n" ..
		"You may read the server’s webpage at http://arklegacy.duckdns.org/. " ..
		"On this site you will find the server rules, as well as an introduction to the world, a FAQ, " ..
		"some gameplay tips, and of course some maps of various locations. The website does not cover everything about Must Test—indeed it cannot—and part of the experience is about exploring, experimenting, and discovering undocumented stuff. Feel free to ask questions of the old-timers—but be careful! If you annoy them too much, you’d better beware lest they feed you to a Dungeon Master …. >:)\n\n" ..
		"Due to the way the mapgen generates ores (among other things), trade with other players comes highly recommended; " ..
		"sell what you don’t need and buy what you do. It is rare for one person to have convenient access to all available resources on this server, though with enough effort it can be done.\n\n" ..
		"Minegeld is currency here. " ..
		"You can trade gold, silver and copper ingots for minegeld at the Wild North Precious Metal Exchange, " ..
		"which is located in the northeast quarter of the city at 1238, -8748. Some long-time inhabitants have commissioned banks out of their own resources, which you can use as well.\n\n" ..
		"In order to register and preserve your account and player data, " ..
		"you must obtain a Proof of Citizenship. The recipe is in the craft guide. Once you have crafted your Proof of Citizenship (PoC) you must keep it in your MAIN inventory at all times. Without it, the server will erase your account. This happens every Sunday when the system is purged of excess player data. Note that later you can upgrade your PoC to a Key, which provides a number of useful features for experienced adventurers, as well as a way to communicate with offline players (via in-game mail).\n\n" ..
		"This server makes use of the latest Minetest APIs, therefore a recent client is recommended.",

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

		-- Force respawn player in city (bypass bed code for simplicity's sake)
		-- if player joins while dead. This nixes a 'disconnect on death' hack.
		-- An uncracked client will still display the respawn formspec, and the
		-- player will respawn again in their bed after pressing the button.
		randspawn.reposition_player(pname, pos)
	end

	if rc.current_realm_at_pos(pos) == "abyss" then
		-- If player logs in (or spawns) in the Outback, then show them the reset
		-- timeout after 30 seconds.
		minetest.after(30, function()
			local days = math.floor(serveressentials.get_outback_timeout() / (60*60*24))
			local s = "s"
			if days == 1 then
				s = ""
			end
			minetest.chat_send_player(pname,
				core.get_color_escape_sequence("#ffff00") ..
				"# Server: In " .. days .. " day" .. s ..", the dry winds of the Outback will cease. Then all begins again.")
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
			"label[0,2.1;Server: ‘Must Test’ @ minetest:arklegacy.duckdns.org:30000]"

		formspec = formspec ..
			"label[0,2.6;Greetings <" .. pname .. ">. Welcome back to the frontier!]"

		local logintime = "Your last login time is unknown!"
		local pauth = core.get_auth_handler().get_auth(pname)
		if pauth and pauth.last_login then
			local days = math.floor((os.time() - pauth.last_login) / (60 * 60 * 24))
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
			"label[2.6,4.7;" .. minetest.formspec_escape(COLOR_ORANGE .. "Priority: Survive!") .. "]"
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

		local warning = minetest.formspec_escape(joinspec.data.warning)
		formspec = formspec ..
			"textarea[0.3,2.3;7,5.6;warning;;" .. warning .. "]"

		-- Exit buttons.
		formspec = formspec ..
			"button[0,7.3;2,1;wrongserver;" .. minetest.formspec_escape("I’m Scared ...") .. "]" ..
			"button[2,7.3;2,1;trading;Tradernet]" ..
			"button[4,7.3;3,1;playgame;Accept Challenge!]"

		formspec = formspec ..
			"label[2.6,8.1;" .. minetest.formspec_escape(COLOR_ORANGE .. "Priority: Survive!") .. "]"
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
		local pos = vector.round(player:get_pos())
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
