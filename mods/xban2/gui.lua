
xban.gui = xban.gui or {}
xban.gui.states = xban.gui.states or {}

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
								list[#list+1] = name -- Insert real name.
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
					list[#list+1] = name
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

local function make_fs(name)
	local state = get_state(name)
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
	}
	local fsn = #fs

	-- Translate internal player names to display names.
	local nlist = {}
	for k, v in ipairs(list) do
		local dn = rename.gpn(v)
		local rn = rename.grn(v)
		if dn ~= rn then
			nlist[k] = minetest.formspec_escape(dn .. " [" .. rn .. "]")
		else
			nlist[k] = minetest.formspec_escape(rn)
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
				ips[#ips+1] = k -- Is an IP address.
			end
		end
		
		local infomsg = {}
		infomsg[#infomsg+1] = "Other names (" .. #names .. "): {"..table.concat(names, ", ").."}"

		if #ips <= 5 then
			infomsg[#infomsg+1] = "IPs used (" .. #ips .. "): ["..table.concat(ips, " | ").."]"
		else
			infomsg[#infomsg+1] = "IPs used (" .. #ips .. "): DYNAMIC"
		end

		-- last_pos and last_seen are per name, not per record-entry.
		if type(e.last_pos) == "table" and e.last_pos[record_name] then
			infomsg[#infomsg+1] = "User was last seen at " ..
				rc.pos_to_namestr(vector.round(e.last_pos[record_name])) .. "."

			-- We can also add a button to allow the formspec user to jump to this
			-- location.
			fsn=fsn+1 fs[fsn] = "button[13,10.3;3,1;jump;Jump To Last Pos]"
		end
		if type(e.last_seen) == "table" and e.last_seen[record_name] then
			infomsg[#infomsg+1] = "Last login: " ..
				os.date("!%Y/%m/%d, %H:%M:%S UTC", e.last_seen[record_name]) .. "."
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
	local name = player:get_player_name()
	if not minetest.check_player_privs(name, { ban=true }) then
		minetest.log("warning",
				"[xban2] Received fields from unauthorized user: "..name)
		return true
	end
	local state = get_state(name)
	if fields.player then
		local t = minetest.explode_textlist_event(fields.player)
		if (t.type == "CHG") or (t.type == "DCL") then
			state.player_index = t.index
			minetest.show_formspec(name, FORMNAME, make_fs(name))
		end
		return true
	end
	if fields.entry then
		local t = minetest.explode_textlist_event(fields.entry)
		if (t.type == "CHG") or (t.type == "DCL") then
			state.entry_index = t.index
			minetest.show_formspec(name, FORMNAME, make_fs(name))
		end
		return true
	end
	if fields.search then
		local filter = fields.filter or ""
		state.filter = filter
		state.list = make_list(filter)
		minetest.show_formspec(name, FORMNAME, make_fs(name))
	end
	if fields.jump then
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
