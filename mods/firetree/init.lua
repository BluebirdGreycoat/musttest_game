
if not minetest.global_exists("firetree") then firetree = {} end
firetree.modpath = minetest.get_modpath("firetree")
local SAPLING_TIME_MIN = 5*60
local SAPLING_TIME_MAX = 10*60

-- Localize for performance.
local math_random = math.random



local FIRETREE_SCHEMATICS = {
    "firetree_tree1.mts",
    "firetree_tree2.mts",
    "firetree_tree3.mts",
    "firetree_tree4.mts",
    "firetree_tree5.mts",
    "firetree_tree6.mts",
}
    


minetest.register_node("firetree:leaves", {
	description = "Firetree Leaves",
	drawtype = "allfaces_optional",
	waving = 1,

	tiles = {"firetree_leaves.png"},
	paramtype = "light",
	groups = utility.dig_groups("leaves", {
		leafdecay = 3,
		flammable = 2,
		leaves = 1,
	}),
  
	drop = {
		max_items = 1,
		items = {
			-- You sometimes get a real apple.
			{items = {'basictrees:tree_apple'}, rarity = 22},
			{items = {'firetree:sapling'}, rarity = 14},
			{items = {"default:stick"}, rarity = 6},

			-- Player will get leaves only if he gets nothing else; this is because 'max_items' is 1.
			{items = {'firetree:leaves'}},
		}
	},
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="firetree:trunk"}),
})



minetest.register_node("firetree:whitewood", {
	description = "Baked Firetree Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"firetree_whitewood.png"},
	groups = utility.dig_groups("wood", {flammable=2, wood=1, wood_light=1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("firetree:firewood", {
	description = "Raw Firetree Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"firetree_firewood.png"},
	groups = utility.dig_groups("wood", {flammable=2, wood=1, wood_dark=1}),
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_craft({
	type = "cooking",
	output = "firetree:whitewood",
	recipe = "firetree:firewood",
})



stairs.register_stair_and_slab(
	"firetree_whitewood",
	"firetree:whitewood",
	{choppy=2, oddly_breakable_by_hand=2, flammable=2},
	{"firetree_whitewood.png"},
	"Baked Firewood",
	default.node_sound_wood_defaults()
)



stairs.register_stair_and_slab(
	"firetree_firewood",
	"firetree:firewood",
	{choppy=2, oddly_breakable_by_hand=2, flammable=2},
	{"firetree_firewood.png"},
	"Raw Firewood",
	default.node_sound_wood_defaults()
)



minetest.register_craft({
    output = "firetree:firewood 4",
    type = "shapeless",
    recipe = {"firetree:trunk"},
})



minetest.register_node("firetree:fruit", {
	description = "Fruit of the Firetree\n\nProtects from extreme heat when consumed.",
	drawtype = "plantlike",

	tiles = {"firetree_fruit.png"},
	inventory_image = "firetree_fruit.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.2, -0.5, -0.2, 0.2, 0, 0.2}
	},
	groups = utility.dig_groups("item", {flammable=2, leafdecay=3, leafdecay_drop=1, foodrot=1}),
	sounds = default.node_sound_leaves_defaults(),
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,

  on_use = function(itemstack, user, pointed_thing)
    if user and user:is_player() then
      local name = user:get_player_name()
      if heatdamage then
        heatdamage.immunize_player(name, 10)
        --minetest.sound_play("hunger_eat", {to_player = name, gain = 0.7})
        ambiance.sound_play("hunger_eat", user:get_pos(), 0.7, 10)
        itemstack:take_item()
        return itemstack
      end
    end
  end,
  
  on_construct = enhanced_leafdecay.make_leaf_constructor({}),
  on_timer = enhanced_leafdecay.make_leaf_nodetimer({tree="firetree:trunk"}),

	after_dig_node = hb4.fruitregrow.after_dig_node(),
	after_place_node = hb4.fruitregrow.after_place_node(),
	on_finish_collapse = hb4.fruitregrow.on_finish_collapse(),
})



local can_grow = function(pos)
	-- Firetree does not grow in other dimensions.
	local crealm = rc.current_realm_at_pos(pos)
	if not (crealm == "overworld" or crealm == "naraxen") then
		return false
	end

	-- Reduced chance to grow if cold/ice nearby.
	local below = {x=pos.x, y=pos.y-1, z=pos.z}
	local cold = minetest.find_nodes_in_area(vector.subtract(below, 3), vector.add(below, 3), "group:cold")
	if #cold > math_random(0, 196) then
		return false
	end

	local node_under = minetest.get_node_or_nil(below)
	if not node_under then
		return false
	end
	local name_under = node_under.name
	local is_soil = minetest.get_item_group(name_under, "nether_soil")
	if is_soil == 0 then
		return false
	end
	local light_level = minetest.get_node_light(pos)
	if not light_level or light_level < 11 then
		return false
	end
	return true
end



local on_place = function(itemstack, placer, pointed_thing)
    local n = "firetree:sapling"
    local minp = {x=-3, y=0, z=-3}
    local maxp = {x=3, y=5, z=3}
    itemstack = default.sapling_on_place(itemstack, placer, pointed_thing, n, minp, maxp, 4)
    return itemstack
end



local on_construct = function(pos)
    minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
end



local on_timer = function(pos, elapsed)
				if mtflower.can_grow(pos) then
					if mtflower.try_grow(pos, "firetree:trunk", "firetree:leaves", "glowstone:minerals", "glowstone:minerals") then
						return
					end
				end

    if not can_grow(pos) then
        minetest.get_node_timer(pos):start(math_random(SAPLING_TIME_MIN, SAPLING_TIME_MAX))
        return
    end

    minetest.set_node(pos, {name='air'}) -- Remove sapling first.
    local schempath = firetree.modpath .. "/schematics/"
    local path = schempath .. FIRETREE_SCHEMATICS[math_random(#FIRETREE_SCHEMATICS)]
    minetest.place_schematic(vector.add(pos, {x=-2, y=0, z=-2}), path, "random", nil, false)
end



firetree.create_firetree_on_vmanip = function(vm, pos)
    local schempath = firetree.modpath .. "/schematics/"
    local path = schempath .. FIRETREE_SCHEMATICS[math_random(#FIRETREE_SCHEMATICS)]
    minetest.place_schematic_on_vmanip(vm, vector.add(pos, {x=-2, y=0, z=-2}), path, "random", nil, false)
end



firetree.create_firetree = function(pos)
    local schempath = firetree.modpath .. "/schematics/"
    local path = schempath .. FIRETREE_SCHEMATICS[math_random(#FIRETREE_SCHEMATICS)]
    minetest.place_schematic(vector.add(pos, {x=-2, y=0, z=-2}), path, "0", nil, false)
end



minetest.register_node("firetree:sapling", {
	description = "Firetree Seedling\n\nMay grow in deep or hot places.\nWill also grow on the surface.\nGrows firefruit.",
	drawtype = "plantlike",

	tiles = {"firetree_sapling.png"},
	inventory_image = "firetree_sapling.png",
	wield_image = "firetree_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = utility.dig_groups("plant", {flammable=2, attached_node=1, sapling=1}),
	sounds = default.node_sound_leaves_defaults(),
    on_timer = on_timer,
    on_place = on_place,
    on_construct = on_construct,
	movement_speed_multiplier = default.SLOW_SPEED_PLANTS,
})



minetest.register_node("firetree:trunk", {
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = basictrees.trunk_nodebox,
	},

    description = "Firetree",
	tiles = {"firetree_trunktop.png", "firetree_trunktop.png", "firetree_trunkside.png"},
	paramtype2 = "facedir",
	groups = utility.dig_groups("tree", {tree=1, flammable=2}),
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
	movement_speed_multiplier = default.NORM_SPEED,
  
  on_destruct = enhanced_leafdecay.make_tree_destructor({
    leaves = {
      "firetree:leaves", 
      "firetree:fruit",
      "group:dry_leaves",
    },
  }),
})



minetest.register_alias("nethertree:tree",      "firetree:trunk")
minetest.register_alias("nethertree:leaves",    "firetree:leaves")
minetest.register_alias("nethertree:sapling",   "firetree:sapling")
minetest.register_alias("nethertree:firewood",  "firetree:firewood")
minetest.register_alias("nethertree:wood",      "firetree:whitewood")
minetest.register_alias("nethertree:fruit",     "firetree:fruit")
