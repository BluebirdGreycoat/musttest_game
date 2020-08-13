
clear_inventory = clear_inventory or {}
clear_inventory.modpath = minetest.get_modpath("clear_inventory")

function clear_inventory.clear_primary_inventories(player)
	local inv = player:get_inventory()

	inv:set_list("craft", {})
	inv:set_list("craftpreview", {})
	inv:set_list("craftresult", {})

	local main = inv:get_list("main")
	for k, v in ipairs(main) do
		if not passport.is_passport(v:get_name()) then
			v:set_count(0)
			v:set_name("")
		end
	end

	inv:set_list("main", main)
	map.update_inventory_info(player:get_player_name())
end

function clear_inventory.clear(name, param)
	local player

	if not param or param == "" then
		player = minetest.get_player_by_name(name)
	elseif param and param ~= "" then
		player = minetest.get_player_by_name(param)
	else
		return
	end

	if not player then
		minetest.chat_send_player(name, "# Server: Player not found!")
		return
	end

	-- Actually clear the player's inventory!
	clear_inventory.clear_primary_inventories(player)
	
	-- Report to player.
	minetest.chat_send_player(name, "# Server: Player <" .. rename.gpn(player:get_player_name()) .. ">'s inventory cleared!")
end

if not clear_inventory.registered then
	minetest.register_privilege("clear_inventory", {
		description = "Player can trash all items in their inventory.",
		give_to_singleplayer = false,
	})

	minetest.register_chatcommand("clearinv", {
		params = "";
		description = "Clear your inventory or another player's inventory.",
		privs = {clear_inventory=true},

		func = function(...)
			return clear_inventory.clear(...)
		end,
	})

	local c = "clear_inventory:core"
	local f = clear_inventory.modpath .. "/init.lua"
	reload.register_file(c, f, false)
	
	clear_inventory.registered = true
end


