
-- Workbench Logic
-- Author: MustTest/GoldFireUn/BluebirdGreycoat
-- License: MIT

if not minetest.global_exists("workbench") then workbench = {} end
workbench.modpath = minetest.get_modpath("workbench")
workbench.players = workbench.players or {}

local FORMSPEC_DISTANCE = 6 -- Distance checks on inventory are handled elsewhere.
local FORMSPEC_NAME = "xdecor:workbench"
local player_contexts = workbench.players

-- This function actually performs the crafting.
local function do_craft(pos, times)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local recipe = inv:get_list("craft")

	local input = {
		method = "normal",
		width = 3,
		items = recipe,
	}

	local output, decremented_input = minetest.get_craft_result(input)
	if output.item:is_empty() then
		meta:set_string("errmsg", "No valid recipe.")
		return
	end

	-- Find out how much of each item we need, per craft operation.
	-- Key: name of item, value: number needed.
	local needed_items = {}

	for k = 1, #recipe do
		local stack = recipe[k]
		if not stack:is_empty() then
			local sname = stack:get_name()
			local scount = stack:get_count()

			if not needed_items[sname] then
				needed_items[sname] = scount
			else
				needed_items[sname] = needed_items[sname] + scount
			end
		end
	end

	local num_crafted = meta:get_int("num_crafted")
	meta:set_int("num_crafted", 0)

	-- Run the crafting logic the requested number of times.
	-- We need to iterate instead of doing fancy math because otherwise there'll
	-- be bugs and duplication glitches.
	for num_crafts = 1, times do
		if not inv:room_for_item("output", output.item) then
			if num_crafted == 0 then
				meta:set_string("errmsg", "No room in product output.")
			else
				meta:set_string("errmsg", "No room in product output. (" .. num_crafted .. " crafted.)")
			end
			return
		end

		-- Check if input contains everything needed.
		for name, count in pairs(needed_items) do
			local stack = ItemStack(name .. " " .. count)
			if not inv:contains_item("input", stack) then
				if num_crafted == 0 then
					meta:set_string("errmsg", "Missing material in storage.")
				else
					meta:set_string("errmsg", "Missing material in storage. (" .. num_crafted .. " crafted.)")
				end
				return
			end
		end

		-- Input contains everything, remove needed materials.
		for name, count in pairs(needed_items) do
			local stack = ItemStack(name .. " " .. count)
			inv:remove_item("input", stack)
		end

		-- Add output item to output inventory.
		inv:add_item("output", output.item)

		-- Finally, add output replacements back to storage, or the world if no room.
		for k, stack in ipairs(output.replacements) do
			local leftover = inv:add_item("input", stack)
			if not leftover:is_empty() then
				minetest.add_item(vector.offset(pos, 0, 1, 0), leftover)
			end
		end

		-- Since input only has stacks of 1, anything in 'decremented_input' should be
		-- a replacement.
		for k, stack in ipairs(decremented_input.items) do
			if not stack:is_empty() then
				local leftover = inv:add_item("input", stack)
				if not leftover:is_empty() then
					minetest.add_item(vector.offset(pos, 0, 1, 0), leftover)
				end
			end
		end

		num_crafted = num_crafted + 1
	end

	meta:set_int("num_crafted", num_crafted)
	meta:set_string("errmsg", "Success, crafted " .. num_crafted)
end

local function update_infotext(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local pname = meta:get_string("owner")
	local stack = inv:get_stack("preview", 1)

	if stack:is_empty() then
		meta:set_string("infotext", "Workbench (Owned by <" .. rename.gpn(pname) .. ">)")
	else
		meta:set_string("infotext",
			"Workbench (Owned by <" .. rename.gpn(pname) .. ">)\n" ..
			"Crafting \"" .. utility.get_short_desc(stack:get_description()) ..
			"\" x" .. stack:get_count())
	end
end

local function init_inventory_and_meta(pos, pname)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not meta or not inv then
		return false
	end

	local owner = meta:get_string("owner")
	if owner == "" then
		meta:set_string("owner", pname)
		inv:set_size("output", 9)
		inv:set_size("input", 21)

		-- These two shall only hold virtual items, not real ones.
		inv:set_size("craft", 9)
		inv:set_size("preview", 1)
	end

	update_infotext(pos)
	meta:set_string("errmsg", "Crafting table ready.")
	meta:mark_as_private({
		"owner",
		"errmsg",
	})
	return true
end

-- Formspec code here.
local function build_formspec(pos, pname)
	local meta = minetest.get_meta(pos)

	local invloc = pos.x .. "," .. pos.y .. "," .. pos.z
	local pad = 0.25
	local x_off = 0.35

	local output_x = x_off + 10 + 10 * pad
	local craft_x = x_off + 4 + 4 * pad
	local input_x = x_off + 0 + 0 * pad
	local player_x = x_off + 4.5 + 4.5 * pad
	local arrow_x = x_off + 7 + 7 * pad
	local arrow2_x = x_off + 9 + 9 * pad
	local preview_x = x_off + 8 + 8 * pad

	local button_c1_x = x_off + 7.5 + 7.5 * pad
	local button_c2_x = x_off + 8.5 + 8.5 * pad
	local button_c1_y = 2.535
	local button_pad = 0.7
	local BW = 1.04
	local BH = 0.6

	local button1_y = button_c1_y + button_pad * 0
	local button2_y = button_c1_y + button_pad * 1
	local button3_y = button_c1_y + button_pad * 2

	local formtable = {
		"size[13,9]",
		(default.gui_bg .. default.gui_bg_img .. default.gui_slots),
		"real_coordinates[true]",
		"image[" .. arrow_x .. ",1;1,1;gui_furnace_arrow_bg.png^[transformR270]",
		"image[" .. arrow2_x .. ",1;1,1;gui_furnace_arrow_bg.png^[transformR270]",
		"list[nodemeta:" .. invloc .. ";input;" .. input_x .. ",1;3,7;]",
		"list[nodemeta:" .. invloc .. ";craft;" .. craft_x .. ",1;3,3;]",
		"list[nodemeta:" .. invloc .. ";preview;" .. preview_x .. ",1;1,1;]",
		"list[nodemeta:" .. invloc .. ";output;" .. output_x .. ",1;3,3;]",
		"list[current_player;main;" .. player_x .. ",5.6;8,1;]",
		"list[current_player;main;" .. player_x .. ",7.1;8,3;8]",
		default.get_hotbar_bg(player_x, 5.6, true),
		"listring[nodemeta:" .. invloc .. ";output]",
		"listring[current_player;main]",
		"listring[nodemeta:" .. invloc .. ";input]",
		"listring[current_player;main]",
		"label[" .. input_x .. ",0.7;Storage]",
		"label[" .. craft_x .. ",0.7;Recipe]",
		"label[" .. preview_x .. ",0.7;Result]",
		"label[" .. output_x .. ",0.7;Product]",
		"button[" .. button_c1_x .. "," .. button1_y .. ";" .. BW .. "," .. BH .. ";do_1;1]",
		"button[" .. button_c1_x .. "," .. button2_y .. ";" .. BW .. "," .. BH .. ";do_4;4]",
		"button[" .. button_c1_x .. "," .. button3_y .. ";" .. BW .. "," .. BH .. ";do_8;8]",
		"button[" .. button_c2_x .. "," .. button1_y .. ";" .. BW .. "," .. BH .. ";do_16;16]",
		"button[" .. button_c2_x .. "," .. button2_y .. ";" .. BW .. "," .. BH .. ";do_32;32]",
		"button[" .. button_c2_x .. "," .. button3_y .. ";" .. BW .. "," .. BH .. ";do_64;64]",
		"button[7.39,0.52;1.5,0.35;clear_craft;Erase]",
	}

	-- Add message string if available.
	local errmsg = meta:get_string("errmsg")
	if errmsg ~= "" then
		formtable[#formtable+1] = "label[" .. craft_x .. ",4.9;" .. errmsg .. "]"
	end

	local formspec = table.concat(formtable)
	return formspec
end

-- Called by workbench node.
function workbench.on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	if not clicker or not clicker:is_player() then
		return
	end

	local player_pos = vector.round(clicker:get_pos())
	local pname = clicker:get_player_name()

	-- Context already exists, error?
	if player_contexts[pname] then
		return
	end

	-- Player too far.
	if vector.distance(pos, player_pos) > FORMSPEC_DISTANCE then
		return
	end

	if not init_inventory_and_meta(pos, pname) then
		minetest.chat_send_player(pname, "# Server: Internal error: cannot initialize workbench.")
		return
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	player_contexts[pname] = {
		pos = vector.new(pos),
		owner = owner,
	}

	local formspec = build_formspec(pos, pname)
	minetest.show_formspec(pname, FORMSPEC_NAME, formspec)
end

local CRAFT_BUTTONS = {
	"do_1",
	"do_4",
	"do_8",
	"do_16",
	"do_32",
	"do_64",
}

-- Player sends UI input.
function workbench.on_receive_fields(player, formname, fields)
	local pname = player:get_player_name()
	local context = player_contexts[pname]

	-- No context == error, maybe CSM.
	if not context then
		return
	end

	local pos = context.pos
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")

	if owner ~= pname then
		player_contexts[pname] = nil
		return
	end

	if owner ~= context.owner then
		player_contexts[pname] = nil
		return
	end

	if fields.quit then
		meta:set_string("errmsg", "Crafting table ready.")
		meta:set_int("num_crafted", 0)
		player_contexts[pname] = nil
		return
	end

	if fields.clear_craft then
		meta:set_string("errmsg", "Crafting table ready.")
		inv:set_list("craft", {})
	end

	for k, v in ipairs(CRAFT_BUTTONS) do
		if fields[v] then
			local num = tonumber(v:sub(4))
			if num then
				do_craft(pos, num)
			end
		end
	end

	local formspec = build_formspec(pos, pname)
	minetest.show_formspec(pname, FORMSPEC_NAME, formspec)
end

-- Player leaves game.
function workbench.on_leaveplayer(pref)
	local pname = pref:get_player_name()
	player_contexts[pname] = nil
end

function workbench.on_blast(pos)
	local drops = {}
	-- Note: 'craft' and 'preview' are not real inventories.
	default.get_inventory_drops(pos, "input", drops)
	default.get_inventory_drops(pos, "output", drops)
	drops[#drops+1] = "xdecor:workbench"
	minetest.remove_node(pos)
	return drops
end

function workbench.after_place_node(pos, placer, itemstack, pointed_thing)
	if not placer or not placer:is_player() then
		return
	end

	local pname = placer:get_player_name()
	init_inventory_and_meta(pos, pname)
end

function workbench.can_dig(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if not meta or not inv then
		return true
	end

	if not inv:is_empty("input") then
		return false
	end

	if not inv:is_empty("output") then
		return false
	end

	-- Note: 'craft' and 'preview' are not real inventories.
	-- These hold virtual items ONLY.

	return true
end

local function update_craft_preview(pos, pname)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local recipe = inv:get_list("craft")

	local input = {
		method = "normal",
		width = 3,
		items = recipe,
	}

	local recipe_empty = true
	for k, v in ipairs(recipe) do
		if not v:is_empty() then
			recipe_empty = false
			break
		end
	end

	local output = minetest.get_craft_result(input)
	inv:set_stack("preview", 1, output.item)

	if output.item:is_empty() and not recipe_empty then
		meta:set_string("errmsg", "No valid recipe.")
	else
		meta:set_string("errmsg", "Crafting table ready.")
	end

	meta:set_int("num_crafted", 0)

	local formspec = build_formspec(pos, pname)
	minetest.show_formspec(pname, FORMSPEC_NAME, formspec)
	update_infotext(pos)
end

function workbench.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local pname = player:get_player_name()
	local context = player_contexts[pname]
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")

	if not context then
		return 0
	end

	if not vector.equals(context.pos, pos) then
		return 0
	end

	if owner ~= context.owner then
		return 0
	end

	if from_list == "preview" or to_list == "preview" then
		return 0
	end

	if to_list == "craft" and from_list ~= to_list then
		-- Place virtual item in craft recipe, but do not modify player's stack.
		local virtstack = inv:get_stack(from_list, from_index)
		if not virtstack:is_empty() then
			virtstack:set_count(1)
			inv:set_stack("craft", to_index, virtstack)
		end
		update_craft_preview(pos, pname)
		return 0
	end

	if from_list == "craft" and from_list ~= to_list then
		-- Erase virtual item from craft recipe.
		inv:set_stack("craft", from_index, ItemStack())
		update_craft_preview(pos, pname)
		return 0
	end

	-- Movement within the craft recipe is allowed.
	if (from_list == "craft" or to_list == "craft") and from_list ~= to_list then
		return 0
	end

	-- Movement within the output is allowed.
	if (from_list == "output" or to_list == "output") and from_list ~= to_list then
		return 0
	end

	return count
end

function workbench.allow_metadata_inventory_put(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	local context = player_contexts[pname]
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")

	if not context then
		return 0
	end

	if not vector.equals(context.pos, pos) then
		return 0
	end

	if owner ~= context.owner then
		return 0
	end

	if listname == "preview" then
		return 0
	end

	if listname == "output" then
		return 0
	end

	if listname == "craft" then
		-- Place virtual item in craft recipe, but do not modify player's stack.
		local virtstack = ItemStack(stack:get_name())
		if not virtstack:is_empty() then
			virtstack:set_count(1)
			inv:set_stack("craft", index, virtstack)
		end
		update_craft_preview(pos, pname)
		return 0
	end

	if listname == "input" then
		local stack_meta = stack:get_meta():to_table()
		local have_fields = false

		for k, v in pairs(stack_meta.fields) do
			have_fields = true
			break
		end

		if have_fields or stack:get_wear() > 0 then
			meta:set_string("errmsg", "Items with wear or metadata not allowed.")

			local formspec = build_formspec(pos, pname)
			minetest.show_formspec(pname, FORMSPEC_NAME, formspec)
			return 0
		end
	end

	return stack:get_count()
end

function workbench.allow_metadata_inventory_take(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	local context = player_contexts[pname]
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")

	if not context then
		return 0
	end

	if not vector.equals(context.pos, pos) then
		return 0
	end

	if owner ~= context.owner then
		return 0
	end

	if listname == "preview" then
		return 0
	end

	if listname == "craft" then
		-- Erase this location from the craft recipe.
		inv:set_stack("craft", index, ItemStack())
		update_craft_preview(pos, pname)
		return 0
	end

	return stack:get_count()
end

function workbench.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local pname = player:get_player_name()
	if from_list == "craft" or to_list == "craft" then
		update_craft_preview(pos, pname)
	end
end

function workbench.on_metadata_inventory_put(pos, listname, index, stack, player)
	local pname = player:get_player_name()
	if listname == "craft" then
		update_craft_preview(pos, pname)
	end
end

function workbench.on_metadata_inventory_take(pos, listname, index, stack, player)
	local meta = minetest.get_meta(pos)
	local pname = player:get_player_name()

	if listname == "craft" then
		update_craft_preview(pos, pname)
	end

	if listname == "output" then
		meta:set_int("num_crafted", 0)
		meta:set_string("errmsg", "Crafting table ready.")

		local formspec = build_formspec(pos, pname)
		minetest.show_formspec(pname, FORMSPEC_NAME, formspec)
	end
end

-- Run once only.
if not workbench.registered then
	minetest.register_on_player_receive_fields(function(...)
		return workbench.on_receive_fields(...) end)

	minetest.register_on_leaveplayer(function(...)
		return workbench.on_leaveplayer(...) end)

	local c = "workbench:core"
	local f = workbench.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	workbench.registered = true
end
