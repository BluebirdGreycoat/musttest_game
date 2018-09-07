--------------------------------------------------------------------------------
-- Gem Tools Mod for Must Test Survival
-- Author: GoldFireUn
-- License of Source Code: MIT
-- License of Media: CC BY-SA 3.0
--------------------------------------------------------------------------------

gem_tools = gem_tools or {}
gem_tools.modpath = minetest.get_modpath("gem_tools")

-- This code is executed only once.
if not gem_tools.registered then
	local REINFORCED_HANDLE = "carbon_steel:ingot"

	local function register_sword(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material},
				{material},
				{'default:stick'},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material},
				{material},
				{REINFORCED_HANDLE},
			}
		})
	end

	local function register_pick(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material, material, material},
				{'', 'default:stick', ''},
				{'', 'default:stick', ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material, material, material},
				{'', REINFORCED_HANDLE, ''},
				{'', REINFORCED_HANDLE, ''},
			}
		})
	end

	local function register_axe(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material, material, ''},
				{material, 'default:stick', ''},
				{'', 'default:stick', ''},
			}
		})

		minetest.register_craft({
			output = result,
			recipe = {
				{'', material, material},
				{'', 'default:stick', material},
				{'', 'default:stick', ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material, material, ''},
				{material, REINFORCED_HANDLE, ''},
				{'', REINFORCED_HANDLE, ''},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{'', material, material},
				{'', REINFORCED_HANDLE, material},
				{'', REINFORCED_HANDLE, ''},
			}
		})
	end

	local function register_shovel(material, result, reinforced)
		minetest.register_craft({
			output = result,
			recipe = {
				{material},
				{'default:stick'},
				{'default:stick'},
			}
		})

		minetest.register_craft({
			output = reinforced,
			recipe = {
				{material},
				{REINFORCED_HANDLE},
				{REINFORCED_HANDLE},
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
			local data_rf = j.tool .. "_" .. v.name .. "stone"
			local iimg = "gem_tools_" .. v.name .. "_" .. j.tool .. ".png"
			local iimg_rf = "gem_tools_rf_" .. v.name .. "_" .. j.tool .. ".png"

			-- Ensure tooldata exists.
			assert(tooldata[data])
			assert(tooldata[data_rf])

			minetest.register_tool(":" .. tool, {
				description = desc,
				inventory_image = iimg,
				tool_capabilities = tooldata[data],
			})

			minetest.register_tool(":" .. tool_rf, {
				description = desc_rf,
				inventory_image = iimg_rf,
				tool_capabilities = tooldata[data_rf],
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
