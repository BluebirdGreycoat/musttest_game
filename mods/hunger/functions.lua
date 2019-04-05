-- read/write
function hunger.read(player)
	local inv = player:get_inventory()
	if not inv then
		return nil
	end
	local hgp = inv:get_stack("hunger", 1):get_count()
	if hgp == 0 then
		hgp = 21
		inv:set_stack("hunger", 1, ItemStack({name = ":", count = hgp}))
	else
		hgp = hgp
	end
	if tonumber(hgp) > HUNGER_MAX + 1 then
		hgp = HUNGER_MAX + 1
	end
	return hgp - 1
end

function hunger.save(player)
	local inv = player:get_inventory()
	local name = player:get_player_name()
	local value = hunger.players[name].lvl
	if not inv or not value then
		return nil
	end
	if value > HUNGER_MAX then
		value = HUNGER_MAX
	end
	if value < 0 then
		value = 0
	end
	inv:set_stack("hunger", 1, ItemStack({name = ":", count = value + 1}))
	return true
end

function hunger.get_hunger(player)
	local pname = player:get_player_name()
	local lvl = hunger.players[pname].lvl
	return lvl
end

function hunger.update_hunger(player, new_lvl)
	local name = player:get_player_name() or nil
	if not name then
		return false
	end
  
	local lvl = hunger.players[name].lvl
	if new_lvl then
		 lvl = new_lvl
	end
  
  -- Clamp hunger value within range.
  if lvl > HUNGER_MAX then lvl = HUNGER_MAX end
  if lvl < 0 then lvl = 0 end
  
	hunger.players[name].lvl = lvl
	if lvl > 20 then
		lvl = 20
	end
  
	hud.change_item(player, "hunger", {number = lvl})
	hunger.save(player)
end
local update_hunger = hunger.update_hunger


-- Function added by MustTest. Hunger only happens outside the city, where players are on their own.
local function distance(player)
	local p = player:getpos()
	local d = math.sqrt((p.x*p.x)+(p.y*p.y)+(p.z*p.z))
	local r = 200 -- Radius of city
	local o = d-r
	if o < 0 then o = 0 end
	return o -- Number of meters player is outside the city radius.
end

local function get_dig_exhaustion(player)
	return HUNGER_EXHAUST_DIG
end

-- player-action based hunger changes
function hunger.handle_node_actions(pos, oldnode, player, ext)
	if not player or not player:is_player() then
		return
	end
	local name = player:get_player_name()
	if not hunger.players[name] then
		return
	end

	local exhaus = hunger.players[name].exhaus
	if not exhaus then
		hunger.players[name].exhaus = 0
		--return
	end

	local new = HUNGER_EXHAUST_PLACE

	-- placenode event
	if not ext then
		new = get_dig_exhaustion(player)
	end

	-- assume its send by action_timer(globalstep)
	if not pos and not oldnode then
		new = HUNGER_EXHAUST_MOVE
		-- If player is walking through tough material, they get exhausted faster.
		if sprint.get_speed_multiplier(name) < default.NORM_SPEED then
			--minetest.chat_send_all(name .. " hungers faster b/c of slow movement!")
			new = HUNGER_EXHAUST_MOVE * 4
		end
	end

	-- Player doesn't get exhausted as quickly if fit and in good health.
	if player:get_hp() >= 18 then
		new = math.floor(new / 3.0)
	end
	exhaus = exhaus + new

	if exhaus > HUNGER_EXHAUST_LVL then
		exhaus = 0
		local h = tonumber(hunger.players[name].lvl)
		if h > 0 and distance(player) > 0 then
			-- Player gets hungrier faster when away from their support base.
			local loss = -1
			local owner = protector.get_node_owner(vector.round(player:get_pos())) or ""
			if owner ~= name then
				loss = -2
			end
			update_hunger(player, h + loss)
		end
	end

	hunger.players[name].exhaus = exhaus
end



-- API function to increase a player's hunger. Called from other mods.
function hunger.increase_hunger(player, amount)
  local pname = player:get_player_name()
  if hunger.players[pname] then
    local h = tonumber(hunger.players[pname].lvl)
    hunger.update_hunger(player, h - amount)
  end
end



function hunger.increase_exhaustion(player, amount)
	local pname = player:get_player_name()
	if hunger.players[pname] then
		if not hunger.players[pname].exhaus then
			hunger.players[pname].exhaus = 0
		end
		-- Player doesn't get exhausted as quickly if fit and in good health.
		if player:get_hp() >= 18 then
			amount = math.floor(amount / 3.0)
		end
		hunger.players[pname].exhaus = hunger.players[pname].exhaus + amount
	end
end



-- Time based hunger functions
local hunger_timer = 0
local health_timer = 0
local action_timer = 0

local function hunger_globaltimer(dtime)
	hunger_timer = hunger_timer + dtime
	health_timer = health_timer + dtime
	action_timer = action_timer + dtime

	if action_timer > HUNGER_MOVE_TICK then
		for _,player in ipairs(minetest.get_connected_players()) do
			local controls = player:get_player_control()
			-- Determine if the player is walking
			if (controls.up or controls.down or controls.left or controls.right) and distance(player) > 0 then
				hunger.handle_node_actions(nil, nil, player)
			end
		end
		action_timer = 0
	end

	-- lower saturation by 1 point after <HUNGER_TICK> second(s)
	if hunger_timer > HUNGER_TICK then
		for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local tab = hunger.players[name]
			if tab then
				local hunger = tab.lvl
				if hunger > 0 and distance(player) > 0 then
					update_hunger(player, hunger - 1)
				end
			end
		end
		hunger_timer = 0
	end

	-- heal or damage player, depending on saturation
	if health_timer > HUNGER_HEALTH_TICK then
		for _,player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local tab = hunger.players[name]
			if tab then
				local air = player:get_breath() or 0
				local hp = player:get_hp()

				-- heal player by 1 hp if not dead and saturation is > 15 (of 30) player is not drowning
				if tonumber(tab.lvl) > HUNGER_HEAL_LVL and hp > 0 and air > 0 then
					if player:get_hp() < 16 then -- Food doesn't heal players past 16 hp. Use bandages for that.
						player:set_hp(hp + HUNGER_HEAL)
					end
				end

				-- or damage player by 1 hp if saturation is < 2 (of 30)
				if tonumber(tab.lvl) < HUNGER_STARVE_LVL then
					if player:get_hp() > 2 then -- Hunger doesn't kill players. Mobs do. By MustTest.
						player:set_hp(hp - HUNGER_STARVE)
					end
				end
			end
		end

		health_timer = 0
	end
end

if minetest.setting_getbool("enable_damage") then
	minetest.register_globalstep(hunger_globaltimer)
end


-- food functions
local food = hunger.food

function hunger.register_food(name, hunger_change, replace_with_item, poisen, heal, sound)
	food[name] = {}
	food[name].saturation = hunger_change	-- hunger points added
	food[name].replace = replace_with_item	-- what item is given back after eating
	food[name].poisen = poisen				-- time its poisening
	food[name].healing = heal				-- amount of HP
	food[name].sound = sound				-- special sound that is played when eating
end

-- Poison player
local function poisenp(tick, time, time_left, player, gorged)
	--[[
		{name="player", step=2, min=1, max=3, msg="He died!", poison=true}
	--]]
	local name = player:get_player_name()
	local data = {
		name = name,
		step = time,
		min = 1,
		max = 1,
		poison = true,
	}
	data.msg = "# Server: <" .. rename.gpn(name) .. "> was poisoned!"
	if gorged then
		local sex = skins.get_gender_strings(name)
		data.msg = "# Server: <" .. rename.gpn(name) .. "> gorged " .. sex.himself .. " to death."
	end
	hb4.delayed_harm2(data)
end

-- wrapper for minetest.item_eat (this way we make sure other mods can't break this one)
local org_eat = core.do_item_eat
core.do_item_eat = function(hp_change, replace_with_item, itemstack, user, pointed_thing)
	local old_itemstack = itemstack
	itemstack = hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)

	-- Don't call item_eat callbacks unless item was actually eaten.
	if itemstack and itemstack:get_count() == old_itemstack:get_count() then
		return itemstack
	end

	for _, callback in pairs(core.registered_on_item_eats) do
		local result = callback(hp_change, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
		if result then
			return result
		end
	end
	return itemstack
end

function hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	local item = itemstack:get_name()
	local def = food[item]
	if not def then
		def = {}
		if type(hp_change) ~= "number" then
			hp_change = 1
			core.log("error", "Wrong on_use() definition for item '" .. item .. "'")
		end
		def.saturation = hp_change * 1.3
		def.replace = replace_with_item
	end
	local func = hunger.item_eat(def.saturation, def.replace, def.poisen, def.healing, def.sound)
	return func(itemstack, user, pointed_thing)
end

function hunger.item_eat(hunger_change, replace_with_item, poisen, heal, sound)
	return function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end

		local name = user:get_player_name()
		if not hunger.players[name] then
			return itemstack
		end
		local sat = tonumber(hunger.players[name].lvl or 0)

		-- If food would put our saturation over the max, then behave as if poisoned instead.
		local gorged = false
		if sat + hunger_change > HUNGER_MAX then
			gorged = true
			heal = nil
			poisen = 3 -- 3 seconds?
		end

		-- Remove food from itemstack only if eating was successful.
		local result = itemstack:take_item()
		if not result or result:get_count() == 0 then return end

		local hp = user:get_hp()
		-- Saturation
		if sat < HUNGER_MAX and hunger_change then
			sat = sat + hunger_change
			hunger.update_hunger(user, sat)
		end
		-- Healing
		if hp < 20 and heal then
			hp = hp + heal
			if hp > 20 then
				hp = 20
			end
			user:set_hp(hp)
		end
		-- Poison
		if poisen then
			if gorged then
				minetest.chat_send_player(name, "# Server: You have eaten too much!")
			end
			--hud.change_item(user, "hunger", {text = "hunger_statbar_poisen.png"})
			poisenp(1.0, poisen, 0, user, gorged)
		end

		-- eating sound
		if not sound then
			sound = "hunger_eat"
		end
		--minetest.sound_play(sound, {to_player = name, gain = 0.7})
		ambiance.sound_play(sound, user:getpos(), 0.7, 10)
		ambiance.particles_eat_item(user, itemstack:get_name())

		if replace_with_item then
			if itemstack:is_empty() then
				itemstack:add_item(replace_with_item)
			else
				local inv = user:get_inventory()
				if inv:room_for_item("main", {name=replace_with_item}) then
					inv:add_item("main", replace_with_item)
				else
					local pos = user:getpos()
					pos.y = math.floor(pos.y + 0.5)
					core.add_item(pos, replace_with_item)
				end
			end
		end

		return itemstack
	end -- End of function.
end


