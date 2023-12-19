
-- Player modifiers mod for Enyekala.
-- Author of source code: MustTest/BlueBird51
-- License of source code: MIT

if not minetest.global_exists("pova") then pova = {} end
pova.modpath = minetest.get_modpath("pova")
pova.players = pova.players or {}



-- Get data for player, creating an initial table with default data if needed.
local function get_player(pref)
	local players = pova.players
	local pname = pref:get_player_name()
	local data = players[pname]
	if not data then
		--minetest.log(dump(pref:get_physics_override()))
		--minetest.log(dump({pref:get_eye_offset()}))

		players[pname] = {
			-- Physics stack.
			physics = {
				-- Initial (default) entry MUST be at index 1.
				{name="", data=pref:get_physics_override()},
			},
			eye_offset = {
				{name="", data={pref:get_eye_offset()}},
			},
		}

		data = players[pname]
	end
	return data
end



-- Update the initial (default) entry in the physics stack (index 1).
local function set_initial_data(data, stack, newdata)
	local initial = data[stack][1].data

	for k, v in pairs(newdata) do
		initial[k] = v
	end
end



-- Combine all physics overrides in stack to a single table. Numbers are
-- multiplied together. Boolean flags and other data simply overwrite, with the
-- data at the top of the player's stack taking precedence.
local function combine_data(data, stack)
	local o = {}

	if stack == "physics" then
		for k, v in ipairs(data.physics) do
			-- Iterate through all keys in the physics_override (v.data) table.
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
		for k, v in ipairs(data.eye_offset) do
			-- Iterate through all keys in the physics_override (v.data) table.
			for i, j in ipairs(v.data) do
				-- Booleans, etc.
				o[i] = j
			end
		end
	end

	return o
end



-- Combine all physics overrides in this player's override stack, and apply
-- them.
local function update_player_data(pref, stack, data)
	if stack == "physics" then
		pref:set_physics_override(combine_data(data, stack))
	elseif stack == "eye_offset" then
		local v1, v2, v3 = unpack(combine_data(data, stack))
		pref:set_eye_offset(v1, v2, v3)
	end
end



-- Get currently-active physics overrides (combining all modifiers in player's
-- stack).
function pova.get_combined_override(pref, stack)
	local data = get_player(pref)
	return combine_data(data, stack)
end



-- Set default physics overrides. Avoid using this function when possible. If
-- you call it, you usually need to call it again with original data in order to
-- restore overrides to what they were before.
function pova.set_override(pref, stack, overrides)
	local data = get_player(pref)
	set_initial_data(data, stack, overrides)
	update_player_data(pref, stack, data)
end



-- Add physics modifier to player's stack. The modifier is always added to the
-- top.
function pova.add_modifier(pref, stack, modifiers, name)
	local data = get_player(pref)
	if name ~= "" and stack ~= "" then
		table.insert(data[stack], {name=name, data=modifiers})
	end
	update_player_data(pref, stack, data)
end



-- Set named physics modifier in the player's stack. The modifier is added if it
-- doesn't exist, otherwise it is replaced.
function pova.set_modifier(pref, stack, modifiers, name)
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
			table.insert(data[stack], {name=name, data=modifiers})
		end
	end

	update_player_data(pref, stack, data)
end



-- Remove physics modifier by name. This undoes the effect of adding the named
-- modifier.
function pova.remove_modifier(pref, stack, name)
	local data = get_player(pref)

	-- Do not allow removing the initial overrides.
	if name ~= "" and stack ~= "" then
		for k, v in ipairs(data[stack]) do
			if v.name == name then
				table.remove(data[stack], k)
				break
			end
		end
	end

	update_player_data(pref, stack, data)
end



-- Remove all modifiers when player leaves game!
function pova.on_leaveplayer(pref)
	local pname = pref:get_player_name()
	pova.players[pname] = nil
end



if not pova.registered then
	pova.registered = true

	minetest.register_on_leaveplayer(function(...)
		return pova.on_leaveplayer(...)
	end)

	-- Register mod reloadable.
	local c = "pova:core"
	local f = pova.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
