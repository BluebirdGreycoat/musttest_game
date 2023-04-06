
if not minetest.global_exists("default") then default = {} end
if not minetest.global_exists("utility") then utility = {} end
utility.modpath = minetest.get_modpath("utility")

-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_random = math.random

-- Dummy function.
fireambiance = {}
function fireambiance.on_flame_addremove(pos)
end

function utility.trim_remove_special_chars(msg)
	local sub = string.gsub
	msg = sub(msg, "%z", "") -- Zero byte.
	msg = sub(msg, "%c", "") -- Control bytes.

	-- Trim whitespace.
	msg = sub(msg, "^%s+", "")
	msg = sub(msg, "%s+$", "")

	return msg
end

-- `level = 0/1, snappy = 3` enables quick digging via shears.
-- Otherwise item cannot be dug by shears at all.
--
-- The 'hand' only digs items `level = 0` or `level = 1`, with some additional
-- restrictions. See tool-data file for details.
--
-- Important/hard-to-craft nodes should be level 0 (like machines) otherwise
-- player will lose the item if dug with a tool without a high enough level.
--
-- Shears only dig nodes with `level = 0/1, snappy = 3`.
--
-- `oddly_breakable_by_hand` only works if `level = 0/1`. HOWEVER, node drops
-- can ONLY be obtained if the node's level is 0! Level 1 nodes may be dug if
-- they're `oddly_breakable_by_hand`, but the player won't get the drops.
--
-- Base hardness for regular stone is `level = 2, cracky = 2`. Cobble is at
-- `level = 1, cracky = 3`. These are both carefully tuned to allow new players
-- to advance: wooden pick digs cobble to make stone pick, and a stone pick is
-- able to dig regular stone. All other rocks/stones in the game should have
-- their hardness calculated around regular stone/cobble.
--
-- The base hardness for tree trunks is `level = 2, choppy = 2`. Wood is
-- calculated at `level = 2, choppy = 3`. All other wooden nodes should be
-- calculated around these two.

local dig_groups = {}

-- Special undiggable group.
dig_groups["ignore"]        = {}

-- Cracky stuff (stones/rocks/minerals).
dig_groups["stone"]         = {level = 2, cracky = 2} -- Carefully tuned dig-params! Do not modify.
dig_groups["softstone"]     = {level = 2, cracky = 3} -- Like sandstone.
dig_groups["cobble"]        = {level = 1, cracky = 3} -- Must be `cracky=3` otherwise cannot be dug by wooden pick.
dig_groups["softcobble"]    = {level = 1, cracky = 3, crumbly = 1} -- Can be dug by wodden pick.
dig_groups["clay"]          = {level = 0, cracky = 2, crumbly = 2}
dig_groups["hardore"]       = {level = 2, cracky = 1}
dig_groups["hardclay"]      = {level = 1, cracky = 2}
dig_groups["ice"]           = {level = 0, cracky = 2}
dig_groups["hardice"]       = {level = 1, cracky = 1}
dig_groups["glass"]         = {level = 1, cracky = 3}
dig_groups["netherack"]     = {level = 1, cracky = 3, oddly_breakable_by_hand = 1} -- Easiest thing to dig, practically!
dig_groups["mineral"]       = {level = 2, cracky = 3}
dig_groups["hardmineral"]   = {level = 2, cracky = 1}
dig_groups["obsidian"]      = {level = 3, cracky = 1} -- Obsidian, etc. Hardest possible.
dig_groups["hardstone"]     = {level = 3, cracky = 2} -- Granites, marbles.
dig_groups["crystal"]       = {level = 2, cracky = 3}

-- Cracky stuff (building blocks/walls/bricks/etc).
dig_groups["wall"]          = {level = 1, cracky = 2}
dig_groups["brick"]         = {level = 1, cracky = 1}
dig_groups["block"]         = {level = 1, cracky = 1} -- Stone blocks, metal blocks, etc.

-- Crumbly stuff (loose earth material).
dig_groups["gravel"]        = {level = 2, crumbly = 2} -- Cannot be dug by hand (level 1).
dig_groups["dirt"]          = {level = 2, crumbly = 3}
dig_groups["sand"]          = {level = 1, crumbly = 2}
dig_groups["snow"]          = {level = 0, crumbly = 3, oddly_breakable_by_hand = 3}
dig_groups["mud"]           = {level = 0, crumbly = 3, oddly_breakable_by_hand = 1}
dig_groups["racksand"]      = {level = 2, crumbly = 3}

-- Choppy stuff (trees/wood).
dig_groups["tree"]          = {level = 2, choppy = 2} -- Carefully tuned dig-params! Do not change.
dig_groups["deadtree"]      = {level = 0, choppy = 2, oddly_breakable_by_hand = 1}
dig_groups["wood"]          = {level = 2, choppy = 3} -- Also wooden 'blocklike'. Planks & stuff.
dig_groups["nyan"]          = {level = 3, choppy = 1}

-- Choppy stuff (crafted building materials).
dig_groups["hardwood"]      = {level = 1, choppy = 1}
dig_groups["softwood"]      = {level = 1, choppy = 3} -- Cactus, etc.

-- Snappy stuff (plants/crops/leaves).
-- Plants/crops can be dug by hand, but leaves cannot without proper tool.
-- Addendum: player can dig leaves by hand but won't get drops.
dig_groups["leaves"]        = {level = 1, snappy = 3, choppy = 2, oddly_breakable_by_hand = 1} -- Must be `snappy=3` otherwise shears won't work.
dig_groups["seeds"]         = {level = 1, snappy = 2, oddly_breakable_by_hand = 3}
dig_groups["plant"]         = {level = 0, snappy = 3, choppy = 2} -- Must be `snappy=3` otherwise shears won't work.
dig_groups["crop"]          = {level = 0, snappy = 3, choppy = 2} -- Ditto ^^^. Also diggable by hand.
dig_groups["straw"]         = {level = 1, snappy = 2, choppy = 1, oddly_breakable_by_hand = 1}
dig_groups["shroom"]        = {level = 1, snappy = 2, choppy = 3, oddly_breakable_by_hand = 1}

-- Misc items (items/machines/furniture/etc).
dig_groups["wool"]          = {level = 1, snappy = 3, choppy = 3}
dig_groups["pane_wood"]     = {level = 1, choppy = 3}
dig_groups["pane_metal"]    = {level = 1, cracky = 2}
dig_groups["pane_glass"]    = {level = 1, cracky = 3}
dig_groups["fence_metal"]   = {level = 1, cracky = 2}
dig_groups["fence_wood"]    = {level = 1, choppy = 2}
dig_groups["furniture"]     = {level = 0, snappy = 1, choppy = 3, oddly_breakable_by_hand = 3}
dig_groups["item"]          = {level = 0, dig_immediate = 3}
dig_groups["bigitem"]       = {level = 0, dig_immediate = 2}
dig_groups["door_metal"]    = {level = 1, cracky = 1}
dig_groups["door_glass"]    = {level = 1, cracky = 2}
dig_groups["door_wood"]     = {level = 1, choppy = 2}
dig_groups["door_woodglass"]= {level = 1, choppy = 1}
dig_groups["door_stone"]    = {level = 1, cracky = 1}
dig_groups["scaffolding"]   = {level = 0, dig_immediate = 2}
dig_groups["chest"]         = {level = 0, choppy = 3, oddly_breakable_by_hand = 3}
dig_groups["metalchest"]    = {level = 0, cracky = 3, oddly_breakable_by_hand = 3}
dig_groups["machine"]       = {level = 0, cracky = 3} -- Must be level 0, or player may lose machine when dug!

-- Get dig groups for a node based on its broad category.
-- When choosing a name for a node, choose the name closest to the node's main material.
function utility.dig_groups(name, ex)
	local groups = {}

	if not dig_groups[name] then
		minetest.log("error", "Could not find data for digging group '" .. name .. "'!")
	end

	local dig = dig_groups[name] or {level = 1, oddly_breakable_by_hand = 3}
	for k, v in pairs(dig) do
		groups[k] = v
	end

	-- Let custom groups override, include other stuff from groups.
	if ex then
		for k, v in pairs(ex) do
			groups[k] = v
		end
	end

	return groups
end

-- Copy standard/builtin groups only.
-- Used mainly to ensure that stairs/microblock nodes don't include strange groups
-- that should ONLY apply to their parent fullblock nodes.
--
-- Shall not return any groups used in crafting recipes!
-- Shall return any/all groups required by tools!
function utility.copy_builtin_groups(old_groups)
	local groups = {}
	groups.level = old_groups.level or 1

	if old_groups.crumbly then
		groups.crumbly = old_groups.crumbly
	end
	if old_groups.cracky then
		groups.cracky = old_groups.cracky
	end
	if old_groups.snappy then
		groups.snappy = old_groups.snappy
	end
	if old_groups.choppy then
		groups.choppy = old_groups.choppy
	end
	if old_groups.oddly_breakable_by_hand then
		groups.oddly_breakable_by_hand = old_groups.oddly_breakable_by_hand
	end
	if old_groups.flammable then
		groups.flammable = old_groups.flammable
	end
	if old_groups.dig_immediate then
		groups.dig_immediate = old_groups.dig_immediate
	end

	return groups
end

function utility.inventory_count_items(inv, listname, itemname)
	local list = inv:get_list(listname)
	local count = 0
	for i = 1, #list, 1 do
		if list[i]:get_name() == itemname then
			count = count + list[i]:get_count()
		end
	end
	return count
end

function utility.get_short_desc(str)
	if string.find(str, "[\n%(]") then
		str = string.sub(str, 1, string.find(str, "[\n%(]")-1)
	end
	str = string.gsub(str, "^%s+", "")
	str = string.gsub(str, "%s+$", "")
	return str
end

dofile(utility.modpath .. "/particle_override.lua")
dofile(utility.modpath .. "/mapsave.lua")
dofile(utility.modpath .. "/functions.lua")
dofile(utility.modpath .. "/getopts.lua")

-- Get a player's foot position, given the player's position.
-- Should help compatibility going into 0.5.0 and beyond.
function utility.get_foot_pos(pos)
	return vector.add(pos, {x=0, y=0, z=0})
end
function utility.get_middle_pos(pos)
	return vector.add(pos, {x=0, y=1, z=0})
end
function utility.get_head_pos(pos)
	return vector.add(pos, {x=0, y=1.75, z=0})
end
-- Get rounded position of node player is standing on.
function utility.node_under_pos(pos)
	return vector_round(vector.add(pos, {x=0, y=-0.05, z=0}))
end

-- Global multipliers for ABMs. Performance setting.
default.ABM_TIMER_MULTIPLIER = 1
default.ABM_CHANCE_MULTIPLIER = 2

-- Global player-movement multiplier values.
default.ROAD_SPEED = 1.3
default.ROAD_SPEED_NETHER = 1.1
default.ROAD_SPEED_CAVERN = 1.15
default.SLOW_SPEED = 0.7
default.SLOW_SPEED_SNOW_LIGHT = 0.95
default.SLOW_SPEED_SNOW = 0.75
default.SLOW_SPEED_SNOW_THICK = 0.6
default.SLOW_SPEED_SNOW_TRACKS_ADDITIVE = 0.15
default.SLOW_SPEED_NETHER = 0.85
default.SLOW_SPEED_ICE = 0.85
default.SLOW_SPEED_GRASS = 0.85
default.SLOW_SPEED_PLANTS = 0.55
default.NORM_SPEED = 1.0
default.ROPE_SPEED = 1.1

default.FAST_JUMP = 1.0
default.SLOW_JUMP = 1.0
default.NORM_JUMP = 1.0



function utility.transform_nodebox(nodebox)
	for k, v in ipairs(nodebox) do
		for m, n in ipairs(v) do
			local p = nodebox[k][m]
			p = p / 16
			p = p - 0.5
			nodebox[k][m] = p
		end
	end
	return nodebox
end



-- Public API function. Sort two positions such that the first is always less than the second.
utility.sort_positions = function(p1, p2)
  local pos1 = {x=p1.x, y=p1.y, z=p1.z}
  local pos2 = {x=p2.x, y=p2.y, z=p2.z}
    
  if pos1.x > pos2.x then pos2.x, pos1.x = pos1.x, pos2.x end
  if pos1.y > pos2.y then pos2.y, pos1.y = pos1.y, pos2.y end
  if pos1.z > pos2.z then pos2.z, pos1.z = pos1.z, pos2.z end
    
  return pos1, pos2
end



--
-- optimized helper to put all items in an inventory into a drops list
--

function default.get_inventory_drops(pos, inventory, drops)
  local inv = minetest.get_meta(pos):get_inventory()
  local n = #drops
  for i = 1, inv:get_size(inventory) do
    local stack = inv:get_stack(inventory, i)
    if stack:get_count() > 0 then
      drops[n+1] = stack:to_table()
      n = n + 1
    end
  end
end


--
-- dig upwards
--

function default.dig_up(pos, node, digger)
  if digger == nil then return end
  local np = {x = pos.x, y = pos.y + 1, z = pos.z}
  local nn = minetest.get_node(np)
  if nn.name == node.name then
    minetest.node_dig(np, nn, digger)
  end
end

--
-- Checks if specified volume intersects a protected volume
--

function default.intersects_protection(minp, maxp, player_name, interval)
  -- 'interval' is the largest allowed interval for the 3D lattice of checks

  -- Compute the optimal float step 'd' for each axis so that all corners and
  -- borders are checked. 'd' will be smaller or equal to 'interval'.
  -- Subtracting 1e-4 ensures that the max co-ordinate will be reached by the
  -- for loop (which might otherwise not be the case due to rounding errors).
  local d = {}
  for _, c in pairs({"x", "y", "z"}) do
    if maxp[c] > minp[c] then
      d[c] = (maxp[c] - minp[c]) / math.ceil((maxp[c] - minp[c]) / interval) - 1e-4
    elseif maxp[c] == minp[c] then
      d[c] = 1 -- Any value larger than 0 to avoid division by zero
    else -- maxp[c] < minp[c], print error and treat as protection intersected
      minetest.log("error", "maxp < minp in 'default.intersects_protection()'")
      return true
    end
  end

  for zf = minp.z, maxp.z, d.z do
    local z = math_floor(zf + 0.5)
    for yf = minp.y, maxp.y, d.y do
      local y = math_floor(yf + 0.5)
      for xf = minp.x, maxp.x, d.x do
        local x = math_floor(xf + 0.5)
        if minetest.test_protection({x = x, y = y, z = z}, player_name) then
          return true
        end
      end
    end
  end

  return false
end



default.get_raillike_selection_box = function()
  return {
    type = "fixed",
    -- but how to specify the dimensions for curved and sideways rails?
    fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
  }
end

default.get_raillike_collision_box = function()
  return {
    type = "fixed",
    fixed = {
      {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
    },
  }
end


--
-- Sapling 'on place' function to check protection of node and resulting tree volume
--

function default.sapling_on_place(itemstack, placer, pointed_thing,
		sapling_name, minp_relative, maxp_relative, interval)
	-- Position of sapling
	local pos = pointed_thing.under
	local node = minetest.get_node_or_nil(pos)
	local pdef = node and minetest.reg_ns_nodes[node.name]

	if pdef and pdef.on_rightclick and not placer:get_player_control().sneak then
		return pdef.on_rightclick(pos, node, placer, itemstack, pointed_thing)
	end

	if not pdef or not pdef.buildable_to then
		pos = pointed_thing.above
		node = minetest.get_node_or_nil(pos)
		pdef = node and minetest.reg_ns_nodes[node.name]
		if not pdef or not pdef.buildable_to then
			return itemstack
		end
	end

	local player_name = placer:get_player_name()
	-- Check sapling position for protection
	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return itemstack
	end
	-- Check tree volume for protection
	if default.intersects_protection(
			vector.add(pos, vector.add(minp_relative, {x=-1, y=-1, z=-1})),
			vector.add(pos, vector.add(maxp_relative, {x=1, y=1, z=1})),
			player_name,
			interval) then
		minetest.record_protection_violation(pos, player_name)
		-- Print extra information to explain
		minetest.chat_send_player(player_name, "# Server: Tree will intersect protection!")
		return itemstack
	end

	minetest.log("action", player_name .. " places node "
			.. sapling_name .. " at " .. minetest.pos_to_string(pos))

	local take_item = not minetest.settings:get_bool("creative_mode")
	local newnode = {name = sapling_name}
	local ndef = minetest.reg_ns_nodes[sapling_name]
	minetest.set_node(pos, newnode)

	-- Run callback
	if ndef and ndef.after_place_node then
		-- Deepcopy place_to and pointed_thing because callback can modify it
		if ndef.after_place_node(table.copy(pos), placer,
				itemstack, table.copy(pointed_thing)) then
			take_item = false
		end
	end

	-- Run script hook
	for _, callback in ipairs(minetest.registered_on_placenodes) do
		-- Deepcopy pos, node and pointed_thing because callback can modify them
		if callback(table.copy(pos), table.copy(newnode),
				placer, table.copy(node or {}),
				itemstack, table.copy(pointed_thing)) then
			take_item = false
		end
	end

	-- Notify other hooks.
	dirtspread.on_environment(pos)
	droplift.notify(pos)

	if take_item then
		itemstack:take_item()
	end

	return itemstack
end

--
-- NOTICE: This method is not an official part of the API yet!
-- This method may change in future.
--

function utility.can_interact_with_node(player, pos)
	if player then
		if minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
	else
		return false
	end

	local meta = minetest.get_meta(pos)
  local owner = meta:get_string("owner") or ""

	if owner == "" or owner == player:get_player_name() then
		-- Owner can access the node to any time
		return true
	end

	-- is player wielding the right key?
	local item = player:get_wielded_item()
	if item:get_name() == "key:key" or item:get_name() == "key:chain" then
		local key_meta = item:get_meta()

		if key_meta:get_string("secret") == "" then
			local key_oldmeta = item:get_metadata()
			if key_oldmeta == "" or not minetest.parse_json(key_oldmeta) then
				return false
			end

			key_meta:set_string("secret", minetest.parse_json(key_oldmeta).secret)
			item:set_metadata("")
		end

		return meta:get_string("key_lock_secret") == key_meta:get_string("secret")
	end

	return false
end

-- Called from bones mod to ensure the map is loaded before placing bones.
-- Dunno if this has any real effect on the problem of bones disappearing.
function utility.ensure_map_loaded(minp, maxp)
	local vm = minetest.get_voxel_manip()
	vm:read_from_map(minp, maxp)
	return vm:get_emerged_area() -- Return area actually loaded.
end



function table.shuffle(t, from, to, random)
	from = from or 1
	to = to or #t
	random = random or math_random
	local n = to - from + 1
	while n > 1 do
		local r = from + n-1
		local l = from + random(0, n-1)
		t[l], t[r] = t[r], t[l]
		n = n-1
	end
end



-- A helper for formspecs which need to show a progress image.
-- Note: percent value is assumed to be an integer, but if it's a float,
-- anthing less than 1 will be treated as 0!
function utility.progress_image(x, y, bg, fg, percent, modifier)
	if not modifier then
		modifier = ""
	end

	if percent < 1 then
		-- Must handle this case specially, because otherwise Minetest will insist
		-- on drawing at least 1 row of pixels from the FG image, even when percent
		-- is zero!
		return "image[" .. x .. "," .. y .. ";1,1;" .. bg .. modifier .. "]"
	else
		return "image[" .. x .. "," .. y .. ";1,1;" .. bg .. "^[lowpart:" ..
			(percent) .. ":" .. fg .. modifier .. "]"
	end
end



minetest.register_alias("akalin:ore_mined", "akalin:ore")
minetest.register_alias("alatro:ore_mined", "alatro:ore")
minetest.register_alias("arol:ore_mined", "arol:ore")
minetest.register_alias("chromium:ore_mined", "chromium:ore")
minetest.register_alias("default:stone_with_diamond_mined", "default:stone_with_diamond")
minetest.register_alias("default:stone_with_gold_mined", "default:stone_with_gold")
minetest.register_alias("default:desert_stone_with_diamond_mined", "default:desert_stone_with_diamond")
minetest.register_alias("default:desert_stone_with_iron_mined", "default:desert_stone_with_iron")
minetest.register_alias("default:desert_stone_with_copper_mined", "default:desert_stone_with_copper")
minetest.register_alias("default:stone_with_copper_mined", "default:stone_with_copper")
minetest.register_alias("default:stone_with_iron_mined", "default:stone_with_iron")
minetest.register_alias("default:desert_stone_with_coal_mined", "default:desert_stone_with_coal")
minetest.register_alias("default:stone_with_coal_mined", "default:stone_with_coal")
minetest.register_alias("rackstone:rackstone_with_meat_mined", "rackstone:rackstone_with_meat")
minetest.register_alias("rackstone:rackstone_with_mese_mined", "rackstone:rackstone_with_mese")
minetest.register_alias("rackstone:rackstone_with_diamond_mined", "rackstone:rackstone_with_diamond")
minetest.register_alias("rackstone:rackstone_with_gold_mined", "rackstone:rackstone_with_gold")
minetest.register_alias("rackstone:rackstone_with_copper_mined", "rackstone:rackstone_with_copper")
minetest.register_alias("rackstone:rackstone_with_iron_mined", "rackstone:rackstone_with_iron")
minetest.register_alias("rackstone:rackstone_with_coal_mined", "rackstone:rackstone_with_coal")
minetest.register_alias("rackstone:redrack_with_tin_mined", "rackstone:redrack_with_tin")
minetest.register_alias("rackstone:redrack_with_coal_mined", "rackstone:redrack_with_coal")
minetest.register_alias("rackstone:redrack_with_copper_mined", "rackstone:redrack_with_copper")
minetest.register_alias("rackstone:redrack_with_iron_mined", "rackstone:redrack_with_iron")
minetest.register_alias("glowstone:luxore_mined", "glowstone:luxore")
minetest.register_alias("glowstone:minerals_mined", "glowstone:minerals")
minetest.register_alias("glowstone:glowstone_mined", "glowstone:glowstone")
minetest.register_alias("quartz:quartz_ore_mined", "quartz:quartz_ore")
minetest.register_alias("pm:quartz_ore_mined", "pm:quartz_ore")
minetest.register_alias("luxore:luxore_mined", "luxore:luxore")
minetest.register_alias("thorium:ore_mined", "thorium:ore")
minetest.register_alias("lead:ore_mined", "lead:ore")
minetest.register_alias("lapis:pyrite_ore_mined", "lapis:pyrite_ore")
minetest.register_alias("kalite:ore_mined", "kalite:ore")
minetest.register_alias("sulfur:ore_mined", "sulfur:ore")
minetest.register_alias("titanium:ore_mined", "titanium:ore")
minetest.register_alias("uranium:ore_mined", "uranium:ore")
minetest.register_alias("whitestone:stone_mined", "whitestone:stone")
minetest.register_alias("zinc:ore_mined", "zinc:ore")
minetest.register_alias("talinite:desert_ore_mined", "talinite:desert_ore")
minetest.register_alias("talinite:ore_mined", "talinite:ore")
