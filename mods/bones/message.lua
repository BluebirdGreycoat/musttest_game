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
			"<" .. dname .. "> " .. random_str(msg_str2) .. " at " .. rc.pos_to_namestr(pos) .. ".")
	else
		minetest.chat_send_all("# Server: " .. random_str(msg_str1) .. " detected. ID and location unknown.")
		minetest.chat_send_player(player, "# Server: You died at " .. rc.pos_to_namestr(pos) .. ". The locator beacon was SUPPRESSED.")
	end

	minetest.chat_send_player(player, "# Server: <" .. rename.gpn(player) .. ">, you may find your bonebox at the above coordinates.")

	-- The player can't trigger any more chat messages until released.
	bones.players[player] = true
	minetest.after(60, release_player, player)
end



bones.do_messages = function(pos, player, num_stacks)
	send_chat_world(pos, player)
	minetest.log("action", "Player <" .. player .. "> died at (" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "): stackcount=" .. num_stacks)
end


