
-- File is reloadable.
local MIN_TIME = 1
local MAX_TIME = 5

dirtspread.register_active_block("default:dirt", {
	min_time = MIN_TIME,
	max_time = MAX_TIME,

	-- If function uses `minetest.add_node`, neighbor nodes will be notified again.
	-- This can create a cascade effect, which may or may not be desired.
	-- Return `true` to restart the timer and call this function again later (useful if you need to wait before changing the node).
	func = function(pos, node)
		--print("test1")
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
		local below = {x=pos.x, y=pos.y-1, z=pos.z}

		local light_above_daytime = minetest.get_node_light(above, 0.5) or 0 -- Light level in daytime.
		local light_above_alltime = minetest.get_node_light(above) or 0 -- Light level right now.

		-- If in complete darkness all the time, turn to sterile dirt. (Node must be underground.)
		if light_above_daytime == 0 then
			local n2_above = minetest.get_node(above)
			-- Special case. This block causes darkness, so must handle it.
			if n2_above.name == "default:snowblock" then
				node.name = "default:dirt_with_snow"
			else
				node.name = "darkage:darkdirt"
			end
			minetest.add_node(pos, node)
			return
		end
		
		--print("test2")
		-- Also turn to sterile dirt if lava is anywhere even slightly nearby.
		if minetest.find_node_near(pos, 3, "group:lava") then
			node.name = "darkage:darkdirt"
			minetest.add_node(pos, node)
			return
		end

		--print("test3")
		-- Dry dirt out if next to fire or sand.
		if minetest.find_node_near(pos, 1, {"group:fire", "group:sand"}) then
			node.name = "default:dry_dirt"
			minetest.add_node(pos, node)
			return
		end

		--print("test4")
		-- Get what's below us.
		local n2_below = minetest.get_node(below)
		local ndef_below = minetest.registered_nodes[n2_below.name]
		local gb = {} -- Groups below.
		if ndef_below then
			gb = ndef_below.groups or {}
		end

		--print("test5")
		-- Convert to permafrost if placed on top of ice or snow (but not cold).
		if (gb.snow and gb.snow > 0) or (gb.ice and gb.ice > 0) then
			node.name = "default:permafrost"
			minetest.add_node(pos, node)
			return
		end

		--print("test6")
		-- Get what's above us.
		local n2_above = minetest.get_node(above)
		local ndef_above = minetest.registered_nodes[n2_above.name]

		local ga = {} -- Groups above.
		local lqa = "none" -- Liquid-type above.
		local under_walkable = true -- Walkable above.
		if ndef_above then
			ga = ndef_above.groups or {}
			lqa = ndef_above.liquidtype or "none"
			under_walkable = ndef_above.walkable
		end

		--print("test7")
		-- If under liquid, do nothing further. (If this was lava, that was already handled above.)
		if lqa ~= "none" then
			return
		end

		--print("test8")
		-- Convert to permafrost if ice placed on top.
		if (ga.ice and ga.ice > 0) then
			node.name = "default:permafrost"
			minetest.add_node(pos, node)
			return
		elseif (ga.snow and ga.snow > 0) or (ga.snowy and ga.snowy > 0) then
			-- Convert to dirt_with_snow if snow on top.
			node.name = "default:dirt_with_snow"
			minetest.add_node(pos, node)
			return
		end

		--print("test9")
		-- Are we under air?
		local under_air = (n2_above.name == "air")

		-- Get what's to the 4 sides.
		local sides_4 = {
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z-1},
			{x=pos.x, y=pos.y, z=pos.z+1},
		}
		table.shuffle(sides_4)

		--print("test10")
		-- If snow nearby, convert to dirt with snow.
		-- Convert to permafrost instead, if next to ice.
		-- But node must be under air/non-walkable in this case.
		if under_air or not under_walkable then
			for k, v in ipairs(sides_4) do
				local n2_beside = minetest.get_node(v)
				local ndef = minetest.registered_nodes[n2_beside.name]

				local gs = {} -- Groups beside.
				if ndef then
					gs = ndef.groups or {}
				end

				if (gs.ice and gs.ice > 0) then
					node.name = "default:permafrost"
					minetest.add_node(pos, node)
					return
				elseif (gs.snow and gs.snow > 0) or (gs.snowy and gs.snowy > 0) then
					node.name = "default:dirt_with_snow"
					minetest.add_node(pos, node)
					return
				end
			end
		end

		--print("test11")
		-- If there's a plant above the dirt, convert to grassy dirt of some type.
		-- But in this case we only grow grass in daytime.
		if light_above_alltime >= 13 then
			if ga.junglegrass and ga.junglegrass > 0 then
				node.name = "moregrass:darkgrass"
				minetest.add_node(pos, node)
				return
			elseif ga.dry_grass and ga.dry_grass > 0 then
				node.name = "default:dirt_with_dry_grass"
				minetest.add_node(pos, node)
				return
			elseif ga.grass and ga.grass > 0 then
				node.name = "default:dirt_with_grass"
				minetest.add_node(pos, node)
				return
			end

			--print("test12")
			-- Convert dirt to grass if grassy dirt is nearby.
			-- (Only if dirt would not turn to permafrost.)
			-- But node must be under air/non-walkable in this case.
			if under_air or not under_walkable then
				for k, v in ipairs(sides_4) do
					local n2_beside = minetest.get_node(v)
					local ndef = minetest.registered_nodes[n2_beside.name]

					local gs = {} -- Groups beside.
					if ndef then
						gs = ndef.groups or {}
					end

					if (gs.grassy_dirt_type and gs.grassy_dirt_type > 0) then
						node.name = n2_beside.name
						-- Special case.
						if n2_beside.name == "default:dirt_with_grass_footsteps" then
							node.name = "default:dirt_with_grass"
						end
						minetest.add_node(pos, node)
						return
					-- If next to dry stuff, convert to more dry dirt.
					elseif (gs.dry_dirt_type and gs.dry_dirt_type > 0) then
						node.name = "default:dry_dirt"
						minetest.add_node(pos, node)
						return
					end
				end
			end
		else
			-- Node in darkness, cannot grow grass. Wait for day.
			return true
		end
	end,
})



for _, NODE_NAME in ipairs({
	"default:dirt_with_grass",
	"default:dirt_with_grass_footsteps",
	"moregrass:darkgrass",
	"default:dirt_with_dry_grass",
}) do
	dirtspread.register_active_block(NODE_NAME, {
		min_time = MIN_TIME,
		max_time = MAX_TIME,

		-- If function uses `minetest.add_node`, neighbor nodes will be notified again.
		-- This can create a cascade effect, which may or may not be desired.
		-- Return `true` to restart the timer and call this function again later (useful if you need to wait before changing the node).
		func = function(pos, node)
			--print("test1")
			local above = {x=pos.x, y=pos.y+1, z=pos.z}
			local below = {x=pos.x, y=pos.y-1, z=pos.z}

			local light_above_daytime = minetest.get_node_light(above, 0.5) or 0 -- Light level in daytime.
			local light_above_alltime = minetest.get_node_light(above) or 0 -- Light level right now.

			-- If in complete darkness all the time, turn to dirt. (Node must be underground.)
			if light_above_daytime == 0 then
				local n2_above = minetest.get_node(above)
				node.name = "default:dirt"
				minetest.add_node(pos, node)
				return
			end

			--print("test2")
			-- Also turn to dirt if lava is anywhere even slightly nearby.
			if minetest.find_node_near(pos, 3, "group:lava") then
				node.name = "default:dry_dirt_with_dry_grass"
				minetest.add_node(pos, node)
				return
			end

			--print("test3")
			-- Dry dirt out if next to fire or sand.
			if minetest.find_node_near(pos, 1, {"group:fire", "group:sand"}) then
				node.name = "default:dry_dirt_with_dry_grass"
				minetest.add_node(pos, node)
				return
			end

			--print("test4")
			-- Get what's below us.
			local n2_below = minetest.get_node(below)
			local ndef_below = minetest.registered_nodes[n2_below.name]
			local gb = {} -- Groups below.
			if ndef_below then
				gb = ndef_below.groups or {}
			end

			--print("test5")
			-- Convert to dirt if placed on top of ice or snow (but not cold).
			if (gb.snow and gb.snow > 0) or (gb.ice and gb.ice > 0) then
				node.name = "default:dirt"
				minetest.add_node(pos, node)
				return
			end

			--print("test6")
			-- Get what's above us.
			local n2_above = minetest.get_node(above)
			local ndef_above = minetest.registered_nodes[n2_above.name]

			local ga = {} -- Groups above.
			local lqa = "none" -- Liquid-type above.
			local under_walkable = true -- Walkable above.
			if ndef_above then
				ga = ndef_above.groups or {}
				lqa = ndef_above.liquidtype or "none"
				under_walkable = ndef_above.walkable
			end

			--print("test7")
			-- If under liquid, turn to dirt. (If this was lava, that was already handled above.)
			if lqa ~= "none" then
				node.name = "default:dirt"
				minetest.add_node(pos, node)
				return
			end

			--print("test8")
			-- Convert to dirt if ice placed on top.
			if (ga.ice and ga.ice > 0) then
				node.name = "default:dirt"
				minetest.add_node(pos, node)
				return
			elseif (ga.snow and ga.snow > 0) or (ga.snowy and ga.snowy > 0) then
				-- Convert to dirt if snow on top.
				node.name = "default:dirt"
				minetest.add_node(pos, node)
				return
			end

			--print("test9")
			-- Are we under air?
			local under_air = (n2_above.name == "air")

			-- Get what's to the 4 sides.
			local sides_4 = {
				{x=pos.x-1, y=pos.y, z=pos.z},
				{x=pos.x+1, y=pos.y, z=pos.z},
				{x=pos.x, y=pos.y, z=pos.z-1},
				{x=pos.x, y=pos.y, z=pos.z+1},
			}
			table.shuffle(sides_4)

			--print("test10")
			-- If snow/ice nearby, convert to dirt.
			-- But node must be under air/non-walkable in this case.
			if under_air or not under_walkable then
				for k, v in ipairs(sides_4) do
					local n2_beside = minetest.get_node(v)
					local ndef = minetest.registered_nodes[n2_beside.name]

					local gs = {} -- Groups beside.
					if ndef then
						gs = ndef.groups or {}
					end

					if (gs.ice and gs.ice > 0) then
						node.name = "default:dirt"
						minetest.add_node(pos, node)
						return
					elseif (gs.snow and gs.snow > 0) or (gs.snowy and gs.snowy > 0) then
						node.name = "default:dirt"
						minetest.add_node(pos, node)
						return
					end
				end
			end
		end,
	})
end



dirtspread.register_active_block("default:permafrost", {
	min_time = MIN_TIME,
	max_time = MAX_TIME,

	-- If function uses `minetest.add_node`, neighbor nodes will be notified again.
	-- This can create a cascade effect, which may or may not be desired.
	-- Return `true` to restart the timer and call this function again later (useful if you need to wait before changing the node).
	func = function(pos, node)
		--print("test1")
		local above = {x=pos.x, y=pos.y+1, z=pos.z}
		local below = {x=pos.x, y=pos.y-1, z=pos.z}

		local light_above_alltime = minetest.get_node_light(above) or 0 -- Light level right now.

		--print("test2")
		-- Also turn to gravel if lava is anywhere even slightly nearby.
		if minetest.find_node_near(pos, 3, "group:lava") then
			node.name = "default:gravel"
			minetest.add_node(pos, node)
			return
		end

		--print("test3")
		-- Dry permafrost to dry-dirt if next to fire.
		if minetest.find_node_near(pos, 1, {"group:fire"}) then
			node.name = "default:dirt"
			minetest.add_node(pos, node)
			return
		end

		--print("test6")
		-- Get what's above us.
		local n2_above = minetest.get_node(above)
		local ndef_above = minetest.registered_nodes[n2_above.name]

		local ga = {} -- Groups above.
		local lqa = "none" -- Liquid-type above.
		local under_walkable = true -- Walkable above.
		if ndef_above then
			ga = ndef_above.groups or {}
			lqa = ndef_above.liquidtype or "none"
			under_walkable = ndef_above.walkable
		end

		--print("test7")
		-- If under liquid, do nothing further. (If this was lava, that was already handled above.)
		if lqa ~= "none" then
			return
		end

		--print("test8")
		-- Convert to permafrost with stones if cobble placed on top.
		if (ga.cobble_type and ga.cobble_type > 0) then
			node.name = "default:permafrost_with_stones"
			minetest.add_node(pos, node)
			return
		-- Convert to permafrost with snow if snow is on top.
		elseif (ga.snow and ga.snow > 0) or (ga.snowy and ga.snowy > 0) then
			-- Convert to dirt if snow on top.
			node.name = "default:permafrost_with_snow"
			minetest.add_node(pos, node)
			return
		end

		--print("test9")
		-- Are we under air?
		local under_air = (n2_above.name == "air")

		-- Get what's to the 4 sides.
		local sides_4 = {
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z-1},
			{x=pos.x, y=pos.y, z=pos.z+1},
		}
		table.shuffle(sides_4)

		--print("test10")
		-- If snow/ice nearby, convert to permafrost with snow.
		-- But node must be under air/non-walkable in this case.
		if under_air or not under_walkable then
			for k, v in ipairs(sides_4) do
				local n2_beside = minetest.get_node(v)
				local ndef = minetest.registered_nodes[n2_beside.name]

				local gs = {} -- Groups beside.
				if ndef then
					gs = ndef.groups or {}
				end

				if (gs.ice and gs.ice > 0) then
					node.name = "default:permafrost_with_snow"
					minetest.add_node(pos, node)
					return
				elseif (gs.snow and gs.snow > 0) or (gs.snowy and gs.snowy > 0) then
					node.name = "default:permafrost_with_snow"
					minetest.add_node(pos, node)
					return
				end
			end
		end
	end,
})
