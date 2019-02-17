
-- Function is badly named! Should be 'entity_ignores_arrow'.
-- Return 'true' if the entity cannot be hit, otherwise return 'false' if the entity should be punched.
function throwing.entity_blocks_arrow(entity_name)
	-- Dropped itemstacks don't take damage.
	if entity_name == "__builtin:item" then
		return true
	end

	-- Ignore other arrows/fireballs in flight.
	local is_arrow = (string.find(entity_name, "arrow") or string.find(entity_name, "fireball"))
	if is_arrow then
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

function throwing_shoot_arrow (itemstack, player, stiffness, is_cross)
  if not player or not player:is_player() then return end
  
	local arrow = itemstack:get_metadata()
	local imeta = itemstack:get_meta()
	if arrow == "" then
		arrow = imeta:get_string("arrow")
	end
  if arrow == "" then return end
  
	local playerpos = utility.get_foot_pos(player:get_pos())
	local obj = minetest.add_entity({x=playerpos.x, y=playerpos.y+1.5, z=playerpos.z}, arrow)
  if not obj then return end
  if not obj:get_luaentity() then return end

	itemstack:set_metadata("")
	imeta:set_string("arrow", nil)
	imeta:set_string("ar_desc", nil)
	toolranks.apply_description(imeta, itemstack:get_definition())

	local dir = player:get_look_dir()
	obj:setvelocity({x=dir.x*stiffness, y=dir.y*stiffness, z=dir.z*stiffness})
	obj:setacceleration({x=dir.x*-3, y=-8.5, z=dir.z*-3})
	obj:setyaw(player:get_look_yaw()+math.pi)
	if is_cross then
		minetest.sound_play("throwing_crossbow_sound", {pos=playerpos})
	else
		minetest.sound_play("throwing_bow_sound", {pos=playerpos})
	end
	obj:get_luaentity().player = player
  obj:get_luaentity().player_name = player:get_player_name()
	obj:get_luaentity().inventory = player:get_inventory()
	obj:get_luaentity().stack = player:get_inventory():get_stack("main", player:get_wield_index()-1)

	-- Return the modified itemstack.
	return itemstack
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

function throwing_arrow_punch_entity (obj, self, damage)
  local player = minetest.get_player_by_name(self.player_name or "")
  if player and player:is_player() then
		if obj:is_player() then
			-- If target is a player, and not a mob, we can't use the shooter as the
			-- attacker. This would only actually apply damage if the shooter was a
			-- short distance from the target. So for this case, we have to "fake" the
			-- target punching themselves.
			obj:punch(self.object, 1.0, {
				full_punch_interval=1.0,
				damage_groups={fleshy=damage},
			}, nil)
		else
			-- The target of the arrow (a mob) sees the shooter as the attacker,
			-- *not* the arrow entity itself. If this were not so, players
			-- could shoot mobs with arrows without retaliation.
			obj:punch(player, 1.0, {
				full_punch_interval=1.0,
				damage_groups={fleshy=damage},
			}, nil)
		end
  else
		-- Shooter logged off game after firing arrow. Use basic fallback.
    obj:punch(self.object, 1.0, {
      full_punch_interval=1.0,
      damage_groups={fleshy=damage},
    }, nil)
  end
end

function throwing_reload (index, indexname, pname, pos, is_cross, loaded)
	-- This function is called after some delay.
	local player = minetest.get_player_by_name(pname)

	-- Check for nil. Can happen if player leaves game right after reloading.
	if not player or not players[pname] then
		return
	end

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
		if (pos.x == player:getpos().x and pos.y == player:getpos().y and pos.z == player:getpos().z) or not is_cross then
			local wear = itemstack:get_wear()
			local bowdef = minetest.registered_items[itemstack:get_name()]
			local bowname = bowdef.description
			local arrow_stack = playerinv:get_stack("main", index + 1)

			for _, arrow in ipairs(throwing_arrows) do
				if arrow_stack:get_name() == arrow[1] then
					-- Remove arrow from beside bow.
					arrow_stack:take_item()
					playerinv:set_stack("main", index + 1, arrow_stack)

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

					-- Don't need to iterate through remaining arrow types.
					playerinv:set_stack("main", index, newstack)
					return
				end
			end
		end
	end
end

-- Bows and crossbows

function throwing_register_bow (name, desc, scale, stiffness, reload_time, toughness, is_cross, craft)
	minetest.register_tool("throwing:" .. name, {
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
				players[pname].reloading = true
				minetest.after(reload_time, throwing_reload, index, indexname, pname, pos, is_cross, "throwing:" .. name .. "_loaded")
			end
		end,
	})
	
	minetest.register_tool("throwing:" .. name .. "_loaded", {
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
	})
	
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
