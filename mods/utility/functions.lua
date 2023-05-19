
-- Localize for performance.
local math_random = math.random
local math_min = math.min
local math_max = math.max



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
		damage_groups = {[damage_type] = damage},
	}, nil)
	-- Note: never set 'damage_groups.from_arrow' here.
	-- That has special meaning to the cityblock code!
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
