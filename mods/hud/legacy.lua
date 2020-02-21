
local armor_org_func = armor.set_player_armor

local function get_armor_lvl(def)
	-- items/protection based display
	local lvl = def.level or 0
	local max = 51.975 -- full mithril armor + mithril shield
	-- TODO: is there a sane way to read out max values?
	local ret = lvl / max
	if ret > 1 then
		ret = 1
	end

	return math.floor(tonumber(20 * (ret)))
end

function armor.set_player_armor(self, player)
	armor_org_func(self, player)
	local name = player:get_player_name()
	local def = self.def
	local armor_lvl = 0
	if def[name] and def[name].level then
		armor_lvl = get_armor_lvl(def[name])
	end
	hud.change_item(player, "armor", {number = armor_lvl})
end
