
function player.set_big_hotbar(pref)
	pref:hud_set_hotbar_image("gui_hotbar2.png")
	pref:hud_set_hotbar_itemcount(16)
end



function player.set_small_hotbar(pref)
	pref:hud_set_hotbar_image("gui_hotbar.png")
	pref:hud_set_hotbar_itemcount(8)
end



-- Called from chatcommand.
function player.toggle_hotbar_size(pname, param)
	if sheriff.is_cheater(pname) then
		minetest.chat_send_player(pname, "# Server: You b'cheatan. :-)")
		return
	end

	local pref = minetest.get_player_by_name(pname)
	local meta = pref:get_meta()

	if meta:get_int("show_big_hotbar") == 1 then
		player.set_small_hotbar(pref)
		minetest.chat_send_player(pname, "# Server: Switched to 8-slot hotbar.")
		meta:set_int("show_big_hotbar", 0)
	else
		player.set_big_hotbar(pref)
		minetest.chat_send_player(pname, "# Server: Switched to 16-slot hotbar.")
		meta:set_int("show_big_hotbar", 1)
	end
end



minetest.register_chatcommand("hotbar", {
	params = "",
	description = "Toggle between 8 and 16 slot hotbar.",
	privs = {big_hotbar=true},

	func = function(...)
		player.toggle_hotbar_size(...)
		return true
	end,
})
