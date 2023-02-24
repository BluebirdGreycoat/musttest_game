------------------------------------------------------------------------------
-- This file is registered as reloadable.
------------------------------------------------------------------------------

reload = reload or {}
reload.impl = reload.impl or {}



-- This function expects only to be called from the chatcommands that this mod registers!
reload.impl.dofile = function(name, path)
	local PREFIX = reload.chat_prefix
	local FILEPATH = path
	
	if type(path) == "string" and type(name) == "string" then
		if path == "" then
			reload.chat_send_player(name, PREFIX .. "No filepath provided.")
			return false
		end
		
		-- Log this action.
		reload.log("action", "[Mod Reload] Player <" .. name .. "> attempts to execute Lua source file '" .. FILEPATH .. "'.")
		
		-- A bit of security.
		if string.find(path, "%.%.") then
			reload.chat_send_player(name, PREFIX .. "Filepath cannot include '..' tokens.")
			return false
		end
		
		-- Attempt to load and execute the Lua file.
		local func, err = loadfile(FILEPATH)
		if not func then  -- Syntax error.
			reload.chat_send_player(name, PREFIX .. "Could not load file. Received error message: '" .. err .. "'.")
			return false
		end
		local good, err = pcall(func)
		if not good then  -- Runtime error.
			reload.chat_send_player(name, PREFIX .. "Could not execute file. Received error message: '" .. err .. "'.")
			return false
		end
		
		reload.chat_send_player(name, PREFIX .. "File '" .. FILEPATH .. "' successfully executed.")
		return true
	else
		reload.chat_send_player(name, PREFIX .. "Invalid arguments.")
		return false
	end
end



-- This function expects only to be called from the chatcommands that this mod registers!
reload.impl.reload = function(name, param)
	local PREFIX = reload.chat_prefix
	local ROOT = reload.root_path .. "/"
	
	local sparams = string.split(param, " ")
	local sfind = nil
	-- total files count
	local itotal = 0
	-- search result count
	local ifound = 0

	if sparams[1] == "list" then
		if type(sparams[2]) == "string" then
			sfind = sparams[2]
		end
		for k, v in pairs(reload.impl.files) do
			-- counting reloadable files
			itotal = itotal + 1
			local found = true
			if sfind then
				found = string.find(k, sfind, 1, false)
			end
			if found then
				-- counting search results
				ifound = ifound + 1
				
				-- get root relative path
				local srelpath = string.gsub(v, "^" .. ROOT, "")
				local sfmt = "%s %-32s '%s'."
				local sfileid = "<" .. k .. ">"
				local smsg = string.format(sfmt, PREFIX, sfileid, srelpath)
				reload.chat_send_player(name, smsg)
			end
		end
		local smsg = string.format("%s Listed %d of %d reloadable files.",
				PREFIX, ifound, itotal)
		reload.chat_send_player(name, smsg)
		reload.chat_send_player(name, PREFIX .. "End of list.")
		return true
	else
		if not param or param == "" then
			reload.chat_send_player(name, PREFIX .. "No file ID provided.")
			return false
		end
		
		local file = reload.impl.files[param]
		if file then
			return reload.impl.dofile(name, file)
		end
		
		reload.chat_send_player(name, PREFIX .. "Invalid file ID.")
		return false
	end
end



reload.impl.execute = function(name, path)
	local path2 = reload.root_path .. "/" .. path
	return reload.impl.dofile(name, path2)
end



reload.impl.dostring = function(name, str)
	local PREFIX = reload.chat_prefix
	if not str or str == "" then
		reload.chat_send_player(name, PREFIX .. "No argument provided.")
		reload.chat_send_player(name, PREFIX .. "Note: available custom variables are: me, mypos, player(name), print(text).")
		return false
	end

	-- Code injection.
	local ci = "do " .. -- Begin new block.
		"local me=minetest.get_player_by_name(\"" .. name .. "\") " ..
		"local mypos=me:get_pos() " ..
		"local myname=me:get_player_name() " ..
		"local function player(pname) return minetest.get_player_by_name(pname) end " ..
		"local function print(text) minetest.chat_send_player(\"" .. name .. "\", \"# Server: \" .. text) end " ..
		str .. " end" -- User code & end of block.

	local func, err = loadstring(ci)
	if not func then  -- Syntax error.
		reload.chat_send_player(name, PREFIX .. "Could not compile string. Received error message: '" .. err .. "'.")
		return false
	end
	local good, err = pcall(func)
	if not good then  -- Runtime error.
		reload.chat_send_player(name, PREFIX .. "Could not execute string. Received error message: '" .. err .. "'.")
		return false
	end
	reload.chat_send_player(name, PREFIX .. "Code executed successfully!")
	return true
end



-- Don't register the chat commands more than once, even if this file is reloaded.
if not reload.chat_registered then
	minetest.register_chatcommand("reload", {
		params = "<fileid> | list [search]",
		description = "Reload a registered source file at runtime.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.reload(...) end,
	})

	minetest.register_chatcommand("exec", {
		params = "<filepath>",
		description = "Load and execute an arbitrary Lua source file.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.execute(...) end,
	})
	
	minetest.register_chatcommand("run", {
		params = "<filepath>",
		description = "Load and execute an arbitrary Lua source file.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.execute(...) end,
	})
	
	minetest.register_chatcommand("dofile", {
		params = "<filepath>",
		description = "Load and execute an arbitrary Lua source file.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.execute(...) end,
	})
	
	-- Alias name. Some people (like me) keep wanting to spell it out.
	minetest.register_chatcommand("execute", {
		params = "<filepath>",
		description = "Load and execute an arbitrary Lua source file.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.execute(...) end,
	})
	
	minetest.register_chatcommand("dostring", {
		params = "<code>",
		description = "Execute a statement in Lua.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.dostring(...) end,
	})
	
	minetest.register_chatcommand("lua", {
		params = "<code>",
		description = "Execute a statement in Lua.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.dostring(...) end,
	})
	
	minetest.register_chatcommand("dolua", {
		params = "<code>",
		description = "Execute a statement in Lua.",
		
		-- Player must have server priviliges.
		privs = {server=true},
		func = function(...) reload.impl.dostring(...) end,
	})
	
	reload.chat_registered = true
end



