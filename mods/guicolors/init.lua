
if not minetest.global_exists("default") then default = {} end
if not minetest.global_exists("guicolors") then guicolors = {} end
guicolors.modpath = minetest.get_modpath("guicolors")




function default.get_hotbar_bg(x, y, real)
	local out = ""
	local pad = 0
	if real then
		pad = 0.25
	end
	for i=0,7,1 do
		out = out .. "image[" .. x+i+(pad*i) .. "," .. y .. ";1,1;gui_hb_bg.png]"
	end
	return out
end

default.formspec = {}

default.formspec.get_form_colors = function()
	local colors = "bgcolor[#080808BB;true]"
	return colors
end
default.formspec.get_slot_colors = function()
	local colors = "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]"
	return colors
end
default.formspec.get_form_image = function()
	local image = "background9[5,5;1,1;gui_formbg.png;true;100]"
	return image
end



default.gui_bg = default.formspec.get_form_colors()
default.gui_bg_img = default.formspec.get_form_image()
default.gui_slots = default.formspec.get_slot_colors()



default.formspec.get_default_form = function()
	local formspec = "size[8,8.5]" ..
		default.formspec.get_form_colors() ..
		default.formspec.get_slot_colors() ..
		default.formspec.get_form_image() ..
		"list[current_player;main;0,4.25;8,1;]" ..
		"list[current_player;main;0,5.5;8,3;8]" ..
		"list[current_player;craft;3,0.5;3,3;]" ..
		"list[current_player;craftpreview;7,1.5;1,1;]" ..
    --"image[7,2.5;1,1;gui_furnace_arrow_bg.png]" ..
		"image[6,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
		"listring[current_player;main]" ..
		"listring[current_player;craft]" ..
		default.get_hotbar_bg(0,4.25)
	return formspec
end



