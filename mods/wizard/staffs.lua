
minetest.register_tool("wizard:banish_staff", {
	description = "Banishing Staff",
	inventory_image = "stoneworld_oerkki_staff.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = function(...) return wizard.banish_staff(...) end,
	on_secondary_use = function(...) return wizard.banish_staff(...) end,

	-- Damage info is stored by sysdmg.
	tool_capabilities = {
		full_punch_interval = 3.0,
	},

	groups = {not_repaired_by_anvil = 1, disable_repair = 1},
})
