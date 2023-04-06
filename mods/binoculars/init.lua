-- Mod global namespace

if not minetest.global_exists("binoculars") then binoculars = {} end
binoculars.modpath = minetest.get_modpath("binoculars")

-- Update player property
-- Global to allow overriding

-- May be called with player object or player name.
function binoculars.update_player_property(player)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	if not player or not player:is_player() then
		return
	end

	local new_zoom_fov = 0
	local have_binocs = false

	if player:get_wielded_item():get_name() == "binoculars:binoculars" then
		new_zoom_fov = 10
		have_binocs = true
	end

	-- Only set property if necessary to avoid player mesh reload
	if player:get_properties().zoom_fov ~= new_zoom_fov then
		player:set_properties({zoom_fov = new_zoom_fov})
	end

	if have_binocs then
		return true
	end
end

function binoculars.deploy(pname)
	if binoculars.update_player_property(pname) then
		minetest.after(1, function() binoculars.deploy(pname) end)
	end
end

function binoculars.on_use(itemstack, user, pointed_thing)
	binoculars.deploy(user:get_player_name())
end

if not binoculars.loaded then
	-- Binoculars item.
	minetest.register_node("binoculars:binoculars", {
		tiles = {"binoculars_binoculars.png"},
		wield_image = "binoculars_binoculars.png",
		description = "Binoculars\n\nUse (punch) and press the 'zoom' key.\nMust be wielded to continue using.",
		inventory_image = "binoculars_binoculars.png",
		paramtype = 'light',
		paramtype2 = "wallmounted",
		drawtype = "nodebox",
		sunlight_propagates = true,
		walkable = false,
		node_box = {
			type = "wallmounted",
			wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
			wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
			wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
		},
		selection_box = {type = "wallmounted"},
		stack_max = 1,
		groups = utility.dig_groups("bigitem", {flammable = 3, attached_node = 1}),
		sounds = default.node_sound_leaves_defaults(),

		on_use = function(...)
			return binoculars.on_use(...)
		end,
	})

	-- Crafting.
	minetest.register_craft({
		output = "binoculars:binoculars",
		recipe = {
			{"default:obsidian_glass", "", "default:obsidian_glass"},
			{"default:bronze_ingot", "brass:ingot", "default:bronze_ingot"},
			{"default:obsidian_glass", "", "default:obsidian_glass"},
		}
	})

	local c = "binoculars:core"
	local f = binoculars.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	binoculars.loaded = true
end

