
if not minetest.global_exists("joinspec") then joinspec = {} end
joinspec.modpath = minetest.get_modpath("welcome_msg")

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local PRIORITY_MESSAGE = "Survive!"
--local PRIORITY_X_OFFSET = 1.4
local WEBADDR = minetest.settings:get("server_address")
local WEBPORT = minetest.settings:get("port")
local FORUMADDR = minetest.settings:get("forum_topic")

if not WEBADDR or WEBADDR == "" then
	WEBADDR = "example.com"
end

if not FORUMADDR or FORUMADDR == "" then
	FORUMADDR = "forum.minetest.net"
end



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
		"You can visit the server’s webpage at http://" .. WEBADDR .. "/. " ..
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
		minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> incarnated dead! Refusing to welcome a corpse.")

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
	local formfact = formspec.create_formspec_from_table
	local formspec = ""

	if returningplayer then
		local logintime = "Your last login time is unknown!"
		local pauth = core.get_auth_handler().get_auth(pname)
		if pauth and pauth.last_login then
			local days = math.floor((os.time() - pauth.last_login) / (60 * 60 * 24))
			local hours = math.floor((os.time() - pauth.last_login) / (60 * 60))
			logintime = "Your last login was on " .. os.date("!%Y/%m/%d, %H:%M UTC", pauth.last_login) .. " "
			local loginhours = ""

			if hours == 1 then
				loginhours = ", 1 hour ago"
			else
				loginhours = ", " .. hours .. " hours ago"
			end

			if days <= 0 then
				logintime = logintime .. "(Today" .. loginhours .. ")"
			elseif days == 1 then
				logintime = logintime .. "(Yesterday" .. loginhours .. ")"
			else
				logintime = logintime .. "(" .. days .. " days" .. loginhours .. ")"
			end
		end

		-- Returning player.
		formspec = {
			size = {x=9.25, y=6.625},

			children = {
				{type="background9", texture="gui_formbg.png", auto_clip=true},

				{type="box", x=0.5, y=0.5, w=8.25, h=2.3, color="#101010FF"},
				{type="image", x=1, y=0.6, w=7.3, h=2.1, texture="musttest_game_logo.png"},
				{type="label", x=1.15, y=1, w=7, h=0.35, text="Enyekala", style={valign="top", halign="left"}, show_box=false},
				{type="label", x=1.15, y=2, w=7, h=0.35, text="Luanti", style={halign="right", valign="bottom"}, show_box=false},

				{
					type = "label",
					x = 0.5,
					y = 3.15,
					text = "Greetings <" .. rename.gpn(pname) .. ">. Welcome back to the Enyekala frontier!",
				},
				{
					type = "label",
					x = 0.5,
					y = 3.5,
					text = logintime,
				},

				{
					type = "label",
					x = 0.5,
					y = 7.85 - 3.9,
					w = 6,
					h = 0.35,
					text = "Server: " .. minetest.colorize("cyan", WEBADDR) .. ":" .. WEBPORT,
					style = {valign="center"},
					show_box = false,
				},
				{
					type = "label",
					x = 0.5,
					y = 8.2 - 3.9,
					w = 6,
					h = 0.35,
					text = "Forum: " .. minetest.colorize("cyan", FORUMADDR),
					style = {valign="center"},
					show_box = false,
				},

				{type="button_url", x=7.05, y=7.85 - 3.9, w=1.7, h=0.35, name="website_link", label="Website", url="http://" .. WEBADDR},
				{type="button_url", x=7.05, y=8.2 - 3.9, w=1.7, h=0.35, name="forum_link", label="Forum", url="http://" .. FORUMADDR},

				{type="button", x=0.5, y=9.2 - 4.1, w=2.2, h=0.8, name="wrongserver", label="Not Now", style={bgcolor="red"}, tooltip="Misclicked in the Minetest Main Menu, did you?"},
				{type="button", x=2.9, y=9.2 - 4.1, w=2.2, h=0.8, name="trading", label="Trading"},
				{type="button", x=5.55 + 1, y=9.2 - 4.1, w=2.2, h=0.8, name="playgame", label="Proceed!"},

				{
					type = "label",
					x = 0.5,
					y = 10.1 - 4.1,
					w = 8.25,
					h = 0.4,
					text = COLOR_ORANGE .. "Priority: " .. PRIORITY_MESSAGE,
					style = {
						halign = "center",
						valign = "center",
					},

					-- Used for debugging.
					show_box = false,
				},
			},
		}

		if haskey then
			table.insert(formspec.children, {type="button", x=5.3, y=9.2 - 4.1, w=1.05, h=0.8, name="passport", label="Key"})
		end

		-- Convert table to string.
		formspec = formfact(formspec)
	else
		-- New player.
		formspec = formfact({
			size = {x=9.25, y=10.875},

			children = {
				{type="background9", texture="gui_formbg.png", auto_clip=true},

				{type="box", x=0.5, y=0.5, w=8.25, h=2.3, color="#101010FF"},
				{type="image", x=1, y=0.6, w=7.3, h=2.1, texture="musttest_game_logo.png"},
				{type="label", x=1.15, y=1, w=7, h=0.35, text="Enyekala", style={valign="top", halign="left"}, show_box=false},
				{type="label", x=1.15, y=2, w=7, h=0.35, text="Luanti", style={halign="right", valign="bottom"}, show_box=false},

				{type="textarea", x=0.5, y=3.1, w=8.25, h=4.4, name="warning", text=get_text(pname)},

				{
					type = "label",
					x = 0.5,
					y = 7.85,
					w = 6,
					h = 0.35,
					text = "Server: " .. minetest.colorize("cyan", WEBADDR) .. ":" .. WEBPORT,
					style = {valign="center"},
					show_box = false,
				},
				{
					type = "label",
					x = 0.5,
					y = 8.2,
					w = 6,
					h = 0.35,
					text = "Forum: " .. minetest.colorize("cyan", FORUMADDR),
					style = {valign="center"},
					show_box = false,
				},

				{type="button_url", x=7.05, y=7.85, w=1.7, h=0.35, name="website_link", label="Website", url="http://" .. WEBADDR},
				{type="button_url", x=7.05, y=8.2, w=1.7, h=0.35, name="forum_link", label="Forum", url="http://" .. FORUMADDR},

				{type="button", x=0.5, y=9.2, w=2.25, h=0.8, name="wrongserver", label="I’m Scared ...", style={bgcolor="red"}, tooltip="Cowards will be kicked!"},
				{type="button", x=3, y=9.2, w=2.25, h=0.8, name="trading", label="Tradernet"},
				{type="button", x=5.5, y=9.2, w=3.25, h=0.8, name="playgame", label="Accept Challenge!", tooltip="You are either brave, or stupid."},

				{
					type = "label",
					x = 0.5,
					y = 10.1,
					w = 8.25,
					h = 0.4,
					text = COLOR_ORANGE .. "Priority: " .. PRIORITY_MESSAGE,
					style = {
						halign = "center",
						valign = "center",
					},

					-- Used for debugging.
					show_box = false,
				},
			},
		})
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
	local returning = false
	local haskey = false

	-- For testing.
	--[[
	if #param > 0 then
		returning = true
	end

	if #param > 1 then
		haskey = true
	end
	--]]

	joinspec.show_formspec(pname, returning, haskey)
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
