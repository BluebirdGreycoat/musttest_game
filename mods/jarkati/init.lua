
if not minetest.global_exists("jarkati") then jarkati = {} end
jarkati.modpath = minetest.get_modpath("jarkati")

function jarkati.on_generated(minp, maxp, blockseed)
	local mapgen = minetest.get_mapgen_object("gennotify")
	local data = (mapgen.custom and mapgen.custom["jarkati:mapgen_info"])
	if not data then return end

	-- 2024/6/8: this ugly hack is currently the best way I know of to make light
	-- correct after chunk generation.
	minetest.after(math.random(1, 100) / 50, function()
		local emin = vector.add(data.minp, {x=-16, y=-16, z=-16})
		local emax = vector.add(data.maxp, {x=16, y=16, z=16})
		--minetest.chat_send_all('mapfix')
		mapfix.work(emin, emax)
	end)

	minetest.after(0, function()
		local t = data.nest_positions
		if #t > 0 then
			--minetest.chat_send_all('generating wisp nest at ' .. dump(data.nest_positions))
			for k = 1, #t do
				pm.on_wisp_vent_place(t[k])
			end
		end
	end)
end



if not jarkati.registered then
	minetest.set_gen_notify("custom", nil, {"jarkati:mapgen_info"})
	minetest.register_on_generated(function(...)
		jarkati.on_generated(...)
	end)

	minetest.register_mapgen_script(jarkati.modpath .. "/mapgen.lua")

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_copper",
		wherein = {"default:desert_stone"},
		clust_scarcity = 6*6*6,
		clust_num_ores = 4,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_copper",
		wherein = {"default:desert_stone"},
		clust_scarcity = 15*15*15,
		clust_num_ores = 27,
		clust_size = 6,
		y_min = 3600,
		y_max = 3700,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_iron",
		wherein = {"default:desert_stone"},
		clust_scarcity = 10*10*10,
		clust_num_ores = 4,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_iron",
		wherein = {"default:desert_stone"},
		clust_scarcity = 24*24*24,
		clust_num_ores = 27,
		clust_size = 6,
		y_min = 3600,
		y_max = 3700,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_diamond",
		wherein = {"default:desert_stone"},
		clust_scarcity = 17*17*17,
		clust_num_ores = 4,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_diamond",
		wherein = {"default:desert_stone"},
		clust_scarcity = 15*15*15,
		clust_num_ores = 6,
		clust_size = 3,
		y_min = 3600,
		y_max = 3700,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "default:desert_stone_with_coal",
		wherein = {"default:desert_stone"},
		clust_scarcity = 8*8*8,
		clust_num_ores = 8,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	oregen.register_ore({
		ore_type = "scatter",
		ore = "pm:quartz_ore",
		wherein = {"default:desert_sand"},
		clust_scarcity = 8*8*8,
		clust_num_ores = 8,
		clust_size = 3,
		y_min = 3600,
		y_max = 3900,
	})

	local c = "jarkati:core"
	local f = jarkati.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	jarkati.registered = true
end
