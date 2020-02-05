local cid_data = {}
minetest.after(0, function()
	for name, def in pairs(minetest.registered_nodes) do
		cid_data[minetest.get_content_id(name)] = {
			name = name,
			drops = def.drops,
			flammable = def.groups.flammable,
			on_blast = def.on_blast,
      on_destruct = def.on_destruct,
      after_destruct = def.after_destruct,
		}
	end
end)

-- loss probabilities array (one in X will be lost)
local stack_loss_prob = {}
stack_loss_prob["default:cobble"] = 2
stack_loss_prob["rackstone:redrack"] = 2
stack_loss_prob["default:ice"] = 2

local function rand_pos(center, pos, radius)
  pos.x = center.x + math.random(-radius, radius)
  pos.z = center.z + math.random(-radius, radius)
  
  -- Keep picking random positions until a position inside the sphere is chosen.
  -- This gives us a uniform (flattened) spherical distribution.
  while vector.distance(center, pos) >= radius do
    pos.x = center.x + math.random(-radius, radius)
    pos.z = center.z + math.random(-radius, radius)
  end
end

local function eject_drops(drops, pos, radius)
  local drop_pos = vector.new(pos)
  for name, total in pairs(drops) do
		local trash = false

		-- Nothing is lost unless the player loses it.
		if stack_loss_prob[name] ~= nil and math.random(1, stack_loss_prob[name]) == 1 then
			trash = true
		end

		if not trash then
			local count = total
			local item = ItemStack(name)

			while count > 0 do
				local take = math.max(1,math.min(radius * radius, count, item:get_stack_max()))

				rand_pos(pos, drop_pos, radius*0.9)
				local dropitem = ItemStack(name)
				dropitem:set_count(take)

				local obj = minetest.add_item(drop_pos, dropitem)
				if obj then
					obj:get_luaentity().collect = true
					obj:setacceleration({x = 0, y = -10, z = 0})
					obj:setvelocity({x = math.random(-3, 3), y = math.random(0, 10), z = math.random(-3, 3)})
					droplift.invoke(obj, math.random(3, 10))
				end

				count = count - take
			end
		end
  end
end

local function add_drop(drops, item)
	item = ItemStack(item)
	local name = item:get_name()
	
	local drop = drops[name]
	if drop == nil then
		drops[name] = item:get_count()
	else
    -- This is causing stacks to get clamped to stack_max, which causes stuff to be lost.
		--drop:set_count(drop:get_count() + item:get_count())
    drops[name] = drops[name] + item:get_count()
	end
end

local function destroy(drops, npos, cid, c_air, c_fire, on_blast_queue, on_destruct_queue, on_after_destruct_queue, fire_locations, ignore_protection, ignore_on_blast, pname)
	-- This, right here, is probably what slows TNT code down the most.
  -- Perhaps we can avoid the issue by not allowing TNT to be placed within
  -- a hundred meters of a city block?
  -- Must also consider: explosions caused by mobs, arrows, other code ...
  -- Idea: TNT blasts ignore protection, but TNT can only be placed away from
  -- cityblocks. Explosions from mobs and arrows respect protection as usual.
  if not ignore_protection then
    if minetest.test_protection(npos, pname) then
      return cid
    end
	end

  local def = cid_data[cid]
  if not def then
    return c_air
  end
  
  if def.on_destruct then
    -- Queue on_destruct callbacks only if ignoring on_blast.
    if ignore_on_blast or not def.on_blast then
      on_destruct_queue[#on_destruct_queue+1] = {
        pos = vector.new(npos),
        on_destruct = def.on_destruct,
      }
    end
  end

  if def.after_destruct then
    -- Queue after_destruct callbacks only if ignoring on_blast.
    if ignore_on_blast or not def.on_blast then
      on_after_destruct_queue[#on_after_destruct_queue+1] = {
        pos = vector.new(npos),
        after_destruct = def.after_destruct,
        oldnode = minetest.get_node(npos),
      }
    end
  end

	if not ignore_on_blast and def.on_blast then
		on_blast_queue[#on_blast_queue + 1] = {
      pos = vector.new(npos),
      on_blast = def.on_blast,
    }
		return cid
	elseif def.flammable then
    fire_locations[#fire_locations+1] = vector.new(npos)
		return c_fire
	else
		local node_drops = minetest.get_node_drops(def.name, "")
		for _, item in ipairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air
	end
end

local function calc_velocity(pos1, pos2, old_vel, power)
	-- Avoid errors caused by a vector of zero length
	if vector.equals(pos1, pos2) then
		return old_vel
	end

	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)

	-- randomize it a bit
	vel = vector.add(vel, {
		x = math.random() - 0.5,
		y = math.random() - 0.5,
		z = math.random() - 0.5,
	})

	-- Limit to terminal velocity
	dist = vector.length(vel)
	if dist > 250 then
		vel = vector.divide(vel, dist / 250)
	end
	return vel
end

local function entity_physics(pos, radius, drops, boomdef)
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:get_pos()
		local dist = math.max(1, vector.distance(pos, obj_pos))

		-- Calculate damage to be applied to player or mob.
		local damage = (8 / dist) * radius

		if obj:is_player() then
			-- Admin is exempt from TNT blasts.
			if not gdac.player_is_admin(obj) then
				-- Damage player. For reasons having to do with bone placement, this
				-- needs to happen before any knockback effects. And knockback effects
				-- should only be applied if the player does not actually die.
				if obj:get_hp() > 0 then
					obj:set_hp(obj:get_hp() - damage)
					if obj:get_hp() <= 0 then
						minetest.chat_send_all("# Server: <" .. rename.gpn(obj:get_player_name()) .. "> exploded.")
					end
				end

				-- Do knockback only if player didn't die.
				if obj:get_hp() > 0 then
					-- Currently the engine has no method to set player velocity.
					-- See #2960. Instead, we knock the player back 1.0 node, and slightly
					-- upwards.
					local dir = vector.normalize(vector.subtract(obj_pos, pos))
					local moveoff = vector.multiply(dir, dist + 1.0)
					local newpos = vector.add(pos, moveoff)
					newpos = vector.add(newpos, {x = 0, y = 0.2, z = 0})
					obj:set_pos(newpos)
				end
			end
		else
			local do_damage = true
			local do_knockback = true
			local entity_drops = {}
			local luaobj = obj:get_luaentity()

			-- Ignore mobs of the same type as the one that launched the TNT boom.
			local ignore = false
			if boomdef.mob and luaobj.mob and boomdef.mob == luaobj.name then
				ignore = true
			end

			if not ignore then
				local objdef = minetest.registered_entities[luaobj.name]

				if objdef and objdef.on_blast then
					do_damage, do_knockback, entity_drops = objdef.on_blast(luaobj, damage)
				end

				if do_knockback then
					local obj_vel = obj:getvelocity()
					obj:setvelocity(calc_velocity(pos, obj_pos,
							obj_vel, radius * 10))
				end
				if do_damage then
					if not obj:get_armor_groups().immortal then
						obj:punch(obj, 1.0, {
							full_punch_interval = 1.0,
							damage_groups = {fleshy = damage},
						}, nil)
					end
				end
				for _, item in ipairs(entity_drops) do
					add_drop(drops, item)
				end
			end
		end
	end
end

local function add_effects(pos, radius, drops)
	minetest.add_particle({
		pos = pos,
		velocity = vector.new(),
		acceleration = vector.new(),
		expirationtime = 0.4,
		size = radius * 10,
		collisiondetection = false,
		vertical = false,
		texture = "tnt_boom.png",
	})
	minetest.add_particlespawner({
		amount = 64,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -10, y = -10, z = -10},
		maxvel = {x = 10, y = 10, z = 10},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 2.5,
		minsize = radius * 3,
		maxsize = radius * 5,
		texture = "tnt_smoke.png",
	})
	
	-- we just dropped some items. Look at the items entities and pick
	-- one of them to use as texture
	local texture = "tnt_blast.png" --fallback texture
	local most = 0
	for name, count in pairs(drops) do
		--local count = stack:get_count()
		if count > most then
			most = count
			local def = minetest.registered_nodes[name]
			if def and def.tiles and def.tiles[1] then
				texture = def.tiles[1]
			end
		end
	end

	minetest.add_particlespawner({
		amount = 64,
		time = 0.1,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x = -3, y = 0, z = -3},
		maxvel = {x = 3, y = 5,  z = 3},
		minacc = {x = 0, y = -10, z = 0},
		maxacc = {x = 0, y = -10, z = 0},
		minexptime = 0.8,
		maxexptime = 2.0,
		minsize = radius * 0.66,
		maxsize = radius * 2,
		texture = texture,
		collisiondetection = true,
	})
end



-- Quickly check for protection in an area.
local function check_protection(pos, radius, pname)
	-- How much beyond the radius to check for protections.
	local e = 10

	local minp = vector.new(pos.x-(radius+e), pos.y-(radius+e), pos.z-(radius+e))
	local maxp = vector.new(pos.x+(radius+e), pos.y+(radius+e), pos.z+(radius+e))

	-- Step size, to avoid checking every single node.
	-- This assumes protections cannot be smaller than this size.
	local ss = 5
	local check = minetest.test_protection

	for x=minp.x, maxp.x, ss do
		for y=minp.y, maxp.y, ss do
			for z=minp.z, maxp.z, ss do
				if check({x=x, y=y, z=z}, pname) then
					-- Protections are present.
					return true
				end
			end
		end
	end

	-- Nothing in the area is protected.
	return false
end



local function tnt_explode(pos, radius, ignore_protection, ignore_on_blast, pname)
	pos = vector.round(pos)
	-- scan for adjacent TNT nodes first, and enlarge the explosion
	local vm1 = VoxelManip()
	local p1 = vector.subtract(pos, 2)
	local p2 = vector.add(pos, 2)
	local minp, maxp = vm1:read_from_map(p1, p2)
	local a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local data = vm1:get_data()
	local count = 0
	local c_tnt = minetest.get_content_id("tnt:tnt")
	local c_tnt_burning = minetest.get_content_id("tnt:tnt_burning")
	local c_tnt_boom = minetest.get_content_id("tnt:boom")
	local c_air = minetest.get_content_id("air")

	for z = pos.z - 2, pos.z + 2 do
	for y = pos.y - 2, pos.y + 2 do
		local vi = a:index(pos.x - 2, y, z)
		for x = pos.x - 2, pos.x + 2 do
			local cid = data[vi]
			if cid == c_tnt or cid == c_tnt_boom or cid == c_tnt_burning then
				count = count + 1
				data[vi] = c_air
			end
			vi = vi + 1
		end
	end
	end
	
	-- 'count' may be 0 if the bomb exploded in a protected area -- in which case no tnt boom
	-- will have been created. Clamping 'count' to a minimum of 1 fixes the problem.
	-- [MustTest]
	if count < 1 then
		count = 1
	end
  
  -- Clamp to avoid massive explosions.
  if count > 64 then count = 64 end

	vm1:set_data(data)
	vm1:write_to_map()

	-- recalculate new radius
	radius = math.floor(radius * math.pow(count, 0.60))

	-- If no protections are present, we can optimize by skipping the protection
	-- check for individual nodes. If we have a small radius, then don't bother.
	if radius > 8 then
		if not check_protection(pos, radius, pname) then
			ignore_protection = true
		end
	end

	-- perform the explosion
	local vm = VoxelManip()
	local pr = PseudoRandom(os.time())
	p1 = vector.subtract(pos, radius)
	p2 = vector.add(pos, radius)
	minp, maxp = vm:read_from_map(p1, p2)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local drops = {}
	local on_blast_queue = {}
  local on_destruct_queue = {}
  local on_after_destruct_queue = {}
  local fire_locations = {}

	local c_fire = minetest.get_content_id("fire:basic_flame")
  
	for z = -radius, radius do
	for y = -radius, radius do
	local vi = a:index(pos.x + (-radius), pos.y + y, pos.z + z)
	for x = -radius, radius do
		local r = vector.length(vector.new(x, y, z))
    local r2 = radius
    
    -- Roughen the walls a bit.
    if pr:next(0, 6) == 0 then
      r2 = radius - 0.8
    end
      
    if r <= r2 then
			local cid = data[vi]
			local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
			if cid ~= c_air then
				data[vi] = destroy(drops, p, cid, c_air, c_fire,
					on_blast_queue, on_destruct_queue, on_after_destruct_queue,
          fire_locations, ignore_protection, ignore_on_blast, pname)
			end
		end
    
		vi = vi + 1
	end
	end
	end
  
  -- Call on_destruct callbacks.
  for k, v in ipairs(on_destruct_queue) do
    v.on_destruct(v.pos)
  end

	vm:set_data(data)
	vm:write_to_map()
	vm:update_map()
	vm:update_liquids()

	-- Check unstable nodes for everything within blast effect.
	local minr = {x=pos.x-(radius+2), y=pos.y-(radius+2), z=pos.z-(radius+2)}
	local maxr = {x=pos.x+(radius+2), y=pos.y+(radius+2), z=pos.z+(radius+2)}

	for z=minr.z, maxr.z do
		for x=minr.x, maxr.x do
			for y=minr.y, maxr.y do
				local p = {x=x, y=y, z=z}
				local d = vector.distance(pos, p)
				if d < radius+2 and d > radius-2 then
					-- Check for nodes with 'falling_node' in groups.
					minetest.check_single_for_falling(p)

					-- Now check using additional falling node logic.
					instability.check_unsupported_single(p)
				end
			end
		end
	end

	-- Execute after-destruct callbacks.
  for k, v in ipairs(on_after_destruct_queue) do
    v.after_destruct(v.pos, v.oldnode)
  end

	for _, queued_data in ipairs(on_blast_queue) do
		local dist = math.max(1, vector.distance(queued_data.pos, pos))
		local intensity = (radius * radius) / (dist * dist)
		local node_drops = queued_data.on_blast(queued_data.pos, intensity)
		if node_drops then
			for _, item in ipairs(node_drops) do
				add_drop(drops, item)
			end
		end
	end
  
  -- Initialize flames.
  local fdef = minetest.registered_nodes["fire:basic_flame"]
  if fdef and fdef.on_construct then
    for k, v in ipairs(fire_locations) do
      fdef.on_construct(v)
    end
  end

	return drops, radius
end

--[[
{
	radius,
	ignore_protection,
	ignore_on_blast,
	damage_radius,
	disable_drops,
	name, -- Name to use when testing protection. Defaults to "".
}
--]]

function tnt.boom(pos, def)
	pos = vector.round(pos)
	-- The TNT code crashes sometimes, for no particular reason?
	local func = function()
		tnt.boom_impl(pos, def)
	end
	pcall(func)
end

-- Not to be called externally.
function tnt.boom_impl(pos, def)
	if def.make_sound == nil or def.make_sound == true then
		minetest.sound_play("tnt_explode", {pos = pos, gain = 1.5, max_hear_distance = 2*64})
	end

	-- Make sure TNT never somehow gets keyed to the admin!
	if def.name and def.name == "MustTest" then
		def.name = nil
	end
	
	if not minetest.test_protection(pos, "") then
		local node = minetest.get_node(pos)
		-- Never destroy death boxes.
		if node.name ~= "bones:bones" then
			minetest.set_node(pos, {name = "tnt:boom"})
		end
	end
	
	local drops, radius = tnt_explode(pos, def.radius, def.ignore_protection, def.ignore_on_blast, def.name or "")
	-- append entity drops
	local damage_radius = (radius / def.radius) * def.damage_radius
	entity_physics(pos, damage_radius, drops, def)
	if not def.disable_drops then
		eject_drops(drops, pos, radius)
	end
	add_effects(pos, radius, drops)
  
  minetest.log("action", "A TNT explosion occurred at " .. minetest.pos_to_string(pos) ..
    " with radius " .. radius)
end
