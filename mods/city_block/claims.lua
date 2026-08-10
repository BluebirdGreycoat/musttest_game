
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

	if fields.quit then
		city_block.formspecs[pname] = nil
		city_block.guiobjs[pname] = nil
		return true
	end

	if fields.protector_scan then
		minetest.chat_send_player(pname, "# Server: Protection scan!")
		return true
	end

	return true
end
