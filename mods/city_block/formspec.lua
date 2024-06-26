
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME
local time_active = city_block.time_active



function city_block.create_formspec(pos, pname, blockdata)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z

	-- Create inventory if needed.
	if inv:get_size("config") == 0 then
		inv:set_size("config", 1)
	end

	local pvp = "false"
	if blockdata.pvp_arena then
		pvp = "true"
	end

	local hud = "false"
	if blockdata.hud_beacon then
		hud = "true"
	end

	local formspec = "size[8.0,4.5]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"real_coordinates[true]" ..
		"container[2.5,0]" ..
			"container[0,0]" ..
				"label[0.3,0.5;Enter city/area region name:]" ..
				"field[0.30,0.75;3.5,0.8;CITYNAME;;]" ..
				"button_exit[3.9,0.75;1.5,0.4;OK;Confirm]" ..
				"button_exit[3.9,1.16;1.5,0.4;CANCEL;Abort]" ..
				"field_close_on_enter[CITYNAME;true]" ..
			"container_end[]" ..
			"checkbox[0.3,3.1;pvp_arena;Mark Dueling Arena;" .. pvp .. "]" ..
			"checkbox[0.3,3.5;hud_beacon;Signal Nearby Keys;" .. hud .. "]" ..
			"container[0.4,0]" ..
				"list[nodemeta:" .. spos .. ";config;3.95,2.9;1,1;]" ..
				"image[3.95,2.9;1,1;configurator_inv.png]" ..
			"container_end[]" ..
		"container_end[]" ..
		"container[0.4,4.6]" ..
			"list[current_player;main;0,0;8,1;]" ..
			default.get_hotbar_bg(0, 0, true) ..
		"container_end[]"

	return formspec
end



local function check_cityname(cityname)
  return not string.match(cityname, "[^%a%s]")
end



function city_block.on_receive_fields(player, formname, fields)
	if formname ~= "city_block:main" then
		return
	end
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pos = city_block.formspecs[pname]

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not pos then
		return true
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	-- Form sender must be owner.
	if pname ~= owner then
		return true
	end

	if fields.key_enter_field == "CITYNAME" or fields.OK then
		local area_name = (fields.CITYNAME or ""):trim()
		area_name = area_name:gsub("%s+", " ")

		-- Ensure city name is valid.
		local is_valid = true

		-- Empty area name means erase.
		--[[
		if #area_name == 0 then
			is_valid = false
		end
		--]]

		if #area_name > 20 then
			is_valid = false
		end
		if not check_cityname(area_name) then
			is_valid = false
		end

		if anticurse.check(pname, area_name, "foul") then
			is_valid = false
		elseif anticurse.check(pname, area_name, "curse") then
			is_valid = false
		end

		if not is_valid then
			minetest.chat_send_player(pname, "# Server: Region name not valid.")
			return
		end

		local block = city_block.get_block(pos)

		-- Ensure we got the city block data.
		if not block then
			return
		end

		-- Write out.
		meta:set_string("cityname", area_name)
		meta:set_string("infotext", city_block.get_infotext(pos))

		if #area_name > 0 then
			block.area_name = area_name
		else
			block.area_name = nil
		end

		city_block:save()
	---[[
	elseif fields.pvp_arena == "true" then
		local block = city_block.get_block(pos)
		if block then
			minetest.chat_send_player(pname, "# Server: Enabled dueling arena.")
			block.pvp_arena = true
			meta:set_string("infotext", city_block.get_infotext(pos))
			city_block:save()
		end
	elseif fields.pvp_arena == "false" then
		local block = city_block.get_block(pos)
		if block then
			minetest.chat_send_player(pname, "# Server: Disabled dueling arena.")
			block.pvp_arena = nil
			meta:set_string("infotext", city_block.get_infotext(pos))
			city_block:save()
		end
	--]]
	---[[
	elseif fields.hud_beacon == "true" then
		local block = city_block.get_block(pos)
		if block then
			minetest.chat_send_player(pname, "# Server: Activated KEY signal.")
			block.hud_beacon = true
			city_block:save()
		end
	elseif fields.hud_beacon == "false" then
		local block = city_block.get_block(pos)
		if block then
			minetest.chat_send_player(pname, "# Server: Disabled KEY signal.")
			block.hud_beacon = nil
			city_block:save()
		end
	--]]
	end

	return true
end
