
if not minetest.global_exists("prospector") then prospector = {} end
prospector.modpath = minetest.get_modpath("silicon")
prospector.players = prospector.players or {}
prospector.hidden_ores = prospector.hidden_ores or {}
prospector.shown_ores = prospector.shown_ores or {}

local HUD_REMAIN_TIME = 15

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random
local vector_equals = vector.equals

prospector.image = "prospector.png"
prospector.name = "prospector:prospector"
prospector.description = "Prospector\n\nTool to scan for hidden materials.\nMust be charged to use."

-- Accuracy is a number between 0 and 100. Higher is more accurate.
function prospector.mark_nodes(pname, start_pos, nodes, accuracy, minp, maxp)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local found = true
	local count_found = 0

	-- Note: inaccuracy can sometimes cause the prospector to NOT find nodes that
	-- are there. However, it can never cause the prospector to find nodes that
	-- ARE NOT there.
	if math_random() > accuracy/100 then
		if math_random(1, 2) == 1 then
			found = not found
		end
	end

	-- Mark nodes on the player's HUD.
	if found then
		local data = prospector.players[pname]
		if not data then
			prospector.players[pname] = {hud={}}
			data = prospector.players[pname]
		end
		local hud = data.hud

		local function do_exists(p)
			for k = 1, #hud do
				if vector_equals(hud[k].pos, p) then
					hud[k].time = os.time()
					return true
				end
			end
		end

		for k, v in ipairs(nodes) do
			-- Set if this node was detected at least once, thus must always be detected.
			-- This is to prevent nodes from being possibly added to the 'undetectable'
			-- list, if we saw them at least once.
			local always_detect = prospector.always_detectable(v)

			-- Accuracy affects how many ores are revealed.
			if math_random() < accuracy/100 or always_detect then
				-- Get value where 1 = most inaccurate, 0 = least inaccurate.
				-- Normalize range, flip and shift.
				local alpha = ((accuracy / 100) * -1) + 1

				-- The revealed position of the ore decreases in accuracy.
				local orepos = {
					x = v.x + (math_random(-7, 7) * alpha),
					y = v.y + (math_random(-7, 7) * alpha),
					z = v.z + (math_random(-7, 7) * alpha),
				}

				-- Skip revealing ores if their randomized position is outside our scan area.
				if (orepos.x >= minp.x and orepos.x <= maxp.x
					 and orepos.y >= minp.y and orepos.y <= maxp.y
					 and orepos.z >= minp.z and orepos.z <= maxp.z)
					 or always_detect then
					-- Skip marking ores that have already been marked as unfindable.
					-- This prevents them from being found again by user spam-clicking.
					if not prospector.is_unfindable(v) then
						-- Check if this ore is already tagged in the user's HUD.
						-- (If it is, we also update its time.)
						if not do_exists(v) then
							local id = pref:hud_add({
								type = "waypoint",
								name = "Ore",
								number = 0X5fb471,
								world_pos = orepos,
								precision = 1, -- Integers only.
							})

							hud[#hud + 1] = {
								id = id,
								time = os.time(),
								pos = v,
							}

							prospector.mark_detectable(v)
						end

						count_found = count_found + 1
					end
				else
					-- Mark this ore as unfindable.
					prospector.mark_unfindable(v)
				end
			else
				-- Mark this ore as unfindable.
				prospector.mark_unfindable(v)
			end
		end

		if not data.started then
			data.started = true
			minetest.after(1, function()
				return prospector.update_hud(pname)
			end)
		end
	end

	local sound = "technic_prospector_" .. ((count_found > 0 and "hit") or "miss")
	ambiance.sound_play(sound, start_pos, 0.6, 20)
end

function prospector.mark_unfindable(pos)
	local hidden = prospector.hidden_ores
	for k = 1, #hidden do
		if vector_equals(hidden[k], pos) then
			return
		end
	end
	hidden[#hidden + 1] = pos
end

function prospector.is_unfindable(pos)
	local hidden = prospector.hidden_ores
	for k = 1, #hidden do
		if vector_equals(hidden[k], pos) then
			return true
		end
	end
end

function prospector.mark_detectable(pos)
	local shown = prospector.shown_ores
	for k = 1, #shown do
		if vector_equals(shown[k], pos) then
			return
		end
	end
	shown[#shown + 1] = pos
end

function prospector.always_detectable(pos)
	local shown = prospector.shown_ores
	for k = 1, #shown do
		if vector_equals(shown[k], pos) then
			return true
		end
	end
end

function prospector.update_hud(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local data = prospector.players[pname]
	if not data then
		return
	end

	local hud = data.hud
	if #hud == 0 then
		data.started = false
		return
	end

	local remaintime = HUD_REMAIN_TIME
	local ctime = os.time()
	local nhud = {}
	for k = 1, #hud do
		if (hud[k].time + remaintime) > ctime then
			nhud[#nhud + 1] = hud[k]
		else
			pref:hud_remove(hud[k].id)
		end
	end
	data.hud = nhud

	minetest.after(1, function()
		return prospector.update_hud(pname)
	end)
end

local function get_metadata(toolstack)
	local meta = toolstack:get_meta()
	local m = {}
	m.target = meta:get_string("target") or ""
	m.look_depth = meta:get_int("look_depth") or 0
	m.look_radius = meta:get_int("look_radius") or 0
	m.accuracy = meta:get_int("accuracy") or 0
	if m.look_depth < 7 then
		m.look_depth = 7
	end
	if m.look_radius < 0 then
		m.look_radius = 0
	end
	if m.accuracy < 0 then m.accuracy = 0 end
	if m.accuracy > 100 then m.accuracy = 100 end
	return m
end

local function set_metadata(toolstack, m)
	local meta = toolstack:get_meta()
	local m2 = table.copy(m)
	if m2.look_depth < 7 then
		m2.look_depth = 7
	end
	if m2.look_radius < 0 then
		m2.look_radius = 0
	end
	if m2.accuracy < 0 then m2.accuracy = 0 end
	if m2.accuracy > 100 then m2.accuracy = 100 end

	meta:set_string("target", m2.target)
	meta:set_int("look_depth", m2.look_depth)
	meta:set_int("look_radius", m2.look_radius)
	meta:set_int("accuracy", m2.accuracy)
end

local function update_description(toolstack)
	local m = get_metadata(toolstack)

	local radius = m.look_radius  * 2 + 1
	local depth = m.look_depth

	local target = "Unknown Block"
	local ndef = minetest.reg_ns_nodes[m.target]
	if ndef then
		local d = ndef.description or ""
		if d ~= "" then
			target = utility.get_short_desc(d)
		else
			target = "UNKNOWN NODE"
		end
	end

	-- Compute accuracy based on energy left.
	local accuracy = (toolstack:get_wear()/(65535*3))
	accuracy = accuracy * -1 + 1 -- Invert.
	if accuracy < 0 then accuracy = 0 end
	if accuracy > 1 then accuracy = 1 end
	accuracy = math_floor(accuracy * 100)

	local meta = toolstack:get_meta()
	meta:set_int("accuracy", accuracy)

	-- Description update.
	local desc = minetest.registered_items[toolstack:get_name()].description
	meta:set_string("description", desc .. "\n\n" ..
		"Target: " .. target .. "\n" ..
		"Cross section: " .. radius .. "x" .. radius .. "\n" ..
		"Depth: " .. depth .. "\n" ..
		"Accuracy: " .. accuracy .. "%")
end

function prospector.do_use(toolstack, user, pointed_thing, wear)
	if not user or not user:is_player() then
		return 10
	end

	local pname = user:get_player_name()

	local toolmeta = get_metadata(toolstack)
	local look_diameter = toolmeta.look_radius * 2 + 1
	local charge_to_take = toolmeta.look_depth * (toolmeta.look_depth + 1) * look_diameter * look_diameter
	charge_to_take = math_floor(charge_to_take / 30)

	if wear > math_floor(65535-charge_to_take) then
		-- Tool has no charge left.
		return 10
	end

	if toolmeta.target == "" then
		minetest.chat_send_player(user:get_player_name(),
			"# Server: Right-click to set target block type.")
		return 10
	end

	local start_pos = pointed_thing.under
	local forward = minetest.facedir_to_dir(minetest.dir_to_facedir(user:get_look_dir(), true))
	local right = forward.x ~= 0 and { x=0, y=1, z=0 } or (forward.y ~= 0 and { x=0, y=0, z=1 } or { x=1, y=0, z=0 })
	local up = forward.x ~= 0 and { x=0, y=0, z=1 } or (forward.y ~= 0 and { x=1, y=0, z=0 } or { x=0, y=1, z=0 })

	local minp = vector.add(start_pos, vector.multiply(vector.add(right, up), -toolmeta.look_radius))
	local maxp = vector.add(start_pos, vector.multiply(vector.add(right, up), toolmeta.look_radius))

	-- Apply depth.
	maxp = vector.add(maxp, vector.multiply(forward, toolmeta.look_depth-1))

	-- Sort.
	if minp.x > maxp.x then minp.x, maxp.x = maxp.x, minp.x end
	if minp.y > maxp.y then minp.y, maxp.y = maxp.y, minp.y end
	if minp.z > maxp.z then minp.z, maxp.z = maxp.z, minp.z end

	local found = false
	local nodes = minetest.find_nodes_in_area(minp, maxp, toolmeta.target) or {}

	-- Test code to ensure minp, maxp are sane.
	--[[
	for x = minp.x, maxp.x do
	for y = minp.y, maxp.y do
	for z = minp.z, maxp.z do
		minetest.set_node({x=x, y=y, z=z}, {name="default:goldblock"})
	end
	end
	end
	--]]

	prospector.mark_nodes(pname, start_pos, nodes, toolmeta.accuracy, minp, maxp)

	return charge_to_take
end

function prospector.do_place(toolstack, user, pointed_thing)
	if not user or not user:is_player() then
		return
	end

	local toolmeta = get_metadata(toolstack)

	local pointed
	if pointed_thing.type == "node" then
		local pname = minetest.get_node(pointed_thing.under).name
		local pdef = minetest.reg_ns_nodes[pname]
		-- Don't allow pointing to unknown stuff.
		if pdef and pname ~= toolmeta.target then
			pointed = pname
		end
	end
	local look_diameter = toolmeta.look_radius * 2 + 1

	local desc = "UNKNOWN BLOCK"
	if minetest.reg_ns_nodes[toolmeta.target] then
		local d = minetest.reg_ns_nodes[toolmeta.target].description or ""
		if d ~= "" then
			desc = utility.get_short_desc(d)
		end
	end

	local pdesc = "UNKNOWN BLOCK"
	if pointed and minetest.reg_ns_nodes[pointed] then
		local d = minetest.reg_ns_nodes[pointed].description or ""
		if d ~= "" then
			pdesc = utility.get_short_desc(d)
		end
	end

	minetest.show_formspec(user:get_player_name(), "technic:prospector_control",
		"size[7,8.5]" ..
			default.gui_bg ..
      default.gui_bg_img ..
      default.gui_slots ..
			"item_image[0,0;1,1;prospector:prospector]"..
			"label[1,0;Prospector]"..

			(toolmeta.target ~= "" and
				"label[0,1.5;Current target:]" ..
				"label[0,2;" .. minetest.formspec_escape("\"" .. desc .. "\"") .. "]" ..
				"item_image[0,2.5;1,1;" .. toolmeta.target .. "]" or
				"label[0,1.5;No target set.]") ..

			(pointed and
				"label[3.5,1.5;May set new target:]"..
				"label[3.5,2;" .. minetest.formspec_escape("\"" .. pdesc .. "\"") .. "]" ..
				"item_image[3.5,2.5;1,1;" .. pointed .. "]" ..
				"button_exit[3.5,3.65;2,0.5;target_" .. pointed .. ";Set target]" or
				"label[3.5,1.5;No new target available.]")..

			"label[0,4.5;Region cross section:]"..
			"label[0,5;" .. look_diameter .. "x" .. look_diameter .. "]" ..
			"label[3.5,4.5;Set region cross section:]"..
			"button_exit[3.5,5.15;1,0.5;look_radius_0;1x1]"..
			"button_exit[4.5,5.15;1,0.5;look_radius_1;3x3]"..
			"button_exit[5.5,5.15;1,0.5;look_radius_3;7x7]"..
			"label[0,6;Region depth:]"..
			"label[0,6.5;" .. toolmeta.look_depth .. "]" ..
			"label[3.5,6;Set region depth:]"..
			"button_exit[3.5,6.65;1,0.5;look_depth_7;7]"..
			"button_exit[4.5,6.65;1,0.5;look_depth_14;14]"..
			"button_exit[5.5,6.65;1,0.5;look_depth_21;21]"..
			"label[0,7.5;Accuracy:]"..
			"label[0,8;" .. minetest.formspec_escape(toolmeta.accuracy .. "%") .. "]")
end

function prospector.on_use(itemstack, user, pt)
	if pt.type ~= "node" then
		return
	end
	local wear = itemstack:get_wear()
	if wear == 0 then
		-- Tool isn't charged!
		-- Once it is charged the first time, wear should never be 0 again.
		return
	end

	local add = prospector.do_use(itemstack, user, pt, wear)
	wear = wear + add

	-- Don't let wear reach max or tool will be destroyed.
	if wear >= 65535 then
		wear = 65534
	end
	itemstack:set_wear(wear)
	update_description(itemstack)
	return itemstack
end

function prospector.on_configure(itemstack, user, pt)
	local wear = itemstack:get_wear()
	if wear == 0 then
		-- Tool isn't charged!
		-- Once it is charged the first time, wear should never be 0 again.
		return
	end

	-- Opens async formspec.
	prospector.do_place(itemstack, user, pt, wear)
	return itemstack
end

function prospector.on_receive_fields(user, formname, fields)
	if formname ~= "technic:prospector_control" then
		return
	end

	if not user or not user:is_player() then
		return
	end

	local toolstack = user:get_wielded_item()
	if toolstack:get_name() ~= "prospector:prospector" then
		return true
	end

	local toolmeta = get_metadata(toolstack)

	for field, value in pairs(fields) do
		if field:sub(1, 7) == "target_" then
			toolmeta.target = field:sub(8)
		end
		if field:sub(1, 12) == "look_radius_" then
			toolmeta.look_radius = tonumber(field:sub(13))
		end
		if field:sub(1, 11) == "look_depth_" then
			toolmeta.look_depth = tonumber(field:sub(12))
		end
	end

	set_metadata(toolstack, toolmeta)

	update_description(toolstack)
	user:set_wielded_item(toolstack)
	return true
end

function prospector.on_leaveplayer(pref)
	local pname = pref:get_player_name()
	prospector.players[pname] = nil
end

-- This must be called periodically to avoid lots of records being stored in RAM.
-- Function is time-recursive.
function prospector.clear_ore_lists()
	prospector.hidden_ores = {}
	prospector.shown_ores = {}

	minetest.after((60*math.random(60, 120)), function()
		prospector.clear_ore_lists()
	end)
end

if not prospector.run_once then
	minetest.register_tool(":" .. prospector.name, {
		description = prospector.description,
		inventory_image = prospector.image,
		wear_represents = "eu_charge",
		groups = {not_repaired_by_anvil = 1},

		on_use = function(...)
			return prospector.on_use(...)
		end,

		on_place = function(...)
			return prospector.on_configure(...)
		end,
	})

	minetest.register_on_player_receive_fields(function(...)
		return prospector.on_receive_fields(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return prospector.on_leaveplayer(...)
	end)

	-- Periodically clear the ore lists.
	minetest.after((60*math.random(60, 120)), function()
		prospector.clear_ore_lists()
	end)

	---[[
	minetest.register_craft({
		output = prospector.name,
		recipe = {
			{"moreores:pick_silver", "moreores:mithril_block", "fine_wire:silver"},
			{"brass:ingot", "techcrafts:control_logic_unit", "brass:ingot"},
			{"", "battery:battery", ""},
		}
	})
	--]]

	local c = "prospector:core"
	local f = prospector.modpath .. "/prospector.lua"
	reload.register_file(c, f, false)

	prospector.run_once = true
end
