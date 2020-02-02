
rename = rename or {}
rename.modpath = minetest.get_modpath("rename")



-- Make sure a chosen name is valid.
-- We don't want players picking names that are impossible.
function rename.validate_name(dname)
	if string.len(dname) > 20 then
		return false
	end
	if string.find(dname, "^[%w_]+$") then
		return true
	end
end



-- API function. Renames a player (validates, but costs nothing).
-- Returns success if the rename is valid.
-- First argument must be the player's real name.
-- Second argument must be the chosen alt.
function rename.rename_player(pname, dname, tell)
	-- Rout chat messages to 'tell'.
	-- If undefined then route chat messages to 'pname'.
	if not tell then
		tell = pname
	end

	-- Don't rename non-existent players.
	-- This avoids creating alias for players that don't yet exist.
	-- Doing so prevents real players from logging in with that name.
	if not minetest.player_exists(pname) then
		return
	end

	-- If the new alias is the same as the old alias, do nothing.
	if dname == rename.gpn(pname) then
		minetest.chat_send_player(tell, "# Server: You are already called <" .. dname .. ">!")
		easyvend.sound_error(tell)
		return
	end

	-- Remove name from storage if it's the same as the original, internal name.
	-- This has to come before the impersonation checks, otherwise
	-- players would never be able to change their names back to the original.
	if dname == pname then
		local oname = rename.gpn(pname)
		local lname = string.lower(oname)
		-- Clear both keys: realname --> nick, and nick --> realname.
		rename.modstorage:set_string(pname .. ":org", nil)
		rename.modstorage:set_string(oname .. ":alt", nil)
		rename.modstorage:set_string(lname .. ":low", nil)

		-- Only send a chat message about it if the new alias
		-- is different from the old alias.
		if oname ~= dname then
			minetest.chat_send_all("# Server: Player <" .. oname .. "> renamed to <" .. pname .. ">!")
		end

		-- Update player's nametag if needed.
		player_labels.update_nametag_text(pname)

		return true
	end

	-- The new alias is *not* the same as the player's original name.
	-- This means we need to record the change (after a few more checks).

	-- Use the anticurse name-checker.
	-- This returns a string if the name would be rejected.
	local check = anticurse.on_prejoinplayer(dname)
	if type(check) == "string" then
		minetest.chat_send_player(tell, "# Server: " .. check)
		easyvend.sound_error(tell)
		return
	end

	-- Check if a name similar to this exists.
	local lname = string.lower(dname)
	local uname = rename.modstorage:get_string(lname .. ":low")
	if uname and uname ~= "" then
		-- Players are allowed to change the capitalization of their own alt name.
		if uname ~= pname then
			minetest.chat_send_player(tell, "# Server: Another name differing only in letter-case is already allocated by someone else.")
			easyvend.sound_error(tell)
			return
		end
	end

	-- Check the auth database to ensure players cannot choose names that are already allocated.
	do
		local get_auth = minetest.get_auth_handler().get_auth
		assert(type(get_auth) == "function")
		local check_name = minetest.get_auth_handler().check_similar_name
		assert(type(check_name) == "function")

		-- Check auth table to see if an entry with this exact name already exists.
		if get_auth(dname) ~= nil then
			minetest.chat_send_player(tell, "# Server: That name is currently allocated by someone else.")
			easyvend.sound_error(tell)
			return
		end

		-- Search the auth table to see if there is already a similar name.
		local names = check_name(dname)
		for k, v in pairs(names) do
			if v:lower() == lname then
				-- Players are allowed to chose names that differ in case from their original.
				if v:lower() ~= pname then
					minetest.chat_send_player(tell, "# Server: That name or a similar one is already allocated!")
					easyvend.sound_error(tell)
					return
				end
			end
		end
	end

	-- Don't allow impersonation.
	if minetest.player_exists(dname) or minetest.get_player_by_name(dname) then
		minetest.chat_send_player(tell, "# Server: That name is currently allocated by someone else.")
		easyvend.sound_error(tell)
		return
	end

	-- Check if name is valid.
	if not rename.validate_name(dname) then
		minetest.chat_send_player(tell, "# Server: Chosen name is invalid for use as a nick!")
		easyvend.sound_error(tell)
		return
	end

	-- Get player's old alt-name, if they had one.
	local cname = rename.gpn(pname)

	-- Add name to storage.
	-- There are two keys, realname --> nick, and nick --> realname.
	-- This allows us to obtain either name.
	-- We make a distinction between original names and alts with a postfix.
	-- This is necessary to prevent getting them confused.
	rename.modstorage:set_string(pname .. ":org", dname)
	rename.modstorage:set_string(dname .. ":alt", pname)
	rename.modstorage:set_string(string.lower(dname) .. ":low", pname)

	-- The old alt must be removed. This prevents corruption.
	rename.modstorage:set_string(cname .. ":alt", nil)
	rename.modstorage:set_string(string.lower(cname) .. ":low", nil)

	minetest.chat_send_all("# Server: Player <" .. cname .. "> is reidentified as <" .. dname .. ">!")

	-- Update player's nametag if needed.
	player_labels.update_nametag_text(pname)

	local player = minetest.get_player_by_name(pname)
	if player then
		player:set_properties({
			infotext = rename.gpn(pname),
		})
	end

	return true
end



-- Get a player's display-name.
-- Just returns their original name if no alias has been stored.
-- This function has a shortname for ease of use.
-- Note: this function may be called in contexts where the player is not online.
function rename.get_player_name(pname)
	-- nil check.
	if not pname or pname == "" then
		return ""
	end

	local dname = rename.modstorage:get_string(pname .. ":org")
	if not dname or dname == "" then
		return pname
	end
	return dname
end
rename.gpn = rename.get_player_name



-- Obtain a player's real name, if passed an alias name.
-- If passed a player's real name, it is simply returned.
-- This is the opposite of the previous function.
function rename.get_real_name(name)
	local pname = rename.modstorage:get_string(name .. ":alt")
	if pname and pname ~= "" then
		-- The alias is registered, so return the real name it links to.
		return pname
	end
	-- No alias? Then return our argument as the real name.
	return name
end
rename.grn = rename.get_real_name



-- Called from on_prejoinplayer (from the AC mod).
-- This prevents players from joining with already-allocated names.
-- This function assumes the given name is an alt to check for.
function rename.name_currently_allocated(dname)
	local pname = rename.modstorage:get_string(dname .. ":alt")
	if pname and pname ~= "" then
		-- A real name is associated with this alt, which means this
		-- alt name must be considered allocated, too.
		return true
	end
	local lname = string.lower(dname)
	pname = rename.modstorage:get_string(lname .. ":low")
	if pname and pname ~= "" then
		-- A capitialized form of this name exists, so this name too
		-- must be considered allocated. The only difference is case.
		return true
	end
end



-- This is the function players should have access to.
-- It performs cost validation.
function rename.purchase_rename(pname, dname)
	-- Get player.
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end

	dname = string.trim(dname)
	if #dname < 1 then
		minetest.chat_send_player(pname, "# Server: No nickname specified.")
		easyvend.sound_error(pname)
		return
	end

	-- The cost is ...
	local cost = "survivalist:copper_skill_token"

	-- Check if player can pay.
	local inv = player:get_inventory()
	if not inv:contains_item("main", cost) then
		minetest.chat_send_player(pname, "# Server: Changing your nickname costs 1 Copper Skill Mark (earned by completing an Iceworld Challenge).")
		minetest.chat_send_player(pname, "# Server: Have a Copper Skill Mark in your main inventory before running this command.")
		easyvend.sound_error(pname)
		return
	end

	if rename.rename_player(pname, dname) then
		-- Take cost, rename was successful.
		inv:remove_item("main", cost)
		minetest.chat_send_player(pname, "# Server: 1 Copper Skill Mark taken!")
		return
	end

	-- Something went wrong.
	minetest.chat_send_player(pname, "# Server: Name not changed, you are still called <" .. rename.gpn(pname) .. ">! No cost taken.")
	easyvend.sound_error(pname)
end



function rename.execute_whoami(pname)
	minetest.chat_send_player(pname, "# Server: You are recognized as <" .. rename.grn(pname) .. ">.")
end



help_info =
	"===| Charter Regulations For Aliases |===\n\n" ..

	"All people registered as Citizens of the Colony have the lawful opportunity " ..
	"(with conditions) to change the name that is shown to other Citizens, be it " ..
	"shown through communication channels and in avatar-to-avatar meetings. If you " ..
	"wish to change your name (which is here, and in other places, refered to as " ..
	"your Alias) then do read the following carefully. You will need to scroll the " ..
	"text.\n\n" ..

	"To discourage missuse of this capability, the Colony Controler requires a " ..
	"payment of 1 Copper Skill Token before Citizens are allowed to change their " ..
	"official alias. A Citizen earns these tokens by proving their determination " ..
	"and skill by successfully completing the Iceworld Challenge. A Citizen may " ..
	"change their Alias as many times as they can afford to do so; however be " ..
	"warned that this can confuse others.\n\n" ..

	"When you change your Alias, it will be used in all your communication as seen " ..
	"by other Citizens and non-citizens, including the main chat. You may or may " ..
	"not be able to observe this change yourself, depending on the date of your " ..
	"client's software.\n\n" ..

	"When you choose an Alias, the Alias which you choose becomes a second name, " ..
	"with as much lawful authority as the first. You will continue to have access " ..
	"to all your protected land, and to any shared locations which other Citizens " ..
	"may have shared with you. You will continue to own this second name (along " ..
	"with your first) until you release it by choosing another. While you own your " ..
	"Alias, no one else may claim that Alias, or any similar to it in terms of " ..
	"capitalization. Also, no one may enter the Colony with that name or any name " ..
	"similar to it (again, in terms of capitalization). Other Citizens may send you " ..
	"E-Mail using your Alias, and use bounty marks or gag orders or jailers on you, " ..
	"also using your Alias. Other Citizens may send you PMs using your Alias. Any new land you " ..
	"protect and items you own will continue to be protected under your original " ..
	"identification, which cannot be changed.\n\n" ..

	"No Alias can be the same as another player's identification or other Alias. No " ..
	"two players may have the same Alias at once. A Citizen can have only one Alias " ..
	"at a time, making a max total of two names per Citizen. When a Citizen chooses " ..
	"an Alias, any previous Alias they may have owned becomes free for another " ..
	"Citizen to claim. Using an Alias does not override the original name, and a " ..
	"Citizen's original name may still be used in communication by other players " ..
	"and in shares and in commands.\n\n" ..

	"If you change your Alias, you must do so with the understanding that this does " ..
	"NOT change your login credentials. You must still login to the server using " ..
	"your ORIGINAL player name!\n\n" ..

	"===| End Charter Alias Regulations |==="



-- Compost the GUI formspec.
function rename.compose_formspec(pname)
  local formspec = ""
  formspec = formspec .. "size[8,7]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..

    "label[0,0;Alias Registration]" ..
		"textarea[0.3,0.5;8,3;info;;" .. minetest.formspec_escape(help_info) .. "]" ..
		"field[0.3,4;4,1;alias;Write New Legal Alias;]" ..
    "button[0,6.2;3,1;choose;Recognize Alias]" ..
    "label[0,5.2;Your registered alias is <" .. rename.gpn(pname) .. ">.]" ..
		"label[0,5.6;Your legal identification is <" .. pname .. ">.]" ..
    "button[6,6.2;2,1;close;Close]"

  return formspec
end



-- API function (called from passport mod, for instance).
function rename.show_formspec(pname)
  local formspec = rename.compose_formspec(pname)
  minetest.show_formspec(pname, "rename:rename", formspec)
end



-- GUI form input handler.
function rename.on_receive_fields(player, formname, fields)
  local pname = player:get_player_name()
  if formname ~= "rename:rename" then
    return
  end

	if fields.quit then
		return true
	end

	if fields.choose then
		rename.purchase_rename(pname, fields.alias)
		minetest.close_formspec(pname, "rename:rename")
		return true
	end

  if fields.close then
		-- Go back to the KoC control panel.
    passport.show_formspec(pname)
    return true
  end

  return true
end



if not rename.run_once then
	rename.modstorage = minetest.get_mod_storage()

	-- Override engine functions.
	dofile(rename.modpath .. "/overrides.lua")

  minetest.register_chatcommand("nickname", {
    params = "<new nickname>",
    description = "Pay an in-game fee and change your own name.",
    privs = {interact=true},
    func = function(pname, param)
      rename.purchase_rename(pname, param)
      return true
    end,
  })

  minetest.register_chatcommand("realnick", {
    params = "",
    description = "Find out the name the sever knows you by (not a nick).",
    privs = {interact=true},
    func = function(pname, param)
      rename.execute_whoami(pname)
      return true
    end,
  })

  minetest.register_chatcommand("whoami", {
    params = "",
    description = "Find out the name the sever knows you by (not a nick).",
    privs = {interact=true},
    func = function(pname, param)
      rename.execute_whoami(pname)
      return true
    end,
  })

	-- TODO: the rename algorithm should only be called on punch or access of a node.
	--[==[
	minetest.register_lbm({
		label = "Rename Owned Nodes",
		nodenames = {
			"group:protector",
			"city_block:cityblock",
			"mailbox:mailbox",
			"group:bed",
			"group:chest",
			"group:door",
			"group:trapdoor",
			"teleports:teleport",
			"group:vending",
			"circular_saw:circular_saw",
			"itemframes:frame",
			"itemframes:pedestal",
		},
		name = "rename:update_node_owner",
		run_at_every_load = false,
		--once_per_session = true,
		action = function(pos)
			-- Spread the action out over many frames.
			minetest.after(math.random(10, 600) / 10, function()
				-- Get the node anew.
				local node = minetest.get_node(pos)
				-- If it has a rename handler, execute it.
				local def = minetest.registered_items[node.name]
				if def and def._on_rename_check then
					def._on_rename_check(pos)
					--minetest.chat_send_player("MustTest", "# Server: Renaming '" .. node.name .. "' @ " .. minetest.pos_to_string(pos) .. "!")
				end
			end)
		end,
	})
	--]==]

  -- GUI input handler.
  minetest.register_on_player_receive_fields(function(...)
    return rename.on_receive_fields(...)
  end)

	local c = "rename:core"
	local f = rename.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	rename.run_once = true
end
