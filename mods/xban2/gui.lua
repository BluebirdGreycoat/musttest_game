
xban.gui = xban.gui or {}
xban.gui.states = xban.gui.states or {}

local FORMNAME = "xban2:main"
local MAXLISTSIZE = 100

local strfind, format = string.find, string.format

local ESC = minetest.formspec_escape

-- Get records of all registered players.
local function make_list(filter)
	filter = filter or ""
	local list, n, dropped = { }, 0, false
	for index, data in ipairs(xban.db) do
		for name, _ in pairs(data.names) do
			if strfind(name, filter, 1, true) then
				if n >= MAXLISTSIZE then
					dropped = true
					break
				end
				n=n+1 list[n] = name
			end
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
		return nil, ("No entry found for <%s>."):format(rename.gpn(name))
	elseif (not e.record) or (#e.record == 0) then
		return nil, ("Player <%s> has no ban records."):format(rename.gpn(name))
	end
	local record = { }
	for _, rec in ipairs(e.record) do
		local msg = (os.date("%Y-%m-%d %H:%M:%S", rec.time).." | "
				..(rec.reason or "No reason given."))
		table.insert(record, msg)
	end
	return record, e.record
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
	fsn=fsn+1 fs[fsn] = format("textlist[0,1.8;4,8;player;%s;%d;0]",
			table.concat(list, ","), pli)
	local record_name = list[pli]
	if record_name then
		local record, e = get_record_simple(record_name)
		if record then
			for i, r in ipairs(record) do
				record[i] = ESC(r)
			end
			fsn=fsn+1 fs[fsn] = format(
					"textlist[4.2,1.8;11.6,8;entry;%s;%d;0]",
					table.concat(record, ","), ei)
			local rec = e[ei]
			if rec then
				fsn=fsn+1 fs[fsn] = format("label[0,10.3;%s]",
						ESC("Source: "..(rec.source or "<none>")
							.."\nDate: "..os.date("%c", rec.time)
							.."\n"..(rec.expires and
								os.date("Expires: %c", rec.expires) or "")),
						pli)
			end
		else
			fsn=fsn+1 fs[fsn] = "textlist[4.2,1.8;11.6,8;err;"..ESC(e)..";0]"
			fsn=fsn+1 fs[fsn] = "label[0,10.3;"..ESC(e).."]"
		end
	else
		local e = "No entry matches the query."
		fsn=fsn+1 fs[fsn] = "textlist[4.2,1.8;11.6,8;err;"..ESC(e)..";0]"
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
		return
	end
	local state = get_state(name)
	if fields.player then
		local t = minetest.explode_textlist_event(fields.player)
		if (t.type == "CHG") or (t.type == "DCL") then
			state.player_index = t.index
			minetest.show_formspec(name, FORMNAME, make_fs(name))
		end
		return
	end
	if fields.entry then
		local t = minetest.explode_textlist_event(fields.entry)
		if (t.type == "CHG") or (t.type == "DCL") then
			state.entry_index = t.index
			minetest.show_formspec(name, FORMNAME, make_fs(name))
		end
		return
	end
	if fields.search then
		local filter = fields.filter or ""
		state.filter = filter
		state.list = make_list(filter)
		minetest.show_formspec(name, FORMNAME, make_fs(name))
	end
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
