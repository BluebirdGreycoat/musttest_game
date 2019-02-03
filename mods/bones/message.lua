-- This module is responsible for informing players of someone's death.
-- We also inform the dead player where their bones are.
-- We also write a message to the logfile.

bones = bones or {}
bones.players = bones.players or {}



local release_player = function(player)
	if bones.players[player] then
		bones.players[player] = nil
	end
end
bones.release_player = release_player



local send_chat_world = function(pos, player)
	-- Don't spam the message console.
	if bones.players[player] then return end

	local show_everyone = true
	if player_labels.query_nametag_onoff(player) == false then
		show_everyone = false
	end

	if show_everyone then
		local dname = rename.gpn(player)
		minetest.chat_send_all("# Server: Blackbox detected. Player <" .. dname .. "> perished in the " ..
			rc.pos_to_name(pos) .. " at " .. rc.pos_to_string(pos) .. ".")
	else
		minetest.chat_send_all("# Server: Blackbox detected. ID and location unknown.")
		minetest.chat_send_player(player, "# Server: You died in the " ..
			rc.pos_to_name(pos) .. " at " .. rc.pos_to_string(pos) ..
			". Your blackbox locator signal is SUPPRESSED.")
	end

	minetest.chat_send_player(player, "# Server: <" .. rename.gpn(player) .. ">, you may find your blackbox at the above coordinates.")

	-- The player can't trigger any more chat messages until released.
	bones.players[player] = true
	minetest.after(60, release_player, player)
end



bones.do_messages = function(pos, player, num_stacks)
	send_chat_world(pos, player)
	minetest.log("action", "Player <" .. player .. "> died at (" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "): stackcount=" .. num_stacks)
end


