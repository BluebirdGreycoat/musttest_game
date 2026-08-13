
falling.register_callback("after_killed_player", "falling", function(params)
	local pname = params.pname
	local dname = rename.gpn(pname)
	local chat = minetest.chat_send_all
	chat(("# Server: <%s> was crushed to death."):format(dname))
end)
