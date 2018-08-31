
xp = xp or {}
xp.modpath = minetest.get_modpath("xp")
xp.digxp_max = 1000
xp.data = xp.data or {} -- Data is stored in string form.
xp.dirty = true



-- This code supports multiple types of XP.
-- Different types of XP are stored seperately.
function xp.set_xp(pname, kind, amount)
	local key = pname .. ":" .. kind
	xp.data[key] = tostring(amount)
	xp.dirty = true
end



function xp.get_xp(pname, kind)
	local key = pname .. ":" .. kind
	if not xp.data[key] then
		return 0
	end
	return tonumber(xp.data[key])
end



function xp.write_xp()
	if xp.dirty then
		local temp = {}
		for k, v in pairs(xp.data) do
			-- Only save XP if >= min XP.
			if tonumber(v) >= 5.0 then
				temp[k] = v
			end
		end
		xp.storage:from_table({fields=temp})
	end
	xp.dirty = false
end



local timer = 0
local delay = 60*5
function xp.globalstep(dtime)
	timer = timer + dtime
	if timer >= delay then
		timer = 0
		xp.write_xp()
	end
end



if not xp.run_once then
	xp.storage = minetest.get_mod_storage()

	-- Load data.
	local data = xp.storage:to_table() or {}
	xp.data = data.fields or {}

	-- Save data.
	minetest.register_on_shutdown(function() xp.write_xp() end)
	minetest.register_globalstep(function(...) xp.globalstep(...) end)

	local c = "xp:core"
	local f = xp.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	xp.run_once = true
end
