-- This module is responsible for informing players of someone's death.
-- We also inform the dead player where their bones are.
-- We also write a message to the logfile.

if not minetest.global_exists("bones") then bones = {} end
bones.players = bones.players or {}

-- Localize for performance.
local math_random = math.random



local release_player = function(player)
	if bones.players[player] then
		bones.players[player] = nil
	end
end
bones.release_player = release_player

local msg_str1 = {
	"Blackbox",
	"Blackbox",

	"Bonebox",
	"Bonebox",
	"Bonebox",

	"Death signal",
	"Blackbox signal",
	"Bonebox signal",

	"Death beacon",
	"Blackbox beacon",
	"Bonebox beacon",

	"Ritual box",
	"Corpse",
	"Coffin",
}
local msg_str2 = {
	"perished",
	"perished",
	"perished",

	"died",
	"died",
	"died",

	"kicked the bucket",
	"kicked the bucket",

	"was killed",
	"was slain",
	"lost a life",
	"croaked",
	"bit the dust",
	"passed away",
	"passed on",

	"expired",
	"expired",

	"did something fatal",
	"became honestly dead",
	"became somewhat dead",
	"became mostly dead",
	"was involved in a fatal occurrence",
	"had a fatal accident",
	"is honestly dead",
	"is completely dead",
	"is mostly dead",
	"passed out (permanently)",
	"is somewhat dead",
	"suffered corporeal malfunction",
	"gave up the ghost",
	"gave up on life",
	"failed survival lessons",
	"threw out the book",
	"met the grim reaper",
	"ended life",

	"met a sticky end",
	"met a horrid end",
	"met a terrifying end",
}
local function random_str(strs)
	return strs[math_random(1, #strs)]
end



local send_chat_world = function(pos, player)
	-- Don't spam the message console.
	if bones.players[player] then return end

	local show_everyone = true
	if player_labels.query_nametag_onoff(player) == false then
		show_everyone = false
	end
	if cloaking.is_cloaked(player) then
		show_everyone = false
	end

	if show_everyone then
		local dname = rename.gpn(player)
		minetest.chat_send_all("# Server: " .. random_str(msg_str1) .. " detected. " ..
			"<" .. dname .. "> " .. random_str(msg_str2) .. " at " .. rc.pos_to_namestr_ex(pos) .. ".")
	else
		minetest.chat_send_all("# Server: " .. random_str(msg_str1) .. " detected. ID and location unknown.")
	end

	-- Print this on the next server step, to ensure it is printed AFTER any other
	-- messages that should be printed first.
	minetest.after(0, function()
		minetest.chat_send_player(player, "# Server: You died at " .. rc.pos_to_namestr_ex(pos) .. ".")

		if fortress.can_teleport_at(pos) then
			minetest.chat_send_player(player,
				"# Server: Find your bone-loot at the above coordinates.")
		end
	end)

	-- The player can't trigger any more chat messages until released.
	bones.players[player] = true
	minetest.after(60, release_player, player)

	return show_everyone
end



bones.do_messages = function(pos, player, num_stacks)
	minetest.log("action", "Player <" .. player .. "> died at (" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "): stackcount=" .. num_stacks)
	return send_chat_world(pos, player)
end



-- Note: this is not called if the player is cloaked or their ID is off.
function bones.death_reason(pname, reason)
	local dname = rename.gpn(pname)

	--minetest.chat_send_all('message dump: ' .. dump(reason))

	-- WARNING: do not do if reason.type == "punch", that will create a bug!

	if reason.type == "fall" then
		minetest.chat_send_all("# Server: <" .. dname .. "> fell.")
	elseif reason.type == "drown" then
		minetest.chat_send_all("# Server: <" .. dname .. "> drowned.")
	elseif reason.reason == "node_damage" then
		-- Note: the engine's builtin 'reason.type' is not used here, because the
		-- armor code nulifies it and converts it to a punch.

		if reason.source_node then
			local ndef = minetest.registered_nodes[reason.source_node]
			if ndef and ndef._death_message then
				local msg = ndef._death_message

				if type(msg) == "table" then
					msg = msg[math.random(1, #msg)]
				elseif type(msg) == "function" then
					msg = msg()
				end

				-- Assume message is string.
				if type(msg) == "string" then
					msg = msg:gsub("<player>", "<" .. dname .. ">")
					minetest.chat_send_all("# Server: " .. msg)
				end
			end
		end
	end
end


