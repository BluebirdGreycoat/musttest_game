
-- Localize for performance.
local math_floor = math.floor



if not minetest.global_exists("toolranks") then toolranks = {} end
toolranks.modpath = minetest.get_modpath("toolranks")
toolranks.players = toolranks.players or {}
toolranks.tools = toolranks.tools or {}

local players = toolranks.players
if not toolranks.mod_storage then
	toolranks.mod_storage = minetest.get_mod_storage()
end
local mod_storage = toolranks.mod_storage

toolranks.colors = {
  grey = minetest.get_color_escape_sequence("#9d9d9d"),
  green = minetest.get_color_escape_sequence("#1eff00"),
  gold = minetest.get_color_escape_sequence("#ffdf00"),
  white = minetest.get_color_escape_sequence("#ffffff")
}

function toolranks.get_tool_type(description)
  if string.find(description, "Pickaxe") then
    return "pickaxe"
  elseif string.find(description, "Axe") then
    return "axe"
  elseif string.find(description, "Shovel") then
    return "shovel"
  elseif string.find(description, "Hoe") then
    return "hoe"
	elseif string.find(description, "Sword") then
		return "sword"
  else
    return "tool"
  end
end

-- Used to apply multiple descriptions into a single description.
-- Any mod wanting to change a tool's description meta should go through this.
function toolranks.apply_description(itemmeta, def)
	local desc1 = itemmeta:get_string("en_desc") or ""
	local desc2 = itemmeta:get_string("tr_desc") or ""
	local desc3 = itemmeta:get_string("ar_desc") or ""

	if desc1 == "" then
		-- No custom description set by engraver, etc.?
		-- Use original description.
		desc1 = def.original_description or ""
		if desc1 == "" then
			desc1 = def.description or ""
		end
	end
	if desc2 == "" then
		-- Nothing assigned by TR yet? Use default TR desc, if any.
		desc2 = def.original_tr_description or ""
	end
	if desc3 ~= "" then
		desc3 = "Loaded: " .. desc3
	end

	if desc2 ~= "" then
		-- Have toolranks description? Seperate with newlines.
		desc1 = desc1 .. "\n\n"
	end
	if desc3 ~= "" then
		desc2 = desc2 .. "\n\n"
	end

	itemmeta:set_string("description", desc1 .. desc2 .. desc3)
end

function toolranks.create_description(name, uses, level)
  local description = utility.get_short_desc(name)
  local tooltype    = toolranks.get_tool_type(description)

	local strpart = "Nodes dug"
	if tooltype == "sword" then
		strpart = "Blows struck"
	elseif tooltype == "pickaxe" then
		strpart = "Resources picked"
	elseif tooltype == "axe" then
		strpart = "Resources chopped"
	elseif tooltype == "shovel" then
		strpart = "Resources shoveled"
	end

  local newdesc = toolranks.colors.green .. description .. "\n" ..
                  toolranks.colors.gold .. "Level " .. (level or 1) .. " " .. tooltype .. "\n" ..
                  toolranks.colors.grey .. strpart .. ": " .. (uses or 0)

  return newdesc
end

function toolranks.get_level(uses, max_uses, old_level)
	-- Uncomment this to enable rapidly testing the tool-rank leveling function.
	--max_uses = 5

	local lvl = 1
	-- subtract 1 from max_uses so that the tool levels up right before it is broken
  if uses <= max_uses-1 then
    lvl = 1
  elseif uses < max_uses*2-1 then
    lvl = 2
  elseif uses < max_uses*3-1 then
    lvl = 3
  elseif uses < max_uses*4-1 then
    lvl = 4
  elseif uses < max_uses*5-1 then
    lvl = 5
	elseif uses < max_uses*7-1 then -- level 7 requires twice the number of nodes dug as previous levels
		lvl = 6
  else
    lvl = 7 -- at level 7, tool wear is cut in half
  end
	if lvl < old_level then
		lvl = old_level
	end
	return lvl
end

-- API function: allow to get the rank-level of a tool,
-- (or 0, if the item is not a tool).
-- The lowest possible (valid) rank is 1.
function toolranks.get_tool_level(item)
	local name = item:get_name()
	local count = item:get_count()

	if count == 1 and toolranks.tools[name] then
		local meta = item:get_meta()
		local rank = tonumber(meta:get_string("tr_lastlevel")) or 1
		return rank
	end

	return 0
end

function toolranks.new_afteruse(itemstack, user, node, digparams)
	-- If either is not specified, then behave like builtin.
	if not user or not node then
		itemstack:add_wear(digparams.wear)
		return itemstack
	end

	local pname = user:get_player_name()

	-- Initialize data if not already done.
	local pdata = players[pname]
	if not pdata then
		players[pname] = {}
		pdata = players[pname]

		-- Default values.
		pdata.last_node = node.name -- Name of the last node dug, used for caching.
		pdata.last_ignore = false

		local ndef = minetest.registered_nodes[node.name]
		if ndef then
			if ndef._toolranks then
				if ndef._toolranks.ignore then
					pdata.last_ignore = true
				end
			end
		else
			-- Ignore unknown nodes.
			pdata.last_ignore = true
		end
	end

	-- Get cached player data.
	if pdata.last_node ~= node.name then
		pdata.last_node = node.name
		pdata.last_ignore = false

		-- If this node is different from the last node, update cached information.
		local ndef = minetest.registered_nodes[node.name]
		if ndef then
			if ndef._toolranks then
				if ndef._toolranks.ignore then
					pdata.last_ignore = true
				end
			end
		else
			-- Ignore unknown nodes.
			pdata.last_ignore = true
		end
	end

	local ignore_this_node = pdata.last_ignore
  local itemmeta  = itemstack:get_meta() -- Metadata
  local itemdef   = itemstack:get_definition() -- Item Definition
  local itemdesc  = itemdef.original_description -- Original Description
  local dugnodes  = tonumber(itemmeta:get_string("tr_dug")) or 0 -- Number of nodes dug
  local lastlevel = tonumber(itemmeta:get_string("tr_lastlevel")) or 1 -- Level the tool had

  -- Only count nodes that spend the tool
	if not ignore_this_node then
		if(digparams.wear > 0) then
		dugnodes = dugnodes + 1
		itemmeta:set_string("tr_dug", dugnodes)
		end
	end

	-- pass total number of nodes (of this type) that could be dug assuming no tool repairs, as second param to this function
  local level = toolranks.get_level(dugnodes, math_floor(65535 / digparams.wear), lastlevel)

	-- New level should never be less than the old level.
  if lastlevel < level then
    local levelup_text = "# Server: Your " .. utility.get_short_desc(itemstack) .. " just leveled up!"
    ambiance.sound_play("toolranks_levelup", user:get_pos(), 1.0, 20)
    minetest.chat_send_player(pname, levelup_text)
    itemmeta:set_string("tr_lastlevel", level)
  end

  local newdesc = toolranks.create_description(itemdesc, dugnodes, level)

	itemmeta:set_string("tr_desc", newdesc)
	toolranks.apply_description(itemmeta, itemdef)
  local wear = digparams.wear
  if level > 1 then
    wear = digparams.wear / (1 + level / 4)
  end

  --minetest.chat_send_all("wear="..wear.."Original wear: "..digparams.wear.." 1+level/4="..1+level/4)
  -- Uncomment for testing ^

  itemstack = utility.wear_tool_with_feedback({
		item = itemstack,
		user = user,
		wear = wear,
	})
  return itemstack
end



if not toolranks.registered then
	local function override_item(name)
		--print(name)
		toolranks.tools[name] = true
		local itemdef = table.copy(minetest.registered_items[name])

		-- Found out by reading MT sources that these must both be nill'ed.
		-- Otherwise we get error: Attempt to redefine name of X to "X".
		itemdef.name = nil
		itemdef.type = nil

		local tr_desc = toolranks.create_description(itemdef.description, 0, 1)

		itemdef.original_description = itemdef.description
		itemdef.description = itemdef.description .. "\n\n" .. tr_desc
		itemdef.original_tr_description = tr_desc
		itemdef.after_use = function(...) return toolranks.new_afteruse(...) end

		minetest.override_item(name, itemdef)
	end

	override_item("default:pick_diamond")
	override_item("default:axe_diamond")
	override_item("default:shovel_diamond")
	override_item("default:pick_wood")
	--override_item("default:axe_wood")
	--override_item("default:shovel_wood")
	override_item("default:pick_steel")
	override_item("default:axe_steel")
	override_item("default:shovel_steel")
	override_item("default:pick_stone")
	override_item("default:axe_stone")
	override_item("default:shovel_stone")
	override_item("default:pick_bronze")
	override_item("default:axe_bronze")
	override_item("default:shovel_bronze")
	override_item("default:pick_bronze2")
	override_item("default:axe_bronze2")
	override_item("default:shovel_bronze2")
	override_item("default:pick_mese")
	override_item("default:axe_mese")
	override_item("default:shovel_mese")

	if minetest.get_modpath("moreores") then
		override_item("moreores:pick_mithril")
		override_item("moreores:axe_mithril")
		override_item("moreores:shovel_mithril")
		override_item("moreores:sword_mithril")
		override_item("moreores:pick_silver")
		override_item("moreores:axe_silver")
		override_item("moreores:shovel_silver")
		override_item("moreores:sword_silver")
	end

	-- add swords for snappy nodes
	--override_item("default:sword_wood")
	override_item("default:sword_stone")
	override_item("default:sword_steel")
	override_item("default:sword_bronze")
	override_item("default:sword_bronze2")
	override_item("default:sword_mese")
	override_item("default:sword_diamond")

	if minetest.get_modpath("titanium") then
		override_item("titanium:sword")
		override_item("titanium:axe")
		override_item("titanium:shovel")
		override_item("titanium:pick")
	end

	if minetest.get_modpath("gem_tools") then
		override_item("gems:sword_emerald")
		override_item("gems:axe_emerald")
		override_item("gems:shovel_emerald")
		override_item("gems:pick_emerald")
		override_item("gems:sword_ruby")
		override_item("gems:axe_ruby")
		override_item("gems:shovel_ruby")
		override_item("gems:pick_ruby")
		override_item("gems:sword_amethyst")
		override_item("gems:axe_amethyst")
		override_item("gems:shovel_amethyst")
		override_item("gems:pick_amethyst")
		override_item("gems:sword_sapphire")
		override_item("gems:axe_sapphire")
		override_item("gems:shovel_sapphire")
		override_item("gems:pick_sapphire")

		override_item("gems:rf_sword_emerald")
		override_item("gems:rf_axe_emerald")
		override_item("gems:rf_shovel_emerald")
		override_item("gems:rf_pick_emerald")
		override_item("gems:rf_sword_ruby")
		override_item("gems:rf_axe_ruby")
		override_item("gems:rf_shovel_ruby")
		override_item("gems:rf_pick_ruby")
		override_item("gems:rf_sword_amethyst")
		override_item("gems:rf_axe_amethyst")
		override_item("gems:rf_shovel_amethyst")
		override_item("gems:rf_pick_amethyst")
		override_item("gems:rf_sword_sapphire")
		override_item("gems:rf_axe_sapphire")
		override_item("gems:rf_shovel_sapphire")
		override_item("gems:rf_pick_sapphire")
	end

	local c = "toolranks:core"
	local f = toolranks.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	toolranks.registered = true
end




