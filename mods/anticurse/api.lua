
if not minetest.global_exists("anticurse") then anticurse = {} end

function anticurse.test(str, noreport)
	if anticurse.check_string(anticurse.foul, str) then
		if noreport == false then
			minetest.chat_send_player("MustTest", "# Server: String contains crudity!")
		end
		return false
	elseif anticurse.check_string(anticurse.curse, str) then
		if noreport == false then
			minetest.chat_send_player("MustTest", "# Server: String contains cursing!")
		end
		return false
	else
		if noreport == false then
			minetest.chat_send_player("MustTest", "# Server: String confirmed SJW-safe!")
		end
	end
	return true
end



function anticurse.dump_files()
	minetest.chat_send_player("MustTest", "# Server: Starting processing ...")

	local lines1, err1 = io.open(minetest.get_worldpath() .. "/ac_dump_bad.txt", "w")
	if err1 then return end
	local lines2, err2 = io.open(minetest.get_worldpath() .. "/ac_dump_good.txt", "w")
	if err2 then lines1:close() return end
	local lines3, err3 = io.open(minetest.get_worldpath() .. "/cursing.txt", "r")
	if err3 then lines1:close() lines2:close() return end

	local input = lines3:read("*all")
	if type(input) == "string" then
		local rows = string.split(input, "\n")
		for k, v in ipairs(rows) do
			local s = v:sub(v:find(">") + 1)
			local result = anticurse.test(s, true)
			if result then
				lines2:write(v .. "\n")
			else
				lines1:write(v .. "\n")
			end
		end
	end

	lines1:write("\n* * * DONE * * *\n")
	lines2:write("\n* * * DONE * * *\n")

	lines1:close()
	lines2:close()
	lines3:close()

	minetest.chat_send_player("MustTest", "# Server: Finished processing!")
end



-- Public API function.
anticurse.check = function(name, string, type)
  -- Always check player chat, even if they anticurse privs.
  -- This way I can see what players *would have* been kicked for,
  -- even if they weren't kicked (priv checking is done in the kick
  -- function). This helps improve the anticurse mod.

  if type == "foul" then
    return anticurse.check_string(anticurse.foul, string)
  elseif type == "curse" then
    return anticurse.check_string(anticurse.curse, string)
  elseif type == "impersonate" then
    return anticurse.check_string(anticurse.impersonate, string)
  elseif type == "other" then
    return anticurse.check_string(anticurse.other, string)
  end

  return false -- Nothing strange found.
end



-- Public API function.
anticurse.log = function(name, msg)
	if anticurse.logfile then
		anticurse.logfile:write("[" .. os.date("%Y-%m-%d, %H:%M:%S") .. "] <" .. name .. "> " .. msg .. "\r\n")
		anticurse.logfile:flush()
	end
end



-- Public API function.
anticurse.kick = function(name, reason)
	local dname = rename.gpn(name)
  if reason == "foul" then
		local ext = anticurse.get_kick_message("foul")
    minetest.chat_send_all("# Server: <" .. dname .. ">, eeew, really? " .. ext)
    spam.block_playerjoin(name, 30)
    minetest.kick_player(name, ext)
  elseif reason == "curse" then
		local ext = anticurse.get_kick_message("curse")
    minetest.chat_send_all("# Server: Player <" .. dname .. "> cursed. " .. ext)
    spam.block_playerjoin(name, 30)
    minetest.kick_player(name, ext)
  end
end



-- Also used to check if a rename is valid (see rename mod).
-- Return a string, to prevent player from connecting (with string as message).
-- Or return nil to allow them to connect.
local singleplayer = minetest.is_singleplayer()
anticurse.on_prejoinplayer = function(name)
	if singleplayer then
		return
	end

  if minetest.check_player_privs(name, {anticurse_bypass=true}) or gdac.player_is_admin(name) then
    return
  end

  --[[if banned_names.guest_name(name) then
    --return "Guest names are forbidden, sorry!"
	
		-- This code has moved to the welcome message mod.
		--minetest.after(10, function() minetest.chat_send_player(name, "# Server: WARNING! You have logged in using a \"guest name\". Please be aware that such accounts are subject to deletion WITHOUT WARNING. You are still free to explore the server, though! If you want to play permanently, log in under another (non-guest) name and register the account by crafting and keeping a Proof of Citizenship item.") end)
		return
  else--]]if anticurse.check_string(anticurse.foul, name) then
    return "Eeeew, really? Pick a different username!"
  elseif anticurse.check_string(anticurse.curse, name) then
    return "Cursing. :-/   Remove the curse, please, and try again."
  elseif anticurse.check_string(anticurse.other, name) then
    return "That name is forbidden. Please pick something else."
  elseif banned_names.all_numeric(name) then
    return "All-numeric names are forbidden, sorry!"
  elseif banned_names.reserved_name(name) then
    return "That name is reserved by the server!"
  elseif anticurse.check_string(anticurse.impersonate, name) then
    return "That name is too similar to someone else!"
  end


	-- We are in maintenance mode.
	--if name ~= "MustTest" then
	--	return "The server is currently down for extended maintenance. It will be back up in a few hours."
	--end
end


