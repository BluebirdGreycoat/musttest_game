
-- Localize for performance.
local math_floor = math.floor
local math_random = math.random

armor.elements = armor.elements or {"head", "torso", "legs", "feet"}
armor.physics = armor.physics or {"jump", "speed", "gravity"}
armor.default_skin = "character"
armor.version = "MustTest"

armor.formspec =
	"size[8,8.5]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"button[0,0.5;2,0.5;main;Back]" ..
	"image[4,0.25;2,4;armor_preview]" ..
	"label[6,0.1;Health: hp_max]" ..
	"label[6,0.4;Block: armor_heal]" ..
	"list[current_player;main;0,4.25;8,1;]" ..
	"list[current_player;main;0,5.5;8,3;8]" ..
	default.get_hotbar_bg(0, 4.25)

-- Transient player data storage.
armor.def = armor.def or {}
armor.textures = armor.textures or {}


--------------------------------------------------------------------------------
-- Use this function (just before) you call player:punch(), to notify the armor
-- mod what the reason info for the punch is. Because as of this writing, you
-- can't pass the PlayerHPChangeReason table directly to the :punch() method.
-- Silly Minetest!
function armor.notify_punch_reason(reason)
	armor.hp_change_reason = reason
	armor.hp_change_reason.type = "punch"
end

-- Same as above, but use if you're calling :set_hp() on the player, and need to
-- notify the armor code what the HP change is for. Note that this is especially
-- important if you're changing the players 'hp_max' as well. In such cases, the
-- reason object often DOES NOT propogate through the engine, and thus this has
-- to be done manually and entirely in Lua. Silly Minetest!
function armor.notify_set_hp_reason(reason)
	armor.hp_change_reason = reason
	armor.hp_change_reason.type = "set_hp"
end
--------------------------------------------------------------------------------



-- To be called by armor code only.
function armor.notify_death_reason(reason)
	armor.death_reason = reason
end


-- May return nil. Note: this function also clears the reason data, to ensure it
-- is only used once!
function armor.get_hp_change_reason(engine_reason)
	if armor.hp_change_reason then
		local reason = armor.hp_change_reason
		armor.hp_change_reason = nil

		-- Copy everything from the engine's reason, but don't clobber our special
		-- 'reason' key.
		for k, v in pairs(engine_reason) do
			if k ~= "reason" then
				reason[k] = v
			end
		end

		return reason
	end

	return nil
end



-- To be called in one place only (the bones code) as it clears the reason
-- at the same time.
function armor.get_death_reason(engine_reason)
	if armor.death_reason then
		local reason = armor.death_reason
		armor.death_reason = nil

		-- Copy everything from the engine's reason, but don't clobber our special
		-- 'reason' key.
		for k, v in pairs(engine_reason) do
			if k ~= "reason" then
				reason[k] = v
			end
		end

		return reason
	end

	return nil
end



function armor.update_player_visuals(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	if self.textures[name] then
		default.player_set_textures(player, {
			self.textures[name].skin,
			self.textures[name].armor,
			self.textures[name].wielditem,
		})
	end
end



function armor.set_player_armor(self, player)
	local name, player_inv = armor:get_valid_player(player, "[set_player_armor]")
	if not name then
		return
	end

	local armor_texture = "3d_armor_trans.png"

	-- Armor groups.
	local loc_arm_grps = {}
	local armor_heal = 0

	local state = 0
	local items = 0
	local elements = {}
	local textures = {}
	local physics_o = {speed=1,gravity=1,jump=1}
	local material = {type=nil, count=1}
	local preview_string = armor:get_preview(name) or "character_preview.png"

	-- List of textures to be applied to the character preview.
	local preview_table = {}

	for _,v in ipairs(self.elements) do
		elements[v] = false
	end

	for i = 1, 6 do
		local stack = player_inv:get_stack("armor", i)
		local item = stack:get_name()
		if stack:get_count() == 1 then
			local def = stack:get_definition()
			for k, v in pairs(elements) do
				if v == false then
					local level = def.groups["armor_" .. k]
					if level and level > 0 then
						--minetest.log('armor piece: ' .. k)

						local tex = def.texture or item:gsub("%:", "_")
						textures[#textures+1] = (tex .. ".png")
						preview_table[#preview_table+1] = (tex .. "_preview.png")

						state = state + stack:get_wear()
						items = items + 1
						armor_heal = armor_heal + (def.groups["armor_heal"] or 0)

						-- Local armor groups.
						local lag = def._armor_resist_groups or {}
						for k, v in pairs(lag) do
							--minetest.log('group: ' .. k)
							loc_arm_grps[k] = (loc_arm_grps[k] or 0) + lag[k]
						end

						for kk,vv in ipairs(self.physics) do
							local o_value = def.groups["physics_"..vv]
							if o_value then
								physics_o[vv] = physics_o[vv] + o_value
							end
						end

						local mat = string.match(item, "%:.+_(.+)$")
						if material.type then
							if material.type == mat then
								material.count = material.count + 1
							end
						else
							material.type = mat
						end

						-- Mark this type/peice of armor as handled.
						-- This avoids letting players use duplicate armor peices.
						elements[k] = true
					end
				end
			end
		end
	end

	-- I guess this gives an armor bonus if all armors are the same material?
	-- MustTest.
	if material.type and material.count == #self.elements then
		loc_arm_grps.fleshy = (loc_arm_grps.fleshy or 0) * 1.1
	end

	armor_heal = armor_heal * ARMOR_HEAL_MULTIPLIER

	if #textures > 0 then
		armor_texture = table.concat(textures, "^")
	end

	local armor_groups = {}

	for k, v in pairs(loc_arm_grps) do
		armor_groups[k] = 100 - (loc_arm_grps[k] * ARMOR_LEVEL_MULTIPLIER)
		--minetest.log('armor: ' .. k .. '=' .. armor_groups[k])

		-- Damage mitigation cannot go above 90%.
		if armor_groups[k] < 10 then
			armor_groups[k] = 10
		end
	end

	-- Sort preview texture list so that the shield is always on top.
	-- This looks better.
	table.sort(preview_table, function(a, b)
		if not a:find("shield") and b:find("shield") then
			return true
		end
		return false
	end)

	-- Generate character preview (a list of textures applied on top of each other).
	for k, v in ipairs(preview_table) do
		preview_string = preview_string .. "^" .. v
	end

	player:set_armor_groups(utility.builtin_armor_groups(armor_groups))
	pova.set_modifier(player, "physics", physics_o, "3d_armor")
	self.textures[name].armor = armor_texture
	self.textures[name].preview = preview_string
	self.def[name].state = state
	self.def[name].count = items
	self.def[name].heal = armor_heal
	self.def[name].jump = physics_o.jump
	self.def[name].speed = physics_o.speed
	self.def[name].gravity = physics_o.gravity
	self.def[name].resistances = loc_arm_grps
	self:update_player_visuals(player)
end



function armor.update_armor(self, player)
	-- Legacy support: Called when armor levels are changed
	-- Other mods can hook on to this function, see hud mod for example 
end



function armor.get_player_skin(self, name)
	local skin = skins.skins[name]
	return skin or armor.default_skin
end



function armor.get_preview(self, name)
end



local function get_player_max_hp(name)
	local pref = minetest.get_player_by_name(name)
	if pref then
		local scale = 500
		local hp_max = pova.get_active_modifier(pref, "properties").hp_max
		return math_floor(hp_max / scale)
	end
	return 20
end



-- Pair internal armor group keys to human-readable names.
local formspec_keysubs = {
	fleshy = "slash",
	boom = "explosive",
	cracky = "bash",
	crumbly = "wither",
	snappy = "pierce",
	choppy = "cleave",
	arrow = "ranged",
	lava = "molten",
	heat = "fire",
	electrocute = "arcane",
}

function armor.get_armor_formspec(self, name)
	if not armor.textures[name] then
		minetest.log("error", "3d_armor: Player texture["..name.."] is nil [get_armor_formspec]")
		return ""
	end

	if not armor.def[name] then
		minetest.log("error", "3d_armor: Armor def["..name.."] is nil [get_armor_formspec]")
		return ""
	end

	local formspec = armor.formspec .. "list[detached:"..name.."_armor;armor;0,1.5;3,2;]"
	formspec = formspec:gsub("armor_preview", armor.textures[name].preview)
	formspec = formspec:gsub("armor_heal", math_floor(armor.def[name].heal))
	formspec = formspec:gsub("hp_max", tostring(get_player_max_hp(name)))

	--minetest.log('testing: ' .. type(armor.def[name].resistances))

	-- Print out armor stats, whatever they are.
	local y = 0.7
	for k, v in pairs(armor.def[name].resistances) do
		--minetest.log('k=' .. k .. ', v=' .. v)

		if formspec_keysubs[k] then
			k = formspec_keysubs[k]
		end

		local s = k:sub(1, 1):upper() .. k:sub(2)
		formspec = formspec .. "label[6," .. y .. ";" .. s .. ": " .. math_floor(v) .. "]"
		y = y + 0.3
	end

	return formspec
end



function armor.update_inventory(self, player)
	local name = armor:get_valid_player(player, "[set_player_armor]")
	if not name then
		return
	end

	local formspec = armor:get_armor_formspec(name)
	formspec = formspec.."listring[current_player;main]"
		.."listring[detached:"..name.."_armor;armor]"

	local page = player:get_inventory_formspec()

	if page:find("detached:"..name.."_armor") then
		inventory_plus.set_inventory_formspec(player, formspec)
	end
end



function armor.get_valid_player(self, player, msg)
	msg = msg or ""
	if not player then
		minetest.log("error", "3d_armor: Player reference is nil "..msg)
		return
	end

	local pname = player:get_player_name()
	if not pname then
		minetest.log("error", "3d_armor: Player name is nil "..msg)
		return
	end

	local pos = player:get_pos()
	local player_inv = player:get_inventory()
	local armor_inv = minetest.get_inventory({type="detached", name=pname.."_armor"})

	if not pos then
		minetest.log("error", "3d_armor: Player position is nil "..msg)
		return
	elseif not player_inv then
		minetest.log("error", "3d_armor: Player inventory is nil "..msg)
		return
	elseif not armor_inv then
		minetest.log("error", "3d_armor: Detached armor inventory is nil "..msg)
		return
	end

	return pname, player_inv, armor_inv, pos
end



function armor.on_player_receive_fields(player, formname, fields)
	local name = armor:get_valid_player(player, "[on_player_receive_fields]")
	if not name then
		return
	end

	if fields.armor then
		local formspec = armor:get_armor_formspec(name)
		inventory_plus.set_inventory_formspec(player, formspec)
		return
	end

	for field, _ in pairs(fields) do
		if string.find(field, "skins_set") then
			minetest.after(0, function(player)
				local skin = armor:get_player_skin(name)
				armor.textures[name].skin = skin..".png"
				armor:set_player_armor(player)
			end, player)
		end
	end
end



function armor.on_joinplayer(player)
	default.player_set_model(player, "3d_armor_character.b3d")

	local name = player:get_player_name()
	local player_inv = player:get_inventory()

	local armor_inv = minetest.create_detached_inventory(name.."_armor", {
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, stack)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,

		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, nil)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,

		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local plaver_inv = player:get_inventory()
			local stack = inv:get_stack(to_list, to_index)
			player_inv:set_stack(to_list, to_index, stack)
			player_inv:set_stack(from_list, from_index, nil)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,

		allow_put = function(inv, listname, index, stack, player)
			return 1
		end,

		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,

		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return count
		end,
	}, name)

	armor_inv:set_size("armor", 6)
	player_inv:set_size("armor", 6)

	for i=1, 6 do
		local stack = player_inv:get_stack("armor", i)
		armor_inv:set_stack("armor", i, stack)
	end

	armor.def[name] = {
		state = 0,
		count = 0,
		heal = 0,
		jump = 1,
		speed = 1,
		gravity = 1,
	}

	armor.textures[name] = {
		skin = armor.default_skin..".png",
		armor = "3d_armor_trans.png",
		wielditem = "3d_armor_trans.png",
		preview = armor.default_skin.."_preview.png",
	}

	local skin = skins.skins[name]
	if skin then
		armor.textures[name].skin = skin .. ".png"
	end

	if minetest.get_modpath("player_textures") then
		local filename = minetest.get_modpath("player_textures").."/textures/player_"..name
		local f = io.open(filename..".png")
		if f then
			f:close()
			armor.textures[name].skin = "player_"..name..".png"
		end
	end

	for i=1, ARMOR_INIT_TIMES do
		minetest.after(ARMOR_INIT_DELAY * i, function(player)
			armor:set_player_armor(player)
		end, player)
	end
end



function armor.drop_armor(pos, stack)
	local obj = minetest.add_item(pos, stack)
	if obj then
		obj:set_velocity({x=math_random(-1, 1), y=5, z=math_random(-1, 1)})
	end
end



function armor.on_dieplayer(player, bp)
	local name, player_inv, armor_inv = armor:get_valid_player(player, "[on_dieplayer]")
	local pos = vector.new(bp)

	if not name then
		return
	end

	local drop = {}
	for i=1, player_inv:get_size("armor") do
		local stack = armor_inv:get_stack("armor", i)
		if stack:get_count() > 0 then
			table.insert(drop, stack)
			armor_inv:set_stack("armor", i, nil)
			player_inv:set_stack("armor", i, nil)
		end
	end

	armor:set_player_armor(player)

	local formspec = inventory_plus.get_formspec(player,"main")
	inventory_plus.set_inventory_formspec(player, formspec)

	local location = minetest.pos_to_string(pos)

	local node = minetest.get_node(pos)
	if node.name == "bones:bones" then
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		for _,stack in ipairs(drop) do
			if stack:get_count() > 0 and inv:room_for_item("main", stack) then
				inv:add_item("main", stack)
				minetest.log("action", "Put " .. stack:to_string() .. " in bones @ " .. location .. ".")
			else
				armor.drop_armor(pos, stack)
			end
		end
	else
		minetest.log("warning", "Failed to add armor to bones node at " ..
			minetest.pos_to_string(pos) .. "!")

		for _,stack in ipairs(drop) do
			armor.drop_armor(pos, stack)
		end
	end
end



function armor.get_damage_type_from_reason(reason)
	local rs = reason.type or ""
	if rs == "set_hp" or rs == "punch" then
		-- Use custom reason only if available, otherwise use engine-defined reason,
		-- which will just be 'set_hp' or 'punch'.
		if reason.reason and reason.reason ~= "" then
			if reason.reason == "node_damage" then
				-- If the notification reason is 'node_damage', then 'damage_group'
				-- should store the actual damage type.
				rs = reason.damage_group
			else
				-- Otherwise the reason itself is usually the damage type.
				rs = reason.reason
			end
		end
	end
	return rs
end



function armor.damage_type_disables_cloak(rstr)
	if rstr == "fleshy" or rstr == "arrow" or rstr == "boom" or rstr == "fireball"
			or rstr == "cracky" or rstr == "crumbly" or rstr == "snappy" or rstr == "choppy"
			or rstr == "crush" then
		return true
	end
	return false
end

function armor.armor_wear_ignores_damage(rstr)
	if rstr == "" or rstr == "xp_update" or rstr == "hp_boost_end"
			or rstr == "hunger" or rstr == "drown" or rstr == "poison"
			or rstr == "pressure" then
		return true
	end
	return false
end



-- Calc wear multiplier based on reason and armor piece.
-- Notes: 'type' will be "set_hp" if from player:set_hp().
-- Must use 'reason' field in that case.
--
-- Reason types are:
--   fall (fall damage, duh)
--   punch (punched by something)
--   drown (drowning, duh)
--   heat (caused by quite a few sources of heat, including lava)
--   pressure (water pressure, usually)
--   ground (ground/floor hazard, spikes, etc)
--   sharp (like cactus)
--   crush (by falling node/object)
--   portal (arcane damage by teleporting)
--   poison (mushrooms, rotten meat)
--   hunger (starvation)
--   kill (kill command)
--   radiation (reactors, etc)
--   electrocute (solar panels)
--   fireball (DM artillery, etc)
--   arrow (player weapon or mob)
--   boom (explosions)
--
-- Note: the above are also the names of damage groups and armor groups.
function armor.wear_from_reason(item, def, reason)
	local rs = armor.get_damage_type_from_reason(reason)

	--minetest.log('Reason: ' .. rs)

	-- If reason not known, just return default wear multiplier.
	if rs == "" then
		return 1
	end

	if def._armor_wear_groups then
		local mult = def._armor_wear_groups[rs] or 1
		--minetest.log('wear multiplier: ' .. mult)
		return mult
	end

	-- Default, if wear modifier not found.
	return 1
end



function armor.on_player_hp_change(player, hp_change, reason)
	-- If a notified reason is available, use that instead.
	if reason.type == "punch" or reason.type == "set_hp" then
		local huh = armor.get_hp_change_reason(reason)
		if huh then
			reason = huh
			--minetest.chat_send_all('replace dump: ' .. dump(reason))
		end
	end

	local pname, player_inv, armor_inv = armor:get_valid_player(player, "[on_hpchange]")
	if not (pname and hp_change < 0) then
		return hp_change
	end

	-- Admin does not take damage.
	local singleplayer = minetest.is_singleplayer()
	if not singleplayer then
		if gdac.player_is_admin(player) then
			return 0
		end
	end

	--minetest.log('reason: ' .. (reason.type or reason.reason or "N/A"))
	--minetest.log('dump: ' .. dump(reason))
	--minetest.chat_send_all('dump: ' .. dump(reason))
	--minetest.log('on_player_hp_change: ' .. hp_change)

	-- used for insta kill tools/commands like /kill (doesnt damage armor)
	if hp_change <= -60000 then
		return hp_change
	end

	local heal_max = 0
	local state = 0
	local items = 0

	-- Need to scale fall damage since players' HP is very high.
	-- AFAIK, the only other way to adjust this would be to change every node's
	-- 'fall_damage_add_percent', but that would NOT be a good idea.
	if reason.type == "fall" then
		--minetest.log('fall: ' .. hp_change)

		-- Kids, don't get bit like I did. I just spend 1 hr trying to debug this
		-- code, and it turned out the problem was passing a negative value to this
		-- function for the amount of damage. Facepalm. Why do they let me code!?
		if armor.stomp_at(player, player:get_pos(), math.abs(hp_change * 1000)) then
			hp_change = hp_change * 100
		else
			hp_change = hp_change * 500
		end
	elseif reason.type == "drown" then
		-- In the case of drowning damage, we HAVE to do it this way, because
		-- Minetest does NOT, apparently, correctly apply drowning damage itself
		-- when the value is very high!
		hp_change = hp_change * 500
	end

	-- Why do I have to do this ugly hack? Because Minetest!!!!11111!!!11
	-- Note: purpose of this hack is to ensure that the node's 'damage_per_second'
	-- can be mitigated by player's current armor stats. As of this writing, by
	-- default in Minetest, 'damage_per_second' behaves like :set_hp(), bypassing
	-- armor groups.
	if reason.type == "node_damage" and reason.node and reason.node ~= "" then
		local ndef = minetest.registered_nodes[reason.node]
		if ndef and ndef._damage_per_second_type then
			local dtp = ndef._damage_per_second_type
			local dps = ndef.damage_per_second or 0

			-- Do NOT execute the following code within this function's call-stack.
			-- That's just asking for trouble because of possible recursion.
			minetest.after(0, function()
				local pref = minetest.get_player_by_name(pname)
				if pref then
					-- PlayerHPChangeReason.type will be 'punch'.
					utility.damage_player(pref, dtp, dps,
						{reason="node_damage", damage_group=dtp, source_node=reason.node, node_pos=reason.node_pos})
				end
			end)

			-- Do not apply damage from this point. Damage will be applied via 'punch'
			-- on the next server step.
			return 0
		end
	end

	local damage_type = armor.get_damage_type_from_reason(reason)
	local ignore_wear = armor.armor_wear_ignores_damage(damage_type)

	-- Test code to check that I know what I'm doing.
	--minetest.log('hpchange type: ' .. reason.type .. ', reason: ' .. damage_type)
	--minetest.log('scaled hp change: ' .. hp_change)

	-- Do not scale damage if the engine type is 'set_hp'.
	if reason.type == "punch" then
		-- If HP change would kill player, do NOT scale it!
		-- That results in misbehavior. This does have the result that damage
		-- scaling behaves weird on the final hit before a player dies, as in that
		-- case damage isn't scaled.
		if math.abs(hp_change) < player:get_hp() then
			hp_change = hp_change * hunger.get_damage_resistance(pname)
		end
	end

	for i = 1, 6 do
		local stack = player_inv:get_stack("armor", i)

		if stack:get_count() > 0 then
			local idef = stack:get_definition()
			local use = idef.groups["armor_use"] or 0
			local heal = idef.groups["armor_heal"] or 0
			local item = stack:get_name()

			if not ignore_wear then
				stack:add_wear(use * armor.wear_from_reason(item, idef, reason))
			end

			armor_inv:set_stack("armor", i, stack)
			player_inv:set_stack("armor", i, stack)

			state = state + stack:get_wear()
			items = items + 1

			if stack:get_count() == 0 then
				local desc = minetest.registered_items[item].description

				if desc then
					minetest.chat_send_player(pname, "# Server: Your " .. desc .. " got destroyed!")
					ambiance.sound_play("default_tool_breaks", player:get_pos(), 1.0, 20)
				end

				armor:set_player_armor(player)
				armor:update_inventory(player)
			end

			heal_max = heal_max + heal
		end
	end

	armor.def[pname].state = state
	armor.def[pname].count = items

	heal_max = heal_max * ARMOR_HEAL_MULTIPLIER
	heal_max = math.min(heal_max, 90)

	if math_random(100) < heal_max then
		hp_change = 0
	end

	armor:update_armor(player)

	-- Critical: the hp change must be an integer; floating-point comparisons are
	-- deadly.
	hp_change = math_floor(hp_change)

	-- Check for combat-related reasons.
	-- (Ignore this if damage was blocked by the heal chance.)
	if math.abs(hp_change) > 0 and armor.damage_type_disables_cloak(damage_type) then
		cloaking.disable_if_enabled(pname, true)
	end

	-- If this change would kill the player, set the death reason.
	-- Note: this RELIES on the bones code getting called after this returns, on
	-- the SAME server step, such that no other death reason could intervene for
	-- any other player that is currently logged in.
	if math.abs(hp_change) >= player:get_hp() then
		--minetest.chat_send_all('armor notify: ' .. dump(reason))
		armor.notify_death_reason(reason)
	end

	return hp_change
end
