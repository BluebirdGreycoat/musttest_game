
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
		return
	end

	local target_name = (tokens[2] or tokens[1]):trim()

	-- Staff user must be sign author.
	if author ~= pname then
		return
	end

	local ptarget = minetest.get_player_by_name(target_name)
	if not ptarget or not ptarget:is_player() then
		return
	end

	-- 10% for the Big Guy.
	if minetest.check_player_privs(ptarget, {server=true}) then
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
		return
	end

	-- Perform kick action AFTER returning from the current stack frame.
	-- User might kick self.
	local ntarget = ptarget:get_player_name()
	minetest.after(0, function()
		minetest.kick_player(ntarget, "Momentarily banished.")
	end)

	-- Take 15 hp of health from the wizard.
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(pname)
		if pref then
			utility.damage_player(pref, "fleshy", 15 * 500)
		end
	end)
end
