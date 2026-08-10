
local function do_protector_scan(pos, pname, guiobj)
	minetest.chat_send_player(pname, "# Server: Protection scan!")

	local nodes = {
		"protector:protect",
		"protector:protect2",
		"protector:protect3",
		"protector:protect4",
	}

	local D = 22 -- Covers a 45x45x45 area.
	local minp = vector.subtract(pos, D)
	local maxp = vector.add(pos, D)

	local prots = minetest.find_nodes_in_area(minp, maxp, nodes)
	if not prots then
		prots = {} -- Nil check.
	end

	minetest.chat_send_player(pname, "# Server: Found " .. #prots .. " prots!")
end



local FORMTABLE = {
	size = {x=10.7, y=6.7},
	children = {
		{h=6.7, texture="gui_formbg.png", type="background9", w=10.7, x=0, x1=50, y=0},
		{h=0.6, label="Find Claims", name="protector_scan", type="button", w=2, x=0.5, y=0.5},
	},
}



function city_block.create_mayor_formspec(pos, pname, blockdata)
	local guiobj = city_block.guiobjs[pname]
	if not guiobj then
		guiobj = formspec.create_gui_object(FORMTABLE)
		city_block.guiobjs[pname] = guiobj
	end

	return guiobj:to_formspec()
end



function city_block.on_mayor_fields(player, formname, fields)
	if formname ~= "city_block:mayor" then
		return
	end
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pos = city_block.formspecs[pname]
	local guiobj = city_block.guiobjs[pname]

	-- Context should have been created in 'on_rightclick'. CSM protection.
	if not pos or not guiobj then
		return true
	end

	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	-- Form sender must be owner.
	if pname ~= owner then
		return true
	end

	if fields.quit then
		city_block.formspecs[pname] = nil
		city_block.guiobjs[pname] = nil
		return true
	end

	if fields.protector_scan then
		do_protector_scan(pos, pname, guiobj)
	end

	minetest.show_formspec(pname, "city_block:mayor", guiobj:to_formspec())
	return true
end
