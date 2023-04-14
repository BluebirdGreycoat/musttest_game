
-- Localize for performance.
local math_floor = math.floor



local armor_org_func = armor.set_player_armor

local function get_armor_lvl(def)
	-- Displays percentage of current wear.
	local state = def.state or 0
	local count = def.count or 0
	local total = count * 65535

	-- D'T div by 0.
	if count == 0 then return 0 end

	local percent = state / total
	local invperc = 1 - percent

	if invperc > 1 then invperc = 1 end
	if invperc < 0 then invperc = 0 end

	return math_floor(tonumber(20 * (invperc)))
end

function armor.set_player_armor(self, player)
	armor_org_func(self, player)
	local name = player:get_player_name()
	local def = self.def
	local armor_lvl = 0
	if def[name] then
		armor_lvl = get_armor_lvl(def[name])
	end
	hud.change_item(player, "armor", {number = armor_lvl, max = 20})
end
