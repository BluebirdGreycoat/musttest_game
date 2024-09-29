
function wizard.banish_staff(itemstack, user, pt)
  if not user or not user:is_player() then
		return
	end

	if pt.type ~= "node" then
		return
	end

	local node = minetest.get_node(pt.under)
	local nodename = node.name

	-- Must be a rune slab.
	if nodename ~= "signs:sign_wall_stone" then
		return
	end

	local pname = user:get_player_name()
	local meta = minetest.get_meta(pt.under)
	local text = meta:get_string("text"):trim()
	local author = meta:get_string("author")

	local tokens = text:split(":")
	if #tokens == 0 or #tokens > 2 then
		meta:set_string("infotext", "CAN'T READ")
		return
	end

	local target_name = (tokens[2] or tokens[1]):trim()

	-- Staff user must be sign author.
	if author ~= pname then
		meta:set_string("infotext", "NO AUTH")
		return
	end

	-- 10% for the Big Guy.
	if minetest.check_player_privs(target_name, {server=true}) or sheriff.is_cheater(pname) then
		meta:set_string("infotext", "SERVE U RIGHT")

		local pos = user:get_pos()
		minetest.after(0, function()
			tnt.boom(pos, {
				radius = 5,
				ignore_protection = false,
				ignore_on_blast = false,
				damage_radius = 5,
				disable_drops = true,
			})
		end)

		itemstack:take_item()
		return itemstack
	end

	local ptarget = minetest.get_player_by_name(target_name)
	if not ptarget or not ptarget:is_player() then
		meta:set_string("infotext", "CAN'T FIND")
		return
	end

	if not rc.same_realm(user:get_pos(), ptarget:get_pos()) then
		meta:set_string("infotext", "OTHER DIMENSION")
		return
	end

	-- Staff user can specify an origin other than himself.
	-- The wizard may use a minion to extend his power.
	local origin = user:get_pos()
	if tokens[1] and tokens[2] then
		local origin_name = tokens[1]:trim()
		if origin_name ~= target_name then
			local origin_ref = minetest.get_player_by_name(origin_name)
			if origin_ref then
				origin = origin_ref:get_pos()
			end
		end
	end

	-- Range limit.
	if vector.distance(origin, ptarget:get_pos()) > 100 then
		meta:set_string("infotext", "TOO FAR")
		return
	end

	meta:set_string("author", "")
	meta:set_string("text", "")
	meta:set_string("infotext", "OBEYING")
	wizard.runeslab_particles(pt.under)

	-- Perform kick action AFTER returning from the current stack frame.
	-- User might kick self. Don't kick dead players.
	local ntarget = ptarget:get_player_name()
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(ntarget)
		if pref and pref:get_hp() > 0 then
			minetest.kick_player(ntarget, "Momentarily banished.")
		end
	end)

	-- Take 15 hp of health from the wizard.
	wizard.damage_player(pname, 15)
	xp.subtract_xp(pname, "digxp", 1000)
end
