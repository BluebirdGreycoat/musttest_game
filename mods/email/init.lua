
-- Mod is reloadable.
email = email or {}
email.inboxes = email.inboxes or {}
email.modpath = minetest.get_modpath("email")
email.worldpath = minetest.get_worldpath()
email.database = email.worldpath .. "/email.sqlite"
email.maxsize = 100
email.max_subject_length = 128
email.max_message_length = 1024*2

-- Localize for performance.
local math_random = math.random

dofile(email.modpath .. "/database.lua")



function email.on_startup()
	assert(not email.db)
	email.db = email.sql.open(email.database)
	assert(email.db)

	-- Ensure table exists.
	email.db_exec([[ CREATE TABLE IF NOT EXISTS email (
		name TEXT,
		sender TEXT,
		date TEXT,
		subject TEXT,
		message TEXT,
		number INTEGER
	); ]])
end



function email.on_shutdown()
	assert(email.db)
	email.db:close()
	email.db = nil
end



function email.get_inbox(name)
	name = rename.grn(name)
  if not email.inboxes[name] then
		assert(email.db)
		email.inboxes[name] = email.load_inbox(email.db, name) or {}
	end
	return email.inboxes[name]
end



function email.get_inbox_size(name)
	name = rename.grn(name)
  local tb = email.get_inbox(name)
  return #tb
end



function email.clear_inbox(name, mails)
	name = rename.grn(name)
	local inbox = email.get_inbox(name)

  -- `mails` is a list of emails to delete.
  -- If an email has a duplicate in the `mails` table, then we delete it.
  for k, v in ipairs(mails) do
    local rng = v.rng
    assert(type(rng) == "number")
		for i, j in ipairs(inbox) do
			local rng2 = j.rng
			assert(type(rng2) == "number")
			if rng2 == rng then
				table.remove(inbox, i)
				break
			end
		end
  end

	email.delete_mails(email.db, name, mails)

  if #inbox == 0 then
		-- This will cause a refetch from database.
    email.inboxes[name] = nil
  end
end



function email.send_mail_multi(from, multi_target, subject, message)
	from = rename.grn(from)

  local success = {}
  local failure = {}

	email.db_exec([[ BEGIN TRANSACTION; ]])
  
  -- Assume multi-target is a table of playernames to send mail to.
  for k, v in ipairs(multi_target) do
		v = rename.grn(v)

    local bresult, sresult = email.send_mail_ex(from, v, subject, message)
    if bresult == true then
      table.insert(success, {name=v, error=sresult})
    elseif bresult == false then
      table.insert(failure, {name=v, error=sresult})
    end
  end

	email.db_exec([[ COMMIT; ]])
  return success, failure -- Tables with success and failure results.
end



-- API function. Shall send mail to a player, first checking if
-- sending is possible and permitted.
-- Returns a success boolean and a string key.
function email.send_mail_single(from, to, subject, message)
	from = rename.grn(from)
	to = rename.grn(to)
  local bresult, sresult = email.send_mail_ex(from, to, subject, message)
  return bresult, sresult -- Boolean, error key.
end



-- This should only be called internally to this mod.
function email.send_mail_ex(from, to, subject, message)
	from = rename.grn(from)
	to = rename.grn(to)

	-- Cannot send email if recipient does not exist.
  if not minetest.player_exists(to) then
		return false, "badplayer"
	end
	if string.len(subject) > email.max_subject_length or string.len(message) > email.max_message_length then
		return false, "toobig"
	end
  
  local inboxes = email.get_inbox(to)
  if #inboxes >= email.maxsize then return false, "boxfull" end -- Inbox full.
  
  -- Find a unique ID for this new email.
  ::tryagain::
  local rng = math_random(1, 32000) -- 0 is not a valid ID. Important!
  for k, v in ipairs(inboxes) do
    if v.rng == rng then goto tryagain end
  end
  
  local mail = {
    date = os.date("%Y-%m-%d"),
    from = from,
    msg = message,
    sub = subject,
    rng = rng, -- Random ID unique from all other emails in this inbox.
  }

	-- Keep in-memory cache sychronized with database.
	-- Only if cache already loaded for this target player.
  if email.inboxes[to] then
    table.insert(email.inboxes[to], mail)
	end

	email.store_mail(email.db, to, mail)
  return true, "success" -- Mail successfully sent!
end



function email.on_joinplayer(player)
	local pname = player:get_player_name()
	minetest.after(10, function()
		if passport.player_registered(pname) then
			local inbox = email.get_inbox(pname)
			if #inbox > 0 then
				minetest.chat_send_player(pname,
					"# Server: You have mail (" ..  #inbox .. ")! Use a Key of Citizenship to view it.")
			end
		end
	end)
end



if not email.registered then
	-- load insecure environment
	local secenv = minetest.request_insecure_environment()
	if secenv then
		print("[email] insecure environment loaded.")
		email.sql = secenv.require("lsqlite3")
		assert(email.sql, "lsqlite3 failed to load")
	else
		minetest.log("error", "[email] Failed to load insecure environment," ..
				" please add this mod to the trusted mods list.")
	end

  -- Don't allow other mods to use this global library!
  if sqlite3 then sqlite3 = nil end

	minetest.register_on_shutdown(function(...)
		return email.on_shutdown(...)
	end)

	minetest.register_on_joinplayer(function(...)
		return email.on_joinplayer(...)
	end)

	email.on_startup()
	dofile(email.modpath .. "/hud.lua")

	local c = "email:core"
	local f = email.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	email.registered = true
end
