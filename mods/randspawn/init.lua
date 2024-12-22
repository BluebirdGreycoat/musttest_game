
if not minetest.global_exists("randspawn") then randspawn = {} end
randspawn.modpath = minetest.get_modpath("randspawn")

-- Localize for performance.
local math_random = math.random

-- After the Outback gateway exit coordinates are changed, this is the min and
-- max number of days until it changes again.
randspawn.min_days = 10
randspawn.max_days = 90



function randspawn.check_spawn_reset()
	local meta = randspawn.modstorage
	local stime = meta:get_string("spawn_reset_timer")

	-- If timestamp is missing, then initialize it.
	-- Outback reset will be scheduled after the timeout.
	if not stime or stime == "" then
		local time = os.time()
		local days = 60*60*24*math_random(randspawn.min_days, randspawn.max_days)
		time = time + days
		stime = tostring(time)
		meta:set_string("spawn_reset_timer", stime)

		-- Find a new spawn point.
		local t = serveressentials.get_realm_names()
		for k, realm in ipairs(t) do
			randspawn.find_new_spawn(false, realm)
		end
		return
	end

	local now = os.time()
	local later = tonumber(stime) -- Time of future reset (or initialization).

	if now >= later then
		later = later + 60*60*24*math_random(randspawn.min_days, randspawn.max_days)
		stime = tostring(later)
		meta:set_string("spawn_reset_timer", stime)

		-- Find a new spawn point.
		local t = serveressentials.get_realm_names()
		for k, realm in ipairs(t) do
			randspawn.find_new_spawn(false, realm)
		end
	end
end
minetest.after(0, function() randspawn.check_spawn_reset() end)



-- Used by the calendar item.
function randspawn.get_spawn_reset_timeout()
	local meta = randspawn.modstorage
	local stime = meta:get_string("spawn_reset_timer")

	local later = tonumber(stime)
	local now = os.time()
	local diff = later - now

	if diff < 0 then diff = 0 end
	return diff
end



-- List of nodes Outback gates should never place players over.
local FORBIDDEN_SPAWN_SURFACE_NODES = {
	"default:water_source",
	"cw:water_source",
	"default:lava_source",
	"lbrim:lava_source",
}

local function forbidden_surface(nodename)
	for k, v in ipairs(FORBIDDEN_SPAWN_SURFACE_NODES) do
		if nodename == v then
			return true
		end
	end
	return false
end



local function callback(blockpos, action, calls_remaining, param)
	-- We don't do anything until the last callback.
	if calls_remaining ~= 0 then
		return
	end

	-- Check if there was an error on the LAST call.
	-- Note: this will usually fail if the area to emerge intersects the map edge.
	-- But usually we don't try to do that, here.
	if action == core.EMERGE_CANCELLED or action == core.EMERGE_ERRORED then
		return
	end

	local pos = param.pos
	local realm = param.realm
	local get_node = minetest.get_node

	local miny = pos.y - 15
	local maxy = pos.y + 195

	-- Start at bottom of emerged area and scan upward to find ground.
	for y = miny, maxy, 1 do
		local thispos = {x=pos.x, y=y, z=pos.z}
		local nu = get_node(thispos)
		local na = get_node(vector.add(thispos, {x=0, y=1, z=0}))
		local nb = get_node(vector.add(thispos, {x=0, y=2, z=0}))
		local nd = get_node(vector.add(thispos, {x=0, y=3, z=0}))

		-- Exit if map not loaded.
		if nu.name == "ignore" or na.name == "ignore" then
			--minetest.log("hit ignore at y=" .. y .. ", aborting")
			break
		end

		-- Require 3 nodes of air to ensure player doesn't spawn with head buried.
		-- We're not communists.
		if na.name == "air" and nb.name == "air" and nd.name == "air" and nu.name ~= "air" then
			if not forbidden_surface(nu.name) then
				thispos.y = thispos.y + 1

				-- We have a new spawnpoint.
				--minetest.log("found new spawn location!")
				serveressentials.update_exit_location(thispos, realm)
				return
			end
		end
	end

	-- We didn't find a suitable spawn location. Try again shortly.
	minetest.log("could not find spawn location, trying again.")
	local ls = param.local_shift
	minetest.after(10, function() randspawn.find_new_spawn(ls, realm) end)
end

function randspawn.find_new_spawn(local_shift, realm)
	local realmspawny = 0
	local realmspawn = rc.get_realm_data(realm).spawnlevel

	local randx = math_random(-6000, 6000)
	local randz = math_random(-6000, 6000)

	if type(realmspawn) == "number" then
		realmspawny = realmspawn
	elseif type(realmspawn) == "function" then
		realmspawny = realmspawn({x=randx, y=0, z=randz})
	end

	local pos = {x=randx, y=realmspawny, z=randz}

	-- If we're only performing a local shift, adjust the coordinates randomly
	-- around the current existing coordinates (if existing coords exist!).
	if local_shift then
		local rad = 75
		local soldpos = serveressentials.get_current_exit_location(realm)
		local oldpos = minetest.string_to_pos(soldpos)
		if oldpos then
			pos.x = math.random(oldpos.x - rad, oldpos.x + rad)
			pos.y = oldpos.y
			pos.z = math.random(oldpos.z - rad, oldpos.z + rad)
		end
	end

	local minp = vector.add(pos, {x=-7, y=-20, z=-7})
	local maxp = vector.add(pos, {x=7, y=200, z=7})

	minetest.emerge_area(minp, maxp, callback,
		{pos=table.copy(pos), local_shift=local_shift, realm=realm})
end



-- This function shall ALWAYS return the Outback's static_spawn!
local function get_respawn_position(invoke_pos, pname)
	-- Regardless of where player dies, if they have no bed,
	-- then they respawn in the outback. Note that a player may lose their bed if
	-- killed by another player outside of the city.
	return rc.static_spawn("abyss")
end
randspawn.get_respawn_pos = get_respawn_position



-- Note: this is also called from the /spawn chatcommand,
-- but only after validation passes (distance, etc.).
-- This API shall place player at the Outback's static_spawn, ALWAYS.
randspawn.reposition_player = function(pname, death_pos)
	local player = minetest.get_player_by_name(pname)
	if player then
		-- Ensure teleport is forced, to prevent a cheat.
		local pos = get_respawn_position(death_pos, pname)
		pos = vector.add(pos, {x=math_random(-1, 1), y=0, z=math_random(-1, 1)})

		preload_tp.execute({
			player_name = pname,
			target_position = pos,
			emerge_radius = 32,

			post_teleport_callback = function()
				ambiance.sound_play("respawn", pos, 0.5, 10)
			end,

			force_teleport = true,
			send_blocks = false,
			particle_effects = true,
		})
	end
end



-- The calendar item calls this to report the location of the current spawnpoint.
function randspawn.get_spawn_name(realm)
	local s = serveressentials.get_current_exit_location(realm)
	local p = minetest.string_to_pos(s)

	-- The outback spawn exit isn't fixed, so you can never really know exactly
	-- where someone will come out at ... the calendar thus can only give you the
	-- aproximate location.
	if p then
		local rd = rc.get_realm_data(rc.current_realm_at_pos(p))
		local ro = {
			x = rd.realm_origin.x % 100,
			y = rd.realm_origin.y % 10,
			z = rd.realm_origin.z % 100,
		}

		p.x = math.floor(p.x / 100) * 100 + ro.x
		p.y = math.floor(p.y / 10) * 10 + ro.y
		p.z = math.floor(p.z / 100) * 100 + ro.z

		return rc.pos_to_namestr(p)
	end

	return "Unknown Location"
end

function randspawn.on_outback_gate_use(params)
	if rc.current_realm_at_pos(params.gate_origin) == "abyss" then
		-- Shift the Outback exit 30 minutes after every use.
		minetest.after(60*30, function()
			local realmname = rc.current_realm_at_pos(params.teleport_destination)
			randspawn.find_new_spawn(true, realmname)
		end)

		-- Make sure there's a return gate entity, in lieu of an actual gate.
		obsidian_gateway.create_portal_entity(vector.offset(params.teleport_destination, 0, 7, 0), {
			target = obsidian_gateway.get_gate_player_spawn_pos(
				params.gate_origin, params.gate_orientation),
		})
	end
end



if not randspawn.run_once then
	-- Reloadable.
	local file = randspawn.modpath .. "/init.lua"
	local name = "randspawn:core"
	reload.register_file(name, file, false)

	portal_cb.register_after_use(function(params)
		randspawn.on_outback_gate_use(params)
	end)

	randspawn.modstorage = minetest.get_mod_storage()
	randspawn.run_once = true
end
