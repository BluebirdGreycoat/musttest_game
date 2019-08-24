
joinspec = joinspec or {}
joinspec.modpath = minetest.get_modpath("welcome_msg")

joinspec.data = {
	warning = "Welcome to Must Test! Scroll text to see all.\n\n" ..
		"You may read the server’s webpage at http://arklegacy.duckdns.org/. " ..
		"You can find the rules there as well as an introduction to the world and " ..
		"a few hints for surviving.\n\n" ..
		"This is a heavily modded hard-core PvP & PvE survival server. " ..
		"The only way to find greatness is to survive, mine, build, and fight your way up! " ..
		"There is no creative mode.\n\n" ..
		"Monsters lurk where you don’t expect them. Always carry a weapon and don’t go out at night!\n\n" ..
		"Due to the way the mapgen generates ores, trade with other players is strongly recommended; " ..
		"sell what you don’t need and buy what you do.\n\n" ..
		"Minegeld is currency here. " ..
		"You can trade gold, silver and copper ingots for minegeld at the Wild North Precious Metal Exchange, " ..
		"which is located in the northeast quarter of the city at 1238, -8748.\n\n" ..
		"In order to register and preserve your account and player data, " ..
		"you must obtain a Proof of Citizenship. The recipe is in the craft guide.\n\n" ..
		"Further information can be found on the server’s website, but be warned that it " ..
		"is quite sparse, only covering a few important items -- part of the experience is " ..
		"about experimenting, exploring and discovering undocumented features. You can of course " ..
		"ask questions. Better hope that no one leads you astray. :-)",

	alert = "A recent client is recommended to enjoy advanced features.",
	version = minetest.get_version(),
}

local COLOR_ORANGE = core.get_color_escape_sequence("#ff3621")



function joinspec.on_joinplayer(player)
	-- Do not show joinspec to players who are dead on join.
	-- It causes the 'respawn' formspec (shown automatically by the client)
	-- to disappear, and the player can never respawn.
	local pname = player:get_player_name()
	if player:get_hp() > 0 then
		local result = passport.player_registered(pname)
		local haskey = passport.player_has_key(pname)
		joinspec.show_formspec(pname, result, haskey)
	else
		minetest.log("error", "Player " .. pname .. " joined while dead! Not showimg welcome formspec.")

		-- Force respawn player in city (bypass bed code for simplicity's sake)
		-- if player joins while dead. This nixes a 'disconnect on death' hack.
		-- An uncracked client will still display the respawn formspec, and the
		-- player will respawn again in their bed after pressing the button.
		randspawn.reposition_player(pname, player:get_pos())
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

		formspec = formspec ..
			"label[0,2.1;Server: ‘Must Test’ @ minetest:arklegacy.duckdns.org:30000]"

		formspec = formspec ..
			"label[0,2.6;Welcome to the frontier, stranger! Recommended device: PC]" ..
			"label[0,3.4;Server engine information:]"

		local project = minetest.formspec_escape(joinspec.data.version.project)
		local version = minetest.formspec_escape(joinspec.data.version.string)
		local vhash = minetest.formspec_escape(joinspec.data.version.hash or "No Hash")
		project = project .. minetest.formspec_escape(" (https://www.minetest.net/)")

		local alert = minetest.formspec_escape(joinspec.data.alert)
		formspec = formspec ..
			"label[0.3,3.8;Project: " .. project .. "]" ..
			"label[0.3,4.2;Version: " .. version .. " (" .. vhash .. ")]" ..
			"label[0.3,4.6;" .. alert .. "]"

		local warning = minetest.formspec_escape(joinspec.data.warning)
		formspec = formspec ..
			"textarea[0.3,5.3;7,2.2;warning;;" .. warning .. "]"

		-- Exit buttons.
		formspec = formspec ..
			"button[0,7.3;2,1;wrongserver;Wrong Server]" ..
			"button[3,7.3;2,1;trading;Trading]" ..
			"button[5,7.3;2,1;playgame;Let’s Try It!]"

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
	end

	if fields.passport then
		passport.show_formspec(pname)
	end

	if fields.trading then
		local pos = vector.round(player:get_pos())
		ads.show_formspec(pos, pname, false)
	end

	return true
end



if not joinspec.run_once then
	minetest.register_on_joinplayer(function(...)
		return joinspec.on_joinplayer(...)
	end)
	minetest.register_on_player_receive_fields(function(...)
		return joinspec.on_receive_fields(...)
	end)

	local c = "joinspec:core"
	local f = joinspec.modpath .. "/joinspec.lua"
	reload.register_file(c, f, false)

	joinspec.run_once = true
end
