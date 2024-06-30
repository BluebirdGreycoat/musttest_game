
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random



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
