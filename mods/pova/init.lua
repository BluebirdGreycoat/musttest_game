
-- Player modifiers mod for Enyekala.
-- Author of source code: MustTest/BlueBird51
-- License of source code: MIT

if not minetest.global_exists("pova") then pova = {} end
pova.modpath = minetest.get_modpath("pova")
pova.players = pova.players or {}
pova.last_properties = pova.last_properties or {}

-- Used to force table.sort() to be stable.
-- This counter increases every time a modifier is added.
pova.counter = pova.counter or 0



-- Properties which pova must never modify (via pref:set_properties()).
local properties_blacklist = {
	eye_height = true,
	physical = true,
	collide_with_objects = true,
	colors = true,
	use_texture_alpha = true,
	spritediv = true,
	initial_sprite_basepos = true,
	automatic_rotate = true,
	automatic_face_movement_dir = true,
	automatic_face_movement_max_rotation_per_sec = true,
	backface_culling = true,
	nametag = true,
	nametag_color = true,
	static_save = true,
	shaded = true,
}

-- Properties which pova may modify (via pref:set_properties()).
local properties_whitelist = {
	hp_max = true,
	breath_max = true,
	zoom_fov = true,
	collisionbox = true,
	selectionbox = true,
	pointable = true,
	visual = true,
	visual_size = true,
	mesh = true,
	textures = true,
	is_visible = true,
	makes_footstep_sound = true,
	stepheight = true,
	glow = true,
	infotext = true,
	damage_texture_modifier = true,
	show_on_minimap = true,
}



local function filter_properties(data)
	local o = {}
	for k, v in pairs(data) do
		-- Blacklist takes precedence.
		if not properties_blacklist[k] then
			if properties_whitelist[k] then
				o[k] = v
			end
		end
	end
	return o
end



local function get_mode(mode)
	if type(mode) == "string" then
		local o = {
			op = mode,
			priority = 0,
			count = pova.counter,
			time = -1,
		}
		pova.counter = pova.counter + 1
		return o
	elseif type(mode) == "nil" then
		local o = {
			priority = 0,
			count = pova.counter,
			time = -1,
		}
		pova.counter = pova.counter + 1
		return o
	else
		local o = {
			op = mode.op or nil,
			priority = mode.priority or 0,
			count = pova.counter,
			time = mode.time or -1,
		}
		if o.priority < -999 then
			o.priority = -999
		end
		pova.counter = pova.counter + 1
		return o
	end
end



-- Get data for player, creating an initial table with default data if needed.
local function get_player(pref)
  local players = pova.players
	local pname = pref:get_player_name()
	local data = players[pname]
	if not data then
		--minetest.log(dump(pref:get_physics_override()))
		--minetest.log(dump({pref:get_eye_offset()}))
		--minetest.log(dump(pref:get_properties()))
		--minetest.log(dump(pref:get_nametag_attributes()))

		-- Initial (default) modifiers MUST be at index 1 in each stack.
		-- Initial modifiers are all named "".
		players[pname] = {
			-- Physics stack.
			physics = {
				{name="", data=pref:get_physics_override(), mode=get_mode({priority=-1000})},
			},
			eye_offset = {
				{name="", data={pref:get_eye_offset()}, mode=get_mode({priority=-1000})},
			},
			properties = {
				{name="", data=filter_properties(pref:get_properties()), mode=get_mode({priority=-1000})},
			},
			nametag = {
				{name="", data=pref:get_nametag_attributes(), mode=get_mode({priority=-1000})},
			},
		}

		data = players[pname]
	end
	return data
end



-- Update the initial (default) entry in the player's named stack (index 1).
local function set_initial_data(data, stack, newdata)
	local initial = data[stack][1].data

	for k, v in pairs(newdata) do
		initial[k] = v
	end
end



local function stable_sort(a, b)
	-- Highest priority entries move to the END of the array.
	-- The higher the priority value, the higher the priority (meaning it
	-- overrrides stuff with lower priority).
	if a.mode.priority < b.mode.priority then
		return true
	end

	-- If the priorities are equal, stable-sort according to counter.
	if a.mode.count < b.mode.count then
		return true
	end

	return false
end



local function do_sort(t)
	local v = table.copy(t)
	table.sort(v, stable_sort)
	return v
end



-- Combine all modifiers in named stack to a single table. Numbers are
-- multiplied together if meaningful to do so. Boolean flags and other data
-- simply overwrite, with the data at the top of the player's stack taking
-- precedence.
local function combine_data(data, stack)
	local o = {}

	if stack == "physics" then
		for k, v in ipairs(do_sort(data.physics)) do
			for i, j in pairs(v.data) do
				if type(j) == "number" then
					o[i] = (o[i] or 1.0) * j
				else
					-- Booleans, etc.
					o[i] = j
				end
			end
		end
	elseif stack == "eye_offset" then
		-- Note: 'eye_offset' is an ARRAY, not a key/value map.
		for k, v in ipairs(do_sort(data.eye_offset)) do
			for i, j in ipairs(v.data) do
				o[i] = j
			end
		end
	elseif stack == "properties" then
		for k, v in ipairs(do_sort(data.properties)) do
			if not v.mode.op then
				for i, j in pairs(v.data) do
					o[i] = j
				end
			elseif v.mode.op == "add" then
				for i, j in pairs(v.data) do
					if type(j) == "number" then
						o[i] = (o[i] or 0.0) + j
					else
						o[i] = j
					end
				end
			end
		end
	elseif stack == "nametag" then
		for k, v in ipairs(do_sort(data.nametag)) do
			for i, j in pairs(v.data) do
				o[i] = j
			end
		end
	end

	return o
end



local function equals(a, b)
	if a == b then
		return true
	end

	local t1 = type(a)
	local t2 = type(b)
	if t1 ~= t2 then
		return false
	end
	if t1 ~= "table" then
		return false
	end

	local key_set = {}

	for key1, value1 in pairs(a) do
		local value2 = b[key1]
		if value2 == nil or equals(value1, value2) == false then
			return false
		end
		key_set[key1] = true
	end

	-- Check if B contains any keys not found in A.
	for key2, _ in pairs(b) do
		if not key_set[key2] then return false end
	end

	return true
end



-- Combine all datums in this player's named stack, and apply them.
local function update_player_data(pref, stack, data)
	if stack == "physics" then
		pref:set_physics_override(combine_data(data, stack))
	elseif stack == "eye_offset" then
		local v1, v2, v3 = unpack(combine_data(data, stack))
		pref:set_eye_offset(v1, v2, v3)
	elseif stack == "properties" then
		local pname = pref:get_player_name()
		local new_props = filter_properties(combine_data(data, stack))
		local old_props = pova.last_properties[pname] or {}
		local changed_props = {}
		for k, v in pairs(new_props) do
			if not equals(old_props[k], v) then
				changed_props[k] = v
			end
		end
		pref:set_properties(changed_props)
		pova.last_properties[pname] = new_props
	elseif stack == "nametag" then
		pref:set_nametag_attributes(combine_data(data, stack))
	end
end



-- Get currently active overrides (combining all modifiers in named stack).
function pova.get_active_modifier(pref, stack)
	local data = get_player(pref)
	return combine_data(data, stack)
end



-- Set default overrides for the named stack. AVOID USING THIS FUNCTION WHEN
-- POSSIBLE. If you call it, you usually need to call it again with original
-- data in order to restore overrides to what they were before.
function pova.set_override(pref, stack, overrides)
	local data = get_player(pref)
	set_initial_data(data, stack, overrides)
	update_player_data(pref, stack, data)
end



-- Add modifier to player's named stack. The modifier is added to the top.
function pova.add_modifier(pref, stack, modifiers, name, mode)
	local data = get_player(pref)
	if name ~= "" and stack ~= "" then
		table.insert(data[stack], {name=name, data=modifiers, mode=get_mode(mode)})
	end
	update_player_data(pref, stack, data)
end



-- Set named modifier in the player's stack. The modifier is added if it doesn't
-- exist, otherwise it is replaced. If the modifier data is COMPLETELY replaced;
-- existing data is NOT combined with the new data.
function pova.set_modifier(pref, stack, modifiers, name, mode)
	local data = get_player(pref)

	-- Do not allow setting the default data.
	if name ~= "" and stack ~= "" then
		local replaced = false

		for k, v in ipairs(data[stack]) do
			if v.name == name then
				v.data = modifiers
				replaced = true
				break
			end
		end

		if not replaced then
			table.insert(data[stack], {name=name, data=modifiers, mode=get_mode(mode)})
		end
	end

	update_player_data(pref, stack, data)
end



-- This is the same as 'pova.set_modifier()', except that if the modifier
-- already exists, the new data is MERGED with the existing data, INSTEAD of
-- totally replacing it. Useful if you want to update a modifier, while
-- providing only a subset of its original data. However, the modifier will be
-- created if it doesn't exist, and put at the top of the named stack. This
-- function also allows you to change the modifer's mode table.
function pova.update_modifier(pref, stack, modifiers, name, mode)
	local data = get_player(pref)

	-- Do not allow setting the default data.
	if name ~= "" and stack ~= "" then
		local replaced = false

		for k, v in ipairs(data[stack]) do
			if v.name == name then
				-- Merge new data with existing data, overwriting as needed.
				for i, j in pairs(modifiers) do
					v.data[i] = j
				end
				if mode then
					v.mode = get_mode(mode)
				end
				replaced = true
				break
			end
		end

		if not replaced then
			table.insert(data[stack], {name=name, data=modifiers, mode=get_mode(mode)})
		end
	end

	update_player_data(pref, stack, data)
end



-- Remove modifier by name from named stack. This undoes the effect of adding
-- the named modifier. Does nothing if the named modifier does not exist in the
-- named stack.
function pova.remove_modifier(pref, stack, name)
	local data = get_player(pref)
	local removed = false

	-- Do not allow removing the initial overrides.
	if name ~= "" and stack ~= "" then
		for k, v in ipairs(data[stack]) do
			if v.name == name then
				table.remove(data[stack], k)
				removed = true
				break
			end
		end
	end

	if removed then
		update_player_data(pref, stack, data)
	end
end



-- Shall update modifier timers and remove expired ones.
function pova.globalstep(dtime)
	local function work(t, i)
		local d = t[i].mode
		if d.time >= 0 then
			d.time = d.time - dtime
			if d.time < 0 then
				return false
			end
		end
		return true
	end

	for pname, data in pairs(pova.players) do
		for stack, array in pairs(data) do
			local _, c = utility.array_remove(array, work)
			if c > 0 then
				local pref = minetest.get_player_by_name(pname)
				update_player_data(pref, stack, data)
			end
		end
	end
end



-- Remove all modifiers when player leaves game! If there is a bug (and there
-- will be bugs) this allows a player to reset all their modifiers to defaults.
function pova.on_leaveplayer(pref)
	local pname = pref:get_player_name()
	pova.players[pname] = nil
end



function pova.dump_modifiers(pname, param)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	local pref2 = minetest.get_player_by_name(param)
	if pref2 and pref2:is_player() then
		pref = pref2
	end

	local tname = pref:get_player_name()
	minetest.chat_send_player(pname, "# Server: Dumping modifiers of <" .. rename.gpn(tname) .. ">.")
	minetest.chat_send_player(pname, "# Server: " .. ("="):rep(80))

	local function round_numbers(t)
		for k, v in pairs(t) do
			if type(v) == "number" then
				t[k] = tonumber(string.format("%.2f", v))
			elseif type(v) == "table" then
				round_numbers(v)
			end
		end
	end

	local data = get_player(pref)
	local function dump_stack(pname, data, stack)
		minetest.chat_send_player(pname, "# Server: === Dumping \"" .. stack .. "\" ===")
		minetest.chat_send_player(pname, "# Server:")
		local tb = do_sort(data[stack])
		for k, v in ipairs(tb) do
			local t = table.copy(v)
			round_numbers(t)
			local dumps = dump(t)
			dumps = dumps:gsub("\n", " ")
			dumps = dumps:gsub("%s+", " ")
			dumps = dumps:gsub(" = ", "=")
			minetest.chat_send_player(pname, "# Server: (" .. k .. "): " .. dumps)
		end
		minetest.chat_send_player(pname, "# Server:")
	end

	for k, v in pairs(data) do
		dump_stack(pname, data, k)
	end
end



if not pova.registered then
	pova.registered = true

	minetest.register_globalstep(function(...)
		return pova.globalstep(...)
	end)

	minetest.register_chatcommand("pova", {
		params = "[<player>]",
		description = "List modifiers of self or player.",
		privs = {server=true},

		func = function(...)
			return pova.dump_modifiers(...)
		end
	})

	minetest.register_on_leaveplayer(function(...)
		return pova.on_leaveplayer(...)
	end)

	-- Register mod reloadable.
	local c = "pova:core"
	local f = pova.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
