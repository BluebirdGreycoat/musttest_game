
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME
local time_active = city_block.time_active

local FORMTABLE = dofile(city_block.modpath .. "/city_gui.lua")



function city_block.create_formspec(pos, pname, blockdata)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z

	local guiobj = formspec.create_gui_object(FORMTABLE)
	guiobj:get_control_by_id("configlist").inventory_location = "nodemeta:" .. spos
	guiobj:get_control_by_id("configlist").list_name = "config"
	guiobj:get_control_by_name("CITYNAME").default = blockdata.area_name

	-- Create inventory if needed.
	if inv:get_size("config") == 0 then
		inv:set_size("config", 1)
	end

	guiobj:get_control_by_name("pvp_arena").selected = (blockdata.pvp_arena == true)
	guiobj:get_control_by_name("hud_beacon").selected = (blockdata.hud_beacon == true)
	guiobj:get_control_by_name("allow_protectors").selected = (blockdata.allow_protectors == nil or blockdata.allow_protectors == true)

	return guiobj:to_formspec()
end



local function check_cityname(cityname)
  return not string.match(cityname, "[^%a%s]")
end



function city_block.on_receive_fields(player, formname, fields)
	if formname ~= "city_block:main" and formname ~= "city_block:mayor" then
		return
	end
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pos = city_block.formspecs[pname]
	local block = city_block.get_block(pos)

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not pos then
		return true
	end

	-- Ensure we got the city block data.
	if not block then
		return true
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	-- Form sender must be owner.
	if pname ~= owner then
		return true
	end

	if fields.manage_claims then
		local is_admin = gdac.player_is_admin(pname)
		local blocktime = block.time or 0
		local have_xp = (xp.get_xp(pname, "buildxp") >= city_block.BUILDXP_FOR_MAYOR)
		local have_time = (block.time ~= nil and block.time >= city_block.BOROUGH_MIN_ACTIVATION_TIME)
		local refused = true

		if is_admin or (have_xp and have_time) then
			if is_admin then
				have_xp = true
				have_time = true
			end

			local formspec = city_block.create_mayor_formspec(pos, pname, block)
			minetest.show_formspec(pname, "city_block:mayor", formspec)
			refused = false
		end

		city_block.run_callbacks("log_borough_action", {
			pname = pname,
			is_admin = is_admin,
			time = blocktime,
			have_xp = have_xp,
			have_time = have_time,
			pos = pos,
			refused = refused,
		})

		return true
	end

	if formname == "city_block:mayor" then
		city_block.on_mayor_fields(player, formname, fields)
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

		-- Write out.
		meta:set_string("cityname", area_name)
		meta:set_string("infotext", city_block.get_infotext(pos))

		if #area_name > 0 then
			block.area_name = area_name
		else
			block.area_name = nil
		end

		city_block:save()
	end

	if fields.pvp_arena == "true" then
		block.pvp_arena = true
		meta:set_string("infotext", city_block.get_infotext(pos))
		city_block:save()
	elseif fields.pvp_arena == "false" then
		block.pvp_arena = nil
		meta:set_string("infotext", city_block.get_infotext(pos))
		city_block:save()
	end

	if fields.hud_beacon == "true" then
		block.hud_beacon = true
		city_block:save()
	elseif fields.hud_beacon == "false" then
		block.hud_beacon = nil
		city_block:save()
	end

	if fields.allow_protectors then
		local str = fields.allow_protectors
		if str == "true" then
			block.allow_protectors = true
		elseif str == "false" then
			if city_block.have_conflicting_boroughs(block) then
				minetest.chat_send_player(pname, "# Server: Foreign borough takes precedence!")
			else
				block.allow_protectors = false
			end
		end
		city_block:save()
	end

	if fields.quit then
		city_block.formspecs[pname] = nil
		city_block.guiobjs[pname] = nil
		return true
	end

	return true
end
