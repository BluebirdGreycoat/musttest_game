
function wizard.summon_staff(itemstack, user, pt)
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
	local target_name = meta:get_string("text"):trim()
	local author = meta:get_string("author")

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

	-- Range limit.
	if vector.distance(user:get_pos(), ptarget:get_pos()) > 500 then
		meta:set_string("infotext", "TOO FAR")
		return
	end

	local playerpos = vector.round(user:get_pos())
	local minp = vector.add(playerpos, {x=-5, y=-5, z=-5})
	local maxp = vector.add(playerpos, {x=5, y=5, z=5})
	local floors = minetest.find_nodes_in_area_under_air(minp, maxp, "griefer:grieferstone")
	if #floors == 0 then
		meta:set_string("infotext", "NO SUMMON STONE")
		return
	end
	local tpos = vector.add(floors[math.random(1, #floors)], {x=0, y=1, z=0})

	meta:set_string("author", "")
	meta:set_string("text", "")
	meta:set_string("infotext", "OBEYING")
	wizard.runeslab_particles(pt.under)

	-- Leave stack frame, first.
	local ntarget = ptarget:get_player_name()
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(ntarget)
		if pref and pref:get_hp() > 0 then
			preload_tp.execute({
				player_name = ntarget,
				target_position = tpos,
				emerge_radius = 32,
				force_teleport = true,
				send_blocks = true,
				particle_effects = true,
			})
		end
	end)

	-- Take 50 hp of health from the wizard.
	wizard.damage_player(pname, 50)
	xp.subtract_xp(pname, "digxp", 500)
end
