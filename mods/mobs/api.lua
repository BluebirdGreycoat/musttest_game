
-- File rewritten to be live-reloadable August 14, 2018 by MustTest.
-- `mobs.registered' is checked throughout file, but only set `true' @ END!

-- Localize functions.
local pi = math.pi
local square = math.sqrt
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local abs = math.abs
local min = math.min
local max = math.max
local ceil = math.ceil
local floor = math.floor
local random = math.random
local v_round = vector.round
local v_equals = vector.equals
local v_distance = vector.distance
local v_add = vector.add
local rad = math.rad
local deg = math.deg



-- For debug reports.
local function report(self, msg, range)
	if mobs.enable_reports then
		return
	end
	if self.name ~= mobs.report_name then
		return
	end
	local pname = gdac.name_of_admin
	if minetest.is_singleplayer() then
		pname = "singleplayer"
	end
	local player = minetest.get_player_by_name(pname)

	-- Range limit so I only get reports from mobs nearby.
	if player then
		local s = self.object:get_pos()
		local p = player:get_pos()
		if vector.distance(s, p) < (range or 50) then
			minetest.chat_send_player(pname, msg)
		end
	end
end

-- Export.
mobs.report = report



-- Function to tell mob which direction to turn to face target.
-- Add pi to the returned yaw to face in the opposite direction.
-- Fixed to use atan2 correctly by MustTest.
local function yaw_to_pos(self, target, pos)
	local x = target.x - pos.x
	local z = target.z - pos.z

	local yaw = atan2(z, x) - self.rotate
	yaw = yaw - (pi / 2)
	return yaw
end



-- Function which takes a yaw value and "squares" it so it points in one of the
-- 4 cardinal directions. Used to make mobs face along one of the horizontal
-- axes, instead of diagonally, for some special situations.
local function square_yaw(yaw)
	local pi2 = pi * 2
	if yaw < 0 then yaw = yaw + pi2 end
	if yaw > pi2 then yaw = yaw - pi2 end
	yaw = deg(yaw)

	if yaw <= 45 or yaw > 315 then
		yaw = 0 -- North.
	elseif yaw <= 315 and yaw > 225 then
		yaw = 270 -- East.
	elseif yaw <= 225 and yaw > 135 then
		yaw = 180 -- South.
	elseif yaw <= 135 and yaw > 45 then
		yaw = 90 -- West.
	end

	return rad(yaw)
end



-- Settings.
local damage_enabled =  true
local peaceful_only =   false
local disable_blood =   false
local mobs_drop_items = minetest.settings:get_bool("mobs_drop_items") ~= false
local mobs_griefing =   true
local creative =        false
local spawn_protected = minetest.settings:get_bool("mobs_spawn_protected") ~= false
local remove_far =      false
local difficulty =      1.0
local show_health =     true
local max_per_block =   tonumber(minetest.settings:get("max_objects_per_block") or 99)
local mob_chance_multiplier = tonumber(minetest.settings:get("mob_chance_multiplier") or 1)
local default_knockback = 1



-- Used by spawner function.
mobs.spawn_protected = spawn_protected

-- Legacy.
if not mobs.invis then
	mobs.invis = {}
end

function mobs.is_invisible(self, pname)
	-- Administrative invisibility is paramount.
	if gdac_invis.is_invisible(pname) then
		return true
	end

	if self.ignore_invisibility then
		return
	end

	return cloaking.is_cloaked(pname)
end

-- creative check
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function mobs.is_creative(name)
	return creative_mode_cache or minetest.check_player_privs(name, {creative = true})
end

-- Peaceful mode message so players will know there are no monsters.
-- Perform registration only ONCE.
if not mobs.registered and peaceful_only then
	minetest.register_on_joinplayer(function(player)
		minetest.chat_send_player(player:get_player_name(),
			"# Server: Peaceful mode active - no new monsters will spawn.")
	end)
end

-- calculate aoc range for mob count
local aoc_range = tonumber(minetest.settings:get("active_block_range")) * 16

-- Pathfinding settings.
local enable_pathfinding = true
local stuck_timeout = 3

-- Note: stuck path timeout is determined based on the length of the path, and
-- is a mob-internal property [MustTest].

-- Default nodes:
local node_fire = "fire:basic_flame"
local node_permanent_flame = "fire:permanent_flame"
local node_ice = "default:ice"
local node_snowblock = "default:snowblock"
local node_snow = "default:snow"
local node_pathfinder_place = "default:cobble"

mobs.fallback_node = "default:cobble"



-- play sound
local function mob_sound(self, sound)
	if sound then
		local dist = self.sounds.distance or 20
		ambiance.sound_play(sound, self.object:get_pos(), 1.0, dist)

		-- This isn't working!
		--minetest.sound_play(sound, {
		--	object = self.object,
		--	gain = 1.0,
		--	max_hear_distance = self.sounds.distance
		--})
	end
end



local function set_state(self, newstate)
	local oldstate = self.state or ""
	if newstate ~= oldstate then
		local sm = mobs.state_machine

		if sm[oldstate] and sm[oldstate].exit then
			sm[oldstate].exit(self)
		end

		self.state = newstate
		self.substate = ""

		if sm[newstate] and sm[newstate].enter then
			sm[newstate].enter(self)
		end

		report(self, "stack: " .. self.state .. " (" .. self.substate .. ") -> " ..
			table.concat(self.state_stack or {}, ","))
	end
end



-- State transition function [MustTest]. Do not set mob state designation
-- manually, call this function instead. It handles state transitions, etc.
local function transition_state(self, newstate)
	self.state_stack = {}
	set_state(self, newstate)
end

-- Export.
mobs.transition_state = function(...)
	transition_state(...)
end

-- States can have "substates". This is basically just an alternate main()
-- function, so states can swap between different main() functions as needed.
-- There are no exit() or enter() calls here.
local function transition_substate(self, newsub)
	if newsub ~= self.substate then
		self.substate = newsub

		report(self, "stack: " .. self.state .. " (" .. self.substate .. ") -> " ..
			table.concat(self.state_stack or {}, ","))
	end
end

-- Export.
mobs.transition_substate = function(...)
	transition_substate(...)
end



local function push_state(self, newstate)
	if not self.state_stack then
		self.state_stack = {}
	end

	if self.state and self.state ~= "" then
		table.insert(self.state_stack, 1, self.state)
	end

	set_state(self, newstate)
end



local function pop_state(self)
	if not self.state_stack then
		self.state_stack = {}
	end

	local state = self.state_stack[1]
	if state then
		table.remove(self.state_stack, 1)
		set_state(self, state)
		return
	end

	set_state(self, "")
end



local function do_attack(self, target)
	if self.state == "attack" then
		return
	end

	if target and target:get_pos() then
		self.attack = target
		transition_state(self, "attack")
		return
	else
		transition_state(self, "")
		return
	end
end



-- Check if the node at a position has 'walkable = true'.
local function pos_walkable(pos)
	local nn = minetest.get_node(pos).name
	local dd = minetest.registered_nodes[nn]
	return dd.walkable
end



local function set_velocity(self, v)
	local yaw = (self.object:get_yaw() or 0) + (self.rotate or 0)
	local vel = self.object:get_velocity()

	local y = 0
	if vel then
		y = vel.y or 0
	end

	-- Fix crash: 2020-09-12 14:26:15: ERROR[Main]: ServerError: AsyncErr:
	-- ServerThread::run Lua: Runtime error from mod 'griefer' in callback
	-- luaentity_Step(): Invalid float vector dimension range 'y' (expected
	-- -2.14748e+06 < y < 2.14748e+06 got -1.96364e+12).
	y = max(min(y, 200), -200)

	self.object:set_velocity({
		x = sin(yaw) * -v,
		y = y,
		z = cos(yaw) * v
	})

	-- Store the requested velocity.
	local o = self.wanted_velocity or 0
	self.wanted_velocity = v
	if v <= 0 and o > 0 then
		self.stand_timer = 0
	end
	if v <= 0 then
		self.stuck_timer = 0
	end
end



local function get_velocity(self)
	local v = self.object:get_velocity()
	return ((v.x * v.x) + (v.z * v.z)) ^ 0.5
end



-- set and return valid yaw
local function set_yaw(self, yaw, delay)

	if not yaw or yaw ~= yaw then
		yaw = 0
	end

	delay = delay or 0

	if delay == 0 then
		self.object:set_yaw(yaw)
		return yaw
	end

	self.target_yaw = yaw
	self.delay = delay

	return self.target_yaw
end



-- global function to set mob yaw
function mobs.yaw(self, yaw, delay)
	set_yaw(self, yaw, delay)
end



local function set_animation(self, anim, speed)
	if not self.animation or not anim then
		return
	end

	self.animation.current = self.animation.current or ""

	-- only set different animation for attacks when setting to same set
	if anim ~= "punch" and anim ~= "shoot"
			and string.find(self.animation.current, anim) then
		return
	end

	-- check for more than one animation
	local num = 0

	for n = 1, 4 do

		if self.animation[anim .. n .. "_start"]
		and self.animation[anim .. n .. "_end"] then
			num = n
		end
	end

	-- choose random animation from set
	if num > 0 then
		num = random(0, num)
		anim = anim .. (num ~= 0 and num or "")
	end

	if anim == self.animation.current
			or not self.animation[anim .. "_start"]
			or not self.animation[anim .. "_end"] then
		return
	end

	self.animation.current = anim

	local anim_speed = (speed or
		self.animation[anim .. "_speed"] or
		self.animation.speed_normal or 15)

	self.object:set_animation({
		x = self.animation[anim .. "_start"],
		y = self.animation[anim .. "_end"]},
		anim_speed,
		0, self.animation[anim .. "_loop"] ~= false)
end

-- Above function exported for "mount.lua".
function mobs.set_animation(self, anim)
	set_animation(self, anim)
end



-- Calculate distance.
local function get_distance(a, b)
	local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
	return square(x * x + y * y + z * z)
end



-- Check line of sight using raycasting (thanks Astrobe).
local function raycast_los(self, pos1, pos2)
	local ray = minetest.raycast(pos1, pos2, false, true)
	local thing = ray:next()

	while thing do
		if thing.type == "node" then
			local name = minetest.get_node(thing.under).name
			local ndef = minetest.registered_nodes[name]

			if ndef and ndef.walkable then
				return false
			end
		end

		thing = ray:next()
	end

	return true
end



-- Export.
function mobs.line_of_sight(self, pos1, pos2)
	return raycast_los(self, pos1, pos2)
end



-- Are we flying in what we are suppose to? (taikedz)
local function flight_check(self, pos_w)
	if type(self.fly_in) == "string" and self.standing_in == self.fly_in then
		return true
	elseif type(self.fly_in) == "table" then
		for _, fly_in in ipairs(self.fly_in) do
			if self.standing_in == fly_in then
				return true
			end
		end
	end

	local def = minetest.reg_ns_nodes[self.standing_in]
	if not def then return false end -- nil check

	-- stops mobs getting stuck inside stairs and plantlike nodes
	if def.drawtype ~= "airlike"
			and def.drawtype ~= "liquid"
			and def.drawtype ~= "flowingliquid" then
		return true
	end

	-- Enables mobs to fly in non-walkable stuff like thin "default:snow".
	if not def.walkable then
		return true
	end

	return false
end



-- custom particle effects
local function effect(
	pos, amount, texture, min_size, max_size, radius, gravity, glow, fall)

	radius = radius or 2
	min_size = min_size or 0.5
	max_size = max_size or 1
	gravity = gravity or -10
	glow = glow or 0

	if fall == true then
		fall = 0
	elseif fall == false then
		fall = radius
	else
		fall = -radius
	end

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = fall, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = 0, y = gravity, z = 0},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end



-- Update nametag colour.
local function update_tag(self)

	local col = "#00FF00"
	local qua = self.hp_max / 4

	if self.health <= floor(qua * 3) then
		col = "#FFFF00"
	end

	if self.health <= floor(qua * 2) then
		col = "#FF6600"
	end

	if self.health <= floor(qua) then
		col = "#FF0000"
	end

	self.object:set_properties({
		nametag = self.nametag,
		nametag_color = col,
	})
end



-- drop items
local function item_drop(self, cooked)

	-- check for nil or no drops
	if not self.drops or #self.drops == 0 then
		return
	end

	-- no drops if disabled by setting
	if not mobs_drop_items then return end

	-- no drops for child mobs
	if self.child then return end

	local obj, item, num
	local pos = self.object:get_pos()

	for n = 1, #self.drops do

		if random(1, self.drops[n].chance) == 1 then

			num = random(self.drops[n].min or 0, self.drops[n].max or 1)
			item = self.drops[n].name

			-- cook items when true
			if cooked then

				local output = minetest.get_craft_result({
					method = "cooking", width = 1, items = {item}})

				if output and output.item and not output.item:is_empty() then
					item = output.item:get_name()
				end
			end

			-- add item if it exists
			obj = minetest.add_item(pos, ItemStack(item .. " " .. num))

			if obj and obj:get_luaentity() then

				obj:set_velocity({
					x = random(-10, 10) / 9,
					y = 6,
					z = random(-10, 10) / 9,
				})
			elseif obj then
				obj:remove() -- item does not exist
			end
		end
	end

	self.drops = {}
end



-- check if mob is dead or only hurt
local function check_for_death(self, cause, cmi_cause)

	-- has health actually changed?
	if self.health == self.old_health and self.health > 0 then
		return
	end

	self.old_health = self.health

	-- still got some health? play hurt sound
	if self.health > 0 then

		mob_sound(self, self.sounds.damage)

		-- make sure health isn't higher than max
		if self.health > self.hp_max then
			self.health = self.hp_max
		end

		-- backup nametag so we can show health stats
		if not self.nametag2 then
			self.nametag2 = self.nametag or ""
		end

		if show_health and self.show_health ~= false and
				(cmi_cause and cmi_cause.type == "punch") then

			local pc = floor((self.health / self.hp_max) * 100)

			self.htimer = 2
			self.nametag = "♥ " .. pc .. "%"

			update_tag(self)
		end

		return false
	end

	-- Mob will die, check if we were attacked.
	if cause == "hit" then
		if self.last_attacked_by and self.last_attacked_by ~= "" then
			local attacked_by = minetest.get_player_by_name(self.last_attacked_by)
			if attacked_by then
				mobs.player_killed_mob(self, attacked_by)
			end
		end
	end

	-- only drop items if weapon is of sufficient level to overcome mob's armor level
	local can_drop = true
	if cmi_cause and cmi_cause.tool_capabilities then
		local max_drop_level = (cmi_cause.tool_capabilities.max_drop_level or 0)

		-- Increase weapon's max drop level if rank is level 7.
		local tool_level = 1
		if cmi_cause.wielded then
			local tool_meta = cmi_cause.wielded:get_meta()
			tool_level = tonumber(tool_meta:get_string("tr_lastlevel")) or 1
		end
		if tool_level >= 7 then
			max_drop_level = max_drop_level + 1
		end

		if (max_drop_level) < (self.armor_level or 0) then
			can_drop = false
		end
	end

	-- mob doesn't drop anything if killed by sunlight
	-- this fixes the problem of drops being scattered around after sunrise
	-- caused by icemen and sandmen
	if cause == "light" then
		can_drop = false
	end

	if can_drop then
		-- dropped cooked item if mob died in lava
		if cause == "lava" or cause == "fire" then
			item_drop(self, true)
		else
			item_drop(self, nil)
		end
	end

	mob_sound(self, self.sounds.death)

	local pos = self.object:get_pos()

	-- execute custom death function
	if self.on_die then

		self.on_die(self, pos)

		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return true
	end

	-- default death function and die animation (if defined)
	if self.animation
	and self.animation.die_start
	and self.animation.die_end then

		local frames = self.animation.die_end - self.animation.die_start
		local speed = self.animation.die_speed or 15
		local length = max(frames / speed, 0)

		self.attack = nil
		self.v_start = false
		self.blinktimer = 0
		self.passive = true
		transition_state(self, "die")
		set_velocity(self, 0)
		set_animation(self, "die")

		minetest.after(length, function(self)
			-- Mark for removal as last action on mob_step().
			-- Note: this is deferred for a bit!
			self.mkrm = true
		end, self)
	else
		-- Mark for removal as last action on mob_step().
		self.mkrm = true
	end

	effect(pos, 20, "tnt_smoke.png")

	return true
end



-- Check if within physical map limits (-30911 to 30927).
local function within_limits(pos, radius)
	if (pos.x - radius) > -30913
        and (pos.x + radius) <  30928
        and (pos.y - radius) > -30913
        and (pos.y + radius) <  30928
        and (pos.z - radius) > -30913
        and (pos.z + radius) <  30928 then
		return true -- Within limits.
	end
	return false -- Beyond limits.
end



-- Returns true if node can deal damage to self.
local function is_node_dangerous(self, nodename, ndef)
	if nodename == "air" then
		return false
	end

	if not ndef then
		ndef = minetest.registered_nodes[nodename]
	end
	if not ndef then
		return true
	end

	local groups = ndef.groups

	local water = groups.water or 0
	local lava = groups.lava or 0
	local fire = groups.fire or 0

	if (self.water_damage or 0) > 0 and water ~= 0 then
		return true
	end

	if (self.lava_damage or 0) > 0 and lava ~= 0 then
		return true
	end

	if (self.fire_damage or 0) > 0 and fire ~= 0 then
		return true
	end

	if ndef.damage_per_second > 0 then
		return true
	end

	return false
end



-- Get node but use fallback for nil or unknown.
local function node_ok(pos, fallback)

	fallback = fallback or mobs.fallback_node

	local node = minetest.get_node_or_nil(pos)

	if node and minetest.registered_nodes[node.name] then
		return node
	end

	return minetest.registered_nodes[fallback]
end



-- This function moves a mob to the center of the X,Z column.
-- True is returned to indicate the mob is moving; otherwise false.
-- Note: the point is to get the mob's collision box entirely inside the X,Z
-- plain of the node it is standing on; if this can't be achieved, the
-- pathfinder WILL exhibit bugs!
local function keep_mob_centered(self, ss)
	local s = ss or self.object:get_pos()
	local c = vector.round(s)

	-- Have mob position himself nearer the center of the node.
	if abs(s.x - c.x) > 0.2 or abs(s.z - c.z) > 0.2 then
		set_yaw(self, yaw_to_pos(self, c, s))
		set_velocity(self, 0.2)
		set_animation(self, "walk", 5)
		return true
	end
end



-- This function causes a mob to walk slowly toward its facing direction until
-- it detects an obstacle (of any kind). It returns true to indicate the mob is
-- moving.
local function walk_mob_forward(self)
	-- Function is not defined yet.
	if not mobs.facing_wall_or_pit(self) then
		set_velocity(self, 0.5)
		set_animation(self, "walk", 5)
		return true
	end
end



local function show_position(p)
	-- Keep this particle code for debugging purposes [MustTest].
	-- Spawn particle at actual computed position without rounding.
	local pname = "singleplayer"
	if not minetest.is_singleplayer() then
		pname = gdac.name_of_admin
	end

	utility.original_add_particle({
		playername = pname,
		pos = p,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.5,
		size = 1,
		collisiondetection = false,
		vertical = false,
		texture = "bubble.png",
	})
end



-- This function computes the rounded position of the node in front of the mob.
-- The math must be such that the mob MUST be standing WITHIN the node's X,Z
-- bounds, in order to get the position of the node ahead. If this is not the
-- case, then the mob would detect obstacles either too soon or too late to
-- correctly deal with them.
local function get_ahead_pos(self, pos, yaw)
	-- Copy position argument so we do not modify it.
	local s = (pos and vector.copy(pos)) or self.object:get_pos()
	s.y = s.y + self.collisionbox[2] + 0.5
	local off = (pi / 2)
	local cir = (pi * 2)
	local dir = yaw or (self.object:get_yaw() + off)

	-- Adjustment factor to improve accuracy.
	local fac = 0.99
	local ang = dir - off
	if ang < 0 then ang = ang + cir end
	if ang > cir then ang = ang - cir end
	local dd = deg(ang)

	--report(self, "angle: " .. dd)

	-- Increase distance when facing corners.
	if dd > 30 and dd < 60 then
		fac = 1.3
	elseif dd > 120 and dd < 150 then
		fac = 1.3
	elseif dd > 210 and dd < 240 then
		fac = 1.3
	elseif dd > 300 and dd < 330 then
		fac = 1.3
	end

	local p = {
		x = s.x + (cos(dir) * fac),
		y = s.y,
		z = s.z + (sin(dir) * fac),
	}

	-- Keep this particle code for debugging purposes [MustTest].
	--[[
	-- Spawn particle at actual computed position without rounding.
	local pname = "singleplayer"
	if not minetest.is_singleplayer() then
		pname = gdac.name_of_admin
	end

	utility.original_add_particle({
		playername = pname,
		pos = p,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.5,
		size = 1,
		collisiondetection = false,
		vertical = false,
		texture = "bubble.png",
	})
	--]]

	p = v_round(p)

	--[[
	-- Spawn particle at rounded node position.
	utility.original_add_particle({
		playername = pname,
		pos = p,
		velocity = {x=0, y=0, z=0},
		acceleration = {x=0, y=0, z=0},
		expirationtime = 0.5,
		size = 4,
		collisiondetection = false,
		vertical = false,
		texture = "bubble.png",
	})
	--]]

	return p
end



-- This function returns a list of walkable surfaces which are level with the
-- position. The returned list contains positions *above* the walkable surfaces.
-- The center position is also included, for a max total of 9 locations.
local function walkable_around(pos)
	local minp = v_add(pos, {x=-1, y=0, z=-1})
	local maxp = v_add(pos, {x=1, y=0, z=1})
	return hb4.find_walkable_in_area_under_unwalkable(minp, maxp)
end



-- Check if a position is a wall or pit. You should pass the rounded position of
-- the node which the mob wants to move INTO. Always returns two values,
-- true/false, and a reason string.
local function is_wall_or_pit(self, wp)
	local drop = (self.fear_height or 0)
	local jump = (self.jump_height or 0)

	-- Note: we need to add 1 to the jump height in order to take care of the case
	-- that the wall has a hole in it near the top. The mob would not be able to
	-- jump through such a wall because of the block above (assuming the mob is 2
	-- blocks high).
	jump = jump + 1

	-- Start the raycast from the top and go down.
	-- Note: the raycast ignores air nodes. So we do not need to do air checks.
	-- Note: the raycast returns ALL nodes, not just those exposed to air.
	local p1 = v_add(wp, {x=0, y=jump, z=0})
	local p2 = v_add(wp, {x=0, y=-drop, z=0})
	local ray = minetest.raycast(p1, p2, false, true)

	local thing = ray:next()
	local head_solid = false

	while thing do
		if thing.type == "node" then
			local p = thing.under
			local n = minetest.get_node(p).name

			local d = minetest.registered_nodes[n]

			if not d then
				return true, "undef"
			end

			if is_node_dangerous(self, n, d) then
				if head_solid then
					return true, "wall"
				else
					return true, "danger"
				end
			end

			-- If the node is not walkable, skip these checks.
			if d.walkable then
				if p.y == p1.y then
					head_solid = true
				elseif p.y == (p1.y - 1) then
					return true, "wall"
				elseif p.y == (p1.y - 2) and head_solid then
					return true, "wall"
				else
					return false, "surface"
				end
			end
		end
		thing = ray:next()
	end

	-- If we reach here, the raycast did not intersect any nodes.
	if (self.fear_height or 0) == 0 then
		return false, "nofear"
	end

	return true, "pit"
end

-- Export function.
mobs.is_wall_or_pit = is_wall_or_pit



-- Is mob facing a wall or a pit/cliff. Always returns two values, true/false,
-- and a reason string.
local function facing_wall_or_pit(self)
	if self.driver then
		return false, "driver"
	end

	local ahead = get_ahead_pos(self)
	return is_wall_or_pit(self, ahead)
end

-- Export function.
mobs.facing_wall_or_pit = facing_wall_or_pit



-- This function is to be called by the pathfinder to determine if a waypoint
-- would be dangerous for a mob to follow. Note that the pathfinder does not
-- place waypoints over deep pits, cliffs, or walls, so we do not need to check
-- for that kind of blockage. Note: pathfinder returns rounded positions.
function waypoint_dangerous(self, waypoint)
	local bnode = node_ok(waypoint)

	-- Is waypoint inside a dangerous node?
	if is_node_dangerous(self, bnode.name) then
		return true
	end
end



-- Global function.
function mobs.node_ok(pos, fallback)
	return node_ok(pos, fallback)
end



-- Get list of players and mobs in radius. Note: all "actor" (player, mob) type
-- targets are returned, irrespective of invisibility. Self is never included.
local function get_targets_in_radius(self, pos, radius)
	local list = {}
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for k, v in ipairs(objs) do
		if v:is_player() then
			list[#list + 1] = v
		else
			local ent = v:get_luaentity()
			if ent and (ent.mob or ent._cmi_is_mob) then
				if ent.object ~= self.object then
					list[#list + 1] = v
				end
			end
		end
	end
	return list
end



-- Environmental damage (water, lava, fire, light).
local function do_env_damage(self)

	-- feed/tame text timer (so mob 'full' messages dont spam chat)
	if self.htimer > 0 then
		self.htimer = self.htimer - 1
	end

	-- reset nametag after showing health stats
	if self.htimer < 1 and self.nametag2 then

		self.nametag = self.nametag2
		self.nametag2 = nil

		update_tag(self)
	end

	local pos = self.object:get_pos()

	self.time_of_day = minetest.get_timeofday()

	-- remove mob if beyond map limits
	if not within_limits(pos, 0) then
		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return
	end

	-- mob may simply despawn at daytime, without dropping anything
	if random(1, 10) == 1 then -- add some random delay chance
		if self.daytime_despawn and pos.y > -10
		and self.time_of_day > 0.2
		and self.time_of_day < 0.8
		and (minetest.get_node_light(pos) or 0) > 12 then
			if self.on_despawn then
				self.on_despawn(self)
				return
			else
				-- Mark for removal as last action on mob_step().
				self.mkrm = true

				return
			end
		end
	end

	-- bright light harms mob
	-- daylight above ground
	if self.light_damage ~= 0
	and pos.y > -10
	and self.time_of_day > 0.2
	and self.time_of_day < 0.8
	and (minetest.get_node_light(pos) or 0) > 12 then

		self.health = self.health - self.light_damage

		effect(pos, 5, "tnt_smoke.png")

		if check_for_death(self, "light", {type = "light"}) then return end
	end

	if self.despawns_in_dark_caves and pos.y < -12 then
		if (minetest.get_node_light(pos) or 0) == 0 then
			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			return
		end
	end

	-- don't fall when on ignore, just stand still
	if self.standing_in == "ignore" then
		self.object:set_velocity({x = 0, y = 0, z = 0})
	end

	local nodef = minetest.reg_ns_nodes[self.standing_in]
	local nodef2 = minetest.reg_ns_nodes[self.standing_on]

	-- Stairs nodes don't do env damage.
	if not nodef or not nodef2 then
		return
	end

	pos.y = pos.y + 1 -- for particle effect position

	-- water
	if self.water_damage ~= 0 and nodef.groups.water then

		if self.water_damage ~= 0 then

			self.health = self.health - self.water_damage

			effect(pos, 5, "bubble.png", nil, nil, 1, nil)

			if check_for_death(self, "water", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- lava damage
	elseif self.lava_damage ~= 0 and nodef.groups.lava then

		if self.lava_damage ~= 0 then

			self.health = self.health - self.lava_damage

			effect(pos, 5, "fire_basic_flame.png", nil, nil, 1, nil)

			if check_for_death(self, "lava", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- fire damage
	elseif self.fire_damage ~= 0 and nodef.groups.fire then

		self.health = self.health - self.fire_damage

		effect(pos, 15, "fire_basic_flame.png", 1, 5, 1, 0.2, 15, true)

		if check_for_death(self, "fire", {type = "environment", pos = pos,
				node = self.standing_in, hot = true}) then return end

	-- damage_per_second node check
	elseif nodef.damage_per_second ~= 0
			and nodef.groups.lava == nil and nodef.groups.fire == nil then

		self.health = self.health - nodef.damage_per_second

		effect(pos, 5, "tnt_smoke.png")

		if check_for_death(self, "dps", {type = "environment",
				pos = pos, node = self.standing_in}) then return end
	end

	if nodef2.groups.lava and self.lava_annihilates and self.lava_annihilates == true then
		self.health = 0

		effect(pos, 5, "tnt_smoke.png")

		pos.y = pos.y - 1 -- erase effect of adjusting for particle position.
		local pb = v_round(pos) -- use rounded position
		local pa = {x=pb.x, y=pb.y+1, z=pb.z}
		if minetest.get_node(pb).name == "air" and minetest.get_node(pa).name == "air" then
			if self.makes_bones_in_lava and self.makes_bones_in_lava == true then

				minetest.add_node(pb, {name="bones:bones_type2"})
				local meta = minetest.get_meta(pb)
				meta:set_int("protection_cancel", 1)

				minetest.add_node(pa, {name="fire:basic_flame"})
				minetest.check_for_falling(pb)
			else
				minetest.add_node(pb, {name="fire:basic_flame"})
			end
		end

		if check_for_death(self, "lava", {type = "environment",
			pos = pos, node = self.standing_in}) then return end
	end

	check_for_death(self, "", {type = "unknown"})
end



-- Arrow shooting code extracted into its own function [MustTest].
local function shoot_arrow(self, vec)
	-- Play shoot attack sound.
	mob_sound(self, self.sounds.shoot_attack)

	-- Spawn arrow comming from mid-height of mob.
	local p = self.object:get_pos()
	p.y = p.y + (self.collisionbox[2] + self.collisionbox[5]) / 2

	if minetest.registered_entities[self.arrow] then
		local obj = minetest.add_entity(p, self.arrow)
		if not obj then return end -- Sanity check.

		local ent = obj:get_luaentity()
		if not ent then
			obj:remove()
			return
		end -- Sanity check.

		local amount = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
		local v = ent.velocity or 1 -- or set to default

		ent.switch = 1
		ent.owner_obj = self.object -- Add unique owner object ref to arrow.

		-- Offset makes shoot aim accurate.
		vec.y = vec.y + self.shoot_offset
		vec.x = vec.x * (v / amount)
		vec.y = vec.y * (v / amount)
		vec.z = vec.z * (v / amount)

		obj:set_velocity(vec)
	end
end

-- Export.
mobs.shoot_arrow = function(...)
	shoot_arrow(...)
end



-- Target punching code extracted into its own function [MustTest].
local function punch_target(self, dtime)
	if not self.attack then return end
	if not self.attack:get_pos() then return end

	-- If the punch timer is still running since the last successful punch, then
	-- don't do anything.
	if (self.punch_timer or 0) > 0 then return end

	local s2 = self.object:get_pos()
	local p2 = self.attack:get_pos()

	p2.y = p2.y + 0.5
	s2.y = s2.y + 0.5

	if not raycast_los(self, p2, s2) then
		return
	end

	-- play attack sound
	mob_sound(self, self.sounds.attack)
	local targetname = (self.attack:is_player() and self.attack:get_player_name() or "")

	-- punch player (or what player is attached to)
	local attached = self.attack:get_attach()
	if attached or default.player_attached[targetname] then
		-- Mob has a chance of removing the player from whatever they're attached to.
		-- This chance only applies on the mob's first hit; if they fail to detach
		-- the player, the mob's target is set to the entity the player is attached to.
		if self.attack:is_player() and random(1, 5) == 1 then
			utility.detach_player_with_message(self.attack)
		elseif attached then
			self.attack = attached
		end
	end

	-- If attacking an entity that has no attached player, then stop attacking.
	if targetname == "" then
		local luaent = self.attack:get_luaentity()

		if luaent and not luaent._cmi_is_mob then
			local children = self.attack:get_children()

			if not children or #children == 0 then
				self.attack = nil
				return
			else
				local has_player = false

				for k, v in ipairs(children) do
					if v:is_player() then
						has_player = true
					end
				end

				if not has_player then
					self.attack = nil
					return
				end
			end
		end
	end

	-- Don't bother the admin.
	if gdac.player_is_admin(targetname) then
		return
	end

	if self.punch_target and self.punch_target(self, self.object, self.attack) == true then
		-- If 'true', skip default punch action.
	else
		local damage = self.damage or 0
		if self.damage_min and self.damage_max then
			if self.damage_min > damage and self.damage_max >= self.damage_min then
				damage = random(self.damage_min, self.damage_max)
			end
		end

		local dgroup = self.damage_group or "fleshy"

		self.attack:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {[dgroup] = damage}
		}, nil)

		-- Start punch timer; mob cannot punch again until timer reaches 0.
		self.punch_timer = 1

		ambiance.sound_play("default_punch", p2, 2.0, 30)
	end

	-- Tell everyone about the death [MustTest].
	if self.attack:is_player() and self.attack:get_hp() <= 0 then
		mobs.mob_killed_player(self, self.attack)
		self.attack = nil
	end
end



-- Remove block if possible [MustTest]. Note: this function does not necessarily
-- have to break a node if it is non-walkable, but even if so (i.e., air) it
-- MUST still return true in that case!
local function try_break_block(self, s)
	-- Must round position ourselves, otherwise we'll expose rounding
	-- inconsistencies in the engine and possibly break protection.
	s = v_round(s)

	local node1 = minetest.get_node(s).name

	-- Shortcut.
	if node1 == "air" then
		return true
	end

	-- Checks must be performed in order of severity.
	local ndef1 = minetest.registered_nodes[node1]

	-- Don't destroy player's bones [MustTest]!
	if (not ndef1) or node1 == "ignore" or node1 == "bones:bones" then
		return false, "special"
	end

	if ndef1.groups.unbreakable or ndef1.groups.immovable then
		return false, "unbreakable"
	end

	-- Some liquids (like lava sources) are walkable. The liquid check must
	-- therefore come first. (Some fake liquids, like nether grit, are diggable.)
	if ndef1.groups.liquid and not ndef1.diggable then
		return false, "liquid"
	end

	-- Check node level against mob's max-dig-level.
	if (ndef1.groups.level or 0) > (self.max_node_dig_level or 1) then
		return false, "unbreakable"
	end

	if ndef1.walkable and minetest.test_protection(s, "") then
		return false, "protected"
	end

	-- If a non-walkable node is also NOT dangerous, it does not block pathfinder.
	if not ndef1.walkable and not is_node_dangerous(node1) then
		return true
	end

	-- If we reach here, node ought to be either walkable, either/or dangerous.
	local oldnode = minetest.get_node(s)
	minetest.set_node(s, {name = "air"})

	-- Run script hook
	for _, callback in ipairs(minetest.registered_on_dignodes) do
		-- Deepcopy pos, oldnode, because callback can modify them
		callback(table.copy(s), table.copy(oldnode), self.object)
	end

	minetest.check_for_falling(s)

	-- This function takes both nodetables and nodenames.
	-- Pass node names, because passing a node table gives wrong results.
	local drops = minetest.get_node_drops(oldnode.name, "")

	for _, item in pairs(drops) do
		local p = {
			x = s.x + random() / 2 - 0.25,
			y = s.y + random() / 2 - 0.25,
			z = s.z + random() / 2 - 0.25,
		}
		minetest.add_item(p, item)
	end

	return true -- success!
end



local function force_jump_up(self, height)
	height = height or self.jump_height or 0
	local v = self.object:get_velocity()
	if height == 1 then
		v.y = 5 -- Jump a bit over one node.
	elseif height == 2 then
		v.y = 6.8 -- Jump slightly over two nodes.
	elseif height == 3 then
		v.y = 8.2 -- Jump over three nodes.
	else
		v.y = 5
	end
	v.y = v.y + (random(-50, 50) / 100)
	self.object:set_velocity(v)

	set_animation(self, "jump")
end



-- Jump if facing a solid node while moving forward (not fences or gates).
-- This function returns true if mob jumped; otherwise 'false' + "reason".
-- Notice: this func DOES NOT rotate the mob under any circumstances.
local function try_jump(self, dtime)
	-- Abort if mob does not have the ability to jump.
	if not self.jump or self.jump_height == 0 or self.fly then
		return false, "disabled"
	end

	-- Limit jump attempts to once per second.
	self.jump_timer = (self.jump_timer or 0) - dtime
	if self.jump_timer > 0 then
		return false, "jumping"
	end
	self.jump_timer = 0

	-- If we've only been stuck for less than a moment, we are still moving.
	if self.stuck_timer < 0.5 then
		return false, "moving"
	end

	-- We can only jump if standing on solid node.
	if not minetest.registered_nodes[self.standing_on].walkable then
		return false, "unwalkable"
	end

	-- What is in front of the mob?
	local nodebot = self.facing_node
	local nodetop = node_ok(v_add(self.facing_pos, {x=0, y=1, z=0}))

	-- Is the mob facing a fence?
	if self.facing_fence then
		return false, "fence"
	end

	-- Is the node in front of the mob's head (assuming 2 node high mob) walkable?
	local blocked = minetest.registered_nodes[nodetop.name].walkable
	if blocked then
		-- Only considered blocked if the mob can't jump 2 nodes high.
		if self.jump_height < 2 then
			return false, "blocked"
		end
	end

	-- Is the node ahead NOT walkable? Something else is probably blocking us.
	if not minetest.registered_nodes[nodebot].walkable then
		return false, "walkable"
	end

	force_jump_up(self)

	-- When in air move forward.
	minetest.after(0.3, function(self)
		if self.object:get_luaentity() then
			local v = self.object:get_velocity()
			self.object:set_acceleration({
				x = v.x * 2,
				y = 0,
				z = v.z * 2,
			})
		end
	end, self)

	if get_velocity(self) > 0 then
		mob_sound(self, self.sounds.jump)
	end

	-- Cannot jump again for one second.
	self.jump_timer = 1
	return true
end



-- Env damage avoidance extracted into its own function [MustTest].
local env_damage_nodes = {
	"group:soil",
	"group:stone",
	"group:sand",
	"group:rackstone",
	"group:netherack",
	node_ice,
	node_snowblock,
}

-- Executed when self.state == "avoid" [MustTest].
-- Function assumes entity object exists (entity methods shall not return nil).
local function avoid_env_damage(self, dtime)
	-- Get rounded position of the node the mob is standing in.
	local s = self.object:get_pos()
	s.y = s.y + self.collisionbox[2] + 0.5
	s = v_round(s)

	self.avoid.timer = self.avoid.timer - dtime
	if self.avoid.timer <= 0 then
		self.avoid.timer = 0
		self.avoid.target = nil
	end

	-- Current target's timeout has expired. Need to find a new safe spot.
	if self.avoid.timer <= 0 then
		-- Get list of nearby safe nodes under air.
		local minp = {x=s.x - 1, y=s.y - 0, z=s.z - 1}
		local maxp = {x=s.x + 1, y=s.y + 1, z=s.z + 1}
		local targets = minetest.find_nodes_in_area_under_air(
			minp, maxp, env_damage_nodes)

		-- Didn't find anything? Expand search area.
		if #targets == 0 then
			minp.x = minp.x - 2
			minp.y = minp.y - 0
			minp.z = minp.z - 2
			maxp.x = maxp.x + 2
			maxp.y = maxp.y + 1
			maxp.z = maxp.z + 2

			targets = minetest.find_nodes_in_area_under_air(
				minp, maxp, env_damage_nodes)
		end

		-- Still didn't find anything? Expand search area again.
		if #targets == 0 then
			minp.x = minp.x - 2
			minp.y = minp.y - 1
			minp.z = minp.z - 2
			maxp.x = maxp.x + 2
			maxp.y = maxp.y + 1
			maxp.z = maxp.z + 2

			targets = minetest.find_nodes_in_area_under_air(
				minp, maxp, env_damage_nodes)
		end

		-- Select position of random block to climb onto.
		if #targets > 0 then
			self.avoid.target = targets[random(1, #targets)]
			self.avoid.timer = 3
		end
	end

	-- Do we have a safe position?
	if self.avoid.target then
		if (self.pathfinding or 0) >= 1 then
			self.path.target = v_add(self.avoid.target, {x=0, y=1, z=0})
			self.path.dangerous_paths = true
			push_state(self, "pathfind")
			return
		else
			-- Look towards land and jump/move in that direction.
			local yaw = yaw_to_pos(self, self.avoid.target, s)
			set_yaw(self, yaw, 4)

			set_velocity(self, self.run_velocity or 0)
			set_animation(self, "run")
			self.avoid.timer = 3
		end
	else
		-- Mob panics, turns in random direction.
		if self.avoid.timer <= 0 then
			local yaw = self.object:get_yaw()
			yaw = yaw + random(-pi, pi)
			set_yaw(self, yaw, 6)
			self.avoid.timer = 3
		end

		set_velocity(self, self.run_velocity or 0)
		set_animation(self, "run")
	end
end



local function do_avoid_enter(self)
	self.avoid.target = nil
	self.avoid.timer = 0
end



-- Should mob follow what I'm holding?
local function follow_holding(self, clicker)
	if not clicker:is_player() then
		return false
	end

	local item = clicker:get_wielded_item()
	local t = type(self.follow)
	local name = item:get_name()

	-- Single item.
	if t == "string" and name == self.follow then
		return true

	-- Multiple items.
	elseif t == "table" then
		for i = 1, #self.follow, 1 do
			if self.follow[i] == name then
				return true
			end
		end
	end

	return false
end



-- Find two animals of same type and breed if nearby and horny.
-- Note: function is never called more than once per second. (No 'dtime' arg.)
local function attempt_breed(self)
	-- Child takes 240 seconds before growing into adult.
	if self.child == true then

		self.hornytimer = self.hornytimer + 1

		if self.hornytimer > 240 then

			self.child = false
			self.hornytimer = 0

			self.object:set_properties({
				textures = self.base_texture,
				mesh = self.base_mesh,
				visual_size = self.base_size,
				collisionbox = self.base_colbox,
				selectionbox = self.base_selbox,
			})

			-- custom function when child grows up
			if self.on_grown then
				self.on_grown(self)
			else
				-- jump when fully grown so as not to fall into ground
				self.object:set_velocity({
					x = 0,
					y = 5,
					z = 0
				})
			end
		end

		return
	end

	-- horny animal can mate for 40 seconds,
	-- afterwards horny animal cannot mate again for 200 seconds
	if self.horny == true
	and self.hornytimer < 240 then

		self.hornytimer = self.hornytimer + 1

		if self.hornytimer >= 240 then
			self.hornytimer = 0
			self.horny = false
		end
	end

	-- find another same animal who is also horny and mate if nearby
	if self.horny == true
	and self.hornytimer <= 40 then

		local pos = self.object:get_pos()

		effect({x = pos.x, y = pos.y + 1, z = pos.z}, 8, "heart.png", 3, 4, 1, 0.1)

		local objs = minetest.get_objects_inside_radius(pos, 3)
		local num = 0
		local ent = nil

		for n = 1, #objs do

			ent = objs[n]:get_luaentity()

			-- check for same animal with different colour
			local canmate = false

			if ent then

				if ent.name == self.name then
					canmate = true
				else
					local entname = string.split(ent.name,":")
					local selfname = string.split(self.name,":")

					if entname[1] == selfname[1] then
						entname = string.split(entname[2],"_")
						selfname = string.split(selfname[2],"_")

						if entname[1] == selfname[1] then
							canmate = true
						end
					end
				end
			end

			if ent
			and canmate == true
			and ent.horny == true
			and ent.hornytimer <= 40 then
				num = num + 1
			end

			-- found your mate? then have a baby
			if num > 1 then

				self.hornytimer = 41
				ent.hornytimer = 41

				-- spawn baby
				minetest.after(5, function(self, ent)

					if not self.object:get_luaentity() then
						return
					end

					-- custom breed function
					if self.on_breed then

						-- when false skip going any further
						if self.on_breed(self, ent) == false then
								return
						end
					else
						effect(pos, 15, "tnt_smoke.png", 1, 2, 2, 15, 5)
					end

					local mob = minetest.add_entity(pos, self.name)
					local ent2 = mob:get_luaentity()
					local textures = self.base_texture

					-- using specific child texture (if found)
					if self.child_texture then
						textures = self.child_texture[1]
					end

					-- and resize to half height
					mob:set_properties({
						textures = textures,
						visual_size = {
							x = self.base_size.x * .5,
							y = self.base_size.y * .5,
						},
						collisionbox = {
							self.base_colbox[1] * .5,
							self.base_colbox[2] * .5,
							self.base_colbox[3] * .5,
							self.base_colbox[4] * .5,
							self.base_colbox[5] * .5,
							self.base_colbox[6] * .5,
						},
						selectionbox = {
							self.base_selbox[1] * .5,
							self.base_selbox[2] * .5,
							self.base_selbox[3] * .5,
							self.base_selbox[4] * .5,
							self.base_selbox[5] * .5,
							self.base_selbox[6] * .5,
						},
					})
					-- tamed and owned by parents' owner
					ent2.child = true
					ent2.tamed = true
					ent2.owner = self.owner
				end, self, ent)

				num = 0

				break
			end
		end
	end
end



-- Find and replace what mob is looking for (grass, wheat etc.).
local function replace(self, pos)

	if not mobs_griefing
	or not self.replace_rate
	or not self.replace_what
	or self.child == true
	or self.object:get_velocity().y ~= 0
	or random(1, self.replace_rate) > 1 then
		return
	end

	local what, with, y_offset

	if type(self.replace_what[1]) == "table" then

		local num = random(#self.replace_what)

		what = self.replace_what[num][1] or ""
		with = self.replace_what[num][2] or ""
		y_offset = self.replace_what[num][3] or 0
	else
		what = self.replace_what
		with = self.replace_with or ""
		y_offset = self.replace_offset or 0
	end

	pos.y = pos.y + y_offset

	local range = self.replace_range or 1
	local target = minetest.find_node_near(pos, range, what)

	if target then

		-- Do not disturb protected stuff.
		if minetest.test_protection(target, "") then return end

-- print ("replace node = ".. minetest.get_node(pos).name, pos.y)

		local oldnode = {name = what}
		local newnode = {name = with}
		local on_replace_return

		if self.on_replace then
			on_replace_return = self.on_replace(self, target, oldnode, newnode)
		end

		if on_replace_return ~= false then

			minetest.add_node(target, {name = with})

			-- when cow/sheep eats grass, replace wool and milk
			if self.gotten == true then
				self.gotten = false
				self.object:set_properties(self)
			end
		end
	end
end



-- Check if daytime and also if mob is docile during daylight hours.
local function day_docile(self)
	if not self.docile_by_day then
		return false
	elseif self.time_of_day > 0.2 and self.time_of_day < 0.8 then
		return true
	end
end



-- Debug path display function.
local function highlight_path(self)
	if not mobs.debug_paths then
		return
	end

	if not self.path.following then
		return
	end

	-- Show path using particles.
	if self.path.way and #self.path.way > 0 then
		local pname = "singleplayer"
		if not minetest.is_singleplayer() then
			pname = gdac.name_of_admin
		end

		for _, pos in ipairs(self.path.way) do
			utility.original_add_particle({
				playername = pname,
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
	end
end



-- Place node, excluding it from protection.
local function force_place_block(name, pos, bridge)
	minetest.set_node(pos, {name=name})
	local meta = minetest.get_meta(pos)
	meta:set_int("protection_cancel", 1)

	-- Drop node if the position underneath is not walkable and NOT bridging.
	if not bridge then
		if not pos_walkable(v_add(pos, {x=0, y=-1, z=0})) then
			if not minetest.test_protection(pos, "") then
				sfn.drop_node(pos)
			end
		else
			minetest.check_for_falling(pos)
		end
	end
end



-- Function shall attempt to place a node, exluding it from protection.
local function try_place_block(self, target, bridge)
	local pn = self.place_node or node_pathfinder_place
	local nn = minetest.get_node(target).name

	if nn == "air" or nn == "default:snow" then
		force_place_block(pn, target, bridge)
		return true
	end

	local ndef = minetest.registered_nodes[nn]
	if not ndef or nn == "ignore" then
		return false
	end

	if ndef.buildable_to and not minetest.test_protection(target, "") then
		force_place_block(pn, target, bridge)
		return true
	end
end



-- Shall return true if blockage was fully removed [MustTest].
local function try_dig_doorway(self)
	local p1 = get_ahead_pos(self)

	-- First, try to break the block above.
	-- If we can't do this, there's no point in trying to break the bottom block.
	-- That would also interfere with us closing the bottom hole up.
	p1.y = p1.y + 1

	local b1
	local b2 = try_break_block(self, p1)

	p1.y = p1.y - 1

	-- Sometimes, a mob is trying to path through a 1x1 hole, where the block
	-- above is undiggable for some reason. I can do something clever here:
	-- if the bottom hole is air, I can close it up. This way, the next time the
	-- pathfinder runs, it will not try to go through this hole. [MustTest]
	local hole_closed = false
	if not b2 then
		if try_place_block(self, p1) then
			hole_closed = true
		end
	else
		b1 = try_break_block(self, p1)
	end

	if b1 and b2 then
		return true
	elseif hole_closed then
		return false, "changed"
	else
		return false, "failed"
	end
end



-- Specific attack.
local function specific_attack(list, what)

	-- No list so attack default (player, animals etc.)
	if list == nil then
		return true
	end

	-- is found entity on list to attack?
	for no = 1, #list do

		if list[no] == what then
			return true
		end
	end

	return false
end



-- Select nearest target entity from an array of entities.
local function select_nearest_entity(self, list)
	local s = self.object:get_pos()
	s.y = s.y + 1 -- Make easier to look up hills.

	local closest_target
	local current_distance = self.view_range + 1

	-- Go through entities and select closest.
	local size = #list -- Cache array length.
	for n = 1, size, 1 do
		local target = list[n]

		local p = target:get_pos()
		p.y = p.y + 1 -- Make easier to look up hills.

		local dist = get_distance(p, s)

		-- Choose closest target that is not self.
		if dist > 0 then
			if dist < current_distance and raycast_los(self, s, p) then
				current_distance = dist
				closest_target = target
			end
		end
	end

	return closest_target
end



-- Specific runaway.
local function specific_runaway(list, what)
	-- No list.
	if not list then return end

	-- Found entity on list to run away from?
	for no = 1, #list, 1 do
		if list[no] == what then
			return true
		end
	end
end



-- Get list of targets in area that should be run away from.
local function get_avoidable_targets(self)
	local s = self.object:get_pos()
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	for n = 1, #objs, 1 do
		local ent = objs[n]:get_luaentity()

		-- Are we a player?
		if objs[n]:is_player() then
			local pname = objs[n]:get_player_name()

			-- If player invisible them mob does not run away from them.
			if mobs.is_invisible(self, pname) then
				objs[n] = nil
				goto continue
			end

			-- Ignore dead players.
			if objs[n]:get_hp() <= 0 then
				objs[n] = nil
				goto continue
			end

			-- If player nametag is off, reduce range at which mob can see them.
			if objs[n] and player_labels.query_nametag_onoff(pname) == false then
				local r = self.view_range * 0.8
				local p = objs[n]:get_pos()
				if v_distance(p, s) > r then
					objs[n] = nil
					goto continue
				end
			end

			-- Don't run from ignored players.
			if minetest.check_player_privs(pname, {mobs_ignore=true}) then
				objs[n] = nil
				goto continue
			end

		-- Or are we a mob?
		elseif ent and ent._cmi_is_mob then

			-- Don't run away from mobs of our own type, or unknown type.
			if ent.name == "" or self.name == ent.name then
				objs[n] = nil
				goto continue
			end

			-- Ignore mobs we don't care about.
			if not specific_runaway(self.runaway_from, ent.name) then
				objs[n] = nil
				goto continue
			end

		-- Remove all other entities.
		else
			objs[n] = nil
			goto continue
		end

		::continue::
	end

	-- Compact targets into an array.
	local targets = {}
	local index = 1

	for k, v in pairs(objs) do
		targets[index] = v
		index = index + 1
	end

	return targets
end



-- Get list of targets in area that can be attacked.
local function get_attackable_targets(self)
	local s = self.object:get_pos()
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	-- Scan found entities and remove entities we aren't interested in.
	for n = 1, #objs, 1 do
		local ent = objs[n]:get_luaentity()

		-- Are we a player?
		if objs[n]:is_player() then
			local pname = objs[n]:get_player_name()

			-- If mob does not attack players.
			if not self.attack_players then
				objs[n] = nil
				goto continue
			end

			-- If player is invisible (some mobs can ignore invisibility).
			if mobs.is_invisible(self, pname) then
				objs[n] = nil
				goto continue
			end

			if not specific_attack(self.specific_attack, "player") then
				objs[n] = nil
				goto continue
			end

			-- Ignore dead players.
			if objs[n]:get_hp() <= 0 then
				objs[n] = nil
				goto continue
			end

			-- If player nametag is off, reduce range at which mob can see them.
			if player_labels.query_nametag_onoff(pname) == false then
				local r = self.view_range * 0.8
				local p = objs[n]:get_pos()
				if v_distance(p, s) > r then
					objs[n] = nil
					goto continue
				end
			end

			-- Don't attack ignored players.
			if minetest.check_player_privs(pname, {mobs_ignore=true}) then
				objs[n] = nil
				goto continue
			end

		-- Or are we a mob?
		elseif ent and ent._cmi_is_mob then

			-- Remove mobs not to attack.
			if self.name == ent.name
					or (not self.attack_animals and ent.type == "animal")
					or (not self.attack_monsters and ent.type == "monster")
					or (not self.attack_npcs and ent.type == "npc")
					or not specific_attack(self.specific_attack, ent.name) then
				objs[n] = nil
				goto continue
			end

			-- Ignore allies.
			if self.specific_allies and self.specific_allies[ent.name] then
				objs[n] = nil
				goto continue
			end

		-- Remove all other entities.
		else
			objs[n] = nil
			goto continue
		end

		::continue::
	end

	-- Compact targets into an array.
	local targets = {}
	local index = 1

	for k, v in pairs(objs) do
		targets[index] = v
		index = index + 1
	end

	return targets
end



-- General attack function for all mobs. Scan for targets and attack them.
-- This function (usually) only executes once per second (per mob) [MustTest].
local function general_attack(self)
	-- Skip because mob is passive.
	if self.passive then return end

	-- Skip because already attacking something, or running away.
	if self.state == "attack" then return end
	if self.state == "runaway" then return end
	if self.state == "pathfind" then return end
	if self.state == "avoid" then return end
	if self.state == "digbuild" then return end

	-- Skip if mob is docile during day.
	if day_docile(self) then return end

	-- Get array list of targets to attack.
	local objs = get_attackable_targets(self)
	local target = select_nearest_entity(self, objs)

	-- Attack closest target.
	if target and random(1, 100) < (self.attack_chance or 95) then
		do_attack(self, target)
		return
	end

	-- Hunt random nearby target. (Allows targets outside of LOS.)
	if #objs > 0 then
		if not target and random(1, 100) < (self.hunt_chance or 5) then
			local tarhunt = objs[random(1, #objs)]
			do_attack(self, tarhunt)
			return
		end
	end
end



-- Find someone to runaway from.
local function runaway_from(self)
	-- Abort if mob doesn't fear any particular enemies.
	if not self.runaway_from then return end

	-- If non-passive mob is attacking, then it will not run away right now.
	if self.state == "attack" and not self.passive then return end
	if self.state == "runaway" then return end
	if self.state == "pathfind" then return end
	if self.state == "avoid" then return end

	-- Get array list of targets to run away from.
	local objs = get_avoidable_targets(self)
	local target = select_nearest_entity(self, objs)

	if target then
		local s = self.object:get_pos()
		local p = target:get_pos()
		local yaw = yaw_to_pos(self, p, s)
		yaw = yaw + pi -- Face opposite.
		set_yaw(self, yaw, 4)

		transition_state(self, "runaway")
	end
end



-- Get an object ref to the mob's owner if in view range.
local function get_owner_in_range(self)
	if not self.owner or self.owner == "" then
		return
	end

	-- Only players can be mob owners.
	local players = minetest.get_connected_players()

	for i = 1, #players, 1 do
		local pref = players[i]
		local pname = pref:get_player_name()
		if pname == self.owner then
			local s = self.object:get_pos()
			local p = pref:get_pos()
			if v_distance(s, p) < self.view_range then
				s.y = s.y + 1
				p.y = p.y + 1
				if raycast_los(self, s, p) then
					-- Do not return player ref if player is ignored.
					if not minetest.check_player_privs(pname, {mobs_ignore=true}) then
						return pref
					end
				end
			end
		end
	end
end



local function get_follow_holding_in_range(self)
	if not self.follow or self.follow == "" then
		return
	end

	-- Only players can hold items that mob might follow.
	local players = minetest.get_connected_players()

	for i = 1, #players, 1 do
		local pref = players[i]
		local s = self.object:get_pos()
		local p = pref:get_pos()
		if v_distance(s, p) < self.view_range then
			if follow_holding(self, pref) then
				s.y = s.y + 1
				p.y = p.y + 1
				if raycast_los(self, s, p) then
					local pname = pref:get_player_name()
					if not minetest.check_player_privs(pname, {mobs_ignore=true}) then
						return pref
					end
				end
			end
		end
	end
end



-- Check nearby players and follow them if conditions are right.
-- Shall follow player if player is mob's owner, or if holding item.
local function follow_something(self)
	-- Skip if attacking or running away.
	if self.state == "attack" then return end
	if self.state == "runaway" then return end
	if self.state == "avoid" then return end
	if self.state == "pathfind" then return end

	-- Skip if already following.
	if self.following and self.following:get_pos() then return end

	-- Skip if horny (who comes up with these terms? Geez).
	if self.horny then return end

	-- Skip if mob is child.
	if self.child then return end

	-- If the mob has an owner nearby, follow him!
	local owner = get_owner_in_range(self)
	if owner then
		local pname = owner:get_player_name()
		if not mobs.is_invisible(self, pname) then
			self.following = owner
			transition_state(self, "follow")
			return
		end
	end

	local holding = get_follow_holding_in_range(self)
	if holding then
		local pname = holding:get_player_name()
		if not mobs.is_invisible(self, pname) then
			self.following = holding
			transition_state(self, "follow")
			return
		end
	end
end



-- If the mob has a target, and LOS to target for time, then refocus attack!
-- This function expects to run once per second.
local function refocus_attack(self)
	if not self.attack then
		self.refocus_timer = 0
		return
	end

	local s = self.object:get_pos()
	local p = self.attack:get_pos()

	if not p then
		self.refocus_timer = 0
		return
	end

	-- Make looking up hills easier.
	s.y = s.y + 1
	p.y = p.y + 1

	local los = raycast_los(self, s, p)

	-- Count consecutive seconds in which mob has LOS to active target.
	if los then
		self.refocus_timer = (self.refocus_timer or 0) + 1
	else
		self.refocus_timer = 0
		return
	end

	-- The counter limit is arbitrary.
	if self.refocus_timer >= 8 then
		transition_state(self, "attack")
		return
	end
end



-- Dogshoot attack switch and counter function.
local function dogswitch(self, dtime)

	-- Switch mode not activated.
	if not self.dogshoot_switch or not dtime then
		return 0
	end

	-- Run timer.
	self.dogshoot_count = self.dogshoot_count + dtime

	local expired
	if self.dogshoot_switch == 1 and self.dogshoot_count > self.dogshoot_count_max then
		expired = true
	elseif self.dogshoot_switch == 2 and self.dogshoot_count > self.dogshoot_count2_max then
		expired = true
	end

	if expired then
		-- Reset timer.
		self.dogshoot_count = 0

		-- Toggle.
		if self.dogshoot_switch == 1 then
			self.dogshoot_switch = 2
		else
			self.dogshoot_switch = 1
		end
	end

	return self.dogshoot_switch
end



local function do_stand_enter(self)
	set_velocity(self, 0)
	set_animation(self, "stand")
end



-- State self.state == "stand" moved to its own function [MustTest].
local function do_stand_state(self, dtime)
	-- Avoid dangerous nodes.
	if is_node_dangerous(self, self.standing_in) then
		push_state(self, "avoid")
		return
	end

	local s = self.object:get_pos()
	if keep_mob_centered(self, s) then
		return
	end

	-- NPCs look at any players nearby, otherwise turn randomly.
	if random(1, 4) == 1 then
		local lp = nil

		if self.type == "npc" then
			local objs = minetest.get_objects_inside_radius(s, 10)

			for n = 1, #objs, 1 do
				if objs[n]:is_player() then
					lp = objs[n]:get_pos()
					break
				end
			end

			-- Small chance that player gets ignored.
			if random(1, 4) == 1 then
				lp = nil
			end
		end

		local yaw = self.object:get_yaw()

		if lp then
			yaw = yaw_to_pos(self, lp, s)
		else
			yaw = yaw + random(-0.5, 0.5)
		end

		set_yaw(self, yaw, 8)
	end

	set_velocity(self, 0)
	set_animation(self, "stand")

	-- Mobs ordered to stand stay standing.
	if self.order == "stand" then return end

	-- Am I facing something dangerous?
	local result, reason = facing_wall_or_pit(self)
	if result then return end

	-- Animals are restricted by fences.
	if self.type == "animal" and self.facing_fence then
		return
	end

	if random(1, 100) > (self.walk_chance or 0) then
		return
	end

	transition_state(self, "walk")

	--[[ fly up/down randomly for flying mobs
	if self.fly and random(1, 100) <= self.walk_chance then

		local v = self.object:get_velocity()
		local ud = random(-1, 2) / 9

		self.object:set_velocity({x = v.x, y = ud, z = v.z})
	end--]]
end



local function do_walk_enter(self)
	set_velocity(self, self.walk_velocity or 0)
	set_animation(self, "walk")
end



-- State self.state == "walk" moved to its own function [MustTest].
local function do_walk_state(self, dtime)
	-- Avoid dangerous nodes.
	if is_node_dangerous(self, self.standing_in) then
		push_state(self, "avoid")
		return
	end

	-- Am I facing something dangerous?
	local result, reason = facing_wall_or_pit(self)
	if result then
		transition_state(self, "stand")
		return
	end

	if self.type == "animal" and self.facing_fence then
		transition_state(self, "stand")
		return
	end

	-- Chance to stop walking.
	if random(1, 100) <= 30 then
		transition_state(self, "stand")
		return
	end

	-- Randomly turn.
	if random(1, 100) <= 30 then
		local yaw = self.object:get_yaw()
		yaw = yaw + random(-0.5, 0.5)
		set_yaw(self, yaw, 8)
	end

	set_velocity(self, self.walk_velocity or 0)

	if flight_check(self)
			and self.animation
			and self.animation.fly_start
			and self.animation.fly_end then
		set_animation(self, "fly")
	else
		set_animation(self, "walk")
	end
end



local function do_runaway_enter(self)
	self.runaway_timer = 5
end



-- Runaway (self.state == "runaway") moved to its own function [MustTest].
-- Note: this function executes once per frame ('continuous is true').
local function do_runaway_state(self, dtime)
	self.runaway_timer = (self.runaway_timer or 0) - dtime
	if self.runaway_timer <= 0 then
		-- Timer has expired. Should we keep running, or stop?
		local objs = get_avoidable_targets(self)
		local target = select_nearest_entity(self, objs)

		if target then
			self.runaway_timer = 5
		else
			pop_state(self)
			return
		end
	end

	-- Do evasion if inside dangerous node.
	if is_node_dangerous(self, self.standing_in) then
		push_state(self, "avoid")
		return
	end

	-- Stop fleeing if heading into obstacle.
	local result, reason = facing_wall_or_pit(self)
	if result then
		pop_state(self)
		return
	end

	try_jump(self, dtime)
	set_velocity(self, self.sprint_velocity or 0)
	set_animation(self, "run")
end



local function do_avoid_state(self, dtime)
	if is_node_dangerous(self, self.standing_in) then
		avoid_env_damage(self, dtime)
	else
		pop_state(self)
	end
end



-- Mob has caught up with target.
local function do_caught_attack(self, dtime)
	-- Target might not be valid anymore.
	if not self.attack or not self.attack:get_pos() then
		pop_state(self)
		return
	end

	local s = self.object:get_pos()
	local p = self.attack:get_pos()

	local dist = get_distance(p, s)
	local targetname = (self.attack:is_player() and self.attack:get_player_name()) or ""

	-- Stop attacking if target invisible, dead, or out of range.
	if dist > self.view_range	or self.attack:get_hp() <= 0
			or mobs.is_invisible(self, targetname) then
		pop_state(self)
		return
	end

	-- Start chasing again if target moved beyond reach.
	if dist > self.reach then
		transition_substate(self, "chase")
		return
	end

	-- Stop and face target.
	do
		set_velocity(self, 0)
		local yaw = yaw_to_pos(self, p, s)
		set_yaw(self, yaw)
	end

	-- If mob does not have a custom attack, or that function returns true, then
	-- execute the default punch-attack code.
	if not self.custom_attack or self.custom_attack(self, p) == true then
		set_animation(self, "punch")
		punch_target(self, dtime)
	end
end



-- Mob is blocked from reaching target by environment, etc.
local function do_blocked_attack(self, dtime)
	-- Target might not be valid anymore.
	if not self.attack or not self.attack:get_pos() then
		pop_state(self)
		return
	end

	-- Avoid dangerous nodes.
	if is_node_dangerous(self, self.standing_in) then
		push_state(self, "avoid")
		return
	end

	local s = self.object:get_pos()
	local p = self.attack:get_pos()

	local dist = get_distance(p, s)
	local targetname = (self.attack:is_player() and self.attack:get_player_name()) or ""

	-- Stop attacking if target invisible, dead, or out of range.
	if dist > self.view_range	or self.attack:get_hp() <= 0
			or mobs.is_invisible(self, targetname) then
		pop_state(self)
		return
	end

	-- Turn to face target. If the target moves around we may eventually become
	-- unblocked.
	do
		set_velocity(self, 0)
		set_animation(self, "stand")

		local yaw = yaw_to_pos(self, p, s)
		set_yaw(self, yaw)
	end

	-- Punch target if within punching range even while stuck [MustTest].
	if dist <= (self.punch_reach or self.reach or 0) then
		punch_target(self, dtime)
	end

	-- If dogshooter, transition to shoot once dogshoot timer expires.
	-- This attack works even while mob is stuck.
	if self.attack_type == "dogshoot" then
		local switch = dogswitch(self, dtime)
		if switch == 1 then
			transition_substate(self, "shoot")
			return
		end
	end

	-- Flag set if mob is directly over or under player. If that is the case, but
	-- we're still beyond the mob's reach, then we have to try something else ....
	local overunder = false
	if abs(s.x - p.x) < 0.5 and abs(s.z - p.z) < 0.5 then
		overunder = true
	end

	if dist < self.reach then
		transition_substate(self, "chase")
		return
	end

	-- If mob facing obstacle, or directly over/under target, then we're stuck.
	if overunder or facing_wall_or_pit(self) then
		-- Mob is stuck and has been standing for 3 seconds.
		if (self.pathfinding or 0) >= 1 and self.stand_timer > 3 then
			self.path.dangerous_paths = false
			self.path.target = v_round(self.attack:get_pos())
			push_state(self, "pathfind")
			return
		end
	else
		-- Otherwise, not facing obstacle and NOT over/under target. Chase!
		transition_substate(self, "chase")
		return
	end
end



local function do_chase_attack(self, dtime)
	-- Target might not be valid anymore.
	if not self.attack or not self.attack:get_pos() then
		pop_state(self)
		return
	end

	local s = self.object:get_pos()
	local p = self.attack:get_pos()

	local dist = get_distance(p, s)
	local targetname = (self.attack:is_player() and self.attack:get_player_name()) or ""

	-- Stop attacking if target invisible, dead, or out of range.
	if dist > self.view_range	or self.attack:get_hp() <= 0
			or mobs.is_invisible(self, targetname) then
		pop_state(self)
		return
	end

	-- If dogshooter, transition to shoot once dogshoot timer expires.
	if self.attack_type == "dogshoot" then
		local switch = dogswitch(self, dtime)
		if switch == 1 then
			transition_substate(self, "shoot")
			return
		end
	end

	local dist = get_distance(p, s)

	-- TODO: must use set_velocity (for fliers) here, not directly!
	if self.fly and dist > self.reach then
		local me_y = floor(s.y + 1)
		local p_y = floor(p.y + 1)
		local v = self.object:get_velocity()

		if flight_check(self, s) then
			if me_y < p_y then

				-- Fly up.
				self.object:set_velocity({
					x = v.x,
					y = 1 * self.walk_velocity,
					z = v.z
				})

			elseif me_y > p_y then

				-- Fly down.
				self.object:set_velocity({
					x = v.x,
					y = -1 * self.walk_velocity,
					z = v.z
				})

			end
		else
			if me_y < p_y then

				-- Fly up slowly.
				self.object:set_velocity({
					x = v.x,
					y = 0.01,
					z = v.z
				})

			elseif me_y > p_y then

				-- Fly down slowly.
				self.object:set_velocity({
					x = v.x,
					y = -0.01,
					z = v.z
				})

			end
		end
	end

	-- Face target.
	do
		local yaw = yaw_to_pos(self, p, s)
		set_yaw(self, yaw)
	end

	-- Flag set if mob is directly over or under player. If that is the case, but
	-- we're still beyond the mob's reach, then we have to try something else ....
	local overunder = false
	if abs(s.x - p.x) < 0.5 and abs(s.z - p.z) < 0.5 then
		overunder = true
	end

	-- Move towards enemy if beyond mob reach.
	if dist > self.reach then
		-- Note: the 'facing_wall_or_pit' function also checks for dangerous nodes.
		-- But some dangerous nodes are non-walkable, which means the pathfinder
		-- would path through them.
		if facing_wall_or_pit(self) or overunder or self.stuck_timer > 1 then
			-- Chase blocked, NOT pathfind blocked.
			transition_substate(self, "blocked")
		else
			try_jump(self, dtime)

			if dist > self.punch_reach then
				set_velocity(self, self.sprint_velocity or 0)
				set_animation(self, "run")
			else
				set_velocity(self, self.run_velocity or 0)
				set_animation(self, "run")
			end
		end

		-- Punch target if within punching range even while moving [MustTest].
		if dist <= (self.punch_reach or self.reach or 0) then
			punch_target(self, dtime)
		end
	else
		-- Inside 'self.reach' range.
		transition_substate(self, "caught")
	end
end



local function do_shoot_attack(self, dtime)
	-- Target might not be valid anymore.
	if not self.attack or not self.attack:get_pos() then
		pop_state(self)
		return
	end

	local s = self.object:get_pos()
	local p = self.attack:get_pos()

	local dist = get_distance(p, s)
	local targetname = (self.attack:is_player() and self.attack:get_player_name()) or ""

	-- Stop attacking if target invisible, dead, or out of range.
	if dist > self.view_range	or self.attack:get_hp() <= 0
			or mobs.is_invisible(self, targetname) then
		pop_state(self)
		return
	end

	p.y = p.y - 0.5
	s.y = s.y + 0.5

	-- If dogshooter, transition to chase once dogshoot timer expires.
	if self.attack_type == "dogshoot" then
		local switch = dogswitch(self, dtime)
		if switch ~= 1 then
			transition_substate(self, "chase")
			return
		end
	end

	-- Face target and stand.
	local yaw = yaw_to_pos(self, p, s)
	set_yaw(self, yaw)
	set_velocity(self, 0)
	set_animation(self, "shoot")

	self.shoot_timer = (self.shoot_timer or 0) + dtime

	if self.shoot_timer > (self.shoot_interval or 1) then
		self.shoot_timer = 0

		-- Shoot in this direction.
		local vec = {
			x = p.x - s.x,
			y = p.y - s.y,
			z = p.z - s.z,
		}

		shoot_arrow(self, vec)
	end
end



local function do_attack_enter(self)
	if random(0, 100) < 90 and self.sounds.war_cry then
		mob_sound(self, self.sounds.war_cry)
	end
end



local function do_attack_exit(self)
end



-- State self.state == "attack" extracted to its own function [MustTest].
-- The attack routines (explode, dogfight, shoot, dogshoot, etc.). This function
-- runs once per frame, while the "attack" state is active.
local function do_attack_state(self, dtime)
	-- Abort if we have no target!
	if not self.attack or not self.attack:get_pos() then
		pop_state(self)
		return
	end

	-- Calculate distance from mob and enemy.
	local s = self.object:get_pos()
	local p = self.attack:get_pos()

	-- Abort if target entity does not exist.
	if not p then
		pop_state(self)
		return
	end

	local dist = get_distance(p, s)
	local targetname = (self.attack:is_player() and self.attack:get_player_name()) or ""

	-- Stop attacking if target invisible, dead, or out of range.
	if dist > self.view_range	or self.attack:get_hp() <= 0
			or mobs.is_invisible(self, targetname) then
		pop_state(self)
		return
	end

	local attack_type = self.attack_type

	-- The special "dogshoot" attack type basically just swaps between "dogfight"
	-- and "shoot" based on timers.
	if attack_type == "dogshoot" then
		local switch = dogswitch(self, dtime)
		if switch == 1 then
			attack_type = "shoot"
		else
			-- If 'dogswitch' returns 0 or 2, mob shall dogfight.
			attack_type = "dogfight"
		end
	end

	if attack_type == "dogfight" then
		transition_substate(self, "chase")
	elseif attack_type == "shoot" then
		transition_substate(self, "shoot")
	end
end



-- Code to handle mob's lifetimer extracted to own function [MustTest].
local function do_lifetimer(self, pos)
	if self.tamed then return end
	if self.type == "npc" then return end
	if self.state == "attack" then return end
	if self.lifetimer > 20000 then return end
	if not remove_far then return end

	self.lifetimer = self.lifetimer - dtime
	if self.lifetimer > 0 then return end

	-- Only despawn away from player
	local objs = minetest.get_objects_inside_radius(pos, 15)

	for n = 1, #objs, 1 do
		if objs[n]:is_player() then
			self.lifetimer = 20
			return
		end
	end

	effect(pos, 15, "tnt_smoke.png", 2, 4, 2, 0)

	-- Mark for removal as last action on mob_step().
	self.mkrm = true
end



-- This function gets the position of the node the mob is standing IN.
-- The node position around its feet, basically.
local function get_standing_pos(self, pos)
	-- Copy position argument so we do not modify it.
	local p = (pos and vector.copy(pos)) or self.object:get_pos()
	local y = self.collisionbox[2]

	if self.child then
		y = self.collisionbox[2] * 0.5
	end

	p.y = p.y + y + 0.25
	p = v_round(p)
	return p
end



-- Code to get what mob is standing in/on extracted to own function [MustTest].
local function update_foot_nodes(self, pos, dtime)
	-- Get node at foot level every quarter second.
	self.node_timer = (self.node_timer or 0) + dtime

	if self.node_timer > 0.25 then
		self.node_timer = 0

		-- What is mob standing in and on?
		local spos = get_standing_pos(self, pos)
		self.standing_in = node_ok(spos, "air").name
		spos.y = spos.y - 1
		self.standing_on = node_ok(spos, "air").name

		-- What is mob facing?
		self.facing_pos = get_ahead_pos(self, pos)
		self.facing_node = node_ok(self.facing_pos, "air").name

		-- Are we facing a fence or wall?
		local fn = self.facing_node
		if fn:find("fence") or fn:find("gate") or fn:find("wall") then
			self.facing_fence = true
		else
			self.facing_fence = false
		end
	end
end



-- Get the absolute delta angle between two yaw angles, in radians.
function yaw_delta(y1, y2)
	local y
	-- First, get the difference between the two yaws.
	if y1 > y2 then
		y = y1 - y2
	else
		y = y2 - y1
	end
	-- Subtract PI if needed to get the smaller delta.
	if y > pi then
		y = y - (pi * 2)
	end
	return abs(y)
end



-- Detect whether a waypoint path contains sharp turns. This function checks the
-- mob's current yaw against the next 3 waypoints. If its yaw to each waypoint
-- is within a small tolerance, the path is straight; otherwise it is not.
local function path_is_straight(self, pos)
	local path = self.path.way
	if not path then return end

	local w1 = path[1]
	local w2 = path[2]
	local w3 = path[3]
	if not w1 or not w2 or not w3 then
		return
	end

	local y1 = self.object:get_yaw()
	local y2 = yaw_to_pos(self, w1, pos)
	local y3 = yaw_to_pos(self, w2, pos)
	local y4 = yaw_to_pos(self, w3, pos)

	local d1 = deg(yaw_delta(y1, y2))
	local d2 = deg(yaw_delta(y1, y3))
	local d3 = deg(yaw_delta(y1, y4))

	return (d1 < 15 and d2 < 10 and d3 < 5)
end



local function do_pathfind_enter(self)
	-- The pathfinder requires a target. I assume the target is a rounded vector.
	-- It should be inside an air node, or non-walkable, and walkable node under.
	if not self.path.target then
		pop_state(self)
		return
	end

	transition_substate(self, "newpath")
end



local function do_pathfind_newpath(self, dtime)
	-- Make sure to round positions, because the pathfinder is very sensitive.
	local start = self.object:get_pos()
	start.y = start.y + self.collisionbox[2] + 0.5
	start = v_round(start)

	-- The mob might be clipped inside a node. Find a start position nearby.
	if pos_walkable(start) then
		local minp = v_add(start, {x=-1, y=0, z=-1})
		local maxp = v_add(start, {x=1, y=0, z=1})
		local positions = hb4.find_walkable_in_area_under_unwalkable(minp, maxp)

		if #positions == 0 then
			transition_state(self, "")
			return
		else
			start = positions[random(1, #positions)]
		end
	end

	local target = v_round(self.path.target)
	local radius = self.pathing_radius or 16

	-- The target might not always be reachable (e.g., the target is a player who
	-- has sneak-moved off the edge of a node, and thus are "standing" in air). So
	-- we choose a random valid position near the target instead of the target
	-- itself. We also check if the player is slightly clipped inside walkable.
	if pos_walkable(target) or not pos_walkable(v_add(target, {x=0, y=-1, z=0})) then
		local minp = v_add(target, {x=-2, y=-1, z=-2})
		local maxp = v_add(target, {x=2, y=1, z=2})
		local positions = hb4.find_walkable_in_area_under_unwalkable(minp, maxp)

		if #positions == 0 then
			if (self.pathfinding or 0) >= 3 then
				-- Replace pathfinder with dig/build code.
				-- The dig/build code should swap back to the pathfinder when ready.
				self.digbuild.target = self.path.target
				pop_state(self)
				push_state(self, "digbuild")
				return
			end

			transition_state(self, "")
			return
		else
			target = positions[random(1, #positions)]
		end
	end

	local dh = 6
	local jh = 0

	if self.fear_height ~= 0 then dh = (self.fear_height - 1) end
	if self.stepheight > 1 then jh = 1 end

	-- Do not generate paths with a jump-height above 3 nodes.
	if self.jump then
		if self.jump_height >= 3 then
			jh = 3
		elseif self.jump_height >= 2 then
			jh = 2
		elseif self.jump_height >= 1 then
			jh = 1
		end
	end

	-- Note: pathfinder is very sensitive to start and finish positions.
	local path = minetest.find_path(start, target, radius, jh, dh, "A*")

	if path then
		-- Yay, I found path.
		if self.attack and self.attack:get_pos() then
			mob_sound(self, self.sounds.war_cry)
		else
			mob_sound(self, self.sounds.random)
		end

		self.path.way = path
		self.path.following = true
		self.path.blocked_count = 0
		self.path.waypoints_gotten = 0
		transition_substate(self, "")
		return
	else
		if (self.pathfinding or 0) >= 3 then
			-- Replace pathfinder with dig/build code.
			-- The dig/build code should swap back to the pathfinder when ready.
			self.digbuild.target = self.path.target
			pop_state(self)
			push_state(self, "digbuild")
			return
		end

		transition_state(self, "")
		return
	end
end



-- In order to correctly follow a path, this function requires to be called once
-- per frame. This property is specified in the state machine table.
local function do_pathfind_state(self, dtime)
	if not self.path.following or not self.path.way then
		transition_state(self, "")
		return
	end

	-- No very long paths [MustTest]. Note that the engine is now a lot better at
	-- pathfinding, so bad paths aren't often generated anymore. I can leave the
	-- limit fairly high.
	local max_len = (self.pathing_radius or 16) * 4
	if #self.path.way > max_len then
		transition_state(self, "")
		return
	end

	local wp = self.path.way[1]

	if not wp then
		transition_state(self, "")
		return
	end

	-- Debug path display.
	highlight_path(self)

	local s = self.object:get_pos()
	local dist = get_distance(wp, s)

	-- Note: waypoint may be vertical from us (above or below).
	if dist < 0.6 then
		-- Reached waypoint, remove it from queue.
		table.remove(self.path.way, 1)
		self.path.waypoints_gotten = (self.path.waypoints_gotten or 0) + 1

		-- Are we done following the path?
		if #self.path.way == 0 then
			pop_state(self)
			return
		end

		-- Take shortcuts only if we've gotten a few waypoints successfully already.
		-- The requirement that we must first traverse at least 4 waypoints prevents
		-- rapid switching between the "main", "newpath", and "rondev" states.
		-- Overall, taking shortcuts makes mob movement look a bit better, at the
		-- cost that sometimes the mob walks into a trap and has to path out of it.
		-- A 50/50 random number helps to break up circular traps.
		local count = random(4, 8)
		local fw = self.path.way[count]
		if random(1, 2) == 1 and fw and abs(wp.y - fw.y) <= 2 and self.path.waypoints_gotten > 4 then
			local y1 = self.object:get_yaw()
			local y2 = yaw_to_pos(self, fw, s)
			local d = yaw_delta(y1, y2)

			if d > rad(20) then
				-- Move raycast up a bit to improve behavior over rough terrain.
				local a = {x=0, y=1, z=0}
				if raycast_los(self, v_add(s, a), v_add(fw, a)) then
					for i = 1, (count - 1), 1 do
						table.remove(self.path.way, 1)
					end
					self.path.rondev_timeout = 5
					transition_substate(self, "rondev")
				end
			end
		end
	elseif dist > 3 then -- Dist factor is a bit arbitrary right now.
		-- We are some distance to the waypoint. Transition to the "rondev" state,
		-- which tries to walk the mob to the target in a direct line.
		self.path.rondev_timeout = 5
		transition_substate(self, "rondev")
		return
	end

	-- Is mob directly over or under the target?
	-- If so, mob should move more slowly so we don't miss the waypoint.
	local on_target = false
	if abs(wp.x - s.x) < 0.2 and abs(wp.z - s.z) < 0.2 then
		on_target = true
	end

	-- Note: the 'facing_wall_or_pit' function also checks for dangerous nodes.
	-- But some dangerous nodes are non-walkable, which means the pathfinder
	-- would path through them.
	local path_careful = false
	if not self.path.dangerous_paths then
		if waypoint_dangerous(self, wp) then
			-- Usually happens due to paths through deadly liquid.
			transition_substate(self, "blocked")
			return
		elseif is_wall_or_pit(self, wp) then
			-- This can happen if the environment changed (player dug pit or wall?).
			self.path.blocked_count = self.path.blocked_count + 1
			transition_substate(self, "blocked")
			return
		else
			-- Soft "slowdown" check has to be performed last.
			local result, reason = facing_wall_or_pit(self)
			if result and (reason == "pit" or reason == "danger") then
				-- Path goes in the direction of something dangerous, like a cliff.
				-- But we don't care if the path is next to a wall.
				path_careful = true
			end
		end
	end

	-- Query whether path is straight. Note: do this BEFORE rotating mob.
	-- The mob's initial yaw is taken into account.
	local sharp_turn = (not path_is_straight(self, s))

	-- Get the mob facing in the right direction.
	local yaw = yaw_to_pos(self, wp, s)
	set_yaw(self, yaw)

	-- Start moving to next waypoint.
	if on_target then
		-- Slow down so we don't overshoot waypoint.
		set_velocity(self, 0.1)
		set_animation(self, "walk", 5)
	elseif path_careful then
		-- Slow down when near dangerous terrain.
		local half_run = ((self.walk_velocity or 0) + (self.run_velocity or 0)) / 2
		set_velocity(self, half_run)
		set_animation(self, "walk")
	elseif sharp_turn then
		-- Slow down to execute turns.
		set_velocity(self, self.run_velocity or 0)
		set_animation(self, "run")
	else
		set_velocity(self, self.sprint_velocity or 0)
		set_animation(self, "run")
	end

	-- Jump only if next waypoint is higher than us.
	if wp.y > s.y then
		try_jump(self, dtime)
	end

	-- Is mob becoming stuck? (Haven't removed next waypoint in timely manner.)
	-- Note that this can trigger if the mob just moves too slowly, so we should
	-- avoid very-slow-moving behaviors when possible.
	if self.stuck_timer > 3 then
		self.path.blocked_count = self.path.blocked_count + 1
		transition_substate(self, "blocked")
		return
	end
end



-- In this state, the mob is some distance from the first waypoint in the path,
-- and must move toward it in a direct line.
local function do_pathfind_rondev(self, dtime)
	if not self.path.following or not self.path.way then
		pop_state(self)
		return
	end

	local wp = self.path.way[1]

	if not wp then
		pop_state(self)
		return
	end

	-- If we've exceeded the time budget for this action, we must be blocked.
	self.path.rondev_timeout = (self.path.rondev_timeout or 0) - dtime
	if self.path.rondev_timeout < 0 then
		self.path.blocked_count = self.path.blocked_count + 1
		transition_substate(self, "blocked")
		return
	end

	local s = self.object:get_pos()

	-- Get the mob facing in the right direction.
	local yaw = yaw_to_pos(self, wp, s)
	set_yaw(self, yaw)

	if facing_wall_or_pit(self) then
		set_velocity(self, 0)
		transition_substate(self, "newpath")
		return
	end

	-- Slow down (half-run) to execute shortcuts.
	set_velocity(self, self.run_velocity)
	set_animation(self, "run")

	try_jump(self, dtime)

	if get_distance(wp, s) < 1.0 then
		transition_substate(self, "")
		return
	end
end



local function try_unblock_path(self)
	--report(self, "try unblock path")
	local s = get_standing_pos(self)
	local p = get_ahead_pos(self)

	local w1 = self.path.way[1]
	local w2 = self.path.way[2]

	-- First, check if the waypoint is inside a walkable or dangerous node. This
	-- would happen if the player (or another mob) modified the environment
	-- through which the path traveled, by placing a block on it.
	if w1 then
		local nn = minetest.get_node(w1).name
		local ndef = minetest.registered_nodes[nn]
		if ndef.walkable or is_node_dangerous(self, nn, ndef) then
			--report(self, "floating in: " .. nn)
			if try_break_block(self, w1) then
				return "continue"
			elseif try_place_block(self, v_add(w1, {x=0, y=1, z=0})) then
				-- Jump up to avoid getting stuck in placed node.
				if w1.y + 1 >= p.y then
					force_jump_up(self, 1)
				end
				-- Move waypoint 2 nodes up and try to continue the same path.
				w1.y = w1.y + 2
				return "continue"
			else
				return ""
			end
		end
	end

	-- Check if the waypoint floating OVER non-walkable (like air). For example,
	-- player might have dug a pit in the mob's path.
	do
		local p2 = v_add(w1, {x=0, y=-1, z=0})
		local nn = minetest.get_node(p2).name
		local ndef = minetest.registered_nodes[nn]
		if not ndef.walkable or is_node_dangerous(self, nn, ndef) then
			report(self, "floating over")
			if try_place_block(self, p2) then
				-- Waypoint goes over placed block; path not modified.
				return "continue"
			elseif try_place_block(self, w1) then
				return "newpath"
			else
				return ""
			end
		end
	end

	-- Is path obstructed by a mob or player?
	if w1 then
		-- Note: w1 is the obstructed waypoint, w2 is the waypoint beyond.
		local obstructed = false
		local can_move = false

		-- Check both the next waypoint AND the mob's "ahead" pos. They might be
		-- separated by some distance, and thus one might be blocked while the other
		-- is not.
		local objs = get_targets_in_radius(self, w1, 1.5)
		if #objs > 0 then
			obstructed = true
		else
			objs = get_targets_in_radius(self, p, 1.5)
			if #objs > 0 then obstructed = true end
		end

		-- Make sure nothing is obstructing the mob (assuming 2-node high mob).
		if obstructed then
			local p2 = v_add(w1, {x=0, y=1, z=0})
			if try_break_block(self, p2) then
				can_move = true
			end
		end

		if obstructed and can_move then
			-- If obstructed, I can deal with this by simply moving the mob by fiat.
			-- Note: cannot use move_to(), it simply collides.
			local t = vector.copy(w1)
			t.y = (t.y - 0.5) + abs(self.collisionbox[2])
			self.object:set_pos(t) -- Place mob exactly on ground.

			-- Remove waypoint.
			table.remove(self.path.way, 1)
			return "continue"
		end
	end

	-- Path goes over a hump while ceiling prevents jumping.
	-- (This function doesn't check for a ceiling, but we assume there is one,
	-- otherwise the movement code would have just jumped over the hump.)
	if w1 and w1.y == p.y + 1 then
		if w2 and w2.y <= w1.y then
			local result, reason = try_break_block(self, p)
			if result then
				-- Modify path slightly.
				w1.y = w1.y - 1
				return "continue"
			else
				-- Couldn't remove blockage (protected, unbreakable, etc.).
				-- Try something else.
				if try_place_block(self, w1) then
					return "newpath"
				end
			end
		end
	end

	-- Path's next waypoint is 2 nodes or higher from mob's ahead position.
	-- Most mobs can't jump this high (neither can the player, usually).
	if w1 and w1.y > p.y + 1 then
		local p2 = v_add(w1, {x=0, y=-1, z=0})
		local result, reason = try_break_block(self, p2)
		if result then
			-- Modify path slightly.
			w1.y = w1.y - 1
			return "continue"
		else
			-- Couldn't remove blockage (protected, unbreakable, etc.).
			-- Try something else.
			if try_place_block(self, w1) then
				return "newpath"
			end
		end
	end

	-- Path goes straight ahead flat (or down). Mob is probably blocked by
	-- blockage over a 1x1 hole or other space too low to fit its head through.
	if w1 and w1.y <= p.y then
		local p2 = v_add(p, {x=0, y=1, z=0})
		local result, reason = try_break_block(self, p2)
		if result then
			-- Keep following path unmodified.
			return "continue"
		else
			-- Couldn't remove blockage (protected, unbreakable, etc.).
			-- Try something else.
			if try_place_block(self, w1) then
				return "newpath"
			end
		end
	end

	-- Path goes up stairs. In this case, we DON'T want to dig the stair node.
	-- We have to dig the ceiling instead.
	if w1 and w2 and w1.y > p.y and w2.y > w1.y then
		local p2 = get_standing_pos(self)
		p2.y = p2.y + 2
		local result, reason = try_break_block(self, p2)
		if result then
			-- Keep following path.
			return "continue"
		else
			-- Couldn't remove ceiling blockage (protected, unbreakable, etc.).
			-- Try something else.
			if try_place_block(self, w1) then
				return "newpath"
			end
		end
	end

	return ""
end



-- This pathfinding state attempts to remove (or place) blocks in order to get
-- around blockages. It should only be entered if the mob's pathfinding value is
-- 2 or greater.
local function do_pathfind_blocked(self, dtime)
	-- Usually, mob should be facing whatever is blocking us. Generally, only
	-- other entities (like mobs) and physical terrain are responsible for this.
	if not self.path.following or not self.path.way then
		transition_state(self, "")
		return
	end

	-- Blocked too many times without successful unblocking? Give up.
	if self.path.blocked_count > 3 then
		transition_state(self, "")
		return
	end

	-- Mob does not support this level of pathfinding?
	if (self.pathfinding or 0) < 2 then
		transition_state(self, "")
		return
	end

	local wp = self.path.way[1]
	if not wp then
		transition_state(self, "")
		return
	end

	-- Halt mob's movement while we try to unblock the path.
	set_velocity(self, 0)
	set_animation(self, "stand")

	-- Get mob facing the next waypoint (and the blockage, presumably).
	local yaw = yaw_to_pos(self, wp, self.object:get_pos())
	set_yaw(self, yaw)

	-- Limit the rate at which blockage is removed.
	self.path.blocked_timer = (self.path.blocked_timer or 0) + dtime
	if self.path.blocked_timer > 1 then
		self.path.blocked_timer = 0

		local result = try_unblock_path(self)

		if result == "continue" then
			-- Continue original path. (Note: path might have been modified slightly.)
			self.path.blocked_count = 0
			transition_substate(self, "")
			return
		elseif result == "newpath" then
			-- The attempt resulted in the environment being changed; retry pathfinder.
			self.path.blocked_count = 0
			transition_substate(self, "newpath")
			return
		else
			-- Couldn't remove blockage.
			pop_state(self)
			return
		end
	end
end



local function do_pathfind_exit(self)
	self.path.following = false
	self.path.way = nil
	self.path.dangerous_paths = false
end



-- Pillar and tunnel to get to the target.
local function do_digbuild_state(self, dtime)
	-- Pathfinder does not have a target?
	if not self.digbuild.target then
		transition_state(self, "")
		return
	end

	-- Mob does not support this level of pathfinding?
	if (self.pathfinding or 0) < 3 then
		transition_state(self, "")
		return
	end

	-- Has mob reached its objective?
	if v_distance(self.object:get_pos(), self.digbuild.target) < 1 then
		pop_state(self)
		return
	end

	local s = self.object:get_pos()
	local p = self.digbuild.target
	local yaw = yaw_to_pos(self, p, s)
	set_yaw(self, yaw)

	-- Start moving! The goal is to get as close to the target as possible in the
	-- X,Z plane before we go up or down.
	local face_result, face_reason = facing_wall_or_pit(self)

	-- If the mob is over or under the target, slow down.
	local overunder = false
	if abs(s.x - p.x) < 0.5 and abs(s.z - p.z) < 0.5 then
		velocity = self.walk_velocity or 0
		overunder = true
	elseif abs(s.x - p.x) < 0.2 and abs(s.z - p.z) < 0.2 then
		overunder = true
		velocity = 0.1
	end

	if face_result or overunder then
		set_velocity(self, 0)
		set_animation(self, "stand")
	else
		-- Get mob moving in the right direction.
		local velocity = self.run_velocity or 0
		set_velocity(self, velocity)
		set_animation(self, "run")
		try_jump(self, dtime)
		return
	end

	-- Another function handles the obstacle we (hopefully) just ran into.
	if face_reason == "wall" or face_reason == "pit" or overunder then
		transition_substate(self, "obstacle")
		return
	end

	if self.stand_timer > 1 then
		transition_substate(self, "obstacle")
		return
	end
end



-- Dig up until we reach the top of a wall.
local function do_digbuild_pillar(self, dtime)
	-- Do nothing until mob is centered in column. Otherwise might get stuck!
	if keep_mob_centered(self) then
		return
	end

	local s = self.object:get_pos()
	local p = self.digbuild.target
	local v = self.object:get_velocity()

	-- Get mob facing in the right direction.
	local yaw = yaw_to_pos(self, p, s)
	set_yaw(self, yaw)
	set_velocity(self, 0)

	-- Limit upward building to once per second.
	self.digbuild.node_timer = self.digbuild.node_timer + dtime
	if self.digbuild.node_timer > 0.5 then
		set_animation(self, "stand")
	end
	if self.digbuild.node_timer < 1 then return end
	self.digbuild.node_timer = 0

	-- Obviosly we can't pillar if the mob is currently falling. We check this
	-- only after checking the dig/build timer, otherwise it would run every frame
	-- and we would immediately exit the pillaring function on every upward jump.
	if v.y < 0 then
		transition_state(self, "")
		return
	end

	-- Ceiling position. Assume mob is 2 blocks high, so it digs above its
	-- head. Position is rounded, so we use a fixed integer.
	local sps = get_standing_pos(self)
	local cps = v_add(sps, {x=0, y=2, z=0})

	-- Cancel pillaring if we're above or near the target's X,Z level.
	if sps.y >= self.digbuild.target.y then
		transition_substate(self, "")
		return
	end

	-- Try to dig ceiling first, then place floor block. There is no point in
	-- placing the floor block unless we can dig the ceiling. Otherwise mob would
	-- just get stuck.
	if try_break_block(self, cps) then
		if try_place_block(self, sps) then
			set_animation(self, "punch")
			force_jump_up(self, 1)

			-- If we reach a plateau, we might be able to path from here.
			local decks = walkable_around(sps)
			if #decks > 1 then -- Always at least 1 due to self.
				-- Try swapping back to the pathfinder.
				-- Note: we assume that if the pathfinder cannot find a path, that it
				-- does NOT move the mob!
				self.path.target = self.digbuild.target
				pop_state(self)
				push_state(self, "pathfind")
				return
			end

			-- If we are above our target, we should switch to bridge/tunnel.
			if sps.y >= self.digbuild.target.y then
				transition_substate(self, "tunnel")
				return
			end
		else
			-- Cannot build, stop trying to get target.
			transition_state(self, "")
			return
		end
	else
		-- Cannot dig, stop trying to get target.
		transition_state(self, "")
		return
	end
end



local function do_digbuild_dig(self, dtime)
	-- Do nothing until mob is centered in column. Otherwise might get stuck!
	if keep_mob_centered(self) then
		return
	end

	local s = self.object:get_pos()
	local p = self.digbuild.target

	-- Get mob facing in the right direction.
	local yaw = yaw_to_pos(self, p, s)
	set_yaw(self, yaw)
	set_velocity(self, 0)

	-- Limit downward building to once per second.
	self.digbuild.node_timer = self.digbuild.node_timer + dtime
	if self.digbuild.node_timer > 0.5 then
		set_animation(self, "stand")
	end
	if self.digbuild.node_timer < 1 then return end
	self.digbuild.node_timer = 0

	-- Ground position.
	local sps = get_standing_pos(self)
	local fps = v_add(sps, {x=0, y=-1, z=0})
	local ups = v_add(sps, {x=0, y=-2, z=0})

	-- Cancel digging if we're below or near the target's X,Z level.
	if sps.y <= self.digbuild.target.y then
		transition_substate(self, "")
		return
	end

	-- Don't dig block below if mob would fall.
	if not pos_walkable(ups) then
		transition_state(self, "")
		return
	end

	if try_break_block(self, fps) then
		set_animation(self, "punch")

		-- If we reach a plateau, we might be able to path from here.
		local decks = walkable_around(v_add(fps, {x=0, y=-1, z=0}))
		if #decks > 1 then -- Always at least 1 due to self.
			-- Try swapping back to the pathfinder.
			-- Note: we assume that if the pathfinder cannot find a path, that it
			-- does NOT move the mob!
			self.path.target = self.digbuild.target
			pop_state(self)
			push_state(self, "pathfind")
			return
		end

		-- If we are below our target, we should switch to bridge/tunnel.
		if sps.y <= self.digbuild.target.y then
			transition_substate(self, "tunnel")
			return
		end
	else
		-- Cannot dig, stop trying to get target.
		transition_state(self, "")
		return
	end
end



local function do_digbuild_tunnel(self, dtime)
	-- Do nothing until mob is centered in column. Otherwise might get stuck!
	if keep_mob_centered(self) then
		return
	end

	-- Exit if falling.
	local v = self.object:get_velocity()
	if v.y < 0 then
		transition_state(self, "")
		return
	end

	local s = self.object:get_pos()
	local p = self.digbuild.target

	-- Get mob facing in the right direction.
	local yaw = yaw_to_pos(self, p, s)
	set_yaw(self, yaw)
	set_velocity(self, 0)

	--local face_result, face_reason = facing_wall_or_pit(self)

	-- If we're no longer facing a wall or other obstacle, we can stop
	-- tunneling/bridging operations (for now).
	--if face_reason == "surface" then
	--	transition_substate(self, "")
	--	return
	--end

	-- Face one of the cardinal directions, and if that direction is a surface,
	-- move to it.
	set_yaw(self, square_yaw(yaw))
	local face_result, face_reason = facing_wall_or_pit(self)
	if face_reason == "surface" then
		self.digbuild.move_to = get_ahead_pos(self)
		transition_substate(self, "move")
		return
	end

	-- Limit digging/building to once per second.
	self.digbuild.node_timer = self.digbuild.node_timer + dtime
	if self.digbuild.node_timer > 0.5 then
		set_animation(self, "stand")
	end
	if self.digbuild.node_timer < 1 then return end
	self.digbuild.node_timer = 0

	-- Tunnel/bridge position. Assume mob is 2 blocks high, so it digs blocks for
	-- its head. Position is rounded, so we use a fixed integer.
	local p1 = get_ahead_pos(self)
	local p2 = v_add(p1, {x=0, y=1, z=0})
	local p0 = v_add(p1, {x=0, y=-1, z=0})

	-- Place bridge block if needed.
	if not pos_walkable(p0) then
		try_place_block(self, p0, true)
	end

	-- Try digging the doorway.
	if try_break_block(self, p1) then
		if try_break_block(self, p2) then
			-- Both blocks facing forwards are successfully dug (or didn't exist).

			-- If we reach an opening, we might be able to path from here.
			-- Start with at least 2 due to self + path behind us.
			local amount = 2
			local decks = walkable_around(p0)
			if #decks <= 2 then
				-- In this case there shouldn't be more than 1 if there is no opening.
				decks = walkable_around(p1)
				amount = 1
			end

			if #decks > amount then
				-- Try swapping back to the pathfinder.
				-- Note: we assume that if the pathfinder cannot find a path, that it
				-- does NOT move the mob!
				self.path.target = self.digbuild.target
				pop_state(self)
				push_state(self, "pathfind")
				return
			end

			-- Move to the section we just built/dug.
			self.digbuild.move_to = p1
			self.digbuild.node_timer = 1
			transition_substate(self, "move")
		else
			-- Cannot dig, stop trying to get target.
			transition_state(self, "")
			return
		end
	else
		-- Cannot dig, stop trying to get target.
		transition_state(self, "")
		return
	end
end



-- Move the mob to the target location. We assume the distance to this location
-- is no more than 1.5 nodes, more or less, and that there are NO obstacles.
-- Once we've reached the target, we transition to the primary state.
local function do_digbuild_move(self, dtime)
	if not self.digbuild.move_to then
		transition_state(self, "")
		return
	end

	local s = self.object:get_pos()
	local c = self.digbuild.move_to

	-- Abort if stuck.
	if self.stuck_timer > 5 then
		transition_state(self, "")
		return
	end

	-- Walk to target.
	if abs(s.x - c.x) > 0.4 or abs(s.z - c.z) > 0.4 then
		set_yaw(self, yaw_to_pos(self, c, s))
		set_velocity(self, self.walk_velocity or 0)
		try_jump(self, dtime)
		set_animation(self, "walk")
		return
	end

	transition_substate(self, "")
end



-- This function expects that the mob is currently facing an obstacle, and NOT
-- currently moving.
local function do_digbuild_obstacle(self, dtime)
	if keep_mob_centered(self) then
		return
	end

	-- First, square the mob's yaw so we can accurately get the obstacle type.
	set_velocity(self, 0)
	set_yaw(self, square_yaw(self.object:get_yaw()))

	-- Wait a moment. (Note: timer only increments when mob is standing still!)
	--if self.stand_timer < 1 then
	--	report(self, "waiting ...")
	--	return
	--end

	local face_result, face_reason = facing_wall_or_pit(self)

	local s = self.object:get_pos()
	local p = self.digbuild.target

	-- Is target directly over or under us?
	if abs(p.x - s.x) < 0.3 and abs(p.z - s.z) < 0.3 then

		if s.y < (p.y - 0.9) then
			transition_substate(self, "pillar")
			return
		elseif s.y > (p.y + 0.9) then
			transition_substate(self, "dig")
			return
		else
			-- We have reached the target.
			pop_state(self)
			return
		end

	-- Is target more than 1 block higher, and we are facing a wall or pit?
	elseif p.y >= (s.y + 0.9) then
		if face_reason == "wall" then
			transition_substate(self, "pillar")
			return
		elseif face_reason == "pit" then
			transition_substate(self, "tunnel")
			return
		elseif face_reason == "surface" then
			self.digbuild.move_to = get_ahead_pos(self)
			transition_substate(self, "move")
			return
		else
			transition_state(self, "")
			return
		end

	-- Otherwise, is target more than 1 block lower than us?
	elseif p.y < (s.y - 0.9) then
		if face_reason == "pit" then
			transition_substate(self, "dig")
			return
		elseif face_reason == "wall" then
			transition_substate(self, "tunnel")
			return
		elseif face_reason == "surface" then
			self.digbuild.move_to = get_ahead_pos(self)
			transition_substate(self, "move")
			return
		else
			transition_state(self, "")
			return
		end

	-- Otherwise, we are (nearly) on the same level as the target.
	else
		-- Dig tunnel through rock, or build bridge through air.
		if face_reason == "pit" or face_reason == "wall" then
			transition_substate(self, "tunnel")
			return
		elseif face_reason == "surface" then
			self.digbuild.move_to = get_ahead_pos(self)
			transition_substate(self, "move")
			return
		end
	end

	-- Encountered a situation we don't know how to deal with. Cancel.
	transition_state(self, "")
end



local function do_follow_state(self, dtime)
	if not self.following then
		transition_state(self, "")
		return
	end

	local s = self.object:get_pos()
	local p = self.following:get_pos()

	-- Stop following if target doesn't exist anymore.
	if not p then
		transition_state(self, "")
		return
	end

	-- Stop following when (...) (who comes up with these terms? Geez).
	if self.horny then
		transition_state(self, "")
		return
	end

	-- Avoid dangerous nodes.
	if is_node_dangerous(self, self.standing_in) then
		push_state(self, "avoid")
		return
	end

	-- Stop following if no longer holding item the (non-NPC) mob wants. Does not
	-- apply to NPCs.
	if self.type ~= "npc" then
		if not follow_holding(self, self.following) then
			transition_state(self, "")
			return
		end
	end

	-- Follow that thing!
	local yaw = yaw_to_pos(self, p, s)
	set_yaw(self, yaw, 6)

	if v_distance(s, p) > self.reach then
		set_velocity(self, self.walk_velocity or 0)
		set_animation(self, "walk")
		try_jump(self, dtime)
	else
		set_velocity(self, 0)
		set_animation(self, "stand")
	end

	-- If stuck, maybe we can pathfind to target.
	if self.stuck_timer > 5 then
		if (self.pathfinding or 0) >= 1 then
			self.path.target = v_round(p)
			push_state(self, "pathfind")
			return
		else
			transition_state(self, "")
			return
		end
	end
end



local function do_follow_exit(self)
	self.following = nil
end



-- This table contains all the individual state functions and their transitions.
local state_machine = {
	-- State with no name.
	[""] = {
		enter = do_stand_enter,
		main = do_stand_state,
	},

	stand = {
		enter = do_stand_enter,
		main = do_stand_state,
	},

	walk = {
		enter = do_walk_enter,
		main = do_walk_state,
	},

	avoid = {
		enter = do_avoid_enter,
		main = do_avoid_state,
	},

	runaway = {
		enter = do_runaway_enter,
		main = do_runaway_state,
		continuous = true,
	},

	attack = {
		enter = do_attack_enter,
		exit = do_attack_exit,
		main = do_attack_state,
		chase = do_chase_attack,
		shoot = do_shoot_attack,
		caught = do_caught_attack,
		blocked = do_blocked_attack,
		continuous = true,
	},

	pathfind = {
		enter = do_pathfind_enter,
		main = do_pathfind_state,
		blocked = do_pathfind_blocked,
		newpath = do_pathfind_newpath,
		rondev = do_pathfind_rondev,
		exit = do_pathfind_exit,
		continuous = true,
	},

	digbuild = {
		main = do_digbuild_state,
		pillar = do_digbuild_pillar,
		dig = do_digbuild_dig,
		tunnel = do_digbuild_tunnel,
		move = do_digbuild_move,
		obstacle = do_digbuild_obstacle,
		continuous = true,
	},

	follow = {
		main = do_follow_state,
		exit = do_follow_exit,
	},
}

-- Export.
mobs.state_machine = state_machine



-- Execute current state (stand, walk, run, attacks). This function is rate
-- limited to reduce server load; thus 'dtime' may be large, but should usually
-- be within 1 second. [MustTest]
local function do_states(self, dtime)
	-- Stupid spurious bugs [MustTest]. Implies our object no longer exists.
	local yaw = self.object:get_yaw()
	if not yaw then return end

	-- Deal with invalid states. Note: unknown state types (non-empty string) are
	-- valid and we don't do anything with them; they can be used by some mobs.
	if not self.state or self.state == "" then
		transition_state(self, "stand")
	end

	--report(self, "current state: " .. self.state .. " (" .. self.substate .. ")", 2)

	-- Execute current state's main function.
	local sm = mobs.state_machine
	local state = sm[self.state]
	if state[self.substate] then
		state[self.substate](self, dtime)
	elseif state.main then
		state.main(self, dtime)
	end
end

-- Export.
mobs.do_states = function(...)
	do_states(...)
end



-- falling and fall damage
local function falling(self, pos)

	if self.fly then
		return
	end

	-- floating in water (or falling)
	local v = self.object:get_velocity()

	if v.y > 0 then

		-- apply gravity when moving up
		self.object:set_acceleration({
			x = 0,
			y = -10,
			z = 0
		})

	elseif v.y <= 0 and v.y > self.fall_speed then

		-- fall downwards at set speed
		self.object:set_acceleration({
			x = 0,
			y = self.fall_speed,
			z = 0
		})
	else
		-- stop accelerating once max fall speed hit
		self.object:set_acceleration({x = 0, y = 0, z = 0})
	end

	-- If in water then float up. Nil check.
	local ndef = self.standing_in and minetest.reg_ns_nodes[self.standing_in]
	if ndef and ndef.groups.water then
		if self.floats == 1 then
			self.object:set_acceleration({
				x = 0,
				y = -self.fall_speed / (max(1, v.y) ^ 8), -- 8 was 2
				z = 0
			})
		end
	else

		-- fall damage onto solid ground
		if self.fall_damage == 1
		and self.object:get_velocity().y == 0 then

			local d = (self.old_y or 0) - self.object:get_pos().y

			if d > 5 then

				self.health = self.health - floor(d - 5)

				effect(pos, 5, "tnt_smoke.png", 1, 2, 2, nil)

				if check_for_death(self, "fall", {type = "fall"}) then
					return
				end
			end

			self.old_y = self.object:get_pos().y
		end
	end
end



-- is Took Ranks mod active?
local tr = minetest.get_modpath("toolranks")



-- Deal damage and effects when mob punched.
local function mob_punch(self, hitter, tflp, tool_capabilities, dir)
	-- Mob health check.
	if self.health <= 0 then return end

	-- Sanity check.
	if not tool_capabilities then return end

	-- Custom punch function.
	if self.do_punch then
		-- When false skip going any further.
		if self.do_punch(self, hitter, tflp, tool_capabilities, dir) == false then
			return
		end
	end

	-- Record name of last attacker.
	self.last_attacked_by = (hitter and hitter:is_player() and hitter:get_player_name()) or ""

	if hitter then
		if hitter:is_player() then
			cloaking.disable_if_enabled(hitter:get_player_name(), true)
		end
	end

	-- Is mob protected?
	if self.protected and hitter:is_player()
			and minetest.test_protection(v_round(self.object:get_pos()), hitter:get_player_name()) then
		minetest.chat_send_player(hitter:get_player_name(), "# Server: Mob has been protected!")
		return
	end

	-- weapon wear
	local weapon = hitter:get_wielded_item()
	--minetest.log("weapon: <" .. weapon:get_name() .. ">")
	local punch_interval = 1.4

	-- calculate mob damage
	local damage = 0
	local armor = self.object:get_armor_groups() or {}
	local tmp

	-- quick error check incase it ends up 0 (serialize.h check test)
	if tflp == 0 then
		tflp = 0.2
	end

	do
		for group,_ in pairs( (tool_capabilities.damage_groups or {}) ) do
			tmp = tflp / (tool_capabilities.full_punch_interval or 1.4)

			if tmp < 0 then
				tmp = 0.0
			elseif tmp > 1 then
				tmp = 1.0
			end

			damage = damage + (tool_capabilities.damage_groups[group] or 0)
				* tmp * ((armor[group] or 0) / 100.0)
		end
	end

	-- check for tool immunity or special damage
	for n = 1, #self.immune_to do
		if self.immune_to[n][1] == weapon:get_name() then

			damage = self.immune_to[n][2] or 0
			break

		-- if "all" then no tool does damage unless it's specified in list
		elseif self.immune_to[n][1] == "all" then
			damage = self.immune_to[n][2] or 0
		end
	end

	-- healing
	if damage <= -1 then
		self.health = self.health - floor(damage)
		return
	end

	-- add weapon wear
	if tool_capabilities then
		punch_interval = tool_capabilities.full_punch_interval or 1.4
	end

	if weapon:get_definition()
			and weapon:get_definition().tool_capabilities then

		-- toolrank support
		local wear = floor((punch_interval / 75) * 9000)

		if mobs.is_creative(hitter:get_player_name()) then
			if tr then
				wear = 1
			else
				wear = 0
			end
		end

		if tr then
			if weapon:get_definition()
					and weapon:get_definition().original_description then
				weapon:add_wear(toolranks.new_afteruse(weapon, hitter, nil, {wear = wear}))
			end
		else
			weapon:add_wear(wear)
		end

		hitter:set_wielded_item(weapon)
	end

	-- only play hit sound and show blood effects if damage is 1 or over
	if damage >= 1 then

		-- weapon sounds
		if weapon:get_definition().sounds ~= nil then

			local s = random(0, #weapon:get_definition().sounds)

			minetest.sound_play(weapon:get_definition().sounds[s], {
				object = self.object, --hitter,
				max_hear_distance = 20
			}, true)
		else
			minetest.sound_play("default_punch", {
				object = self.object, --hitter,
				max_hear_distance = 20
			}, true)
		end

		-- blood_particles
		if self.blood_amount > 0 and not disable_blood then
			local pos = self.object:get_pos()

			pos.y = pos.y + (-self.collisionbox[2] + self.collisionbox[5]) * .5

			-- do we have a single blood texture or multiple?
			if type(self.blood_texture) == "table" then
				local blood = self.blood_texture[random(1, #self.blood_texture)]
				effect(pos, self.blood_amount, blood, nil, nil, 1, nil)
			else
				effect(pos, self.blood_amount, self.blood_texture, nil, nil, 1, nil)
			end
		end

		-- do damage
		self.health = self.health - floor(damage)

		-- exit here if dead, special item check
		if weapon:get_name() == "mobs:pick_lava" then
			if check_for_death(self, "lava", {
						type = "punch",
						puncher = hitter,
						tool_capabilities = tool_capabilities,
						wielded = weapon,
					}) then
				return
			end
		else
			if check_for_death(self, "hit", {
						type = "punch",
						puncher = hitter,
						tool_capabilities = tool_capabilities,
						wielded = weapon,
					}) then
				return
			end
		end

		--[[ add healthy afterglow when hit (can cause hit lag with larger textures)
		minetest.after(0.1, function()

			if not self.object:get_luaentity() then return end

			self.object:settexturemod("^[colorize:#c9900070")

			core.after(0.3, function()
				self.object:settexturemod("")
			end)
		end) ]]

		-- knock back effect (only on full punch)
		if self.knock_back and tflp >= punch_interval then
			local v = self.object:get_velocity()
			local r = 1.4 - min(punch_interval, 1.4)
			local kb = r * 5
			local up = 2

			-- if already in air then dont go up anymore when hit
			if v.y > 0
			or self.fly then
				up = 0
			end

			-- direction error check
			dir = dir or {x = 0, y = 0, z = 0}

			-- check if tool already has specific knockback value
			if tool_capabilities.damage_groups["knockback"] then
				kb = tool_capabilities.damage_groups["knockback"]
			else
				kb = kb * default_knockback
			end

			self.object:set_velocity({
				x = dir.x * kb,
				y = up,
				z = dir.z * kb
			})

			self.pause_timer = 0.25
		end
	end -- END if damage

	-- If skittish then run away.
	if self.runaway == true then

		local lp = hitter:get_pos()
		local s = self.object:get_pos()

		local yaw = yaw_to_pos(self, lp, s)
		yaw = yaw + pi -- go in reverse
		yaw = set_yaw(self, yaw, 6)

		transition_state(self, "runaway")
		return
	end

	-- Ignore punches from self.
	if self.object == hitter then return end

	-- Ignore punches if mob is passive.
	if self.passive then return end
	if self.child then return end

	-- Ignore punches from owner.
	local name = (hitter:is_player() and hitter:get_player_name()) or ""
	if name ~= "" and name == self.owner then
		return
	end

	-- Note: mob can defend itself if punched by invisible players, so no
	-- invisibility check here.

	-- Attack whoever punched mob (if not already attacking that player/mob).
	if self.state ~= "attack" or self.attack ~= hitter then
		transition_state(self, "")
		do_attack(self, hitter)
	end

	if not self.group_attack then return end

	-- Alert others to the attack.
	local objs = minetest.get_objects_inside_radius(hitter:get_pos(), self.view_range)

	for n = 1, #objs, 1 do
		local obj = objs[n]:get_luaentity()

		if obj and obj._cmi_is_mob then
			-- Alert members of same mob if have 'group_attack'.
			if obj.state ~= "attack" and obj.name == self.name then
				-- But owned mobs will not attack their owners.
				if not (obj.owner == name) then
					do_attack(obj, hitter)
				end
			end

			-- have owned mobs attack player threat
			if name ~= "" and obj.owner == name and obj.owner_loyal then
				do_attack(obj, self.object)
			end
		end
	end
end



-- export!
function mobs.mob_punch(self, hitter, tflp, tool_capabilities, dir)
	return mob_punch(self, hitter, tflp, tool_capabilities, dir)
end



-- get entity staticdata
local function mob_staticdata(self)

	-- remove mob when out of range unless tamed
	if remove_far
			and self.remove_ok
			and self.type ~= "npc"
			and self.state ~= "attack"
			and not self.tamed
			and self.lifetimer < 20000 then

		--print ("REMOVED " .. self.name)

		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return ""-- nil
	end

	self.remove_ok = true
	self.attack = nil
	self.following = nil
	self.state = "stand"
	self.substate = ""

	-- used to rotate older mobs
	if self.drawtype and self.drawtype == "side" then
		self.rotate = rad(90)
	end

	local tmp = {}

	for _,stat in pairs(self) do

		local t = type(stat)

		if  t ~= "function" and t ~= "nil" and t ~= "userdata" and _ ~= "_cmi_components" then
			tmp[_] = self[_]
		end
	end

	--print('===== '..self.name..'\n'.. dump(tmp)..'\n=====\n')
	return minetest.serialize(tmp)
end



-- export!
function mobs.mob_staticdata(self)
	return mob_staticdata(self)
end



-- Activate mob and reload settings.
local function mob_activate(self, staticdata, def, dtime)

	-- Remove mob if activated during daytime and has 'daytime_despawn'.
	if def.daytime_despawn then
		local tod = (minetest.get_timeofday() or 0) * 24000
		if tod > 4500 and tod < 19500 then
			-- Daylight, but mob despawns at daytime.

			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			return
		end
	end

	-- Remove mob if outside realm dimensions.
	if not rc.is_valid_realm_pos(self.object:get_pos()) then
		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return
	end

	-- load entity variables
	local tmp = minetest.deserialize(staticdata)
	if tmp then
		for _, stat in pairs(tmp) do
			self[_] = stat
		end
	end

	-- Do select random texture, set model and size.
	if not self.base_texture then

		-- Do compatiblity with old simple mobs textures.
		if def.textures and type(def.textures[1]) == "string" then
			def.textures = {def.textures}
		end

		self.base_texture = def.textures and def.textures[random(1, #def.textures)]
		self.base_mesh = def.mesh
		self.base_size = self.visual_size
		self.base_colbox = self.collisionbox
		self.base_selbox = self.selectionbox
	end

	-- for current mobs that dont have this set
	if not self.base_selbox then
		self.base_selbox = self.selectionbox or self.base_colbox
	end

	-- set texture, model and size
	local textures = self.base_texture
	local mesh = self.base_mesh
	local vis_size = self.base_size
	local colbox = self.base_colbox
	local selbox = self.base_selbox

	-- specific texture if gotten
	if self.gotten == true and def.gotten_texture then
		textures = def.gotten_texture
	end

	-- specific mesh if gotten
	if self.gotten == true and def.gotten_mesh then
		mesh = def.gotten_mesh
	end

	-- set child objects to half size
	if self.child == true then

		vis_size = {
			x = self.base_size.x * .5,
			y = self.base_size.y * .5,
		}

		if def.child_texture then
			textures = def.child_texture[1]
		end

		colbox = {
			self.base_colbox[1] * .5,
			self.base_colbox[2] * .5,
			self.base_colbox[3] * .5,
			self.base_colbox[4] * .5,
			self.base_colbox[5] * .5,
			self.base_colbox[6] * .5
		}
		selbox = {
			self.base_selbox[1] * .5,
			self.base_selbox[2] * .5,
			self.base_selbox[3] * .5,
			self.base_selbox[4] * .5,
			self.base_selbox[5] * .5,
			self.base_selbox[6] * .5
		}
	end

	if self.health == 0 then
		-- Choose full health from min/max HP.
		-- Then, set max HP to chosen value.
		self.health = random (self.hp_min, self.hp_max)
		self.hp_max = self.health
	end

	-- Pathfinding init.
	self.path = {}
	self.path.way = {} -- path to follow, table of positions
	self.path.lastpos = {x = 0, y = 0, z = 0}
	self.path.following = false -- currently following path?
	self.path.pos_rec_timer = 0
	self.path.find_path_timer = 0
	self.path.putnode_timer = 0
	self.path.los_counter = 0
	self.path.los_check = 0
	self.path.target = nil

	-- Avoidance "avoid" state init.
	self.avoid = {}
	self.avoid.target = nil
	self.avoid.timer = 0

	-- Dig/build state init.
	self.digbuild = {}
	self.digbuild.target = nil
	self.digbuild.node_timer = 0

	-- Adjust the chance to use pathfinding on a per-entity basis.
	if self.pathfinding and self.pathfinding ~= 0 then
		-- If pathfinding is enabled, by default chance is 100%.
		local chance = self.pathfinding_chance or 100
		local res = random(1, 100)

		if res > chance then
			self.pathfinding = 0
		end
	end

	-- mob defaults
	-- Hmmm ... setting 'immortal' prevents Minetest's default damage calculation.
	self.object:set_armor_groups(utility.builtin_armor_groups({immortal = 1, fleshy = self.armor}))
	self.old_y = self.object:get_pos().y
	self.old_health = self.health
	self.sounds.distance = self.sounds.distance or 10
	self.textures = textures
	self.mesh = mesh
	self.collisionbox = colbox
	self.selectionbox = selbox
	self.visual_size = vis_size
	self.standing_in = "air"
	self.standing_on = "air"

	-- check existing nametag
	if not self.nametag then
		self.nametag = def.nametag
	end

	-- set anything changed above
	self.object:set_properties(self)
	set_yaw(self, (random(0, 360) - 180) / 180 * pi, 6)
	update_tag(self)
	set_animation(self, "stand")

	-- run on_spawn function if found
	if self.on_spawn and not self.on_spawn_run then
		if self.on_spawn(self) then
			self.on_spawn_run = true --  if true, set flag to run once only
		end
	end

	-- run after_activate
	if def.after_activate then
		def.after_activate(self, staticdata, def, dtime)
	end
end



-- export!
function mobs.mob_activate(self, staticdata, def, dtime)
	return mob_activate(self, staticdata, def, dtime)
end



local function smooth_rotate(self)
	-- smooth rotation by ThomasMonroe314

	if self.delay and self.delay > 0 then

		local yaw = self.object:get_yaw()

		if self.delay == 1 then
			yaw = self.target_yaw
		else
			local dif = abs(yaw - self.target_yaw)

			if yaw > self.target_yaw then

				if dif > pi then
					dif = 2 * pi - dif -- need to add
					yaw = yaw + dif / self.delay
				else
					yaw = yaw - dif / self.delay -- need to subtract
				end

			elseif yaw < self.target_yaw then

				if dif > pi then
					dif = 2 * pi - dif
					yaw = yaw - dif / self.delay -- need to subtract
				else
					yaw = yaw + dif / self.delay -- need to add
				end
			end

			if yaw > (pi * 2) then yaw = yaw - (pi * 2) end
			if yaw < 0 then yaw = yaw + (pi * 2) end
		end

		self.delay = self.delay - 1
		self.object:set_yaw(yaw)
	end

	-- end rotation
end



local function stuck_timer(self, dtime, pos)
	-- Set up 'is_stuck' state flag/timer. This is a timer which clocks how long
	-- the mob has not moved for. It is clamped whenever it exceeds 100 seconds,
	-- and reset when the mob's position changes.
	if (self.wanted_velocity or 0) > 0 then
		self.stuck_timer = (self.stuck_timer or 0) + dtime
		if self.stuck_timer > 100 then self.stuck_timer = 100 end
		if v_distance(self.last_pos or pos, pos) > 0.001 then
			self.stuck_timer = 0
		end
		self.last_pos = pos
		self.stand_timer = 0
	else
		-- If the wanted velocity is zero, the stuck-timer does not run.
		-- We are obviously not stuck in such a case!
		self.last_pos = pos
		self.stuck_timer = 0

		self.stand_timer = (self.stand_timer or 0) + dtime
		if self.stand_timer > 100 then self.stand_timer = 100 end
	end
end



local function do_punch_timer(self, dtime)
	self.punch_timer = (self.punch_timer or 0) - dtime
	if self.punch_timer < 0 then
		self.punch_timer = 0
	end
end



-- Here is the main mob function.
local function mob_step(self, dtime)
	-- The final (actually first) action of mob_step().
	-- If the mob was marked for removal, we call self.object:remove() here.
	-- This: self.object:remove(), should not be called anywhere else!
	if self.mkrm then self.object:remove(); return end

	-- Stupid spurious errors [MustTest]. Implies our object does not exist.
	local pos = self.object:get_pos()
	if not pos then return end

	-- Manage stuck-timer.
	stuck_timer(self, dtime, pos)

	-- When lifetimer expires, remove mob.
	do_lifetimer(self, pos)

	-- Get what nodes the mob is standing in/on.
	update_foot_nodes(self, pos, dtime)

	-- Check if falling, flying, floating.
	falling(self, pos)

	-- Do smooth rotation.
	smooth_rotate(self)

	-- Manage punch timer.
	do_punch_timer(self, dtime)

	-- Knockback timer. If set, the mob will do nothing until it expires!
	-- Typically this would be set for something like a knockback effect.
	if self.pause_timer > 0 then
		self.pause_timer = self.pause_timer - dtime

		return
	end

	-- Run custom function (defined in mob's script file).
	if self.do_custom then

		-- when false skip going any further
		if self.do_custom(self, dtime) == false then
			return
		end
	end

	-- Environmental damage timer (every 1 second).
	self.env_damage_timer = self.env_damage_timer + dtime

	if self.env_damage_timer >= 1 then
		self.env_damage_timer = 0

		-- Check for environmental damage (water, fire, lava, etc.).
		do_env_damage(self)

		-- Node replace check (cow eats grass, etc.).
		replace(self, pos)

		-- Debug path display.
		highlight_path(self)
	end

	-- Mob plays random sound at times.
	self.sound_timer = (self.sound_timer or 0) + dtime
	if self.sound_timer >= 1 then
		if random(1, 100) == 1 then
			mob_sound(self, self.sounds.random)
		end
		self.sound_timer = 0
	end

	-- This code forces state logic to only run once per second, unless the
	-- current state is flagged to execute continuously. This reduces load on the
	-- server.
	local sm = state_machine
	if not sm[self.state].continuous then
		self.logic_timer = (self.logic_timer or 0) + dtime
		if self.logic_timer < 1 then return end
		self.logic_timer = 0

		-- Since we return early if time is less than 1 second, once timer fires,
		-- we need to pass a 'dtime' of 1 to the logic that follows.
		dtime = 1
	end

	-- Limit the general scanning functions to once per second.
	self.scan_timer = (self.scan_timer or 0) + dtime
	if self.scan_timer >= 1 then
		self.scan_timer = 0

		-- For belligerent mobs, scan for victims to attack.
		general_attack(self)

		-- For skittish mobs, scan for things to run away from.
		runaway_from(self)

		-- Mob reproduction.
		attempt_breed(self)

		-- Periodically refocus attacking mobs.
		refocus_attack(self)

		-- Scan for things to follow around.
		follow_something(self)
	end

	do_states(self, dtime)
end



-- export!
function mobs.mob_step(self, dtime)
	return mob_step(self, dtime)
end



-- Default function when mobs are blown up with TNT.
local function do_tnt(obj, damage)

	obj.object:punch(obj.object, 1.0, {
		full_punch_interval = 1.0,
		damage_groups = {boom = damage},
	}, nil)

	return false, true, {}
end



-- export!
function mobs.do_tnt(obj, damage)
	return do_tnt(obj, damage)
end



local function first_or_second(arg1, arg2)
    if type(arg1) ~= "nil" then
        return arg1
    else
        return arg2
    end
end



-- register mob entity function
if not mobs.registered then
	mobs.spawning_mobs = {}

	-- Register mob function.
	mobs.register_mob = function(name, def)
		mobs.spawning_mobs[name] = true

		minetest.register_entity(name, {
			-- Warning: this parameter is set by the engine anway!
			name                    = name,

			_name                   = name,
			mob                     = true,
			type                    = def.type,
			armor_level             = def.armor_level or 0,
			description             = def.description,
			stepheight              = def.stepheight or 1.1,
			attack_type             = def.attack_type,
			fly                     = def.fly,
			fly_in                  = def.fly_in or "air",
			owner                   = def.owner or "",
			order                   = def.order or "",
			on_die                  = def.on_die,
			do_custom               = def.do_custom,

			-- The number of nodes a mob can jump over. Actual jump velocity is
			-- calculated from this. Supported values are 1, 2, 3.
			jump_height             = def.jump_height or 1,

			drawtype                = def.drawtype, -- DEPRECATED, use rotate instead
			rotate                  = rad(def.rotate or 0), --  0=front, 90=side, 180=back, 270=side2
			lifetimer               = def.lifetimer or 180, -- 3 minutes
			hp_min                  = (def.hp_min or (5*500)) * difficulty,
			hp_max                  = (def.hp_max or (10*500)) * difficulty,
			physical                = true,
			collisionbox            = def.collisionbox or {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
			selectionbox            = def.selectionbox or def.collisionbox,
			visual                  = def.visual,
			visual_size             = def.visual_size or {x = 1, y = 1},
			mesh                    = def.mesh,
			makes_footstep_sound    = def.makes_footstep_sound or false,
			view_range              = def.view_range or 5,
			walk_velocity           = def.walk_velocity or 1,
			run_velocity            = def.run_velocity or 2,
			sprint_velocity         = def.sprint_velocity or def.run_velocity or 2,

			-- Mob may do an exact amount of damage.
			-- But if min/max damage values are set (non-nil, non-0), those are used
			-- instead.
			damage                  = (def.damage or 0) * difficulty,
			damage_min              = (def.damage_min or 0) * difficulty,
			damage_max              = (def.damage_max or 0) * difficulty,
			damage_group            = def.damage_group,

			daytime_despawn         = def.daytime_despawn,
			on_despawn              = def.on_despawn,
			light_damage            = def.light_damage or 0,
			water_damage            = def.water_damage or 0,
			lava_damage             = def.lava_damage or 0,
			fire_damage             = def.fire_damage or 0,
			suffocation             = def.suffocation or 2,

			lava_annihilates        = first_or_second(def.lava_annihilates, true),
			makes_bones_in_lava     = first_or_second(def.makes_bones_in_lava, true),

			fall_damage             = def.fall_damage or (1*500),
			fall_speed              = def.fall_speed or -10, -- must be lower than -2 (default: -10)
			drops                   = def.drops or {},
			armor                   = def.armor or 100,
			on_rightclick           = def.on_rightclick,
			arrow                   = def.arrow,
			shoot_interval          = def.shoot_interval,
			sounds                  = def.sounds or {},
			animation               = def.animation,
			follow                  = def.follow,
			jump                    = def.jump ~= false,
			walk_chance             = def.walk_chance or 50,
			--fov = def.fov or 120,
			passive                 = def.passive or false,
			knock_back              = def.knock_back ~= false,
			blood_amount            = def.blood_amount or 5,
			blood_texture           = def.blood_texture or "mobs_blood.png",
			shoot_offset            = def.shoot_offset or 0,
			floats                  = def.floats or 1, -- floats in water by default
			replace_rate            = def.replace_rate,
			replace_what            = def.replace_what,
			replace_with            = def.replace_with,
			replace_offset          = def.replace_offset or 0,
			on_replace              = def.on_replace,

			-- Feature added by MustTest.
			replace_range           = def.replace_range or 1,
			despawns_in_dark_caves  = def.despawns_in_dark_caves or false,

			timer                   = 0,
			env_damage_timer        = 0, -- only used when state = "attack"
			tamed                   = false,
			pause_timer             = 0,
			horny                   = false,
			hornytimer              = 0,
			child                   = false,
			gotten                  = false,
			health                  = 0,
			reach                   = def.reach or 3,
			punch_reach             = def.punch_reach or def.reach or 3,
			htimer                  = 0,
			texture_list            = def.textures,
			child_texture           = def.child_texture,
			docile_by_day           = def.docile_by_day or false,
			time_of_day             = 0.5,
			fear_height             = def.fear_height or 0,
			runaway                 = def.runaway,
			runaway_timer           = 0,
			pathfinding             = def.pathfinding or 0,
			pathfinding_chance      = def.pathfinding_chance,
			place_node              = def.place_node,
			immune_to               = def.immune_to or {},
			explosion_radius        = def.explosion_radius,
			explosion_damage_radius = def.explosion_damage_radius,
			explosion_timer         = def.explosion_timer or 3,
			allow_fuse_reset        = def.allow_fuse_reset ~= false,
			stop_to_explode         = def.stop_to_explode ~= false,
			custom_attack           = def.custom_attack,
			double_melee_attack     = def.double_melee_attack,
			dogshoot_switch         = def.dogshoot_switch,
			dogshoot_count          = 0,
			dogshoot_count_max      = def.dogshoot_count_max or 5,
			dogshoot_count2_max     = def.dogshoot_count2_max or (def.dogshoot_count_max or 5),
			group_attack            = def.group_attack or false,
			attack_monsters         = def.attack_monsters or false,
			attack_animals          = def.attack_animals or false,
			attack_players          = def.attack_players ~= false,
			attack_npcs             = def.attack_npcs ~= false,
			specific_attack         = def.specific_attack,
			specific_allies         = def.specific_allies,
			runaway_from            = def.runaway_from,
			owner_loyal             = def.owner_loyal,
			facing_fence            = false,
			ignore_invisibility     = def.ignore_invisibility,
			pathing_radius          = def.pathing_radius,
			max_node_dig_level      = def.max_node_dig_level,
			--hunt_players            = def.hunt_players,
			hunt_chance             = def.hunt_chance or 0,
			-- The meaning of 'attack_chance' is inverted in order to make more sense [MustTest].
			attack_chance           = def.attack_chance or 95,
			show_health             = def.show_health,
			_cmi_is_mob             = true,

			punch_target            = def.punch_target,

			on_spawn = def.on_spawn,

			on_blast = def.on_blast or function(...) return mobs.do_tnt(...) end,

			on_step = function(...) return mobs.mob_step(...) end,

			do_punch = def.do_punch,

			on_punch = function(...) return mobs.mob_punch(...) end,

			on_breed = def.on_breed,

			on_grown = def.on_grown,

			on_activate = function(self, staticdata, dtime)
				return mobs.mob_activate(self, staticdata, def, dtime)
			end,

			get_staticdata = function(self)
				return mobs.mob_staticdata(self)
			end,
		})
	end -- END mobs:register_mob function
end



local function arrow_step(self, dtime, def)
	self.timer = self.timer + 1

	local pos = self.object:get_pos()
	if not pos then
		return
	end

	-- Remove expired arrows.
	if self.switch == 0
			or self.timer > 150
			or not within_limits(pos, 0) then

		self.object:remove()
		return
	end

	-- does arrow have a tail (fireball)
	if def.tail
	and def.tail == 1
	and def.tail_texture then

		minetest.add_particle({
			pos = pos,
			velocity = {x = 0, y = 0, z = 0},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = def.expire or 0.25,
			collisiondetection = false,
			texture = def.tail_texture,
			size = def.tail_size or 5,
			glow = def.glow or 0,
		})
	end

	if self.hit_node then
		-- Always round node position before passing it to code that probably
		-- assumes that position is an integer (failure to do this can result in
		-- coordinate problems in the engine)!
		local rpos = v_round(pos)
		local node = node_ok(rpos).name

		local ndef = minetest.reg_ns_nodes[node]
		if not ndef or ndef.walkable then

			self.hit_node(self, rpos, node)

			if self.drop == true then

				pos.y = pos.y + 1

				self.lastpos = (self.lastpos or pos)

				minetest.add_item(self.lastpos, self.object:get_luaentity().name)
			end

			self.object:remove() ; -- print ("hit node")

			return
		end
	end

	if self.hit_player or self.hit_mob then
		-- Find target that we hit.
		for _, target in pairs(minetest.get_objects_inside_radius(pos, 1.5)) do
			if self.hit_player and target:is_player() then
				self.hit_player(self, target)
				self.object:remove()
				return
			end

			local entity = target:get_luaentity()

			if entity and self.hit_mob and entity._cmi_is_mob == true
					and target ~= self.owner_obj
					and entity.name ~= self.name then

				-- Check that target actually exists.
				if target:get_pos() then
					self.hit_mob(self, target)
					self.object:remove()
					return
				end
			end
		end
	end

	self.lastpos = pos
end



-- export!
function mobs.arrow_step(self, dtime, def)
	return arrow_step(self, dtime, def)
end



-- register mob arrow entity function
if not mobs.registered then
	-- register arrow for shoot attack
	function mobs.register_arrow(name, def)
		if not name or not def then return end -- errorcheck

		minetest.register_entity(name, {
			physical = false,
			visual = def.visual,
			visual_size = def.visual_size,
			textures = def.textures,
			velocity = def.velocity,
			hit_player = def.hit_player,
			hit_node = def.hit_node,
			hit_mob = def.hit_mob,
			drop = def.drop or false, -- drops arrow as registered item when true
			collisionbox = {0, 0, 0, 0, 0, 0}, -- remove box around arrows
			timer = 0,
			switch = 0,
			rotate = def.rotate,

			automatic_face_movement_dir = def.rotate
				and (def.rotate - (pi / 180)) or false,

			on_activate = def.on_activate,

			on_step = def.on_step or function(self, dtime)
				return mobs.arrow_step(self, dtime, def)
			end,
		})
	end
end



-- Spawner item.
-- Note: This also introduces the “spawn_egg” group:
-- * spawn_egg=1: Spawn egg (generic mob, no metadata)
-- * spawn_egg=2: Spawn egg (captured/tamed mob, metadata)
if not mobs.registered then
	mobs.register_egg = function(mob, desc, background, addegg, no_creative)
		local invimg = background

		if addegg == 1 then
				invimg = "mobs_egg.png^(" .. background .. "^[mask:mobs_egg_overlay.png)"
		elseif addegg == 0 then
				invimg = background
		end

		-- Register new spawn egg containing mob information
		minetest.register_craftitem(mob .. "_set", {
			description = desc .. " Spawn Egg (Tamed)",
			inventory_image = invimg,
			groups = {
				not_in_creative_inventory = 1,
				not_in_craft_guide = 1,
				spawn_egg = 2,
			},
			stack_max = 1,

			on_place = function(itemstack, placer, pointed_thing)

				local pos = pointed_thing.above

				-- Am I clicking on something with existing on_rightclick function?
				local under = minetest.get_node(pointed_thing.under)
				local def = minetest.registered_nodes[under.name]
				if def and def.on_rightclick then
					return def.on_rightclick(pointed_thing.under, under, placer, itemstack)
				end

				if pos and within_limits(pos, 0) then
					if not minetest.registered_entities[mob] then
						minetest.chat_send_player(name, "# Server: Creature type not defined!")
						return
					end

					pos.y = pos.y + 1

					local data = itemstack:get_metadata()
					local mob = minetest.add_entity(pos, mob, data)
					local ent = mob:get_luaentity()

					if not ent then mob:remove()
						minetest.chat_send_player(name, "# Server: Failed to revive creature!")
						return
					end

					-- Set owner if not a monster or NPC.
					if ent.type ~= "monster" and ent.type ~= "npc" then
						ent.owner = placer:get_player_name()
						ent.tamed = true
					end

					-- Since mob is unique we remove egg once spawned.
					itemstack:take_item()
				end

				return itemstack
			end,
		})

		-- Register old stackable mob egg.
		minetest.register_craftitem(mob, {
			description = desc .. " Spawn Egg",
			inventory_image = invimg,
			groups = {
				not_in_creative_inventory = 1,
				not_in_craft_guide = 1,
				spawn_egg = 1,
			},

			on_place = function(itemstack, placer, pointed_thing)
				local pos = pointed_thing.above
				local name = placer:get_player_name()

				if pos and within_limits(pos, 0) then
					if not minetest.registered_entities[mob] then
						minetest.chat_send_player(name, "# Server: Creature type not defined!")
						return
					end

					pos.y = pos.y + 1

					local mob = minetest.add_entity(pos, mob)
					local ent = mob:get_luaentity()

					if not ent then mob:remove()
						minetest.chat_send_player(name, "# Server: Failed to summon creature!")
						return
					end

					-- Don't set owner if monster or NPC or sneak pressed.
					if ent.type ~= "monster" and ent.type ~= "npc" then
						if not placer:get_player_control().sneak then
							ent.owner = placer:get_player_name()
							ent.tamed = true
						end
					end
				end

				itemstack:take_item()
				return itemstack
			end,
		})
	end
end



-- Capture critter (thanks to blert2112 for idea).
function mobs.capture_mob(self, clicker, chance_hand, chance_net, chance_lasso, force_take, replacewith)

	if self.child
	or not clicker:is_player()
	or not clicker:get_inventory() then
		return false
	end

	-- get name of clicked mob
	local mobname = self.name

	-- if not nil change what will be added to inventory
	if replacewith then
		mobname = replacewith
	end

	local name = clicker:get_player_name()
	local tool = clicker:get_wielded_item()

	-- are we using hand, net or lasso to pick up mob?
	if tool:get_name() ~= ""
	and tool:get_name() ~= "mobs:net"
	and tool:get_name() ~= "mobs:lasso" then
		return false
	end

	-- Is mob tamed?
	if self.tamed == false and force_take == false then
		minetest.chat_send_player(name, "# Server: Animal not tamed!")
		return true -- false
	end

	-- Cannot pick up if not owner.
	if self.owner ~= name and force_take == false then
		minetest.chat_send_player(name, "# Server: Player <" .. rename.gpn(self.owner) .. "> is owner!")
		return true -- false
	end

	if clicker:get_inventory():room_for_item("main", mobname) then
		-- Was mob clicked with hand, net, or lasso?
		local chance = 0
		local tool = clicker:get_wielded_item()

		if tool:get_name() == "" then
			chance = chance_hand

		elseif tool:get_name() == "mobs:net" then

			chance = chance_net

			tool:add_wear(4000) -- 17 uses

			clicker:set_wielded_item(tool)

		elseif tool:get_name() == "mobs:lasso" then

			chance = chance_lasso

			tool:add_wear(650) -- 100 uses

			clicker:set_wielded_item(tool)

		end

		-- calculate chance.. add to inventory if successful?
		if chance > 0 and random(1, 100) <= chance then

			-- default mob egg
			local new_stack = ItemStack(mobname)

			-- add special mob egg with all mob information
			-- unless 'replacewith' contains new item to use
			if not replacewith then

				new_stack = ItemStack(mobname .. "_set")

				local tmp = {}

				for _,stat in pairs(self) do
					local t = type(stat)
					if  t ~= "function"
					and t ~= "nil"
					and t ~= "userdata" then
						tmp[_] = self[_]
					end
				end

				local data_str = minetest.serialize(tmp)

				new_stack:set_metadata(data_str)
			end

			local inv = clicker:get_inventory()

			if inv:room_for_item("main", new_stack) then
				inv:add_item("main", new_stack)
			else
				minetest.add_item(clicker:get_pos(), new_stack)
			end

			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			mob_sound(self, "default_place_node_hard")

		elseif chance ~= 0 then
			minetest.chat_send_player(name, "# Server: Missed!")
			mob_sound(self, "mobs_swing")
		end
	end
end



-- Make tables persistent even when file reloaded.
if not mobs.registered then
	mobs.nametagdata = {}
	mobs.nametagdata.mob_obj = {}
	mobs.nametagdata.mob_sta = {}
end

local mob_obj = mobs.nametagdata.mob_obj
local mob_sta = mobs.nametagdata.mob_sta

-- Feeding, taming and breeding (thanks blert2112).
function mobs.feed_tame(self, clicker, feed_count, breed, tame)
	if not self.follow then
		return false
	end

	-- can eat/tame with item in hand
	if follow_holding(self, clicker) then

		-- if not in creative then take item
		if not creative then

			local item = clicker:get_wielded_item()

			item:take_item()

			clicker:set_wielded_item(item)
		end

		-- increase health
		self.health = self.health + 4

		if self.health >= self.hp_max then
			self.health = self.hp_max
			if self.htimer < 1 then
				minetest.chat_send_player(clicker:get_player_name(), "# Server: Mob has full health!")
				self.htimer = 5
			end
		end

		self.object:set_hp(self.health)

		update_tag(self)

		-- make children grow quicker
		if self.child == true then

			self.hornytimer = self.hornytimer + 20

			return true
		end

		-- feed and tame
		self.food = (self.food or 0) + 1
		if self.food >= feed_count then

			self.food = 0

			if breed and self.hornytimer == 0 then
				self.horny = true
			end

			self.gotten = false

			if tame then

				if self.tamed == false then
					minetest.chat_send_player(clicker:get_player_name(), "# Server: Mob has been tamed!")
				end

				self.tamed = true

				if not self.owner or self.owner == "" then
					self.owner = clicker:get_player_name()
				end
			end

			-- make sound when fed so many times
			mob_sound(self, self.sounds.random)
		end

		return true
	end

	local item = clicker:get_wielded_item()

	-- if mob has been tamed you can name it with a nametag
	if item:get_name() == "mobs:nametag"
	and clicker:get_player_name() == self.owner then

		local name = clicker:get_player_name()

		-- store mob and nametag stack in external variables
		mob_obj[name] = self
		mob_sta[name] = item

		local tag = self.nametag or ""

		minetest.show_formspec(name, "mobs_nametag", "size[8,4]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. "field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]"
			.. "button_exit[2.5,3.5;3,1;mob_rename;" .. minetest.formspec_escape("Rename") .. "]")
	end

	return false
end

function mobs.nametag_receive_fields(player, formname, fields)
	-- right-clicked with nametag and name entered?
	if formname == "mobs_nametag"
	and fields.name
	and fields.name ~= "" then

		local name = player:get_player_name()

		if not mob_obj[name]
		or not mob_obj[name].object then
			return
		end

		-- make sure nametag is being used to name mob
		local item = player:get_wielded_item()

		if item:get_name() ~= "mobs:nametag" then
			return
		end

		-- limit name entered to 64 characters long
		if string.len(fields.name) > 64 then
			fields.name = string.sub(fields.name, 1, 64)
		end

		-- update nametag
		mob_obj[name].nametag = fields.name

		update_tag(mob_obj[name])

		-- if not in creative then take item
		if not mobs.is_creative(name) then

			mob_sta[name]:take_item()

			player:set_wielded_item(mob_sta[name])
		end

		-- reset external variables
		mob_obj[name] = nil
		mob_sta[name] = nil
	end
end

-- inspired by blockmen's nametag mod
if not mobs.registered then
	minetest.register_on_player_receive_fields(function(...)
		return mobs.nametag_receive_fields(...)
	end)
end


-- compatibility function for old entities to new modpack entities
if not mobs.registered then
	function mobs.alias_mob(old_name, new_name)

		-- spawn egg
		minetest.register_alias(old_name, new_name)

		-- entity
		minetest.register_entity(":" .. old_name, {

			physical = false,

			on_activate = function(self)

				if minetest.registered_entities[new_name] then
					minetest.add_entity(self.object:get_pos(), new_name)
				end

				-- Remove mob immediately, as last step of this function.
				-- Controls returns to engine.
				self.object:remove()
				self.mkrm = true
			end
		})
	end
end



-- Register as a reloadable file.
if not mobs.registered then
	local c = "mobs:api"
	local f = mobs.modpath .. "/api.lua"
	reload.register_file(c, f, false)

	mobs.registered = true
end
