
-- Localize for performance.
local math_floor = math.floor

-- Code API.
if not minetest.global_exists("hud_clock") then hud_clock = {} end

local player_hud = {}

local timer = 0
local positionx = 1.0
local positiony = 1.0 --0.02

--local positionx = 0.30;   --horz
--local positiony = 0.90;  --vert

local last_time = os.time()


local function floormod ( x, y )
	return (math_floor(x) % y);
end

local function get_digxp(pname)
	return string.format("%.2f", xp.get_xp(pname, "digxp"))
end

function hud_clock.get_time()
	local secs = (60*60*24*minetest.get_timeofday())
	local s = floormod(secs, 60)
	local m = floormod(secs/60, 60)
	local h = floormod(secs/3600, 60)
	local a = "Noctis"
	if secs >= 60*60*5 and secs <= 60*60*19 then
		a = "Dies"
	end
	if h > 12 then
		h = h - 12
	end
	if h < 1 then
		h = h + 12
	end
	return ("%02d:%02d %s"):format(h, m, a);
end

minetest.register_globalstep(function ( dtime )
	timer = timer + dtime;
	if os.time() >= last_time then
		last_time = os.time() + 1
		if (timer >= 1.0) then
			timer = 0
			for _,player in ipairs(minetest.get_connected_players()) do
				local name = player:get_player_name();
				if player_hud[name] then
					local h = player_hud[name].clock
					player:hud_change(h, "text", hud_clock.get_time())
				end
			end
		end
	end
end)



function hud_clock.update_xp(pname)
	local pref = minetest.get_player_by_name(pname)
	if pref and player_hud[pname] then
		local x = player_hud[pname].digxp
		pref:hud_change(x, "text", ("Mineral XP: " .. get_digxp(pname)))
	end
end



minetest.register_on_joinplayer(function(pref)
	local pname = pref:get_player_name()
	if player_hud[pname] then
		player_hud[pname] = nil
	end
	player_hud[pname] = {}
	local offy = -130
	local h = pref:hud_add({
		type = "text",
		position = {x=positionx, y=positiony},
		alignment = {x=-1, y=1},
		offset = {x=-16, y=offy},
		text = hud_clock.get_time(),
		number = 0xFFFFFF,
	})
	local c = pref:hud_add({
		type = "image",
		position = {x=positionx, y=positiony},
		alignment = {x=-1, y=1},
		offset = {x=-108, y=offy},
		scale = {x=1, y=1},
		text = "mthudclock.png",
	})
	local x = pref:hud_add({
		type = "text",
		position = {x=positionx, y=positiony},
		offset = {x=-16, y=offy + 18},
		alignment = {x=-1, y=1},
		text = ("Mineral XP: " .. get_digxp(pname)),
		number = 0xFFFFFF,
	})
	player_hud[pname].clock = h
	player_hud[pname].icon = c
	player_hud[pname].digxp = x
end)

-- Do NOT change formatting, code relies on this!
function hud_clock.get_datetime(days)
	local season = snow.get_day()

	local r1 = math_floor(days/(34*12)) -- Years.
	local r2 = math_floor(days%(34*12)) -- Year remainder, in days.

	local m1 = math_floor(r2/34) -- Months.
	local m2 = math_floor(r2%34) -- Month remainder, in days.
	local d1 = m2 -- Days.

	return season .. "\nSince Epoch: " .. r1+1 .. "/" .. m1+1 .. "/" .. d1+1
end

-- Do NOT change formatting, code relies on this!
function hud_clock.get_date_string()
	local time = os.time()
	local epoch = os.time({year=2016, month=10, day=1})
	time = time - epoch
	local days = math_floor(((time/60)/60)/24)
	return hud_clock.get_datetime(days)
end

function hud_clock.get_calendar_infotext(pos)
	local days1 = math_floor(serveressentials.get_outback_timeout() / (60*60*24))
	local days2 = math_floor(randspawn.get_spawn_reset_timeout() / (60*60*24))
	local days3 = math_floor(serveressentials.get_midfeld_timeout() / (60*60*24))

	days1 = math.max(days1, 0)
	days2 = math.max(days2, 0)
	days3 = math.max(days3, 0)

	local realmname = rc.current_realm_at_pos(pos)

	return hud_clock.get_date_string() ..
		"\nSpawn: " .. randspawn.get_spawn_name(realmname) ..
		"\nOutback Winds: " .. days1 .. " Days" ..
		"\nOutback Gate: " .. days2 .. " Days" ..
		"\nMidfeld Fog: " .. days3 .. " Days"
end

minetest.register_node("clock:calendar", {
	description = "Calendar of Enyekala",
	tiles = {"calendar.png"},
	wield_image = "calendar.png",
	inventory_image = "calendar.png",
	sounds = default.node_sound_leaves_defaults(),
	groups = utility.dig_groups("bigitem", {flammable = 1}),
	paramtype = 'light',
	paramtype2 = "wallmounted",
	drawtype = "nodebox",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.375, 0.4375, -0.5, 0.375, 0.5, 0.5},
		wall_bottom = {-0.375, -0.5, -0.5, 0.375, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.375, -0.4375, 0.5, 0.375},
	},
	selection_box = {type = "wallmounted"},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", hud_clock.get_calendar_infotext(pos))
		minetest.get_node_timer(pos):start(60*60)
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", hud_clock.get_calendar_infotext(pos))
		minetest.get_node_timer(pos):start(60*60)
	end,

	on_punch = function(pos, node, puncher, pt)
		if not puncher or not puncher:is_player() then
			return
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", hud_clock.get_calendar_infotext(pos))
	end,
})

minetest.register_craft({
	output = "clock:calendar",
	recipe = {
		{'', 'default:paper', ''},
		{'', 'group:stick', ''},
		{'', 'default:paper', ''},
	},
})

