--[[
More Blocks: circular saw

Copyright (c) 2011-2015 Calinou and contributors.
Licensed under the zlib license. See LICENSE.md for more information.
--]]

local S = function(str) return str end

circular_saw = circular_saw or {}

-- This is populated by stairsplus:register_all:
circular_saw.known_nodes = circular_saw.known_nodes or {}

-- How many microblocks does this shape at the output inventory cost:
-- It may cause slight loss, but no gain.
circular_saw.cost_in_microblocks = {
  1, 1, 1, 1, 1, 1, 1, 2,
	2, 2, 3, 2, 4, 2, 4, 4,
	5, 6, 7, 1, 1, 2, 4, 6,
	7, 8, 3, 3, 1, 1, 2, 4,
	4, 2, 6, 7, 3, 7, 7, 4,
	8, 3, 2, 6, 2, 1, 3, 4,

	-- Cost for extra custom slopes/microblocks. In same order as custom blocks in the `names' list.
	2, 6, 4, 4, 1,

	-- New slabs,
	1, 2, 2, 3, 3, 1, 3,
}

circular_saw.names = {
  {"micro", "_1"},
  {"panel", "_1"},
  {"micro", "_2"},
  {"panel", "_2"},
  {"micro", "_4"},
  {"panel", "_4"},
  {"micro", ""},
  {"panel", ""},

  {"micro", "_12"},
  {"panel", "_12"},
  {"micro", "_14"},
  {"panel", "_14"},
  {"micro", "_15"},
  {"panel", "_15"},

	-- These 2 are custom.
  {"micro", "_16"},
  {"panel", "_16"},

  {"stair", "_outer"},
  {"stair", ""},
  {"stair", "_inner"},
  {"slab", "_1"},
  {"slab", "_2"},
  {"slab", "_quarter"},
  {"slab", ""},
  {"slab", "_three_quarter"},
  {"slab", "_14"},
  {"slab", "_15"},

  {"stair", "_half"},
  {"stair", "_right_half"}, -- Not included in vanila moreblocks? Must be custom.
  {"stair", "_alt_1"},
  {"stair", "_alt_2"},
  {"stair", "_alt_4"},
  {"stair", "_alt"},

  {"slope", ""},
  {"slope", "_half"},
  {"slope", "_half_raised"},
  {"slope", "_inner"},
  {"slope", "_inner_half"},
  {"slope", "_inner_half_raised"},
  {"slope", "_inner_cut"},
  {"slope", "_inner_cut_half"},
  {"slope", "_inner_cut_half_raised"},

  {"slope", "_outer"},
  {"slope", "_outer_half"},
  {"slope", "_outer_half_raised"},
  {"slope", "_outer_cut"},
  {"slope", "_outer_cut_half"},
  {"slope", "_outer_cut_half_raised"},

  {"slope", "_cut"},

	-- Extra slopes, custom.
	{"slope", "_xslope_quarter"},
	{"slope", "_xslope_three_quarter"},
	{"slope", "_xslope_three_quarter_half"},
	{"slope", "_xslope_cut"},
	{"slope", "_xslope_slope"},

	-- New slabs from latest moreblocks mod.
	{"slab", "_two_sides"},
	{"slab", "_three_sides"},
	{"slab", "_three_sides_u"},

	-- Custom.
	{"slab", "_four_sides"},
	{"slab", "_hole"},
	{"slab", "_two_opposite"},
}

function circular_saw:get_cost(inv, stackname)
  for i, item in pairs(inv:get_list("output")) do
    if item:get_name() == stackname then
      return circular_saw.cost_in_microblocks[i]
    end
  end
end

function circular_saw:get_output_inv(modname, material, amount, max)
  if (not max or max < 1 or max > 64) then max = 64 end

  local list = {}
  local pos = #list

  -- If there is nothing inside, display empty inventory:
  if amount < 1 then
    return list
  end

  for i = 1, #circular_saw.names do
    local t = circular_saw.names[i]
    local cost = circular_saw.cost_in_microblocks[i]
    local balance = math.min(math.floor(amount/cost), max)
    local nodename = modname .. ":" .. t[1] .. "_" .. material .. t[2]
    if  minetest.registered_nodes[nodename] then
      pos = pos + 1
      list[pos] = nodename .. " " .. balance
    end
  end
  return list
end


-- Reset empty circular_saw after last full block has been taken out
-- (or the circular_saw has been placed the first time)
-- Note: max_offered is not reset:
function circular_saw:reset(pos)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
	local owner = meta:get_string("owner")
	local dname = rename.gpn(owner)

  inv:set_list("input",  {})
  inv:set_list("micro",  {})
  inv:set_list("output", {})
  meta:set_int("anz", 0)

  meta:set_string("infotext",
      S("Circular Saw is Empty (Owned by <%s>!)")
      :format(dname))
end


-- Player has taken something out of the box or placed something inside
-- that amounts to count microblocks:
function circular_saw:update_inventory(pos, amount)
  local meta          = minetest.get_meta(pos)
  local inv           = meta:get_inventory()

  amount = meta:get_int("anz") + amount

  -- The material is recycled automaticly.
  inv:set_list("recycle",  {})

  if amount < 1 then -- If the last block is taken out.
    self:reset(pos)
    return
  end

  local stack = inv:get_stack("input",  1)
  -- At least one "normal" block is necessary to see what kind of stairs are requested.
  if stack:is_empty() then
    -- Any microblocks not taken out yet are now lost.
    -- (covers material loss in the machine)
    self:reset(pos)
    return

  end
  local node_name = stack:get_name() or ""
  local name_parts = circular_saw.known_nodes[node_name] or ""
  local modname  = name_parts[1] or ""
  local material = name_parts[2] or ""

  inv:set_list("input", { -- Display as many full blocks as possible:
    node_name.. " " .. math.floor(amount / 8)
  })

  -- The stairnodes made of default nodes use moreblocks namespace, other mods keep own:
  if modname == "default" then
    modname = "circular_saw"
  end
  -- print("circular_saw set to " .. modname .. " : "
  --	.. material .. " with " .. (amount) .. " microblocks.")

  -- 0-7 microblocks may remain left-over:
  inv:set_list("micro", {
    modname .. ":micro_" .. material .. "_bottom " .. (amount % 8)
  })
  -- Display:
  inv:set_list("output",
		self:get_output_inv(modname, material, amount,
				meta:get_int("max_offered")))
  -- Store how many microblocks are available:
  meta:set_int("anz", amount)

	local material_desc = node_name
	local def = minetest.registered_items[node_name]
	if def and def.description then
		material_desc = def.description
	end

	local owner = meta:get_string("owner")
	local dname = rename.gpn(owner)
  meta:set_string("infotext",
      S("Circular Saw is Working on \"%s\" (Owned by <%s>!)")
      :format(material_desc, dname))
end


-- The amount of items offered per shape can be configured:
function circular_saw.on_receive_fields(pos, formname, fields, sender)
  local meta = minetest.get_meta(pos)
  local max = tonumber(fields.max_offered)
  if max and max > 0 then
    meta:set_string("max_offered",  max)
    -- Update to show the correct number of items:
    circular_saw:update_inventory(pos, 0)
  end
end



local function has_saw_privilege(meta, player)
  if not meta then return false end
  if not player then return false end
  
  if minetest.check_player_privs(player, "protection_bypass") then
    return true
  end

  local owner = (meta:get_string("owner") or "")
  if player:get_player_name() == owner then
    return true
  end
    
  return false
end


-- Moving the inventory of the circular_saw around is not allowed because it
-- is a fictional inventory. Moving inventory around would be rather
-- impractical and make things more difficult to calculate:
function circular_saw.allow_metadata_inventory_move(
    pos, from_list, from_index, to_list, to_index, count, player)
  return 0
end


-- Only input- and recycle-slot are intended as input slots:
function circular_saw.allow_metadata_inventory_put(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)
  if not has_saw_privilege(meta, player) then return 0 end
  
  if listname == "fuel" then
    if stack:get_name() == "default:mese_crystal_fragment" then
      return stack:get_count()
    else
      return 0
    end
  end
  
  -- The player is not allowed to put something in there:
  if listname == "output" or listname == "micro" then
    return 0
  end

  local inv  = meta:get_inventory()
  local stackname = stack:get_name()
  local count = stack:get_count()

  -- Only alow those items that are offered in the output inventory to be recycled:
  if listname == "recycle" then
    if not inv:contains_item("output", stackname) then
      return 0
    end
    local stackmax = stack:get_stack_max()
    local instack = inv:get_stack("input", 1)
    local microstack = inv:get_stack("micro", 1)
    local incount = instack:get_count()
    local incost = (incount * 8) + microstack:get_count()
    local maxcost = (stackmax * 8) + 7
    local cost = circular_saw:get_cost(inv, stackname)
    if (incost + cost) > maxcost then
      return math.max((maxcost - incost) / cost, 0)
    end
    return count
  end

  -- Only accept certain blocks as input which are known to be craftable into stairs:
  if listname == "input" then
    if not inv:is_empty("input") then
      if inv:get_stack("input", index):get_name() ~= stackname then
        return 0
      end
    end
    if not inv:is_empty("micro") then
      local microstackname = inv:get_stack("micro", 1):get_name():gsub("^.+:micro_", "", 1)
      local cutstackname = stackname:gsub("^.+:", "", 1)
      if microstackname ~= cutstackname then
        return 0
      end
    end
    for name, t in pairs(circular_saw.known_nodes) do
      if name == stackname and inv:room_for_item("input", stack) then
        return count
      end
    end
    return 0
  end
end

-- Taking is allowed from all slots (even the internal microblock slot).
-- Putting something in is slightly more complicated than taking anything
-- because we have to make sure it is of a suitable material:
function circular_saw.on_metadata_inventory_put(
    pos, listname, index, stack, player)
  -- We need to find out if the circular_saw is already set to a
  -- specific material or not:
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  local stackname = stack:get_name()
  local count = stack:get_count()

  -- Putting something into the input slot is only possible if that had
  -- been empty before or did contain something of the same material:
  if listname == "input" then
    -- Each new block is worth 8 microblocks:
    circular_saw:update_inventory(pos, 8 * count)
  elseif listname == "recycle" then
    -- Lets look which shape this represents:
    local cost = circular_saw:get_cost(inv, stackname)
    local input_stack = inv:get_stack("input", 1)
    -- check if this would not exceed input itemstack max_stacks
    if input_stack:get_count() + ((cost * count) / 8) <= input_stack:get_stack_max() then
      circular_saw:update_inventory(pos, cost * count)
    end
  end
end

local mese_to_cut_ratio = 10

function circular_saw.allow_metadata_inventory_take(pos, listname, index, stack, player)
  local meta = minetest.get_meta(pos)
  if not has_saw_privilege(meta, player) then return 0 end
  
  if listname == "output" then
    local inv = meta:get_inventory()
    if inv:is_empty("fuel") then
      minetest.chat_send_player(player:get_player_name(), "# Server: No power to saw!")
			easyvend.sound_error(player:get_player_name())
      return 0
    else
      local count = math.ceil(stack:get_count() / mese_to_cut_ratio)
      if count < 1 then count = 1 end
      local fuel = inv:get_stack("fuel", 1)
      if fuel:get_count() < count then
        minetest.chat_send_player(player:get_player_name(), "# Server: Not enough energy!")
				easyvend.sound_error(player:get_player_name())
        return 0
      end
    end
  end
  return stack:get_count()
end

function circular_saw.on_metadata_inventory_take(
    pos, listname, index, stack, player)

  -- Prevent (inbuilt) swapping between inventories with different blocks
  -- corrupting player inventory or Saw with 'unknown' items.
  local meta          = minetest.get_meta(pos)
  local inv           = meta:get_inventory()
  local input_stack = inv:get_stack(listname,  index)
  if not input_stack:is_empty() and input_stack:get_name()~=stack:get_name() then
    local player_inv = player:get_inventory()
    if player_inv:room_for_item("main", input_stack) then
      player_inv:add_item("main", input_stack)
    end

    circular_saw:reset(pos)
    return
  end
  
  -- If it is one of the offered stairs: find out how many
  -- microblocks have to be substracted:
  if listname == "output" then
    local fuel = math.ceil(stack:get_count() / mese_to_cut_ratio)
    if fuel < 1 then fuel = 1 end
    inv:remove_item("fuel", ItemStack("default:mese_crystal_fragment " .. fuel))
    
    -- We do know how much each block at each position costs:
    local cost = circular_saw.cost_in_microblocks[index]
        * stack:get_count()

    circular_saw:update_inventory(pos, -cost)
  elseif listname == "micro" then
    -- Each microblock costs 1 microblock:
    circular_saw:update_inventory(pos, -stack:get_count())
  elseif listname == "input" then
    -- Each normal (= full) block taken costs 8 microblocks:
    circular_saw:update_inventory(pos, 8 * -stack:get_count())
  end
  -- The recycle field plays no role here since it is processed immediately.
end

function circular_saw.on_construct(pos)
  local meta = minetest.get_meta(pos)
  local fancy_inv = default.gui_bg..default.gui_bg_img..default.gui_slots

	-- Modify formspec size and inventory size in order to make room for more blocks.
  meta:set_string("formspec", "size[15,10]"..fancy_inv..
      "label[0,0;" ..S("Input\nMaterial").. "]" ..
      "list[context;input;1.5,0;1,1;]" ..
      "label[0,1;" ..S("Left-Over").. "]" ..
      "list[context;micro;1.5,1;1,1;]" ..
      "label[0,2;" ..S("Recycle\nOutput").. "]" ..
      "list[context;recycle;1.5,2;1,1;]" ..
      "field[0.3,4.0;1,1;max_offered;" ..S("Max").. ":;${max_offered}]" ..
      "button[1,3.7;1,1;Set;" ..S("Set").. "]" ..
      "list[context;output;2.8,0;12,6;]" ..
      "list[current_player;main;2.8,6.25;8,4;]" ..
      "label[0,5;Mese Fuel\nStorage]" ..
      "list[context;fuel;1.5,5;1,1;]"
  )

  meta:set_int("anz", 0) -- No microblocks inside yet.
  meta:set_string("max_offered", 64) -- How many items of this kind are offered by default?
  meta:set_string("infotext", S("Circular Saw is Empty"))

  local inv = meta:get_inventory()
  inv:set_size("input", 1)    -- Input slot for full blocks of material x.
  inv:set_size("micro", 1)    -- Storage for 1-7 surplus microblocks.
  inv:set_size("recycle", 1)  -- Surplus partial blocks can be placed here.
  inv:set_size("output", 6*12) -- 6x11 versions of stair-parts of material x.
  inv:set_size("fuel", 1)

  circular_saw:reset(pos)
end


function circular_saw.can_dig(pos,player)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  if not inv:is_empty("input") or
    not inv:is_empty("micro") or
    not inv:is_empty("recycle") or
    not inv:is_empty("fuel") then
    return false
  end
  -- Can be dug by anyone when empty, not only by the owner:
  return true
end

minetest.register_node("circular_saw:circular_saw",  {
  description = "Circular Saw\n\nRequires mese fragments to power the cutting blade.\nDo not allow children to use.",
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-0.4, -0.5, -0.4, -0.25, 0.25, -0.25}, -- Leg
      {0.25, -0.5, 0.25, 0.4, 0.25, 0.4}, -- Leg
      {-0.4, -0.5, 0.25, -0.25, 0.25, 0.4}, -- Leg
      {0.25, -0.5, -0.4, 0.4, 0.25, -0.25}, -- Leg
      {-0.5, 0.25, -0.5, 0.5, 0.375, 0.5}, -- Tabletop
      {-0.01, 0.4375, -0.125, 0.01, 0.5, 0.125}, -- Saw blade (top)
      {-0.01, 0.375, -0.1875, 0.01, 0.4375, 0.1875}, -- Saw blade (bottom)
      {-0.25, -0.0625, -0.25, 0.25, 0.25, 0.25}, -- Motor case
    },
  },
  tiles = {
    "moreblocks_circular_saw_top.png",
    "moreblocks_circular_saw_bottom.png",
    "moreblocks_circular_saw_side.png"
  },
  paramtype = "light",
  sunlight_propagates = true,
  paramtype2 = "facedir",

	on_rotate = function(...)
		return screwdriver.rotate_simple(...)
	end,

  groups = {
    level = 1, choppy = 3, oddly_breakable_by_hand = 1,
    immovable = 1,
  },
  sounds = default.node_sound_wood_defaults(),
  on_construct = circular_saw.on_construct,
  can_dig = circular_saw.can_dig,

  -- Set the owner of this circular saw.
  after_place_node = function(pos, placer)
    local meta = minetest.get_meta(pos)
    local owner = placer and placer:get_player_name() or ""
		local dname = rename.gpn(owner)
    meta:set_string("owner",  owner)
		meta:set_string("rename", dname)
    meta:set_string("infotext",
        S("Circular Saw is Empty (Owned by <%s>!)")
        :format(dname))
  end,

  -- The amount of items offered per shape can be configured:
  on_receive_fields = circular_saw.on_receive_fields,
  allow_metadata_inventory_move = circular_saw.allow_metadata_inventory_move,
  -- Only input- and recycle-slot are intended as input slots:
  allow_metadata_inventory_put = circular_saw.allow_metadata_inventory_put,
  allow_metadata_inventory_take = circular_saw.allow_metadata_inventory_take,
  -- Taking is allowed from all slots (even the internal microblock slot). Moving is forbidden.
  -- Putting something in is slightly more complicated than taking anything because we have to make sure it is of a suitable material:
  on_metadata_inventory_put = circular_saw.on_metadata_inventory_put,
  on_metadata_inventory_take = circular_saw.on_metadata_inventory_take,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local cname = meta:get_string("rename")
		local dname = rename.gpn(owner)
		-- Check if the owner's current alias has changed.
		if cname ~= dname then
			meta:set_string("rename", dname)

			-- Update circular saw.
			circular_saw:update_inventory(pos, 0)
		end
	end,
})


minetest.register_craft({
  output = "circular_saw:circular_saw",
  recipe = {
    {'', 'gem_cutter:blade', ''},
    {'group:wood', 'group:wood', 'group:wood'},
    {'cast_iron:ingot', 'techcrafts:electric_motor', 'cast_iron:ingot'},
  }
})
