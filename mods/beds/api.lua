
-- Localize for performance.
local vector_round = vector.round

local reverse = true

local function destruct_bed(pos, n)
	local node = minetest.get_node(pos)
	local other

	if n == 2 then
		local dir = minetest.facedir_to_dir(node.param2)
		other = vector.subtract(pos, dir)
	elseif n == 1 then
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner") or ""
    if owner ~= "" and owner ~= "server" then
			if beds.spawn[owner] then
				local p1 = vector_round(pos)
				local p2 = vector_round(beds.spawn[owner])
				if vector.equals(p1, p2) then
					beds.spawn[owner] = nil
					beds.save_spawns()
					beds.storage:set_int(owner .. ":count", 0)

					chat_core.alert_player_sound(owner)
					local RED = core.get_color_escape_sequence("#ff0000")
					minetest.chat_send_player(owner, RED .. "# Server: Your primary bed is destroyed. Your home position is LOST!")
				else
					minetest.chat_send_player(owner, "# Server: A secondary bed owned by you was destroyed.")
				end
			else
				minetest.chat_send_player(owner, "# Server: A bed owned by you was destroyed, but you had no home position set.")
			end
    end
    
		local dir = minetest.facedir_to_dir(node.param2)
		other = vector.add(pos, dir)
	end

	if reverse then
		reverse = not reverse
		minetest.remove_node(other)
		minetest.check_for_falling(other)
	else
		reverse = not reverse
	end
end

function beds.register_bed(name, def)
	minetest.register_node(name .. "_bottom", {
		description = def.description,
		inventory_image = def.inventory_image,
		wield_image = def.wield_image,
		drawtype = "nodebox",
		tiles = def.tiles.bottom,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		stack_max = 1,
		groups = utility.dig_groups("furniture", {flammable = 3, bed = 1, immovable = 1}),
		sounds = def.sounds or default.node_sound_wood_defaults(),
		node_box = {
			type = "fixed",
			fixed = def.nodebox.bottom,
		},
		selection_box = {
			type = "fixed",
			fixed = def.selectionbox,
		},
    
		on_place = function(itemstack, placer, pointed_thing)
			if not placer or not placer:is_player() then
				return itemstack
			end

			local under = pointed_thing.under
      local node = minetest.get_node(under)
			local udef = minetest.reg_ns_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end

			local pos
			if minetest.registered_items[minetest.get_node(under).name].buildable_to then
				pos = under
			else
				pos = pointed_thing.above
			end

			if minetest.is_protected(pos, placer:get_player_name()) then
				minetest.record_protection_violation(pos, placer:get_player_name())
				return itemstack
			end

			local node_def = minetest.reg_ns_nodes[
				minetest.get_node(pos).name]
			if not node_def or not node_def.buildable_to then
				return itemstack
			end

			local dir = minetest.dir_to_facedir(placer:get_look_dir())
			local botpos = vector.add(pos, minetest.facedir_to_dir(dir))

			if minetest.is_protected(botpos, placer:get_player_name()) then
				minetest.record_protection_violation(botpos, placer:get_player_name())
				return itemstack
			end

			local botdef = minetest.reg_ns_nodes[
				minetest.get_node(botpos).name]
			if not botdef or not botdef.buildable_to then
				return itemstack
			end

			minetest.add_node(pos, {name = name .. "_bottom", param2 = dir})
			minetest.add_node(botpos, {name = name .. "_top", param2 = dir})

			-- If player is holding 'E', then bed shall be public.
			do
				local control = placer:get_player_control()
				if control.aux1 then
					local meta = minetest.get_meta(pos)
					meta:set_string("owner", "server") -- "server" is a reserved name.
					meta:mark_as_private("owner")
					meta:set_string("infotext", "Public Bed")
				end
			end

			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,

    on_destruct = function(pos)
      destruct_bed(pos, 1)
    end,

		-- TNT+beds=problems.
    on_blast = function(pos) end,

		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			beds.on_rightclick(pos, clicker)
			return itemstack
		end,

		on_rotate = function(pos, node, user, mode, new_param2)
			local dir = minetest.facedir_to_dir(node.param2)
			local p = vector.add(pos, dir)
			local node2 = minetest.get_node_or_nil(p)
			if not node2 or not minetest.get_item_group(node2.name, "bed") == 2 or
					not node.param2 == node2.param2 then
				return false
			end
			if minetest.is_protected(p, user:get_player_name()) then
				minetest.record_protection_violation(p, user:get_player_name())
				return false
			end
			if mode ~= screwdriver.ROTATE_FACE then
				return false
			end
			local newp = vector.add(pos, minetest.facedir_to_dir(new_param2))
			local node3 = minetest.get_node_or_nil(newp)
			local node_def = node3 and minetest.reg_ns_nodes[node3.name]
			if not node_def or not node_def.buildable_to then
				return false
			end
			if minetest.is_protected(newp, user:get_player_name()) then
				minetest.record_protection_violation(newp, user:get_player_name())
				return false
			end
			node.param2 = new_param2
			-- do not remove_node here - it will trigger destroy_bed()
			minetest.swap_node(p, {name = "air"})
			minetest.swap_node(pos, node) -- Do not remove meta.
			minetest.add_node(newp, {name = name .. "_top", param2 = new_param2})
			return true
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(pos)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			-- Nobody placed this block.
			if owner == "" or owner == "server" then
				return
			end
			local dname = rename.gpn(owner)

			meta:set_string("rename", dname)
			meta:mark_as_private("rename")
			meta:set_string("infotext", "Bed (Owned by <" .. dname .. ">!)")
		end,
	})

	minetest.register_node(name .. "_top", {
		drawtype = "nodebox",
		tiles = def.tiles.top,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		pointable = false,
		groups = utility.dig_groups("furniture", {oddly_breakable_by_hand = 1, flammable = 3, bed = 2, immovable = 1}),
		sounds = def.sounds or default.node_sound_wood_defaults(),
		drop = name .. "_bottom",
		node_box = {
			type = "fixed",
			fixed = def.nodebox.top,
		},
		on_destruct = function(pos)
			destruct_bed(pos, 2)
		end,

		-- TNT+beds=problems.
		on_blast = function(pos) end,
	})

	minetest.register_alias(name, name .. "_bottom")

	minetest.register_craft({
		output = name,
		recipe = def.recipe
	})
end
