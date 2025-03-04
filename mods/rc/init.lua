
-- Realm Control Mod.
-- This mod manages realm boundaries and prevents players from moving freely
-- between realms/dimensions without programmatic intervention.

-- Author: MustTest/BluebirdGreycoat51/GoldFireUn
-- License: MIT

if not minetest.global_exists("rc") then rc = {} end
rc.players = rc.players or {}
rc.modpath = minetest.get_modpath("rc")

dofile(rc.modpath .. "/gravity.lua")

-- Localize for performance.
local vector_round = vector.round
local math_random = math.random

local default_sky = {type="regular", clouds=true, body_orbit_tilt=0.0}
local default_sun = {visible=true, sunrise_visible=true, scale=1}
local default_moon = {visible=true, scale=1}
local default_stars = {visible=true, count=1000, day_opacity=0.0}
local default_clouds = {
	height = 120,
	density = 0.4,
	speed = {x = 0, z = -2},
	thickness = 16,
}

local SERVER_STATIC_SPAWN = {x=-9223, y=4169+400, z=5861}

-- Known realms. Min/max area positions should not overlap!
-- WARNING: ABSOLUTE MINIMUM GAP BETWEEN REALMS MUST BE 500 BLOCKS!
rc.realms = {
	{
		id = 1, -- REALM ID. Code relies on this.
		name = "overworld", -- Default/overworld realm.
		description = "Overworld",
		minp = {x=-30912, y=-30912, z=-30912},
		maxp = {x=30927, y=500, z=30927},
		gate_minp = {x=-30000, y=-30800, z=-30000},
		gate_maxp = {x=30000, y=-10, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = -10,
		underground = -32, -- Affects sky color, see sky mod.
		sealevel = 0,
		spawnlevel = 0,
		windlevel = 20,
		realm_origin = {x=-1067, y=-10, z=8930},
		disabled = false, -- Whether realm can be "gated" to. Use when testing!

		cloud_data = {
			-- Overworld clouds change direction of travel on every restart.
			speed = {x = math_random(-200, 200)/200, z = math_random(-200, 200)/200},
		},
		sky_data = {body_orbit_tilt = snow.body_orbit_tilt()},
    star_data = {day_opacity = snow.star_opacity()},

    bed_assault_mob = function(pos)
			if pos.y < -25000 then
				return "oerkki:oerkki"
			elseif pos.y < -30 then
				if math.random(1, 10) == 1 then
					return "dm:dm"
				else
					return "stoneman:stoneman"
				end
			end
			return "iceman:iceman"
		end,
	},
	-- Distance to channelwood: 2500
	{
		id = 2, -- REALM ID. Code relies on this.
		name = "channelwood", -- Forest realm. 250 meters high.
		description = "Channelwood",
		minp = {x=-30912, y=3050, z=-30912},
		maxp = {x=30927, y=3150, z=30927},
		gate_minp = {x=-30000, y=3065, z=-30000},
		gate_maxp = {x=30000, y=3067, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 3066,
		underground = 3050,
		sealevel = 3066,
		spawnlevel = 3066,
		windlevel = 3100,
		realm_origin = {x=2019, y=3066, z=-1992},
		disabled = false, -- Whether realm can be "gated" to.
		cloud_data={height=3112, density=0.6, speed={x=0.1, z=0.1}, thickness=4},
		moon_data={scale=2.5},
		sky_data = {body_orbit_tilt = -10.0},
    bed_assault_mob = "dirtleaf:dirtleaf",
	},
	-- Distance to jarkati: 450
	-- This breaks our minimum distance rule. Not much I can do about it now.
	{
		id = 3, -- REALM ID. Code relies on this.
		name = "jarkati",
		description = "Jarkati",
		minp = {x=-30912, y=3600, z=-30912},
		maxp = {x=30927, y=3800, z=30927},
		gate_minp = {x=-30000, y=3620, z=-30000},
		gate_maxp = {x=30000, y=3640, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 3740,
		underground = 3730,
		sealevel = 3740,
		spawnlevel = 3740,
		windlevel = 3750,
		realm_origin = {x=1986, y=3700, z=-1864},
		sky_data={clouds=true},
		cloud_data={height=3900, density=0.2, speed={x=5, z=2}},
		moon_data={scale=0.4},
		sun_data={scale=0.4},
    bed_assault_mob = "sandman:sandman",
	},
	-- Distance to utilities (pocket realms): 600
	{
		-- The OUTBACK. Starting realm for new players.
		id = 4, -- REALM ID. Code relies on this.
		name = "abyss",
		description = "Outback",
		minp = vector.add({x=-9174, y=4100+400, z=5782}, {x=-100, y=-100, z=-100}),
		maxp = vector.add({x=-9174, y=4100+400, z=5782}, {x=100, y=100, z=100}),
		gate_minp = vector.add({x=-9174, y=4100+400, z=5782}, {x=-80, y=-80, z=-80}),
		gate_maxp = vector.add({x=-9174, y=4100+400, z=5782}, {x=80, y=80, z=80}),
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 4170+400,
		underground = 4160+400, -- Affects sky color, see sky mod.
		sealevel = 4160+400,
		spawnlevel = 4560,
		windlevel = 4150+400,
		realm_origin = {x=-9174, y=4100+400, z=5782},
		disabled = true, -- Realm cannot receive an incoming gate. OFFICIAL.
    sky_data = {clouds=false},
    sun_data = {visible=true},
    moon_data = {visible=true},
    star_data = {visible=true, count=50},
    realm_resets = true,

    border_edge_distance = 7,
    border_edge = function(...)
			return welcome.player_near_outback_edge(...)
		end,

    --[[

			-- Notes:
			--
			-- If you got into the Outback by dying in Midfeld (and your bed wasn't
			-- in Midfeld), then using the Outback portal shall always send you back
			-- to Midfeld, even if you subseqently died in the Outback as well.
			--
			-- Otherwise, using the Outback portal sends you to the Overworld.

    --]]
	},
	{
		-- The MIDFELD. In-between place; travel realm.
		id = 5, -- REALM ID. Code relies on this.
		name = "midfeld",
		description = "Midfeld",
		minp = vector.add({x=-12174, y=4100+400, z=5782}, {x=-132, y=-50, z=-132}),
		maxp = vector.add({x=-12174, y=4100+400, z=5782}, {x=132, y=150, z=132}),
		gate_minp = vector.add({x=-12174, y=4100+400, z=5782}, {x=-116, y=-34, z=-116}),
		gate_maxp = vector.add({x=-12174, y=4100+400, z=5782}, {x=116, y=-10, z=116}),
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 4096+400,
		underground = 4085+400, -- Affects sky color, see sky mod.
		sealevel = 4095+400,
		spawnlevel = 4480,
		windlevel = 4125+400,
		realm_origin = {x=-12174, y=4097+400, z=5782},
		disabled = true, -- Realm cannot receive an incoming gate. OFFICIAL.
		moon_data = {scale=2.5},
		sun_data = {scale=2.5},
		cloud_data = {height=4250+400, density=0.2, speed={x=-6, z=1}},
		protection_temporary = true,
		protection_time = 60*60*24*14,
    realm_resets = true,

		--[[

			//fixedpos set1 -11967 4450 5989
			//fixedpos set2 -12381 4650 5575

			-- Schempos: -12381,4450,5575

			-- Notes:
			--
			-- If you die in Midfeld for any reason,
			--  a) if you have a bed IN Midfeld, you respawn in your bed,
			--  b) otherwise (even if you have a bed elsewhere), you respawn in the Outback.
			--
			-- Dying in Midfeld is the canonical way to get into the Outback without
			-- needing to lose your bed respawn position (the dumb way, is to lose your
			-- bed's respawn position by dying multiple times).

		--]]
	},
	-- Distance to stoneworld: 500
	{
		-- Stoneworld. Tartarus. Place of evildoers. 3000 blocks high, all stone.
		id = 6, -- REALM ID. Code relies on this.
		name = "naraxen", -- described in the 'stoneworld' folder.
		description = "Naraxen",
		minp = {x=-30912, y=5150, z=-30912},
		maxp = {x=30927, y=8150, z=30927},
		gate_minp = {x=-30000, y=5350, z=-30000},
		gate_maxp = {x=30000, y=7950, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 8150,
		underground = 8150, -- Affects sky color, see sky mod.
		sealevel = 8150,
		spawnlevel = function(pos3d) return stoneworld.get_ground_y(pos3d) end,
		windlevel = 8150,
		realm_origin = {x=2382, y=6650, z=-3721},
		moon_data = {visible=false},
		sun_data = {visible=false},
		sky_data = {clouds=false},
		star_data = {visible=false},
    bed_assault_mob = {
			"griefer:griefer",
			"nssm:morde",
		},
	},

	-- Work in progress realms.
	{
		id = 7, -- REALM ID. Code relies on this.
		name = "waterworld",
		description = "Great Deep",
		minp = {x=-30912, y=8650, z=-30912},
		maxp = {x=30927, y=9650, z=30927},
		gate_minp = {x=-30000, y=8650+50, z=-30000},
		gate_maxp = {x=30000, y=8650+500, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 8650+500,
		underground = 8650+450, -- Affects sky color, see sky mod.
		sealevel = 8650+500,
		spawnlevel = 8650+500,
		windlevel = 8650+500,
		realm_origin = {x=-482, y=8650+500, z=5582},
		disabled = true, -- Not ready yet.
	},

	{
		id = 8, -- REALM ID. Code relies on this.
		name = "stoneworld", -- 'sw' folder.
		description = "Carcorsica",

		alt_description = function(pos)
			if pos.y >= 13150 then
				return "Ir-Xen"
			end
			return "Carcorsica"
		end,

		minp = {x=-30912, y=10150, z=-30912},
		maxp = {x=30927, y=15150, z=30927},
		gate_minp = {x=-30000, y=10150+50, z=-30000},
		gate_maxp = {x=30000, y=10150+200, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = function(pos3d) return sw.get_ground_y(pos3d) end,
		underground = function(pos3d) return sw.get_ground_y(pos3d) - 50 end,
		sealevel = 10150+200,
		spawnlevel = function(pos3d) return sw.get_ground_y(pos3d) end,
		windlevel = function(pos3d) return sw.get_ground_y(pos3d) + 30 end,
		realm_origin = {x=-7729, y=10150+200, z=-5821},
		disabled = false,
		bed_assault_mob = "stoneman:stoneman",

		-- Clouds don't play nice atm.
		sky_data = {clouds = false},
		cloud_data = {density = 0},

		-- Low gravity in Xen.
		get_physics_override = function(pos)
			if pos.y >= 13150 then
				return {gravity=0.75, liquid_sink=2}
			end
		end,
	},

	{
		id = 9, -- REALM ID. Code relies on this.
		name = "paradaxun",
		description = "Paradaxun",
		minp = {x=-30912, y=15650, z=-30912},
		maxp = {x=30927, y=20650, z=30927},
		gate_minp = {x=-30000, y=15650+50, z=-30000},
		gate_maxp = {x=30000, y=15650+4000, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 15650+4000,
		underground = 15650+4000, -- Affects sky color, see sky mod.
		sealevel = 15650+4000,
		spawnlevel = 15650+4000,
		windlevel = 15650+4000,
		realm_origin = {x=6565, y=15650+4000, z=4404},
		disabled = true, -- Not ready yet.
	},

	{
		id = 10, -- REALM ID. Code relies on this.
		name = "ariba",
		description = "Saravinca",
		minp = {x=-30912, y=21150, z=-30912},
		maxp = {x=30927, y=23450, z=30927},
		gate_minp = {x=-30000, y=21150+50, z=-30000},
		gate_maxp = {x=30000, y=21150+2000, z=30000},
		orig = SERVER_STATIC_SPAWN, -- Same as server's static spawnpoint!
		ground = 21150+2000,
		underground = 21150+1850, -- Affects sky color, see sky mod.
		sealevel = 21150+2000,
		spawnlevel = 21150+1900,
		windlevel = 21150+2000,
		realm_origin = {x=6565, y=21150+2000, z=4404},
		disabled = false,
		cloud_data = {height=23300, density=0.3, speed={x=-20, z=5}},
		star_data = {count=200},
	},
}

-- Return true if a position is underground in some realm.
-- False is returned if not underground.
-- Returns nil if position isn't in any valid realm.
function rc.position_underground(pos)
	local p = vector_round(pos)

	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			local ugl = v.underground
			if type(ugl) == "function" then
				ugl = ugl(pos)
			end
			if p.y < ugl then
				return true
			else
				return false
			end
		end
	end

	-- Not in any realm?
	return nil
end

-- Used by ice/ice-brick/snow nodes to determine if they should melt away.
-- This is also used by the tree-snowdust code to determine whether a tree
-- should spawn with snow on top.
function rc.ice_melts_at_pos(pos)
	if pos.y < -26000 or pos.y > 1000 then
		return true
	end
end

-- Convert realm position to absolute coordinate. May return NIL if not valid!
function rc.realmpos_to_pos(realm, pos)
	local data = rc.get_realm_data(realm:lower())
	if data then
		local origin = data.realm_origin
		return {
			x = origin.x + pos.x,
			y = origin.y + pos.y,
			z = origin.z + pos.z,
		}
	end

	-- Indicate failure.
	return nil
end

-- Convert absolute coordinate to realm position. May return NIL if not valid!
function rc.pos_to_realmpos(pos)
	local origin = rc.get_realm_origin_at_pos(pos)
	if origin then
		return {
			x = pos.x - origin.x,
			y = pos.y - origin.y,
			z = pos.z - origin.z,
		}
	end

	-- Indicate failure.
	return nil
end

function rc.pos_to_namestr(pos)
	local name = rc.pos_to_name(pos)
	local str = rc.pos_to_string(pos)

	str = string.gsub(str, "[%(%)]", "")

	return "(" .. name .. ": " .. str .. ")"
end

function rc.pos_to_name(pos)
	return rc.realm_description_at_pos(pos)
end

function rc.get_realm_origin_at_pos(p)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			local o = table.copy(v.realm_origin)
			return o
		end
	end

	-- Not in any realm?
	return nil
end

-- Obtain a string in the format "(x,y,z)".
function rc.pos_to_string(pos)
	local realpos = rc.pos_to_realmpos(pos)
	if realpos then
		return minetest.pos_to_string(realpos)
	end

	-- Indicate failure.
	return "(Nan,Nan,Nan)"
end

function rc.get_realm_sky(pos)
	local n = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if n then
		local t = table.copy(default_sky)
		for k, v in pairs(n.sky_data or {}) do
			t[k] = v
		end
		--minetest.chat_send_all(dump(t))
		return t
	end
	return {}
end

function rc.get_realm_sun(pos)
	local n = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if n then
		local t = table.copy(default_sun)
		for k, v in pairs(n.sun_data or {}) do
			t[k] = v
		end
		--minetest.chat_send_all(dump(t))
		return t
	end
	return {}
end

function rc.get_realm_moon(pos)
	local n = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if n then
		local t = table.copy(default_moon)
		for k, v in pairs(n.moon_data or {}) do
			t[k] = v
		end
		--minetest.chat_send_all(dump(t))
		return t
	end
	return {}
end

function rc.get_realm_stars(pos)
	local n = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if n then
		local t = table.copy(default_stars)
		for k, v in pairs(n.star_data or {}) do
			t[k] = v
		end
		--minetest.chat_send_all(dump(t))
		return t
	end
	return {}
end

function rc.get_realm_clouds(pos)
	local n = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if n then
		local t = table.copy(default_clouds)
		for k, v in pairs(n.cloud_data or {}) do
			t[k] = v
		end
		--minetest.chat_send_all(dump(t))
		return t
	end
	return {}
end

function rc.get_realm_data(name)
	for k, v in ipairs(rc.realms) do
		if v.name == name then
			return v
		end
		if v.name == "overworld" then
			-- Alternate names.
			if name == "netherworld" or name == "nether" or name == "caverns" or name == "caves" then
				return v
			end
		end
		if v.name == "abyss" then
			-- Alternate names.
			if name == "outback" then
				return v
			end
		end
	end
	return nil
end

function rc.get_random_enabled_realm_data()
	if (#rc.realms) < 1 then
		return
	end

	local tries = 1
	local realm = rc.realms[math_random(1, #rc.realms)]
	while realm.disabled and tries < 10 do
		tries = tries + 1
		realm = rc.realms[math_random(1, #rc.realms)]
	end

	if realm.disabled then
		return
	end

	return realm
end

function rc.get_random_realm_gate_position(pname, origin)
	if rc.is_valid_realm_pos(origin) then
		if origin.y >= 128 and origin.y <= 1000 then
			-- If gateway is positioned in the Overworld mountains,
			-- permit easy realm hopping.
			local realm = rc.get_random_enabled_realm_data()
			if not realm then
				return nil
			end
			assert(realm)

			local pos = {
				x = math_random(realm.gate_minp.x, realm.gate_maxp.x),
				y = math_random(realm.gate_minp.y, realm.gate_maxp.y),
				z = math_random(realm.gate_minp.z, realm.gate_maxp.z),
			}

			local below = vector.add(origin, {x=0, y=-16, z=0})
			local minp = vector.add(below, {x=-16, y=-16, z=-16})
			local maxp = vector.add(below, {x=16, y=16, z=16})

			-- Should find 30K stone.
			local positions, counts = minetest.find_nodes_in_area(minp, maxp, {"default:stone"})

			--for k, v in pairs(counts) do
			--	minetest.chat_send_player(pname, "# Server: " .. k .. " = " .. v .. "!")
			--end

			if counts["default:stone"] > math_random(10000, 30000) then
				-- Search again, even deeper. The stone amount should be MUCH higher.
				below = vector.add(below, {x=0, y=-32, z=0})
				minp = vector.add(below, {x=-16, y=-16, z=-16})
				maxp = vector.add(below, {x=16, y=16, z=16})
				positions, counts = minetest.find_nodes_in_area(minp, maxp, {"default:stone"})

				--for k, v in pairs(counts) do
				--	minetest.chat_send_player(pname, "# Server: " .. k .. " = " .. v .. "!")
				--end

				if counts["default:stone"] > math_random(20000, 32000) then
					return pos
				end
			end
			return nil
		elseif origin.y > 1000 then
			-- The gateway is positioned in a realm somewhere.
			-- 9/10 times the exit point stays in the same realm.
			-- Sometimes a realm hop is possible.
			local realm
			if math_random(1, 10) == 1 then
				realm = rc.get_random_enabled_realm_data()
			else
				realm = rc.get_realm_data(rc.current_realm_at_pos(origin))
			end
			if not realm then
				return nil
			end
			assert(realm)

			-- Not more than 3000 meters away from origin!
			local pos = {
				x = math_random(-3000, 3000) + origin.x,
				y = math_random(-300, 300) + origin.y,
				z = math_random(-3000, 3000) + origin.z,
			}

			local min = math.min
			local max = math.max

			-- Clamp position to ensure we remain within realm boundaries.
			pos.x = max(realm.gate_minp.x, min(pos.x, realm.gate_maxp.x))
			pos.y = max(realm.gate_minp.y, min(pos.y, realm.gate_maxp.y))
			pos.z = max(realm.gate_minp.z, min(pos.z, realm.gate_maxp.z))

			return pos
		end
	end

	local realm = rc.get_realm_data("overworld")
	assert(realm)

	-- Player is in the Overworld or Nether. Use old Gateway behavior!
	-- Not more than 3000 meters in any direction, and MUST stay in the Overworld
	-- (or the Nether). Gate is more likely to go down rather than up.
	local pos = {
		x = math_random(-3000, 3000) + origin.x,
		y = math_random(-2000, 1500) + origin.y,
		z = math_random(-3000, 3000) + origin.z,
	}

	local min = math.min
	local max = math.max

	-- Clamp position.
	pos.x = max(realm.gate_minp.x, min(pos.x, realm.gate_maxp.x))
	pos.y = max(realm.gate_minp.y, min(pos.y, realm.gate_maxp.y))
	pos.z = max(realm.gate_minp.z, min(pos.z, realm.gate_maxp.z))

	return pos
end

function rc.is_valid_gateway_region(pos)
	local p = vector_round(pos)
	for k, v in ipairs(rc.realms) do
		local gate_minp = v.gate_minp
		local gate_maxp = v.gate_maxp

		-- Is position within realm boundaries suitable for a gateway?
		if p.x >= gate_minp.x and p.x <= gate_maxp.x and
				p.y >= gate_minp.y and p.y <= gate_maxp.y and
				p.z >= gate_minp.z and p.z <= gate_maxp.z then
			return true
		end
	end

	-- Not in any realm?
	return false
end

function rc.is_valid_realm_pos(pos)
	local p = vector_round(pos)
	for i = 1, #rc.realms, 1 do
		local v = rc.realms[i]

		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return true
		end
	end

	-- Not in any realm?
	return false
end

function rc.get_ground_level_at_pos(pos)
	local p = vector_round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			local gl = v.ground
			if type(gl) == "function" then
				gl = gl(pos)
			end
			return true, gl
		end
	end

	-- Not in any realm?
	return false, nil
end

function rc.get_sea_level_at_pos(pos)
	local p = vector_round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return true, v.sealevel
		end
	end

	-- Not in any realm?
	return false, nil
end

function rc.get_wind_level_at_pos(pos)
	local p = vector_round(pos)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is position within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			local wl = v.windlevel
			if type(wl) == "function" then
				wl = wl(pos)
			end
			return true, wl
		end
	end

	-- Not in any realm?
	return false, nil
end

-- API function. Get string name of the current realm the player is in.
function rc.current_realm(player)
	local p = vector_round(player:get_pos())
	return rc.current_realm_at_pos(p)
end

-- API function. Get string name of the current realm at a position.
function rc.current_realm_at_pos(p)
	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is pos within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			return v.name
		end
	end

	-- Not in any realm?
	return ""
end

-- API function. Get static spawn point of a named realm.
function rc.static_spawn(name)
	for k, v in ipairs(rc.realms) do
		if v.name == name then
			return table.copy(v.orig)
		end
	end

	-- Not in any realm?
	return {x=0, y=-7, z=0}
end

function rc.same_realm(p1, p2)
	return (rc.current_realm_at_pos(p1) == rc.current_realm_at_pos(p2))
end

function rc.realm_description_at_pos(p)
	-- Special realm name.
	if p.y < -25000 then
		if p.y < -30760 and p.y > -30800 then
			return "Abyssal Sea"
		end
		return "Nether"
	elseif p.y < -5000 then
		return "Caverns"
	end

	for k, v in ipairs(rc.realms) do
		local minp = v.minp
		local maxp = v.maxp

		-- Is player within realm boundaries?
		if p.x >= minp.x and p.x <= maxp.x and
				p.y >= minp.y and p.y <= maxp.y and
				p.z >= minp.z and p.z <= maxp.z then
			if v.alt_description then
				return v.alt_description(p)
			else
				return v.description
			end
		end
	end

	-- Not in any realm?
	return "Void"
end

-- API function.
-- Check player position and current realm. If not valid, reset player to last
-- valid location. If last valid location not found, reset them to 0,0,0.
-- This function should be called from a global-step callback somewhere.
function rc.check_position(player)
	local p = vector_round(player:get_pos())
	local n = player:get_player_name()
	local data = rc.players[n]

	-- Data not initialized yet.
	if not data then return end

	-- Admin may fly around in the void.
	-- WARNING: use only when needed!
	-- Careless flying+mapgen WILL cause lighting issues!
	--if gdac.player_is_admin(player) then return end

	local reset -- Table set if player out-of-bounds.

	-- Bounds check to avoid an engine bug. These coordinates should be the last
	-- row of nodes at the map edge. This way, we never teleport the player to a
	-- location that is strictly outside the world boundaries, if they trigger it.
	if p.x < -30912 or p.x > 30927 or
			p.y < -30912 or p.y > 30927 or
			p.z < -30912 or p.z > 30927 then
		-- Some old clients, it seems, can randomly cause this problem.
		-- Or someone is deliberately triggering it.
		reset = {}
		reset.spawn = rc.static_spawn("abyss")
	end

	-- Check if player is currently in the void.
	if not reset then
		if data.realm == "" then
			reset = {}
			reset.spawn = rc.static_spawn("abyss")
		end
	end

	-- Do bounds checks for individual realms.
	if not reset then
		local lrem = #(rc.realms)
		for k = 1, lrem, 1 do
			local v = rc.realms[k]

			-- Is player within boundaries of the realm they are supposed to be in?
			if data.realm == v.name then
				local minp = v.minp
				local maxp = v.maxp

				if p.x < minp.x or p.x > maxp.x or
						p.y < minp.y or p.y > maxp.y or
						p.z < minp.z or p.z > maxp.z then
					reset = {}
					reset.spawn = v.orig -- Use current realm's respawn coordinates.
					break
				end

				-- Check if player is NEAR the edge of the realm, and call a special
				-- function if they are. This function gets called every time, and it
				-- must handle being called multiple times as long as the player is
				-- near the realm boundary.
				if v.border_edge then
					local d = v.border_edge_distance or 10
					local minp2 = {x=minp.x + d, y=minp.y, z=minp.z + d}
					local maxp2 = {x=maxp.x - d, y=maxp.y, z=maxp.z - d}

					if p.x < minp2.x or p.x > maxp2.x or
							p.y < minp2.y or p.y > maxp2.y or
							p.z < minp2.z or p.z > maxp2.z then
						v.border_edge(player, p)
					end
				end
			end
		end
	end

	if reset then
		-- Player is out-of-bounds. Reset to last known good position.
		if not gdac.player_is_admin(n) and not data.new_arrival then
			if not spam.test_key(58921) then
				spam.mark_key(58921, 30)

				minetest.chat_send_all("# Server: <" .. rename.gpn(n) ..
					"> strayed from the path ....")
			end
		end

		-- Notify wield3d we're adjusting the player position.
		-- Wielded item entities don't like sudden movement.
		wield3d.on_teleport()
		default.detach_player_if_attached(player)

		if player:get_hp() > 0 then
			-- Return player to last known good position.
			local nrealm = rc.current_realm_at_pos(data.pos)
			if nrealm ~= "" and nrealm == data.realm then
				player:set_pos(data.pos)
			else
				-- This can happen if player joins the server outside of any realm.
				rc.notify_realm_update(player, reset.spawn)
				player:set_pos(reset.spawn)
			end
		else
			-- Update which realm the player is supposed to be in.
			-- (We might have crossed realms depending on what happened above.)
			rc.notify_realm_update(player, reset.spawn)

			-- Return to realm's origin point.
			player:set_pos(reset.spawn)
		end

		-- Damage player. Prevents them triggering this indefinitely.
		if player:get_hp() > 0 and not data.new_arrival then
			-- Bypass armor code.
			player:set_hp(player:get_hp() - (2*500))

			-- Note: per bones code, if position is not within any valid realm, bones
			-- will not be spawned.

			if player:get_hp() <= 0 then
				if not gdac.player_is_admin(n) then
					minetest.chat_send_all("# Server: <" .. rename.gpn(n) ..
						"> took a flying leap off the Yggdrasill.")

					spam.block_playerjoin(n, 60*2)
					minetest.kick_player(n, "You found an end in the Void.")
				end
			end
		end

		return
	end

	-- If we got this far, the player is not out of bounds.
	-- Record last known good position. Realm name should be same as before.
	do
		local ps = data.pos
		ps.x = p.x
		ps.y = p.y
		ps.z = p.z
	end
end



function rc.on_joinplayer(player)
	local n = player:get_player_name()
	local p = player:get_pos()

	local crealm = rc.current_realm(player)

	-- Player's current dimension is determined from position on login.
	rc.players[n] = {
		pos = p,
		realm = crealm,
		new_arrival = true,
	}

	-- Remove the 'new_arrival' flag after a few seconds.
	minetest.after(10, function()
		local data = rc.players[n]
		if not data then return end
		data.new_arrival = nil
	end)

	rc.do_gravity_check(n)
end



function rc.on_leaveplayer(player, timeout)
	local n = player:get_player_name()
	rc.players[n] = nil
end



function rc.plane_shift_message(pref, p, n)
	local pp = vector_round(pref:get_pos())
	local rr = rc.current_realm_at_pos(pp)
	local rr2 = rc.current_realm_at_pos(p)

	-- Only if new realm is different from old.
	if rr ~= rr2 then
		if gdac_invis.is_invisible(n) or cloaking.is_cloaked(n) or player_labels.query_nametag_onoff(n) == false then
			if not gdac.player_is_admin(n) then
				minetest.chat_send_all("# Server: Someone has plane shifted.")
			end
		else
			local d = rc.get_realm_data(rr2)
			if d and d.description then
				local realm_name = d.description
				local insult = ""

				local pname = pref:get_player_name()
				if beds.get_respawn_count(pname) == 0 then
					if rr ~= "abyss" and rr2 == "abyss" then
						insult = " Noob!"
					end
				end

				minetest.chat_send_all("# Server: <" .. rename.gpn(n) .. "> has plane shifted to " .. realm_name .. "." .. insult)
			end
		end
	end
end



-- API function. Call this whenever a player teleports,
-- or lawfully changes realm. You can pass a player object or a name.
-- Note: this must be called *before* you call :set_pos() on the player!
-- Note #2: read the above note again! I really mean it!
function rc.notify_realm_update(player, pos)
	local p = vector_round(pos)
	local n = ""
	if type(player) == "string" then
		n = player
	else
		n = player:get_player_name()
	end
	local pref = minetest.get_player_by_name(n)

	local tb = rc.players[n]
	if not tb then
		minetest.log("action", "could not find data for player " .. n .. " when updating realm info")
		return
	end

	-- Print plane-shift message.
	if pref and tb.realm then
		rc.plane_shift_message(pref, p, n)
	end

	-- Set 'new_arrival' flag to avoid complaining about them straying from the path ....
	tb.new_arrival = true
	tb.pos = p
	tb.realm = rc.current_realm_at_pos(p)
	sky.notify_sky_update_needed(n)
	bone_mark.notify_hud_update_needed(n)

	-- Remove the 'new_arrival' flag after a few seconds.
	-- Note: this flag was set in order to suppress the 'strayed from path' message
	-- that gets printed if the player is caught outside the correct realm. This
	-- can happen because player position is controled by the client. Give the
	-- player's client a few seconds to get its feet in gear.
	minetest.after(5, function()
		local data = rc.players[n]
		if not data then return end
		data.new_arrival = nil
	end)
end



local LIQUID_FORBIDDEN_REGIONS = {
	-- Xen coordinates.
	{
		minp = {x=-30912, y=13150, z=-30912},
		maxp = {x=30927, y=15150, z=30927},
	},
}

function rc.liquid_forbidden_at(pos)
	for k, v in ipairs(LIQUID_FORBIDDEN_REGIONS) do
		local minp = v.minp
		local maxp = v.maxp

		if pos.x >= minp.x and pos.x <= maxp.x
		   and pos.y >= minp.y and pos.y <= maxp.y
		   and pos.z >= minp.z and pos.z <= maxp.z then
			-- Forbid liquid here.
			return true
		end
	end
	return false
end



if not rc.registered then
	minetest.register_on_joinplayer(function(...)
		return rc.on_joinplayer(...)
	end)

	minetest.register_on_leaveplayer(function(...)
		return rc.on_leaveplayer(...)
	end)

	local c = "rc:core"
	local f = rc.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	rc.registered = true
end
