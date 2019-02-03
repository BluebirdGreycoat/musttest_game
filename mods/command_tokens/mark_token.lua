
command_tokens = command_tokens or {}
command_tokens.mark = command_tokens.mark or {}
command_tokens.mark.players = command_tokens.mark.players or {}



local formspec = "size[4.1,2.0]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"label[0,0;Type name of person to mark:]" ..
	"field[0.30,0.75;4,1;PLAYERNAME;;]" ..
	"button_exit[0,1.30;2,1;OK;Confirm]" ..
	"button_exit[2,1.30;2,1;CANCEL;Cancel]" ..
	"field_close_on_enter[PLAYERNAME;false]"



command_tokens.mark.player_marked = function(player)
	if command_tokens.mark.players[player] then
		return true
	else
		return false
	end
end



-- Called when the player uses a marker token.
command_tokens.mark.mark_player = function(itemstack, user, pointed)
	if user and user:is_player() then
		if pointed.type == "object" then
			local object = pointed.ref
			if object and object:is_player() then
				command_tokens.mark.execute(user:get_player_name(), object:get_player_name())
			else
				minetest.chat_send_player(user:get_player_name(), "# Server: Target is not a player!")
			end
		else
			local name = user:get_player_name()
			minetest.show_formspec(name, "command_tokens:mark", formspec)
		end
	end
end



local function is_valid_target(name, target)
	if minetest.get_player_by_name(target) then
		if gdac_invis.is_invisible(target) == true then return end

		if name == target then
			return true -- Player can always mark self.
		end
        
		if not minetest.check_player_privs(target, {server=true}) then
			return true
		end
	end
end



command_tokens.mark.execute = function(player, target)
	player = rename.grn(player)
	target = rename.grn(target)
	local dname = rename.gpn(target)

	if is_valid_target(player, target) then
		local p1 = minetest.get_player_by_name(player)
		local p2 = minetest.get_player_by_name(target)

		if rc.same_realm(p1, p2) then
			-- Mark player if they wern't marked, unmark them if they were.
			if not command_tokens.mark.players[target] then
				command_tokens.mark.players[target] = true
				minetest.chat_send_all("# Server: Player <" .. dname .. "> has been marked!")
			else
				command_tokens.mark.players[target] = nil
				minetest.chat_send_all("# Server: Player <" .. dname .. "> was unmarked.")
			end

			-- Consume token.
			minetest.after(0, function() -- Necessary because this code will not operate during the on_use callback.
				local ref = minetest.get_player_by_name(player)
				if ref and ref:is_player() then
					local inv = ref:get_inventory()
					inv:remove_item("main", "command_tokens:mark_player")
				end
			end)
		else
			minetest.chat_send_player(player, "# Server: Target is in another dimension!")
		end
	else
		minetest.chat_send_player(player, "# Server: Player <" .. dname .. "> cannot be marked.")
	end
end




command_tokens.mark_on_receive_fields = function(player, formname, fields)
	if formname == "command_tokens:mark" then
		if fields.OK then
			command_tokens.mark.execute(player:get_player_name(), fields.PLAYERNAME)
		end
	end
end



-- Register once only.
if not command_tokens.mark.registered then
	minetest.register_on_player_receive_fields(function(...)
		return command_tokens.mark_on_receive_fields(...)
	end)
	command_tokens.mark.registered = true
end




