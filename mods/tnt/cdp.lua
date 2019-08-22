
-- Controled Demolition Pack. An explosive for getting rid of locked chests, doors, etc. on unclaimed land.
cdp = cdp or {}
cdp.modpath = minetest.get_modpath("tnt")

function cdp.on_ignite(pos)
	local timer = minetest.get_node_timer(pos)
	if timer:is_started() then
		return
	end

	minetest.sound_play("tnt_ignite", {pos = pos})
	timer:start(5)
end

function cdp.on_timer(pos, elapsed)
	local remove = function(pos)
		if not minetest.test_protection(pos, "") then
			local node = minetest.get_node(pos)
			local ndef = minetest.registered_nodes[node.name]
			if ndef and ndef.on_blast then
				ndef.on_blast(pos, 1.0)
			end

			-- Might have already been removed by the `on_blast` callback,
			-- but just to make sure.
			minetest.remove_node(pos)
		end
	end

	-- Remove nodes adjacent to all 6 sides.
	local targets = {
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y+1, z=pos.z},
		{x=pos.x, y=pos.y-1, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x, y=pos.y, z=pos.z-1},
	}
	for k, v in ipairs(targets) do
		remove(v)
	end

	-- Make sure to remove ourselves.
	minetest.remove_node(pos)

	-- Add an explosion effect with real damage.
	tnt.boom(pos, {
		radius = 3,
		ignore_protection = false,
		ignore_on_blast = false,
		damage_radius = 5,
		disable_drops = true,
	})
end

if not cdp.registered then
	minetest.register_node("tnt:controled_demolition_pack", {
		description = "Controled Low-Yield Demolition Pack\n\nUse to clear rubbish off land (e.g. doors, chests).\nDoes not work in protected zones.\nPlace directly next to rubbish, then ignite.",
		tiles = {"tnt_cdp_top.png", "tnt_cdp_bottom.png", "tnt_cdp_side.png"},
		is_ground_content = false,
		groups = utility.dig_groups("bigitem", {tnt = 1}),
		sounds = default.node_sound_wood_defaults(),

		on_ignite = function(...)
			return cdp.on_ignite(...)
		end,

		on_timer = function(...)
			return cdp.on_timer(...)
		end,
	})

	minetest.register_craft({
		output = "tnt:controled_demolition_pack",
		recipe = {
			{"", "moreores:tin_ingot", ""},
			{"moreores:tin_ingot", "tnt:tnt", "moreores:tin_ingot"},
			{"", "morechests:ironchest_public_closed", ""},
		},
	})

	-- Registered as reloadable in the init.lua file.
	cdp.registered = true
end
