
-- The idea here is to completely wrap all chat commands, both existing ones and
-- those to be registered in the future, with a function that intercepts their
-- return values and deals with them.

local function wrap_commands()
	local data = minetest.registered_chatcommands

	for k, v in pairs(data) do
		local old = v.func
		v.func = function(...)
			local result, message = old(...)
			if message and message ~= "" then
				message = "# Server: " .. message
			end
			-- The *builtin* will send the message via core.chat_send_player.
			return result, message
		end
	end
end

-- Execute action after startup.
minetest.after(0, wrap_commands)
