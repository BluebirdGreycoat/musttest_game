
engraver = engraver or {}
engraver.modpath = minetest.get_modpath("engraver")

-- API function to allow caller to check if an item has a custom description.
function engraver.item_has_custom_description(item)
	if item:get_count() ~= 1 then
		return false
	end

	local meta = item:get_meta()
	local en_desc = meta:get_string("en_desc") or ""
	local ar_desc = meta:get_string("ar_desc") or ""
	return en_desc ~= "" or ar_desc ~= ""
end

local function player_wields_tools(user)
	local chisel_index = user:get_wield_index()
	local hammer_index = chisel_index + 1

	local inv = user:get_inventory()
	local chisel_stack = inv:get_stack("main", chisel_index)
	local chisel_name = chisel_stack:get_name()
	local hammer_stack = inv:get_stack("main", hammer_index)
	local hammer_name = hammer_stack:get_name()

	if chisel_name ~= "engraver:chisel" then
		return false
	end

	if hammer_name ~= "xdecor:hammer" and hammer_name ~= "anvil:hammer" then
		return false
	end

	return true
end



local function node_can_be_chiseled(pos)
	local node = minetest.get_node(pos)
	local ndef = minetest.registered_nodes[node.name]

	if not ndef then
		return false
	end

	-- Check node drawtype (must be full node).
	local dt = ndef.drawtype
	if dt ~= "normal" and dt ~= "glasslike" and dt ~= "glasslike_framed" and dt ~= "glasslike_framed_optional" and dt ~= "allfaces" and dt ~= "allfaces_optional" then
		return false
	end

	-- Check node groups (must be stone, brick or block).
	local groups = ndef.groups or {}
	if (groups.stone and groups.stone > 0) or (groups.brick and groups.brick > 0) or (groups.block and groups.block > 0) then
		-- Do nothing.
	else
		return false
	end

	-- Check meta (cannot have infotext or formspec, or must have been previously chiseled).
	local meta = minetest.get_meta(pos)
	local data = meta:to_table() or {fields={}, inventory={}}

	-- Any inventory fields means this node can't be engraved.
	for k, v in pairs(data.inventory) do
		return false
	end

	local was_engraved = false
	local was_polished = false
	local has_other_fields = false
	local has_infotext = false
	for k, v in pairs(data.fields) do
		if k == "engraver_chiseled" then
			was_engraved = true
		elseif k == "infotext" then
			has_infotext = true
		elseif k == "chiseled_text" or k == "chiseled_date" then
			-- Nothing to be done. Ignore these fields.
		elseif k == "chiseled_polished" then
			was_polished = true
		else
			has_other_fields = true
		end
	end

	if has_infotext and not was_engraved then
		return false
	end
	if has_other_fields or was_polished then
		return false
	end

	return true
end



local function show_chisel_formspec(pos, user)
	local pname = user:get_player_name()
	local node = minetest.get_node(pos)
	local text = minetest.get_meta(pos):get_string("chiseled_text")

	local formspec = "size[5,2.3]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"item_image[1,1;1,1;" .. minetest.formspec_escape(node.name) .. "]" ..
		"field[0.3,0.3;5,1;text;;" .. minetest.formspec_escape(text) .. "]" ..
		"button_exit[2,1;2,1;proceed;Chisel Text]" ..
		"label[0,2;`%n' inserts a new line.]"

	local formname = "engraver:chisel_" .. minetest.pos_to_string(pos)
	minetest.show_formspec(pname, formname, formspec)
end



-- Must be a tool for the wear bar to work.
minetest.register_tool("engraver:chisel", {
	description = "Chisel",
	groups = {not_repaired_by_anvil = 1},
	inventory_image = "engraver_chisel.png",
	wield_image = "engraver_chisel.png",

	on_use = function(itemstack, user, pt)
		if not user or not user:is_player() then
			return
		end

		if pt.type ~= "node" then
			return
		end

		if not player_wields_tools(user) then
			return
		end

		if not node_can_be_chiseled(pt.under) then
			return
		end

		ambiance.sound_play("anvil_clang", pt.under, 1.0, 30)
		show_chisel_formspec(pt.under, user)
	end,
})



local function handle_engraver_use(player, formname, fields)
	if not string.find(formname, "^engraver:chisel_") then
		return
	end
	if not player or not player:is_player() then
		return true
	end
	local pname = player:get_player_name()

	local pos = minetest.string_to_pos(string.sub(formname, string.len("engraver:chisel_") + 1))
	if not pos then
		return true
	end

	if not player_wields_tools(player) then
		return true
	end

	if not node_can_be_chiseled(pos) then
		return true
	end

	if not fields.text or type(fields.text) ~= "string" then
		return true
	end

	local message = utility.trim_remove_special_chars(fields.text)

	if anticurse.check(pname, message, "foul") then
		anticurse.log(pname, message)
		minetest.chat_send_player(pname, "# Server: Don't use a chisel for naughty talk!")
		return true
	elseif anticurse.check(pname, message, "curse") then
		anticurse.log(pname, message)
		minetest.chat_send_player(pname, "# Server: Please do not curse with a chisel.")
		return true
	end

	if string.len(message) > 256 then
		minetest.chat_send_player(pname, "# Server: Message is too long. Put something shorter.")
		return true
	end

	-- Add wear to the chisel.
	local got_chisel = false
	local inv = player:get_inventory()
	local index = player:get_wield_index()
	local chisel = inv:get_stack("main", index)
	if chisel:get_name() == "engraver:chisel" then
		chisel:add_wear(300)
		inv:set_stack("main", index, chisel)

		if chisel:is_empty() == 0 then
			ambiance.sound_play("default_tool_breaks", pos, 1.0, 10)
		end

		got_chisel = true
	end

	if got_chisel then
		local meta = minetest.get_meta(pos)
		meta:set_string("chiseled_text", message)
		meta:set_string("chiseled_date", os.time())
		meta:set_int("engraver_chiseled", 1)
		meta:mark_as_private({"chiseled_text", "chiseled_date", "engraver_chiseled"})

		-- Translate escape sequences.
		message = string.gsub(message, "%%[nN]", "\n")

		if message ~= "" then
			meta:set_string("infotext", message)
		else
			meta:set_string("infotext", "")
			meta:set_int("engraver_chiseled", 0)
		end

		minetest.chat_send_player(pname, "# Server: Text chiseled successfully.")
		ambiance.sound_play("anvil_clang", pos, 1.0, 30)
	end

	return true
end



minetest.register_on_player_receive_fields(handle_engraver_use)

minetest.register_craft({
	output = "engraver:chisel",
	recipe = {
		{"carbon_steel:ingot"},
		{"default:stick"},
	},
})




-- Code by 'octacian'

--
-- Formspec
--

local function get_workbench_formspec(pos, error)
	local msg = "Rename Item"
	local text = minetest.get_meta(pos):get_string("text")

	if error then
		msg = minetest.colorize("red", error)
	end

	return
		"size[8,7]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"field[0.5,0.5;6.2,1;text;"..msg..";"..minetest.formspec_escape(text).."]" ..
		"button[6.5,0.2;1.5,1;rename;Rename]" ..
		"list[context;input;1.5,1.4;1,1;]" ..
		"image[2.5,1.4;1,1;gui_workbench_plus.png]" ..
		"image[3.5,1.4;1,1;default_nametag_slot.png]" ..
		"list[context;nametag;3.5,1.4;1,1;]" ..
		"image[4.5,1.4;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
		"list[context;output;5.5,1.4;1,1]" ..
		"list[current_player;main;0,2.85;8,1;]" ..
		"list[current_player;main;0,4.08;8,3;8]" ..
		"field_close_on_enter[text;false]" ..
		default.get_hotbar_bg(0,2.85)
end

local function get_item_desc(stack)
	if not stack:is_known() then
		return
	end

	local desc = stack:get_meta():get_string("description")
	if desc == "" then
		desc = minetest.registered_items[stack:get_name()].description or ""
	end
	desc = utility.get_short_desc(desc)

	return desc
end

local function workbench_update_text(pos, stack)
	local meta = minetest.get_meta(pos)
	meta:set_string("text", get_item_desc(stack))
	meta:set_string("formspec", get_workbench_formspec(pos))
end

local function workbench_update_help(pos, type, string)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", get_workbench_formspec(pos, string))
	meta:set_string("error", type)
end

--
-- Node definition
--

minetest.register_node(":engraver:bench", {
	description = "Engraving Bench",
	tiles = {"default_workbench_top.png", "default_wood.png", "default_workbench_sides.png",
		"default_workbench_sides.png", "default_workbench_sides.png", "default_workbench_sides.png"},
	groups = utility.dig_groups("furniture", {flammable = 3}),
	sounds = default.node_sound_wood_defaults(),

	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 3/16, -0.5, 0.5, 0.5, 0.5},
			{-7/16, -0.5, 1/4, -1/4, 0.5, 7/16},
			{-7/16, -0.5, -7/16, -1/4, 0.5, -1/4},
			{1/4, -0.5, 1/4, 7/16, 0.5, 7/16},
			{1/4, -0.5, -7/16, 7/16, 0.5, -1/4},
		}
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_workbench_formspec(pos))
		local inv = meta:get_inventory()
		inv:set_size("input", 1)
		inv:set_size("nametag", 1)
		inv:set_size("output", 1)
	end,
	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()

		if inv:is_empty("input") and inv:is_empty("nametag") and
				inv:is_empty("output") then
			return true
		else
			return false
		end
	end,
	on_blast = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()

		local drops = {
			inv:get_list("input")[1],
			inv:get_list("nametag")[1],
			inv:get_list("output")[1],
			"engraver:bench",
		}
		minetest.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local pname = player:get_player_name()
		if minetest.test_protection(pos, pname) then
			return 0
		end
		if not stack:is_known() then
			return 0
		end

		if listname == "nametag" then
			if stack:get_name() ~= "engraver:plate" then
				return 0
			else
				return stack:get_count()
			end
		elseif listname == "output" then
			return 0
		elseif listname == "input" then
			if minetest.get_item_group(stack:get_name(), "not_renamable") > 0 then
				return 0
			end
			if stack:get_stack_max() > 1 then
				return 0
			end
			return stack:get_count()
		end

		return 0
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local pname = player:get_player_name()
		if minetest.test_protection(pos, pname) then
			return 0
		end
		return stack:get_count()
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local error = meta:get_string("error")

		if error == "input" and not inv:is_empty("input") then
			meta:set_string("formspec", get_workbench_formspec(pos))
		elseif error == "nametag" and not inv:is_empty("nametag") then
			meta:set_string("formspec", get_workbench_formspec(pos))
		end

		if listname == "input" then
			workbench_update_text(pos, stack)
		end
	end,

	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index)
		-- Moving is not allowed.
	end,

	on_metadata_inventory_take = function(pos, listname)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local error = meta:get_string("error")

		if error == "output" and inv:is_empty("output") then
			meta:set_string("formspec", get_workbench_formspec(pos))
		end

		if listname == "input" then
			meta:set_string("text", "")
			meta:set_string("formspec", get_workbench_formspec(pos))
		end
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local pname = sender:get_player_name()

		if fields.rename or fields.key_enter_field == "text" then
			meta:set_string("text", fields.text)

			if inv:is_empty("input") then
				workbench_update_help(pos, "input", "Missing input item!")
			elseif inv:is_empty("nametag") then
				workbench_update_help(pos, "nametag", "Missing nameplate!")
			elseif not inv:is_empty("output") then
				workbench_update_help(pos, "output", "No room in output!")
			else
				local new_stack  = inv:get_stack("input", 1)

				if not new_stack:is_known() then
					workbench_update_help(pos, nil, "Cannot rename unknown item!")
					return
				end

				local item       = minetest.registered_items[new_stack:get_name()]
				local renameable = item.groups.renameable ~= 0

				if not renameable then
					workbench_update_help(pos, nil, "Item cannot be renamed!")
					return
				elseif new_stack:get_stack_max() > 1 then
					workbench_update_help(pos, nil, "Item cannot be renamed!")
					return
				elseif fields.text == "" then
					workbench_update_help(pos, nil, "Description cannot be blank!")
					return
				elseif anticurse.check(pname, fields.text, "foul") then
					workbench_update_help(pos, nil, "No foul language!")
					return
				elseif anticurse.check(pname, fields.text, "curse") then
					workbench_update_help(pos, nil, "No cursing!")
					return
				elseif fields.text:len() > 256 then
					workbench_update_help(pos, nil, "Description too long (max 256 characters)!")
					return
				elseif fields.text == get_item_desc(inv:get_stack("input", 1)) then
					workbench_update_help(pos, nil, "Description not changed!")
				end

				local itemmeta = new_stack:get_meta()
				itemmeta:set_string("en_desc", fields.text)
				toolranks.apply_description(itemmeta, new_stack:get_definition())

				minetest.log("action", pname .. " renames "
					..inv:get_stack("input", 1):get_name().." to "..fields.text)

				inv:remove_item("input", inv:get_stack("input", 1))
				inv:remove_item("nametag", inv:get_stack("nametag", 1):take_item(1))
				inv:set_stack("output", 1, new_stack)

				meta:set_string("text", "")
				workbench_update_help(pos)
			end
		end
	end,
})

minetest.register_craft({
	output = "engraver:bench",
	recipe = {
		{'default:bronze_ingot', 'default:bronze_ingot', 'default:bronze_ingot'},
		{'basictrees:tree_wood', '', 'basictrees:tree_wood'},
		{'basictrees:tree_wood', '', 'basictrees:tree_wood'},
	}
})

minetest.register_craftitem(":engraver:plate", {
	description = "Nameplate",
	inventory_image = "default_nametag.png",
	groups = {not_renamable = 1}
})

minetest.register_craft({
	type = "compressing",
	output = "engraver:plate 4",
	recipe = "default:bronze_ingot",
	time = 10,
})

