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
  
	itemstack:set_metadata("")
	imeta:set_string("arrow", nil)
	imeta:set_string("description", nil)
	player:set_wielded_item(itemstack)
	local playerpos = player:getpos()
	local obj = minetest.add_entity({x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, arrow)
  if not obj then return end
  if not obj:get_luaentity() then return end
  
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
	return true
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
					player:get_inventory():add_item("main", arrow[1])
				end
			end
		end
	end
	if wear >= 65535 then
		player:set_wielded_item({})
	else
		player:set_wielded_item({name=unloaded, wear=wear})
	end
end

function throwing_arrow_punch_entity (obj, self, damage)
  local player = minetest.get_player_by_name(self.player_name or "")
  if player and player:is_player() then
    -- The target of the arrow sees the shooter as the attacker,
    -- *not* the arrow entity itself. If this were not so, players
    -- could shoot mobs with arrows without retaliation.
    obj:punch(player, 1.0, {
      full_punch_interval=1.0,
      damage_groups={fleshy=damage},
    }, nil)
  else
    obj:punch(self.object, 1.0, {
      full_punch_interval=1.0,
      damage_groups={fleshy=damage},
    }, nil)
  end
end

function throwing_reload (itemstack, pname, pos, is_cross, loaded)
	local player = minetest.get_player_by_name(pname)

	-- Check for nil. Can happen if player leaves game right after reloading.
	if not player or not players[pname] then
		return
	end

	players[pname].reloading = false

	if itemstack:get_name() == player:get_wielded_item():get_name() then
		if (pos.x == player:getpos().x and pos.y == player:getpos().y and pos.z == player:getpos().z) or not is_cross then
			local wear = itemstack:get_wear()
			local bowname = minetest.registered_items[itemstack:get_name()].description
			for _,arrow in ipairs(throwing_arrows) do
				if player:get_inventory():get_stack("main", player:get_wield_index()+1):get_name() == arrow[1] then
					if not minetest.setting_getbool("creative_mode") then
						player:get_inventory():remove_item("main", arrow[1])
					end
					local name = arrow[1]
					local arrowdesc = minetest.registered_items[name].description
					local entity = arrow[2]
					local newstack = ItemStack(loaded)
					newstack:set_wear(wear)
					local imeta = newstack:get_meta()
					imeta:set_string("arrow", entity)
					imeta:set_string("description", bowname .. " (Loaded: " .. arrowdesc .. ")")
					player:set_wielded_item(newstack)
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
		on_use = function(itemstack, user, pointed_thing)
			local pos = user:get_pos()
			local pname = user:get_player_name()
			if not players[pname].reloading then
				players[pname].reloading = true
				minetest.after(reload_time, throwing_reload, itemstack, pname, pos, is_cross, "throwing:" .. name .. "_loaded")
			end
			return itemstack
		end,
	})
	
	minetest.register_tool("throwing:" .. name .. "_loaded", {
		description = desc,
		inventory_image = "throwing_" .. name .. "_loaded.png",
		wield_scale = scale,
	    stack_max = 1,
		on_use = function(itemstack, user, pointed_thing)
			local wear = itemstack:get_wear()
			--if not minetest.setting_getbool("creative_mode") then
				wear = wear + (65535/toughness)
			--end
			local unloaded = "throwing:" .. name
			throwing_shoot_arrow(itemstack, user, stiffness, is_cross)
			minetest.after(0, throwing_unload, itemstack, user, unloaded, wear)				
			return itemstack
		end,
		on_drop = function(itemstack, dropper, pointed_thing)
			local wear = itemstack:get_wear()
			local unloaded = "throwing:" .. name
			minetest.after(0, throwing_unload, itemstack, dropper, unloaded, wear)
		end,
		groups = {not_in_creative_inventory=1, not_repaired_by_anvil=1},
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
  
  local def = minetest.registered_nodes[nn]
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
