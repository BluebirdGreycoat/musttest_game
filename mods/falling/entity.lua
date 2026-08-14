
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

local function damage_entities_around(self, dtime)
	self.damage_timer = (self.damage_timer or 0) + dtime
	if self.damage_timer < ENTITY_DAMAGE_TIME then
		return
	end
	self.damage_timer = 0

	local pharm = self.pharm
	local mharm = self.mharm

	if not pharm or pharm < 1 then
		return
	end
	if not mharm or mharm < 1 then
		return
	end

	local pos = vector_round(self.object:get_pos())
	local objects = get_objects_inside_radius(pos, 1.2)

	for i = 1, #objects do
		local r = objects[i]
		if r:is_player() then
			if not gdac.player_is_admin(r) and not camc.player_is_camera(r) then
				local hp = r:get_hp()
				if hp > 0 then
					utility.damage_player(r, "crush", pharm)

					if r:get_hp() <= 0 then
						-- Player will die.
						falling.run_callbacks_after("after_killed_player", {
							pname = r:get_player_name(),
							player_pos = r:get_pos(),
							pos = pos,
						})
					end
				end
			end
		else
			local l = r:get_luaentity()
			if l then
				if l.mob and l.mob == true then
					TOOL_CAPABILITIES.damage_groups.fleshy = mharm
					r:punch(r, 1, TOOL_CAPABILITIES, nil)
				elseif l.name == "__builtin:item" then
					droplift.invoke(r)
				end
			end
		end
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
			-- Mobs always take damage*5.
			return cd, cd*5
		end
	end

	-- Default amount of harm to: player, mobs.
	return 4*500, 20*500
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

		core.remove_node(bcp)
	else
		-- We are placing on top so check what's there
		np.y = np.y + 1

		local n2 = core.get_node(np)
		local nd = core.registered_nodes[n2.name]
		if not nd or nd.buildable_to then
			core.remove_node(np)
		else
			-- 'walkable' is used to mean "falling nodes can't replace this"
			-- here. Normally we would collide with the walkable node itself
			-- and place our node on top (so `n2.name == "air"`), but we
			-- re-check this in case we ended up inside a node.
			if not nd.diggable or nd.walkable then
				return false
			end
			nd.on_dig(np, n2, nil)
			-- If it's still there, it might be protected
			if core.get_node(np).name == n2.name then
				return false
			end
		end
	end

	-- Create node
	local def = core.registered_nodes[self.node.name]
	if def then
		core.add_node(np, self.node)
		if self.meta then
			core.get_meta(np):from_table(self.meta)
		end
		if def.sounds and def.sounds.place then
			core.sound_play(def.sounds.place, {pos = np}, true)
		end
	end
	core.check_for_falling(np)
	return true
end



local function get_moveresult_info(moveresult)
	local bcp, bcn
	local player_collision

	if moveresult.touching_ground then
		for _, info in ipairs(moveresult.collisions) do
			if info.type == "object" then
				if info.axis == "y" and info.object:is_player() then
					player_collision = info
				end
			elseif info.axis == "y" then
				bcp = info.node_pos
				bcn = core.get_node(bcp)
				break
			end
		end
	end

	return bcp, bcn, player_collision
end



local function handle_collision_player_or_ignore(self, bcp, bcn, player_collision)
	if not bcp then
		-- We're colliding with something, but not the ground. Irrelevant to us.
		if player_collision then
			-- Continue falling through players by moving a little into
			-- their collision box
			-- TODO: this hack could be avoided in the future if objects
			--       could choose who to collide with
			local vel = self.object:get_velocity()
			self.object:set_velocity(vector.new(
				vel.x,
				player_collision.old_velocity.y,
				vel.z
			))
			self.object:set_pos(self.object:get_pos():offset(0, -0.5, 0))
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
	local pos = self.object:get_pos()
	local drops = core.get_node_drops(self.node, "")
	for _, item in pairs(drops) do
		core.add_item(pos, item)
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
	local bcp, bcn, player_collision = get_moveresult_info(moveresult)

	if handle_collision_player_or_ignore(self, bcp, bcn, player_collision) then
		-- If hit ignore, self is deleted.
		-- If hit player, self is teleported slightly.
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
