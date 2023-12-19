
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
		--minetest.log(dump(pref:get_properties()))
		--minetest.log(dump(pref:get_nametag_attributes()))

		-- Initial (default) modifiers MUST be at index 1 in each stack.
		-- Initial modifiers are all named "".
		players[pname] = {
			-- Physics stack.
			physics = {
				{name="", data=pref:get_physics_override()},
			},
			eye_offset = {
				{name="", data={pref:get_eye_offset()}},
			},
			properties = {
				{name="", data=pref:get_properties()},
			},
			nametag = {
				{name="", data=pref:get_nametag_attributes()},
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



-- Combine all modifiers in named stack to a single table. Numbers are
-- multiplied together if meaningful to do so. Boolean flags and other data
-- simply overwrite, with the data at the top of the player's stack taking
-- precedence.
local function combine_data(data, stack)
	local o = {}

	if stack == "physics" then
		for k, v in ipairs(data.physics) do
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
			for i, j in ipairs(v.data) do
				o[i] = j
			end
		end
	elseif stack == "properties" then
		for k, v in ipairs(data.properties) do
			for i, j in ipairs(v.data) do
				o[i] = j
			end
		end
	elseif stack == "nametag" then
		for k, v in ipairs(data.nametag) do
			for i, j in ipairs(v.data) do
				o[i] = j
			end
		end
	end

	return o
end



-- Combine all datums in this player's named stack, and apply them.
local function update_player_data(pref, stack, data)
	if stack == "physics" then
		pref:set_physics_override(combine_data(data, stack))
	elseif stack == "eye_offset" then
		local v1, v2, v3 = unpack(combine_data(data, stack))
		pref:set_eye_offset(v1, v2, v3)
	elseif stack == "properties" then
		pref:set_properties(combine_data(data, stack))
	elseif stack == "nametag" then
		pref:set_nametag_attributes(combine_data(data, stack))
	end
end



-- Get currently-active overrides (combining all modifiers in named stack).
function pova.get_combined_override(pref, stack)
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
function pova.add_modifier(pref, stack, modifiers, name)
	local data = get_player(pref)
	if name ~= "" and stack ~= "" then
		table.insert(data[stack], {name=name, data=modifiers})
	end
	update_player_data(pref, stack, data)
end



-- Set named modifier in the player's stack. The modifier is added if it doesn't
-- exist, otherwise it is replaced.
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



-- Remove modifier by name from named stack. This undoes the effect of adding
-- the named modifier.
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



-- Remove all modifiers when player leaves game! If there is a bug (and there
-- will be bugs) this allows a player to reset all their modifiers to defaults.
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
