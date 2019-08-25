-- our API object
doors = {}

-- private data
local _doors = {}
_doors.registered_doors = {}
_doors.registered_trapdoors = {}

-- returns an object to a door object or nil
function doors.get(pos)
	local node_name = minetest.get_node(pos).name
	if _doors.registered_doors[node_name] then
		-- A normal upright door
		return {
			pos = pos,
			open = function(self, player)
				if self:state() then
					return false
				end
				return _doors.door_toggle(self.pos, nil, player)
			end,
			close = function(self, player)
				if not self:state() then
					return false
				end
				return _doors.door_toggle(self.pos, nil, player)
			end,
			toggle = function(self, player)
				return _doors.door_toggle(self.pos, nil, player)
			end,
			state = function(self)
				local state = minetest.get_meta(self.pos):get_int("state")
				return state %2 == 1
			end
		}
	elseif _doors.registered_trapdoors[node_name] then
		-- A trapdoor
		return {
			pos = pos,
			open = function(self, player)
				if self:state() then
					return false
				end
				return _doors.trapdoor_toggle(self.pos, nil, player)
			end,
			close = function(self, player)
				if not self:state() then
					return false
				end
				return _doors.trapdoor_toggle(self.pos, nil, player)
			end,
			toggle = function(self, player)
				return _doors.trapdoor_toggle(self.pos, nil, player)
			end,
			state = function(self)
				return minetest.get_node(self.pos).name:sub(-5) == "_open"
			end
		}
	else
		return nil
	end
end

-- this hidden node is placed on top of the bottom, and prevents
-- nodes from being placed in the top half of the door.
minetest.register_node("doors:hidden", {
	description = "Hidden Door Segment",
	-- can't use airlike otherwise falling nodes will turn to entities
	-- and will be forever stuck until door is removed.
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	-- has to be walkable for falling nodes to stop falling.
	walkable = true,
	pointable = false,
	diggable = false,
	buildable_to = false,
	floodable = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	on_blast = function() end,
	tiles = {"doors_blank.png"},
	-- 1px transparent block inside door hinge near node top.
	nodebox = {
		type = "fixed",
		fixed = {-15/32, 13/32, -15/32, -13/32, 1/2, -13/32},
	},
	-- collision_box needed otherise selection box would be full node size
	collision_box = {
		type = "fixed",
		fixed = {-15/32, 13/32, -15/32, -13/32, 1/2, -13/32},
	},
})

-- table used to aid door opening/closing
local transform = {
	{
		{v = "_a", param2 = 3},
		{v = "_a", param2 = 0},
		{v = "_a", param2 = 1},
		{v = "_a", param2 = 2},
	},
	{
		{v = "_b", param2 = 1},
		{v = "_b", param2 = 2},
		{v = "_b", param2 = 3},
		{v = "_b", param2 = 0},
	},
	{
		{v = "_b", param2 = 1},
		{v = "_b", param2 = 2},
		{v = "_b", param2 = 3},
		{v = "_b", param2 = 0},
	},
	{
		{v = "_a", param2 = 3},
		{v = "_a", param2 = 0},
		{v = "_a", param2 = 1},
		{v = "_a", param2 = 2},
	},
}

-- Force door at position to toggle, produce no sound, no ownership checks.
-- Function cannot/must not fail.
function _doors.door_toggle_force(pos, node)
	local meta = minetest.get_meta(pos)
	node = node or minetest.get_node(pos)
	local def = minetest.reg_ns_nodes[node.name]
	local name = def.door.name

	local state = meta:get_string("state")
	if state == "" then
		-- fix up lvm-placed right-hinged doors, default closed
		if node.name:sub(-2) == "_b" then
			state = 2
		else
			state = 0
		end
	else
		state = tonumber(state)
	end

	-- until Lua-5.2 we have no bitwise operators :(
	if state % 2 == 1 then
		state = state - 1
	else
		state = state + 1
	end

	local dir = node.param2

	minetest.swap_node(pos, {
		name = name .. transform[state + 1][dir+1].v,
		param2 = transform[state + 1][dir+1].param2
	})
	meta:set_int("state", state)
end

function _doors.have_matching_door(pos, node)
	local nn = minetest.get_node(pos)
	if nn.name == node.name and nn.param2 == node.param2 then
		return true
	end
end



-- The OFFICIAL door toggle function.
function _doors.door_toggle(pos, node, clicker)
	local meta = minetest.get_meta(pos)
	node = node or minetest.get_node(pos)
	local def = minetest.reg_ns_nodes[node.name]
	local name = def.door.name

	local state = meta:get_string("state")
	if state == "" then
		-- fix up lvm-placed right-hinged doors, default closed
		if node.name:sub(-2) == "_b" then
			state = 2
		else
			state = 0
		end
	else
		state = tonumber(state)
	end

  if clicker and not minetest.check_player_privs(clicker, "protection_bypass") then
    -- is player wielding the right key?
    local item = clicker:get_wielded_item()
    local owner = meta:get_string("doors_owner")
    if item:get_name() == "key:key" or item:get_name() == "key:chain" then
      local key_meta = item:get_meta()
      local secret = meta:get_string("key_lock_secret")

      if key_meta:get_string("secret") == "" then
        local key_oldmeta = item:get_metadata()
        if key_oldmeta == "" or not minetest.parse_json(key_oldmeta) then
					ambiance.sound_play("doors_locked", pos, 1.0, 20)
          return false
        end

        key_meta:set_string("secret", minetest.parse_json(key_oldmeta).secret)
        item:set_metadata("")
      end

      if secret ~= key_meta:get_string("secret") then
        minetest.chat_send_player(clicker:get_player_name(), "# Server: Key does not fit lock!")
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
        return false
      end

    elseif owner ~= "" then
      if clicker:get_player_name() ~= owner then
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
        return false
      end
    end
  end

	local door_above = _doors.have_matching_door({x=pos.x, y=pos.y + 2, z=pos.z}, node)
	local door_below = _doors.have_matching_door({x=pos.x, y=pos.y - 2, z=pos.z}, node)

	-- until Lua-5.2 we have no bitwise operators :(
	if state % 2 == 1 then
		state = state - 1
	else
		state = state + 1
	end

	local dir = node.param2

	-- Play door open/close sound (check if hinges are oiled, in which case door makes no sound).
	local last_oiled = meta:get_int("oiled_time")
	if (os.time() - last_oiled) > math.random(0, 60*60*24*7) then
		if state % 2 == 0 then
			minetest.sound_play(def.door.sounds[1],
				{pos = pos, gain = 0.3, max_hear_distance = 20})
		else
			minetest.sound_play(def.door.sounds[2],
				{pos = pos, gain = 0.3, max_hear_distance = 20})
		end
	end

	minetest.swap_node(pos, {
		name = name .. transform[state + 1][dir+1].v,
		param2 = transform[state + 1][dir+1].param2
	})
	meta:set_int("state", state)

	if door_above then
		_doors.door_toggle_force({x=pos.x, y=pos.y + 2, z=pos.z}, node)
	end

	if door_below then
		_doors.door_toggle_force({x=pos.x, y=pos.y - 2, z=pos.z}, node)
	end

	return true
end


local function on_place_node(place_to, newnode,
	placer, oldnode, itemstack, pointed_thing)
	-- Run script hook
	for _, callback in ipairs(minetest.registered_on_placenodes) do
		-- Deepcopy pos, node and pointed_thing because callback can modify them
		local place_to_copy = {x = place_to.x, y = place_to.y, z = place_to.z}
		local newnode_copy =
			{name = newnode.name, param1 = newnode.param1, param2 = newnode.param2}
		local oldnode_copy =
			{name = oldnode.name, param1 = oldnode.param1, param2 = oldnode.param2}
		local pointed_thing_copy = {
			type  = pointed_thing.type,
			above = vector.new(pointed_thing.above),
			under = vector.new(pointed_thing.under),
			ref   = pointed_thing.ref,
		}
		callback(place_to_copy, newnode_copy, placer,
			oldnode_copy, itemstack, pointed_thing_copy)
	end
end

local function can_dig_door(pos, digger)
	local digger_name = digger and digger:get_player_name()
	if digger_name and minetest.get_player_privs(digger_name).protection_bypass then
		return true
	end
	return minetest.get_meta(pos):get_string("doors_owner") == digger_name
end

function doors.register(name, def)
	if not name:find(":") then
		name = "doors:" .. name
	end

	local inv_image = def.inventory_image
	if def.protected then
		inv_image = inv_image .. "^protector_lock.png"
	end

	minetest.register_craftitem(":" .. name, {
		description = def.description,
		inventory_image = inv_image,
    groups = def.groups,

		on_place = function(itemstack, placer, pointed_thing)
			local pos

			if not pointed_thing.type == "node" then
				return itemstack
			end

      -- Pass through interactions to nodes that define them (like chests).
      local node = minetest.get_node(pointed_thing.under)
      local pdef = minetest.reg_ns_nodes[node.name]
      if pdef and pdef.on_rightclick and not placer:get_player_control().sneak then
        return pdef.on_rightclick(pointed_thing.under, node, placer, itemstack, pointed_thing)
      end

			if pdef and pdef.buildable_to then
				pos = pointed_thing.under
			else
				pos = pointed_thing.above
				node = minetest.get_node(pos)
				pdef = minetest.reg_ns_nodes[node.name]
				if not pdef or not pdef.buildable_to then
					return itemstack
				end
			end

			local above = {x = pos.x, y = pos.y + 1, z = pos.z}
			local top_node = minetest.get_node_or_nil(above)
			local topdef = top_node and minetest.reg_ns_nodes[top_node.name]

			if not topdef or not topdef.buildable_to then
				return itemstack
			end

			local pn = placer:get_player_name()
			if minetest.is_protected(pos, pn) or minetest.is_protected(above, pn) then
				return itemstack
			end

			local dir = minetest.dir_to_facedir(placer:get_look_dir())

			local ref = {
				{x = -1, y = 0, z = 0},
				{x = 0, y = 0, z = 1},
				{x = 1, y = 0, z = 0},
				{x = 0, y = 0, z = -1},
			}

			local aside = {
				x = pos.x + ref[dir + 1].x,
				y = pos.y + ref[dir + 1].y,
				z = pos.z + ref[dir + 1].z,
			}

			local state = 0
			if minetest.get_item_group(minetest.get_node(aside).name, "door") == 1 then
				state = state + 2
				minetest.set_node(pos, {name = name .. "_b", param2 = dir})
				minetest.set_node(above, {name = "doors:hidden", param2 = (dir + 3) % 4})
			else
				minetest.set_node(pos, {name = name .. "_a", param2 = dir})
				minetest.set_node(above, {name = "doors:hidden", param2 = dir})
			end

			local meta = minetest.get_meta(pos)
			meta:set_int("state", state)

			if def.protected then
				meta:set_string("doors_owner", pn)
				local dname = rename.gpn(pn)
				meta:set_string("rename", dname)
				meta:set_string("infotext", "Locked Door (Owned by <" .. dname .. ">!)")
			end

			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end

			on_place_node(pos, minetest.get_node(pos),
				placer, node, itemstack, pointed_thing)

			return itemstack
		end
	})
	def.inventory_image = nil

	if def.recipe then
		minetest.register_craft({
			output = name,
			recipe = def.recipe,
		})
	end
	def.recipe = nil

	if not def.sounds then
		def.sounds = default.node_sound_wood_defaults()
	end

	if not def.sound_open then
		def.sound_open = "doors_door_open"
	end

	if not def.sound_close then
		def.sound_close = "doors_door_close"
	end

	def.groups.not_in_creative_inventory = 1
	def.groups.door = 1
	def.drop = name
	def.door = {
		name = name,
		sounds = { def.sound_close, def.sound_open },
	}

	def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		_doors.door_toggle(pos, node, clicker)
		return itemstack
	end
	def.after_dig_node = function(pos, node, meta, digger)
		minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
		minetest.check_for_falling({x = pos.x, y = pos.y + 1, z = pos.z})
	end
  
  def.on_rotate = function(pos, node, user, mode, new_param2)
    return false
  end

	if def.protected then
		def.can_dig = can_dig_door
		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = doors.get(pos)
			door:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if not gdac.player_is_admin(pname) then
				if owner ~= pname then
					minetest.record_protection_violation(pos, pname)
					minetest.chat_send_player(pname, "# Server: You do not own this locked door.")
					return nil
				end
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked door", owner
		end

		-- Called by rename LBM.
		def._on_rename_check = function(pos)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			-- Nobody placed this block.
			if owner == "" then
				return
			end
			local dname = rename.gpn(owner)

			meta:set_string("rename", dname)
			meta:set_string("infotext", "Locked Door (Owned by <" .. dname .. ">!)")
		end

		-- Disable client dig prediction.
		def.node_dig_prediction = ""
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			-- hidden node doesn't get blasted away.
			minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
			return {name}
		end
	end

	def.on_destruct = function(pos)
		minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
	end

	def.drawtype = "mesh"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.sunlight_propagates = true
	def.walkable = true
	def.is_ground_content = false
	def.buildable_to = false
	def.selection_box = {type = "fixed", fixed = {-1/2,-1/2,-1/2,1/2,3/2,-6/16}}
	def.collision_box = {type = "fixed", fixed = {-1/2,-1/2,-1/2,1/2,3/2,-6/16}}

	def.mesh = "door_a.obj"
	minetest.register_node(":" .. name .. "_a", def)

	def.mesh = "door_b.obj"
	minetest.register_node(":" .. name .. "_b", def)

	_doors.registered_doors[name .. "_a"] = true
	_doors.registered_doors[name .. "_b"] = true
end

doors.register("door_wood", {
    tiles = {{ name = "doors_door_wood.png", backface_culling = true }},
    description = "Wooden Door",
    inventory_image = "doors_item_wood.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:stick"},
        {"group:wood_light", "group:wood_light"},
        {"group:wood_light", "group:wood_light"},
    }
})
  
minetest.register_craft({
  output = "doors:door_wood",
  recipe = {
    {"firetree:firewood", "group:stick"},
    {"firetree:firewood", "firetree:firewood"},
    {"firetree:firewood", "firetree:firewood"},
  },
})

minetest.register_craft({
  output = "doors:door_wood_locked",
  recipe = {
    {"firetree:firewood", "group:stick", ""},
    {"firetree:firewood", "firetree:firewood", "default:steel_ingot"},
    {"firetree:firewood", "firetree:firewood", ""},
  },
})

doors.register("door_wood_locked", {
    tiles = {{ name = "doors_door_wood.png", backface_culling = true }},
    description = "Locked Wooden Door",
    inventory_image = "doors_item_wood.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:stick", ""},
        {"group:wood_light", "group:wood_light", "default:steel_ingot"},
        {"group:wood_light", "group:wood_light", ""},
    }
})

doors.register("door_steel", {
    tiles = {{name = "doors_door_steel.png", backface_culling = true}},
    description = "Locked Iron Door",
    inventory_image = "doors_item_steel.png",
    protected = true,
    groups = utility.dig_groups("door_metal"),
    sounds = default.node_sound_metal_defaults(),
    sound_open = "doors_steel_door_open",
    sound_close = "doors_steel_door_close",
    recipe = {
        {"default:steel_ingot", "default:steel_ingot", ""},
        {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot", ""},
    }
})

doors.register("door_steel_unlocked", {
    tiles = {{name = "doors_door_steel.png", backface_culling = true}},
    description = "Iron Door",
    inventory_image = "doors_item_steel.png",
    groups = utility.dig_groups("door_metal"),
    sounds = default.node_sound_metal_defaults(),
    sound_open = "doors_steel_door_open",
    sound_close = "doors_steel_door_close",
    recipe = {
        {"default:steel_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot"},
    }
})

doors.register("door_iron", {
		tiles = {{name = "doors_door_iron.png", backface_culling = true}},
		description = "Wrought Iron Door",
		inventory_image = "doors_item_iron.png",
		groups = utility.dig_groups("door_metal"),
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_iron_door_open",
		sound_close = "doors_iron_door_close",
		recipe = {
			{"default:iron_lump", "default:iron_lump"},
			{"default:iron_lump", "default:iron_lump"},
			{"default:iron_lump", "default:iron_lump"},
		}
})

doors.register("door_iron_locked", {
		tiles = {{name = "doors_door_iron.png", backface_culling = true}},
		description = "Locked Wrought Iron Door",
		inventory_image = "doors_item_iron.png",
        protected = true,
		groups = utility.dig_groups("door_metal"),
		sounds = default.node_sound_metal_defaults(),
		sound_open = "doors_iron_door_open",
		sound_close = "doors_iron_door_close",
		recipe = {
			{"default:iron_lump", "default:iron_lump", ""},
			{"default:iron_lump", "default:iron_lump", "default:steel_ingot"},
			{"default:iron_lump", "default:iron_lump", ""},
		}
})

doors.register("door_glass", {
		tiles = {"doors_door_glass.png"},
		description = "Glass Door",
		inventory_image = "doors_item_glass.png",
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:glass", "default:glass"},
			{"default:glass", "default:glass"},
			{"default:glass", "default:glass"},
		}
})

doors.register("door_glass_locked", {
		tiles = {"doors_door_glass.png"},
		description = "Locked Glass Door",
		inventory_image = "doors_item_glass.png",
        protected = true,
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:glass", "default:glass", ""},
			{"default:glass", "default:glass", "default:steel_ingot"},
			{"default:glass", "default:glass", ""},
		}
})

doors.register("door_obsidian_glass", {
		tiles = {"doors_door_obsidian_glass.png"},
		description = "Obsidian Glass Door",
		inventory_image = "doors_item_obsidian_glass.png",
		groups = utility.dig_groups("door_glass"),
		sounds = default.node_sound_glass_defaults(),
		sound_open = "doors_glass_door_open",
		sound_close = "doors_glass_door_close",
		recipe = {
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
		},
})

doors.register("door_obsidian_glass_locked", {
    tiles = {"doors_door_obsidian_glass.png"},
    description = "Locked Obsidian Glass Door",
    inventory_image = "doors_item_obsidian_glass.png",
    protected = true,
    groups = utility.dig_groups("door_glass"),
    sounds = default.node_sound_glass_defaults(),
    sound_open = "doors_glass_door_open",
    sound_close = "doors_glass_door_close",
    recipe = {
        {"default:obsidian_glass", "default:obsidian_glass", ""},
        {"default:obsidian_glass", "default:obsidian_glass", "default:steel_ingot"},
        {"default:obsidian_glass", "default:obsidian_glass", ""},
    },
})

doors.register("door_wood_solid", {
    tiles = {"doors_door_woodsolid.png"},
    description = "Solid Wood Door",
    inventory_image = "doors_item_woodsolid.png",
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:wood_light"},
        {"group:wood_light", "group:wood_light"},
        {"group:wood_light", "group:wood_light"},
    },
})

doors.register("door_wood_solid_locked", {
    tiles = {"doors_door_woodsolid.png"},
    description = "Locked Solid Wood Door",
    inventory_image = "doors_item_woodsolid.png",
    protected = true,
    groups = utility.dig_groups("door_wood", {flammable = 2}),
    recipe = {
        {"group:wood_light", "group:wood_light", ""},
        {"group:wood_light", "group:wood_light", "default:steel_ingot"},
        {"group:wood_light", "group:wood_light", ""},
    },
})

doors.register("door_steel_glass", {
    tiles = {{name="doors_door_steelglass.png", backface_culling = true}},
    description = "Fancy Glass/Iron Door",
    inventory_image = "doors_item_steelglass.png",
    groups = utility.dig_groups("door_metal"),
    recipe = {
        {"default:steel_ingot", "default:glass"},
        {"default:glass", "default:steel_ingot"},
        {"default:steel_ingot", "default:glass"},
    },
})

doors.register("door_steel_glass_locked", {
    tiles = {{name="doors_door_steelglass.png", backface_culling = true}},
    description = "Locked Fancy Glass/Iron Door",
    inventory_image = "doors_item_steelglass.png",
    protected = true,
    groups = utility.dig_groups("door_metal"),
    recipe = {
        {"default:steel_ingot", "default:glass", ""},
        {"default:glass", "default:steel_ingot", "default:steel_ingot"},
        {"default:steel_ingot", "default:glass", ""},
    },
})

doors.register("door_wood_glass", {
    tiles = {{name="doors_door_woodglass.png", backface_culling = true}},
    description = "Fancy Glass/Darkwood Door",
    inventory_image = "doors_item_woodglass.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass"},
        {"default:glass", "group:wood_dark"},
        {"group:wood_dark", "default:glass"},
    },
})

doors.register("door_wood_glass_locked", {
    tiles = {{name="doors_door_woodglass.png", backface_culling = true}},
    description = "Locked Fancy Glass/Darkwood Door",
    inventory_image = "doors_item_woodglass.png",
    protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass", ""},
        {"default:glass", "group:wood_dark", "default:steel_ingot"},
        {"group:wood_dark", "default:glass", ""},
    },
})

doors.register("door_lightwood_glass", {
    tiles = {{name="doors_door_lightwoodglass.png", backface_culling = true}},
    description = "Fancy Glass/Wood Door",
    inventory_image = "doors_item_lightwoodglass.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass"},
        {"default:glass", "group:wood_light"},
        {"group:wood_light", "default:glass"},
    },
})

doors.register("door_lightwood_glass_locked", {
    tiles = {{name="doors_door_lightwoodglass.png", backface_culling = true}},
    description = "Locked Fancy Glass/Wood Door",
    inventory_image = "doors_item_lightwoodglass.png",
    protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass", ""},
        {"default:glass", "group:wood_light", "default:steel_ingot"},
        {"group:wood_light", "default:glass", ""},
    },
})

doors.register("door_fancy_ext1", {
    tiles = {{name="doors_door_ext_fancy1.png", backface_culling = true}},
    description = "Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy1.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass"},
        {"group:wood_light", "default:glass"},
        {"group:wood_light", "group:wood_light"},
    },
})

doors.register("door_fancy_ext1_locked", {
    tiles = {{name="doors_door_ext_fancy1.png", backface_culling = true}},
    description = "Locked Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy1.png",
		protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_light", "default:glass", ""},
        {"group:wood_light", "default:glass", "default:steel_ingot"},
        {"group:wood_light", "group:wood_light", ""},
    },
})

doors.register("door_fancy_ext2", {
    tiles = {{name="doors_door_ext_fancy2.png", backface_culling = true}},
    description = "Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy2.png",
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass"},
        {"group:wood_dark", "brass:ingot"},
        {"group:wood_dark", "group:wood_dark"},
    },
})

doors.register("door_fancy_ext2_locked", {
    tiles = {{name="doors_door_ext_fancy2.png", backface_culling = true}},
    description = "Locked Fancy Exterior Wood/Glass Door",
    inventory_image = "doors_item_ext_fancy2.png",
		protected = true,
    groups = utility.dig_groups("door_woodglass", {flammable = 2}),
    recipe = {
        {"group:wood_dark", "default:glass", ""},
        {"group:wood_dark", "brass:ingot", "default:steel_ingot"},
        {"group:wood_dark", "group:wood_dark", ""},
    },
})

-- Capture mods using the old API as best as possible.
function doors.register_door(name, def)
	if def.only_placer_can_open then
		def.protected = true
	end
	def.only_placer_can_open = nil

	local i = name:find(":")
	local modname = name:sub(1, i - 1)
	if not def.tiles then
		if def.protected then
			def.tiles = {{name = "doors_door_steel.png", backface_culling = true}}
		else
			def.tiles = {{name = "doors_door_wood.png", backface_culling = true}}
		end
		minetest.log("warning", modname .. " registered door \"" .. name .. "\" " ..
				"using deprecated API method \"doors.register_door()\" but " ..
				"did not provide the \"tiles\" parameter. A fallback tiledef " ..
				"will be used instead.")
	end

	doors.register(name, def)
end

----trapdoor----

function _doors.trapdoor_toggle(pos, node, clicker)
  node = node or minetest.get_node(pos)
  if clicker and not minetest.check_player_privs(clicker, "protection_bypass") then
    -- is player wielding the right key?
    local item = clicker:get_wielded_item()
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("doors_owner")
    if item:get_name() == "key:key" or item:get_name() == "key:chain" then
      local key_meta = item:get_meta()
      local secret = meta:get_string("key_lock_secret")

      if key_meta:get_string("secret") == "" then
        local key_oldmeta = item:get_metadata()
        if key_oldmeta == "" or not minetest.parse_json(key_oldmeta) then
					ambiance.sound_play("doors_locked", pos, 1.0, 20)
          return false
        end

        key_meta:set_string("secret", minetest.parse_json(key_oldmeta).secret)
        item:set_metadata("")
      end

      if secret ~= key_meta:get_string("secret") then
        minetest.chat_send_player(clicker:get_player_name(), "# Server: Key does not fit lock!")
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
        return false
      end

    elseif owner ~= "" then
      if clicker:get_player_name() ~= owner then
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
        return false
      end
    end
  end

	local def = minetest.reg_ns_nodes[node.name]

	-- Play trapdoor open/close sound (check if hinges are oiled, in which case door makes no sound).
	local play_sound = false
	local last_oiled = meta:get_int("oiled_time")
	if (os.time() - last_oiled) > math.random(0, 60*60*24*7) then
		play_sound = true
	end

	if string.sub(node.name, -5) == "_open" then
		if play_sound then
			minetest.sound_play(def.sound_close,
				{pos = pos, gain = 0.3, max_hear_distance = 20})
		end

		minetest.swap_node(pos, {name = string.sub(node.name, 1,
			string.len(node.name) - 5), param1 = node.param1, param2 = node.param2})
	else
		if play_sound then
			minetest.sound_play(def.sound_open,
				{pos = pos, gain = 0.3, max_hear_distance = 20})
		end

		minetest.swap_node(pos, {name = node.name .. "_open",
			param1 = node.param1, param2 = node.param2})
	end
end

function doors.register_trapdoor(name, def)
	if not name:find(":") then
		name = "doors:" .. name
	end

	def.groups = def.groups or {}
	def.groups.trapdoor = 1

	local name_closed = name
	local name_opened = name.."_open"

	def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		_doors.trapdoor_toggle(pos, node, clicker)
		return itemstack
	end

	-- Common trapdoor configuration
	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.is_ground_content = false

	if def.protected then
		def.can_dig = can_dig_door
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			local dname = rename.gpn(pn)
			meta:set_string("rename", dname)
			meta:set_string("infotext", "Locked Trapdoor (Owned by <" .. dname .. ">!)")

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = doors.get(pos)
			door:toggle(player)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			local pname = player:get_player_name()

			-- verify placer is owner of lockable door
			if not gdac.player_is_admin(pname) then
				if owner ~= pname then
					minetest.record_protection_violation(pos, pname)
					minetest.chat_send_player(pname, "# Server: You do not own this trapdoor.")
					return nil
				end
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, "a locked trapdoor", owner
		end

		-- Called by rename LBM.
		def._on_rename_check = function(pos)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("doors_owner")
			-- Nobody placed this block.
			if owner == "" then
				return
			end
			local dname = rename.gpn(owner)

			meta:set_string("rename", dname)
			meta:set_string("infotext", "Locked Trapdoor (Owned by <" .. dname .. ">!)")
		end

		-- Disable client dig prediction.
		def.node_dig_prediction = ""
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			return {name}
		end
	end

	if not def.sounds then
		def.sounds = default.node_sound_wood_defaults()
	end

	if not def.sound_open then
		def.sound_open = "doors_door_open"
	end

	if not def.sound_close then
		def.sound_close = "doors_door_close"
	end

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	}
	def_closed.tiles = {def.tile_front,
			def.tile_front .. '^[transformFY',
			def.tile_side, def.tile_side,
			def.tile_side, def.tile_side}

	def_opened.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 6/16, 0.5, 0.5, 0.5}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 6/16, 0.5, 0.5, 0.5}
	}
	def_opened.tiles = {def.tile_side, def.tile_side,
			def.tile_side .. '^[transform3',
			def.tile_side .. '^[transform1',
			def.tile_front .. '^[transform46',
			def.tile_front .. '^[transform6'}

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	if def.protected then
		def_closed.inventory_image = def_closed.inventory_image .. "^protector_lock.png"
		def_opened.inventory_image = def_opened.inventory_image .. "^protector_lock.png"
	end

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	_doors.registered_trapdoors[name_opened] = true
	_doors.registered_trapdoors[name_closed] = true
end

doors.register_trapdoor("doors:trapdoor", {
	description = "Wooden Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
	groups = utility.dig_groups("door_wood", {flammable = 2, door = 1}),
})

doors.register_trapdoor("doors:trapdoor_locked", {
	description = "Locked Wooden Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
    protected = true,
	groups = utility.dig_groups("door_wood", {flammable = 2, door = 1}),
})

doors.register_trapdoor("doors:trapdoor_steel", {
	description = "Iron Trapdoor",
	inventory_image = "doors_trapdoor_steel.png",
	wield_image = "doors_trapdoor_steel.png",
	tile_front = "doors_trapdoor_steel.png",
	tile_side = "doors_trapdoor_steel_side.png",
	protected = true,
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
})

doors.register_trapdoor("doors:trapdoor_iron_locked", {
	description = "Locked Wrought Iron Trapdoor",
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	tile_front = "doors_trapdoor_iron.png",
	tile_side = "doors_trapdoor_iron_side.png",
	protected = true,
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
})

doors.register_trapdoor("doors:trapdoor_iron", {
	description = "Wrought Iron Trapdoor",
	inventory_image = "doors_trapdoor_iron.png",
	wield_image = "doors_trapdoor_iron.png",
	tile_front = "doors_trapdoor_iron.png",
	tile_side = "doors_trapdoor_iron_side.png",
	sounds = default.node_sound_metal_defaults(),
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = utility.dig_groups("door_metal", {door = 1}),
})

minetest.register_craft({
	output = 'doors:trapdoor 2',
	recipe = {
		{'default:wood', 'default:wood', 'default:wood'},
		{'default:wood', 'default:wood', 'default:wood'},
		{'', '', ''},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_locked',
	recipe = {
		{'default:wood', 'default:steel_ingot', 'default:wood'},
		{'default:wood', 'default:wood',        'default:wood'},
		{'', '', ''},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_steel',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_iron',
	recipe = {
		{'default:iron_lump', 'default:iron_lump', 'default:iron_lump'},
		{'default:iron_lump', 'default:iron_lump', 'default:iron_lump'},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_iron_locked',
	recipe = {
		{'default:iron_lump', 'default:steel_ingot', 'default:iron_lump'},
		{'default:iron_lump', 'default:iron_lump',   'default:iron_lump'},
	}
})


----fence gate----

function doors.register_fencegate(name, def)
	local fence = {
		description = def.description,
		drawtype = "mesh",
		tiles = {def.texture},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = name .. "_closed",
		connect_sides = {"left", "right"},
		groups = def.groups,
		sounds = def.sounds,
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			local node_def = minetest.reg_ns_nodes[node.name]
			minetest.swap_node(pos, {name = node_def.gate, param2 = node.param2})
			minetest.sound_play(node_def.sound, {pos = pos, gain = 0.3,
				max_hear_distance = 20})
			return itemstack
		end,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/4, 1/2, 1/2, 1/4},
		},
	}

	if not fence.sounds then
		fence.sounds = default.node_sound_wood_defaults()
	end

	fence.groups.fence = 1

	local fence_closed = table.copy(fence)
	fence_closed.mesh = "doors_fencegate_closed.obj"
	fence_closed.gate = name .. "_open"
	fence_closed.sound = "doors_fencegate_open"
	fence_closed.collision_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/4, 1/2, 1/2, 1/4},
	}

	local fence_open = table.copy(fence)
	fence_open.mesh = "doors_fencegate_open.obj"
	fence_open.gate = name .. "_closed"
	fence_open.sound = "doors_fencegate_close"
	fence_open.groups.not_in_creative_inventory = 1
	fence_open.collision_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/4, -3/8, 1/2, 1/4},
			{-1/2, -3/8, -1/2, -3/8, 3/8, 0}},
	}

	minetest.register_node(":" .. name .. "_closed", fence_closed)
	minetest.register_node(":" .. name .. "_open", fence_open)

	minetest.register_craft({
		output = name .. "_closed",
		recipe = {
			{"group:stick", def.material, "group:stick"},
			{"group:stick", def.material, "group:stick"}
		}
	})
end

doors.register_fencegate("doors:gate_wood", {
	description = "Wooden Fence Gate",
	texture = "default_wood.png",
	material = "default:wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_acacia_wood", {
	description = "Acacia Wood Fence Gate",
	texture = "default_acacia_wood.png",
	material = "default:acacia_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_junglewood", {
	description = "Jungle Wood Fence Gate",
	texture = "default_junglewood.png",
	material = "default:junglewood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_pine_wood", {
	description = "Pine Wood Fence Gate",
	texture = "default_pine_wood.png",
	material = "default:pine_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_aspen_wood", {
	description = "Aspen Wood Fence Gate",
	texture = "default_aspen_wood.png",
	material = "default:aspen_wood",
	groups = utility.dig_groups("fence_wood", {flammable = 2}),
})

doors.register_fencegate("doors:gate_iron", {
	description = "Wrought Iron Fence Gate",
	texture = "default_fence_iron.png",
	material = "default:steel_ingot",
	groups = utility.dig_groups("fence_metal"),
})

doors.register_fencegate("doors:gate_bronze", {
	description = "Bronze Fence Gate",
	texture = "default_fence_bronze.png",
	material = "default:bronze_ingot",
	groups = utility.dig_groups("fence_metal"),
})
