
if not minetest.global_exists("command_tokens") then command_tokens = {} end
command_tokens.mute = command_tokens.mute or {}
command_tokens.mute.players = command_tokens.mute.players or {}
local mute_duration = 60*10 -- Time in seconds.

-- Localize for performance.
local math_random = math.random



local formspec = "size[4.1,2.0]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"label[0,0;Need name to mute for " .. mute_duration/60 .. " minutes:]" ..
	"field[0.30,0.75;4,1;PLAYERNAME;;]" ..
	"button_exit[0,1.30;2,1;OK;Confirm]" ..
	"button_exit[2,1.30;2,1;CANCEL;Cancel]" ..
	"field_close_on_enter[PLAYERNAME;true]"



command_tokens.mute.player_muted = function(player)
	if command_tokens.mute.players[player] then
		return true
	else
		return false
	end
end



-- Called when the player uses a marker token.
command_tokens.mute.mute_player = function(itemstack, user, pointed)
	if user and user:is_player() then
		local pname = user:get_player_name()

		if pointed.type == "object" then
			local object = pointed.ref
			if object and object:is_player() then
				local success = command_tokens.mute.execute(
					pname, object:get_player_name())

				if success then
					itemstack:take_item()
					return itemstack
				end
			else
				minetest.chat_send_player(pname, "# Server: Target is not a player!")
			end
		else
			minetest.show_formspec(pname, "command_tokens:mute", formspec)
		end
	end
end



local function unmute_on_timeout(target, rng)
	if command_tokens.mute.players[target] then
		-- This delayed callback only works if rng number matches.
		if command_tokens.mute.players[target] == rng then
			if minetest.get_player_by_name(target) then
				-- Player online.
				local dname = rename.gpn(target)
				minetest.chat_send_all("# Server: Player <" .. dname .. ">'s chat has been restored.")
				command_tokens.mute.players[target] = nil
			else
				-- Player offline.
				if command_tokens.mute.players[target] ~= 0 then
					local dname = rename.gpn(target)
					local str = skins.get_gender_strings(target)
					minetest.chat_send_all("# Server: Cannot remove ducktape from <" .. dname ..
						"> because " .. str.he .. "'s offline.")
				end

				command_tokens.mute.players[target] = 0
				minetest.after(mute_duration, unmute_on_timeout, target, 0)
			end
		end
	end
end



local function is_valid_target(target)
	if minetest.get_player_by_name(target) then
		if not minetest.check_player_privs(target, {server=true}) and
				not minetest.check_player_privs(target, {nomute=true}) then
			return true
		end
	end
end



command_tokens.mute.execute = function(player, target, chatcommand)
	player = rename.grn(player)
	target = rename.grn(target)
	local dname = rename.gpn(target)

	if is_valid_target(target) then
		-- Ensure player has a mute token in their inventory.
		local pref = minetest.get_player_by_name(player)
		local pinv = pref:get_inventory()
		local stack = ItemStack("command_tokens:mute_player")

		if chatcommand or pinv:contains_item("main", stack) then
			-- Mute player if they wern't muted, unmute them if they were.
			if not command_tokens.mute.players[target] then
				-- Mark this occurance with an ID that isn't likely to be already in use.
				-- Note: 0 has special meaning, must not be used as a random ID!
				local rng = math_random(1, 65000)
				command_tokens.mute.players[target] = rng
				minetest.after(mute_duration, unmute_on_timeout, target, rng)
				minetest.chat_send_all("# Server: Player <" .. dname .. ">'s chat has been duct-taped!")

				minetest.log("action", player .. " applies ducktape to " .. target)
			else
				command_tokens.mute.players[target] = nil
				minetest.chat_send_all("# Server: Player <" .. dname .. "> was unmuted.")

				minetest.log("action", player .. " unmutes " .. target)
			end

			-- Caller must consume token.
			return true
		else
			minetest.chat_send_player(player, "# Server: Error. Invalid usage.")
		end
	else
		-- Target not found.
		minetest.chat_send_player(player, "# Server: Player <" .. dname .. "> cannot be silenced.")
	end
end



command_tokens.mute_on_receive_fields = function(player, formname, fields)
	if formname == "command_tokens:mute" then
		if fields.key_enter_field == "PLAYERNAME" or fields.OK then
			local pname = player:get_player_name()

			local success = command_tokens.mute.execute(
				pname, fields.PLAYERNAME or "")

			if success then
				local inv = player:get_inventory()
				if inv then
					inv:remove_item("main", "command_tokens:mute_player")
				end
			end
		end
	end
end



-- Register once only.
if not command_tokens.mute.registered then
	minetest.register_on_player_receive_fields(function(...)
		return command_tokens.mute_on_receive_fields(...)
	end)

	minetest.register_privilege("nomute", {
		description = "Player is immune to being muted.",
		give_to_singleplayer = false,
	})

	command_tokens.mute.registered = true
end




