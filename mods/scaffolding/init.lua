
scaffolding = scaffolding or {}
scaffolding.modpath = minetest.get_modpath("scaffolding")



dofile(minetest.get_modpath("scaffolding").."/sort.lua")



if not scaffolding.run_once then
	dofile(minetest.get_modpath("scaffolding").."/functions.lua")

	minetest.register_craftitem("scaffolding:scaffolding_wrench", {
		description = "Scaffolding Reinforcement & Chest Sorting Wrench",
		inventory_image = "scaffolding_wrench.png",

		on_use = function(...)
			return scaffolding.wrench_on_use(...)
		end,
	})



	minetest.register_node("scaffolding:scaffolding", {
			description = "Wooden Scaffolding",
			drawtype = "nodebox",
			tiles = {"scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding.png",
			"scaffolding_wooden_scaffolding.png", "scaffolding_wooden_scaffolding.png", "scaffolding_wooden_scaffolding.png"},
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = true,
			walkable = false,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_wood_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:reinforced_scaffolding"
							minetest.env:set_node(pos, node)
							--puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,
			--[[on_rightclick = function(pos, node, player, itemstack, pointed_thing)
					if itemstack:get_name() == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:reinforced_scaffolding"
							minetest.env:set_node(pos, node)

					end
			end,
			on_punch = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "air"
							minetest.env:set_node(pos, node)
							puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,]]
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
			after_dig_node = function(pos, node, metadata, digger)
			default.dig_up(pos, node, digger)
	end,
	})

	minetest.register_node("scaffolding:reinforced_scaffolding", {
			description = "Wooden Scaffolding",
			drawtype = "nodebox",
			tiles = {"scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png", "scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png",
			"scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png"},
			drop = "scaffolding:scaffolding",
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = true,
			walkable = false,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_wood_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:scaffolding"
							minetest.env:set_node(pos, node)
							--puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,
			--[[ on_rightclick = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:scaffolding"
							minetest.env:set_node(pos, node)
					end
			end,
			on_punch = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "air"
							minetest.env:set_node(pos, node)
							puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,]]
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
	})

	minetest.register_node("scaffolding:platform", {
			description = "Wooden Platform",
			drawtype = "nodebox",
			tiles = {"scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding_top.png", "scaffolding_wooden_scaffolding.png^scaffolding_platform.png"},
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = false,
			walkable = true,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_wood_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:reinforced_platform"
							minetest.env:set_node(pos, node)
					end
			end,
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
			after_dig_node = function(pos, node, metadata, digger)
			scaffolding.dig_horx(pos, node, digger)
			scaffolding.dig_horx2(pos, node, digger)
			scaffolding.dig_horz(pos, node, digger)
			scaffolding.dig_horz2(pos, node, digger)
	end,
	})

	minetest.register_node("scaffolding:reinforced_platform", {
			description = "Wooden Platform",
			drawtype = "nodebox",
			tiles = {"scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png", "scaffolding_wooden_scaffolding.png^scaffolding_reinforced.png", "scaffolding_wooden_scaffolding.png^scaffolding_platform.png"},
			drop = "scaffolding:platform",
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = false,
			walkable = true,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_wood_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:platform"
							minetest.env:set_node(pos, node)
					end
			end,
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
	})

	minetest.register_node("scaffolding:iron_scaffolding", {
			description = "Iron Scaffolding",
			drawtype = "nodebox",
			tiles = {"scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding.png",
			"scaffolding_iron_scaffolding.png", "scaffolding_iron_scaffolding.png", "scaffolding_iron_scaffolding.png"},
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = true,
			walkable = false,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_stone_defaults(),
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:reinforced_iron_scaffolding"
							minetest.env:set_node(pos, node)
							--puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,
	--[[on_rightclick = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:reinforced_iron_scaffolding"
							minetest.env:set_node(pos, node)
					end
			end,
			on_punch = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "air"
							minetest.env:set_node(pos, node)
							--puncher:get_inventory():remove_item("main", ItemStack("beer_test:tankard"))
							puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,]]
	after_dig_node = function(pos, node, metadata, digger)
			default.dig_up(pos, node, digger)
	end,
	})

	minetest.register_node("scaffolding:reinforced_iron_scaffolding", {
			description = "Iron Scaffolding",
			drawtype = "nodebox",
			tiles = {"scaffolding_iron_scaffolding.png^scaffolding_reinforced.png", "scaffolding_iron_scaffolding.png^scaffolding_reinforced.png",
			"scaffolding_iron_scaffolding.png^scaffolding_reinforced.png"},
			drop = "scaffolding:iron_scaffolding",
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = true,
			walkable = false,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_stone_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:iron_scaffolding"
							minetest.env:set_node(pos, node)
							--puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,
			--[[on_rightclick = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:iron_scaffolding"
							minetest.env:set_node(pos, node)
					end
			end,
			on_punch = function(pos, node, puncher)
			local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "air"
							minetest.env:set_node(pos, node)
							--puncher:get_inventory():remove_item("main", ItemStack("beer_test:tankard"))
							puncher:get_inventory():add_item("main", ItemStack("scaffolding:scaffolding"))
					end
			end,]]
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
					},
			},
	})

	minetest.register_node("scaffolding:iron_platform", {
			description = "Iron Platform",
			drawtype = "nodebox",
			tiles = {"scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding_top.png", "scaffolding_iron_scaffolding.png^scaffolding_platform.png"},
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = false,
			walkable = true,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_stone_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:reinforced_iron_platform"
							minetest.env:set_node(pos, node)
					end
			end,
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
			after_dig_node = function(pos, node, metadata, digger)
					scaffolding.dig_horx(pos, node, digger)
					scaffolding.dig_horx2(pos, node, digger)
					scaffolding.dig_horz(pos, node, digger)
					scaffolding.dig_horz2(pos, node, digger)
			end,
	})

	minetest.register_node("scaffolding:reinforced_iron_platform", {
			description = "Iron Platform",
			drawtype = "nodebox",
			tiles = {"scaffolding_iron_scaffolding.png^scaffolding_reinforced.png", "scaffolding_iron_scaffolding.png^scaffolding_reinforced.png", "scaffolding_iron_scaffolding.png^scaffolding_platform.png"},
			drop = "scaffolding:iron_platform",
			paramtype = "light",
			paramtype2 = "facedir",
			climbable = false,
			walkable = true,
			groups = utility.dig_groups("scaffolding", {scaffolding=1}),
			sounds = default.node_sound_stone_defaults(),
			on_punch = function(pos, node, puncher)
					local tool = puncher:get_wielded_item():get_name()
					if tool and tool == "scaffolding:scaffolding_wrench" then
							node.name = "scaffolding:iron_platform"
							minetest.env:set_node(pos, node)
					end
			end,
			node_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
			selection_box = {
					type = "fixed",
					fixed = {
							{-0.5, -0.3, -0.5, 0.5, 0.1, 0.5},
					},
			},
	})

	----------------------
	-- wood scaffolding --
	----------------------

	minetest.register_craft({
		output = 'scaffolding:scaffolding 12',
		recipe = {
			{'group:wood', 'group:wood', 'group:wood'},
			{'group:stick', '', 'group:stick'},
			{'group:wood', 'group:wood', 'group:wood'},
		}
	})

	minetest.register_craft({
		output = 'scaffolding:scaffolding 4',
		recipe = {
			{'group:wood'},
			{'group:stick'},
			{'group:wood'},
		}
	})

	-- back to scaffolding --

	minetest.register_craft({
		output = 'scaffolding:scaffolding',
		recipe = {
			{'scaffolding:platform'},
			{'scaffolding:platform'},
		}
	})

	-- wood platforms --

	minetest.register_craft({
		output = 'scaffolding:platform 2',
		recipe = {
			{'scaffolding:scaffolding'},
		}
	})

	minetest.register_craft({
		output = 'scaffolding:platform 6',
		recipe = {
			{'scaffolding:scaffolding', 'scaffolding:scaffolding', 'scaffolding:scaffolding'},
		}
	})

	----------------------
	-- iron scaffolding --
	----------------------

	minetest.register_craft({
		output = 'scaffolding:iron_scaffolding 12',
		recipe = {
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'group:stick', '', 'group:stick'},
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		}
	})

	minetest.register_craft({
		output = 'scaffolding:iron_scaffolding 4',
		recipe = {
			{'default:steel_ingot'},
			{'group:stick'},
			{'default:steel_ingot'},
		}
	})
	-- back to scaffolding --

	minetest.register_craft({
		output = 'scaffolding:iron_scaffolding',
		recipe = {
			{'scaffolding:iron_platform'},
			{'scaffolding:iron_platform'},
		}
	})

	-- iron platforms --

	minetest.register_craft({
		output = 'scaffolding:iron_platform 2',
		recipe = {
			{'scaffolding:iron_scaffolding'},
		}
	})

	minetest.register_craft({
		output = 'scaffolding:iron_platform 6',
		recipe = {
			{'scaffolding:iron_scaffolding', 'scaffolding:iron_scaffolding', 'scaffolding:iron_scaffolding'},
		}
	})


	------------
	-- wrench --
	------------

	minetest.register_craft({
		output = 'scaffolding:scaffolding_wrench',
		recipe = {
			{'', 'default:steel_ingot', ''},
			{'', 'default:steel_ingot', 'default:steel_ingot'},
			{'default:steel_ingot', '', ''},
		}
	})

	local c = "scaffolding:core"
	local f = scaffolding.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	scaffolding.run_once = true
end


