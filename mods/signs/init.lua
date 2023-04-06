
if not minetest.global_exists("signs") then signs = {} end
signs.modpath = minetest.get_modpath("signs")

local MAX_SIGN_LENGTH = 256

function signs.on_punch(pos, node, puncher, pt)
	minetest.get_meta(pos):set_string("formspec", nil)
end

function signs.on_construct(pos)
	--local n = minetest.get_node(pos)
	--local meta = minetest.get_meta(pos)
	--meta:set_string("formspec", "field[text;;${text}]")
end

function signs.on_rightclick(pos, node, clicker, itemstack, pt)
	local pname = clicker:get_player_name()
	local text = minetest.get_meta(pos):get_string("text")

	--local formspec = "field[text;;${text}]"
	local formspec = ""
	formspec = formspec ..
		"size[5,2.3]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"item_image[1,1;1,1;" .. minetest.formspec_escape(node.name) .. "]" ..
		"field[0.3,0.3;5,1;text;;" .. minetest.formspec_escape(text) .. "]" ..
		"button_exit[2,1;2,1;proceed;Proceed]" ..
		"label[0,2;`%n' inserts a new line.]"

	local formname = "signs:input_" .. minetest.pos_to_string(pos)
	minetest.show_formspec(pname, formname, formspec)
end

function signs.on_receive_fields(pos, formname, fields, sender)
	local pname = sender:get_player_name()
	if minetest.test_protection(pos, pname) then
		return
	end

	local meta = minetest.get_meta(pos)
	if not fields.text or type(fields.text) ~= "string" then
		return
	end

	-- Max sign length.
	local the_text = fields.text:sub(1, MAX_SIGN_LENGTH)
	local message = utility.trim_remove_special_chars(the_text)

	if anticurse.check(pname, message, "foul") then
		anticurse.log(pname, message)
		minetest.chat_send_player(pname, "# Server: Please do not write dirty talk on a sign.")
		return
	elseif anticurse.check(pname, message, "curse") then
		anticurse.log(pname, message)
		minetest.chat_send_player(pname, "# Server: Please do not curse on a sign.")
		return
	end

	minetest.log("action", pname .. " wrote \"" ..
		message .. "\" to sign at " .. minetest.pos_to_string(pos))

	meta:set_string("text", message)
	meta:set_string("author", pname)

	meta:mark_as_private({"text", "author"})

	-- Translate escape sequences.
	message = string.gsub(message, "%%[nN]", "\n")

	meta:set_string("infotext", message)

	-- Zero-out old stuff.
	meta:set_string("formspec", nil)
end

function signs.on_player_receive_fields(player, formname, fields)
	if not string.find(formname, "^signs:input_") then
		return
	end
	if not player or not player:is_player() then
		return true
	end

	local pos = minetest.string_to_pos(string.sub(formname, string.len("signs:input_") + 1))
	if not pos then
		return true
	end

	-- Make sure player is actually using a sign.
	local node = minetest.get_node(pos)
	local name = node.name
	if name ~= "signs:sign_wall_wood" and name ~= "signs:sign_wall_steel" and name ~= "signs:sign_wall_tin" then
		return true
	end

	signs.on_receive_fields(pos, "", fields, player)
	return true
end

if not signs.run_once then
	local function register_sign(material, desc, def)
		minetest.register_node("signs:sign_wall_" .. material, {
			description = desc .. " Sign",
			drawtype = "nodebox",
			tiles = {"default_sign_wall_" .. material .. ".png"},
			inventory_image = "default_sign_" .. material .. ".png",
			wield_image = "default_sign_" .. material .. ".png",
			paramtype = "light",
			paramtype2 = "wallmounted",
			sunlight_propagates = true,
			is_ground_content = false,
			walkable = false,
			floodable = true,
			node_box = {
				type = "wallmounted",
				wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
				wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
				wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
			},
			groups = def.groups,
			legacy_wallmounted = true,
			sounds = def.sounds,

			on_construct = function(...)
				return signs.on_construct(...)
			end,

			on_receive_fields = function(...)
				return signs.on_receive_fields(...)
			end,

			on_rightclick = function(...)
				return signs.on_rightclick(...)
			end,

			on_punch = function(...)
				return signs.on_punch(...)
			end,
		})
	end

	register_sign("wood", "Wooden", {
		sounds = default.node_sound_wood_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1, flammable = 2})
	})

	register_sign("steel", "Iron", {
		sounds = default.node_sound_metal_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	register_sign("tin", "Tin", {
		sounds = default.node_sound_metal_defaults(),
		groups = utility.dig_groups("bigitem", {attached_node = 1})
	})

	minetest.register_craft({
		output = 'signs:sign_wall_steel 3',
		recipe = {
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_tin 3',
		recipe = {
			{'moreores:tin_ingot', 'moreores:tin_ingot', 'moreores:tin_ingot'},
			{'moreores:tin_ingot', 'moreores:tin_ingot', 'moreores:tin_ingot'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_craft({
		output = 'signs:sign_wall_wood 3',
		recipe = {
			{'group:wood', 'group:wood', 'group:wood'},
			{'group:wood', 'group:wood', 'group:wood'},
			{'', 'group:stick', ''},
		}
	})

	minetest.register_alias("default:sign_wall_wood", "signs:sign_wall_wood")
	minetest.register_alias("default:sign_wall_steel", "signs:sign_wall_steel")

	minetest.register_on_player_receive_fields(function(...)
		return signs.on_player_receive_fields(...) end)

	local c = "signs:core"
	local f = signs.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	signs.run_once = true
end


