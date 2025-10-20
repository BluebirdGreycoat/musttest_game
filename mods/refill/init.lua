
if not minetest.global_exists("refill") then refill = {} end
refill.modpath = minetest.get_modpath("refill")


function refill.refill_all(pname)
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end
	local inv = player:get_inventory()
	local sz = inv:get_size("main")
	local total = 0
	for i = 1, sz, 1 do
		local stack = inv:get_stack("main", i)
		local count = stack:get_count()
		local max = stack:get_stack_max()
		if count > 0 and count < max then
			stack:set_count(max)
			inv:set_stack("main", i, stack)
			total = total + 1
		end
	end
	minetest.chat_send_player(pname, "# Server: " .. total .. " inventory stack(s) refilled.")
end



function refill.refill_single(pname)
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end
	local stack = player:get_wielded_item()
	local count = stack:get_count()
	local max = stack:get_stack_max()
	if count > 0 and count < max then
		stack:set_count(max)
		player:set_wielded_item(stack)
		minetest.chat_send_player(pname, "# Server: Stack refilled.")
	else
		minetest.chat_send_player(pname, "# Server: Nothing to do.")
		easyvend.sound_error(pname)
	end
end



if not refill.run_once then
	minetest.register_privilege("refill", {
		description = "User is allowed infinite item stacks.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("refill", {
		params = "[all]",
		description = "Refill item stacks to max capacity.",
		privs = {refill = true},

		func = function(pname, param)
			param = string.trim(param)
			if param == "all" then
				refill.refill_all(pname)
				return true
			end
			refill.refill_single(pname)
			return true
		end,
	})

	local c = "refill:core"
	local f = refill.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	refill.run_once = true
end
