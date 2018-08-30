
command_tokens = command_tokens or {}
command_tokens.mute = command_tokens.mute or {}
command_tokens.mute.players = command_tokens.mute.players or {}
local mute_duration = 60*10 -- Time in seconds.



local formspec = "size[4.1,2.0]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"label[0,0;Need name to mute for " .. mute_duration/60 .. " minutes:]" ..
	"field[0.30,0.75;4,1;PLAYERNAME;;]" ..
	"button_exit[0,1.30;2,1;OK;Confirm]" ..
	"button_exit[2,1.30;2,1;CANCEL;Cancel]" ..
	"field_close_on_enter[PLAYERNAME;false]"



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
        if pointed.type == "object" then
            local object = pointed.ref
            if object and object:is_player() then
                command_tokens.mute.execute(user:get_player_name(), object:get_player_name())
            else
                minetest.chat_send_player(user:get_player_name(), "# Server: Target is not a player!")
            end
        else
            local name = user:get_player_name()
            minetest.show_formspec(name, "command_tokens:mute", formspec)
        end
	end
end



local function unmute_on_timeout(target, rng)
	if command_tokens.mute.players[target] then
		-- This delayed callback only works if rng number matches.
		if command_tokens.mute.players[target] == rng then
			local dname = rename.gpn(target)
			minetest.chat_send_all("# Server: Player <" .. dname .. ">'s chat has been restored.")
			command_tokens.mute.players[target] = nil
		end
	end
end



local function is_valid_target(target)
	if minetest.get_player_by_name(target) then
		if not minetest.check_player_privs(target, {server=true}) then
			return true
		end
	end
end



command_tokens.mute.execute = function(player, target)
	player = rename.grn(player)
	target = rename.grn(target)
	local dname = rename.gpn(target)

	if is_valid_target(target) then
		-- Mute player if they wern't muted, unmute them if they were.
		if not command_tokens.mute.players[target] then
			-- Mark this occurance with an ID that isn't likely to be already in use.
			local rng = math.random(0, 65000)
			command_tokens.mute.players[target] = rng
			minetest.after(mute_duration, unmute_on_timeout, target, rng)
			minetest.chat_send_all("# Server: Player <" .. dname .. ">'s chat has been duct-taped!")

			minetest.log("action", player .. " applies ducktape to " .. target)
		else
			command_tokens.mute.players[target] = nil
			minetest.chat_send_all("# Server: Player <" .. dname .. "> was unmuted.")

			minetest.log("action", player .. " unmutes " .. target)
		end

		-- Consume token.
		minetest.after(0, function() -- Necessary because this code will not operate during the on_use callback.
				local ref = minetest.get_player_by_name(player)
				if ref and ref:is_player() then
						local inv = ref:get_inventory()
						inv:remove_item("main", "command_tokens:mute_player")
				end
		end)
	else
		-- Target not found. Restore the player's marker.
		minetest.chat_send_player(player, "# Server: Player <" .. dname .. "> cannot be silenced.")
	end
end



command_tokens.mute_on_receive_fields = function(player, formname, fields)
	if formname == "command_tokens:mute" then
		if fields.OK then
			command_tokens.mute.execute(player:get_player_name(), fields.PLAYERNAME or "")
		end
	end
end



-- Register once only.
if not command_tokens.mute.registered then
	minetest.register_on_player_receive_fields(function(...)
		return command_tokens.mute_on_receive_fields(...)
	end)
	command_tokens.mute.registered = true
end




