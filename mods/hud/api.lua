
-- global values
hud.registered_items = {}
hud.damage_events = {}
hud.breath_events = {}

-- keep id handling internal
local hud_id = {}	-- hud item ids
local sb_bg = {}	-- statbar background ids

-- localize often used table
local items = hud.registered_items

local function throw_error(msg)
	minetest.log("error", "Better HUD[error]: " .. msg)
end



--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

function hud.register(name, def)
	if not name or not def then
		throw_error("Not enough parameters given")
		return false
	end

	--TODO: allow other elements
	if def.hud_elem_type ~= "statbar" then
		throw_error("The given HUD element is not a statbar")
		return false
	end

	if items[name] ~= nil then
		throw_error("A statbar with that name already exists")
		return false
	end

	-- Actually register
	-- Add background first since draworder is based on id.
	if def.hud_elem_type == "statbar" and def.background ~= nil then
		sb_bg[name] = table.copy(def)
		sb_bg[name].text = def.background
		sb_bg[name].number = 20
	end

	-- add item itself
	items[name] = def

	-- register events
	if def.events then
		for _, v in pairs(def.events) do
			if v and v.type and v.func then
				if v.type == "damage" then
					table.insert(hud.damage_events, v)
				end

				if v.type == "breath" then
					table.insert(hud.breath_events, v)
				end
			end
		end
	end
	
	-- no error so far, return sucess
	return true
end



function hud.change_item(player, name, def)
	if not player or not player:is_player() or not name or not def then
		throw_error("Not enough parameters given to change HUD item")
		return false
	end

	local i_name = player:get_player_name().."_"..name
	local elem = hud_id[i_name]
	if not elem then
		--throw_error("Given HUD element " .. dump(name) .. " does not exist")
		return false
	end

	-- Update supported values (currently number and text only)
	if def.number and elem.number then
		elem.number = math.floor((def.number / def.max) * 20)

		player:hud_change(elem.id, "number", elem.number)
	end

	if def.text and elem.text then
		player:hud_change(elem.id, "text", def.text)
		elem.text = def.text
	end

	if def.offset and elem.offset then
		player:hud_change(elem.id, "offset", def.offset)
		elem.offset = def.offset
	end

	return true
end



function hud.remove_item(player, name)
	if not player or not name then
		throw_error("Not enough parameters given")
		return false
	end

	local i_name = player:get_player_name() .. "_" .. name
	if hud_id[i_name] == nil then
		--throw_error("Given HUD element " .. dump(name) .. " does not exist")
		return false
	end

	player:hud_remove(hud_id[i_name].id)
	hud_id[i_name] = nil

	return true
end


--------------------------------------------------------------------------------
-- Add registered HUD items to joining players
--------------------------------------------------------------------------------

-- Following code is placed here to keep HUD ids internal.
local function add_hud_item(player, name, def)
	if not player or not name or not def then
		throw_error("not enough parameters given")
		return false
	end

	local i_name = player:get_player_name() .. "_" .. name
	hud_id[i_name] = def
	hud_id[i_name].id = player:hud_add(def)
end

minetest.register_on_joinplayer(function(player)
	-- First: hide the default statbars.
	local hud_flags = player:hud_get_flags()
	hud_flags.healthbar = false
	hud_flags.breathbar = false
	player:hud_set_flags(hud_flags)

	-- Now add the backgrounds for statbars.
	for _, item in pairs(sb_bg) do
		add_hud_item(player, _ .. "_bg", item)
	end

	-- And finally the actual HUD items.
	for _, item in pairs(items) do
		add_hud_item(player, _, item)
	end
end)
