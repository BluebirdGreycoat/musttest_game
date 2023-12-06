
-- This is a cleanroom reimplementation of the GPL "anvil" mod commonly found
-- lying around. This reimplementation is developed from memory of how the anvil
-- worked in-game, and through in-game behavior testing of THIS implementation
-- as it was being developed. This mod is provided under the MIT license.
--
-- Disclosure notice: by "cleanroom implementation", I (MustTest) declare that
-- all code in this init.lua file was written WITHOUT REFERENCE to the code
-- in the original anvil mod. Thus, this file is my own, separate expression of
-- the concept of an anvil in Minetest. Certain similarities are required to
-- achieve drop-in compatibility, they are as follows: the node name
-- "anvil:anvil". The hammer name "anvil:hammer". The entity name "anvil:item",
-- the metadata inventory list name, "input", and finally the group name
-- "not_repaired_by_anvil".

if not minetest.global_exists("anvil") then anvil = {} end
anvil.modpath = minetest.get_modpath("anvil")

-- Place entity exactly on anvil surface.
-- Search for entities inside anvil node ONLY.
anvil.entity_offset = {x=0, y=0.15, z=0}
anvil.entity_radius = 0.45



-- Check protection, check access rights.
function anvil.player_can_use(pos, player)
	local pname = player:get_player_name()
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if owner == "" then
		return true
	end

	-- Note: this is really only effective if anvil is ALSO inside protection.
	if owner == pname then
		return true
	end

	-- Player can use the anvil if not protected, even if they aren't owner.
	-- This also lets anvils be shared, by sharing the protection.
	if not minetest.test_protection(pos, pname) then
		return true
	end

	return false
end



-- Check if itemstack is a hammer.
function anvil.is_hammer(itemstack)
	if itemstack:is_empty() then
		return false
	end

	local sn = itemstack:get_name()
	if sn == "anvil:hammer" or sn == "xdecor:hammer" then
		return true
	end

	return false
end



-- Apply wear to the hammer.
function anvil.wear_hammer(pos, stack)
	if stack:is_empty() then
		return stack
	end

	local uses = {
		["anvil:hammer"] = 1000,
		["xdecor:hammer"] = 100,
	}

	local sdef = stack:get_definition()
	if sdef and uses[stack:get_name()] then
		stack:add_wear_by_uses(uses[stack:get_name()])

		if stack:is_empty() then
			if sdef.sounds and sdef.sounds.breaks then
				ambiance.sound_play(sdef.sounds.breaks, pos, 1.0, 16)
			end
		end
	end

	return stack
end



-- Check whether itemstack is repairable by anvils.
function anvil.item_repairable_or_craftable(itemstack)
	if minetest.get_item_group(itemstack:get_name(), "not_repaired_by_anvil") ~= 0 then
		return false
	end

	-- Must NOT have a 'wear_represents' key, that means wear is NOT durability.
	local idef = minetest.registered_items[itemstack:get_name()]
	if idef and idef.wear_represents then
		return false
	end

	-- Allow stuff that's used in anvil recipes.
	if minetest.get_craft_result({
				method = "anvil",
				width = 1,
				items = {itemstack}
			}).time ~= 0 then
		return true
	end

	if minetest.registered_tools[itemstack:get_name()] then
		return true
	end

	return false
end



-- Do craft action.
function anvil.craft_something(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	if meta:get_int("strike") >= 1 then
		return false
	end

	for index = 1, inv:get_size("input"), 1 do
		local stack = inv:get_stack("input", index)
		local craft, aftercraft = minetest.get_craft_result({
			method = "anvil",
			width = 1,
			items = {stack}
		})

		if craft.time ~= 0 and inv:room_for_item("input", craft.item) then
			stack = aftercraft.items[1]
			inv:set_stack("input", index, stack)
			inv:add_item("input", ItemStack(craft.item))
			meta:set_int("strike", 1)
			anvil.update_infotext(pos)

			local timer = minetest.get_node_timer(pos)
			if not timer:is_started() then
				timer:start(1)
			end

			return true
		end
	end

	return false
end



-- Anvil item entity activation function.
-- Note: this is also call for NEW entities, not just reactivated ones.
function anvil.on_activate(self, staticdata)
	local pos = vector.round(self.object:get_pos())
	local node = minetest.get_node(pos)

	-- Clean up orphaned.
	if node.name ~= "anvil:anvil" then
		self.object:remove()
		return
	end

	if staticdata and staticdata ~= "" then
		local fields = minetest.deserialize(staticdata)
		if fields and fields.wield_name then
			self:set_display_item(pos, fields.wield_name)
		else
			-- Clean up the ones with bad data.
			self.object:remove()
		end
	end
end



-- Anvil item entity staticdata function.
function anvil.get_staticdata(self)
	-- Note: can't access self.object here because it appears this function gets
	-- called after the object has already been removed.

	local fields = {
		-- If we don't have a wield item name, you get a lump of coal instead.
		wield_name = self._wield_item or "default:coal_lump",
	}

	return minetest.serialize(fields)
end



-- Set the display item on the display entity.
function anvil.set_display_item(self, pos, stackname)
	local p2 = vector.add(pos, anvil.entity_offset)
	local node = minetest.get_node(pos)

	-- Rotations determined by visual inspection (trial-and-error).
	local param2_tab = {
		[0] = math.pi,
		[1] = math.pi / 2,
		[2] = 0,
		[3] = -(math.pi / 2),
	}
	local y_rot = param2_tab[node.param2] or 0

	local entity = self.object
	entity:set_pos(p2)
	entity:set_rotation({x = math.pi / 2, y=y_rot, z=0})
	entity:set_properties({
		wield_item = stackname,
	})

	-- Also store stack name in the luaentity.
	-- This lets us access the data in the 'get_staticdata' function.
	self._wield_item = stackname
end



-- Updates infotext according to current state.
function anvil.update_infotext(pos)
	local info = ""
	local workpiece = ""
	local itemstack

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local inv = meta:get_inventory()
	local list = inv:get_list("input") or {}

	for index, stack in ipairs(list) do
		if not stack:is_empty() then
			local sdef = stack:get_definition() or {}
			workpiece = utility.get_short_desc(sdef.description or "Unknown")
			itemstack = stack
			break
		end
	end

	if owner ~= "" then
		info = info .. "<" .. rename.gpn(owner) .. ">'s Anvil\n"
	else
		info = info .. "Blacksmithing Anvil\n"
	end

	if workpiece ~= "" then
		info = info .. "Workpiece: " .. workpiece .. "\n"
	end

	if itemstack then
		local tdef = minetest.registered_items[itemstack:get_name()]
		if tdef and tdef.stack_max == 1 then
			-- Must NOT have a 'wear_represents' key, that implies wear is NOT default.
			if not tdef.wear_represents then
				local wear = itemstack:get_wear()
				if wear == 0 then
					info = info .. "Durability: 100%\n"
				else
					info = info .. "Durability: " .. math.floor(((wear / 65535) * -1 + 1) * 100) .. "%\n"
				end
			end
		end
	end

	local heat = meta:get_int("heat")
	if heat > 0 then
		info = info .. "Let cool before take (" .. heat .. ")\n"
	end

	meta:set_string("infotext", info)
end



-- Updates formspec according to current state.
function anvil.update_formspec(pos)
	local smeta = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

	local formspec = "size[8,8]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[2.5,1;Workspace]" ..
		"list[" .. smeta .. ";input;2.5,1.5;3,1;]" ..
		"list[current_player;main;0,3.75;8,1;]" ..
		"list[current_player;main;0,5;8,3;8]" ..
		default.get_hotbar_bg(0, 3.75)

	-- Note: using a NON-standard name because we do NOT want special
	-- engine/client handling. This is just a storage space for the formspec
	-- string, but we send it to the client manually.
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec2", formspec)

	local inv = meta:get_inventory()
	inv:set_size("input", 3)
end



-- Node constructor.
function anvil.on_construct(pos)
	anvil.update_infotext(pos)
	anvil.update_formspec(pos)
	anvil.update_entity(pos)
end



-- Node destructor.
function anvil.on_destruct(pos)
	anvil.on_pre_fall(pos)
	anvil.remove_entity(pos)
end



-- Pre-fall callback. Node is being converted to falling node.
function anvil.on_pre_fall(pos)
	local meta = minetest.get_meta(pos)
	local heat = meta:get_int("heat")
	local inv = meta:get_inventory()
	local list = inv:get_list("input") or {}

	for index, stack in ipairs(list) do
		if not stack:is_empty() then
			-- In anvil is removed/destroyed while hot items are on it, damage them.
			if heat > 0 then
				local idef = minetest.registered_tools[stack:get_name()]
				if idef and idef.stack_max == 1 and not idef.wear_represents then
					-- Add 2/3rds wear. This has a high chance to destroy the tool unless
					-- it had good durability.
					stack:add_wear((65535 / 3) * 2)

					if stack:is_empty() then
						if idef.sounds and idef.sounds.breaks then
							ambiance.sound_play(idef.sounds.breaks, pos, 1.0, 16)
						end
					end
				end
			end

			list[index] = ItemStack("")
			if not stack:is_empty() then
				minetest.add_item(pos, stack)
			end
		end
	end

	-- Have to explicitly clear the inventory.
	-- Otherwise it will be duplicated when the node actually falls.
	inv:set_list("input", list)
end



-- Anvil gets blasted.
function anvil.on_blast(pos)
	anvil.on_pre_fall(pos)
	minetest.remove_node(pos)
end



-- Anvil fell but cannot be placed as a node for some reason.
function anvil.on_collapse_to_entity(pos, node)
	minetest.add_item(pos, ItemStack("anvil:anvil"))
end



-- Anvil fell and was reconstructed as a node.
function anvil.on_finish_collapse(pos, node)
	anvil.update_entity(pos)
	anvil.update_infotext(pos)
	anvil.update_formspec(pos)

	-- If there was a timer running, restart it.
	local meta = minetest.get_meta(pos)
	if meta:get_int("heat") > 0 then
		minetest.get_node_timer(pos):start(1)
	end
end



-- Formspec received fields.
function anvil.on_player_receive_fields(player, formname, fields)
	local fn = formname:sub(1, 14)
	if fn ~= "anvil:formspec" then
		return
	end

	local pos = minetest.string_to_pos(formname:sub(16))
	if not pos then
		return
	end

	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local plpos = player:get_pos()

	-- Require close interactions (needed for security, since owner can be blank).
	if vector.distance(pos, plpos) > 10 then
		return
	end

	if not anvil.player_can_use(pos, player) then
		return
	end

	-- We handled it.
	return true
end



-- Function to show player the formspec.
function anvil.show_formspec(pname, pos)
	local meta = minetest.get_meta(pos)
	local fs = meta:get_string("formspec2")
	local sp = minetest.pos_to_string(pos)
	minetest.show_formspec(pname, "anvil:formspec_" .. sp, fs)
end



-- Player rightclicks on anvil.
function anvil.on_rightclick(pos, node, user, itemstack, pt)
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Rightclicking with an empty hand takes from anvil, if there is something to take.
	if anvil.player_can_use(pos, user) then
		if itemstack:is_empty() and not inv:is_empty("input") then
			if meta:get_int("heat") > 0 then
				anvil.burn_user(pos, user)
				return
			end

			return anvil.put_or_take(pos, user, itemstack, false)
		end
	end

	-- Player does not need access rights to open the formspec.
	if itemstack:is_empty() or not anvil.item_repairable_or_craftable(itemstack) then
		anvil.show_formspec(pname, pos)
		return
	end

	-- Otherwise, player needs access to be able to put or take from anvil.
	if anvil.player_can_use(pos, user) then
		if anvil.item_repairable_or_craftable(itemstack) then
			if meta:get_int("heat") > 0 then
				anvil.burn_user(pos, user)
				return
			end

			return anvil.put_or_take(pos, user, itemstack, true)
		end
	end
end



-- Put or take user's currently-wielded item.
function anvil.put_or_take(pos, user, itemstack, put)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	if put then
		-- Putting onto anvil.
		if inv:room_for_item("input", itemstack) then
			inv:add_item("input", itemstack)
			anvil.update_entity(pos)
			anvil.update_infotext(pos)
			anvil.update_formspec(pos)
			return ItemStack("")
		end
	else
		-- Taking from anvil.
		local list = inv:get_list("input") or {}
		for index, stack in ipairs(list) do
			if not stack:is_empty() then
				inv:set_stack("input", index, ItemStack(""))
				anvil.update_entity(pos)
				anvil.update_infotext(pos)
				anvil.update_formspec(pos)
				return stack
			end
		end
	end

	return itemstack
end



-- Function to update entity display.
function anvil.update_entity(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local inv = meta:get_inventory()

	local stack
	local ilist = inv:get_list("input")
	for index, item in ipairs(ilist) do
		if not item:is_empty() then
			stack = item
			break
		end
	end

	local p2 = vector.add(pos, anvil.entity_offset)
	local ents = minetest.get_objects_inside_radius(p2, anvil.entity_radius)

	local count = 0
	local entity
	local luaent

	for k, v in ipairs(ents) do
		local ent = v:get_luaentity()
		if ent and ent.name == "anvil:item" then
			-- If there are multiple entities, remove the extras.
			-- Remove all entities if there is nothing on the anvil.
			if not stack or count >= 1 then
				v:remove()
			else
				entity = v
				luaent = ent
				count = count + 1
			end
		end
	end

	-- If there are no entities and something is on the anvil, create one.
	if count == 0 and stack then
		local ent = minetest.add_entity(p2, "anvil:item")
		if ent then
			local lent = ent:get_luaentity()
			if not lent then
				ent:remove()
				return
			end

			entity = ent
			luaent = lent
		end
	end

	-- We must have entity, lua-entity, and stack.
	if not entity or not luaent or not stack then
		return
	end

	luaent:set_display_item(pos, stack:get_name())
end



-- Remove the entity display.
function anvil.remove_entity(pos)
	local p2 = vector.add(pos, anvil.entity_offset)
	local ents = minetest.get_objects_inside_radius(p2, anvil.entity_radius)

	for k, v in ipairs(ents) do
		local luaent = v:get_luaentity()
		if luaent and luaent.name == "anvil:item" then
			v:remove()
		end
	end
end



-- Can player move stuff in inventory.
function anvil.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
	local meta = minetest.get_meta(pos)
	if meta:get_int("heat") > 0 then
		anvil.burn_user(pos, user)
		return 0
	end

	if not anvil.player_can_use(pos, user) then
		return 0
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return count
end



-- After inventory move.
function anvil.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
	anvil.update_entity(pos)
	anvil.update_infotext(pos)
	anvil.update_formspec(pos)
end



-- Can player put stuff in inventory.
function anvil.allow_metadata_inventory_put(pos, listname, index, stack, user)
	local meta = minetest.get_meta(pos)
	if meta:get_int("heat") > 0 then
		anvil.burn_user(pos, user)
		return 0
	end

	if not anvil.player_can_use(pos, user) then
		return 0
	end

	if not anvil.item_repairable_or_craftable(stack) then
		return 0
	end
	return stack:get_count()
end



-- After inventory put.
function anvil.on_metadata_inventory_put(pos, listname, index, stack, user)
	anvil.update_entity(pos)
	anvil.update_infotext(pos)
	anvil.update_formspec(pos)
end



-- Can player take stuff from inventory.
function anvil.allow_metadata_inventory_take(pos, listname, index, stack, user)
	local meta = minetest.get_meta(pos)
	if meta:get_int("heat") > 0 then
		anvil.burn_user(pos, user)
		return 0
	end

	if not anvil.player_can_use(pos, user) then
		return 0
	end

	return stack:get_count()
end



-- After inventory take.
function anvil.on_metadata_inventory_take(pos, listname, index, stack, user)
	anvil.update_entity(pos)
	anvil.update_infotext(pos)
	anvil.update_formspec(pos)
end



-- After place node.
function anvil.after_place_node(pos, user, itemstack, pt)
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	local control = user:get_player_control()

	local meta = minetest.get_meta(pos)

	-- Hold 'E' to set owner, otherwise anyone can use.
	if control.aux1 then
		meta:set_string("owner", pname)
		anvil.update_infotext(pos)
		anvil.update_formspec(pos)
	end
end



-- Player punches anvil.
function anvil.on_punch(pos, node, user, pt)
	if not user or not user:is_player() then
		return
	end

	local stack = user:get_wielded_item()
	local sname = stack:get_name()

	-- Note: hammering sound shall be played even if player cannot actually use the anvil.
	if sname:find("hammer") or sname:find("pick") or sname:find("axe") or sname:find("sword") then
		anvil.sparks_and_sound(pos)
	else
		ambiance.sound_play("default_dig_metal", pos, 0.5, 16)
	end

	if not anvil.player_can_use(pos, user) then
		return
	end

	-- Punching with empty hand takes item, if possible.
	if stack:is_empty() then
		local meta = minetest.get_meta(pos)
		if meta:get_int("heat") > 0 then
			anvil.burn_user(pos, user)
			return
		end

		stack = anvil.put_or_take(pos, user, stack, false)
		user:set_wielded_item(stack)
		return
	end

	-- We are going to repair or craft. Player must be wielding a hammer.
	if not anvil.is_hammer(stack) then
		return
	end

	if anvil.repair_tool(pos) then
		user:set_wielded_item(anvil.wear_hammer(pos, stack))
		return
	end

	if anvil.craft_something(pos) then
		user:set_wielded_item(anvil.wear_hammer(pos, stack))
		return
	end
end



-- Repair tool.
function anvil.repair_tool(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local list = inv:get_list("input") or {}

	if meta:get_int("strike") >= 1 then
		return false
	end

	for index, stack in ipairs(list) do
		local idef = minetest.registered_tools[stack:get_name()]
		if idef and idef.stack_max == 1 and not idef.wear_represents then
			local wear = stack:get_wear()
			if wear == 0 then
				return false
			end

			-- A heat source makes repairs faster.
			local repair_amount = 500
			if minetest.find_node_near(pos, 2, "group:fire") then
				repair_amount = 2000
			elseif minetest.find_node_near(pos, 2, "group:lava") then
				repair_amount = 5000
			end

			-- Max wear is 65535 (16 bit unsigned).
			wear = wear - repair_amount
			if wear < 0 then wear = 0 end
			stack:set_wear(wear)

			list[index] = stack
			inv:set_list("input", list)
			meta:set_int("strike", 1)
			meta:set_int("heat", meta:get_int("heat") + 10)

			anvil.update_infotext(pos)

			local timer = minetest.get_node_timer(pos)
			if not timer:is_started() then
				timer:start(1)
			end

			return true
		end
	end

	-- Nothing repaired.
	return false
end



-- Timer fires.
function anvil.on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local heat = meta:get_int("heat")
	meta:set_int("strike", 0)

	-- Cool off over time.
	if heat > 0 then
		local loss = 1
		if minetest.find_node_near(pos, 2, "group:water") then
			loss = 3
		end

		heat = heat - loss
		if heat < 0 then
			heat = 0
		end

		meta:set_int("heat", heat)
		anvil.update_infotext(pos)

		local p2 = vector.add(pos, anvil.entity_offset)
		p2.y = p2.y - 0.2
		minetest.add_particlespawner({
			amount = 6,
			time = 1,
			minpos = {x = p2.x - 0.1, y = p2.y + 0.1, z = p2.z - 0.1 },
			maxpos = {x = p2.x + 0.1, y = p2.y + 0.2, z = p2.z + 0.1 },
			minvel = {x = -3, y = 0.5, z = -3},
			maxvel = {x = 3, y = 0.5, z = 3},
			minacc = {x = -0.15, y = -8, z = -0.15},
			maxacc = {x = 0.15, y = -8, z = 0.15},
			minexptime = 0.2,
			maxexptime = 0.5,
			minsize = 0.1,
			maxsize = 0.1,
			collisiondetection = true,
			texture = "anvil_particle_heat.png",
			glow = 13,
		})

		return true
	end
end



-- Check if diggable.
function anvil.can_dig(pos, user)
	if not user or not user:is_player() then
		return false
	end

	if not anvil.player_can_use(pos, user) then
		return false
	end

	return true
end



-- Make sparks fly!
function anvil.sparks_and_sound(pos)
	local pos = vector.add(pos, {
		x = math.random(-10, 10) / 30,
		y = 0.2,
		z = math.random(-10, 10) / 30
	})
	minetest.add_particlespawner({
		amount = 6,
		time = 0.2,
		collisiondetection = true,
		collision_removal = true,
		texture = "anvil_particle_spark.png",
		glow = 13,
		minsize = 0.5,
		maxsize = 0.5,
		minpos = vector.add(pos, {x=0, y=0, z=0}),
		maxpos = vector.add(pos, {x=0, y=0, z=0}),
		minvel = {x=-4, y=1, z=-4},
		maxvel = {x=4, y=2, z=4},
		minacc = {x=0, y=-8, z=0},
		maxacc = {x=0, y=-8, z=0},
		minexptime = 0.5,
		maxexptime = 1.0,
	})
	ambiance.sound_play("anvil_clang", pos, 0.3, 40)
end



-- Rotate the anvil (and the display entity).
function anvil.on_rotate(pos, node, user, mode, new_param2)
	if mode ~= screwdriver.ROTATE_FACE then
		return false
	end

	node.param2 = new_param2
	minetest.swap_node(pos, node)
	minetest.check_for_falling(pos)

	-- Rotate the display entity if we have one.
	anvil.update_entity(pos)

	-- Returning 'true' means we did the rotation ourselves.
	return true
end



-- Burn player and play a sound.
function anvil.burn_user(pos, user)
	utility.damage_player(user, "heat", 1*250)
	minetest.sound_play("default_item_smoke", {pos=pos, max_hear_distance=16, gain=0.5}, true)

	local p2 = vector.add(pos, anvil.entity_offset)
	minetest.add_particlespawner({
		amount = 3,
		time = 0.1,
		minpos = {x = p2.x - 0.1, y = p2.y + 0.1, z = p2.z - 0.1 },
		maxpos = {x = p2.x + 0.1, y = p2.y + 0.2, z = p2.z + 0.1 },
		minvel = {x = 0, y = 2.5, z = 0},
		maxvel = {x = 0, y = 2.5, z = 0},
		minacc = {x = -0.15, y = -0.02, z = -0.15},
		maxacc = {x = 0.15, y = -0.01, z = 0.15},
		minexptime = 4,
		maxexptime = 6,
		minsize = 5,
		maxsize = 5,
		collisiondetection = false,
		texture = "default_item_smoke.png"
	})
end



if not anvil.registered then
	anvil.registered = true

	minetest.register_on_player_receive_fields(function(...)
		return anvil.on_player_receive_fields(...) end)


	-- Display entity.
	minetest.register_entity("anvil:item", {
		initial_properties = {
			visual = "item",
			wield_item = "default:coal_lump",
			visual_size = {x=0.3, y=0.3, z=0.2},
			collide_with_objects = false,
			pointable = false,
			collisionbox = {0},
			selectionbox = {0},
		},

		on_activate = function(...) return anvil.on_activate(...) end,
		get_staticdata = function(...) return anvil.get_staticdata(...) end,
		set_display_item = function(...) return anvil.set_display_item(...) end,
	})


	local function box(x1, y1, z1, x2, y2, z2)
		return {
			x1 / 16 - 0.5,
			y1 / 16 - 0.5,
			z1 / 16 - 0.5,
			x2 / 16 - 0.5,
			y2 / 16 - 0.5,
			z2 / 16 - 0.5,
		}
	end


	-- The node.
	minetest.register_node("anvil:anvil", {
		description = "Blacksmithing Anvil",
		drawtype = "nodebox",
		tiles = {
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
		},
		paramtype = "light",
		paramtype2 = "facedir",
		on_rotate = function(...) return anvil.on_rotate(...) end,

		node_box = {
			type = "fixed",
			fixed = {
				box(-3, 8, 7, 0, 10, 9),
				box(0, 7, 6, 3, 10, 10),
				box(3, 7, 5, 16, 10, 11),
				box(16, 8, 6, 18, 10, 10),
				box(3, 6, 6, 15, 7, 10),
				box(5, 3, 6, 11, 6, 10),
				box(3, 2, 5, 13, 3, 11),
				box(2, 0, 5, 14, 2, 11),
				box(2, 0, 3, 4, 2, 13),
				box(12, 0, 3, 14, 2, 13),
			},
		},

		selection_box = {
			type = "fixed",
			fixed = {
				box(-3, 7, 5, 18, 10, 11),
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				box(0, 0, 4, 16, 10, 12),
			},
		},

		groups = utility.dig_groups("machine", {falling_node=1}),
		drop = 'anvil:anvil',
		sounds = default.node_sound_metal_defaults({dig="default_silence"}),
		stack_max = 1,

		on_construct = function(...) return anvil.on_construct(...) end,
		on_destruct = function(...) return anvil.on_destruct(...) end,
		on_blast = function(...) return anvil.on_blast(...) end,
		on_collapse_to_entity = function(...) return anvil.on_collapse_to_entity(...) end,
		on_finish_collapse = function(...) return anvil.on_finish_collapse(...) end,
		on_rightclick = function(...) return anvil.on_rightclick(...) end,
		allow_metadata_inventory_move = function(...) return anvil.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_put = function(...) return anvil.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_take = function(...) return anvil.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...) return anvil.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...) return anvil.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...) return anvil.on_metadata_inventory_take(...) end,
		after_place_node = function(...) return anvil.after_place_node(...) end,
		on_punch = function(...) return anvil.on_punch(...) end,
		on_timer = function(...) return anvil.on_timer(...) end,
		can_dig = function(...) return anvil.can_dig(...) end,
		_on_update_infotext = function(...) return anvil.update_infotext(...) end,
		_on_update_formspec = function(...) return anvil.update_formspec(...) end,
		_on_update_entity = function(...) return anvil.update_entity(...) end,
		_on_pre_fall = function(...) return anvil.on_pre_fall(...) end,
	})


	-- Hammering tool.
	minetest.register_tool("anvil:hammer", {
		description = "Blacksmithing Hammer",
		inventory_image = "anvil_tool_steelhammer.png",
		wield_image = "anvil_tool_steelhammer.png",
		tool_capabilities = tooldata["hammer_hammer"],
		sounds = {
			breaks = "basictools_tool_breaks",
		},
		groups = {not_repaired_by_anvil=1},
	})


	minetest.register_craft({
		output = "anvil:hammer",
		recipe = {
			{"carbon_steel:ingot", "darkage:iron_stick", "carbon_steel:ingot"},
			{"carbon_steel:ingot", "darkage:iron_stick", "carbon_steel:ingot"},
			{"", "darkage:iron_stick", ""},
		},
	})


	minetest.register_craft({
		output = "anvil:anvil",
		recipe = {
			{"carbon_steel:ingot", "carbon_steel:ingot", "carbon_steel:ingot"},
			{"", "cast_iron:ingot", ""},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		},
	})


	-- Register mod reloadable.
	local c = "anvil:core"
	local f = anvil.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
