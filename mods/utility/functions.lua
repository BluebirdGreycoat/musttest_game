
-- Localize for performance.
local math_random = math.random
local math_min = math.min
local math_max = math.max

-- Copied from builtin so we can actually USE the damn code. >:(
-- Builtin has been getting very modder-unfriendly!
function utility.drop_attached_node(p)
	local n = core.get_node(p)
	local drops = core.get_node_drops(n, "")
	local def = core.registered_items[n.name]
	if def and def.preserve_metadata then
		local oldmeta = core.get_meta(p):to_table().fields
		-- Copy pos and node because the callback can modify them.
		local pos_copy = vector.copy(p)
		local node_copy = {name=n.name, param1=n.param1, param2=n.param2}
		local drop_stacks = {}
		for k, v in pairs(drops) do
			drop_stacks[k] = ItemStack(v)
		end
		drops = drop_stacks
		def.preserve_metadata(pos_copy, node_copy, oldmeta, drops)
	end
	if def and def.sounds and def.sounds.fall then
		core.sound_play(def.sounds.fall, {pos = p}, true)
	end
	core.remove_node(p)
	for _, item in pairs(drops) do
		local pos = {
			x = p.x + math.random()/2 - 0.25,
			y = p.y + math.random()/2 - 0.25,
			z = p.z + math.random()/2 - 0.25,
		}
		core.add_item(pos, item)
	end
end

-- Copied from builtin so we can actually USE the damn code. >:(
-- Builtin has been getting very modder-unfriendly!
function utility.check_attached_node(p, n, group_rating)
	local def = core.registered_nodes[n.name]
	local d = vector.zero()
	if group_rating == 3 then
		-- always attach to floor
		d.y = -1
	elseif group_rating == 4 then
		-- always attach to ceiling
		d.y = 1
	elseif group_rating == 2 then
		-- attach to facedir or 4dir direction
		if (def.paramtype2 == "facedir" or
				def.paramtype2 == "colorfacedir") then
			-- Attach to whatever facedir is "mounted to".
			-- For facedir, this is where tile no. 5 point at.

			-- The fallback vector here is in case 'facedir to dir' is nil due
			-- to voxelmanip placing a wallmounted node without resetting a
			-- pre-existing param2 value that is out-of-range for facedir.
			-- The fallback vector corresponds to param2 = 0.
			d = core.facedir_to_dir(n.param2) or vector.new(0, 0, 1)
		elseif (def.paramtype2 == "4dir" or
				def.paramtype2 == "color4dir") then
			-- Similar to facedir handling
			d = core.fourdir_to_dir(n.param2) or vector.new(0, 0, 1)
		end
	elseif def.paramtype2 == "wallmounted" or
			def.paramtype2 == "colorwallmounted" then
		-- Attach to whatever this node is "mounted to".
		-- This where tile no. 2 points at.

		-- The fallback vector here is used for the same reason as
		-- for facedir nodes.
		d = core.wallmounted_to_dir(n.param2) or vector.new(0, 1, 0)
	else
		d.y = -1
	end
	local p2 = vector.add(p, d)
	local nn = core.get_node(p2).name
	local def2 = core.registered_nodes[nn]
	if def2 and not def2.walkable then
		return false
	end
	return true
end



-- Use this to damage a player, instead of player:set_hp(), because this takes
-- player's current armor groups into account.
function utility.damage_player(player, damage_type, damage, reason)
	-- Inform 3D armor what the reason for this punch is.
	-- Cannot pass the PlayerHPChangeReason table through :punch()!
	-- Note: reason.type will be "punch", per 3D armor code.
	local rt = type(reason)

	if rt == "string" or rt == nil then
		armor.notify_punch_reason({reason = reason or damage_type})
	elseif rt == "table" then
		local nr = {reason = reason.reason or ""}
		for k, v in pairs(reason) do
			nr[k] = v
		end
		armor.notify_punch_reason(nr)
	end

	player:punch(player, 1.0, {
		full_punch_interval = 1.0,
		damage_groups = {[damage_type] = damage, from_env = 1},
	}, nil)
	-- Note: never set 'damage_groups.from_arrow' here.
	-- That has special meaning to the cityblock code!
	--
	-- Note: 'from_env' informs the cityblock code that this punch should NOT be
	-- treated as PvP. This is damage from the environment, OR from a mob.
end



function utility.detach_player_with_message(player)
	local k = default.detach_player_if_attached(player)
	if k then
		local t = player:get_player_name()
		if k == "cart" then
			minetest.chat_send_all("# Server: Someone threw <" .. rename.gpn(t) .. "> out of a minecart.")
		elseif k == "boat" then
			minetest.chat_send_all("# Server: Boater <" .. rename.gpn(t) .. "> was tossed overboard.")
		elseif k == "sled" then
			minetest.chat_send_all("# Server: Someone kicked <" .. rename.gpn(t) .. "> off a sled.")
		elseif k == "bed" then
			minetest.chat_send_all("# Server: <" .. rename.gpn(t) .. "> was rudely kicked out of bed.")
		end
	end
end



-- Function to find an ignore node NOT beyond the world edge.
-- This is useful when we must check for `ignore`, but don't want to be confused at the edge of the world.
function utility.find_node_near_not_world_edge(pos, rad, node)
	local minp = vector.subtract(pos, rad)
	local maxp = vector.add(pos, rad)

	minp.x = math_max(minp.x, -30912)
	minp.y = math_max(minp.y, -30912)
	minp.z = math_max(minp.z, -30912)

	maxp.x = math_min(maxp.x, 30927)
	maxp.y = math_min(maxp.y, 30927)
	maxp.z = math_min(maxp.z, 30927)

	local positions = minetest.find_nodes_in_area(minp, maxp, node)

	if (#positions > 0) then
		return positions[math_random(1, #positions)]
	end
end


local function add_effects(pos, radius)
	minetest.add_particlespawner({
		amount = 8,
		time = 0.5,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x=-10, y=-10, z=-10},
		maxvel = {x=10,  y=10,  z=10},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		texture = "tnt_smoke.png",
	})
end

function utility.shell_boom(pos)
	minetest.sound_play("throwing_shell_explode", {pos=pos, gain=1.5, max_hear_distance=2*64}, true)

  -- Don't destroy things.
  if minetest.get_node(pos).name == "air" then
    minetest.set_node(pos, {name="tnt:boom"})
    minetest.get_node_timer(pos):start(0.5)
  end

  add_effects(pos, 1)
end



-- Note: this works for boats, too.
-- Returns [""] if player wasn't attached. Otherwise, name of previous attachment type.
function default.detach_player_if_attached(player)
	local pname = player:get_player_name()

	-- Player might be in bed! Get them out properly.
	if beds.kick_one_player(pname) then
		return "bed"
	end

	local ents = minetest.get_objects_inside_radius(utility.get_foot_pos(player:get_pos()), 2)

	local result = ""
	for k, obj in ipairs(ents) do
		local ent = obj:get_luaentity()
		if ent and ent.name == "carts:cart" then
			-- Must detach player from cart.
			carts:manage_attachment(player, nil)
			result = "cart"
		elseif ent and ent.name == "boats:boat" then
			if ent.driver and ent.driver == player then
				-- Since boat driver == player, this should always detach.
				boats.on_rightclick(ent, player)
				result = "boat"
			end
		elseif ent and ent.name == "sleds:sled" then
			if ent.driver and ent.driver == player then
				sleds.on_rightclick(ent, player)
				result = "sled"
			end
		end
	end

	return result
end



-- Override Minetest's builtin knockback calculation.
-- Warning: 'player' can also be any other entity, including a mob.
function minetest.calculate_knockback(player, hitter, tflp, tcaps, dir, distance, damage)
	-- Get knockback value from weapon capabilities.
	local knockback = (tcaps.damage_groups and tcaps.damage_groups.knockback) or 0
	tflp = math.min(4.0, math.max(tflp, 0))

	--minetest.log('knockback: ' .. knockback .. ', tflp: ' .. tflp)

	if knockback <= 0 then
		return 0.0
	end

	-- Only on full punch.
	--if tflp < 4.0 then
	--	return 0.0
	--end

	-- Divide by 100 to get meters per second.
	local res = knockback / 100

	if distance < 2.0 then
		res = res * 1.1 -- more knockback when closer
	elseif distance > 4.0 then
		res = res * 0.9 -- less when far away
	end

	return res * 5 * (tflp / 4)
end
