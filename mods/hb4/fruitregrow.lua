
hb4 = hb4 or {}
hb4.fruitregrow = hb4.fruitregrow or {}



function hb4.fruitregrow.on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
	if node.name == meta:get_string("leafname") then
		local fruit = meta:get_string("fruitname")
		if fruit ~= "" and minetest.reg_ns_nodes[fruit] then
			-- param2 is 0, so fruit can regrow if picked again.
			minetest.add_node(pos, {name=fruit})
			return
		end
	end
	-- Else just remove the dummy node.
	minetest.remove_node(pos)
end



function hb4.fruitregrow.after_place_node_impl(pos, placer, itemstack, pointed_thing)
	local node = minetest.get_node(pos)
	-- Fruit placed by players does not regrow if picked.
	node.param2 = 1
	minetest.swap_node(pos, node)
end

function hb4.fruitregrow.after_place_node()
	return function(...)
		return hb4.fruitregrow.after_place_node_impl(...)
	end
end



-- We must set param2 on fallen fruit nodes, otherwise they
-- will reproduce infinitely!
function hb4.fruitregrow.on_finish_collapse_impl(pos, node)
	node.param2 = 1
	minetest.swap_node(pos, node)
end

function hb4.fruitregrow.on_finish_collapse()
	return function(...)
		return hb4.fruitregrow.on_finish_collapse_impl(...)
	end
end



function hb4.fruitregrow.after_dig_node_impl(pos, oldnode, oldmetadata, digger)
	-- Only for fruit placed by the mapgen/voxelmanip/schems.
	if oldnode.param2 == 0 then
		local node = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z})
		minetest.add_node(pos, {name="hb4:fruitregrow"})
		local meta = minetest.get_meta(pos)
		meta:set_string("fruitname", oldnode.name)
		meta:set_string("leafname", node.name)
		local timer = minetest.get_node_timer(pos)
		timer:start(math.random(60*20, 60*120))
	end
end

function hb4.fruitregrow.after_dig_node()
	return function(...)
		return hb4.fruitregrow.after_dig_node_impl(...)
	end
end



if not hb4.fruitregrow.registered then
	minetest.register_node("hb4:fruitregrow", {
		drawtype = "airlike",
		description = "Fruit Spawner (Please Report to Admin)",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		groups = {immovable = 1},
		climbable = false,
		buildable_to = true,
		floodable = true,
		drop = "",

		on_timer = function(...)
			return hb4.fruitregrow.on_timer(...)
		end,

		on_finish_collapse = function(pos, node)
			minetest.remove_node(pos)
		end,

		on_collapse_to_entity = function(pos, node)
    	-- Do nothing.
  	end,
	})

	minetest.register_node(":basictrees:tree_apple", {
		description = "Apple",
		drawtype = "plantlike",
		--visual_scale = 1.0,
		tiles = {"default_apple.png"},
		inventory_image = "default_apple.png",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {-0.2, -0.5, -0.2, 0.2, 0, 0.2}
		},
		-- Apples do not rot.
		groups = {fleshy=3, dig_immediate=3, flammable=2, leafdecay=3, leafdecay_drop=1},
		on_use = minetest.item_eat(2),
		sounds = default.node_sound_leaves_defaults(),

		on_construct = enhanced_leafdecay.make_leaf_constructor({}),
		on_timer = enhanced_leafdecay.make_leaf_nodetimer({}),

		after_dig_node = hb4.fruitregrow.after_dig_node(),
		after_place_node = hb4.fruitregrow.after_place_node(),
		on_finish_collapse = hb4.fruitregrow.on_finish_collapse(),
	})

	hb4.fruitregrow.registered = true
end
