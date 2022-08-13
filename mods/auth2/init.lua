
auth2 = auth2 or {}
auth2.modpath = minetest.get_modpath("auth2")



function auth2.last_login(name, param)
	if param == "" then
		param = name
	end

	-- Disallow getting the administrator's last login time.
	if not gdac.player_is_admin(param) then
		local pauth = minetest.get_auth_handler().get_auth(param)
		if pauth and pauth.last_login and pauth.last_login ~= -1 then
			local hours = math.floor((os.time() - pauth.last_login) / (60 * 60))
			local time_since = ""

			if hours == 1 then
				time_since = "Was " .. hours .. " hour ago."
			else
				time_since = "Was " .. hours .. " hours ago."
			end

			-- Time in UTC, ISO 8601 format
			minetest.chat_send_player(name, "# Server: <" .. rename.gpn(param) ..
				">'s last login time was " ..
				os.date("!%Y-%m-%dT%H:%M:%SZ", pauth.last_login) .. ". " .. time_since)

			return true
		end
	end

	minetest.chat_send_player(name, "# Server: <" .. rename.gpn(param) ..
		">'s last login time is unknown.")

	return true
end



if not auth2.run_once then
	-- Override this function before 'sauth' calls it.
	-- Sauth must depend on this mod for this to work.
	local old_auth_register = minetest.register_authentication_handler
	function minetest.register_authentication_handler(handler)

		local get_auth = handler.get_auth
		function handler.get_auth(name)
			return get_auth(rename.grn(name))
		end

		local create_auth = handler.create_auth
		function handler.create_auth(name, password)
			return create_auth(rename.grn(name), password)
		end

		local delete_auth = handler.delete_auth
		function handler.delete_auth(name)
			return delete_auth(rename.grn(name))
		end

		local set_password = handler.set_password
		function handler.set_password(name, password)
			return set_password(rename.grn(name), password)
		end

		local set_privileges = handler.set_privileges
		function handler.set_privileges(name, privileges)
			return set_privileges(rename.grn(name), privileges)
		end

		local reload = handler.reload
		function handler.reload()
			return reload()
		end

		local record_login = handler.record_login
		function handler.record_login(name)
			-- Delay the login record so that we can get the previous login
			-- time from within another `on_playerjoin` handler.
			minetest.after(0.5, function() record_login(rename.grn(name)) end)
		end

		local name_search = handler.name_search
		function handler.name_search(name)
			return name_search(rename.grn(name))
		end

		-- Log activity.
		minetest.log("action", "Wrapped auth handler in live-rename functions!")

		-- Call the original engine function.
		return old_auth_register(handler)
	end

	-- Override some global functions, for completeness.
	local set_password = core.set_player_password
	function core.set_player_password(name, password)
		return set_password(rename.grn(name), password)
	end

	local set_privileges = core.set_player_privs
	function core.set_player_privs(name, privileges)
		return set_privileges(rename.grn(name), privileges)
	end

	minetest.register_chatcommand("last-login", {
		params = "[name]",
		description = "Get the last login time of a player or yourself.",

		func = function(...)
			return auth2.last_login(...)
		end,
	})

	local c = "auth2:core"
	local f = auth2.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	auth2.run_once = true
end
