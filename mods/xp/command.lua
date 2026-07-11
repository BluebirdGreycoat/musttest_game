
function xp.do_chatcommand(pname, param, ex_params)
	-- Simplify.
	if not ex_params then
		ex_params = {}
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref or not pref:is_player() then
		minetest.chat_send_player(pname, "# Server: You failed the existence test.")
		return
	end

	local function system_response(msg)
		minetest.chat_send_player(pname, "# Server: " .. msg)
	end

	local function system_error(msg)
		minetest.chat_send_player(pname, "# Server: " .. msg)
		easyvend.sound_error(pname)
	end

	local tokens = param:split(" ")
	local verb = (tokens[1] or ""):lower()

	local VALID_XPTYPES = {
		digxp = true,
		buildxp = true,
	}

	local COMMAND_VERBS = {
		get = {
			params = "<character>",
			description = "Query user's current experience points.",
			action = function(pname, param)
				local tokens = param:split(" ")

				if #tokens ~= 1 then
					system_error("Wrong number of arguments.")
					return
				end

				local target = rename.grn(tokens[1])

				if not minetest.player_exists(target) then
					system_error("No such player.")
					return
				end

				local digxp = xp.get_xp(target, "digxp")
				local buildxp = xp.get_xp(target, "buildxp")
				system_response("<" .. rename.gpn(target) .. "> has XP: " .. digxp .. " / " .. buildxp .. ".")
			end,
		},

		set = {
			params = "<character> <digxp|buildxp> <amount>",
			description = "Set user's experience points to a specific amount.",
			action = function(pname, param)
				local tokens = param:split(" ")

				if #tokens ~= 3 then
					system_error("Wrong number of arguments.")
					return
				end

				local target = rename.grn(tokens[1])
				local xptype = tokens[2]
				local amount = tonumber(tokens[3])

				if not minetest.player_exists(target) then
					system_error("No such player.")
					return
				end

				if type(amount) == "nil" then
					system_error("Couldn't parse amount.")
					return
				end

				if not VALID_XPTYPES[xptype] then
					system_error("Invalid XP type.")
					return
				end

				xp.set_xp(target, xptype, amount)

				local digxp = xp.get_xp(target, "digxp")
				local buildxp = xp.get_xp(target, "buildxp")
				system_response("<" .. rename.gpn(target) .. "> now has XP: " .. digxp .. " / " .. buildxp .. ".")
			end,
		},

		add = {
			params = "<character> <digxp|buildxp> <amount>",
			description = "Add or subtract from user's experience points.",
			action = function(pname, param)
				local tokens = param:split(" ")

				if #tokens ~= 3 then
					system_error("Wrong number of arguments.")
					return
				end

				local target = rename.grn(tokens[1])
				local xptype = tokens[2]
				local amount = tonumber(tokens[3])

				if not minetest.player_exists(target) then
					system_error("No such player.")
					return
				end

				if type(amount) == "nil" then
					system_error("Couldn't parse amount.")
					return
				end

				if not VALID_XPTYPES[xptype] then
					system_error("Invalid XP type.")
					return
				end

				-- Add function handles negatives.
				xp.add_xp(target, xptype, amount)

				local digxp = xp.get_xp(target, "digxp")
				local buildxp = xp.get_xp(target, "buildxp")
				system_response("<" .. rename.gpn(target) .. "> now has XP: " .. digxp .. " / " .. buildxp .. ".")
			end,
		},
	}
	COMMAND_VERBS["subtract"] = COMMAND_VERBS["add"]
	COMMAND_VERBS["sub"] = COMMAND_VERBS["add"]
	COMMAND_VERBS["query"] = COMMAND_VERBS["get"]
	COMMAND_VERBS["who"] = COMMAND_VERBS["get"]

	if COMMAND_VERBS[verb] then
		COMMAND_VERBS[verb].action(pname, param:sub(verb:len() + 2):trim())
		return
	end

	if ex_params.show_help then
		system_response("The following sub-commands are available:")
		for verb, def in pairs(COMMAND_VERBS) do
			local args = def.params and def.params ~= "" and (" " .. def.params .. ": ") or ": "
			local desc = def.description or "No description provided."
			system_response("    /" .. ex_params.command_name .. " " .. verb .. args .. desc)
		end

		local helplines = {
			"It is possible to store experience points in Rune Slabs (with a small cost calculated on retrieval).",
			"Be cautious with doing this, however, as anyone can come and steal your precious XP!",
		}

		for _, line in ipairs(helplines) do
			system_response(line)
		end

		return
	end

	system_error("Improper command invocation.")
end
