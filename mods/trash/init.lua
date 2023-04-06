
if not minetest.global_exists("trash") then trash = {} end
trash.modpath = minetest.get_modpath("trash")

function trash.get_listname()
	return "detached:trash", "main"
end

function trash.get_iconname()
	return "trash_trash_icon.png"
end

function trash.allow_put(inv, listname, index, stack, player)
	if passport.is_passport(stack:get_name()) then
		return 0
	end

	-- Don't allow minegeld to be trashed.
	if minetest.get_item_group(stack:get_name(), "minegeld") ~= 0 then
		return 0
	end

	local stack_count = stack:get_count()

	-- Do not allow trashing of tools that have gained rank.
	if toolranks.get_tool_level(stack) > 1 then
		return 0
	end

	-- Do not allow trashing of items with engraved names.
	if engraver.item_has_custom_description(stack) then
		return 0
	end

	return stack_count
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
		}, true)

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
