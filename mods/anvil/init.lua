
-- This is a cleanroom reimplementation of the GPL "anvil" mod commonly found
-- lying around. This reimplementation is developed from memory and in-game
-- (loose) behavior testing. It is provided under the MIT license.

if not minetest.global_exists("anvil") then anvil = {} end
anvil.modpath = minetest.get_modpath("anvil")



-- Check whether itemstack is repairable by anvils.
function anvil.item_repairable(itemstack)
	if minetest.get_item_group(itemstack:get_name(), "not_repaired_by_anvil") ~= 0 then
		return true
	end
	return false
end



-- Get inventory list names.
function anvil.get_inventory_names()
	return {"input", "output"}
end



-- Anvil item entity activation function.
function anvil.on_activate(self, staticdata)
end



-- Anvil item entity staticdata function.
function anvil.get_staticdata(self)
	return ""
end



-- Updates infotext according to current state.
function anvil.update_infotext(pos)
	local info = "Placeholder"

	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", info)
end



-- Updates formspec according to current state.
function anvil.update_formspec(pos)
	local formspec = "size[8,8]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots

	-- Note: using a NON-standard name because we do NOT want special
	-- engine/client handling. This is just a storage space for the formspec
	-- string, but we send it to the client manually.
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec2", formspec)
end



-- Node constructor.
function anvil.on_construct(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local lists = anvil.get_inventory_names()

	for index, name in ipairs(lists) do
		inv:set_size(name, 1)
	end

	anvil.update_entity(pos)
end



-- Node destructor.
function anvil.on_destruct(pos)
	anvil.remove_entity(pos)
end



-- Anvil gets blasted.
function anvil.on_blast(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local lists = anvil.get_inventory_names()

	for index, name in ipairs(lists) do
		local stack = inv:get_stack(name, 1)

		if not stack:is_empty() then
			inv:set_stack(name, ItemStack(""))
			minetest.add_item(pos, stack)
		end
	end

	minetest.remove_node(pos)
end



-- Anvil fell but cannot be placed as a node for some reason.
function anvil.on_collapse_to_entity(pos, node)
end



-- Anvil fell and was reconstructed as a node.
function anvil.on_finish_collapse(pos, node)
	anvil.update_entity(pos)
end



-- Formspec received fields.
function anvil.on_player_receive_fields(player, formname, fields)
	local fn = formname:sub(1, 14)
	if fn ~= "anvil:formspec" then
		return
	end

	local pos = minetest.string_to_pos(formname:sub(16))
	if not pos then
		return
	end

	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local plpos = player:get_pos()

	-- Require close interactions (needed for security, since owner can be blank).
	if vector.distance(pos, plpos) > 10 then
		return
	end

	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)

	local owner = meta:get_string("owner")

	-- If owner is unset, let anyone use it.
	if owner ~= "" and owner ~= pname then
		return
	end

	-- We handled it.
	return true
end



-- Function to show player the formspec.
function anvil.show_formspec(pname, pos)
	local meta = minetest.get_meta(pos)
	local fs = meta:get_string("formspec2")
	local sp = minetest.pos_to_string(pos)
	minetest.show_formspec(pname, "anvil:formspec_" .. sp, fs)
end



-- Player rightclicks on anvil.
function anvil.on_rightclick(pos, node, user, itemstack, pt)
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	anvil.show_formspec(pname, pos)
end



-- Function to update entity display.
function anvil.update_entity(pos)
end



-- Remove the entity display.
function anvil.remove_entity(pos)
end



-- Can player move stuff in inventory.
function anvil.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, user)
	return 1
end



-- After inventory move.
function anvil.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



-- Can player put stuff in inventory.
function anvil.allow_metadata_inventory_put(pos, listname, index, stack, user)
	return 1
end



-- After inventory put.
function anvil.on_metadata_inventory_put(pos, listname, index, stack, user)
end



-- Can player take stuff from inventory.
function anvil.allow_metadata_inventory_take(pos, listname, index, stack, user)
	return 1
end



-- After inventory take.
function anvil.on_metadata_inventory_take(pos, listname, index, stack, user)
end



-- After place node.
function anvil.after_place_node(pos, user, itemstack, pt)
	if not user or not user:is_player() then
		return
	end

	local pname = user:get_player_name()
	local control = user:get_player_control()

	local meta = minetest.get_meta(pos)

	-- Hold 'E' to set owner, otherwise anyone can use.
	if control.aux1 then
		meta:set_string("owner", pname)
	end
end



-- Player punches anvil.
function anvil.on_punch(pos, node, user, pt)
end



-- Timer fires.
function anvil.on_timer(pos, elapsed)
end



-- Check if diggable.
function anvil.can_dig(pos, user)
	if not user or not user:is_player() then
		return false
	end

	return true
end



if not anvil.registered then
	anvil.registered = true

	minetest.register_on_player_receive_fields(function(...)
		return anvil.on_player_receive_fields(...) end)


	-- Display entity.
	minetest.register_entity("anvil:item", {
		initial_properties = {
			visual = "item",
			wield_item = "default:coal_lump",
			visual_size = {x=0.4, y=0.4, z=0.4},
			collide_with_objects = false,
			pointable = false,
			collisionbox = {0},
		},

		on_activate = function(...) return anvil.on_activate(...) end,
		get_staticdata = function(...) return anvil.get_staticdata(...) end,
	})


	-- The node.
	minetest.register_node("anvil:anvil", {
		description = "Blacksmithing Anvil",
		drawtype = "nodebox",
		tiles = {
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
			{name="anvil_tool_anvil.png"},
		},
		paramtype2 = "facedir",
		on_rotate = function(...) return screwdriver.rotate_simple(...) end,

		groups = utility.dig_groups("bigitem", {falling_node=1}),
		drop = 'anvil:anvil',
		sounds = default.node_sound_metal_defaults(),

		on_construct = function(...) return anvil.on_construct(...) end,
		on_destruct = function(...) return anvil.on_destruct(...) end,
		on_blast = function(...) return anvil.on_blast(...) end,
		on_collapse_to_entity = function(...) return anvil.on_collapse_to_entity(...) end,
		on_finish_collapse = function(...) return anvil.on_finish_collapse(...) end,
		on_rightclick = function(...) return anvil.on_rightclick(...) end,
		allow_metadata_inventory_move = function(...) return anvil.allow_metadata_inventory_move(...) end,
		allow_metadata_inventory_put = function(...) return anvil.allow_metadata_inventory_put(...) end,
		allow_metadata_inventory_take = function(...) return anvil.allow_metadata_inventory_take(...) end,
		on_metadata_inventory_move = function(...) return anvil.on_metadata_inventory_move(...) end,
		on_metadata_inventory_put = function(...) return anvil.on_metadata_inventory_put(...) end,
		on_metadata_inventory_take = function(...) return anvil.on_metadata_inventory_take(...) end,
		after_place_node = function(...) return anvil.after_place_node(...) end,
		on_punch = function(...) return anvil.on_punch(...) end,
		on_timer = function(...) return anvil.on_timer(...) end,
		can_dig = function(...) return anvil.can_dig(...) end,
	})


	-- Hammering tool.
	minetest.register_tool("anvil:hammer", {
		description = "Blacksmithing Hammer",
		inventory_image = "anvil_tool_steelhammer.png",
		wield_image = "anvil_tool_steelhammer.png",
		tool_capabilities = tooldata["hammer_hammer"],
		sound = {
			breaks = "basictools_tool_breaks",
		},
		groups = {not_repaired_by_anvil=1},
	})


	minetest.register_craft({
		output = "anvil:hammer",
		recipe = {
			{"carbon_steel:ingot", "darkage:iron_stick", "carbon_steel:ingot"},
			{"carbon_steel:ingot", "darkage:iron_stick", "carbon_steel:ingot"},
			{"", "darkage:iron_stick", ""},
		},
	})


	minetest.register_craft({
		output = "anvil:anvil",
		recipe = {
			{"carbon_steel:ingot", "carbon_steel:ingot", "carbon_steel:ingot"},
			{"", "cast_iron:ingot", ""},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		},
	})


	-- Register mod reloadable.
	local c = "anvil:core"
	local f = anvil.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
