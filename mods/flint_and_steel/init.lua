
-- Flint & Steel
flint_and_steel = flint_and_steel or {}
flint_and_steel.modpath = minetest.get_modpath("flint_and_steel")

-- Flint & steel on-use callback.
function flint_and_steel.on_use(itemstack, user, pointed_thing)
  if not user or not user:is_player() then return end
  local pname = user:get_player_name()
  local pt = pointed_thing
  if pt.type ~= "node" then return end
  
  -- What are we pointing at?
  local nn = minetest.get_node(pt.under).name

	-- If node has `on_ignite' defined, use that instead.
	local ndef = minetest.reg_ns_nodes[nn]
	if ndef and ndef.on_ignite then
		ndef.on_ignite(pt.under)
	else
		-- does not have `on_ignite' defined!
		local is_coalblock = (nn == "default:coalblock")
		local is_netherack = (nn == "rackstone:redrack" or nn == "rackstone:mg_redrack")
		local is_tnt = (nn == "tnt:tnt")
		local is_gunpowder = (nn == "tnt:gunpowder")
		
		-- Allow stairs, slabs, dark obsidian, etc. to be struck by firestriker.
		-- This comes before protection check so that players can use others' portals.
		if string.find(nn, "obsidian") then
			flameportal.try_teleport_on_flint_use(user)
		end
		if string.find(nn, "obsidian") or string.find(nn, "grieferstone") then
			obsidian_gateway.attempt_activation(pt.under, user)
		end
		
		-- Play sound.
		ambiance.sound_play("fire_flint_and_steel", pt.above, 0.7, 10)
		
		-- Check if fires can be started at this location.
		if not minetest.check_player_privs(user, {server=true}) then
			if minetest.test_protection(pt.under, pname) then
				minetest.chat_send_player(pname, "# Server: That spot is protected from arson!")
				return
			end
		end
		
		if minetest.get_item_group(nn, "flammable") >= 1 or is_coalblock or is_tnt or is_gunpowder or is_netherack then
			local flame_pos = pt.above
			
			if is_coalblock or is_netherack then
				flame_pos = {x = pt.under.x, y = pt.under.y + 1, z = pt.under.z}
			elseif is_tnt or is_gunpowder then
				flame_pos = pt.under
			end
							
			if minetest.get_node(flame_pos).name == "air" or is_tnt or is_gunpowder then
				if is_coalblock then
					minetest.add_node(flame_pos, {name = "fire:permanent_flame"})
				elseif is_netherack then
					minetest.add_node(flame_pos, {name = "fire:nether_flame"})
				elseif is_tnt then
					minetest.add_node(flame_pos, {name = "tnt:tnt_burning"})
				elseif is_gunpowder then
					minetest.add_node(flame_pos, {name = "tnt:gunpowder_burning"})
				else
					minetest.add_node(flame_pos, {name = "fire:basic_flame"})
				end
			end
		elseif nn == "default:obsidian" then
			local result, pos = flameportal.find_gateway(pt.under)
			if result == true and pos then
				flameportal.activate_gateway(pos)
			end
		end
	end

	-- Trigger gas explosions sometimes.
	breath.ignite_nearby_gas(pt.under)
  
  -- Wear tool.
  local wdef = itemstack:get_definition()
  itemstack:add_wear(1000)
  -- Tool break sound.
  if itemstack:get_count() == 0 then
    ambiance.sound_play("default_tool_breaks", pt.above, 0.7, 10)
  end
  return itemstack
end

-- One-time registrations.
if not flint_and_steel.run_once then
  minetest.register_tool("flint_and_steel:flint_and_steel", {
    description = "Flint & Steel",
    inventory_image = "fire_flint_steel.png",
    sound = {breaks = "default_tool_breaks"},
    groups = {not_repaired_by_anvil = 1},
    
    on_use = function(...)
      return flint_and_steel.on_use(...)
    end
  })

  minetest.register_craft({
    output = "flint_and_steel:flint_and_steel",
    recipe = {
      {"default:flint", "default:steel_ingot"},
    }
  })

  minetest.register_alias("fire:flint_and_steel", "flint_and_steel:flint_and_steel")

  local c = "flint_and_steel:core"
  local f = flint_and_steel.modpath .. "/init.lua"
  reload.register_file(c, f, false)
  
  flint_and_steel.run_once = true
end



