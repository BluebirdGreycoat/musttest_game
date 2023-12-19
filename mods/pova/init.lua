
-- Player modifiers mod for Enyekala.
-- Author of source code: MustTest/BlueBird51
-- License of source code: MIT
-- This is not TenPlus1's 'pova' mod, nor is it based on it.

if not minetest.global_exists("pova") then pova = {} end
pova.modpath = minetest.get_modpath("pova")
pova.players = pova.players or {}



-- Get data for player, creating an initial table with default data if needed.
local function get_player(pref)
	local players = pova.players
	local pname = pref:get_player_name()
	local data = players[pname]
	if not data then
		players[pname] = {
			-- Physics stack.
			physics_stack = {
				-- Initial (default) entry MUST be at index 1.
				{name="", data=pref:get_physics_override()},
			},
		}
		data = players[pname]
	end
	return data
end



-- Update the initial (default) entry in the physics stack (index 1).
local function set_initial_physics(data, newdata)
	local initial = data.physics_stack[1].data

	for k, v in pairs(newdata) do
		initial[k] = v
	end
end



-- Combine all physics overrides in stack to a single table. Numbers are
-- multiplied together. Boolean flags and other data simply overwrite, with the
-- data at the top of the player's stack taking precedence.
local function combine_physics(data)
	local o = {}

	for k, v in ipairs(data.physics_stack) do
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

	return o
end



-- Combine all physics overrides in this player's override stack, and apply
-- them.
local function update_player_physics(pref, data)
	pref:set_physics_override(combine_physics(data))
end



-- Get currently-active physics overrides (combining all modifiers in player's
-- stack).
function pova.get_combined_physics_override(pref)
	local data = get_player(pref)
	return combine_physics(data)
end



-- Set default physics overrides. Avoid using this function when possible. If
-- you call it, you usually need to call it again with original data in order to
-- restore overrides to what they were before.
function pova.set_physics_override(pref, overrides)
	local data = get_player(pref)
	set_initial_physics(data, overrides)
	update_player_physics(pref, data)
end



-- Add physics modifier to player's stack. The modifier is always added to the
-- top.
function pova.add_physics_modifier(pref, modifiers, name)
	local data = get_player(pref)
	table.insert(data.physics_stack, {name=name, data=modifiers})
	update_player_physics(pref, data)
end



-- Set named physics modifier in the player's stack. The modifier is added if it
-- doesn't exist, otherwise it is replaced.
function pova.set_physics_modifier(pref, modifiers, name)
	local data = get_player(pref)

	-- Do not allow setting the default data.
	if name ~= "" then
		local replaced = false

		for k, v in ipairs(data.physics_stack) do
			if v.name == name then
				v.data = modifiers
				replaced = true
				break
			end
		end

		if not replaced then
			table.insert(data.physics_stack, {name=name, data=modifiers})
		end
	end

	update_player_physics(pref, data)
end



-- Remove physics modifier by name. This undoes the effect of adding the named
-- modifier.
function pova.remove_physics_modifier(pref, name)
	local data = get_player(pref)

	-- Do not allow removing the initial overrides.
	if name ~= "" then
		for k, v in ipairs(data.physics_stack) do
			if v.name == name then
				table.remove(data.physics_stack, k)
				break
			end
		end
	end

	update_player_physics(pref, data)
end



if not pova.registered then
	pova.registered = true

	-- Register mod reloadable.
	local c = "pova:core"
	local f = pova.modpath .. "/init.lua"
	reload.register_file(c, f, false)
end
