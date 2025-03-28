
function wizard.track_staff(itemstack, user, pt)
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

	-- Don't need to check if target is in the same realm.

	meta:set_string("author", "")
	meta:set_string("text", "")
	meta:set_string("infotext", "OBEYING")
	wizard.runeslab_particles(pt.under)

	local range = 100
	local duration = 300
	ac.show_path(pname, target_name, user:get_pos(), range, duration)

	-- Take 5 hp of health from the wizard.
	wizard.damage_player(pname, 5)
	xp.subtract_xp(pname, "digxp", 10)
end
