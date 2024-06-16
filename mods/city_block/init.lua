-- Minetest mod "City block"
-- City block disables use of water/lava buckets and also sends aggressive players to jail
-- 2016.02 - improvements suggested by rnd. removed spawn_jailer support. some small fixes and improvements.

-- This library is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

if not minetest.global_exists("city_block") then city_block = {} end
city_block.blocks = city_block.blocks or {}
city_block.filename = minetest.get_worldpath() .. "/city_blocks.txt"
city_block.modpath = minetest.get_modpath("city_block")
city_block.formspecs = city_block.formspecs or {}

-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random

-- Cityblocks take 6 hours to become "active".
-- This prevents certain classes of exploits (such as using them offensively
-- during PvP). This also strongly discourages constantly moving them around
-- for trivial reasons.
local CITYBLOCK_DELAY_TIME = 60*60*6
--local CITYBLOCK_DELAY_TIME = 1

local function time_active(t1, t2)
	return (math.abs(t2 - t1) > CITYBLOCK_DELAY_TIME)
end



function city_block.get_block(pos)
	local allblocks = city_block.blocks
	local numblocks = #(city_block.blocks)
	local block

	for i = 1, numblocks do
		local entry = allblocks[i]
		if vector_equals(entry.pos, pos) then
			block = entry
			break
		end
	end

	return block
end



function city_block.delete_blocks_from_area(minp, maxp)
	local i = 1
	local blocks = city_block.blocks

	::do_next::
	if i > #blocks then
		return
	end
	local p = blocks[i].pos

	if p.x >= minp.x and p.x <= maxp.x and
			p.y >= minp.y and p.y <= maxp.y and
			p.z >= minp.z and p.z <= maxp.z then
		-- Don't need to worry about relative ordering.
		-- This is your standard swap'n'pop.
		blocks[i] = blocks[#blocks]
		blocks[#blocks] = nil
		goto do_next
	end

	i = i + 1
	goto do_next

	-- Done.
	city_block:save()
end



function city_block.on_punch(pos, node, puncher, pt)
	if not pos or not node or not puncher or not pt then
		return
	end

	local pname = puncher:get_player_name()

	local wielded = puncher:get_wielded_item()
	if wielded:get_name() == "rosestone:head" and wielded:get_count() >= 8 then
		-- Only if area is not protected against this player.
		if not minetest.test_protection(pos, pname) then
			for i, v in ipairs(city_block.blocks) do
				if vector_equals(v.pos, pos) then
					if not v.is_jail then
						local p1 = vector_add(pos, {x=-1, y=0, z=-1})
						local p2 = vector_add(pos, {x=1, y=0, z=1})
						local positions, counts = minetest.find_nodes_in_area(p1, p2, "griefer:grieferstone")

						if counts["griefer:grieferstone"] == 8 then
							v.is_jail = true
							local meta = minetest.get_meta(pos)
							local infotext = meta:get_string("infotext")
							infotext = infotext .. "\nJail Marker"
							meta:set_string("infotext", infotext)

							city_block:save()

							wielded:take_item(8)
							puncher:set_wielded_item(wielded)

							minetest.chat_send_player(pname, "# Server: Jail position marked!")
							return
						end
					end
				end
			end
		end
	end

	-- Duel activation.
	-- Can be done even if player doesn't have access to protection.
	if wielded:get_name() == "default:gold_ingot" and wielded:get_count() > 0 then
		local block = city_block.get_block(pos)
		if block.pvp_arena then
			if armor.is_valid_arena(pos) then
				if armor.add_dueling_player(puncher, pos) then
					wielded:take_item()
					puncher:set_wielded_item(wielded)
				else
					if armor.dueling_players[pname] then
						minetest.chat_send_player(pname, "# Server: You are already in a duel!")
					end
				end
			else
				minetest.chat_send_player(pname, "# Server: This is not a working dueling arena! You need city blocks, protection, and at least 2 public beds.")
			end
		end
	end
end



-- Returns a table of the N-nearest city-blocks to a given position.
-- The return value format is: {{pos, owner}, {pos, owner}, ...}
-- Note: only returns blocks in the same realm! See RC mod.
-- The 'rangelim' parameter is optional, if specified, blocks farther than this
-- are ignored entirely.
function city_block:nearest_blocks_to_position(pos, num, rangelim)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local p = sblocks[i].pos
		local t1 = sblocks[i].time or 0

		if time_active(t1, t2) then
			if rangelim then
				if vector_distance(p, pos) < rangelim then
					if get_rn(p) == realm then
						blocks[#blocks+1] = sblocks[i]
					end
				end
			else
				if get_rn(p) == realm then
					blocks[#blocks+1] = sblocks[i]
				end
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
	local ret = {}
	for i = 1, num, 1 do
		if i <= #blocks then
			ret[#ret + 1] = blocks[i]
		else
			break
		end
	end
	return ret
end

function city_block:nearest_jails_to_position(pos, num, rangelim)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local v = sblocks[i]
		local p = v.pos
		local t1 = v.time or 0

		if v.is_jail and time_active(t1, t2) then
			if rangelim then
				if vector_distance(p, pos) < rangelim then
					if get_rn(p) == realm then
						blocks[#blocks+1] = v
					end
				end
			else
				if get_rn(p) == realm then
					blocks[#blocks+1] = v
				end
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
	local ret = {}
	for i=1, num, 1 do
		if i <= #blocks then
			ret[#ret+1] = blocks[i]
		else
			break
		end
	end
	return ret
end



-- Get nearest named cityblock to position which is owned by 'owner'. If 'owner'
-- is nil or an empty string, returns any nearest named cityblock.
function city_block:nearest_named_region(pos, owner)
	local get_rn = rc.current_realm_at_pos
	local realm = get_rn(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	-- Only copy over blocks in the same realm, too.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	for i=1, #sblocks, 1 do
		local b = sblocks[i]
		local p = b.pos
		local t1 = b.time or 0

		if time_active(t1, t2) then
			if b.area_name and vector_distance(p, pos) < 100 and
					(not owner or owner == "" or b.owner == owner) then
				if get_rn(p) == realm then
					blocks[#blocks+1] = sblocks[i]
				end
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- Return N-nearest blocks (should be at the front of the sorted table).
	if #blocks > 0 then
		return {blocks[1]}
	end
	return {}
end



function city_block.erase_jail(pos)
	pos = vector_round(pos)
	local b = city_block.blocks
	for k, v in ipairs(b) do
		if vector_equals(pos, v.pos) then
			local meta = minetest.get_meta(pos)
			local pname = meta:get_string("owner")
			local dname = rename.gpn(pname)
			meta:set_string("infotext", "City Marker (Placed by <" .. dname .. ">!)")

			v.is_jail = nil
			city_block:save()
			return
		end
	end
end



-- Get city information for the given position.
function city_block.city_info(pos)
	pos = vector_round(pos)
	local marker = city_block:nearest_blocks_to_position(pos, 1, 100)
	if marker and marker[1] then
		-- Covers a 45x45x45 area.
		local r = 22
		local vpos = marker[1].pos
		if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
			 pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
			 pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
			return marker[1]
		end
	end
end



function city_block:save()
	local datastring = minetest.serialize(self.blocks)
	if not datastring then
		return
	end

	minetest.safe_file_write(self.filename, datastring)

	--[[
	local file, err = io.open(self.filename, "w")
	if err then
		return
	end
	file:write(datastring)
	file:close()
	--]]
end

function city_block:load()
	local file, err = io.open(self.filename, "r")
	if err then
		self.blocks = {}
		return
	end
	self.blocks = minetest.deserialize(file:read("*all"))
	if type(self.blocks) ~= "table" then
		self.blocks = {}
	end
	file:close()
end

function city_block:in_city(pos)
	pos = vector_round(pos)
	-- Covers a 45x45x45 area.
	local r = 22
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end

-- Query whether pos is in a dueling arena. Size is same as city area.
function city_block:in_pvp_arena(pos)
	pos = vector_round(pos)
	-- Covers a 45x45x45 area.
	local r = 22
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				 pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				 pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				if v.pvp_arena then
					return true
				end
			end
		end
	end
	return false
end

-- Pass the player doing the liquid dig/place action.
function city_block:in_disallow_liquid_zone(pos, player)
	-- Never in city zone, if not a player doing this.
	if not player or not player:is_player() then
		return false
	end

	local pname = player:get_player_name()
	pos = vector_round(pos)

	-- Copy the master table's indices so we don't modify it.
	-- We do not need to copy the inner table data itself. Just the indices.
	local blocks = {}
	local sblocks = self.blocks
	local t2 = os.time()

	-- Covers a 45x45x45 area.
	local r = 22

	for i=1, #sblocks, 1 do
		local vpos = sblocks[i].pos
		local t1 = sblocks[i].time or 0

		-- Only include active blocks.
		if time_active(t1, t2) then
			-- This is a cubic distance check.
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				-- Add this block to list.
				blocks[#blocks+1] = sblocks[i]
			end
		end
	end

	-- Sort blocks, nearest blocks first.
	table.sort(blocks,
		function(a, b)
			local d1 = vector_distance(a.pos, pos)
			local d2 = vector_distance(b.pos, pos)
			return d1 < d2
		end)

	-- No intersecting blocks at all?
	if #blocks == 0 then
		return false
	end

	-- Check only the first, nearest block. Assumed active.
	local bcheck = blocks[1]

	if bcheck.owner == pname then
		return false
	end

	-- Nearest block NOT owned by player.
	-- This means this position is "in city" for purposes of placing/digging liquid.
	return true
end

function city_block:in_city_suburbs(pos)
	pos = vector_round(pos)
	local r = 44
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end

function city_block:in_safebed_zone(pos)
	-- Covers a 111x111x111 area.
	pos = vector_round(pos)
	local r = 55
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end

function city_block:in_no_tnt_zone(pos)
	pos = vector_round(pos)
	local r = 50
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end

function city_block:in_no_leecher_zone(pos)
	pos = vector_round(pos)
	local r = 100
	local blocks = self.blocks
	local t2 = os.time()

	for i=1, #blocks, 1 do -- Convenience of ipairs() does not justify its overhead.
		local v = blocks[i]
		local vpos = v.pos
		local t1 = v.time or 0

		if time_active(t1, t2) then
			if pos.x >= (vpos.x - r) and pos.x <= (vpos.x + r) and
				pos.z >= (vpos.z - r) and pos.z <= (vpos.z + r) and
				pos.y >= (vpos.y - r) and pos.y <= (vpos.y + r) then
				return true
			end
		end
	end
	return false
end



function city_block.on_rightclick(pos, node, clicker, itemstack)
	if not clicker or not clicker:is_player() then
		return
	end

	local pname = clicker:get_player_name()
	local meta = minetest.get_meta(pos)

	-- Player must be owner of city block.
	if meta:get_string("owner") ~= pname then
		return
	end

	-- Create formspec context.
	city_block.formspecs[pname] = pos
	local blockdata = city_block.get_block(pos)

	local formspec = city_block.create_formspec(pos, pname, blockdata)
	minetest.show_formspec(pname, "city_block:main", formspec)
end



function city_block.create_formspec(pos, pname, blockdata)
	local pvp = "false"
	if blockdata.pvp_arena then
		pvp = "true"
	end

	local formspec = "size[4.1,3.0]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[0,0;Enter city/area region name:]" ..
		"field[0.30,0.75;4,1;CITYNAME;;]" ..
		"button_exit[0,1.30;2,1;OK;Confirm]" ..
		"button_exit[2,1.30;2,1;CANCEL;Abort]" ..
		"field_close_on_enter[CITYNAME;true]" ..
		"checkbox[0,2;pvp_arena;Mark Dueling Arena;" .. pvp .. "]"

	return formspec
end



function check_cityname(cityname)
  return not string.match(cityname, "[^%a%s]")
end



function city_block.on_receive_fields(player, formname, fields)
	if formname ~= "city_block:main" then
		return
	end
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pos = city_block.formspecs[pname]

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not pos then
		return true
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	-- Form sender must be owner.
	if pname ~= owner then
		return true
	end

	if fields.key_enter_field == "CITYNAME" or fields.OK then
		local area_name = (fields.CITYNAME or ""):trim()
		area_name = area_name:gsub("%s+", " ")

		-- Ensure city name is valid.
		local is_valid = true
		if #area_name == 0 then
			is_valid = false
		end
		if #area_name > 20 then
			is_valid = false
		end
		if not check_cityname(area_name) then
			is_valid = false
		end

		if anticurse.check(pname, area_name, "foul") then
			is_valid = false
		elseif anticurse.check(pname, area_name, "curse") then
			is_valid = false
		end

		if not is_valid then
			minetest.chat_send_player(pname, "# Server: Region name not valid.")
			return
		end

		local block = city_block.get_block(pos)

		-- Ensure we got the city block data.
		if not block then
			return
		end

		-- Write out.
		meta:set_string("cityname", area_name)
		meta:set_string("infotext", city_block.get_infotext(pos))
		block.area_name = area_name
		city_block:save()
	---[[
	elseif fields.pvp_arena == "true" then
		local block = city_block.get_block(pos)
		if block then
			minetest.chat_send_player(pname, "# Server: Enabled dueling arena.")
			block.pvp_arena = true
			meta:set_string("infotext", city_block.get_infotext(pos))
			city_block:save()
		end
	elseif fields.pvp_arena == "false" then
		local block = city_block.get_block(pos)
		if block then
			minetest.chat_send_player(pname, "# Server: Disabled dueling arena.")
			block.pvp_arena = nil
			meta:set_string("infotext", city_block.get_infotext(pos))
			city_block:save()
		end
	--]]
	end

	return true
end



function city_block.get_infotext(pos)
	local meta = minetest.get_meta(pos)
	local pname = meta:get_string("owner")
	local cityname = meta:get_string("cityname")
	local dname = rename.gpn(pname)

	local text = "City Marker (Placed by <" .. dname .. ">!)"

	if cityname ~= "" then
		text = text .. "\nRegion Designate: \"" .. cityname .. "\""
	end

	local blockdata = city_block.get_block(pos)
	if blockdata and blockdata.pvp_arena then
		text = text .. "\nThis marks a dueling arena.\nPunch with gold ingot to duel."
	end

	return text
end



if not city_block.run_once then
	city_block:load()

	minetest.register_on_player_receive_fields(function(...)
		return city_block.on_receive_fields(...) end)

	minetest.register_node("city_block:cityblock", {
		description = "Lawful Zone Marker [Marks a 45x45x45 area as a city.]\n\nSaves your bed respawn position, if someone killed you within the city area.\nMurderers and trespassers will be sent to jail if caught in a city.\nPrevents the use of ore leeching equipment within 100 meters radius.\nPrevents mining with TNT nearby.",
		tiles = {"moreblocks_circle_stone_bricks.png^default_tool_mesepick.png"},
		is_ground_content = false,
		groups = utility.dig_groups("obsidian", {
			immovable=1,
		}),
		is_ground_content = false,
		sounds = default.node_sound_stone_defaults(),
		stack_max = 1,

		on_rightclick = function(...)
			return city_block.on_rightclick(...)
		end,

		after_place_node = function(pos, placer)
			if placer and placer:is_player() then
				local pname = placer:get_player_name()
				local meta = minetest.get_meta(pos)
				local dname = rename.gpn(pname)
				meta:set_string("rename", dname)
				meta:set_string("owner", pname)
				meta:set_string("infotext", city_block.get_infotext(pos))
				table.insert(city_block.blocks, {
					pos = vector_round(pos),
					owner = pname,
					time = os.time(),
				})
				city_block:save()
			end
		end,

		-- We don't need an `on_blast` func because TNT calls `on_destruct` properly!
		on_destruct = function(pos)
			-- The cityblock may not exist in the list if the node was created by falling,
			-- and was later dug.
			for i, EachBlock in ipairs(city_block.blocks) do
				if vector_equals(EachBlock.pos, pos) then
					table.remove(city_block.blocks, i)
					city_block:save()
				end
			end
		end,

		-- Called by rename LBM.
		_on_update_infotext = function(pos)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			-- Nobody placed this block.
			if owner == "" then
				return
			end
			local dname = rename.gpn(owner)

			meta:set_string("rename", dname)
			meta:set_string("infotext", city_block.get_infotext(pos))
		end,

		on_punch = function(...)
			return city_block.on_punch(...)
		end,
	})

	minetest.register_craft({
		output = 'city_block:cityblock',
		recipe = {
			{'default:pick_mese', 'farming:hoe_mese', 'default:sword_diamond'},
			{'chests:chest_locked', 'default:goldblock', 'default:sandstone'},
			{'default:obsidianbrick', 'default:mese', 'cobble_furnace:inactive'},
		}
	})

	minetest.register_privilege("disable_pvp", {
		description = "Players cannot damage players with this priv by punching.",
		give_to_singleplayer = false,
	})

	minetest.register_on_punchplayer(function(...)
		return city_block.on_punchplayer(...)
	end)

	local c = "city_block:core"
	local f = city_block.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	city_block.run_once = true
end



function city_block:get_adjective()
  local adjectives = {
    "murdering",
    "slaying",
    "killing",
    "whacking",
    "trashing",
    "fatally attacking",
    "fatally harming",
    "doing away with",
    "giving the Chicago treatment to",
    "fatally thrashing",
    "fatally stabbing",
  }
  return adjectives[math_random(1, #adjectives)]
end



local murder_messages = {
	"<v> collapsed from <k>'s brutal attack.",
	"<k>'s <w> apparently wasn't such an unusual weapon after all, as <v> found out.",
	"<k> killed <v> with great prejudice.",
	"<v> died from <k>'s horrid slaying.",
	"<v> fell prey to <k>'s deadly <w>.",
	"<k> went out of <k_his> way to slay <v> with <k_his> <w>.",
	"<v> danced <v_himself> to death under <k>'s craftily wielded <w>.",
	"<k> used <k_his> <w> to kill <v> with prejudice.",
	"<k> made a splortching sound with <v>'s head.",
	"<v> got flattened by <k>'s skillfully handled <w>.",
	"<v> became prey for <k>.",
	"<v> didn't get out of <k>'s way in time.",
	"<v> SAW <k> coming with <k_his> <w>. Didn't get away in time.",
	"<v> made no real attempt to get out of <k>'s way.",
	"<k> barreled through <v> as if <v_he> wasn't there.",
	"<k> sent <v> to that place where kindling wood isn't needed.",
	"<v> didn't suspect that <k> meant <v_him> any harm.",
	"<v> fought <k> to the death and lost painfully.",
	"<v> knew <k> was wielding <k_his> <w> but didn't guess what <k> meant to do with it.",
	"<k> clonked <v> over the head using <k_his> <w> with silent skill.",
	"<k> made sure <v> didn't see that coming!",
	"<k> has decided <k_his> favorite weapon is <k_his> <w>.",
	"<v> did the mad hatter dance just before being killed with <k>'s <w>.",
	"<v> played the victim to <k>'s bully behavior!",
	"<k> used <v> for weapons practice with <k_his> <w>.",
	"<v> failed to avoid <k>'s oncoming weapon.",
	"<k> successfully got <v> to complain of a headache.",
	"<v> got <v_himself> some serious hurt from <k>'s <w>.",
	"Trying to talk peace to <k> didn't win any for <v>.",
	"<v> was brutally slain by <k>'s <w>.",
	"<v> jumped the mad-hatter dance under <k>'s <w>.",
	"<v> got <v_himself> a fatal mauling by <k>'s <w>.",
	"<k> just assassinated <v> with <k_his> <w>.",
	"<k> split <v>'s wig.",
	"<k> took revenge on <v>.",
	"<k> flattened <v>.",
	"<v> played dead. Permanently.",
	"<v> never saw what hit <v_him>.",
	"<k> took <v> by surprise.",
	"<v> was assassinated.",
	"<k> didn't take any prisoners from <v>.",
	"<k> pinned <v> to the wall with <k_his> <w>.",
	"<v> failed <v_his> weapon checks.",
}

function city_block.murder_message(killer, victim, sendto)
	if spam.test_key("kill" .. victim .. "15662") then
		return
	end
	spam.mark_key("kill" .. victim .. "15662", 30)

	local msg = murder_messages[math_random(1, #murder_messages)]
	msg = string.gsub(msg, "<v>", "<" .. rename.gpn(victim) .. ">")
	msg = string.gsub(msg, "<k>", "<" .. rename.gpn(killer) .. ">")

	local ksex = skins.get_gender_strings(killer)
	local vsex = skins.get_gender_strings(victim)

	msg = string.gsub(msg, "<k_himself>", ksex.himself)
	msg = string.gsub(msg, "<k_his>", ksex.his)

	msg = string.gsub(msg, "<v_himself>", vsex.himself)
	msg = string.gsub(msg, "<v_his>", vsex.his)
	msg = string.gsub(msg, "<v_him>", vsex.him)
	msg = string.gsub(msg, "<v_he>", vsex.he)

	if string.find(msg, "<w>") then
		local hitter = minetest.get_player_by_name(killer)
		if hitter then
			local wield = hitter:get_wielded_item()
			local def = minetest.registered_items[wield:get_name()]
			local meta = wield:get_meta()
			local description = meta:get_string("description")
			if description ~= "" then
				msg = string.gsub(msg, "<w>", "'" .. utility.get_short_desc(description):trim() .. "'")
			elseif def and def.description then
				local str = utility.get_short_desc(def.description)
				if str == "" then
					str = "Potato Fist"
				end
				msg = string.gsub(msg, "<w>", str)
			end
		end
	end

	if type(sendto) == "string" then
		minetest.chat_send_player(sendto, "# Server: " .. msg)
	else
		minetest.chat_send_all("# Server: " .. msg)
	end
end



function city_block.hit_possible(p1pos, p2pos)
	-- Range limit, stops hackers with long reach.
	if vector_distance(p1pos, p2pos) > 6 then
		return false
	end

	-- Cannot attack through walls.
	-- But if node wouldn't stop an arrow, keep testing the line.
	--local raycast = minetest.raycast(p1pos, p2pos, false, false)

	-- This seems to cause random freezes and 100% CPU.
	--[[
	local los, pstop = minetest.line_of_sight(p1pos, p2pos)
	while not los do
		if throwing.node_blocks_arrow(minetest.get_node(vector_round(pstop)).name) then
			return false
		end
		local dir = vector.direction(pstop, p2pos)
		local ns = vector.add(pstop, dir)
		los, pstop = minetest.line_of_sight(ns, p2pos)
	end
	--]]

	return true
end



function city_block.send_to_jail(victim_pname, attack_pname)
	-- Killers don't go to jail if the victim is a registered cheater.
	if not sheriff.is_cheater(victim_pname) then
		local hitter = minetest.get_player_by_name(attack_pname)
		if hitter and jail.go_to_jail(hitter, nil) then
			minetest.chat_send_all(
				"# Server: Criminal <" .. rename.gpn(attack_pname) .. "> was sent to gaol for " ..
				city_block:get_adjective() .. " <" .. rename.gpn(victim_pname) .. "> within city limits.")
		end
	end
end



function city_block.handle_assassination(p2pos, victim_pname, attack_pname, melee)
	-- Bed position is only lost if player died outside city to a melee weapon.
	if not city_block:in_safebed_zone(p2pos) and melee then
		-- Victim doesn't lose their bed respawn if they were killed by a cheater.
		if not sheriff.is_cheater(attack_pname) then
			local pref = minetest.get_player_by_name(victim_pname)
			if pref then
				local meta = pref:get_meta()
				meta:set_int("was_assassinated", 1)
			end
			--minetest.chat_send_player(victim_pname, "# Server: Your bed is lost! You were assassinated in the wilds.")
			--beds.clear_player_spawn(victim_pname)
		end
	end
end



-- Note: this is called on the next server step after the punch, otherwise we
-- cannot know if the player died as a result.
function city_block.handle_consequences(player, hitter, melee, stomp)
	--minetest.log('handle_consequences')

	local victim_pname = player:get_player_name()
	local attack_pname = hitter:get_player_name()
	local time = os.time()
	local hp = player:get_hp()
	local p2pos = utility.get_head_pos(player:get_pos())
	local vpos = vector_round(p2pos)

	city_block.attackers[victim_pname] = attack_pname
	city_block.victims[victim_pname] = time

	-- Victim didn't die yet.
	if hp > 0 then
		return
	end

	default.detach_player_if_attached(player)

	-- Stomp messages are handled elsewhere.
	if not stomp then
		city_block.murder_message(attack_pname, victim_pname)
	end

	if city_block:in_city(p2pos) then
		local t0 = city_block.victims[attack_pname] or time
		local tdiff = (time - t0)

		if not city_block.attackers[attack_pname] then
			city_block.attackers[attack_pname] = ""
		end

		--[[
			Behavior Table (obtained through testing):

			In city-block area, no protection:
				A kills B, B did not retaliate -> A goes to jail
				A kills B, B had retaliated    -> Nobody jailed
				(The table is the same if A and B are inverted)

			In city-block area, protected by A (with nearby jail available):
				A kills B, B did not retaliate -> A goes to jail
				A kills B, B had retaliated    -> Nobody jailed
				B kills A, A did not retaliate -> B goes to jail
				B kills A, A had retaliated    -> B goes to jail
				(The table is the same if A and B are inverted, and protection is B's)

			Notes:
				A hit from A or B is considered retaliation if it happens very soon
				after the other player hit. Thus, if both A and B are hitting, then both
				are considered to be retaliating -- in that case, land ownership is used
				to resolve who should go to jail.

				It does not matter who hits first in a fight -- only who kills the other
				player first.

				If there is no jail available for a crook to be sent to, then nothing
				happens in any case, regardless of who wins the fight or owns the land.

		--]]

		-- Victim is "landowner" if area is protected, but they have access.
		local landowner = (minetest.test_protection(vpos, "") and
			not minetest.test_protection(vpos, victim_pname))

		-- Killing justified after provocation, but not if victim owns the land.
		if city_block.attackers[attack_pname] == victim_pname and
				tdiff < 30 and not landowner then
			return
		else
			-- Go to jail! Do not pass Go. Do not collect $200.
			city_block.send_to_jail(victim_pname, attack_pname)
		end
	else
		-- Player killed outside town.
		-- This only does something if the attack was with a melee weapon!
		city_block.handle_assassination(p2pos, victim_pname, attack_pname, melee)
	end
end



city_block.attackers = city_block.attackers or {}
city_block.victims = city_block.victims or {}

-- Return `true' to prevent the default damage mechanism.
-- Note: player is sometimes the hitter (player punches self). This is sometimes
-- necessary when a mod needs to punch a player, but has no entity that can do
-- the actual punch.
function city_block.on_punchplayer(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	--minetest.chat_send_all('city_block: on_punchplayer')

	if not player:is_player() then
		return
	end

	-- Callback is called even if player is dead. Shortcut.
	if player:get_hp() <= 0 or hitter:get_hp() <= 0 then
		return
	end

	--minetest.log('on_punchplayer')

	local melee_hit = true
	local stomp_hit = false
	local from_env = false
	local from_mob = false

	if tool_capabilities.damage_groups.from_stomp then
		stomp_hit = true
	end

	if tool_capabilities.damage_groups.from_env then
		from_env = true
	end

	if tool_capabilities.damage_groups.from_mob then
		from_mob = true
	end

	if tool_capabilities.damage_groups.from_arrow then
		-- Someone launched this weapon. The hitter is most likely the nearest
		-- player that isn't the player going to be hit.
		melee_hit = false

		--minetest.chat_send_all('from arrow')
	end
	
	if not hitter:is_player() then
		--minetest.chat_send_all('hitter not player')
		return
	end

	-- Random accidents happen to punished players during PvP.
	do
		local attacker = hitter:get_player_name()
		if sheriff.is_cheater(attacker) then
			if sheriff.punish_probability(attacker) then
				sheriff.punish_player(attacker)
			end
		end
	end

	local p1pos = utility.get_head_pos(hitter:get_pos())
	local p2pos = utility.get_head_pos(player:get_pos())

	-- Check if hit is physically possible (range, blockage, etc).
	if melee_hit and not city_block.hit_possible(p1pos, p2pos) then
		return true
	end

	-- PvP is disabled for players in jail. This fixes a possible way to exploit jail.
	if not from_env and (jail.is_player_in_jail(hitter) or jail.is_player_in_jail(player)) then
		minetest.chat_send_player(hitter:get_player_name(), "# Server: Brawling is not allowed in jail.")
		return true
	end

	-- Admins cannot be punched.
	if gdac.player_is_admin(player) then
		return true
	end

	-- Let others hear sounds of nearby combat.
	if damage > 0 then
		ambiance.sound_play("player_damage", p2pos, 2.0, 30)
	end

	local pname = player:get_player_name()
	local hname = hitter:get_player_name()

	-- If hitter is self, punch was (most likely) due to game code.
	-- E.g., node damage or other environment hazard.
	if player == hitter then
		--minetest.chat_send_all('player == hitter')
		--minetest.chat_send_all(dump(from_env))
		--minetest.chat_send_all(dump(from_mob))
		--minetest.chat_send_all(dump(not melee_hit))
		if not from_env and not from_mob and not melee_hit then
			-- This one's a suicide.
			--minetest.chat_send_all('suicide!')
			armor.notify_duel_punch(pname, hname, stomp_hit, not melee_hit)
		end
		return
	end

	-- Stuff that happens when one player kills another.
	-- Must be executed on the next server step, so we can determine if victim
	-- really died! (This is because damage will often be modified.)
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(pname)
		local href = minetest.get_player_by_name(hname)
		if pref and href then
			city_block.handle_consequences(pref, href, melee_hit, stomp_hit)
		end
	end)

	-- When we return from this punch handler, the HP-change callback(s) will be called.
	-- This notifies the dueling code that the next HP-change is from a player-to-player
	-- punch, so that we can handle the HP-change sensibly.
	if not from_env and not from_mob then
		-- Pass victim name, hitter name, boot-stomp flag, ranged/arrow flag.
		armor.notify_duel_punch(pname, hname, stomp_hit, not melee_hit)
	end
end

