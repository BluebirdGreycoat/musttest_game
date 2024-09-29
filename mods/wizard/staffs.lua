
minetest.register_tool("wizard:banish_staff", {
	description = "Banishing Staff",
	inventory_image = "stoneworld_oerkki_staff_2.png",

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

minetest.register_tool("wizard:tracking_staff", {
	description = "Tracking Prop",
	inventory_image = "stoneworld_oerkki_staff_2.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = function(...) return wizard.track_staff(...) end,
	on_secondary_use = function(...) return wizard.track_staff(...) end,

	-- Damage info is stored by sysdmg.
	tool_capabilities = {
		full_punch_interval = 3.0,
	},

	groups = {not_repaired_by_anvil = 1, disable_repair = 1},
})

minetest.register_tool("wizard:gagging_staff", {
	description = "Muzzling Stave",
	inventory_image = "stoneworld_oerkki_staff_2.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = function(...) return wizard.gag_staff(...) end,
	on_secondary_use = function(...) return wizard.gag_staff(...) end,

	-- Damage info is stored by sysdmg.
	tool_capabilities = {
		full_punch_interval = 3.0,
	},

	groups = {not_repaired_by_anvil = 1, disable_repair = 1},
})

minetest.register_tool("wizard:punish_staff", {
	description = "Punishing Cane",
	inventory_image = "stoneworld_oerkki_staff_2.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = function(...) return wizard.punish_staff(...) end,
	on_secondary_use = function(...) return wizard.punish_staff(...) end,

	-- Damage info is stored by sysdmg.
	tool_capabilities = {
		full_punch_interval = 3.0,
	},

	groups = {not_repaired_by_anvil = 1, disable_repair = 1},
})

minetest.register_tool("wizard:summon_staff", {
	description = "Summoning Wand",
	inventory_image = "stoneworld_oerkki_staff_2.png",

	-- Tools with dual-use functions MUST put the secondary use in this callback,
	-- otherwise normal punches do not work!
	on_place = function(...) return wizard.summon_staff(...) end,
	on_secondary_use = function(...) return wizard.summon_staff(...) end,

	-- Damage info is stored by sysdmg.
	tool_capabilities = {
		full_punch_interval = 3.0,
	},

	groups = {not_repaired_by_anvil = 1, disable_repair = 1},
})
