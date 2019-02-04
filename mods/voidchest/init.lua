
voidchest = voidchest or {}
voidchest.modpath = minetest.get_modpath("voidchest")

local function get_chest_formspec()
	-- Obtain hooks into the trash mod's trash slot inventory.
	local ltrash, mtrash = trash.get_listname()
	local itrash = trash.get_iconname()

  local formspec = "size[14,9]" ..
    default.gui_bg ..
    default.gui_bg_img ..
    default.gui_slots ..
    "list[current_player;voidchest:voidchest;0,0.3;14,4;]" ..
    "list[current_player;main;2,4.85;8,1;]" ..
    "list[current_player;main;2,6.08;8,3;8]" ..
    "listring[current_player;voidchest:voidchest]" ..
    "listring[current_player;main]" ..
    default.get_hotbar_bg(2, 4.85)

		-- Trash icon.
		.. "list[" .. ltrash .. ";" .. mtrash .. ";11,4.85;1,1;]" ..
		"image[11,4.85;1,1;" .. itrash .. "]"
  
  return formspec
end



local open_chests = {}

local function chest_lid_obstructed(pos)
  local above = {x=pos.x, y=pos.y+1, z=pos.z}
  local def = minetest.reg_ns_nodes[minetest.get_node(above).name]

	-- Unknown node obstructs.
	if not def then
		return true
	end
  
  -- Allow ladders, signs, wallmounted things and torches to not obstruct.
  if def.drawtype == "airlike" or
     def.drawtype == "signlike" or
     def.drawtype == "torchlike" or
     (def.drawtype == "nodebox" and def.paramtype2 == "wallmounted") then
    return false
  end
  
  return true
end

local function open_chest(pname, pos, node)
  ambiance.sound_play("default_chest_open", pos, 0.5, 10)
  
  if not chest_lid_obstructed(pos) then
    minetest.swap_node(pos, {
      name = "voidchest:voidchest_opened",
      param2 = node.param2,
    })
  end
  
  minetest.after(0.2, minetest.show_formspec,
    pname, "voidchest:chest", get_chest_formspec())
  
  open_chests[pname] = {pos=pos}
end

local function close_chest(pname, pos, node)
  open_chests[pname] = nil
  
  minetest.after(0.2, minetest.swap_node, pos, {
    name = "voidchest:voidchest_closed",
    param2 = node.param2
  })
  
  ambiance.sound_play("default_chest_close", pos, 0.5, 10)
end

-- Guard against players leaving the game while a chest is open.
minetest.register_on_leaveplayer(function(player, timeout)
  if not player or not player:is_player() then return end
  local pn = player:get_player_name()
  if open_chests[pn] then
    local pos = open_chests[pn].pos
    local node = minetest.get_node(pos)
    local sound = open_chests[pn].sound
    local swap = open_chests[pn].swap
    close_chest(pn, pos, node, swap, sound)
  end
end)



minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "voidchest:chest" then return end -- Wrong formspec.
  
  local pname = player:get_player_name()
  if not open_chests[pname] then return true end -- No opened chest.
  
  local pos = open_chests[pname].pos
  local node = minetest.get_node(pos)
  local nn = node.name
  
  if nn ~= "voidchest:voidchest_opened" then return true end -- Wrong node!
  
  if fields.quit then
    close_chest(pname, pos, node)
  end
  
  return true
end)



-- Definitions common to both open and closed variants on the starfissure chest.
local VOIDCHEST_DEF = {
  drawtype = "mesh",
  visual = "mesh",
  paramtype = "light",
  paramtype2 = "facedir",
  legacy_facedir_simple = true,
  is_ground_content = false,
  
  description = "Star-Fissure Chest\n\nHas a shared inventory with other Star-Fissure Chests.\nIs volatile when dug!",
  tiles = {"voidchest_voidchest.png"},
  
  drop = "starpearl:pearl 8",
  groups = {
    level = 3, cracky = 1,
    immovable = 1, -- No pistons, no nothing.
		chest = 1,
  },
  sounds = default.node_sound_stone_defaults(),
  
  -- After digging chest, sometimes, a nasty surprise.
  after_dig_node = function(pos, oldnode, oldmetadata, digger)
    minetest.sound_play("tnt_gunpowder_burning", {pos=pos, gain=2})
    if math.random(1, 10) == 1 then
      minetest.after(math.random(1, 5), function()
        tnt.boom(pos, {
          radius = 2,
          ignore_protection = false,
          ignore_on_blast = false,
          damage_radius = 3,
          disable_drops = true,
        })
      end)
    elseif math.random(1, 10) == 1 then
      minetest.set_node(pos, {name="fire:nether_flame"})
    end
  end,

  -- Setup initial metadata.
  after_place_node = function(pos, placer)
    local meta = minetest.get_meta(pos)
		local pname = placer:get_player_name()
		local dname = rename.gpn(pname)
    meta:set_string("owner", pname)
		meta:set_string("rename", dname)
    meta:set_string("infotext", "Star-Fissure Box (Owned by <" .. dname .. ">!)")
  end,
  
  -- Open chest formspec.
  on_rightclick = function(pos, node, clicker)
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner") or ""
    local pname = clicker:get_player_name()

    -- Only the owner may view the inventory.
    if owner == pname then
			-- Update infotext.
			local dname = rename.gpn(pname)
			meta:set_string("infotext", "Star-Fissure Box (Owned by <" .. dname .. ">!)")

      open_chest(pname, pos, node)
    end
  end,
  
  -- Handle explosions. The chest generates a secondary explosion.
  on_blast = function(pos)
    minetest.remove_node(pos)
    minetest.after(0.5, function()
      tnt.boom(pos, {
        radius = 2,
        ignore_protection = false,
        ignore_on_blast = false,
        damage_radius = 3,
        disable_drops = true,
      })
    end)
  end,

	-- Called by rename LBM.
	_on_rename_check = function(pos)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		-- Nobody placed this block.
		if owner == "" then
			return
		end
		local dname = rename.gpn(owner)

		meta:set_string("rename", dname)
		meta:set_string("infotext", "Star-Fissure Box (Owned by <" .. dname .. ">!)")
	end,
}

-- Split definitions.
local VOIDCHEST_CLOSED = table.copy(VOIDCHEST_DEF)
local VOIDCHEST_OPENED = table.copy(VOIDCHEST_DEF)

VOIDCHEST_OPENED.mesh = "chest_open.obj"
VOIDCHEST_CLOSED.mesh = "chest_close.obj"

-- Chest can't be dug while opened.
VOIDCHEST_OPENED.can_dig = function()
  return false
end

VOIDCHEST_OPENED.groups.not_in_creative_inventory = 1
VOIDCHEST_OPENED.selection_box = {
  type = "fixed",
  fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
}


minetest.register_node("voidchest:voidchest_closed", VOIDCHEST_CLOSED)
minetest.register_node("voidchest:voidchest_opened", VOIDCHEST_OPENED)

-- Compatibility.
minetest.register_alias("voidchest:voidchest", "voidchest:voidchest_closed")



minetest.register_craft({
  output = "voidchest:voidchest_closed",
  recipe = {
    {"starpearl:pearl", "starpearl:pearl",    "starpearl:pearl"},
    {"starpearl:pearl", "group:chest_closed", "starpearl:pearl"},
    {"starpearl:pearl", "starpearl:pearl",    "starpearl:pearl"},
  },
})



minetest.register_on_joinplayer(function(player)
  local inv = player:get_inventory()
  inv:set_size("voidchest:voidchest", 14*4)
end)

