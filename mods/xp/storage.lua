
local IMBUE_PROXIMITY_DISTANCE = 256

local function chat_send(pname, spamkey, message)
	spamkey = pname .. ":" .. spamkey
	if not spam.test_key(spamkey) then
		spam.mark_key(spamkey, 30)
		minetest.chat_send_player(pname, "# Server: " .. message)
	end
end

-- Imbue or take experience points from a Rune Slab.
-- Explicitly NOT checking protection! So keep your Rune Slabs HIDDEN.
function xp.on_punch_sign(pos, node, pname)
	local function system_response(msg)
		minetest.chat_send_player(pname, "# Server: " .. msg)
	end

	local nn = minetest.get_node(pos)
	if nn.name ~= node.name then
		return
	end

	local pref = minetest.get_player_by_name(pname)
	if not pref or not pref:is_player() then
		return
	end

	local control = pref:get_player_control()
	if not control.sneak then
		return
	end

	-- Only for rune slabs.
	if not nn.name:find("stone") then
		return
	end

	local meta = minetest.get_meta(pos)
	local info = minetest.deserialize(meta:get_string("xp_storage")) or
		{owner="", total={dig=0, build=0}}

	if info.owner == "" then
		-- Imbue XP.
		local total = {dig=xp.get_xp(pname, "digxp"), build=xp.get_xp(pname, "buildxp")}
		if total.dig >= 1000 and total.build >= 1000 then
			total.dig = 1000
			total.build = 1000
			xp.subtract_xp(pname, "digxp", 1000)
			xp.subtract_xp(pname, "buildxp", 1000)
			info.total = total
			info.owner = pname
			system_response("You imbue some of your experience points into the Rune Slab.")

			xp.run_callbacks_after("on_runeslab_imbue", pos, pname)
			-- Serialize at end of function.
		else
			system_response("You need at least 1k experience points in both categories in order to imbue.")
			return
		end
	elseif info.owner == pname then
		-- Retrieve XP.
		local loss_scalar = 0.98

		local get_dig = info.total.dig * loss_scalar
		local get_build = info.total.build * loss_scalar

		xp.add_xp(pname, "digxp", get_dig)
		xp.add_xp(pname, "buildxp", get_build)

		info.total = {dig=0, build=0}
		info.owner = ""

		system_response("The stored experience points return to your person.")
		system_response("You gain: " .. get_dig .. " / " .. get_build .. ".")

		xp.run_callbacks_after("on_runeslab_retrieve", pos, pname)
		-- Serialize at end of function.
	else
		-- Steal XP.
		local original_owner = info.owner
		local loss_scalar = 0.75

		local get_dig = info.total.dig * loss_scalar
		local get_build = info.total.build * loss_scalar

		xp.add_xp(pname, "digxp", get_dig)
		xp.add_xp(pname, "buildxp", get_build)

		info.total = {dig=0, build=0}
		info.owner = ""

		system_response("The stolen experience points are added to your person.")
		system_response("You gain: " .. get_dig .. " / " .. get_build .. ".")

		xp.run_callbacks_after("on_runeslab_steal", pos, pname, original_owner)
	end

	meta:set_string("xp_storage", minetest.serialize(info))
	meta:mark_as_private("xp_storage")
end

minetest.after(0, function()
	signs.register_callback("on_punch_sign", "xp", xp.on_punch_sign)
end)

local function do_particles(pos)
	local p = vector.add(pos, {x=0, y=0, z=0})

	minetest.add_particlespawner({
		amount = 1,
		time = 0.1, -- If 0, spawner lifespan is infinite.
		minpos = {x = p.x - 0.3, y = p.y + 0.1, z = p.z - 0.3 },
		maxpos = {x = p.x + 0.3, y = p.y + 0.2, z = p.z + 0.3 },
		minvel = {x = -0.2, y = 2, z = -0.2},
		maxvel = {x = 0.2, y = 3, z = 0.2},
		minacc = {x = -0.15, y = -10, z = -0.15},
		maxacc = {x = 0.15, y = -10, z = 0.15},
		minexptime = 0.5,
		maxexptime = 0.8,
		minsize = 1.5,
		maxsize = 2.0,
		collisiondetection = true,
		texture = "default_gold_lump.png",
		glow = 5,
	})
end

local function do_proximity_notify(pos, except_pname)
	for _, pref in ipairs(minetest.get_connected_players()) do
		local pname = pref:get_player_name()
		if pname ~= except_pname then
			local pos2 = pref:get_pos()
			if vector.distance(pos, pos2) < IMBUE_PROXIMITY_DISTANCE then
				chat_send(pname, "xp1", "You feel electricity in the air as experience points are transferred.")
			end
		end
	end
end

xp.register_callback("on_runeslab_imbue", "xp", function(pos, pname)
	do_particles(pos)
	do_proximity_notify(pos, pname)
end)

xp.register_callback("on_runeslab_retrieve", "xp", function(pos, pname)
	do_particles(pos)
	do_proximity_notify(pos, pname)
end)

xp.register_callback("on_runeslab_steal", "xp", function(pos, pname, original_owner)
	do_particles(pos)
	do_proximity_notify(pos, pname)

	local pref_owner = minetest.get_player_by_name(original_owner)
	if not pref_owner then return end

	chat_send(original_owner, "xp2", "You feel as though someone is robbing your life essence!")
end)
