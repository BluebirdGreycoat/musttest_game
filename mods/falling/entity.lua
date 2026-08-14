
-- How many seconds between checks to punch nearby entities while in flight.
local ENTITY_DAMAGE_TIME = 0.2

-- Gravity.
local GRAVITY = 9.8

local FDIR_TO_EULER = {
	{y = 0, x = 0, z = 0},
	{y = -math.pi/2, x = 0, z = 0},
	{y = math.pi, x = 0, z = 0},
	{y = math.pi/2, x = 0, z = 0},
	{y = math.pi/2, x = -math.pi/2, z = math.pi/2},
	{y = math.pi/2, x = math.pi, z = math.pi/2},
	{y = math.pi/2, x = math.pi/2, z = math.pi/2},
	{y = math.pi/2, x = 0, z = math.pi/2},
	{y = -math.pi/2, x = math.pi/2, z = math.pi/2},
	{y = -math.pi/2, x = 0, z = math.pi/2},
	{y = -math.pi/2, x = -math.pi/2, z = math.pi/2},
	{y = -math.pi/2, x = math.pi, z = math.pi/2},
	{y = 0, x = 0, z = math.pi/2},
	{y = 0, x = -math.pi/2, z = math.pi/2},
	{y = 0, x = math.pi, z = math.pi/2},
	{y = 0, x = math.pi/2, z = math.pi/2},
	{y = math.pi, x = math.pi, z = math.pi/2},
	{y = math.pi, x = math.pi/2, z = math.pi/2},
	{y = math.pi, x = 0, z = math.pi/2},
	{y = math.pi, x = -math.pi/2, z = math.pi/2},
	{y = math.pi, x = math.pi, z = 0},
	{y = -math.pi/2, x = math.pi, z = 0},
	{y = 0, x = math.pi, z = 0},
	{y = math.pi/2, x = math.pi, z = 0}
}

local get_node = core.get_node
local get_node_or_nil = core.get_node_or_nil
local get_node_drops = core.get_node_drops
local add_item = core.add_item
local add_node = core.set_node
local add_node_level = core.add_node_level
local remove_node = core.remove_node
local random = math.random
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local all_nodes = core.registered_nodes
local string_find = string.find
local get_objects_inside_radius = core.get_objects_inside_radius
local get_item_group = core.get_item_group
local get_meta = core.get_meta
local after = core.after
local node_walkable = falling.node_walkable
local pos_out_of_bounds = falling.pos_out_of_bounds
local find_adjacent_slope = falling.find_adjacent_slope



-- Hardcoded tool capabilities for speed.
local TOOL_CAPABILITIES = {
	full_punch_interval = 0.1,
	max_drop_level = 3,
	groupcaps= {
			fleshy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			choppy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			bendy =       {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			cracky =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			crumbly =     {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
			snappy =      {times={[1] = 0, [2] = 0, [3] = 0}, uses = 0, maxlevel = 3},
	},
	damage_groups = {fleshy = 1},
}

-- Do damage to player or mob.
-- Invokes droplift on __builtin:item entites.
-- Ignores all other entities.
local function damage_entity(self, obj)
	local pharm = self.pharm -- Damage to players.
	local mharm = self.mharm -- Damage to mobs.

	if not pharm or pharm < 1 then
		return
	end
	if not mharm or mharm < 1 then
		return
	end

	if obj:is_player() then
		if not gdac.player_is_admin(obj) and not camc.player_is_camera(obj) then
			local hp = obj:get_hp()
			if hp > 0 then -- Ignore the already-dead.
				utility.damage_player(obj, "crush", pharm)

				if obj:get_hp() <= 0 then
					-- Player will die.
					falling.run_callbacks_after("after_killed_player", {
						pname = obj:get_player_name(),
						player_pos = obj:get_pos(),
						pos = pos,
					})
				end
			end
		end

		return -- Done.
	end

	local entity = obj:get_luaentity()
	if entity then
		if entity.mob and entity.mob == true then
			TOOL_CAPABILITIES.damage_groups.fleshy = mharm
			obj:punch(obj, 1, TOOL_CAPABILITIES, nil)
		elseif entity.name == "__builtin:item" then
			droplift.invoke(obj)
		end
	end
end

local function damage_entities_around(self, dtime)
	self.damage_timer = (self.damage_timer or 0) + dtime
	if self.damage_timer < ENTITY_DAMAGE_TIME then
		return
	end
	self.damage_timer = 0

	local pos = vector_round(self.object:get_pos())
	local objects = get_objects_inside_radius(pos, 1.2)

	for i = 1, #objects do
		local r = objects[i]
		damage_entity(self, r)
	end
end



local function get_node_falling_sound(name)
	local def = all_nodes[name]
	if not def then
		return "default_gravel_footstep"
	end

	if def.no_sound_on_fall then
		return
	end

	if def.sounds then
		if def.sounds.footstep then
			local s = def.sounds.footstep
			if s.name then
				return s.name
			end
		end
	end

	return "default_gravel_footstep"
end



-- Called to check if a falling node may cause harm when it lands.
-- Must return the amount of harm the node does. Called when the falling node is first spawned.
local function get_node_falling_harm(name)
	if not name or name == "air" or name == "ignore" then
		return 0, 0
	end

	-- Abort if node cannot cause harm.
	if name == "bones:bones_type2" or string_find(name, "lava_") or string_find(name, "water_") then
		return 0, 0
	end

	-- Non-walkable nodes cause no harm.
	local ndef = all_nodes[name]
	if ndef then
		if not ndef.walkable then
			return 0, 0
		end

		-- Falling leaves cause a little damage.
		if ndef.groups then
			local lg = (ndef.groups.leaves or 0)
			if lg > 0 then
				return 100, 100
			end
		end

		-- If `crushing_damage' is defined, use it.
		if ndef.crushing_damage then
			local cd = ndef.crushing_damage
			return cd, cd
		end
	end

	-- Default amount of harm to: player, mobs.
	return 4*500, 4*500
end



local function set_visual_properties(self, node, def)
	-- Set up entity visuals
	-- For compatibility with older clients we continue to use "item" visual
	-- for simple situations.
	local drawtypes = {normal=true, glasslike=true, allfaces=true, nodebox=true}
	local p2types = {none=true, facedir=true, ["4dir"]=true}
	if drawtypes[def.drawtype] and p2types[def.paramtype2] and def.use_texture_alpha ~= "blend" then
		-- Calculate size of falling node
		local s = vector.zero()
		s.x = (def.visual_scale or 1) * 0.667
		s.y = s.x
		s.z = s.x
		-- Compensate for wield_scale
		if def.wield_scale then
			s.x = s.x / def.wield_scale.x
			s.y = s.y / def.wield_scale.y
			s.z = s.z / def.wield_scale.z
		end
		self.object:set_properties({
			is_visible = true,
			visual = "item",
			wield_item = node.name,
			visual_size = s,
			glow = def.light_source,
		})
		-- Rotate as needed
		if def.paramtype2 == "facedir" then
			local fdir = node.param2 % 32 % 24
			local euler = FDIR_TO_EULER[fdir + 1]
			if euler then
				self.object:set_rotation(euler)
			end
		elseif def.paramtype2 == "4dir" then
			local fdir = node.param2 % 4
			local euler = FDIR_TO_EULER[fdir + 1]
			if euler then
				self.object:set_rotation(euler)
			end
		end
	elseif def.drawtype ~= "airlike" then
		self.object:set_properties({
			is_visible = true,
			node = node,
			glow = def.light_source,
		})
	end

	-- Set collision box (certain nodeboxes only for now)
	local nb_types = {fixed=true, leveled=true, connected=true}
	if def.drawtype == "nodebox" and def.node_box and
		nb_types[def.node_box.type] and def.node_box.fixed then
		local box = table.copy(def.node_box.fixed)
		if type(box[1]) == "table" then
			box = #box == 1 and box[1] or nil -- We can only use a single box
		end
		if box then
			if def.paramtype2 == "leveled" and (self.node.level or 0) > 0 then
				box[5] = -0.5 + self.node.level / 64
			end
			self.object:set_properties({
				collisionbox = box
			})
		end
	end
end



-- Warning: 'meta' sometimes contains userdata from the engine, or builtin.
local function get_converted_metadata(meta)
	meta = meta or {}

	-- If we got userdata meta, convert to table form.
	if type(meta.to_table) == "function" then
		meta = meta:to_table()
	end

	for _, list in pairs(meta.inventory or {}) do
		for i, stack in pairs(list) do
			if type(stack) == "userdata" then
				list[i] = stack:to_string()
			end
		end
	end

	return meta
end



function falling.set_node(self, node, meta)
	-- If this is a snow node and snow is supposed to be melted,
	-- then just remove the falling entity so we don't create gfx artifacts.
	if node.name == "default:snow" then
		if not snow.is_visible() then
			self.object:remove()
			return
		end
	end

	-- Don't create falling nodes from unknown nodes.
	local ndef = all_nodes[node.name]
	if not ndef then
		self.object:remove()
		return
	end

	self.node = {name=node.name, param2=node.param2 or 0}
	self.meta = get_converted_metadata(meta)

	-- Cache whether we're supposed to float on water
	self.floats = (core.get_item_group(node.name, "float") ~= 0)
	-- Save liquidtype for falling water
	self.liquidtype = ndef.liquidtype

	set_visual_properties(self, self.node, ndef)

	self.pharm, self.mharm = get_node_falling_harm(node.name)
	self.sound = get_node_falling_sound(node.name)
end



function falling.get_staticdata(self)
	local ds = {
		node = self.node,
		meta = self.meta,
	}

	return minetest.serialize(ds)
end



function falling.on_activate(self, staticdata)
	self.object:set_armor_groups({immortal = 1})
	self.object:set_acceleration({x = 0, y = -GRAVITY, z = 0})

	local pos = self.object:get_pos()
	if pos_out_of_bounds(pos) then
		self.object:remove()
		return
	end

	local ds = minetest.deserialize(staticdata)
	if ds and ds.node then
		self:set_node(ds.node, ds.meta)
	elseif ds then -- What case is this supposed to handle?
		self:set_node(ds)
	elseif staticdata ~= "" then
		self:set_node({name = staticdata})
	end
end



local function finish_collapse_callback(np, def, node)
	-- Mark node as unprotectable.
	-- This has to come before executing the node callback because the callback might remove the node.
	-- If the callback changes the node placed, it should use `minetest.swap_node()'.
	local meta = get_meta(np)
	meta:set_int("protection_cancel", 1)
	meta:mark_as_private("protection_cancel")

	-- Execute node callback.
	local callback = def.on_finish_collapse
	if callback then
		callback(np, node)
	end

	-- Dirtspread notification.
	dirtspread.on_environment(np)
end



local function try_remove(protected, np)
	local node = core.get_node(np)
	local name = node.name
	local ndef = all_nodes[name] or {}

	if name ~= "air" then
		if not protected then
			core.remove_node(np)

			-- Run script hook.
			for _, callback in pairs(core.registered_on_dignodes) do
				callback(np, node) -- Node position, oldnode.
			end

			if not ndef.buildable_to and ndef.liquidtype == "none" then
				-- Add dropped items.
				-- Pass node name, because passing a node table gives wrong results.
				local drops = get_node_drops(name, "")
				for _, dropped_item in pairs(drops) do
					add_item(np, dropped_item)
				end
			end

			return true
		end

		-- These nodes can always be replaced by falling nodes.
		if name == "default:snow" or name == "snow:footprints" then
			return true
		end

		-- Protected. Can't remove.
		return false
	end

	-- Removing air always succeeds.
	return true
end



local function try_place(self, bcp, bcn)
	local bcd = core.registered_nodes[bcn.name]
	-- Add levels if dropped on same leveled node
	if bcd and bcd.paramtype2 == "leveled" and bcn.name == self.node.name then
		local addlevel = self.node.level
		if (addlevel or 0) <= 0 then
			addlevel = bcd.leveled
		end
		if core.add_node_level(bcp, addlevel) < addlevel then
			return true
		elseif bcd.buildable_to then
			-- Node level has already reached max, don't place anything
			return true
		end
	end

	local do_remove = false

	-- Decide if we're replacing the node or placing on top
	-- This condition is very similar to the check in core.check_single_for_falling(p)
	local np = vector.copy(bcp)
	if bcd and bcd.buildable_to
			and -- Take "float" group into consideration:
			(
				-- Fall through non-liquids
				not self.floats or bcd.liquidtype == "none" or
				-- Only let sources fall through flowing liquids
				(self.floats and self.liquidtype ~= "none" and bcd.liquidtype ~= "source")
			) then

		do_remove = true
	else
		-- We are placing on top so check what's there
		np.y = np.y + 1

		local n2 = core.get_node(np)
		local nd = core.registered_nodes[n2.name]
		if not nd or nd.buildable_to then
			do_remove = true
		else
			-- 'walkable' is used to mean "falling nodes can't replace this"
			-- here. Normally we would collide with the walkable node itself
			-- and place our node on top (so `n2.name == "air"`), but we
			-- re-check this in case we ended up inside a node.
			if not nd.diggable or nd.walkable then
				return false
			end

			do_remove = true
		end
	end

	-- Prefetch whether the location we'll place to is protected.
	local protected = core.test_protection(np, "")

	-- Actually try to remove what's here.
	if do_remove then
		if not try_remove(protected, np) then
			return false
		end
	end

	-- Create node
	local def = core.registered_nodes[self.node.name]
	if def then
		-- If the position is protected and the node we're placing is `buildable_to',
		-- then we must drop an item instead in order to avoid creating a protection exploit.
		-- (Player could drop a buildable_to node, get "protection_cancel" set on its
		-- metadata, then build into the node, thus breaking protection.)
		local ndef = all_nodes[self.node.name] or {}
		if protected and ndef.buildable_to then
			return false
		end

		core.add_node(np, self.node)

		if self.meta then
			core.get_meta(np):from_table(self.meta)
		end
		if def.sounds and def.sounds.place then
			core.sound_play(def.sounds.place, {pos = np}, true)
		end

		finish_collapse_callback(np, def, self.node)
	end

	core.check_for_falling(np)
	return true
end



local function get_moveresult_info(moveresult)
	local bcp, bcn
	local entity_collision

	if moveresult.touching_ground then
		for _, info in ipairs(moveresult.collisions) do
			if info.type == "object" then
				if info.axis == "y" then
					if info.object:is_player() then
						entity_collision = info
					else
						local entity = info.object:get_luaentity()
						if entity.mob == true then
							entity_collision = info
						end
					end
				end
			elseif info.axis == "y" then
				bcp = info.node_pos
				bcn = core.get_node(bcp)
				break
			end
		end
	end

	return bcp, bcn, entity_collision
end



local function handle_collision_entity_or_ignore(self, bcp, bcn, entity_collision)
	if not bcp then
		-- We're colliding with something, but not the ground. Irrelevant to us.
		if entity_collision then
			-- Continue falling through players/mobs by moving a little into
			-- their collision box
			-- TODO: this hack could be avoided in the future if objects
			--       could choose who to collide with
			local vel = self.object:get_velocity()
			self.object:set_velocity(vector.new(
				vel.x,
				entity_collision.old_velocity.y,
				vel.z
			))
			self.object:set_pos(self.object:get_pos():offset(0, -0.5, 0))
			damage_entity(self, entity_collision.object)
		end
		return true
	elseif bcn.name == "ignore" then
		-- Delete on contact with ignore at world edges
		self.object:remove()
		return true
	end
end



local function handle_collision_extended_node(self, bcp, bcn)
	local failure = false

	local pos = self.object:get_pos()
	local distance = vector.apply(vector.subtract(pos, bcp), math.abs)

	if distance.x >= 1 or distance.z >= 1 then
		-- We're colliding with some part of a node that's sticking out
		-- Since we don't want to visually teleport, drop as item
		failure = true
	elseif distance.y >= 2 then
		-- Doors consist of a hidden top node and a bottom node that is
		-- the actual door. Despite the top node being solid, the moveresult
		-- almost always indicates collision with the bottom node.
		-- Compensate for this by checking the top node
		bcp.y = bcp.y + 1
		bcn = core.get_node(bcp)
		local def = core.registered_nodes[bcn.name]
		if not (def and def.walkable) then
			failure = true -- This is unexpected, fail
		end
	end

	return failure, bcp, bcn
end



local function follow_adjacent_slope(self, bcp)
	-- We have hit the ground. Check for a possible slope which we can continue to fall down.
	local ndef = all_nodes[self.node.name]
	local ss = find_adjacent_slope(bcp, ndef)
	if ss ~= nil then
		self.object:set_pos(vector_add(ss, {x=0, y=1, z=0}))
		self.object:set_velocity({x=0, y=0, z=0})

		ambiance.sound_play("default_gravel_footstep", ss, 0.2, 20)
		return true
	end
end



local function drop_as_item(self)
	local ndef = all_nodes[self.node.name]
	local callback = ndef.on_collapse_to_entity
	if callback then
		local pos = vector_round(self.object:get_pos())
		callback(pos, self.node)
	else
		local pos = self.object:get_pos()
		local drops = core.get_node_drops(self.node, "")
		for _, item in pairs(drops) do
			core.add_item(pos, item)
		end
	end
end



local function trigger_fallthrough_callbacks(self)
	local pos = self.object:get_pos()

	local bcp = pos:offset(0, -0.7, 0):round()
	local bcn = core.get_node(bcp)

	local bcd = core.registered_nodes[bcn.name]
	if bcd and bcd._falling_remove then
		if type(bcd._falling_remove) == "function" then
			bcd._falling_remove(bcp)
		elseif bcd._falling_remove == true then
			remove_node(bcp)
		end
	end
end



local function handle_floating_fall(self)
	-- Fallback code since collision detection can't tell us
	-- about liquids (which do not collide)
	if self.floats then
		local pos = self.object:get_pos()

		local bcp = pos:offset(0, -0.7, 0):round()
		local bcn = core.get_node(bcp)

		local bcd = core.registered_nodes[bcn.name]
		if bcd and bcd.liquidtype ~= "none" then
			if try_place(self, bcp, bcn) then
				self.object:remove()
				return true
			end
		end
	end
end



function falling.on_step(self, dtime, moveresult)
	trigger_fallthrough_callbacks(self)
	damage_entities_around(self, dtime)

	-- Collision detection does not detect liquids.
	if handle_floating_fall(self) then
		return
	end

	if not moveresult or not moveresult.collides then
		return -- Fast path.
	end

	-- Returns: bcp=nodepos, bcn=nodetable. Or nil.
	local bcp, bcn, entity_collision = get_moveresult_info(moveresult)

	if handle_collision_entity_or_ignore(self, bcp, bcn, entity_collision) then
		-- If hit ignore, self is deleted.
		-- If hit player or other entity, self is teleported slightly.
		-- Do damage to players and mobs.
		return
	end

	local failure = false
	failure, bcp, bcn = handle_collision_extended_node(self, bcp, bcn)

	-- Try to actually place ourselves
	if not failure then
		if follow_adjacent_slope(self, bcp) then
			-- If slope found, keep falling.
			return
		end
		failure = not try_place(self, bcp, bcn)
	end

	if failure then
		-- Could not place, so drop as item.
		drop_as_item(self)
	end
	self.object:remove()
end
