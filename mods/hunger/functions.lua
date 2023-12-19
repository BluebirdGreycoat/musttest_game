
-- Localize for performance.
local vector_round = vector.round
local math_floor = math.floor
local math_min = math.min



function hunger.on_joinplayer(player)
	local inv = player:get_inventory()
	inv:set_size("hunger", 1)

	local name = player:get_player_name()
	hunger.players[name] = {}
	hunger.players[name].lvl = hunger.read(player)
	hunger.players[name].exhaus = 0
	local lvl = hunger.players[name].lvl
	if lvl > 30 then
		lvl = 30
	end

	minetest.after(0.8, function()
		hud.change_item(player, "hunger", {number = lvl, max = HUNGER_MAX})
	end)
end



function hunger.on_respawnplayer(player)
	hunger.update_hunger(player, 20)
	return true
end



function hunger.on_leaveplayer(player, timeout)
	local pname = player:get_player_name()
	hunger.players[pname] = nil
end



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
	local data = hunger.players[pname]
	if not data then
		return 0
	end
	return data.lvl
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
  
	hud.change_item(player, "hunger", {number = lvl, max = HUNGER_MAX})
	hunger.save(player)
end
local update_hunger = hunger.update_hunger



local function get_dig_exhaustion(player)
	-- Note: this code will skip obtaining the 'hand' tool capabilities whenever
	-- the player is wielding a non-tool, but since the hand doesn't have a dig
	-- exhaustion modifier anyway, that's OK.
	local tool = player:get_wielded_item()
	local tdef = tool:get_definition()
	local tcap = tdef.tool_capabilities
	if tcap and tcap.dig_exhaustion_modifier then
		--minetest.log("Exhaustion modifier: " .. tcap.dig_exhaustion_modifier)
		return (HUNGER_EXHAUST_DIG * tcap.dig_exhaustion_modifier)
	end
	return HUNGER_EXHAUST_DIG
end



function hunger.handle_action_event(player, new)
	local pname = player:get_player_name()
	if not hunger.players[pname] then
		return
	end

	local exhaus = hunger.players[pname].exhaus
	if not exhaus then
		hunger.players[pname].exhaus = 0
	end

	-- Player doesn't get exhausted as quickly if fit and in good health.
	local max_hp = player:get_properties().hp_max
	if player:get_hp() >= (max_hp * 0.9) then
		new = math_floor(new / 2.0)
	end
	exhaus = exhaus + new

	if exhaus > HUNGER_EXHAUST_LVL then
		exhaus = 0
		local h = tonumber(hunger.players[pname].lvl)

		if h > 0 then
			-- Player gets hungrier faster when away from their support base.
			local loss = -1
			local owner = protector.get_node_owner(vector_round(player:get_pos())) or ""
			if owner ~= pname then
				loss = -2
			end
			update_hunger(player, h + loss)
		end
	end

	hunger.players[pname].exhaus = exhaus
end



-- Dignode event.
function hunger.on_dignode(pos, oldnode, player)
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pinfo = hunger.players[pname]

	-- Enforce rate limit of once per second, as otherwise this would trigger many
	-- many times for certain actions, like digging papyrus or scaffolding. This
	-- bug was, I think, actually present in the original old code, but harder to
	-- notice because the effect was not immediately apparent.
	if os.time() > (pinfo.dig_time or 0) then
		pinfo.dig_time = os.time()

		-- Use drawtype to guess how costly this node should be to dig.
		-- Just need a quick approximation.
		local cost = -2
		local ndef = minetest.registered_nodes[oldnode.name]
		if ndef then
			local dt = ndef.drawtype or ""
			if dt == "normal" then
				cost = -3

				-- Special: anything that could be an ore should be a little bit harder.
				local nn = oldnode.name
				if nn:find("ore") or nn:find("_with_") or nn:find("mineral") then
					cost = -5
				end
			elseif dt == "torchlike" or dt == "signlike" or dt == "plantlike"
					or dt == "firelike" or dt == "nodebox" or dt == "mesh" then
				cost = -1
			elseif dt == "airlike" then
				cost = 0
			end
		end

		-- The amount of exhaustion added is based the percentage of stamina.
		local maxsta = SPRINT_STAMINA
		local cursta = sprint.get_stamina(player)
		local pccsta = (cursta / maxsta)
		local invsta = (1.0 - pccsta)

		sprint.add_stamina(player, cost)

		local new = get_dig_exhaustion(player) * invsta
		hunger.handle_action_event(player, new)
	end
end



-- Placenode event.
function hunger.on_placenode(pos, newnode, player, oldnode)
	if not player or not player:is_player() then
		return
	end

	local pname = player:get_player_name()
	local pinfo = hunger.players[pname]

	-- Enforce rate limit of once per second, as otherwise this would trigger many
	-- many times for certain actions, like digging papyrus or scaffolding. This
	-- bug was, I think, actually present in the original old code, but harder to
	-- notice because the effect was not immediately apparent.
	if os.time() > (pinfo.place_time or 0) then
		pinfo.place_time = os.time()

		-- The amount of exhaustion added is based the percentage of stamina.
		local maxsta = SPRINT_STAMINA
		local cursta = sprint.get_stamina(player)
		local pccsta = (cursta / maxsta)
		local invsta = (1.0 - pccsta)

		sprint.add_stamina(player, -1)

		local new = HUNGER_EXHAUST_PLACE * invsta
		hunger.handle_action_event(player, new)
	end
end



-- Player moving event.
function hunger.on_move(player)
	if not player or not player:is_player() then
		return
	end

	local name = player:get_player_name()
	local new = HUNGER_EXHAUST_MOVE

	local speed = pova.get_active_modifier(player, "physics").speed

	-- If player is walking through tough material, they get exhausted faster.
	if speed < default.NORM_SPEED then
		--minetest.chat_send_all(name .. " hungers faster b/c of slow movement!")
		new = HUNGER_EXHAUST_MOVE * 4
	end

	hunger.handle_action_event(player, new)
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
		local max_hp = player:get_properties().hp_max
		if player:get_hp() >= (max_hp * 0.9) then
			amount = math_floor(amount / 3.0)
		end
		hunger.players[pname].exhaus = hunger.players[pname].exhaus + amount
	end
end



-- Time based hunger functions
local hunger_timer = 0
local health_timer = 0
local action_timer = 0

function hunger.on_globalstep(dtime)
	hunger_timer = hunger_timer + dtime
	health_timer = health_timer + dtime
	action_timer = action_timer + dtime

	if action_timer > HUNGER_MOVE_TICK then
		for _,player in ipairs(minetest.get_connected_players()) do
			local controls = player:get_player_control()
			-- Determine if the player is walking
			if (controls.up or controls.down or controls.left or controls.right) then
				hunger.on_move(player)
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
				if hunger > 0 then
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
				local hp_max = player:get_properties().hp_max

				local healmod = (hp / hp_max)
				healmod = healmod * healmod * hunger.get_hpgen_boost(name)

				-- Treat these as percentages.
				local hp_heal = math.floor(HUNGER_HEAL * hp_max) * healmod
				local hp_stav = math.floor(HUNGER_STARVE * hp_max)

				--minetest.log('heal: ' .. hp_heal)

				-- heal player
				if tonumber(tab.lvl) > HUNGER_HEAL_LVL and hp > 0 and air > 0 then
					if hp < hp_max then
						local new_hp = hp + hp_heal
						player:set_hp(new_hp)
					end
				end

				-- or damage player
				if tonumber(tab.lvl) < HUNGER_STARVE_LVL then
					-- but don't kill player
					if hp > hp_stav then
						player:set_hp(hp - hp_stav, {reason="hunger"})
					end
				end
			end
		end

		health_timer = 0
	end
end



-- food functions
function hunger.register_food(name, hunger_change, replace_with_item, poisen, heal, sound)
	local food = hunger.food
	food[name] = {}
	food[name].saturation = hunger_change  -- hunger points added
	food[name].replace = replace_with_item -- what item is given back after eating
	food[name].poisen = poisen             -- time its poisening
	food[name].healing = heal              -- amount of HP
	food[name].sound = sound               -- special sound that is played when eating
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
		min = 1*100,
		max = 1*500,
		poison = true,
	}
	data.msg = "# Server: <" .. rename.gpn(name) .. "> was poisoned!"

	if gorged then
		local sex = skins.get_gender_strings(name)
		data.msg = "# Server: <" .. rename.gpn(name) .. "> gorged " .. sex.himself .. " to death."

		-- Overeating will not damage player below 2 hp!
		data.hp_min = 2
	end

	hb4.delayed_harm2(data)
end



-- wrapper for minetest.item_eat (this way we make sure other mods can't break this one)
function hunger.do_item_eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	local old_itemstack = itemstack
	itemstack = hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)

	-- Don't call item_eat callbacks unless item was actually eaten.
	if itemstack and itemstack:get_count() == old_itemstack:get_count() then
		return itemstack
	end

	for _, callback in ipairs(core.registered_on_item_eats) do
		local result = callback(hp_change, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
		if result then
			return result
		end
	end

	return itemstack
end



function hunger.eat(hp_change, replace_with_item, itemstack, user, pointed_thing)
	local item = itemstack:get_name()
	local def = hunger.food[item]

	-- In case food isn't defined at this time.
	if not def then
		def = {}
		if type(hp_change) ~= "number" then
			hp_change = 1
			core.log("error", "Wrong on_use() definition for item '" .. item .. "'")
		end
		def.saturation = hp_change * 1.3
		def.replace = replace_with_item
	end

	def = hunger.adjust_from_diet(user:get_player_name(), item, def)

	local func = hunger.item_eat(def.saturation, def.replace, def.poisen, def.healing, def.sound)
	return func(itemstack, user, pointed_thing)
end



-- Note: due to the way this function works, changes to it require a server
-- restart; reloading the hunger mod WILL NOT work!
function hunger.item_eat2(hunger_change, replace_with_item, poisen, heal, sound)
	-- Returns 'on_use' callback closure.
	return function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return end

		local name = user:get_player_name()
		if not hunger.players[name] then
			return itemstack
		end
		local sat = tonumber(hunger.players[name].lvl or 0)

		-- If food would put our saturation over the max, then behave as if poisoned instead.
		local gorged = false
		if sat >= HUNGER_MAX then
			gorged = true
			heal = nil
			if not poisen then
				poisen = 3 -- 3 seconds?
			end
		end

		-- Remove food from itemstack only if eating was successful.
		local result = itemstack:take_item()
		if not result or result:get_count() == 0 then return end

		local hp = user:get_hp()
		local hp_max = user:get_properties().hp_max

		-- Saturation
		if sat < HUNGER_MAX and hunger_change then
			sat = sat + hunger_change
			hunger.update_hunger(user, sat)
		end

		-- Healing (or damage!)
		if hp <= hp_max and heal then
			-- Warning: this might kill the player, causing other code to do
			-- who-knows-what to the player inventory. Consequently this must be
			-- executed out-of-band.
			minetest.after(0, function()
				local user = minetest.get_player_by_name(name)
				if user then
					local hp = user:get_hp()
					local newhp = hp + heal

					if newhp > hp_max then newhp = hp_max end
					if newhp < 0 then newhp = 0 end

					user:set_hp(newhp, {reason="hunger"})
				end
			end)
		end

		-- Poison
		if poisen then
			if gorged then
				minetest.chat_send_player(name, "# Server: You have eaten too much!")
			end
			poisenp(1.0, poisen, 0, user, gorged)
		end

		-- eating sound
		if not sound then
			sound = "hunger_eat"
		end

		ambiance.sound_play(sound, user:get_pos(), 0.7, 10)
		ambiance.particles_eat_item(user, itemstack:get_name())

		if replace_with_item then
			if itemstack:is_empty() then
				itemstack:add_item(replace_with_item)
			else
				local inv = user:get_inventory()
				if inv:room_for_item("main", {name=replace_with_item}) then
					inv:add_item("main", replace_with_item)
				else
					local pos = user:get_pos()
					pos.y = math_floor(pos.y + 0.5)
					core.add_item(pos, replace_with_item)
				end
			end
		end

		return itemstack
	end -- End of function.
end



function hunger.on_dieplayer(player)
	local pname = player:get_player_name()

	local tab = hunger.players[pname]
	if not tab then
		return
	end

	-- Set timers on all active effects to 0.
	local timers = {}

	-- Collect timers.
	for k, v in pairs(tab) do
		if k:find("^effect_time_") then
			timers[#timers + 1] = k
		end
	end

	-- Zero timers.
	for k, v in ipairs(timers) do
		tab[v] = 0
	end
end



