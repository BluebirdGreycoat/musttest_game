
city_block.register_callback("on_access_borough_control", "cityblock", function(params)
	minetest.chat_send_all('testing: ' .. dump(params))
end)
