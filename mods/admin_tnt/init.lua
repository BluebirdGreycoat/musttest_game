
admin_tnt = admin_tnt or {}
admin_tnt.modpath = minetest.get_modpath("admin_tnt")
admin_tnt.explode_time = 60*60*24*3+60*60*3
admin_tnt.step_time = 30

-- Development protection.
--if not minetest.is_singleplayer() then
--	return
--end

local function time_to_string(time)
	local floor = math.floor
	local mod = math.mod

	local days = floor(time/86400)
  local hours = floor(floor(time % 86400)/3600)
  local minutes = floor(floor(time % 3600)/60)

	local sday = "days"
	local shour = "hours"
	local smin = "minutes"

	if days == 1 then sday = "day" end
	if hours == 1 then shour = "hour" end
	if minutes == 1 then smin = "minute" end

	return days .. " " .. sday .. ", " ..
		hours .. " " .. shour .. ", " ..
		minutes .. " " .. smin
end

function admin_tnt.on_construct(pos)
end

function admin_tnt.on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local time = meta:get_int("explode_in")
	time = time - elapsed
	if time <= 0 then
		time = 0
	end
	meta:set_int("explode_in", time)

	if time <= 0 then
		-- Who was this bomb marked for?
		local keyname = meta:get_string("keyname") or ""

		minetest.remove_node(pos) -- Remove TNT node.

		-- Explode. Placed in minetest.after() to avoid callstack issues.
		minetest.after(0, function()
			tnt.boom(pos, {
				radius = 4,
				ignore_protection = false,
				ignore_on_blast = true, -- Necessary to get rid of protectors.
				damage_radius = 6,
				disable_drops = true,
				name = keyname, -- Only destroy stuff owned by this player, or no-one.
			})
		end)
	end

	meta:set_string("infotext", "Admin TNT will explode in " .. time_to_string(time) .. ".")
	return true -- Run timer again for same timeout value.
end

function admin_tnt.after_place_node(pos, placer, itemstack, pt)
	local pname = placer and placer:get_player_name() or ""

	-- Make sure tnt was placed by admin, otherwise remove.
	if not gdac.player_is_admin(pname) then
		minetest.remove_node(pos)
		return
	end

	local et = math.floor(admin_tnt.explode_time)

	-- Start nodetimer.
	local timer = minetest.get_node_timer(pos)
	timer:start(admin_tnt.step_time)

	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", "Admin TNT will explode in " .. time_to_string(et) .. ".")
	meta:set_int("explode_in", et)

	-- Admin TNT becomes keyed to the owner of the area it is placed in.
	-- If no owner, then TNT is not keyed to anybody.
	local keyname = protector.get_node_owner(pos) or ""
	meta:set_string("keyname", keyname)

	-- Mark as private!
	meta:mark_as_private({"keyname", "explode_in"})
end

-- Does nothing when blasted.
function admin_tnt.on_blast(pos, intensity)
end

function admin_tnt.can_dig(pos, player)
	return false
end

if not admin_tnt.registered then
	-- There is no craft recipe for this item.
	minetest.register_node("admin_tnt:tnt", {
		description = "Admin TNT\n\nWarning: will destroy protectors and bedrock!\nIgnores `on_blast' callbacks.\nFor admin use only.\nBlast radius: 4 blocks.\n\nIf placed in a protected area, will only destroy stuff owned by that player.",
		tiles = {
			"admin_tnt_top.png",
			"admin_tnt_bottom.png",
			"admin_tnt_side.png",
		},
		paramtype2 = "facedir",

		-- Requires admin pick to remove.
		groups = {
			admin_tnt = 1, immovable = 1, unbreakable = 1,
		},

		sounds = default.node_sound_wood_defaults(),
		drop = "",
		diggable = false,
		always_protected = true, -- Cannot be removed without protection bypass. Protector mod handles this.

		on_construct = function(...)
			return admin_tnt.on_construct(...)
		end,

		after_place_node = function(...)
			return admin_tnt.after_place_node(...)
		end,

		on_timer = function(...)
			return admin_tnt.on_timer(...)
		end,

		on_blast = function(...)
			return admin_tnt.on_blast(...)
		end,

		can_dig = function(...)
			return admin_tnt.can_dig(...)
		end,
	})

	local c = "admin_tnt:core"
	local f = admin_tnt.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	admin_tnt.registered = true
end
