
if not minetest.global_exists("bonemeal") then bonemeal = {} end
bonemeal.modpath = minetest.get_modpath("bonemeal")

-- Localize for performance.
local math_random = math.random



function bonemeal.do_dirtspread(pos)
	local above = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
	if above.name ~= "air" then
		return
	end
	local dirt = minetest.find_node_near(pos, 2, {
		"default:dirt_with_grass",
		"default:dirt_with_dry_grass",
		"moregrass:darkgrass",
	})
	if dirt then
		local node = minetest.get_node(dirt)
		minetest.add_node(pos, {name=node.name})
	end
end

function bonemeal.on_use(itemstack, user, pt)
	if not user or not user:is_player() then
		return
	end

	if pt.type == "node" then
		local pos = pt.under
		if minetest.is_protected(pos, user:get_player_name()) then
			return
		end

		local node = minetest.get_node(pos)
		local def = minetest.registered_items[node.name]

		local take = false

		if def then
			if def._farming_next_plant and def.on_timer then
				local timer = minetest.get_node_timer(pos)
				if timer:is_started() then
					local timeout = timer:get_timeout()
					local elapsed = timer:get_elapsed()
					local remain = (timeout - elapsed)
					if remain > 0 then
						-- Plant growtime is reduced by 2 thirds.
						local newtime = (remain / 3)
						timer:set(newtime, elapsed)
					end
				end
				take = true
			elseif def.groups and def.groups.flora and def.groups.flora > 0 then
				if math_random(1, 3) == 1 then
					flowers.flower_spread(pos, node)
				end
				take = true
			elseif node.name == "flowers:mushroom_brown" or
				node.name == "flowers:mushroom_red" or
				node.name == "cavestuff:mycena" or
				node.name == "cavestuff:fungus" then
				if math_random(1, 3) == 1 then
					flowers.mushroom_spread(pos, node)
				end
				take = true
			elseif node.name == "default:cactus" then
				if math_random(1, 3) == 1 then
					cactus.grow(pos, node)
				end
				take = true
			elseif node.name == "default:papyrus" then
				if math_random(1, 3) == 1 then
					papyrus.grow(pos, node)
				end
				take = true
			elseif node.name == "default:tvine" or 
					node.name == "default:tvine_alt" or
					node.name == "default:tvine_top" or
					node.name == "default:tvine_top_alt" then
				if math_random(1, 3) == 1 then
					tvine.grow(pos, node)
				end
				take = true
			elseif def.groups and def.groups.sapling and def.groups.sapling > 0 and def.on_timer then
				local timer = minetest.get_node_timer(pos)
				if timer:is_started() then
					local timeout = timer:get_timeout()
					local elapsed = timer:get_elapsed()
					local remain = (timeout - elapsed)
					if remain > 0 then
						local newtime = (remain / 3)*2
						timer:set(newtime, elapsed)
					end
				end
				take = true
			elseif node.name == "nethervine:vine" then
				if math_random(1, 3) == 1 then
					nethervine.grow(pos, node)
				end
				take = true
			elseif node.name == "default:dirt" then
				if math_random(1, 3) == 1 then
					bonemeal.do_dirtspread(pos)
				end
				take = true
			elseif node.name == "default:dirt_with_dry_grass" then
				if math_random(1, 2) == 1 then
					local above = {x=pos.x, y=pos.y+1, z=pos.z}
					local anode = minetest.get_node(above)
					if anode.name == "air" then
						if not minetest.is_protected(above, user:get_player_name()) then
							if math_random(1, 4) > 1 then
								minetest.add_node(above, {name="default:dry_grass_" .. math_random(1, 5),  param2=2})
							else
								local name = "default:dry_shrub"
								if math_random(1, 2) == 1 then
									name = "default:dry_shrub2"
								end
								minetest.add_node(above, {name=name})
							end
						end
					end
				end
				take = true
			elseif node.name == "default:dirt_with_grass" then
				if math_random(1, 2) == 1 then
					local above = {x=pos.x, y=pos.y+1, z=pos.z}
					local anode = minetest.get_node(above)
					if anode.name == "air" then
						if not minetest.is_protected(above, user:get_player_name()) then
							if math_random(1, 2) == 1 then
								minetest.add_node(above, {name="default:grass_" .. math_random(1, 5),  param2=2})
							else
								minetest.add_node(above, {name="default:coarsegrass",  param2=2})
							end
						end
					end
				end
				take = true
			elseif node.name == "moregrass:darkgrass" then
				if math_random(1, 2) == 1 then
					local above = {x=pos.x, y=pos.y+1, z=pos.z}
					local anode = minetest.get_node(above)
					if anode.name == "air" then
						if not minetest.is_protected(above, user:get_player_name()) then
							if math_random(1, 2) == 1 then
								minetest.add_node(above, {name="default:junglegrass", param2=2})
							else
								minetest.add_node(above, {name="default:coarsegrass",  param2=2})
							end
						end
					end
				end
				take = true
			elseif string.find(node.name, "^nether:grass_%d$") then
				if math_random(1, 2) == 1 then
					if not minetest.is_protected(pos, user:get_player_name()) then
						nethervine.flora_spread(pos, minetest.get_node(pos))
					end
				end
				take = true
			end
		end

		if take then
			itemstack:take_item()
		end
		return itemstack
	end
end



if not bonemeal.run_once then
	-- bone item
	minetest.register_craftitem("bonemeal:bone", {
		description = "Bone",
		inventory_image = "bone_bone.png",
	})

	minetest.register_craft({
		output = "bonemeal:bone 16",
		recipe = {
			{'bones:bones_type2', 'bones:bones_type2'},
			{'bones:bones_type2', 'bones:bones_type2'},
		},
	})

	minetest.register_craft({
		output = "bones:bones_type2",
		recipe = {
			{'bonemeal:bone', 'bonemeal:bone'},
			{'bonemeal:bone', 'bonemeal:bone'},
		},
	})

	-- bonemeal recipe
	minetest.register_craft({
		output = 'bonemeal:meal 3',
		recipe = {{'bonemeal:bone'}},
	})

	minetest.register_craft({
		type = "anvil",
		output = 'bonemeal:meal 5',
		recipe = 'bonemeal:bone',
	})

	minetest.register_craft({
		type = "grinding",
		output = 'bonemeal:meal 6',
		recipe = 'bonemeal:bone',
		time = 4,
	})

	-- bonemeal item
	minetest.register_craftitem("bonemeal:meal", {
		description = "Bone Meal",
		inventory_image = "bone_bonemeal.png",
		liquids_pointable = false,

		on_use = function(...)
			return bonemeal.on_use(...)
		end,
	})

	local c = "bonemeal:core"
	local f = bonemeal.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	bonemeal.run_once = true
end
