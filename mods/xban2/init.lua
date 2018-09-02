
xban = xban or {}
xban.db = xban.db or {}
xban.tempbans = xban.tempbans or {}
xban.MP = minetest.get_modpath("xban2")

-- Reloadable.
dofile(xban.MP.."/serialize.lua")

local DEF_SAVE_INTERVAL = 300 -- 5 minutes
local DEF_DB_FILENAME = minetest.get_worldpath().."/xban.db"

local DB_FILENAME = minetest.settings:get("xban.db_filename")
local SAVE_INTERVAL = tonumber(
  minetest.settings:get("xban.db_save_interval")) or DEF_SAVE_INTERVAL

if (not DB_FILENAME) or (DB_FILENAME == "") then
	DB_FILENAME = DEF_DB_FILENAME
end

local function make_logger(level)
	return function(text, ...)
		minetest.log(level, "[xban] "..text:format(...))
	end
end

local ACTION = make_logger("action")
local WARNING = make_logger("warning")

local unit_to_secs = {
	s = 1, m = 60, h = 3600,
	D = 86400, W = 604800, M = 2592000, Y = 31104000,
	[""] = 1,
}

local function parse_time(t) --> secs
	local secs = 0
	for num, unit in t:gmatch("(%d+)([smhDWMY]?)") do
		secs = secs + (tonumber(num) * (unit_to_secs[unit] or 1))
	end
	return secs
end

function xban.find_entry(player, create) --> entry, index
	for index, e in ipairs(xban.db) do
		for name in pairs(e.names) do
			if name == player then
				return e, index
			end
		end
	end
	if create then
		ACTION("Created new entry for `%s'", player)
		local e = {
			names = { [player]=true },
			banned = false,
			record = { },
			last_pos = { },
			last_seen = { },
		}
		table.insert(xban.db, e)
		return e, #xban.db
	end
	return nil
end

function xban.get_info(player) --> ip_name_list, banned, last_record
	local e = xban.find_entry(player)
	if not e then
		return nil, "No such entry."
	end
	return e.names, e.banned, e.record[#e.record]
end

function xban.ban_player(player, source, expires, reason) --> bool, err
	if xban.get_whitelist(player) then
		return nil, "Player is whitelisted; remove from whitelist first!"
	end
	local e = xban.find_entry(player, true)
	if e.banned then
		return nil, "Player already banned."
	end
	if minetest.check_player_privs(player, {server=true}) then
		return nil, "Administrators cannot be banned!"
	end
	local rec = {
		source = source,
		time = os.time(), -- Date of ban.
		expires = expires,
		reason = reason,
	}
	table.insert(e.record, rec)
	e.names[player] = true
	local pl = minetest.get_player_by_name(player)
	if pl then
		local ip = minetest.get_player_ip(player)
		if ip then
			e.names[ip] = true
		end
		e.last_pos[player] = pl:get_pos()
	end
	e.reason = reason
	e.time = rec.time
	e.expires = expires
	e.banned = true
	local msg
	local date = (expires and os.date("%c", expires)
	  or "The End of Time")
	if expires then
		table.insert(xban.tempbans, e)
		msg = ("Banned: Expires: %s, Reason: %s"):format(date, reason)
	else
		msg = ("Banned: Reason: %s"):format(reason)
	end
	for nm in pairs(e.names) do
		minetest.kick_player(nm, msg)
	end
	ACTION("%s bans %s until %s for reason: %s", source, player,
	  date, reason)
	ACTION("Banned Names/IPs: %s", table.concat(e.names, ", "))
	return true
end

function xban.unban_player(player, source) --> bool, err
	local e = xban.find_entry(player)
	if not e then
		return nil, "No such entry."
	end
	if not e.banned then
		return nil, "Player not banned."
	end
	local rec = {
		source = source,
		time = os.time(),
		reason = "Unbanned",
	}
	table.insert(e.record, rec)
	e.banned = false
	e.reason = nil
	e.expires = nil
	e.time = nil
	ACTION("%s unbans %s", source, player)
	ACTION("Unbanned Names/IPs: %s", table.concat(e.names, ", "))
	return true
end

function xban.get_whitelist(name_or_ip)
	return xban.db.whitelist and xban.db.whitelist[name_or_ip]
end

function xban.remove_whitelist(name_or_ip)
	if xban.db.whitelist then
		xban.db.whitelist[name_or_ip] = nil
	end
end

function xban.add_whitelist(name_or_ip, source)
	local wl = xban.db.whitelist
	if not wl then
		wl = { }
		xban.db.whitelist = wl
	end
	wl[name_or_ip] = {
		source=source,
	}
	return true
end

function xban.get_record(player)
	local e = xban.find_entry(player)
	if not e then
		return nil, ("No entry for <%s>."):format(rename.gpn(player))
	elseif (not e.record) or (#e.record == 0) then
		return nil, ("<%s> has no ban records."):format(rename.gpn(player))
	end
	local record = { }
	for _, rec in ipairs(e.record) do
		local msg = rec.reason and ("Reason: '" .. rec.reason .. "'") or "No reason given"
		if rec.expires then
			msg = msg..(", Expires: %s"):format(os.date("%c", e.expires))
		end
		if rec.source then
			msg = msg..", Source: '"..rec.source.."'"
		end
		table.insert(record, ("[%s]: %s."):format(os.date("%c", e.time), msg))
	end
	local last_pos
	if e.last_pos and e.last_pos[player] then
		last_pos = ("User was last seen at %s."):format(
		  minetest.pos_to_string(vector.round(e.last_pos[player])))
	end
	return record, last_pos
end

function xban.on_prejoinplayer(name, ip)
	if minetest.check_player_privs(name, {server=true}) then
		return
	end
	local wl = xban.db.whitelist or { }
	if wl[name] or wl[ip] then return end
	local e = xban.find_entry(name) or xban.find_entry(ip)
	if not e then return end
	if e.banned then
		local date = (e.expires and os.date("%c", e.expires) or "The End of Time")
		return ("\nBanned!\nExpires: %s\nReason: %s"):format(date, e.reason)
	end
end

function xban.on_joinplayer(player)
	local name = player:get_player_name()
	local e = xban.find_entry(name)
	local ip = minetest.get_player_ip(name)
	if not e then
		-- Don't create database entries for players who never registered.
		-- This keeps the database size limited to only those players who
		-- decided to play on the server for a while. Guests are not included.
		if ip and passport.player_registered(name) then
			e = xban.find_entry(ip, true)
		else
			return
		end
	end
	e.names[name] = true
	if ip then
		e.names[ip] = true
	end
	e.last_seen = os.time()
end

function xban.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()

	-- Don't record last_pos for temporary accounts.
	if not passport.player_registered(pname) then
		return
	end

	local e = xban.find_entry(pname)
	if e then
		e.last_pos[pname] = player:get_pos()
	end
end

function xban.chatcommand_ban(name, params)
	local plname, reason = params:match("^(%S+)%s+(.+)$")
	if not (plname and reason) then
		minetest.chat_send_player(name, "# Server: Usage: '/xban <player> <reason>'.")
		return false
	end
	reason = reason:trim()
	local ok, e = xban.ban_player(plname, rename.gpn(name), nil, reason)
	local msg = ("# Server: Banned <%s>."):format(rename.gpn(plname))
	if not ok then
		msg = "# Server: " .. e
	end
	minetest.chat_send_player(name, msg)
	return ok
end

function xban.chatcommand_tempban(name, params)
	local plname, time, reason = params:match("^(%S+)%s+(%S+)%s+(.+)$")
	if not (plname and time and reason) then
		minetest.chat_send_player(name, "# Server: Usage: '/xtempban <player> <time> <reason>'.")
		return false
	end
	time = parse_time(time)
	if time < 60 then
		minetest.chat_send_player(name, "# Server: You must ban for at least 60 seconds.")
		return false
	end
	reason = reason:trim()
	local expires = os.time() + time
	local ok, e = xban.ban_player(plname, rename.gpn(name), expires, reason)
	local msg = ("# Server: Banned <%s> until %s."):format(rename.gpn(plname), os.date("%c", expires))
	if not ok then
		msg = "# Server: " .. e
	end
	minetest.chat_send_player(name, msg)
	return ok
end

function xban.chatcommand_xunban(name, params)
	local plname = params:match("^%S+$")
	if not plname or plname == "" then
		minetest.chat_send_player(name, "# Server: Usage: '/xunban <player>|<ip>'.")
		return
	end
	local ok, e = xban.unban_player(plname, rename.gpn(name))
	local msg = ("# Server: Unbanned <%s>."):format(rename.gpn(plname))
	if not ok then
		msg = "# Server: " .. e
	end
	minetest.chat_send_player(name, msg)
	return ok
end

function xban.chatcommand_record(name, params)
	local plname = params:match("^%S+$")
	if not plname or plname == "" then
		minetest.chat_send_player(name, "# Server: Usage: '/xban_record <player>|<ip>'.")
		return false
	end
	local record, last_pos = xban.get_record(plname)
	if not record then
		local err = last_pos
		minetest.chat_send_player(name, "# Server: [xban]: "..err)
		return
	end
	for _, e in ipairs(record) do
		minetest.chat_send_player(name, "# Server: [xban]: "..e)
	end
	if last_pos then
		minetest.chat_send_player(name, "# Server: [xban]: "..last_pos)
	end
	minetest.chat_send_player(name, "# Server: [xban]: End of record.")
	return true
end

function xban.chatcommand_wl(name, params)
	local cmd, plname = params:match("^%s*(%S+)%s*(%S+)%s*$")
	if not cmd or cmd == "" then
		minetest.chat_send_player(name, "# Server: Usage: '/xban_wl (add|del|get) <name>|<ip>'.")
		return false
	end
	if not plname or plname == "" then
		minetest.chat_send_player(name, "# Server: Usage: '/xban_wl (add|del|get) <name>|<ip>'.")
		return false
	end
	if cmd == "add" then
		xban.add_whitelist(plname, rename.gpn(name))
		ACTION("%s adds %s to whitelist", name, plname)
		minetest.chat_send_player(name, "# Server: Added <"..rename.gpn(plname).."> to whitelist!")
		return true
	elseif cmd == "del" then
		xban.remove_whitelist(plname)
		ACTION("%s removes %s to whitelist", name, plname)
		minetest.chat_send_player(name, "# Server: Removed <"..rename.gpn(plname).."> from whitelist!")
		return true
	elseif cmd == "get" then
		local e = xban.get_whitelist(plname)
		if e then
			minetest.chat_send_player(name, "# Server: Source: "..(e.source and ("'"..e.source.."'") or "Unknown")..".")
			return true
		else
			minetest.chat_send_player(name, "# Server: No whitelist for <"..rename.gpn(plname)..">!")
			return true
		end
	end
end

function xban.check_temp_bans()
	minetest.after(60, function() xban.check_temp_bans() end)
	local to_rm = { }
	local now = os.time()
	for i, e in ipairs(xban.tempbans) do
		if e.expires and (e.expires <= now) then
			table.insert(to_rm, i)
			e.banned = false
			e.expires = nil
			e.reason = nil
			e.time = nil
		end
	end
	for _, i in ipairs(to_rm) do
		table.remove(xban.tempbans, i)
	end
end

function xban.save_db()
	minetest.after(SAVE_INTERVAL, function() xban.save_db() end)
	local f, e = io.open(DB_FILENAME, "wt")
	xban.db.timestamp = os.time()
	if f then
		local ok, err = f:write(xban.serialize(xban.db))
		if not ok then
			WARNING("Unable to save database: %s", err)
		end
	else
		WARNING("Unable to save database: %s", e)
	end
	if f then f:close() end
	return
end

function xban.load_db()
	local f, e = io.open(DB_FILENAME, "rt")
	if not f then
		WARNING("Unable to load database: %s", e)
		return
	end
	local cont = f:read("*a")
	if not cont then
		WARNING("Unable to load database: %s", "Read failed")
		return
	end
	local t, e2 = minetest.deserialize(cont)
	if not t then
		WARNING("Unable to load database: %s",
		  "Deserialization failed: "..(e2 or "unknown error"))
		return
	end

	local function is_vector(data)
		local count = 0
		if type(data) == "table" then
			for k, v in pairs(data) do
				count = count + 1
			end
		end
		if count ~= 3 then
			return false
		end
		if type(data) == "table"
			and type(data.x) == "number"
			and type(data.y) == "number"
			and type(data.z) == "number"
			and count == 3 then
			return true
		end
		return false
	end

	-- Update DB format. Remove entries that are in an old, invalid format.
	for k, v in ipairs(t) do
		if type(v.last_seen) ~= "nil" and type(v.last_seen) ~= "table" then
			v.last_seen = nil
		end
		if type(v.last_pos) ~= "nil" and is_vector(v.last_pos) then
			v.last_pos = nil
		end

		-- Add empty tables for missing elements.
		if not v.last_pos then
			v.last_pos = {}
		end
		if not v.last_seen then
			v.last_seen = {}
		end
	end

	xban.db = t
	xban.tempbans = {}

	for _, entry in ipairs(xban.db) do
		if entry.banned and entry.expires then
			table.insert(xban.tempbans, entry)
		end
	end
end

if not xban.registered then
	minetest.register_on_joinplayer(function(...)
		return xban.on_joinplayer(...)
	end)

	minetest.register_on_prejoinplayer(function(...)
		return xban.on_prejoinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return xban.on_leaveplayer(...)
	end)

	minetest.register_chatcommand("xban_wl", {
		description = "Manages the XBan whitelist.",
		params = "(add|del|get) <name>|<ip>",
		privs = { ban=true },
		func = function(...)
			return xban.chatcommand_wl(...)
		end,
	})

	minetest.register_chatcommand("xban_record", {
		description = "Show the ban records of a player.",
		params = "<player>|<ip>",
		privs = { ban=true },
		func = function(...)
			return xban.chatcommand_record(...)
		end,
	})

	minetest.register_chatcommand("xunban", {
		description = "XUnban a player.",
		params = "<player>|<ip>",
		privs = { ban=true },
		func = function(...)
			return xban.chatcommand_xunban(...)
		end,
	})

	minetest.register_chatcommand("xtempban", {
		description = "XBan a player temporarily.",
		params = "<player> <time> <reason>",
		privs = { ban=true },
		func = function(...)
			return xban.chatcommand_tempban(...)
		end,
	})

	minetest.register_chatcommand("xban", {
		description = "XBan a player.",
		params = "<player> <reason>",
		privs = { ban=true },
		func = function(...)
			return xban.chatcommand_ban(...)
		end,
	})

	minetest.register_on_shutdown(function(...) return xban.save_db(...) end)
	minetest.after(SAVE_INTERVAL, function() xban.save_db() end)
	minetest.after(1, function() xban.check_temp_bans() end)

	xban.load_db()

	local c = "xban:core"
	local f = xban.MP .. "/init.lua"
	reload.register_file(c, f, false)

	xban.registered = true
end

-- Reloadable.
dofile(xban.MP.."/dbimport.lua")
dofile(xban.MP.."/gui.lua")
