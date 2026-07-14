
if not minetest.global_exists("itemstring") then itemstring = {} end
itemstring.modpath = minetest.get_modpath("itemstring")

function itemstring.handle_command(pname, param)
	local player = minetest.get_player_by_name(pname)
	if not player then return end
	if not player:is_player() then return end

	local stack = player:get_wielded_item()
	if stack:is_empty() then
		minetest.chat_send_player(pname, "# Server: Wielding nothing.")
	else
		local name = stack:get_name()
		local count = stack:get_count()
		local wear = stack:get_wear()
		local mtable = stack:get_meta():to_table()
		local str = dump(mtable) -- "" disables linebreaks and indents.

		-- The reason for all this is because stack:to_string() isn't exactly
		-- human-readable.

		local helplines = {
			"Wielded: " .. utility.get_short_desc(stack) .. " (" .. name ..")",
		}
		if count > 1 or wear > 0 then
			table.insert(helplines, "Stackcount: " .. count .. ", wear: " .. wear)
		end
		if next(mtable.fields or {}) then
			table.insert(helplines, "Meta:")
			local tokens = str:split("\n")
			for _, tok in ipairs(tokens) do
				table.insert(helplines, tok)
			end
		end

		for _, line in ipairs(helplines) do
			minetest.chat_send_player(pname, "# Server: " .. line)
		end
	end
end

function itemstring.handle_command_search(pname, param)
	local player = minetest.get_player_by_name(pname)
	if not player then return end
	if not player:is_player() then return end

	local function response(msg)
		minetest.chat_send_player(pname, "# Server: " .. msg)
	end

	if #param == 0 then
		local count = 0
		for k, v in pairs(minetest.registered_items) do
			count = count + 1
		end

		response("No search term(s) provided.")
		response("There are " .. count .. " registered items.")
		return
	end

	local matching = {}

	for item, _ in pairs(minetest.registered_items) do
		local tokens = param:split("[ _:]", false, -1, true)
		local count = 0

		for _, str in ipairs(tokens) do
			if item:find(str, 1, true) then
				count = count + 1
			end
		end

		if count == #tokens then
			table.insert(matching, item)
		end
	end

	if #matching > 0 then
		response("Found " .. #matching .. " items:")
		local max_report = 0
		local aborted = false

		for _, str in ipairs(matching) do
			response("    " .. str)
			max_report = max_report + 1
			if max_report > 20 then
				aborted = true
				break
			end
		end

		if aborted then
			response("    ... (not showing all items).")
		end
	else
		response("Found no items matching search.")
	end
end

if not itemstring.registered then
	itemstring.registered = true

	minetest.register_privilege("item_info", {
		description = "User can get wielded item info.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("item-string", {
		params = "",
		description = "Get the item-string of a wielded item.",
		privs = {item_info=true},

		func = function(...)
			return itemstring.handle_command(...)
		end
	})

	minetest.register_chatcommand("item-search", {
		params = "<name>",
		description = "Find item-strings of matching registered items.",
		privs = {item_info=true},

		func = function(...)
			return itemstring.handle_command_search(...)
		end
	})

	local c = "itemstring:core"
	local f = itemstring.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
