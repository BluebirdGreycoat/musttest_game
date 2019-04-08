
itempickup = itempickup or {}
itempickup.modpath = minetest.get_modpath("itempickup")


-- custom particle effects
local function effect(pos, amount, texture, min_size, max_size, radius, gravity, glow)

	radius = radius or 2
	min_size = min_size or 2.0
	max_size = max_size or 6.0
	gravity = gravity or -10
	glow = glow or 0

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = -radius, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = 0, y = gravity, z = 0},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end


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
			local range = 0
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

      local pos -- Initialized only if items are searched.
      local items = {}

			if range > 0 then
				pos = utility.get_middle_pos(v:get_pos())
				items = minetest.get_objects_inside_radius(pos, range)
			end

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


function itempickup.drop_an_item(pos, stack, digger, tool_capabilities)
	local pp = utility.get_middle_pos(digger:get_pos())

	-- Some tools always make their drops go directly to player's inventory.
	local direct = tool_capabilities.direct_to_inventory

	-- Stack goes directly into inventory if player close enough.
	if vector.distance(pp, pos) < 3.5 or direct then
		local inv = digger:get_inventory()
		if inv then
			stack = inv:add_item("main", stack)

			-- If stack couldn't be added because of full inventory, then material is sometimes lost.
			if not stack:is_empty() and math.random(0, 1) == 0 then
				-- Don't drop anything on the ground, 50% chance.
				-- Give particle feedback to player.
				effect(pos, math.random(2, 5), "tnt_smoke.png")
				return
			end
		end
	end

	if not stack:is_empty() then
		local obj = minetest.add_item(pos, stack)

		-- Make the drop fly a bit.
		if obj then
			obj:set_velocity({
				x=math.random(-10, 10) / 5,
				y=3,
				z=math.random(-10, 10) / 5,
			})
		end
	end
end



function itempickup.handle_node_drops(pos, drops, digger)
	-- Nil check.
	if not digger or not digger:is_player() then
		return
	end

	-- Node hasn't been removed yet, we can make use of it. GOOD!
	local node = minetest.get_node(pos) -- Node to be dug.
	local tool = digger:get_wielded_item()
	local tool_meta = tool:get_meta()
	local tool_level = tonumber(tool_meta:get_string("tr_lastlevel")) or 1
	local tn = tool:get_name()
	local xp_drop_enabled = true

	-- Node definition.
	local ndef = minetest.reg_ns_nodes[node.name] or minetest.registered_nodes[node.name]

	-- Nil check.
	if not ndef then
		return
	end

	-- We have to get tool capabilities directly from the itemdef in order to access custom data.
	-- If tool capabilities are not present, use those from the HAND. Note: not doing this
	-- properly was the cause of an embarrassing bug where players could not get items that they
	-- had dug with the hand while wielding another non-tool item.
	local idef = tool:get_definition()
	if not idef then
		return
	end
	local tool_capabilities = idef.tool_capabilities
	if not tool_capabilities then
		tool_capabilities = tooldata["hand_hand"]
		assert(tool_capabilities)
	end
	if tool_capabilities.node_overrides then
		if tool_capabilities.node_overrides[node.name] then
			tool_capabilities = tool_capabilities.node_overrides[node.name]
		end
	end

	-- Max level (toolranks) tool gets its `max_drop_level` improved by 1!
	local max_drop_level = (tool_capabilities.max_drop_level or 0)
	if tool_level >= 7 then
		max_drop_level = max_drop_level + 1
		--minetest.log("max_drop_level increased!") -- Tested, works.
	end

	-- Player does not get node drop if tool doesn't have sufficient level.
	if (max_drop_level) < (ndef.groups.level or 0) then
		-- 1 in 4 chance player will get the node anyway.
		if math.random(1, 4) > 1 then
			-- Particle feedback to player.
			effect(pos, math.random(2, 5), "tnt_smoke.png")
			return
		end
	end

	-- Test tool's chance to destroy node regardless of node/tool levels.
	if tool_capabilities.destroy_chance then
		if math.random(1, 1000) < tool_capabilities.destroy_chance then
			-- Particle feedback to player.
			effect(pos, math.random(2, 5), "tnt_smoke.png")
			return
		end
	end

	local is_basic_tool = (tn:find("pick_") or tn:find("sword_") or tn:find("shovel_") or tn:find("axe_") or tn:find(":axe"))

	-- If node has a drop string/table for silver tools, override drop table.
	-- Player doesn't get XP for nodes dug this way, but that's good (prevents exploit).
	if is_basic_tool and tn:find("silver") then
		if ndef.silverpick_drop then
			local newdrop = ndef.silverpick_drop
			if type(newdrop) == "table" then
				drops = newdrop
			elseif type(newdrop) == "string" then
				drops = {newdrop}
			elseif type(newdrop) == "boolean" and newdrop == true then
				drops = {node.name}
			end
		end
	elseif tn:find("shears") then
		if ndef.shears_drop then
			local newdrop = ndef.shears_drop
			if type(newdrop) == "table" then
				drops = newdrop
			elseif type(newdrop) == "string" then
				drops = {newdrop}
			elseif type(newdrop) == "boolean" and newdrop == true then
				drops = {node.name}
			end
		end
	end

	for _, item in pairs(drops) do
		local stack = ItemStack(item) -- Itemstring to itemstack.
		local sname = stack:get_name()

		-- Give drop to player, or drop on ground.
		itempickup.drop_an_item(pos, stack, digger, tool_capabilities)

		if xp_drop_enabled and drop_xp_list[sname] then
			local value = drop_xp_list[sname]
			local pname = digger:get_player_name()
			local digxp = xp.get_xp(pname, "digxp")

			-- Reward player more when Mineral XP is higher.
			do
				-- Both X's should be in range [0, 1].
				local x1 = math.min(math.max(0, digxp), xp.digxp_max) / xp.digxp_max
				local x2 = math.random(0, 10000)/10000
				if x1*x1 >= x2 then
					if drop_extra_item_list[sname] then
						-- Give drop to player, or drop on ground.
						itempickup.drop_an_item(pos, stack, digger, tool_capabilities)
					end
				end
			end

			-- Increase player's XP if not at max yet.
			if digxp < xp.digxp_max then
				digxp = digxp + (value * (tool_capabilities.xp_gain or 1.0))
				if digxp > xp.digxp_max then
					digxp = xp.digxp_max
				end
				xp.set_xp(pname, "digxp", digxp)
				hud_clock.update_xp(pname)
			end
		end -- If item in drop_xp list.
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

