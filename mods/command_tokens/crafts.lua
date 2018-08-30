
-- Used to mute a player who spams.
minetest.register_craftitem("command_tokens:mute_player", {
	description = "Gag Order\n\nUse this on someone who ruins chat for people.\nTarget will not be able to speak for some time.",
	inventory_image = "default_diamond_block.png",
	on_use = function(...) return command_tokens.mute.mute_player(...) end,
})

minetest.register_craft({
	output = 'command_tokens:mute_player 1',
	recipe = {
		{'default:diamond'},
	},
})


-- Use this to show someone's coordinates when they speak.
minetest.register_craftitem("command_tokens:mark_player", {
	description = "Bounty Marker\n\nUse this to show a person's coordinates when they speak.",
	inventory_image = "default_gold_block.png",
	on_use = function(...) return command_tokens.mark.mark_player(...) end,
})

minetest.register_craft({
	output = 'command_tokens:mark_player',
	type = 'shapeless',
	recipe = {
		'default:gold_ingot',
		'default:gold_ingot',
	},
})



-- Use this to kick someone into jail, if they are in your area.
minetest.register_craftitem("command_tokens:jail_player", {
	description = "Trespass Restraining Order\n\nUse this to kick someone into jail, if they are in your protected area.\nThey must also be in an area marked as city.\nPerfect for getting rid of annoying people.",
	inventory_image = "default_steel_block.png",
	on_use = function(...) return command_tokens.jail.jail_player(...) end,
})

minetest.register_craft({
  output = 'command_tokens:jail_player',
  recipe = {
    {'',                    'default:steel_ingot', ''                   },
    {'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
    {'',                    'default:steel_ingot', ''                   },
  },
})




