-- our API object
doors = {}
doors.modpath = minetest.get_modpath("doors")

-- Localize for performance.
local math_random = math.random

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
			open = function(self, pname)
				if self:state() then
					return false
				end
				return _doors.door_toggle(self.pos, nil, pname)
			end,
			close = function(self, pname)
				if not self:state() then
					return false
				end
				return _doors.door_toggle(self.pos, nil, pname)
			end,
			toggle = function(self, pname)
				return _doors.door_toggle(self.pos, nil, pname)
			end,
			state = function(self)
				local state = minetest.get_meta(self.pos):get_int("state")
				return state %2 == 1
			end,
			owner = function(self)
				return minetest.get_meta(self.pos):get_string("doors_owner")
			end,
		}
	elseif _doors.registered_trapdoors[node_name] then
		-- A trapdoor
		return {
			pos = pos,
			open = function(self, pname)
				if self:state() then
					return false
				end
				return _doors.trapdoor_toggle(self.pos, nil, pname)
			end,
			close = function(self, pname)
				if not self:state() then
					return false
				end
				return _doors.trapdoor_toggle(self.pos, nil, pname)
			end,
			toggle = function(self, pname)
				return _doors.trapdoor_toggle(self.pos, nil, pname)
			end,
			state = function(self)
				return minetest.get_node(self.pos).name:sub(-5) == "_open"
			end,
			owner = function(self)
				return minetest.get_meta(self.pos):get_string("doors_owner")
			end,
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
function _doors.door_toggle(pos, node, clickername)
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

  if not minetest.check_player_privs(clickername, "protection_bypass") then
    -- is player wielding the right key?
    local clicker = minetest.get_player_by_name(clickername)
    local item = clicker and clicker:get_wielded_item()
    local owner = meta:get_string("doors_owner")

    if (clicker and item) and (item:get_name() == "key:key" or item:get_name() == "key:chain") then
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
        minetest.chat_send_player(clickername, "# Server: Key does not fit lock!")
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
        return false
      end

    elseif owner ~= "" then
      if clickername ~= owner then
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
	if (os.time() - last_oiled) > math_random(0, 60*60*24*7) then
		if state % 2 == 0 then
			minetest.sound_play(def.door.sounds[1],
				{pos = pos, gain = 0.3, max_hear_distance = 20}, true)
		else
			minetest.sound_play(def.door.sounds[2],
				{pos = pos, gain = 0.3, max_hear_distance = 20}, true)
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
				minetest.add_node(pos, {name = name .. "_b", param2 = dir})
				minetest.add_node(above, {name = "doors:hidden", param2 = (dir + 3) % 4})
			else
				minetest.add_node(pos, {name = name .. "_a", param2 = dir})
				minetest.add_node(above, {name = "doors:hidden", param2 = dir})
			end

			local meta = minetest.get_meta(pos)
			meta:set_int("state", state)

			if def.protected then
				meta:set_string("doors_owner", pn)
				local dname = rename.gpn(pn)
				meta:set_string("rename", dname)
				meta:set_string("infotext", "Locked Door (Owned by <" .. dname .. ">!)")
			end

			if not minetest.settings:get_bool("creative_mode") then
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
		if clicker then
			_doors.door_toggle(pos, node, clicker:get_player_name())
		end
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
			door:toggle(player:get_player_name())
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

function _doors.trapdoor_toggle(pos, node, clickername)
	node = node or minetest.get_node(pos)
	local meta = minetest.get_meta(pos)

	if not minetest.check_player_privs(clickername, "protection_bypass") then
		-- is player wielding the right key?
		local clicker = minetest.get_player_by_name(clickername)
		local item = clicker and clicker:get_wielded_item()
		local owner = meta:get_string("doors_owner")

		if (clicker and item) and (item:get_name() == "key:key" or item:get_name() == "key:chain") then
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
				minetest.chat_send_player(clickername, "# Server: Key does not fit lock!")
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
				return false
			end

		elseif owner ~= "" then
			if clickername ~= owner then
				ambiance.sound_play("doors_locked", pos, 1.0, 20)
				return false
			end
		end
	end

	local def = minetest.reg_ns_nodes[node.name]

	-- Play trapdoor open/close sound (check if hinges are oiled, in which case door makes no sound).
	local play_sound = false
	local last_oiled = meta:get_int("oiled_time")
	if (os.time() - last_oiled) > math_random(0, 60*60*24*7) then
		play_sound = true
	end

	if string.sub(node.name, -5) == "_open" then
		if play_sound then
			minetest.sound_play(def.sound_close,
				{pos = pos, gain = 0.3, max_hear_distance = 20}, true)
		end

		minetest.swap_node(pos, {name = string.sub(node.name, 1,
			string.len(node.name) - 5), param1 = node.param1, param2 = node.param2})
	else
		if play_sound then
			minetest.sound_play(def.sound_open,
				{pos = pos, gain = 0.3, max_hear_distance = 20}, true)
		end

		minetest.swap_node(pos, {name = node.name .. "_open",
			param1 = node.param1, param2 = node.param2})
	end
end



function doors.register_trapdoor(name, def)
	local origname = name
	local origdef = table.copy(def)

	if not name:find(":") then
		name = "doors:" .. name
	end

	def.groups = def.groups or {}
	def.groups.trapdoor = 1

	local name_closed = name
	local name_opened = name.."_open"

	def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if clicker then
			_doors.trapdoor_toggle(pos, node, clicker:get_player_name())
		end
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

			return minetest.settings:get_bool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = doors.get(pos)
			door:toggle(player:get_player_name())
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

	if def.recipeitem then
		local hinge = "techcrafts:hinge"
		if def.recipehinge then
			hinge = def.recipehinge
		end

		if def.protected then
			minetest.register_craft({
				output = name,
				recipe = {
					{'', 'default:padlock', ''},
					{def.recipeitem, def.recipeitem, 'group:stick'},
					{def.recipeitem, def.recipeitem, hinge},
				}
			})
		else
			minetest.register_craft({
				output = name,
				recipe = {
					{def.recipeitem, def.recipeitem, 'group:stick'},
					{def.recipeitem, def.recipeitem, hinge},
				}
			})
		end
	end

	_doors.registered_trapdoors[name_opened] = true
	_doors.registered_trapdoors[name_closed] = true

	doors.register_trapdoor_climbable("climbable_" .. origname, origdef)
end




function doors.register_trapdoor_climbable(name, def)
	if not name:find(":") then
		name = "doors:" .. name
	end

	def.groups = def.groups or {}
	def.groups.trapdoor = 1

	local name_closed = name
	local name_opened = name.."_open"

	def.description = def.description .. " With Ladder"

	def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if clicker then
			_doors.trapdoor_toggle(pos, node, clicker:get_player_name())
		end
		return itemstack
	end

	-- Common trapdoor configuration
	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.climbable = true
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

			return minetest.settings:get_bool("creative_mode")
		end

		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local door = doors.get(pos)
			door:toggle(player:get_player_name())
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
	def_closed.inventory_image = def_closed.inventory_image .. "^doors_ladder.png"
	def_opened.inventory_image = def_opened.inventory_image .. "^doors_ladder.png"

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	if def.recipeitem then
		local hinge = "techcrafts:hinge"
		if def.recipehinge then
			hinge = def.recipehinge
		end

		if def.protected then
			minetest.register_craft({
				output = name,
				recipe = {
					{'', 'default:padlock', ''},
					{def.recipeitem, def.recipeitem, 'default:ladder_wood'},
					{def.recipeitem, def.recipeitem, hinge},
				}
			})
		else
			minetest.register_craft({
				output = name,
				recipe = {
					{def.recipeitem, def.recipeitem, 'default:ladder_wood'},
					{def.recipeitem, def.recipeitem, hinge},
				}
			})
		end
	end

	_doors.registered_trapdoors[name_opened] = true
	_doors.registered_trapdoors[name_closed] = true
end



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
			minetest.swap_node(pos, {name = node_def._gate, param2 = node.param2})
			minetest.sound_play(node_def._gate_sound, {pos = pos, gain = 0.3,
				max_hear_distance = 20}, true)
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
	fence_closed._gate = name .. "_open"
	fence_closed._gate_sound = "doors_fencegate_open"
	fence_closed.collision_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/4, 1/2, 1/2, 1/4},
	}

	local fence_open = table.copy(fence)
	fence_open.mesh = "doors_fencegate_open.obj"
	fence_open._gate = name .. "_closed"
	fence_open._gate_sound = "doors_fencegate_close"
	fence_open.groups.not_in_creative_inventory = 1
	fence_open.collision_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/4, -3/8, 1/2, 1/4},
			{-1/2, -3/8, -1/2, -3/8, 3/8, 0}},
	}

	minetest.register_node(":" .. name .. "_closed", fence_closed)
	minetest.register_node(":" .. name .. "_open", fence_open)

	do
		local hinge = "techcrafts:hinge"
		if minetest.get_item_group(def.material, "wood") ~= 0 then
			hinge = "techcrafts:hinge_wood"
		end

		minetest.register_craft({
			output = name .. "_closed",
			recipe = {
				{hinge, def.material, "group:stick"},
				{"group:stick", def.material, "group:stick"},
			}
		})
	end
end

dofile(doors.modpath .. "/doors.lua")
dofile(doors.modpath .. "/trapdoors.lua")
dofile(doors.modpath .. "/gates.lua")
