
itempickup = itempickup or {}
itempickup.modpath = minetest.get_modpath("itempickup")



itempickup.sound = function(pos)
  ambiance.sound_play("itempickup_pickup", pos, 0.07, 20)
end



local pickuptimer = 0
itempickup.update = function(dtime)
	-- Time delay 0.5 second.
	pickuptimer = pickuptimer + dtime
	if pickuptimer < 0.5 then
		return
	end
	pickuptimer = 0
	--collectgarbage("step") -- Do not enable - causes huge issues.

  local players = minetest.get_connected_players()
  for k, v in ipairs(players) do
		rc.check_position(v) -- Check position before calling `get_objects_inside_radius'.

		local pname = v:get_player_name()
    if v:is_player() and v:get_hp() > 0 and not gdac_invis.is_invisible(pname) then
			-- Basic range, when player is standing still.
			local range = 0.5
			local sneak = false
			local control = v:get_player_control()

			-- Sneaking increases pickup range.
			if control.sneak or control.aux1 then
				range = 3.5
				sneak = true
			end

			-- Range is increased a bit when digging.
			-- This is because items are dropped when nodes are dug,
			-- but it would be too annoying if even nodes right next
			-- to the player were dropped on the ground.
			if control.LMB then
				range = 2.5
			end

			-- Moving increases pickup range a little (not as much as sneak).
			if control.up or control.left or control.right then
				-- Override `sneak`.
				range = 1.5
			end
      
      local pos = utility.get_middle_pos(v:get_pos())
      local items = minetest.get_objects_inside_radius(pos, range)

      local inv
      if #items > 0 then
				inv = v:get_inventory()
			end

      for m, n in ipairs(items) do
        -- Ensure object found is an item-drop.
				local luaent = n:get_luaentity()
        if not n:is_player() and luaent and luaent.name == "__builtin:item" then
          local name = luaent.itemstring
          if name ~= "" then -- Some itemstacks have empty names.
						if not control.aux1 then
							if luaent.dropped_by and type(luaent.dropped_by) == "string" then
								if luaent.dropped_by == pname then
									goto next_drop
								end
							end
						end
						local item = ItemStack(name)

						-- Ensure player's inventory has enough room.
						if inv and inv:room_for_item("main", item) then
							inv:add_item("main", item)
							itempickup.sound(pos)
							luaent.itemstring = "" -- Prevents item duplication.
							n:remove()
						end
          end
        end
				::next_drop::
			end
    end
  end
end



-- Anything not listed here is assumed to have an XP value of 0.
-- Be carefull not to include nodes that can be dug over and over again.
local drop_xp_list = {
	["akalin:lump"] = 1.0,
	["alatro:lump"] = 1.0,
	["arol:lump"] = 1.0,
	["chromium:lump"] = 1.0,
	["gems:raw_ruby"] = 10.0,
	["gems:raw_emerald"] = 10.0,
	["gems:raw_sapphire"] = 10.0,
	["gems:raw_amethyst"] = 10.0,
	["kalite:lump"] = 0.1,
	["lead:lump"] = 1.0,
	["default:coal_lump"] = 0.1,
	["default:iron_lump"] = 1.0,
	["default:copper_lump"] = 1.0,
	["default:gold_lump"] = 2.0,
	["default:mese_crystal"] = 2.0,
	["default:diamond"] = 5.0,
	["moreores:tin_lump"] = 0.5,
	["moreores:silver_lump"] = 1.0,
	["moreores:mithril_lump"] = 20.0,
	["glowstone:glowing_dust"] = 1.0,
	["quartz:quartz_crystal"] = 0.5,
	["talinite:lump"] = 1.0,
	["titanium:titanium"] = 1.0,
	["uranium:lump"] = 1.0,
	["zinc:lump"] = 1.0,
	["sulfur:lump"] = 0.1,
}
local drop_xp_multiplier = 1.0
for k, v in pairs(drop_xp_list) do
	drop_xp_list[k] = v * drop_xp_multiplier
end

-- Stuff listed here is what player can actually get, if XP == max.
-- Be carefull not to include nodes that can be dug over and over again.
local drop_extra_item_list = {
	["akalin:lump"] = true,
	["alatro:lump"] = true,
	["arol:lump"] = true,
	["chromium:lump"] = true,
	["gems:raw_ruby"] = true,
	["gems:raw_emerald"] = true,
	["gems:raw_sapphire"] = true,
	["gems:raw_amethyst"] = true,
	["kalite:lump"] = true,
	["lead:lump"] = true,
	["default:coal_lump"] = true,
	["default:iron_lump"] = true,
	["default:copper_lump"] = true,
	["default:gold_lump"] = true,
	["default:mese_crystal"] = true,
	["default:diamond"] = true,
	["default:mese"] = true,
	["mese_crystals:mese_crystal_ore1"] = true,
	["mese_crystals:mese_crystal_ore2"] = true,
	["mese_crystals:mese_crystal_ore3"] = true,
	["mese_crystals:mese_crystal_ore4"] = true,
	["moreores:tin_lump"] = true,
	["moreores:silver_lump"] = true,
	["moreores:mithril_lump"] = true,
	["glowstone:glowing_dust"] = true,
	["quartz:quartz_crystal"] = true,
	["talinite:lump"] = true,
	["titanium:titanium"] = true,
	["uranium:lump"] = true,
	["zinc:lump"] = true,
	["sulfur:lump"] = true,
}


function itempickup.drop_an_item(pos, iname, digger)
	local pp = utility.get_middle_pos(digger:get_pos())
	if vector.distance(pp, pos) < 3.5 then
		local inv = digger:get_inventory()
		local left = inv:add_item("main", iname)
		iname = left
	end
	local obj = minetest.add_item(pos, iname)
	if obj then
		obj:set_velocity({
			x=math.random(-10, 10) / 10,
			y=0.5,
			z=math.random(-10, 10) / 10,
		})
	end
end



function itempickup.handle_node_drops(pos, drops, digger)
	for k, item in ipairs(drops) do
		local ss = ""
		if type(item) == "string" then
			ss = item
		else
			ss = item:to_string()
		end

		itempickup.drop_an_item(pos, ss, digger)

		if digger and digger:is_player() then
			local stackname = ItemStack(ss):get_name()
			local ndef = minetest.reg_ns_nodes[stackname] or
				minetest.registered_nodes[stackname]

			if drop_xp_list[stackname] and ndef then
				local value = drop_xp_list[stackname]
				local pname = digger:get_player_name()
				--minetest.chat_send_player(
				--	"MustTest", "# Server: <" .. pname .. "> got drop '" .. stackname ..
				--	"' at " .. minetest.pos_to_string(pos) .. " with XP " .. value .. "!")

				local digxp = xp.get_xp(pname, "digxp")

				-- Reward player more when Mineral XP is higher.
				do
					-- Both X's should be in range [0, 1].
					local x1 = math.min(math.max(0, digxp), xp.digxp_max) / xp.digxp_max
					local x2 = math.random(0, 10000)/10000
					if x1*x1 >= x2 then
						if drop_extra_item_list[stackname] then
							itempickup.drop_an_item(pos, stackname, digger)
						end
					end
				end

				-- Increase player's XP if not at max yet.
				if digxp < xp.digxp_max then
					digxp = digxp + value
					if digxp > xp.digxp_max then
						digxp = xp.digxp_max
					end
					xp.set_xp(pname, "digxp", digxp)
					hud_clock.update_xp(pname)
				end
			end
		end
	end
end



-- First-time initialization code.
if not itempickup.run_once then
  minetest.register_globalstep(function(...) itempickup.update(...) end)

  local name = "itempickup:core"
  local file = itempickup.modpath .. "/init.lua"
  reload.register_file(name, file, false)
  
	function minetest.handle_node_drops(pos, drops, player)
		return itempickup.handle_node_drops(pos, drops, player)
	end

  itempickup.run_once = true
end

