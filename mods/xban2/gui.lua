
xban.gui = xban.gui or {}
xban.gui.states = xban.gui.states or {}

-- Localize for performance.
local vector_round = vector.round

local FORMNAME = "xban2:main"
local MAXLISTSIZE = 1000

local strfind, format = string.find, string.format

local ESC = minetest.formspec_escape

-- Get records of all registered players.
local function make_list(filter)
	filter = filter and filter:split(",") or {}
	local list, dropped = { }, false

	-- Trim whitespace from filters.
	for k, v in ipairs(filter) do
		filter[k] = v:trim()
	end

	-- If a filter is chosen, only return filtered items.
	if #filter > 0 then
		for _, data in ipairs(xban.db) do
			for name, _ in pairs(data.names) do
				if not name:find("[%.%:]") then -- No IP addresses.
					for _, fname in ipairs(filter) do
						-- Plaintext search.
						if fname ~= "" then -- Don't search empty filters.
							-- Match real name or alias.
							if strfind(name, fname, 1, true) or strfind(rename.gpn(name), fname, 1, true) then
								if #list > MAXLISTSIZE then
									dropped = true
									goto done
								end

								-- Do not include administrators in the list.
								if not minetest.check_player_privs(name, {server=true}) then
									list[#list+1] = name -- Insert real name.
								end
							end
						end
					end
				end
			end
		end
	else
		for _, data in ipairs(xban.db) do
			for name, _ in pairs(data.names) do
				if not name:find("[%.%:]") then -- No IP addresses.
					if #list > MAXLISTSIZE then
						dropped = true
						goto done
					end

					-- Do not include administrators in the list.
					if not minetest.check_player_privs(name, {server=true}) then
						list[#list+1] = name
					end
				end
			end
		end
	end

	::done::

	-- If filter has more than one entry, remove duplicates in the list.
	if #filter > 1 then
		local klist = {}
		for k, v in ipairs(list) do
			klist[v] = true
		end
		list = {}
		for k, v in pairs(klist) do
			list[#list+1] = k
		end
	end

	table.sort(list)
	return list, dropped
end

local states = xban.gui.states

local function get_state(name)
	local state = states[name]
	if not state then
		state = { index=1, filter="" }
		states[name] = state
		state.list, state.dropped = make_list()
	end
	return state
end

local function get_record_simple(name)
	local e = xban.find_entry(name)

	if not e then
		return nil, {("No entry found for <%s>."):format(rename.gpn(name))}, false
	elseif (not e.record) or (#e.record == 0) then
		return e, {("Player <%s> has no ban records."):format(rename.gpn(name))}, false
	end

	local strings = {}

	-- Assemble ban record strings.
	for _, rec in ipairs(e.record) do
		local msg = (os.date("%Y-%m-%d %H:%M:%S", rec.time).." | "
			..(rec.reason or "No reason given."))
		table.insert(strings, msg)
	end

	return e, strings, true
end

local function sanitize_ipv4(ip)
	if ip:find("::ffff:") then
		ip = ip:sub(8)
	end
	return ip
end

local function get_authdate(authdata)
	local s
	local t = authdata.first_login or 0
	if t ~= 0 then
		s = os.date("!%Y-%m-%d", t)
	else
		-- For a lot of players, first login info was populated from the chatlog.
		-- There's no useable data before this date;
		-- players whos played before the chatlog was added have a first login of 0.
		-- (Check for IS NULL in the SQL database.)
		s = "Pre 2017-07-03"
	end
	return s
end

local function get_account_age(first_login, last_login)
	local diff = last_login - first_login

	local days = math.floor(diff / (60*60*24))
	local months = 0
	local years = 0

	-- This is making me feel stupid.
	while days >= 30 do
		months = months + 1
		days = days - 30
	end
	while months >= 12 do
		years = years + 1
		months = months - 12
	end

	-- Return the result as a string
	return string.format("%d years, %d months, %d days", years, months, days)
end

local function make_fs(pname)
	local state = get_state(pname)
	local list, filter = state.list, state.filter
	local pli, ei = state.player_index or 1, state.entry_index or 0
	if pli > #list then
		pli = #list
	end

	local fs = {
		"size[16,12]",
		default.gui_bg,
		default.gui_bg_img,
		default.gui_slots,
		"label[0,0.02;Filter]",
		"field[1.5,0.33;12.8,1;filter;;"..ESC(filter).."]",
		"button[14,0;2,1;search;Search]",
		"field_close_on_enter[filter;false]",
	}
	local fsn = #fs

	-- Translate internal player names to display names.
	local nlist = {}
	for k, v in ipairs(list) do
		local dn = rename.gpn(v)
		local rn = rename.grn(v)
		local ts = ac.get_total_suspicion(rn)
		if dn ~= rn then
			if ts > 0 then
				nlist[k] = ESC(dn .. " [" .. rn .. "] (" .. ts .. ")")
			else
				nlist[k] = ESC(dn .. " [" .. rn .. "]")
			end
		else
			if ts > 0 then
				nlist[k] = ESC(rn .. " (" .. ts .. ")")
			else
				nlist[k] = ESC(rn)
			end
		end
	end

	fsn=fsn+1 fs[fsn] = format("textlist[0,1.8;4,8;player;%s;%d;0]",
			table.concat(nlist, ","), pli)

	local record_name = list[pli]
	if record_name then
		local e, strings, gotten = get_record_simple(record_name)

		for i, r in ipairs(strings) do
			strings[i] = ESC(r)
		end

		-- Element field name changes based on whether we got a real set of ban records.
		fsn=fsn+1 fs[fsn] = format(
				"textlist[4.2,1.8;11.6,6;" .. (gotten and "entry" or "err") .. ";%s;%d;0]",
				table.concat(strings, ","), ei)

		local rec = e.record[ei]
		if #e.record > 0 then
			-- Ensure a valid record is selected.
			if not rec then
				rec = e.record[1]
				state.entry_index = 1
				ei = 1
			end	

			fsn=fsn+1 fs[fsn] = format("label[0,10.3;%s]",

				ESC("Source: "..(rec.source or "<none>")
					.."\nDate: "..os.date("%c", rec.time)
					.."\n"..(rec.expires and os.date("Expires: %c", rec.expires) or "")
					.."\n"..(e.banned and "Status: Banned!" or "Player is not banned.")),

				pli) -- End format.
		else
			-- No ban records?
			fsn=fsn+1 fs[fsn] = format("label[0,10.3;%s]",
					ESC("Player <" .. rename.gpn(record_name) .. "> has no ban records.")
				) -- End format.
		end

		-- Obtain all alternate names/IPs for this record.
		local names = {}
		local ips = {}
		for k, v in pairs(e.names) do
			if not k:find("[%.%:]") then
				names[#names+1] = rename.gpn(k)
			else
				ips[#ips+1] = sanitize_ipv4(k) -- Is an IP address.
			end
		end
		
		local infomsg = {}

		-- Only the server operator should be able to see this info.
		-- Keep the admin's alt(s) top secret :)
		if minetest.check_player_privs(pname, {server=true}) then
			infomsg[#infomsg+1] = "Other names (" .. #names .. "): {"..table.concat(names, ", ").."}"

			if #ips <= 5 then
				infomsg[#infomsg+1] = "IPs used (" .. #ips .. "): ["..table.concat(ips, " | ").."]"
			else
				infomsg[#infomsg+1] = "IPs used (" .. #ips .. "): DYNAMIC"
			end
		end

		-- last_pos and last_seen are per name, not per record-entry.
		if type(e.last_pos) == "table" and e.last_pos[record_name] then
			infomsg[#infomsg+1] = "User was last seen at " ..
				rc.pos_to_namestr(vector_round(e.last_pos[record_name])) .. "."

			-- We can also add a button to allow the formspec user to jump to this
			-- location.
			if minetest.check_player_privs(pname, {teleport=true}) then
				fsn=fsn+1 fs[fsn] = "button[13,10.3;3,1;jump;Jump To Last Pos]"
			end
		end

		local FIRST_LOGIN
		local LAST_LOGIN

		-- May return nil.
		local authdata = minetest.get_auth_handler().get_auth(record_name)
		if authdata then
			infomsg[#infomsg+1] = "First login: " .. get_authdate(authdata) .. "."

			if (authdata.first_login or 0) ~= 0 then
				FIRST_LOGIN = authdata.first_login
			end
			if (authdata.last_login or 0) ~= 0 then
				LAST_LOGIN = authdata.last_login
			end
		end

		if type(e.last_seen) == "table" and e.last_seen[record_name] then
			infomsg[#infomsg+1] = "Last login: " ..
				os.date("!%Y-%m-%d, %H:%M:%S UTC", e.last_seen[record_name]) .. "."
		end

		local time_NOW = os.time()
		if FIRST_LOGIN and time_NOW > FIRST_LOGIN then
			infomsg[#infomsg+1] = "Account age: " .. get_account_age(FIRST_LOGIN, time_NOW) .. "."
		end

		if sheriff.is_cheater(record_name) then
			infomsg[#infomsg+1] = "Player is a registered cheater/hacker."
		elseif sheriff.is_suspected_cheater(record_name) then
			infomsg[#infomsg+1] = "Player is a suspected cheater!"
		end

		for k, v in ipairs(infomsg) do
			infomsg[k] = ESC(v)
		end
		fsn=fsn+1 fs[fsn] = "textlist[4.2,8.0;11.6,1.8;info;"..table.concat(infomsg, ",")..";0]"
	else
		local e = "No entry matches the query."
		fsn=fsn+1 fs[fsn] = "textlist[4.2,1.8;11.6,6;err;"..ESC(e)..";0]"
		fsn=fsn+1 fs[fsn] = "textlist[4.2,8.0;11.6,1.8;info;;0]"
		fsn=fsn+1 fs[fsn] = "label[0,10.3;"..ESC(e).."]"
	end
	return table.concat(fs)
end

function xban.gui.on_receive_fields(player, formname, fields)
	if formname ~= FORMNAME then return end
	local pname = player:get_player_name()
	if not minetest.check_player_privs(pname, { ban=true }) then
		minetest.log("warning", "[xban2] Received fields from unauthorized user: " .. pname)
		return true
	end
	local state = get_state(pname)

	if fields.player then
		local t = minetest.explode_textlist_event(fields.player)
		if (t.type == "CHG") or (t.type == "DCL") then
			state.player_index = t.index
			minetest.show_formspec(pname, FORMNAME, make_fs(pname))
		end
		return true
	end

	if fields.entry then
		local t = minetest.explode_textlist_event(fields.entry)
		if (t.type == "CHG") or (t.type == "DCL") then
			state.entry_index = t.index
			minetest.show_formspec(pname, FORMNAME, make_fs(pname))
		end
		return true
	end

	if fields.key_enter_field == "filter" or fields.search then
		local filter = fields.filter or ""
		state.filter = filter
		state.list = make_list(filter)
		minetest.show_formspec(pname, FORMNAME, make_fs(pname))
	end

	if fields.jump and minetest.check_player_privs(pname, {teleport=true}) then
		local list = state.list
		local pli = state.player_index or 1
		if pli > #list then
			pli = #list
		end
		local record_name = list[pli]
		if record_name then
			local e, strings, gotten = get_record_simple(record_name)
			if type(e.last_pos) == "table" and e.last_pos[record_name] then
				local pos = vector_round(table.copy(e.last_pos[record_name]))
				minetest.chat_send_player(pname,
					"# Server: Teleporting to <" .. rename.gpn(record_name) ..
					">'s last known exit position at " .. rc.pos_to_namestr(pos) .. ".")
				rc.notify_realm_update(pname, pos)
				player:set_pos(pos)
			end
		end
	end

	return true
end

function xban.gui.chatcommand(name, params)
	minetest.show_formspec(name, FORMNAME, make_fs(name))
end

if not xban.gui.registered then
	minetest.register_on_player_receive_fields(function(...)
		return xban.gui.on_receive_fields(...)
	end)

	minetest.register_chatcommand("xban_gui", {
		description = "Show XBan GUI.",
		params = "",
		privs = { ban=true, },
		func = function(...)
			return xban.gui.chatcommand(...)
		end,
	})

	xban.gui.registered = true
end
