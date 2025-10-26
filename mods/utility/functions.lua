
-- Localize for performance.
local math_random = math.random
local math_min = math.min
local math_max = math.max



function utility.wear_tool_with_feedback(params)
	-- First, get the stack definition, before adding wear.
	local def = params.item:get_definition()
	local itemname = params.item:get_name()
	if not def then return params.item end -- No def? No go.
	if not minetest.registered_tools[itemname] then return params.item end

	local total_uses = 0
	local total_wear = 0
	local current_wear = params.item:get_wear()

	-- Add the wear (damage).
	if params.wear then
		params.item:add_wear(params.wear)
		total_uses = math.floor(65536 / params.wear)
		total_wear = params.wear
	elseif params.total_uses then
		params.item:add_wear_by_uses(params.total_uses)
		total_uses = params.total_uses
		total_wear = math.floor(65536 / params.total_uses)
	end

	-- Count will be 0 if wear broke the tool.
	local count = params.item:get_count()
	local remaining_uses = math.floor((65536 - current_wear) / total_wear) - 1
	local sound = def.sound or {}
	local breaksound = sound.breaks or "default_tool_breaks"

	-- Play broken tool sound.
	if count == 0 then
		local player = params.user
		local pname = player:get_player_name()
		local pos = player:get_pos()
		local desc = def.description

		minetest.chat_send_player(pname, "# Server: Your " .. desc .. " is lost.")
		minetest.sound_play(breaksound, {pos=pos, gain=1.0}, true)
	elseif remaining_uses <= 10 then
		-- Warn tool will soon break.
		local player = params.user
		local pos = player:get_pos()
		local pname = player:get_player_name()
		local desc = def.description
		local spamkey = pname .. ":" .. itemname .. ":breaks"

		if not spam.test_key(spamkey) then
			minetest.chat_send_player(pname,
				"# Server: Your " .. desc .. " is about to break!")
			minetest.sound_play(breaksound, {pos=pos, gain=0.5}, true)
			spam.mark_key(spamkey, 5)
		end
	end

	-- Return itemstack.
	return params.item
end



-- Use this to define 'on_blast' for nodes that should be knocked down by TNT
-- to prevent them from being left hanging in air (like glow obsidian, which is
-- normally immovable).
function utility.make_knockdown_on_blast(args)
	return function(pos)
		-- Note: using 'minetest.after' to ensure this code takes lower priority
		-- over code that runs in the same stack frame as the actual bast.
		minetest.after(0, function()
			if minetest.test_protection(pos, "") then
				return
			end
			if minetest.get_node(pos).name ~= args.name then
				return
			end

			local airs = {
				vector.offset(pos, 0, 1, 0),
				vector.offset(pos, 0, -1, 0),
				vector.offset(pos, 1, 0, 0),
				vector.offset(pos, -1, 0, 0),
				vector.offset(pos, 0, 0, 1),
				vector.offset(pos, 0, 0, -1),
			}

			local count = 0
			local get_node = minetest.get_node

			for k = 1, #airs do
				local nn = get_node(airs[k]).name
				if nn == "air" then
					count = count + 1
				end
			end

			if count >= args.count then
				minetest.spawn_falling_node(pos, args.force_drop)
			end
		end)
	end
end



-- Get the object ref of the first client that has the "server" priv, or nil.
function utility.get_first_available_admin()
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if minetest.check_player_privs(v, "server") then
			return v
		end
	end
end

-- Get array of all admin-level clients currently connected.
function utility.get_connected_admins()
	local tb = {}
	local players = minetest.get_connected_players()
	for k, v in ipairs(players) do
		if minetest.check_player_privs(v, "server") then
			tb[#tb + 1] = v
		end
	end
	return tb
end

-- Get name of first connected admin, or whatever is in config, or "singleplayer".
-- Try to use this function instead of writing the actual admin name everywhere.
function utility.get_admin_name()
	local admin = utility.get_first_available_admin()
	if admin then
		return admin:get_player_name()
	end
	return minetest.settings:get("name") or "singleplayer"
end



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



function utility.check_hanging_node(p, n, group_rating)
	local def = core.registered_nodes[n.name]
	local p2 = vector.offset(p, 0, 1, 0)

	local nn = core.get_node(p2).name
	local def2 = core.registered_nodes[nn]

	-- Node can hang from a node with the same name.
	if n.name == nn then
		return true
	end

	-- Node can hang from another hanging node above it.
	if ((def2.groups or {}).hanging_node or 0) ~= 0 then
		return true
	end

	-- Node can hang from any solid node.
	if def2 and def2.walkable then
		return true
	end

	return false
end



function utility.check_standing_node(p, n, group_rating)
	local def = core.registered_nodes[n.name]
	local p2 = vector.offset(p, 0, -1, 0)

	local nn = core.get_node(p2).name
	local def2 = core.registered_nodes[nn]

	-- Node can stand on a node with the same name.
	if n.name == nn then
		return true
	end

	-- Node can stand on another standing node below it.
	if ((def2.groups or {}).handing_node or 0) ~= 0 then
		return true
	end

	-- Node can stand on any solid node.
	if def2 and def2.walkable then
		return true
	end

	return false
end



-- Use this to damage a player, instead of player:set_hp(), because this takes
-- player's current armor groups into account.
function utility.damage_player(player, damage_type, damage, reason)
	-- Inform 3D armor what the reason for this punch is.
	-- Cannot pass the PlayerHPChangeReason table through :punch()!
	-- Note: reason.type will be "punch", per 3D armor code.
	local rt = type(reason)

	if rt == "string" or rt == "nil" then
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

	local parent = player:get_attach()
	if parent then
		local ent = parent:get_luaentity()
		if ent then
			if ent.name == "3d_armor:pvpduel_respawn" then
				ent:detach_player()
				return "bed"
			end
		end
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



-- Process Lua array, removing elements as we go. The array is modified in-place.
function utility.array_remove(t, keep)
	local j, n, c = 1, #t, 0

	for i = 1, n do
		if keep(t, i, j) then
			-- Move i's kept value to j's position, if it's not already there.
			if (i ~= j) then
				t[j] = t[i]
				t[i] = nil
			end
			j = j + 1 -- Increment position of where we'll place the next kept value.
		else
			c = c + 1 -- Increment number removed.
			t[i] = nil
		end
	end

	return t, c
end
