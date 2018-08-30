
xban.importers = xban.importers or { }

-- Files are reloadable.
dofile(xban.MP.."/importers/minetest.lua")
dofile(xban.MP.."/importers/v1.lua")
dofile(xban.MP.."/importers/v2.lua")

function xban.importers.chatcommand(name, params)
	if params == "--list" then
		local importers = { }
		for importer in pairs(xban.importers) do
			table.insert(importers, importer)
		end
		minetest.chat_send_player(name,
			("# Server: Known importers: %s."):format(
			table.concat(importers, ", ")))
		return
	elseif not xban.importers[params] then
		minetest.chat_send_player(name,
			("# Server: Unknown importer '%s'"):format(params))
		minetest.chat_send_player(name, "# Server: Try '/xban_dbi --list'.")
		return
	end
	local f = xban.importers[params]
	local ok, err = f()
	if ok then
		minetest.chat_send_player(name, "# Server: Import successfull.")
	else
		minetest.chat_send_player(name,
			("# Server: Import failed: '%s'."):format(err))
	end
end

if not xban.importers.registered then
	minetest.register_chatcommand("xban_dbi", {
		description = "Import old databases.",
		params = "<importer>",
		privs = { server=true },
		func = function(...)
			return xban.importers.chatcommand(...)
		end,
	})

	xban.importers.registered = true
end
