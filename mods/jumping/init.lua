
-- Mod is reloadable.
if not minetest.global_exists("jumping") then jumping = {} end
jumping.modpath = minetest.get_modpath("jumping")

local next_node = {
	["jumping:bouncer_1"] = "jumping:bouncer_2",
	["jumping:bouncer_2"] = "jumping:bouncer_3",
	["jumping:bouncer_3"] = "jumping:bouncer_4",
	["jumping:bouncer_4"] = "jumping:bouncer_5",
	["jumping:bouncer_5"] = "jumping:bouncer_6",
	["jumping:bouncer_6"] = "jumping:bouncer_7",
	["jumping:bouncer_7"] = "jumping:bouncer_1",
}

local node_info = {
	["jumping:bouncer_1"] = "1",
	["jumping:bouncer_2"] = "2",
	["jumping:bouncer_3"] = "3",
	["jumping:bouncer_4"] = "4",
	["jumping:bouncer_5"] = "5",
	["jumping:bouncer_6"] = "6",
	["jumping:bouncer_7"] = "7",
}

function jumping.set_infotext(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "Bouncer: Strength " .. node_info[node.name])
end

function jumping.on_bouncer_punch(pos, node, puncher, pt)
	if not puncher or not puncher:is_player() then
		return
	end
	local pname = puncher:get_player_name()
	if minetest.test_protection(pos, pname) then
		minetest.chat_send_player(pname, "# Server: Bouncer is protected!")
		return
	end
	local nn = next_node[node.name]
	local cn = minetest.get_node(pos)
	cn.name = nn
	minetest.swap_node(pos, cn)
	jumping.set_infotext(pos)
end

-- One-time execution goes here.
if not jumping.run_once then
	for i = 1, 7, 1 do
		minetest.register_node("jumping:bouncer_"..i, {
			description = "Bouncing Cube",
			paramtype = "light",
			tiles = {"jumping_bouncer.png"},
			groups = utility.dig_groups("furniture", {
				bouncy = 20 + (i * 15),
				fall_damage_add_percent = -50,
			}),
			drop = "jumping:bouncer_1",
			on_construct = function(...)
				return jumping.set_infotext(...)
			end,
			on_punch = function(...)
				return jumping.on_bouncer_punch(...)
			end,
		})
	end

	minetest.register_node("jumping:cushion", {
		description = "Falling Cushion",
		paramtype = "light",
		tiles = {"jumping_cushion.png"},
		groups = utility.dig_groups("furniture", {
			disable_jump = 1,
			fall_damage_add_percent = -70,
		}),
	})

	minetest.register_craft({
		output = "jumping:bouncer_1",
		recipe = {
			{"default:steel_ingot", "wool:black", "default:steel_ingot"},
			{"wool:black", "wool:black", "wool:black"},
			{"default:steel_ingot", "wool:black", "default:steel_ingot"}
		}
	})

	minetest.register_craft({
		output = "jumping:cushion",
		recipe = {
			{"default:steel_ingot", "wool:cyan", "default:steel_ingot"},
			{"wool:cyan", "wool:cyan", "wool:cyan"},
			{"default:steel_ingot", "wool:cyan", "default:steel_ingot"}
		}
	})

	local c = "jumping:core"
	local f = jumping.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	jumping.run_once = true
end
