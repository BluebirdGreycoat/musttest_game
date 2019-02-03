
-- Code API.
hud_clock = hud_clock or {}

local player_hud = {}

local timer = 0
local positionx = 0.97
local positiony = 0.9 --0.02

--local positionx = 0.30;   --horz
--local positiony = 0.90;  --vert

local last_time = os.time()


local function floormod ( x, y )
	return (math.floor(x) % y);
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
		if (timer >= 10.0) then
			timer = 0
			for _,player in ipairs(minetest.get_connected_players()) do
				local name = player:get_player_name();
				if player_hud[name] then
					local h = player_hud[name].clock
					player:hud_change(h, "text", hud_clock.get_time())
					--local x = player_hud[name].digxp
					--player:hud_change(x, "text", ("Dig XP: " .. xp.get_xp(pname, "digxp")))
				end
			end
		end
	end
end)



function hud_clock.update_xp(pname)
	local player = minetest.get_player_by_name(pname)
	if player and player_hud[pname] then
		local x = player_hud[pname].digxp
		player:hud_change(x, "text", ("Mineral XP: " .. get_digxp(pname)))
	end
end



minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if player_hud[pname] then
		player_hud[pname] = nil
	end
	player_hud[pname] = {}
	local h = player:hud_add({
		hud_elem_type = "text",
		position = {x=positionx, y=positiony},
		alignment = {x=-1, y=1},
		offset = {x=0, y=0},
		text = hud_clock.get_time(),
		number = 0xFFFFFF,
	})
	local c = player:hud_add({
		hud_elem_type = "image",
		position = {x=positionx, y=positiony},
		alignment = {x=-1, y=1},
		offset = {x=-95, y=-2},
		scale = {x=1, y=1},
		text = "mthudclock.png",
	})
	local x = player:hud_add({
		hud_elem_type = "text",
		position = {x=positionx, y=positiony},
		offset = {x=0, y=18},
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

	local r1 = math.floor(days/(34*12)) -- Years.
	local r2 = math.floor(days%(34*12)) -- Year remainder, in days.

	local m1 = math.floor(r2/34) -- Months.
	local m2 = math.floor(r2%34) -- Month remainder, in days.
	local d1 = m2 -- Days.

	return season .. "\nSince Epoch: " .. r1+1 .. "/" .. m1+1 .. "/" .. d1+1
end

-- Do NOT change formatting, code relies on this!
function hud_clock.get_date_string()
	local time = os.time()
	local epoch = os.time({year=2016, month=10, day=1})
	time = time - epoch
	local days = math.floor(((time/60)/60)/24)
	return hud_clock.get_datetime(days)
end

function hud_clock.get_calendar_infotext()
	return hud_clock.get_date_string() .. "\nCurrent Spawn: " .. randspawn.get_spawn_name()
end

minetest.register_node("clock:calendar", {
	description = "Snowmelt Calendar",
	tiles = {"calendar.png"},
	wield_image = "calendar.png",
	inventory_image = "calendar.png",
	sounds = default.node_sound_leaves_defaults(),
	groups = {level = 1, dig_immediate = 2},
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
		meta:set_string("infotext", hud_clock.get_calendar_infotext())
		minetest.get_node_timer(pos):start(60*60)
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", hud_clock.get_calendar_infotext())
		minetest.get_node_timer(pos):start(60*60)
	end,

	on_punch = function(pos, node, puncher, pt)
		if not puncher or not puncher:is_player() then
			return
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", hud_clock.get_calendar_infotext())
	end,
})

minetest.register_craft({
	output = "clock:calendar",
	recipe = {
		{'', 'default:paper', ''},
		{'', 'default:stick', ''},
		{'', 'default:paper', ''},
	},
})

