
-- Function is badly named! Should be 'entity_ignores_arrow'.
-- Return 'true' if the entity cannot be hit, otherwise return 'false' if the entity should be punched.
-- Note: 'entity_name' is the registered name of the entity to be checked for hit.
function throwing.entity_ignores_arrow(entity_name)
	-- Dropped itemstacks don't take damage.
	if entity_name == "__builtin:item" then
		return true
	end

	-- Ignore other arrows/fireballs in flight.
	local is_arrow = (string.find(entity_name, "arrow") or string.find(entity_name, "fireball"))
	if is_arrow then
		return true
	end

	-- Ignore health gauges above players.
	if entity_name == "gauges:hp_bar" then
		return true
	end

	-- Ignore sound beacons.
	if entity_name:find("^soundbeacon:") then
		return true
	end

	-- Entity is unknown, so punch it for damage!
	return false
end


--~ 
--~ Shot and reload system
--~ 

local players = {}

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = {
		reloading=false,
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

-- This function copied and translated from C++, from one of my C++ projects.
local function rotate_point_2d(p, r)
	local x = p.x
	local y = p.y

	-- Rotate.
	local s = math.sin(r)
	local c = math.cos(r)

	-- Temp vars required to avoid clobbering the equation.
	-- This mistake caused me quite a bit of wasted time!
	local nx = x*c - y*s
	local ny = x*s + y*c

	x = nx
	y = ny

	return {x=x, y=y}
end

local function get_shoot_position(player)
	local yaw = player:get_look_horizontal()
	local pos = player:get_pos()

	local off = {x=0.24, y=0}
	--local off = {x=0, y=0}
	off = rotate_point_2d(off, yaw)

	pos.x = pos.x + off.x
	pos.y = pos.y + 1.3
	pos.z = pos.z + off.y
	return pos
end

function throwing_shoot_arrow(itemstack, player, stiffness, is_cross)
  if not player or not player:is_player() then return end
  local pname = player:get_player_name()
  
	local arrow = itemstack:get_metadata()
	local imeta = itemstack:get_meta()
	if arrow == "" then
		arrow = imeta:get_string("arrow")
	end
  if arrow == "" then return end
  
	local playerpos = player:get_pos()
	local spawnpos = get_shoot_position(player)
	local obj = minetest.add_entity(spawnpos, arrow)
  if not obj then return end

	local luaent = obj:get_luaentity()
  if not luaent then return end

	itemstack:set_metadata("")
	imeta:set_string("arrow", nil)
	imeta:set_string("ar_desc", nil)
	toolranks.apply_description(imeta, itemstack:get_definition())

	local dir = player:get_look_dir()
	local vel = stiffness * 2
	obj:set_velocity({x=dir.x*vel, y=dir.y*vel, z=dir.z*vel})
	obj:set_acceleration({x=0, y=-5, z=0})
	obj:set_yaw(player:get_look_horizontal() - (math.pi / 2))

	if is_cross then
		minetest.sound_play("throwing_crossbow_sound", {pos=playerpos}, true)
	else
		minetest.sound_play("throwing_bow_launch", {pos=playerpos}, true)
	end

	luaent.player = player
  luaent.player_name = pname
	luaent.inventory = player:get_inventory()
	luaent.stack = player:get_inventory():get_stack("main", player:get_wield_index()-1)
	luaent.lastpos = table.copy(spawnpos)

	-- Firing anything disables your cloak.
	cloaking.disable_if_enabled(pname, true)

	-- Return the modified itemstack.
	return itemstack
end



function throwing.flight_particle(lpos, cpos)
	local mpos = {
		x = (lpos.x + cpos.x) / 2,
		y = (lpos.y + cpos.y) / 2,
		z = (lpos.z + cpos.z) / 2,
	}
	local mpos2 = {
		x = (mpos.x + cpos.x) / 2,
		y = (mpos.y + cpos.y) / 2,
		z = (mpos.z + cpos.z) / 2,
	}
	local mpos3 = {
		x = (lpos.x + mpos.x) / 2,
		y = (lpos.y + mpos.y) / 2,
		z = (lpos.z + mpos.z) / 2,
	}

	local targets = {
		mpos3,
		mpos,
		mpos2,
		cpos,
	}

	for i = 1, #targets, 1 do
		local mpos = targets[i]

		minetest.add_particlespawner({
			amount = 3,
			time = 0.1,
			minpos = mpos,
			maxpos = mpos,
			minvel = {x=-0.1, y=-0.1, z=-0.1},
			maxvel = {x=0.1,  y=0.1,  z=0.1},
			minacc = vector.new(),
			maxacc = vector.new(),
			minexptime = 0.5,
			maxexptime = 2.5,
			minsize = 0.5,
			maxsize = 1,
			texture = "throwing_sparkle.png",
			glow = 8,
		})
	end
end


local function highlight_position(pos)
	utility.original_add_particle({
		pos = pos,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 1.5,
		size = 4,
		collisiondetection = false,
		vertical = false,
		texture = "heart.png",
	})
end


-- Do flying/collision logic, and execute entity callbacks.
-- This should be called inside of the entity's on_step() function.
-- Returns 'true' if the entity was removed and should no longer be used.
function throwing.do_fly(self, dtime)
	-- Get arrow's current and previous position.
	local cpos = self.object:get_pos()
	local lpos = self.lastpos

	ambiance.sound_play("throwing_arrow_fly", cpos, 1.0, 4)

	-- Detect collisions: raycast from last position to current. (Note: 'lastpos'
	-- table is never nil because it is part of entity definition. This is why
	-- test is against 'x' key here.)
	--
	-- Update: arrow throwing function now always sets 'lastpos' when the arrow
	-- entity is spawned (to solve problems where the arrow has moved some distance
	-- before the 'on_step' function gets called). Still checking this to avoid
	-- problems with old arrow entities in the world.
	if lpos.x ~= nil then
		local ray = minetest.raycast(lpos, cpos, true, true)

		for thing in ray do
			if thing.type == "node" then
				local nodeu = minetest.get_node(thing.under)
				local nodea = minetest.get_node(thing.above)

				local blocku = throwing_node_should_block_arrow(nodeu.name)
				local blocka = throwing_node_should_block_arrow(nodea.name)

				if not blocka and blocku then
					-- Test shows that nodeboxes are indeed collisioned correctly.
					--if thing.intersection_point then
					--	highlight_position(thing.intersection_point)
					--end

					if self.hit_node then
						self:hit_node(thing.under, thing.above, thing.intersection_point)
					end

					self.object:remove()
					return true
				elseif (blocka and blocku) or (blocka and not blocku) then
					-- Arrow was fired from inside solid nodes.
					self.object:remove()
					return true
				end
			elseif thing.type == "object" and thing.ref then
				local obj = thing.ref
				if obj:is_player() then
					-- Not permitted to hit the player that fired it.
					if obj:get_player_name() ~= self.player_name then
						local continue = false

						if self.hit_player then
							-- If function returns true, arrow continues flight through this object.
							if self:hit_player(obj, thing.intersection_point) then
								continue = true
							end
						end

						if not continue then
							self.object:remove()
							return true
						end
					end
				else
					local ent = obj:get_luaentity()
					if ent and not throwing.entity_ignores_arrow(ent.name) then
						local continue = false

						if self.hit_object then
							-- If function returns true, arrow continues flight through this object.
							if self:hit_object(obj, thing.intersection_point) then
								continue = true
							end
						end

						if not continue then
							self.object:remove()
							return true
						end
					end
				end
			end
		end

		if self.flight_particle then
			self:flight_particle(lpos, cpos)
		else
			throwing.flight_particle(lpos, cpos)
		end
	end

	self.lastpos = {x=cpos.x, y=cpos.y, z=cpos.z}
end



function throwing_unload (itemstack, player, unloaded, wear)
	if itemstack:get_metadata() then
		for _,arrow in ipairs(throwing_arrows) do
			local arw = itemstack:get_metadata()
			if arw == "" then
				local imeta = itemstack:get_meta()
				arw = imeta:get_string("arrow")
			end
			if arw ~= "" then
				if arw == arrow[2] then
					local leftover = player:get_inventory():add_item("main", arrow[1])
					minetest.item_drop(leftover, player, player:get_pos())
				end
			end
		end
	end

	if wear >= 65535 then
		ambiance.sound_play("default_tool_breaks", player:get_pos(), 1.0, 20)
		itemstack:take_item(itemstack:get_count())
		return itemstack
	else
		local newstack = ItemStack(unloaded)
		newstack:set_wear(wear)
		local imeta = newstack:get_meta()

		local ometa = itemstack:get_meta()
		imeta:set_string("en_desc", ometa:get_string("en_desc"))

		toolranks.apply_description(imeta, newstack:get_definition())
		return newstack
	end
end

function throwing_arrow_punch_entity (target, self, damage)
	-- Get tool capabilities from the tool-data API.
	local toolcaps = td_api.arrow_toolcaps(self._name or "", damage)

  local player = minetest.get_player_by_name(self.player_name or "")
  if player and player:is_player() then
		armor.notify_punch_reason({reason="arrow"})
		target:punch(player, 1.0, toolcaps, nil)
  else
		-- Shooter logged off game after firing arrow. Use basic fallback.
		toolcaps.damage_groups.from_arrow = nil
		armor.notify_punch_reason({reason="arrow"})
    target:punch(self.object, 1.0, toolcaps, nil)
  end
end

function throwing_reload (index, indexname, controls, pname, pos, is_cross, loaded)
	-- This function is called after some delay.
	local player = minetest.get_player_by_name(pname)

	-- Check for nil. Can happen if player leaves game right after reloading.
	if not player or not players[pname] then
		return
	end

	pova.remove_modifier(player, "physics", "bow_reloading")

	players[pname].reloading = false
	local playerinv = player:get_inventory()
	local itemstack = playerinv:get_stack("main", index)
	if not itemstack or itemstack:get_count() ~= 1 then
		return
	end

	-- Check if the player is still wielding the same object.
	-- This check isn't very secure, but we don't care too much.
	local same_selected = false
	if index == player:get_wield_index() then
		if indexname == itemstack:get_name() then
			same_selected = true
		end
	end

	if same_selected then
		if (pos.x == player:get_pos().x and pos.y == player:get_pos().y and pos.z == player:get_pos().z) or not is_cross then
			local wear = itemstack:get_wear()
			local bowdef = minetest.registered_items[itemstack:get_name()]
			local bowname = bowdef.description
			local arrow_index = 1

			-- The selected arrow can come from 1 of 4 places to the right of the bow,
			-- depending on player's controls at the time the load operation was started.
			if controls.sneak and not controls.aux1 then
				arrow_index = 2
			elseif not controls.sneak and controls.aux1 then
				arrow_index = 3
			elseif controls.sneak and controls.aux1 then
				arrow_index = 4
			end

			local arrow_stack = playerinv:get_stack("main", index + arrow_index)

			for _, arrow in ipairs(throwing_arrows) do
				if arrow_stack:get_name() == arrow[1] then
					-- Remove arrow from beside bow.
					arrow_stack:take_item()
					playerinv:set_stack("main", index + arrow_index, arrow_stack)

					local name = arrow[1]
					local arrowdesc = utility.get_short_desc(minetest.registered_items[name].description or "")
					local entity = arrow[2]

					-- Replace with loaded bow item.
					local newstack = ItemStack(loaded)
					newstack:set_wear(wear)
					local imeta = newstack:get_meta()

					-- Preserve name of bow (if named).
					local ometa = itemstack:get_meta()
					imeta:set_string("en_desc", ometa:get_string("en_desc"))

					imeta:set_string("arrow", entity)
					imeta:set_string("ar_desc", arrowdesc)
					toolranks.apply_description(imeta, bowdef)

					playerinv:set_stack("main", index, newstack)

					-- Start checking to see if player unwields this bow. If they do, we
					-- must unload it.
					throwing.wield_check(pname, index, indexname, loaded)

					ambiance.sound_play("throwing_arrow_nock", pos, 1.0, 16)

					-- Don't need to iterate through remaining arrow types.
					return
				end
			end
		end
	end
end



function throwing.wield_check(pname, index, unloaded, loaded)
	local player = minetest.get_player_by_name(pname)
	if not player then
		return
	end

	local cindex = player:get_wield_index()
	if cindex ~= index then
		local stack = player:get_inventory():get_stack("main", index)
		if stack:get_name() == loaded then
			local newstack = throwing_unload(stack, player, unloaded, stack:get_wear())
			if newstack then
				player:get_inventory():set_stack("main", index, newstack)
			end
		end
		return
	end

	minetest.after(0, throwing.wield_check, pname, index, unloaded, loaded)
end



-- Bows and crossbows

function throwing_register_bow (name, desc, scale, stiffness, reload_time, toughness, is_cross, craft)
	local bow_unloaded_name = "throwing:" .. name
	local bow_loaded_name = "throwing:" .. name .. "_loaded"

	minetest.register_tool(bow_unloaded_name, {
		description = desc,
		inventory_image = "throwing_" .. name .. ".png",
		wield_scale = scale,
    stack_max = 1,
		groups = {not_repaired_by_anvil=1},

		on_use = function(itemstack, user, pt)
			if not user or not user:is_player() then
				return
			end

			local pos = user:get_pos()
			local pname = user:get_player_name()
			local index = user:get_wield_index()
			local inv = user:get_inventory()
			local stack = inv:get_stack("main", index)
			local indexname = ""
			if stack and stack:get_count() == 1 then
				indexname = stack:get_name()
			end

			-- Reload bow after some delay.
			if not players[pname].reloading then
				pova.set_modifier(user, "physics", {speed=0.7}, "bow_reloading")

				players[pname].reloading = true
				local controls = user:get_player_control()
				minetest.after(reload_time, throwing_reload, index, indexname, controls, pname, pos, is_cross, "throwing:" .. name .. "_loaded")
			end
		end,
	})
	
	minetest.register_tool(bow_loaded_name, {
		description = desc,
		inventory_image = "throwing_" .. name .. "_loaded.png",
		wield_scale = scale,
		stack_max = 1,
		groups = {not_in_creative_inventory=1, not_repaired_by_anvil=1},

		on_use = function(itemstack, user, pt)
			if not user or not user:is_player() then
				return
			end

			local control = user:get_player_control()
			local unloaded = "throwing:" .. name
			local wear = itemstack:get_wear()

			-- Unload the bow.
			if control.sneak then
				local newstack = throwing_unload(itemstack, user, unloaded, wear)

				if newstack then
					return newstack
				end
				return itemstack
			end

			-- Fire the bow.
			local newstack = throwing_shoot_arrow(itemstack, user, stiffness, is_cross)
			if newstack then
				wear = wear + (65535 / toughness)
				newstack = throwing_unload(newstack, user, unloaded, wear)
			end

			if newstack then
				return newstack
			end
			return itemstack
		end,

		-- Prevent dropping loaded bows.
		on_drop = function(itemstack, dropper, pos) return itemstack end,
	})

	-- Store loaded/unloaded bow names.
	throwing.bow_names_loaded[#(throwing.bow_names_loaded) + 1] = {
		name = bow_loaded_name,
		unloaded = bow_unloaded_name,
	}
	throwing.bow_names_unloaded[#(throwing.bow_names_unloaded) + 1] = {
		name = bow_unloaded_name,
		loaded = bow_loaded_name,
	}
	
	minetest.register_craft({
		output = 'throwing:' .. name,
		recipe = craft
	})

	minetest.register_craft({
		output = 'throwing:' .. name,
		recipe = {
			{craft[1][3], craft[1][2], craft[1][1]},
			{craft[2][3], craft[2][2], craft[2][1]},
			{craft[3][3], craft[3][2], craft[3][1]},
		}
	})
end



-- Determine if a node should block an arrow.
-- Cheapest checks should come first.
function throwing_node_should_block_arrow (nn)
  if nn == "air" then return false end
  if snow.is_snow(nn) then return false end
  --if nn == "ignore" then return true end
  
  if string.find(nn, "^throwing:") or
     string.find(nn, "^fire:") or
     string.find(nn, "^default:fence") or
     string.find(nn, "ladder") then
    return false
  end
  
  local def = minetest.reg_ns_nodes[nn]
  if def then
    local dt = def.drawtype
    local pt2 = def.paramtype2
    if dt == "airlike" or
       dt == "signlike" or
       dt == "torchlike" or
       dt == "raillike" or
       dt == "plantlike" or
       (dt == "nodebox" and pt2 == "wallmounted") then
      return false
    end
  end
  
  return true
end
throwing.node_blocks_arrow = throwing_node_should_block_arrow

-- Prevent moving loaded bows out of player inventory to other inventories.
-- The action has to be prevented completely (we cannot simply unload the bow)
-- because we cannot track the itemstack after it has been moved out of the
-- player's inventory.
local function inventory_allow(player, action, inventory, inventory_info)
	if action == "take" then
		local sname = inventory_info.stack:get_name()
		if sname:find("^throwing:") then
			for k, v in ipairs(throwing.bow_names_loaded) do
				if v.name == sname then
					return 0
				end
			end
		end
	end
end

local function inventory_action(player, action, inventory, inventory_info)
	if action == "put" then
		local sname = inventory_info.stack:get_name()
		if sname:find("^throwing:") then
			for k, v in ipairs(throwing.bow_names_loaded) do
				if v.name == sname then
					-- Player has put a loaded bow into their inventory from somewhere else.
					-- Unload the bow to prevent a possible exploit.
					local bowstack = inventory_info.stack
					local newstack = throwing_unload(bowstack, player, v.unloaded, bowstack:get_wear())
					if newstack then
						player:get_inventory():set_stack(inventory_info.listname, inventory_info.index, newstack)
					end
				end
			end
		end
	elseif action == "move" then
		local movedstack = player:get_inventory():get_stack(inventory_info.to_list, inventory_info.to_index)
		local sname = movedstack:get_name()
		if sname:find("^throwing:") then
			for k, v in ipairs(throwing.bow_names_loaded) do
				if v.name == sname then
					-- Player has moved a bow around in their inventory.
					-- Unloaded it, as they almost certainly aren't wielding it anymore.
					local bowstack = movedstack
					local newstack = throwing_unload(bowstack, player, v.unloaded, bowstack:get_wear())
					if newstack then
						player:get_inventory():set_stack(inventory_info.to_list, inventory_info.to_index, newstack)
					end
				end
			end
		end
	end
end

local function get_unloaded_name(loaded)
	for k, v in ipairs(throwing.bow_names_loaded) do
		if v.name == loaded then
			return v.unloaded
		end
	end
end

local function unload_all_bows(player)
	local inv = player:get_inventory()
	local sz = inv:get_size("main")

	for k = 1, sz do
		local stack = inv:get_stack("main", k)
		local sname = stack:get_name()

		if sname:find("^throwing:") and sname:find("_loaded$") then
			local unloaded = get_unloaded_name(sname)
			if unloaded then
				local newstack = throwing_unload(stack, player, unloaded, stack:get_wear())
				if newstack then
					inv:set_stack("main", k, newstack)
				end
			end
		end
	end
end

minetest.register_allow_player_inventory_action(inventory_allow)
minetest.register_on_player_inventory_action(inventory_action)
minetest.register_on_joinplayer(unload_all_bows)
