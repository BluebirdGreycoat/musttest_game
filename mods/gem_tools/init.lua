--------------------------------------------------------------------------------
-- Gem Tools Mod for Must Test Survival
-- Author: GoldFireUn
-- License of Source Code: MIT
-- License of Media: CC BY-SA 3.0
--------------------------------------------------------------------------------

if not minetest.global_exists("gem_tools") then gem_tools = {} end
gem_tools.modpath = minetest.get_modpath("gem_tools")

-- This code is executed only once.
if not gem_tools.registered then
	local function register_sword(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{'', material, ''},
				{'farming:string', material, 'farming:string'},
				{'', 'default:sword_steel', ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{'', material, ''},
				{'farming:string', material, 'farming:string'},
				{'', 'titanium:sword', ''},
			}
		})
	end

	local function register_pick(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material, material, material},
				{'', 'farming:string', ''},
				{'', 'default:pick_steel', ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material, material, material},
				{'', 'farming:string', ''},
				{'', 'titanium:pick', ''},
			}
		})
	end

	local function register_axe(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material, material, ''},
				{material, 'farming:string', ''},
				{'', 'default:axe_steel', ''},
			}
		})

		minetest.register_craft({
			output = result,
			recipe = {
				{'', material, material},
				{'', 'farming:string', material},
				{'', 'default:axe_steel', ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material, material, ''},
				{material, 'farming:string', ''},
				{'', 'titanium:axe', ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{'', material, material},
				{'', 'farming:string', material},
				{'', 'titanium:axe', ''},
			}
		})
	end

	local function register_shovel(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material},
				{'farming:string'},
				{'default:shovel_steel'},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material},
				{'farming:string'},
				{'titanium:shovel'},
			}
		})
	end

	local gems = {
		{name="ruby", desc="Ruby"},
		{name="amethyst", desc="Amethyst"},
		{name="sapphire", desc="Sapphire"},
		{name="emerald", desc="Emerald"},
	}
	local tools = {
		{tool="pick", desc="Pickaxe", register=register_pick},
		{tool="sword", desc="Sword", register=register_sword},
		{tool="axe", desc="Axe", register=register_axe},
		{tool="shovel", desc="Shovel", register=register_shovel},
	}

	for k, v in ipairs(gems) do
		for i, j in ipairs(tools) do
			local material = "gems:" .. v.name .. "_gem"
			local tool = "gems:" .. j.tool .. "_" .. v.name
			local tool_rf_old = "gems:stone_" .. j.tool .. "_" .. v.name
			local tool_rf = "gems:rf_" .. j.tool .. "_" .. v.name
			local desc = v.desc .. " " .. j.desc
			local desc_rf = v.desc .. " " .. j.desc .. " (Reinforced Handle)"
			local data = j.tool .. "_" .. v.name
			local data_rf = j.tool .. "_" .. v.name .. "_rf"
			local iimg = "gem_tools_" .. v.name .. "_" .. j.tool .. ".png"
			local iimg_rf = "gem_tools_rf_" .. v.name .. "_" .. j.tool .. ".png"

			-- Ensure tooldata exists.
			assert(tooldata[data])
			assert(tooldata[data_rf])

			local sounds = {
				breaks = "basictools_tool_breaks",
			}

			if j.tool == "sword" or j.tool == "axe" then
				sounds.punch_use_air = "sword_swipe"
				sounds._punch_mob = "sword_flesh"
			end

			minetest.register_tool(":" .. tool, {
				description = desc,
				inventory_image = iimg,
				tool_capabilities = tooldata[data],
				groups = {gem_tool=1},
				sounds = sounds,
			})

			minetest.register_tool(":" .. tool_rf, {
				description = desc_rf,
				inventory_image = iimg_rf,
				tool_capabilities = tooldata[data_rf],
				groups = {gem_tool=1},
				sounds = sounds,
			})

			-- Register craft recipes.
			j.register(material, tool, tool_rf)

			-- Alias old tools.
			minetest.register_alias(tool_rf_old, tool_rf)
		end
	end

	-- Give players back their steel ingots.
	minetest.register_alias("gems:stone_rod", "default:steel_ingot")

	local c = "gem_tools:core"
	local f = gem_tools.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	gem_tools.registered = true
end
