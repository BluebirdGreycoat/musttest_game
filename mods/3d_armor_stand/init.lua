
-- Localize for performance.
local vector_round = vector.round

local armor_stand_formspec = "size[8,7]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	default.get_hotbar_bg(0,3) ..
	"button[0.5,0.5;2,1;equip;Equip]" ..
	"button[0.5,1.5;2,1;unequip;Unequip]" ..
	"list[context;armor_head;3,0.5;1,1;]" ..
	"list[context;armor_torso;4,0.5;1,1;]" ..
	"list[context;armor_legs;3,1.5;1,1;]" ..
	"list[context;armor_feet;4,1.5;1,1;]" ..
	"list[context;armor_shield;5,1.5;1,1;]" ..
	"image[3,0.5;1,1;3d_armor_stand_head.png]" ..
	"image[4,0.5;1,1;3d_armor_stand_torso.png]" ..
	"image[3,1.5;1,1;3d_armor_stand_legs.png]" ..
	"image[4,1.5;1,1;3d_armor_stand_feet.png]" ..
	"image[5,1.5;1,1;3d_armor_stand_shield.png]" ..
	"list[current_player;main;0,3;8,1;]" ..
	"list[current_player;main;0,4.25;8,3;8]" ..
	"tooltip[equip;Equip this armor.\n\n" ..
	  "If you are already wearing some armor\n" ..
	  "pieces, they will be swapped instead.]" ..
	"tooltip[unequip;Unequip your armor.\n\n" ..
	  "The slots in the armor stand must be\n" ..
	  "free, or the corresponding armor pieces\n" ..
	  "will not be unequipped.]"

local elements = {"head", "torso", "legs", "feet", "shield"}

local function drop_armor(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	for _, element in pairs(elements) do
		local stack = inv:get_stack("armor_"..element, 1)
		if stack and stack:get_count() > 0 then
			armor.drop_armor(pos, stack)
			inv:set_stack("armor_"..element, 1, nil)
		end
	end
end

local function get_stand_object(pos)
	local object = nil
	local objects = minetest.get_objects_inside_radius(pos, 0.5) or {}
	for _, obj in pairs(objects) do
		local ent = obj:get_luaentity()
		if ent then
			if ent.name == "3d_armor_stand:armor_entity" then
				-- Remove duplicates
				if object then
					obj:remove()
				else
					object = obj
				end
			end
		end
	end
	return object
end

local function update_entity(pos)
	local node = minetest.get_node(pos)
	local object = get_stand_object(pos)
	if object then
		if not string.find(node.name, "3d_armor_stand:") then
			object:remove()
			return
		end
	else
		object = minetest.add_entity(pos, "3d_armor_stand:armor_entity")
	end
	if object then
		local texture = "3d_armor_trans.png"
		local textures = {}
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local yaw = 0
		if inv then
			for _, element in pairs(elements) do
				local stack = inv:get_stack("armor_"..element, 1)
				if stack:get_count() == 1 then
					local item = stack:get_name() or ""
					local def = stack:get_definition() or {}
					local groups = def.groups or {}
					if groups["armor_"..element] then
						if def.texture then
							table.insert(textures, def.texture)
						else
							table.insert(textures, item:gsub("%:", "_")..".png")
						end
					end
				end
			end
		end
		if #textures > 0 then
			texture = table.concat(textures, "^")
		end
		if node.param2 then
			local rot = node.param2 % 4
			if rot == 1 then
				yaw = 3 * math.pi / 2
			elseif rot == 2 then
				yaw = math.pi
			elseif rot == 3 then
				yaw = math.pi / 2
			end
		end
		object:set_yaw(yaw)
		object:set_properties({textures={texture}})
	end
end

local function has_locked_armor_stand_privilege(meta, player)
	local name = ""
	if player then
		if minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
		name = player:get_player_name()
	end
	if name ~= meta:get_string("owner") then
		return false
	end
	return true
end

local function add_hidden_node(pos, player)
	local p = {x=pos.x, y=pos.y + 1, z=pos.z}
	local name = player:get_player_name()
	local node = minetest.get_node(p)
	if node.name == "air" and not minetest.is_protected(pos, name) then
		minetest.add_node(p, {name="3d_armor_stand:top"})
	end
end

local function remove_hidden_node(pos)
	local p = {x=pos.x, y=pos.y + 1, z=pos.z}
	local node = minetest.get_node(p)
	if node.name == "3d_armor_stand:top" then
		minetest.remove_node(p)
	end
end

local function on_receive_fields(pos, formname, fields, sender)
	if not sender or not sender:is_player() then
		return
	end

	local node = minetest.get_node(pos)
	local is_locked = nil

	if node.name == "3d_armor_stand:armor_stand" then
		is_locked = false
	elseif node.name == "3d_armor_stand:locked_armor_stand" then
		is_locked = true
	else
		-- Not an armor stand. This should never happen, anyways.
		return
	end

	if fields.quit then
		return
	end

	local name = sender:get_player_name()
	local meta = minetest.get_meta(pos)

	if is_locked and not has_locked_armor_stand_privilege(meta, sender) then
		minetest.chat_send_player(name, "# Server: This armor stand isn't yours.")
		easyvend.sound_error(sender)
		return
	end

	if fields.equip or fields.unequip then

		local inv = meta:get_inventory()
		local pname, player_inv, armor_inv = armor:get_valid_player(sender, "[3d_armor_stand]")

		-- Note: a nil check on pname alone would suffice, as other cases are
		-- already caught (and logged!) by armor:get_valid_player() itself. However,
		-- these additional checks make luacheck happy.
		if not pname or not player_inv or not armor_inv then
			minetest.chat_send_player(name, "# Server: General protection fault! " ..
				"Please, try again or report to admin.")
			return
		end

		-- Working on a list will hopefully make things a little faster, and partly
		-- atomic. This cannot be done with the armor stand own inventory, though,
		-- because it uses a separate inventory list per each group.
		local armor_list = armor_inv:get_list("armor")

		-- The logic is simple. For each existing element (aka, group) we aim to
		-- swap the items in the corresponding slots of the armor stand inventory
		-- and the player's armor inventory. Things are slightly different in the
		-- two cases, though:
		--   - equip: equip the pieces OR swap them if already worn.
		--   - unequip: unequip pieces if there's room in the stand, otherwise skip.

		local swap_count = 0

		for _, element in ipairs(elements) do
			local group = "armor_" .. element
			local stand_stack = inv:get_stack(group, 1)

			if
				fields.unequip and     stand_stack:is_empty() or
				fields.equip   and not stand_stack:is_empty()
			then
				local swap_pos = nil

				-- Search for a wore piece of the same group, and/or an empty slot in
				-- the player's armor inventory.
				for i = 1, #armor_list do
					local armor_stack = armor_list[i]

					if fields.equip and armor_stack:is_empty() then
						if not swap_pos then
							-- First free slot.
							swap_pos = i
						end
					elseif not armor_stack:is_empty() then
						local def = armor_stack:get_definition()
						if def.groups and def.groups[group] then
							-- Slot with a piece with the same group.
							swap_pos = i
							break
						end
					end
				end

				-- If a swap position has been found, swap! Note that the source or
				-- destination slots may be empty item stacks. (But not both, ofc.)
				if swap_pos then
					inv:set_stack(group, 1, armor_list[swap_pos])
					armor_list[swap_pos] = stand_stack
					swap_count = swap_count + 1
				end
			end
		end

		if swap_count == 0 then
			if fields.equip then
				minetest.chat_send_player(name, "# Server: Nothing to equip.")
			else
				minetest.chat_send_player(name, "# Server: Nothing to unequip, or no room on the armor stand.")
			end
		else
			local pieces = swap_count > 1 and "pieces" or "piece"
			local equipd = fields.equip and "equipped" or "unequipped"

			minetest.chat_send_player(name, string.format(
				"# Server: %d armor %s %s.", swap_count, pieces, equipd))

			if fields.equip then
				easyvend.sound_vend(pos)
			else
				easyvend.sound_setup(pos)
			end

			-- Update player's armor inventories (both detached and pinv).
			armor_inv:set_list("armor", armor_list)
			player_inv:set_list("armor", armor_list)

			-- Update player's armor formspec.
			armor:update_inventory(sender)

			-- Actually apply the new armor stats to player.
			armor:set_player_armor(sender)

			-- Update the armor stand entity.
			update_entity(pos)
		end
	end -- fields.equip or fields.unequip
end

minetest.register_node("3d_armor_stand:top", {
	description = "Armor Stand Top",
	paramtype = "light",
	drawtype = "plantlike",
	sunlight_propagates = true,
	walkable = true,
	pointable = false,
	diggable = false,
	buildable_to = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	on_blast = function() end,
	tiles = {"3d_armor_trans.png"},
})

minetest.register_node("3d_armor_stand:armor_stand", {
	description = "Armor Stand",
	drawtype = "mesh",
	mesh = "3d_armor_stand.obj",
	tiles = {"3d_armor_stand.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.4375, -0.25, 0.25, 1.4, 0.25},
			{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
		},
	},
	groups = {choppy=2, oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", armor_stand_formspec)
		meta:set_string("infotext", "Armor Stand")
		local inv = meta:get_inventory()
		for _, element in pairs(elements) do
			inv:set_size("armor_"..element, 1)
		end
		local timer = minetest.get_node_timer(pos)
		timer:start(60*60) -- 1 hour.
	end,
	on_timer = function(pos, elapsed)
		update_entity(pos)
		return true -- Restart timer with same timeout.
	end,
	on_receive_fields = on_receive_fields,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		for _, element in pairs(elements) do
			if not inv:is_empty("armor_"..element) then
				return false
			end
		end
		return true
	end,
	after_place_node = function(pos, placer)
		minetest.add_entity(pos, "3d_armor_stand:armor_entity")
		add_hidden_node(pos, placer)
	end,

	-- Called by rename LBM.
	_on_update_infotext = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", armor_stand_formspec)
		update_entity(pos)
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack)
		local def = stack:get_definition() or {}
		local groups = def.groups or {}
		if groups[listname] then
			return 1
		end
		return 0
	end,
	allow_metadata_inventory_move = function(pos)
		return 0
	end,
	on_metadata_inventory_put = function(pos)
		update_entity(pos)

		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(60*60)
		end
	end,
	on_metadata_inventory_take = function(pos)
		update_entity(pos)

		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(60*60)
		end
	end,
	after_destruct = function(pos)
		update_entity(pos)
		remove_hidden_node(pos)
	end,
	on_blast = function(pos)
		drop_armor(pos)
		armor.drop_armor(pos, "3d_armor_stand:armor_stand")
		minetest.remove_node(pos)
	end,
})

minetest.register_node("3d_armor_stand:locked_armor_stand", {
	description = "Locked Armor Stand",
	drawtype = "mesh",
	mesh = "3d_armor_stand.obj",
	tiles = {"3d_armor_stand_locked.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.4375, -0.25, 0.25, 1.4, 0.25},
			{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
		},
	},
	groups = {choppy=2, oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", armor_stand_formspec)
		meta:set_string("infotext", "Armor Stand")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		for _, element in pairs(elements) do
			inv:set_size("armor_"..element, 1)
		end
		local timer = minetest.get_node_timer(pos)
		timer:start(60*60) -- 1 hour.
	end,
	on_timer = function(pos, elapsed)
		update_entity(pos)
		return true -- Restart timer with same timeout.
	end,
	on_receive_fields = on_receive_fields,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		for _, element in pairs(elements) do
			if not inv:is_empty("armor_"..element) then
				return false
			end
		end
		return true
	end,
	after_place_node = function(pos, placer)
		minetest.add_entity(pos, "3d_armor_stand:armor_entity")
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Armor Stand (Owned by <" .. rename.gpn(meta:get_string("owner")) .. ">!)")
		add_hidden_node(pos, placer)
	end,

	-- Called by rename LBM.
	_on_update_infotext = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", armor_stand_formspec)
		meta:set_string("infotext", "Armor Stand (Owned by <" .. rename.gpn(meta:get_string("owner")) .. ">!)")
		update_entity(pos)
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_armor_stand_privilege(meta, player) then
			return 0
		end
		local def = stack:get_definition() or {}
		local groups = def.groups or {}
		if groups[listname] then
			return 1
		end
		return 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_armor_stand_privilege(meta, player) then
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_move = function(pos)
		return 0
	end,
	on_metadata_inventory_put = function(pos)
		update_entity(pos)

		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(60*60)
		end
	end,
	on_metadata_inventory_take = function(pos)
		update_entity(pos)

		local timer = minetest.get_node_timer(pos)
		if not timer:is_started() then
			timer:start(60*60)
		end
	end,
	after_destruct = function(pos)
		update_entity(pos)
		remove_hidden_node(pos)
	end,
	on_blast = function(pos)
		-- Not affected by TNT
	end,
})

minetest.register_entity("3d_armor_stand:armor_entity", {
	initial_properties = {
		physical = true,
		visual = "mesh",
		mesh = "3d_armor_entity.obj",
		visual_size = {x=1, y=1},
		collisionbox = {0,0,0,0,0,0},
		textures = {"3d_armor_trans.png"},
	},
	_pos = nil,
	on_activate = function(self)
		local pos = self.object:get_pos()
		if pos then
			self._pos = vector_round(pos)
			update_entity(pos)
		end
	end,
	on_blast = function(self, damage)
		local drops = {}
		local node = minetest.get_node(self._pos)
		if node.name == "3d_armor_stand:armor_stand" then
			drop_armor(self._pos)
			self.object:remove()
		end
		return false, false, drops
	end,
})

minetest.register_craft({
	output = "3d_armor_stand:armor_stand",
	recipe = {
		{"", "default:fence_pine_wood", ""},
		{"", "default:fence_pine_wood", ""},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "3d_armor_stand:locked_armor_stand",
	recipe = {
		{"3d_armor_stand:armor_stand", "default:padlock"},
	}
})
