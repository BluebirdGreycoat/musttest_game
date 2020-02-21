
HUD_IW_MAX = 8
HUD_IW_TICK = 0.5
HUD_SB_SIZE = {x=16, y=16}

local width = 16*10
local gap = 16*1.5

HUD_HEALTH_POS = {x = 0.5,y = 1}
HUD_HEALTH_OFFSET = {x = -width + -gap, y = -107}
HUD_AIR_POS = {x = 0.5, y = 1}
HUD_AIR_OFFSET = {x = gap, y = -127}
HUD_HUNGER_POS = {x = 0.5, y = 1}
HUD_HUNGER_OFFSET = {x = gap, y = -107}
HUD_ARMOR_POS = {x = 0.5, y = 1}
HUD_ARMOR_OFFSET = {x = -width + -gap, y = -127}

hud.register("health", {
	hud_elem_type = "statbar",
	position = HUD_HEALTH_POS,
	size = HUD_SB_SIZE,
	text = "hud_heart_fg.png",
	number = 20,
	alignment = {x = -1, y = -1},
	offset = HUD_HEALTH_OFFSET,
	background = "hud_heart_bg.png",
	events = {
		{
			type = "damage",
			func = function(player)
				local props = player:get_properties()
				hud.change_item(player, "health", {number = player:get_hp(), max = props.hp_max})
			end,
		},
	},
	max = 20,
})

hud.register("air", {
	hud_elem_type = "statbar",
	position = HUD_AIR_POS,
	size = HUD_SB_SIZE,
	text = "hud_air_fg.png",
	number = 0,
	alignment = {x = -1, y = -1},
	offset = HUD_AIR_OFFSET,
	background = "bubble_bg.png",
	events = {
		{
			type = "breath",
			func = function(player)
				local air = player:get_breath()
				local props = player:get_properties()
				hud.change_item(player, "air", {number = air, max = props.breath_max})
			end,
		},
	},
	max = 20,
})

hud.register("armor", {
	hud_elem_type = "statbar",
	position = HUD_ARMOR_POS,
	size = HUD_SB_SIZE,
	text = "hud_armor_fg.png",
	number = 0,
	alignment = {x = -1, y = -1},
	offset = HUD_ARMOR_OFFSET,
	background = "hud_armor_bg.png",
	max = 20,
})

hud.register("hunger", {
	hud_elem_type = "statbar",
	position = HUD_HUNGER_POS,
	size = HUD_SB_SIZE,
	text = "hud_hunger_fg.png",
	number = 0,
	alignment = {x = -1, y = -1},
	offset = HUD_HUNGER_OFFSET,
	background = "hud_hunger_bg.png",
	max = 20,
})
