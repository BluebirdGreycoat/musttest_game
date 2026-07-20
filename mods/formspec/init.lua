
if not minetest.global_exists("formspec") then formspec = {} end
formspec.modpath = minetest.get_modpath("formspec")

formspec.WIDGET_TYPES = formspec.WIDGET_TYPES or {}
formspec.FORMSPEC_VERSION = 9



function formspec.register_widget(name, info)
	formspec.WIDGET_TYPES[name] = table.copy(info)
end



dofile(formspec.modpath .. "/widgets.lua")
dofile(formspec.modpath .. "/editor.lua")
dofile(formspec.modpath .. "/docparser.lua")
dofile(formspec.modpath .. "/serialize.lua")



if not formspec.run_once then
	formspec.run_once = true

	local c = "formspec:core"
	local f = formspec.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	formspec.MOD_STORAGE = minetest.get_mod_storage()

	minetest.register_chatcommand("fs", {
		params = "",
		description = "Show the formspec editor.",
		privs = {server=true},

		func = function(...)
			formspec.show_editor(...)
		end,
	})

	minetest.register_on_player_receive_fields(function(...)
		return formspec.on_player_receive_fields(...)
	end)

	------------------------------------------------------------------------------
	-- HTTP GROK CODE B/C I'M LAZY
	-- Fetch the widget style documentation from Github.
	-- This way it's always up-to-date and I never have to worry about it.
	-- Unless the devs change their markdown format, heh, heh.
	------------------------------------------------------------------------------

	-- Must be called at the top level of init.lua (not inside a function)
	local http = core.request_http_api and core.request_http_api()

	if not http then
		core.log("error", "[formspec] HTTP API is not available. "
			.. "Add your mod name to secure.http_mods in luanti.conf / minetest.conf")
		return
	end

	-- The function that will receive the raw document
	local function process_lua_api_md(raw_markdown)
		-- raw_markdown is the full text of lua_api.md
		core.log("action", "[formspec] Received lua_api.md (" .. #raw_markdown .. " bytes)")
		-- do whatever you want with it here

		-- The documentation for which styles are valid for which widgets should
		-- be between these tags. Don't store the whole document in memory persistently,
		-- it's huge.
		local start = raw_markdown:find("### Valid Properties")
		local finish = raw_markdown:find("### Valid States")

		if start and finish and start < finish then
			formspec.RAW_MARKDOWN = raw_markdown:sub(start, finish):split("\n")
			formspec.HTTP_REQUEST_SUCCEEDED = true
		end
	end

	-- Perform the request
	http.fetch({
		url = "https://raw.githubusercontent.com/luanti-org/luanti/refs/heads/master/doc/lua_api.md",
		timeout = 20,          -- seconds
	}, function(result)
		if result.succeeded and result.data then
			process_lua_api_md(result.data)
		else
			core.log("error", "[formspec] Failed to fetch lua_api.md"
				.. (result.code and (" (HTTP " .. result.code .. ")") or " (timeout/error)"))
		end
	end)

	------------------------------------------------------------------------------
	-- END GROK CODE.
	------------------------------------------------------------------------------
end
