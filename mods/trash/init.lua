
trash = trash or {}
trash.modpath = minetest.get_modpath("trash")

function trash.get_listname()
	return "detached:trash", "main"
end

function trash.get_iconname()
	return "trash_trash_icon.png"
end

function trash.allow_put(inv, listname, index, stack, player)
	if stack:get_name() == "passport:passport" then
		return 0
	end

	return stack:get_count()
end

function trash.on_put(inv, to_list, to_index, stack, player)
	local stack = inv:get_stack(to_list, to_index)

	inv:set_stack(to_list, to_index, ItemStack(nil))

	if player and player:is_player() then
		local pos = player:get_pos()
		-- Play a trash sound. Let other players hear it.
		minetest.sound_play("trash_trash", {
			gain=1.0,
			pos=pos,
			max_hear_distance=16,
		})

		minetest.log("action", player:get_player_name() .. " trashes " ..
			"\"" .. stack:get_name() .. " " .. stack:get_count() .. "\"" ..
			" using inventory trash slot.")
	end
end

if not trash.registered then
	local inv = minetest.create_detached_inventory("trash", {
		allow_put = function(...)
			return trash.allow_put(...)
		end,

		on_put = function(...)
			return trash.on_put(...)
		end,
	})

	inv:set_size("main", 1)

	local c = "trash:core"
	local f = trash.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	trash.registered = true
end
