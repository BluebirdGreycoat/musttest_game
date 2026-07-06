
if not minetest.global_exists("toad") then toad = {} end
toad.modpath = minetest.get_modpath("toad")



local TRANSFORMATION_TIME = 60*60

local ANIMALS = {
	toad = {words={"ribbit", "ibbit", "croak", "ribbit", "croak"}},
	pig = {words={"oink", "oink", "oink", "oink", "oink", "squeal"}},
	snake = {words={"sss", "hisss", "hiss", "iss", "ss"}},
	human = {},
}



function toad.modify_chat(pname, chat)
	local victim = minetest.get_player_by_name(pname)
	if not victim or not victim:is_player() then return chat end

	local toad_type = victim:get_meta():get_string("toad_type")
	local toad_time = tonumber(victim:get_meta():get_string("toad_time"))

	local time = os.time()
	local toad_info = ANIMALS[toad_type]

	if not toad_info then return chat end
	if not toad_info.words then return chat end
	local words = toad_info.words

	if (toad_time + TRANSFORMATION_TIME) > time then
		local tokens = chat:split(" ")
		for k=1, #tokens, 1 do
			tokens[k] = words[math.random(1, #words)]
		end
		chat = table.concat(tokens, " ")
	end

	return chat
end



function toad.is_transformed(pname)
	local victim = minetest.get_player_by_name(pname)
	if not victim or not victim:is_player() then return end

	local toad_type = victim:get_meta():get_string("toad_type")
	local toad_time = tonumber(victim:get_meta():get_string("toad_time"))

	if not toad_time then return end

	local time = os.time()

	if (toad_time + TRANSFORMATION_TIME) > time then
		return true, toad_type
	end
end



function toad.on_chatcommand(pname, param)
	local player = minetest.get_player_by_name(pname)
	if not player or not player:is_player() then return end

	if not passport.player_has_key(pname) then
		minetest.chat_send_player(pname, "# Server: Toading anyone requires a Key of Citizenship.")
		return
	end

	local tokens = param:split(" ")
	if not tokens or #tokens ~= 2 then
		minetest.chat_send_player(pname, "# Server: Invalid command syntax.")
		return
	end

	local target = tokens[1]
	local animal = tokens[2]

	local pref = minetest.get_player_by_name(target)

	if not pref or not pref:is_player() then
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> could not be found.")
		return
	end

	local is_transformed, toad_type = toad.is_transformed(pname)
	if is_transformed and animal ~= "human" then
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> is currently a " .. toad_type .. ".")
		minetest.chat_send_player(pname, "# Server: You'll need to wait for the transformation to wear off.")
		return
	end
	if is_transformed and animal == toad_type then
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> is already a " .. toad_type .. ".")
		return
	end

	if not ANIMALS[animal] then
		minetest.chat_send_player(pname, "# Server: Invalid creature type.")
		return
	end

	pref:get_meta():set_string("toad_type", animal)
	pref:get_meta():set_string("toad_time", tostring(os.time()))

	if target ~= pname then
		minetest.chat_send_player(pname, "# Server: <" .. rename.gpn(target) .. "> is now a " .. animal .. ".")
	end
	minetest.chat_send_player(target, "# Server: It seems you have become a " .. animal .. ".")
end



if not toad.registered then
	minetest.register_chatcommand("toad", {
		params = "<target> <creature>",
		description = "Temporarily turn someone into something unpleasant, or reverse the process.",
		privs = {},
		func = function(pname, param)
			toad.on_chatcommand(pname, param)
			return true
		end,
	})

	reload.register_file("toad:core", toad.modpath .. "/init.lua", false)
	toad.registered = true
end
