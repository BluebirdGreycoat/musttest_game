
local vround = vector.round

local function update_player_gravity_now(pname, pref)
	local pos = vround(pref:get_pos())
	local phy = rc.get_realm_physics_override(pos)
	if phy then
		-- Merges with existing, creates if needed.
		pova.update_modifier(pref, "physics", phy, "rc_physics", {priority=-1000})
	else
		-- Does nothing if modifier doesn't exist.
		pova.remove_modifier(pref, "physics", "rc_physics")
	end
end

function rc.do_gravity_check(pname)
	local pref = minetest.get_player_by_name(pname)
	if not pref then
		return
	end

	update_player_gravity_now(pname, pref)

	-- Schedule next check.
	minetest.after(1.5, rc.do_gravity_check, pname)
end

function rc.get_realm_physics_override(pos)
	local data = rc.get_realm_data(rc.current_realm_at_pos(pos))
	if data and data.get_physics_override then
		return data.get_physics_override(pos)
	end
end
