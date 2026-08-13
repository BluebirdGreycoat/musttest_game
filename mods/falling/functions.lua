
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



-- Shall return 'true' if self-node considers under-node to be an obstacle.
function falling.node_walkable(pos, nodedef, selfdef)
	-- Can't check for 'buildable_to' here, because liquids are 'buildable_to'.
	if nodedef.walkable then return true end

	local f = selfdef.groups.float or 0
	if f ~= 0 and nodedef.liquidtype ~= "none" then
		return true
	end
end
local node_walkable = falling.node_walkable



-- Shall return true if a hypothetical falling node spawned at this position
-- would find a slope to fall down (or would fall straight down). In other words,
-- return false if that falling node, if spawned, would immediately turn back to
-- a solid node without moving.
function falling.could_fall_here(pos)
	local d = vector.add(pos, {x=0, y=-1, z=0})
	local selfdef = all_nodes[get_node(pos).name]
	local nodedef = all_nodes[get_node(d).name]

	if outof_bounds(d) then
		return false
	end

	if not node_walkable(d, nodedef, selfdef) then
		return true
	end

	if find_slope(d, selfdef) then
		return true
	end

	return false
end



-- Copied from builtin so I can fix the behavior.
local function convert_to_falling_node(pos, node)
	local obj = core.add_entity(pos, "__builtin:falling_node")
	if not obj then
		return false
	end

	ambiance.particles_on_dig(pos, node)

	local def = core.registered_nodes[node.name]
	if def and def.sounds and def.sounds.fall then
		core.sound_play(def.sounds.fall, {pos = pos}, true)
	end

	-- Execute node callback PRIOR to dropping the node, incase it needs to clean stuff up.
	-- Also make sure to call this BEFORE we get the node's meta, because the callback can change it.
	if def and def._on_pre_fall then
		def._on_pre_fall(pos)
	end

	-- remember node level, the entities' set_node() uses this
	node.level = core.get_node_level(pos)
	local meta = core.get_meta(pos)
	local metatable = meta and meta:to_table() or {}

	-- 'metatable' must be in table form, WITHOUT userdata.
	obj:get_luaentity():set_node(node, metatable)
	core.remove_node(pos)
	return true, obj
end



-- Copied from builtin so I can fix the behavior.
function core.spawn_falling_node(pos, drop_immovable)
	local node = core.get_node(pos)
	if node.name == "air" or node.name == "ignore" then
		return false
	end
	if not drop_immovable then
		if string.find(node.name, "flowing") then
			-- Do not treat flowing liquid as a falling node. Looks ugly.
			return false
		end
		if minetest.get_item_group(node.name, "immovable") ~= 0 then
			return false
		end
	end
	return convert_to_falling_node(pos, node)
end


--[[
local function highlight_position(pos)
	utility.original_add_particle({
		pos = pos,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 1.5,
		size = 4,
		collisiondetection = false,
		vertical = false,
		texture = "heart.png",
	})
end
--]]


-- Copied from builtin so I can fix the behavior.
function core.check_single_for_falling(p)
	local n = core.get_node(p)
	local ndef = minetest.registered_nodes[n.name]
	if not ndef or not ndef.groups then
		return false
	end
	local groups = ndef.groups

	if (groups.falling_node or 0) ~= 0 then
		local p_bottom = vector.offset(p, 0, -1, 0)
		-- Only spawn falling node if node below is loaded
		local n_bottom = core.get_node_or_nil(p_bottom)
		local d_bottom = n_bottom and core.registered_nodes[n_bottom.name]

		if d_bottom then
			local same = n.name == n_bottom.name
			-- Let leveled nodes fall if it can merge with the bottom node
			if same and d_bottom.paramtype2 == "leveled" and
					core.get_node_level(p_bottom) <
					core.get_node_max_level(p_bottom) then
				local success, _ = convert_to_falling_node(p, n)
				return success
			end

			-- Otherwise only if the bottom node is considered "fall through"
			if not same and not node_walkable(p_bottom, d_bottom, ndef) then
				local success, _ = convert_to_falling_node(p, n)
				return success
			end
		end
	end

	-- Handle special groups.

	local attached_node = groups.attached_node or 0
	local hanging_node = groups.hanging_node or 0
	local standing_node = groups.standing_node or 0

	-- These checks are not mutually exclusive.
	-- If any of them succeed, the node does not fall.
	-- If all checks (however many) fail, the node falls.
	local checks_done = 0
	local fail_count = 0

	if attached_node ~= 0 then
		if not utility.check_attached_node(p, n, attached_node) then
			fail_count = fail_count + 1
		end
		checks_done = checks_done + 1
	end

	if hanging_node ~= 0 then
		if not utility.check_hanging_node(p, n, hanging_node) then
			fail_count = fail_count + 1
		end
		checks_done = checks_done + 1
	end

	if standing_node ~= 0 then
		if not utility.check_standing_node(p, n, standing_node) then
			fail_count = fail_count + 1
		end
		checks_done = checks_done + 1
	end

	if checks_done > 0 and fail_count >= checks_done then
		utility.drop_attached_node(p)
		return true
	end

	return false
end


