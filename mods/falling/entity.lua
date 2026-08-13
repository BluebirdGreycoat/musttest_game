
-- How many seconds between checks to punch nearby entities while in flight.
local ENTITY_DAMAGE_TIME = 0.2

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



local function pos_out_of_bounds(pos)
	if pos.z < -30912 then
		return true
	end
	if pos.z > 30927 then
		return true
	end
	if pos.x > 30927 then
		return true
	end
	if pos.x < -30912 then
		return true
	end
	return false
end



local ADJACENCY = {
	{x=0, y=0, z=0},
	{x=0, y=0, z=0},
	{x=0, y=0, z=0},
	{x=0, y=0, z=0},
}

local function find_adjacent_slope(pos, selfdef)
	ADJACENCY[1].x=pos.x-1 ADJACENCY[1].y=pos.y ADJACENCY[1].z=pos.z
	ADJACENCY[2].x=pos.x+1 ADJACENCY[2].y=pos.y ADJACENCY[2].z=pos.z
	ADJACENCY[3].x=pos.x   ADJACENCY[3].y=pos.y ADJACENCY[3].z=pos.z+1
	ADJACENCY[4].x=pos.x   ADJACENCY[4].y=pos.y ADJACENCY[4].z=pos.z-1

	local targets = {}

	for i = 1, 4 do
		local p = ADJACENCY[i]
		local nodedef = all_nodes[get_node(p).name]

		if not node_walkable(p, nodedef, selfdef) then
			p.y = p.y + 1
			nodedef = all_nodes[get_node(p).name]

			if not node_walkable(p, nodedef, selfdef) and not pos_out_of_bounds(p) then
				targets[#targets+1] = {x=p.x, y=p.y-1, z=p.z}
			end

			p.y = p.y - 1
		end
	end

	if #targets == 0 then
		return nil
	end
	return targets[random(1, #targets)]
end



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

local function damage_entities_around(pos, node, pharm, mharm)
	if not pharm or pharm < 1 then
		return
	end
	if not mharm or mharm < 1 then
		return
	end

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



-- Warning: 'meta' sometimes contains userdata from the engine, or builtin.
function falling.set_node(self, node, meta)
	-- If this is a snow node and snow is supposed to be melted, then just remove the falling entity so we don't create gfx artifacts.
	if node.name == "default:snow" then
		if not snow.is_visible() then
			self.object:remove()
			return
		end
	end

	local ndef = all_nodes[node.name]
	if not ndef then
		self.object:remove()
		return
	end

	self.node = node
	self.meta = meta or {}

	-- Cache whether we're supposed to float on water
	self.floats = core.get_item_group(node.name, "float") ~= 0

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

	self.object:set_properties({
		is_visible = true,
		textures = {node.name},
	})
	self.pharm, self.mharm = get_node_falling_harm(node.name)
	self.sound = get_node_falling_sound(node.name)

	--minetest.log("TEST1: " .. dump(self.meta))
end



function falling.get_staticdata(self)
	local ds = {
		node = self.node,
		meta = self.meta,
		pharm = self.pharm,
		mharm = self.mharm,
		sound = self.sound,
	}

	--minetest.log("TEST2: " .. dump(ds))

	return minetest.serialize(ds)
end



function falling.on_activate(self, staticdata)
	self.object:set_armor_groups({immortal = 1})

	local pos = self.object:get_pos()
	if pos_out_of_bounds(pos) then
		self.object:remove()
		return
	end

	local ds = minetest.deserialize(staticdata)
	if ds and ds.node then
		self:set_node(ds.node, ds.meta)
	elseif ds then
		self:set_node(ds)
	elseif staticdata ~= "" then
		self:set_node({name = staticdata})
	end

	-- Set gravity.
	self.object:set_acceleration({x = 0, y = -8, z = 0})
end



function falling.on_step(self, dtime, moveresult)
	-- Turn to actual node when colliding with ground, or continue to move
	local pos = self.object:get_pos()

	-- Position of bottom center point
	local bcp = vector_round({x = pos.x, y = pos.y - 0.7, z = pos.z})

	-- Damage entities while falling/in-flight.
	self.damage_timer = (self.damage_timer or 0) + dtime
	if self.damage_timer >= ENTITY_DAMAGE_TIME then
		damage_entities_around(bcp, self.node, self.pharm, self.mharm)
		self.damage_timer = 0
	end

	-- Avoid bugs caused by an unloaded node below
	local bcn = get_node_or_nil(bcp)
	local bcd = bcn and all_nodes[bcn.name]
	local selfdef = all_nodes[self.node.name]

	-- Bail if nil.
	if not selfdef then
		self.object:remove()
		return
	end

	if bcd and bcd._falling_remove then
		if type(bcd._falling_remove) == "function" then
			bcd._falling_remove(bcp)
		else
			remove_node(bcp)
		end
	end

	if bcn and (not bcd or node_walkable(bcp, bcd, selfdef)) then
		if bcd and bcd.leveled and bcn.name == self.node.name then
			local addlevel = self.node.level

			if not addlevel or addlevel <= 0 then
				addlevel = bcd.leveled
			end

			if add_node_level(bcp, addlevel) == 0 then
				self.object:remove()
				return
			end
		elseif bcd and bcd.buildable_to and (not self.floats or bcd.liquidtype == "none") then
			remove_node(bcp)
			return
		end

		-- We have hit the ground. Check for a possible slope which we can continue to fall down.
		if bcd then
			local ss = find_adjacent_slope(bcp, selfdef)
			if ss ~= nil then
				self.object:set_pos(vector_add(ss, {x=0, y=1, z=0}))
				self.object:set_velocity({x=0, y=0, z=0})

				ambiance.sound_play("default_gravel_footstep", ss, 0.2, 20)
				return
			end
		end

		local np = {x=bcp.x, y=bcp.y+1, z=bcp.z}
		local protected = nil

		-- Check what's here.
		local n2 = get_node(np)
		local nd = all_nodes[n2.name]
		local nodedef = all_nodes[self.node.name]

		if nodedef then
			-- If not merely replacing air, or the nodetype is `buildable_to', then check protection.
			if n2.name ~= "air" or nodedef.buildable_to then
				protected = minetest.test_protection(np, "")
			end

			-- If it's not air and not liquid (and not protected), remove node and replace it with it's drops.
			if not protected and n2.name ~= "air" and (not nd or nd.liquidtype == "none") then
				remove_node(np)
				if nd.buildable_to == false then
					-- Add dropped items.
					-- Pass node name, because passing a node table gives wrong results.
					local drops = get_node_drops(n2.name, "")
					for _, dropped_item in pairs(drops) do
						add_item(np, dropped_item)
					end
				end

				-- Run script hook
				for _, callback in pairs(core.registered_on_dignodes) do
					callback(np, n2)
				end
			end

			-- Create node and remove entity.
			if not protected or n2.name == "air" or n2.name == "default:snow" or n2.name == "snow:footprints" then
				if protected and nodedef.buildable_to then
					-- If the position is protected and the node we're placing is `buildable_to',
					-- then we must drop an item instead in order to avoid creating a protection exploit,
					-- even though we'd normally be placing into air.
					local callback = nodedef.on_collapse_to_entity
					if callback then
						local drops = callback(np, self.node)
						if drops then
							for k, v in ipairs(drops) do
								minetest.add_item(np, v)
							end
						end
					else
						add_item(np, self.node)
					end
				else
					-- We're either placing into air, or crushing something that isn't protected.
					add_node(np, self.node)
					if self.meta then
						local meta = get_meta(np)
						meta:from_table(self.meta)
					end

					if self.sound then
						ambiance.sound_play(self.sound, np, 1.3, 20)
					end

					-- Mark node as unprotectable.
					-- This has to come before executing the node callback because the callback might remove the node.
					-- If the callback changes the node placed, it should use `minetest.swap_node()'.
					local meta = get_meta(np)
					meta:set_int("protection_cancel", 1)
					meta:mark_as_private("protection_cancel")

					-- Execute node callback.
					local callback = nodedef.on_finish_collapse
					if callback then
						callback(np, self.node)
					end

					-- Dirtspread notification.
					dirtspread.on_environment(np)
				end
			else
				-- Not air and protected, so we drop as entity instead.
				local callback = nodedef.on_collapse_to_entity
				if callback then
					callback(np, self.node)
				else
					add_item(np, self.node)
				end
			end
		end

		self.object:remove()
		after(1, function() core.check_for_falling(np) end)
		return
	end

	local vel = self.object:get_velocity()
	if vector_equals(vel, {x = 0, y = 0, z = 0}) then
		local npos = self.object:get_pos()
		self.object:set_pos(vector_round(npos))
	end
end
