
-- This is a cleanroom reimplementation of the GPL "anvil" mod commonly found
-- lying around. This reimplementation is developed from memory and in-game
-- (loose) behavior testing. It is provided under the MIT license.

if not minetest.global_exists("anvil") then anvil = {} end
anvil.modpath = minetest.get_modpath("anvil")



-- Check whether itemstack is repairable by anvils.
function anvil.item_repairable_or_craftable(itemstack)
	if minetest.get_item_group(itemstack:get_name(), "not_repaired_by_anvil") ~= 0 then
		return false
	end
	if minetest.get_craft_result({
				method = "anvil",
				width = 1,
				items = {itemstack}
			}).time ~= 0 then
		return true
	end
	if minetest.registered_tools[itemstack:get_name()] then
		return true
	end
	return false
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
	local smeta = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

	local formspec = "size[8,8]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[2.5,1;Workspace]" ..
		"list[" .. smeta .. ";input;2.5,1.5;3,1;]" ..
		"list[current_player;main;0,3.75;8,1;]" ..
		"list[current_player;main;0,5;8,3;8]" ..
		default.get_hotbar_bg(0, 3.75)

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
	inv:set_size("input", 3)

	anvil.update_infotext(pos)
	anvil.update_formspec(pos)
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
	local list = inv:get_list("input")

	for index, stack in ipairs(list) do
		if not stack:is_empty() then
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
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return inv:get_stack(from_list, from_index):get_count()
end



-- After inventory move.
function anvil.on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, user)
end



-- Can player put stuff in inventory.
function anvil.allow_metadata_inventory_put(pos, listname, index, stack, user)
	if not anvil.item_repairable_or_craftable(stack) then
		return 0
	end
	return stack:get_count()
end



-- After inventory put.
function anvil.on_metadata_inventory_put(pos, listname, index, stack, user)
end



-- Can player take stuff from inventory.
function anvil.allow_metadata_inventory_take(pos, listname, index, stack, user)
	return stack:get_count()
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
	anvil.sparks_and_sound(pos)
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



-- Make sparks fly!
function anvil.sparks_and_sound(pos)
	local pos = vector.add(pos, {
		x = math.random(-10, 10) / 30,
		y = 0.2,
		z = math.random(-10, 10) / 30
	})
	minetest.add_particlespawner({
		amount = 6,
		time = 0.2,
		collisiondetection = true,
		collision_removal = true,
		texture = "anvil_particle_spark.png",
		glow = 13,
		minsize = 1,
		maxsize = 1,
		minpos = vector.add(pos, {x=0, y=0, z=0}),
		maxpos = vector.add(pos, {x=0, y=0, z=0}),
		minvel = {x=-4, y=1, z=-4},
		maxvel = {x=4, y=2, z=4},
		minacc = {x=0, y=-8, z=0},
		maxacc = {x=0, y=-8, z=0},
		minexptime = 0.5,
		maxexptime = 1.0,
	})
	ambiance.sound_play("anvil_clang", pos, 0.5, 40)
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


	local function box(x1, y1, z1, x2, y2, z2)
		return {
			x1 / 16 - 0.5,
			y1 / 16 - 0.5,
			z1 / 16 - 0.5,
			x2 / 16 - 0.5,
			y2 / 16 - 0.5,
			z2 / 16 - 0.5,
		}
	end


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

		node_box = {
			type = "fixed",
			fixed = {
				box(-3, 8, 7, 0, 10, 9),
				box(0, 7, 6, 3, 10, 10),
				box(3, 7, 5, 16, 10, 11),
				box(16, 8, 6, 18, 10, 10),
				box(3, 6, 6, 15, 7, 10),
				box(5, 3, 6, 11, 6, 10),
				box(3, 2, 5, 13, 3, 11),
				box(2, 0, 5, 14, 2, 11),
				box(2, 0, 3, 4, 2, 13),
				box(12, 0, 3, 14, 2, 13),
			},
		},

		selection_box = {
			type = "fixed",
			fixed = {
				box(-3, 7, 5, 18, 10, 11),
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				box(0, 0, 4, 16, 10, 12),
			},
		},

		groups = utility.dig_groups("bigitem", {falling_node=1}),
		drop = 'anvil:anvil',
		sounds = default.node_sound_metal_defaults({dig="default_silence"}),
		stack_max = 1,

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
		_on_update_infotext = function(...) return anvil.update_infotext(...) end,
		_on_update_formspec = function(...) return anvil.update_formspec(...) end,
		_on_update_entity = function(...) return anvil.update_entity(...) end,
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
