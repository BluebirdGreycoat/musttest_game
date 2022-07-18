
-- File rewritten to be live-reloadable August 14, 2018 by MustTest.
-- `mobs.registered' is checked throughout file, but only set `true' @ END!

-- localize functions
local pi = math.pi
local square = math.sqrt
local sin = math.sin
local cos = math.cos
local abs = math.abs
local min = math.min
local max = math.max
local ceil = math.ceil
local atan2 = math.atan2
local random = math.random
local math_random = math.random
local floor = math.floor
local v_round = vector.round
local v_equals = vector.equals
local vector_distance = vector.distance
local v_distance = vector.distance

local function report(msg)
	if minetest.is_singleplayer() then
		minetest.chat_send_all(msg)
	else
		local pname = gdac.name_of_admin
		minetest.chat_send_player(pname, msg)
	end
end

-- Function to tell mob which direction to turn to face target.
-- Add pi to the returned yaw to face in the opposite direction.
-- Fixed to use atan2 correctly by MustTest.
local function compute_yaw_to_target(self, target, pos)
	local x = target.x - pos.x
	local z = target.z - pos.z

	local yaw = atan2(z, x) - self.rotate
	yaw = yaw - (pi / 2)
	return yaw
end

-- Load settings.
local damage_enabled =  true --minetest.setting_getbool("enable_damage")
local peaceful_only =   false --minetest.setting_getbool("only_peaceful_mobs")
local disable_blood =   false --minetest.setting_getbool("mobs_disable_blood")
local mobs_drop_items = minetest.settings:get_bool("mobs_drop_items") ~= false
local mobs_griefing =   minetest.settings:get_bool("mobs_griefing") ~= false
local creative =        minetest.setting_getbool("creative_mode")
local spawn_protected = minetest.settings:get_bool("mobs_spawn_protected") ~= false
local remove_far =      minetest.setting_getbool("remove_far_mobs")
local difficulty =      tonumber(minetest.setting_get("mob_difficulty")) or 1.0
local show_health =     minetest.settings:get_bool("mob_show_health") ~= false
local max_per_block =   tonumber(minetest.settings:get("max_objects_per_block") or 99)
local mob_chance_multiplier = tonumber(minetest.settings:get("mob_chance_multiplier") or 1)

local default_knockback = 1

-- Used by spawner function.
mobs.spawn_protected = spawn_protected

-- Legacy.
if not mobs.invis then
	mobs.invis = {}
end

function mobs.is_invisible(self, pname)
	if not self.ignore_invisibility then
		return (cloaking.is_cloaked(pname) or gdac_invis.is_invisible(pname))
	end
end

-- creative check
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function mobs.is_creative(name)
	return creative_mode_cache or minetest.check_player_privs(name, {creative = true})
end

-- Peaceful mode message so players will know there are no monsters.
-- Perform registration only ONCE.
if not mobs.registered and peaceful_only then
	minetest.register_on_joinplayer(function(player)
		minetest.chat_send_player(player:get_player_name(),
			"# Server: Peaceful mode active - no new monsters will spawn.")
	end)
end

-- calculate aoc range for mob count
local aoc_range = tonumber(minetest.settings:get("active_block_range")) * 16

-- pathfinding settings
local enable_pathfinding = true
local stuck_timeout = 3 -- how long before mob gets stuck in place and starts searching

-- Note: stuck path timeout is determined based on the length of the path, and
-- is a mob-internal property [MustTest].

-- default nodes
local node_fire = "fire:basic_flame"
local node_permanent_flame = "fire:permanent_flame"
local node_ice = "default:ice"
local node_snowblock = "default:snowblock"
local node_snow = "default:snow"
local node_pathfiner_place = "default:cobble"

mobs.fallback_node = minetest.registered_aliases["mapgen_dirt"] or "default:dirt"



-- play sound
local function mob_sound(self, sound)
	if sound then
		local dist = self.sounds.distance or 20
		ambiance.sound_play(sound, self.object:get_pos(), 1.0, dist)

		-- This isn't working!
		--minetest.sound_play(sound, {
		--	object = self.object,
		--	gain = 1.0,
		--	max_hear_distance = self.sounds.distance
		--})
	end
end



local kill_adj = {
	"killed",
	"slain",
	"slaughtered",
	"mauled",
	"murdered",
	"pwned",
	"owned",
	"dispatched",
	"neutralized",
	"wasted",
	"polished off",
	"rubbed out",
	"snuffed out",
	"assassinated",
	"annulled",
	"destroyed",
	"finished off",
	"terminated",
	"wiped out",
	"scrubbed",
	"abolished",
	"obliterated",
	"voided",
	"ended",
	"annihilated",
	"undone",
	"nullified",
	"exterminated",
}
local kill_adj2 = {
	"killed",
	"slew",
	"slaughtered",
	"mauled",
	"murdered",
	"pwned",
	"owned",
	"dispatched",
	"neutralized",
	"wasted",
	"polished off",
	"rubbed out",
	"snuffed out",
	"assassinated",
	"annulled",
	"destroyed",
	"finished off",
	"terminated",
	"wiped out",
	"scrubbed",
	"abolished",
	"obliterated",
	"voided",
	"ended",
	"annihilated",
	"undid",
	"nullified",
	"exterminated",
}
local kill_adj3 = {
	"kill",
	"slay",
	"slaughter",
	"maul",
	"murder",
	"pwn",
	"own",
	"dispatch",
	"neutralize",
	"waste",
	"polish off",
	"rub out",
	"snuff out",
	"assassinate",
	"annul",
	"destroy",
	"finish off",
	"terminate",
	"wipe out",
	"scrub",
	"abolish",
	"obliterate",
	"void",
	"end",
	"annihilate",
	"undo",
	"nullify",
	"exterminate",
}
local kill_adv = {
	"brutally",
	"",
	"swiftly",
	"",
	"savagely",
	"",
	"viciously",
	"",
	"uncivilly",
	"",
	"barbarously",
	"",
	"ruthlessly",
	"",
	"ferociously",
	"",
	"rudely",
	"",
	"cruelly",
	"",
}
local kill_ang = {
	"angry",
	"",
	"PO'ed",
	"",
	"furious",
	"",
	"disgusted",
	"",
	"infuriated",
	"",
	"annoyed",
	"",
	"irritated",
	"",
	"bitter",
	"",
	"offended",
	"",
	"outraged",
	"",
	"irate",
	"",
	"enraged",
	"",
	"indignant",
	"",
	"irritable",
	"",
	"cross",
	"",
	"riled",
	"",
	"vexed",
	"",
	"wrathful",
	"",
	"fierce",
	"",
	"displeased",
	"",
	"irascible",
	"",
	"ireful",
	"",
	"sulky",
	"",
	"ill-tempered",
	"",
	"vehement",
	"",
	"raging",
	"",
	"incensed",
	"",
	"frenzied",
	"",
	"enthusiastic",
	"",
	"fuming",
	"",
	"cranky",
	"",
	"peevish",
	"",
	"belligerent",
	"",
}

local function mob_killed_player(self, player)

	local pname = player:get_player_name()
	local mname = utility.get_short_desc(self.description or "mob")
	local adv = kill_adv[math_random(1, #kill_adv)]
	if adv ~= "" then
		adv = adv .. " "
	end
	local adj = kill_adj[math_random(1, #kill_adj)]
	local ang = kill_ang[math_random(1, #kill_ang)]
	if ang ~= "" then
		ang = ang .. " "
	end
	local an = "a"
	if ang ~= "" then
		if ang:find("^[aeiouAEIOU]") then
			an = "an"
		end
	else
		if mname:find("^[aeiouAEIOU]") then
			an = "an"
		end
	end

	local victim = "<" .. rename.gpn(pname) .. ">"
	if cloaking.is_cloaked(pname) or player_labels.query_nametag_onoff(pname) == false then
		victim = "An explorer"
	end

	minetest.chat_send_all("# Server: " .. victim .. " was " .. adv .. adj .. " by " .. an .. " " .. ang .. mname .. ".")
end



local pain_words = {
	"harm",
	"pain",
	"grief",
	"trouble",
	"evil",
	"ill will",
}

local murder_messages = {
	"<n> <v> collapsed from <an_angry_k>'s <angry>attack.",
	"<an_angry_k>'s <w> apparently wasn't such an unusual weapon after all, as <n> <v> found out.",
	"<an_angry_k> <brutally><slew> <n> <v> with great prejudice.",
	"<n> <v> died from <an_angry_k>'s horrid slaying.",
	"<n> <v> fell prey to <an_angry_k>'s deadly <w>.",
	"<an_angry_k> went out of <k_his> way to <slay> <n> <v> with <k_his> <w>.",
	"<n> <v> danced <v_himself> to death under <an_angry_k>'s craftily wielded <w>.",
	"<an_angry_k> used <k_his> <w> to <slay> <n> <v> with prejudice.",
	"<an_angry_k> made a splortching sound with <n> <v>'s head.",
	"<n> <v> was <slain> by <an_angry_k>'s skillfully handled <w>.",
	"<n> <v> became prey for <an_angry_k>.",
	"<n> <v> didn't get out of <an_angry_k>'s way in time.",
	"<n> <v> SAW <an_angry_k> coming with <k_his> <w>. Didn't get away in time.",
	"<n> <v> made no real attempt to get out of <an_angry_k>'s way.",
	"<an_angry_k> barreled through <n> <v> as if <v_he> wasn't there.",
	"<an_angry_k> sent <n> <v> to that place where kindling wood isn't needed.",
	"<n> <v> didn't suspect that <an_angry_k> meant <v_him> any <pain>.",
	"<n> <v> fought <an_angry_k> to the death and lost painfully.",
	"<n> <v> knew <an_angry_k> was wielding <k_his> <w> but didn't guess what <k> meant to do with it.",
	"<an_angry_k> <brutally>clonked <n> <v> over the head using <k_his> <w> with silent skill.",
	"<an_angry_k> made sure <n> <v> didn't see that coming!",
	"<an_angry_k> has decided <k_his> favorite weapon is <k_his> <w>.",
	"<n> <v> did the mad hatter dance just before being <slain> with <an_angry_k>'s <w>.",
	"<n> <v> played the victim to <an_angry_k>'s bully behavior!",
	"<an_angry_k> used <n> <v> for weapons practice with <k_his> <w>.",
	"<n> <v> failed to avoid <an_angry_k>'s oncoming weapon.",
	"<an_angry_k> successfully got <n> <v> to complain of a headache.",
	"<n> <v> got <v_himself> some serious hurt from <an_angry_k>'s <w>.",
	"Trying to talk peace to <an_angry_k> didn't win any for <n> <v>.",
	"<n> <v> was <brutally><slain> by <an_angry_k>'s <w>.",
	"<n> <v> jumped the mad-hatter dance under <an_angry_k>'s <w>.",
	"<n> <v> got <v_himself> a fatal mauling by <an_angry_k>'s <w>.",
	"<an_angry_k> <brutally><slew> <n> <v> with <k_his> <w>.",
	"<an_angry_k> split <n> <v>'s wig.",
	"<an_angry_k> took revenge on <n> <v>.",
	"<an_angry_k> <brutally><slew> <n> <v>.",
	"<n> <v> played dead. Permanently.",
	"<n> <v> never saw what hit <v_him>.",
	"<an_angry_k> took <n> <v> by surprise.",
	"<n> <v> was <brutally><slain>.",
	"<an_angry_k> didn't take any prisoners from <n> <v>.",
	"<an_angry_k> <brutally>pinned <n> <v> to the wall with <k_his> <w>.",
	"<n> <v> failed <v_his> weapon checks.",
	"<k> eliminated <n> <v>.",
}

local message_spam_avoidance = {}

local function player_killed_mob(self, player)
	local pname = player:get_player_name()
	if message_spam_avoidance[pname] then
		return
	end


	local mname = utility.get_short_desc(self.description or "mob")

	local msg = murder_messages[math_random(1, #murder_messages)]
	msg = string.gsub(msg, "<v>", mname)

	local ksex = skins.get_gender_strings(pname)
	local vsex = skins.get_random_standard_gender(5) -- 5% female.

	msg = string.gsub(msg, "<k_himself>", ksex.himself)
	msg = string.gsub(msg, "<k_his>", ksex.his)

	msg = string.gsub(msg, "<v_himself>", vsex.himself)
	msg = string.gsub(msg, "<v_his>", vsex.his)
	msg = string.gsub(msg, "<v_him>", vsex.him)
	msg = string.gsub(msg, "<v_he>", vsex.he)

	if string.find(msg, "<brutally>") then
		local adv = kill_adv[math_random(1, #kill_adv)]
		if adv ~= "" then
			adv = adv .. " "
		end
		msg = string.gsub(msg, "<brutally>", adv)
	end

	if string.find(msg, "<slain>") then
		local adj = kill_adj[math_random(1, #kill_adj)]
		msg = string.gsub(msg, "<slain>", adj)
	end

	if string.find(msg, "<slew>") then
		local adj = kill_adj2[math_random(1, #kill_adj2)]
		msg = string.gsub(msg, "<slew>", adj)
	end

	if string.find(msg, "<slay>") then
		local adj = kill_adj3[math_random(1, #kill_adj3)]
		msg = string.gsub(msg, "<slay>", adj)
	end

	if string.find(msg, "<pain>") then
		local adj = pain_words[math_random(1, #pain_words)]
		msg = string.gsub(msg, "<pain>", adj)
	end

	if string.find(msg, "<angry>") then
		local ang = kill_ang[math_random(1, #kill_ang)]
		if ang ~= "" then
			ang = ang .. " "
		end
		msg = string.gsub(msg, "<angry>", ang)
	end

	if string.find(msg, "<an_angry_k>") then
		local replace = ""

		local angry = kill_ang[math_random(1, #kill_ang)]
		if angry ~= "" then
			local an = "a"

			if angry:find("^[aeiouAEIOU]") then
				an = "an"
			end

			replace = an .. " " .. angry .. " "
		end

		local name = ""
		if cloaking.is_cloaked(pname) or player_labels.query_nametag_onoff(pname) == false then
			if replace == "" then
				name = "an explorer"
			else
				name = "explorer"
			end
			replace = replace .. name
		else
			replace = replace .. "<" .. rename.gpn(pname) .. ">"
		end

		msg = string.gsub(msg, "<an_angry_k>", replace)
	end

	if msg:find("<k>") then
		local replace = "<" .. rename.gpn(pname) .. ">"
		if cloaking.is_cloaked(pname) or player_labels.query_nametag_onoff(pname) == false then
			replace = "an explorer"
		end
		msg = msg:gsub("<k>", replace)
	end

	if string.find(msg, "<n>") then
		local an = "a"
		if mname:find("^[aeiouAEIOU]") then
			an = "an"
		end
		msg = string.gsub(msg, "<n>", an)
	end

	-- Get weapon description.
	if string.find(msg, "<w>") then
		local wield = player:get_wielded_item()
		local def = minetest.registered_items[wield:get_name()]
		local meta = wield:get_meta()
		local description = meta:get_string("description")
		if description ~= "" then
			msg = string.gsub(msg, "<w>", "'" .. utility.get_short_desc(description):trim() .. "'")
		elseif def and def.description then
			local str = utility.get_short_desc(def.description)
			if str == "" then
				str = "Potato Fist"
			end
			msg = string.gsub(msg, "<w>", str)
		end
	end

	-- Make first character uppercase.
	msg = string.upper(msg:sub(1, 1)) .. msg:sub(2)
	msg = string.gsub(msg, "%s+", " ") -- Remove duplicate spaces.
	msg = string.gsub(msg, " %.$", ".") -- Remove space before period.
	minetest.chat_send_all("# Server: " .. msg)

	message_spam_avoidance[pname] = {}
	minetest.after(math_random(10, 60*2), function()
		message_spam_avoidance[pname] = nil
	end)
end



local function do_attack(self, player)
	if self.state == "attack" then
		return
	end

	self.state = "attack"
	self.attack = player

	if random(0, 100) < 90 and self.sounds.war_cry then
		mob_sound(self, self.sounds.war_cry)
	end
end



local function set_velocity(self, v)
	-- Do not move if mob has been ordered to stay.
	if self.order == "stand" then
		self.object:set_velocity({x = 0, y = 0, z = 0})
		return
	end

	local yaw = (self.object:get_yaw() or 0) + (self.rotate or 0)
	local vel = self.object:get_velocity()
	local y = 0
	if vel then
		y = vel.y or 0
	end

	-- Fix crash: 2020-09-12 14:26:15: ERROR[Main]: ServerError: AsyncErr:
	-- ServerThread::run Lua: Runtime error from mod 'griefer' in callback
	-- luaentity_Step(): Invalid float vector dimension range 'y' (expected
	-- -2.14748e+06 < y < 2.14748e+06 got -1.96364e+12).
	y = max(min(y, 200), -200)

	self.object:set_velocity({
		x = sin(yaw) * -v,
		y = y,
		z = cos(yaw) * v
	})
end



local function get_velocity(self)
	local v = self.object:getvelocity()
	return (v.x * v.x + v.z * v.z) ^ 0.5
end



-- set and return valid yaw
local function set_yaw(self, yaw, delay)

	if not yaw or yaw ~= yaw then
		yaw = 0
	end

	delay = delay or 0

	if delay == 0 then
		self.object:set_yaw(yaw)
		return yaw
	end

	self.target_yaw = yaw
	self.delay = delay

	return self.target_yaw
end



-- global function to set mob yaw
function mobs.yaw(self, yaw, delay)
	set_yaw(self, yaw, delay)
end



local function set_animation(self, anim)
	if not self.animation or not anim then
		return
	end

	self.animation.current = self.animation.current or ""

	-- only set different animation for attacks when setting to same set
	if anim ~= "punch" and anim ~= "shoot"
	and string.find(self.animation.current, anim) then
		return
	end

	-- check for more than one animation
	local num = 0

	for n = 1, 4 do

		if self.animation[anim .. n .. "_start"]
		and self.animation[anim .. n .. "_end"] then
			num = n
		end
	end

	-- choose random animation from set
	if num > 0 then
		num = random(0, num)
		anim = anim .. (num ~= 0 and num or "")
	end

	if anim == self.animation.current
	or not self.animation[anim .. "_start"]
	or not self.animation[anim .. "_end"] then
		return
	end

	self.animation.current = anim

	self.object:set_animation({
		x = self.animation[anim .. "_start"],
		y = self.animation[anim .. "_end"]},
		self.animation[anim .. "_speed"] or self.animation.speed_normal or 15,
		0, self.animation[anim .. "_loop"] ~= false)
end



-- above function exported for mount.lua
function mobs.set_animation(self, anim)
	set_animation(self, anim)
end



-- calculate distance
local function get_distance(a, b)
	local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
	return square(x * x + y * y + z * z)
end



-- check line of sight (by BrunoMine, tweaked by Astrobe)
local function line_of_sight(self, pos1, pos2, stepsize)

	if not pos1 or not pos2 then return end

	stepsize = stepsize or 1

	local stepv = vector.multiply(vector.direction(pos1, pos2), stepsize)

	local s, pos = minetest.line_of_sight(pos1, pos2, stepsize)

	-- normal walking and flying mobs can see you through air
	if s == true then return true end

	-- New pos1 to be analyzed
	local npos1 = {x = pos1.x, y = pos1.y, z = pos1.z}

	local r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

	-- Checks the return
	if r == true then return true end

	-- Nodename found
	local nn = minetest.get_node(pos).name

	-- It continues to advance in the line of sight in search of a real
	-- obstruction which counts as 'normal' nodebox.
	local registered = minetest.reg_ns_nodes
	local ndef = registered[nn] or minetest.registered_nodes[nn]

	while ndef
		and (ndef.walkable == false
		or ndef.drawtype == "nodebox"
		or ndef.drawtype:find("glasslike")) do

		npos1 = vector.add(npos1, stepv)

		if get_distance(npos1, pos2) < stepsize then return true end

		-- scan again
		r, pos = minetest.line_of_sight(npos1, pos2, stepsize)

		if r == true then return true end

		-- New Nodename found
		nn = minetest.get_node(pos).name
		ndef = registered[nn] or minetest.registered_nodes[nn]
	end

	return false
end



-- global function
function mobs.line_of_sight(self, pos1, pos2, stepsize)
	return line_of_sight(self, pos1, pos2, stepsize)
end



-- are we flying in what we are suppose to? (taikedz)
local function flight_check(self, pos_w)
	local def = minetest.reg_ns_nodes[self.standing_in]
	if not def then return false end -- nil check

	if type(self.fly_in) == "string"
	and self.standing_in == self.fly_in then

		return true

	elseif type(self.fly_in) == "table" then

		for _,fly_in in pairs(self.fly_in) do

			if self.standing_in == fly_in then

				return true
			end
		end
	end

	--print ("standing in " .. self.standing_in)

	-- stops mobs getting stuck inside stairs and plantlike nodes
	if def.drawtype ~= "airlike"
	and def.drawtype ~= "liquid"
	and def.drawtype ~= "flowingliquid" then
		return true
	end

	-- enables mobs to fly in non-walkable stuff like thin default:snow
	if not def.walkable then
		return true
	end

	return false
end



-- custom particle effects
local function effect(pos, amount, texture, min_size, max_size, radius, gravity, glow)

	radius = radius or 2
	min_size = min_size or 0.5
	max_size = max_size or 1
	gravity = gravity or -10
	glow = glow or 0

	minetest.add_particlespawner({
		amount = amount,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -radius, y = -radius, z = -radius},
		maxvel = {x = radius, y = radius, z = radius},
		minacc = {x = 0, y = gravity, z = 0},
		maxacc = {x = 0, y = gravity, z = 0},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = min_size,
		maxsize = max_size,
		texture = texture,
		glow = glow,
	})
end



-- Update nametag colour.
local function update_tag(self)

	local col = "#00FF00"
	local qua = self.hp_max / 4

	if self.health <= floor(qua * 3) then
		col = "#FFFF00"
	end

	if self.health <= floor(qua * 2) then
		col = "#FF6600"
	end

	if self.health <= floor(qua) then
		col = "#FF0000"
	end

	self.object:set_properties({
		nametag = self.nametag,
		nametag_color = col,
	})
end



-- drop items
local function item_drop(self, cooked)

	-- check for nil or no drops
	if not self.drops or #self.drops == 0 then
		return
	end

	-- no drops if disabled by setting
	if not mobs_drop_items then return end

	-- no drops for child mobs
	if self.child then return end

	local obj, item, num
	local pos = self.object:get_pos()

	for n = 1, #self.drops do

		if random(1, self.drops[n].chance) == 1 then

			num = random(self.drops[n].min or 0, self.drops[n].max or 1)
			item = self.drops[n].name

			-- cook items when true
			if cooked then

				local output = minetest.get_craft_result({
					method = "cooking", width = 1, items = {item}})

				if output and output.item and not output.item:is_empty() then
					item = output.item:get_name()
				end
			end

			-- add item if it exists
			obj = minetest.add_item(pos, ItemStack(item .. " " .. num))

			if obj and obj:get_luaentity() then

				obj:set_velocity({
					x = random(-10, 10) / 9,
					y = 6,
					z = random(-10, 10) / 9,
				})
			elseif obj then
				obj:remove() -- item does not exist
			end
		end
	end

	self.drops = {}
end



-- check if mob is dead or only hurt
local function check_for_death(self, cause, cmi_cause)

	-- has health actually changed?
	if self.health == self.old_health and self.health > 0 then
		return
	end

	self.old_health = self.health

	-- still got some health? play hurt sound
	if self.health > 0 then

		mob_sound(self, self.sounds.damage)

		-- make sure health isn't higher than max
		if self.health > self.hp_max then
			self.health = self.hp_max
		end

		-- backup nametag so we can show health stats
		if not self.nametag2 then
			self.nametag2 = self.nametag or ""
		end

		if show_health and (cmi_cause and cmi_cause.type == "punch") then

			self.htimer = 2
			self.nametag = "♥ " .. self.health .. " / " .. self.hp_max

			update_tag(self)
		end

		return false
	end

	-- Mob will die, check if we were attacked.
	if cause == "hit" then
		if self.last_attacked_by and self.last_attacked_by ~= "" then
			local attacked_by = minetest.get_player_by_name(self.last_attacked_by)
			if attacked_by then
				player_killed_mob(self, attacked_by)
			end
		end
	end

	-- only drop items if weapon is of sufficient level to overcome mob's armor level
	local can_drop = true
	if cmi_cause and cmi_cause.tool_capabilities then
		local max_drop_level = (cmi_cause.tool_capabilities.max_drop_level or 0)

		-- Increase weapon's max drop level if rank is level 7.
		local tool_level = 1
		if cmi_cause.wielded then
			local tool_meta = cmi_cause.wielded:get_meta()
			tool_level = tonumber(tool_meta:get_string("tr_lastlevel")) or 1
		end
		if tool_level >= 7 then
			max_drop_level = max_drop_level + 1
		end

		if (max_drop_level) < (self.armor_level or 0) then
			can_drop = false
		end
	end

	-- mob doesn't drop anything if killed by sunlight
	-- this fixes the problem of drops being scattered around after sunrise
	-- caused by icemen and sandmen
	if cause == "light" then
		can_drop = false
	end

	if can_drop then
		-- dropped cooked item if mob died in lava
		if cause == "lava" then
			item_drop(self, true)
		else
			item_drop(self, nil)
		end
	end

	mob_sound(self, self.sounds.death)

	local pos = self.object:get_pos()

	-- execute custom death function
	if self.on_die then

		self.on_die(self, pos)

		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return true
	end

	-- default death function and die animation (if defined)
	if self.animation
	and self.animation.die_start
	and self.animation.die_end then

		local frames = self.animation.die_end - self.animation.die_start
		local speed = self.animation.die_speed or 15
		local length = max(frames / speed, 0)

		self.attack = nil
		self.v_start = false
		self.timer = 0
		self.blinktimer = 0
		self.passive = true
		self.state = "die"
		set_velocity(self, 0)
		set_animation(self, "die")

		minetest.after(length, function(self)
			-- Mark for removal as last action on mob_step().
			-- Note: this is deferred for a bit!
			self.mkrm = true
		end, self)
	else
		-- Mark for removal as last action on mob_step().
		self.mkrm = true
	end

	effect(pos, 20, "tnt_smoke.png")

	return true
end



-- Check if within physical map limits (-30911 to 30927).
local function within_limits(pos, radius)
	if (pos.x - radius) > -30913
        and (pos.x + radius) <  30928
        and (pos.y - radius) > -30913
        and (pos.y + radius) <  30928
        and (pos.z - radius) > -30913
        and (pos.z + radius) <  30928 then
		return true -- Within limits.
	end
	return false -- Beyond limits.
end



-- Is mob facing a cliff.
local function is_at_cliff(self)
	if self.fear_height == 0 then -- 0 for no falling protection!
		return false
	end

	local yaw = self.object:get_yaw()
	local dir_x = -sin(yaw) * (self.collisionbox[4] + 0.5)
	local dir_z = cos(yaw) * (self.collisionbox[4] + 0.5)
	local pos = self.object:getpos()
	local ypos = pos.y + self.collisionbox[2] -- just above floor

	if minetest.line_of_sight(
		{x = pos.x + dir_x, y = ypos, z = pos.z + dir_z},
		{x = pos.x + dir_x, y = ypos - self.fear_height, z = pos.z + dir_z}
	, 1) then

		return true
	end

	return false
end



-- Get node but use fallback for nil or unknown.
local function node_ok(pos, fallback)

	fallback = fallback or mobs.fallback_node

	local node = minetest.get_node_or_nil(pos)

	if node and minetest.reg_ns_nodes[node.name] then
		return node
	end

	return minetest.reg_ns_nodes[fallback]
end



-- Global function.
function mobs.node_ok(pos, fallback)
	return node_ok(pos, fallback)
end


-- Environmental damage (water, lava, fire, light).
local function do_env_damage(self)

	-- feed/tame text timer (so mob 'full' messages dont spam chat)
	if self.htimer > 0 then
		self.htimer = self.htimer - 1
	end

	-- reset nametag after showing health stats
	if self.htimer < 1 and self.nametag2 then

		self.nametag = self.nametag2
		self.nametag2 = nil

		update_tag(self)
	end

	local pos = self.object:getpos()

	self.time_of_day = minetest.get_timeofday()

	-- remove mob if beyond map limits
	if not within_limits(pos, 0) then
		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return
	end

	-- mob may simply despawn at daytime, without dropping anything
	if random(1, 10) == 1 then -- add some random delay chance
		if self.daytime_despawn and pos.y > -10
		and self.time_of_day > 0.2
		and self.time_of_day < 0.8
		and (minetest.get_node_light(pos) or 0) > 12 then
			if self.on_despawn then
				self.on_despawn(self)
				return
			else
				-- Mark for removal as last action on mob_step().
				self.mkrm = true

				return
			end
		end
	end

	-- bright light harms mob
	-- daylight above ground
	if self.light_damage ~= 0
	and pos.y > -10
	and self.time_of_day > 0.2
	and self.time_of_day < 0.8
	and (minetest.get_node_light(pos) or 0) > 12 then

		self.health = self.health - self.light_damage

		effect(pos, 5, "tnt_smoke.png")

		if check_for_death(self, "light", {type = "light"}) then return end
	end

	if self.despawns_in_dark_caves and pos.y < -12 then
		if (minetest.get_node_light(pos) or 0) == 0 then
			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			return
		end
	end

	-- don't fall when on ignore, just stand still
	if self.standing_in == "ignore" then
		self.object:set_velocity({x = 0, y = 0, z = 0})
	end

	local nodef = minetest.reg_ns_nodes[self.standing_in]
	local nodef2 = minetest.reg_ns_nodes[self.standing_on]

	-- Stairs nodes don't do env damage.
	if not nodef or not nodef2 then
		return
	end

	pos.y = pos.y + 1 -- for particle effect position

	-- water
	if self.water_damage
	and nodef.groups.water then

		if self.water_damage ~= 0 then

			self.health = self.health - self.water_damage

			effect(pos, 5, "bubble.png", nil, nil, 1, nil)

			if check_for_death(self, "water", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- lava or fire
	elseif self.lava_damage
	and (nodef.groups.lava or nodef.groups.fire) then

		if self.lava_damage ~= 0 then

			self.health = self.health - self.lava_damage

			effect(pos, 5, "fire_basic_flame.png", nil, nil, 1, nil)

			if check_for_death(self, "lava", {type = "environment",
					pos = pos, node = self.standing_in}) then return end
		end

	-- damage_per_second node check
	elseif nodef.damage_per_second ~= 0 then

		self.health = self.health - nodef.damage_per_second

		effect(pos, 5, "tnt_smoke.png")

		if check_for_death(self, "dps", {type = "environment",
				pos = pos, node = self.standing_in}) then return end
	end

	if nodef2.groups.lava and self.lava_annihilates and self.lava_annihilates == true then
		self.health = 0

		effect(pos, 5, "tnt_smoke.png")

		pos.y = pos.y - 1 -- erase effect of adjusting for particle position.
		local pb = v_round(pos) -- use rounded position
		local pa = {x=pb.x, y=pb.y+1, z=pb.z}
		if minetest.get_node(pb).name == "air" and minetest.get_node(pa).name == "air" then
			if self.makes_bones_in_lava and self.makes_bones_in_lava == true then

				minetest.add_node(pb, {name="bones:bones_type2"})
				local meta = minetest.get_meta(pb)
				meta:set_int("protection_cancel", 1)

				minetest.add_node(pa, {name="fire:basic_flame"})
				minetest.check_for_falling(pb)
			else
				minetest.add_node(pb, {name="fire:basic_flame"})
			end
		end

		if check_for_death(self, "lava", {type = "environment",
			pos = pos, node = self.standing_in}) then return end
	end

	check_for_death(self, "", {type = "unknown"})
end



-- Arrow shooting code extracted into its own function [MustTest].
function mobs.shoot_arrow(self, vec)
	-- play shoot attack sound
	mob_sound(self, self.sounds.shoot_attack)

	local p = self.object:get_pos()

	p.y = p.y + (self.collisionbox[2] + self.collisionbox[5]) / 2

	if minetest.registered_entities[self.arrow] then

		local obj = minetest.add_entity(p, self.arrow)
		if not obj then return end -- Sanity check.

		local ent = obj:get_luaentity()
		local amount = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
		local v = ent.velocity or 1 -- or set to default

		ent.switch = 1
		ent.owner_id = tostring(self.object) -- add unique owner id to arrow

		-- offset makes shoot aim accurate
		vec.y = vec.y + self.shoot_offset
		vec.x = vec.x * (v / amount)
		vec.y = vec.y * (v / amount)
		vec.z = vec.z * (v / amount)

		obj:set_velocity(vec)
	end
end



-- Target punching code extracted into its own function [MustTest].
function mobs.punch_target(self)
	if not self.attack then
		return
	end

	local s2 = self.object:get_pos()
	local p2 = self.attack:get_pos()

	p2.y = p2.y + 0.5
	s2.y = s2.y + 0.5

	if not line_of_sight(self, p2, s2) then
		return
	end

	-- play attack sound
	mob_sound(self, self.sounds.attack)
	local targetname = (self.attack:is_player() and self.attack:get_player_name() or "")

	-- punch player (or what player is attached to)
	local attached = self.attack:get_attach()
	if attached or default.player_attached[targetname] then
		-- Mob has a chance of removing the player from whatever they're attached to.
		if self.attack:is_player() and random(1, 5) == 1 then
			utility.detach_player_with_message(self.attack)
		elseif attached then
			self.attack = attached
		end
	end

	-- Don't bother the admin.
	if not gdac.player_is_admin(targetname) then
		local dmg1 = self.damage or 0
		local dmg2 = math_random(self.damage_min or 0, self.damage_max or 0)
		local dmg = dmg1
		if dmg2 > dmg1 then
			dmg = dmg2
		end

		self.attack:punch(self.object, 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = dmg}
		}, nil)

		ambiance.sound_play("default_punch", self.attack:get_pos(), 2.0, 30)
	end

	-- Tell everyone about the death [MustTest].
	if self.attack:is_player() and self.attack:get_hp() <= 0 then
		mob_killed_player(self, self.attack)
		self.attack = nil -- stop attacking
	end
end



-- Remove block if possible [MustTest].
local function try_break_block(self, s)
	s = v_round(s)

	local node1 = minetest.get_node(s).name
	local ndef1 = minetest.registered_nodes[node1]

	-- Don't destroy player's bones [MustTest]!
	if (not ndef1) or node1 == "ignore" or node1 == "bones:bones" then
		return false, "special"
	end

	if (ndef1.groups.level or 0) > (self.max_node_dig_level or 1) then
		return false, "unbreakable"
	end

	if ndef1.groups.unbreakable or ndef1.groups.liquid or ndef1.groups.immovable then
		return false, "unbreakable"
	end

	if node1 ~= "air" and minetest.test_protection(s, "") then
		return false, "protected"
	end

	if node1 == "air" then
		return true
	end

	-- Can't do this check, many, many nodes use these callbacks [MustTest].
	--if ndef1.on_construct or ndef1.after_construct or ndef1.on_blast then
	--	return
	--end

	local oldnode = minetest.get_node(s)
	minetest.set_node(s, {name = "air"})

	-- Run script hook
	for _, callback in ipairs(minetest.registered_on_dignodes) do
		-- Deepcopy pos, oldnode, because callback can modify them
		callback(table.copy(s), table.copy(oldnode), self.object)
	end

	minetest.check_for_falling(s)

	-- This function takes both nodetables and nodenames.
	-- Pass node names, because passing a node table gives wrong results.
	local drops = minetest.get_node_drops(oldnode.name, "")

	for _, item in pairs(drops) do
		local p = {
			x = s.x + math_random()/2 - 0.25,
			y = s.y + math_random()/2 - 0.25,
			z = s.z + math_random()/2 - 0.25,
		}
		minetest.add_item(p, item)
	end

	return true -- success!
end



-- jump if facing a solid node (not fences or gates)
local function do_jump(self, break_blocks)

	if not self.jump
	or self.jump_height == 0
	or self.fly
	or self.child
	or self.order == "stand" then
		return false
	end

	self.facing_fence = false

	-- something stopping us while moving?
	if self.state ~= "stand"
	and get_velocity(self) > 0.5
	and self.object:get_velocity().y ~= 0 then
		return false
	end

	local pos = self.object:get_pos()
	local yaw = self.object:get_yaw()

	-- sanity check
	if not yaw then return false end

	-- we can only jump if standing on solid node
	if minetest.registered_nodes[self.standing_on].walkable == false then
		return false
	end

	-- where is front
	local dir_x = -sin(yaw) * (self.collisionbox[4] + 0.5)
	local dir_z = cos(yaw) * (self.collisionbox[4] + 0.5)

	-- set y_pos to base of mob
	pos.y = pos.y + self.collisionbox[2]

	-- what is in front of mob?
	local nod = node_ok({
		x = pos.x + dir_x,
		y = pos.y + 0.5,
		z = pos.z + dir_z
	})

	-- what is above and in front?
	local nodt = node_ok({
		x = pos.x + dir_x, y = pos.y + 1.5, z = pos.z + dir_z
	})

	local blocked = minetest.registered_nodes[nodt.name].walkable

	-- are we facing a fence or wall
	if nod.name:find("fence") or nod.name:find("gate") or nod.name:find("wall") then
		self.facing_fence = true
	end
--[[
print("on: " .. self.standing_on
	.. ", front: " .. nod.name
	.. ", front above: " .. nodt.name
	.. ", blocked: " .. (blocked and "yes" or "no")
	.. ", fence: " .. (self.facing_fence and "yes" or "no")
)
]]

	if (self.walk_chance == 0 or minetest.registered_items[nod.name].walkable)
			and not blocked and not self.facing_fence and nod.name ~= node_snow then

		if break_blocks then
			-- What is above mob's head [MustTest]?
			local pa = {x = pos.x, y = pos.y + 2.5, z = pos.z}
			local noda = node_ok(pa)

			-- Is mob prevented from jumping upward [MustTest]?
			if minetest.registered_nodes[noda.name].walkable then
				if try_break_block(self, pa) then
					self.path.putnode_timer = 1
				end
			end

			-- What is above and in front of mob's head [MustTest]?
			local pa = {x = pos.x + dir_x, y = pos.y + 2.5, z = pos.z + dir_z}
			local noda = node_ok(pa)

			-- Is mob prevented from jumping upward [MustTest]?
			if minetest.registered_nodes[noda.name].walkable then
				if try_break_block(self, pa) then
					self.path.putnode_timer = 1
				end
			end
		end

		local v = self.object:get_velocity()

		v.y = self.jump_height

		set_animation(self, "jump") -- only when defined

		self.object:set_velocity(v)

		-- when in air move forward
		minetest.after(0.3, function(self, v)
			if self.object:get_luaentity() then
				self.object:set_acceleration({
					x = v.x * 2,--1.5,
					y = 0,
					z = v.z * 2,--1.5
				})
			end
		end, self, v)

		if get_velocity(self) > 0 then
			mob_sound(self, self.sounds.jump)
		end

		self.jump_count = 0

		return true
	end

	-- if blocked for 3 counts then turn
	if not self.following and (self.facing_fence or blocked) then

		self.jump_count = (self.jump_count or 0) + 1

		if self.jump_count > 2 then

			local yaw = self.object:get_yaw() or 0
			local turn = random(0, 2) + 1.35

			yaw = set_yaw(self, yaw + turn, 12)

			self.jump_count = 0
		end
	end

	return false
end



-- Blast damage to entities nearby (modified from TNT mod).
local function entity_physics(pos, radius)
	radius = radius * 2

	local objs = minetest.get_objects_inside_radius(pos, radius)
	local obj_pos, dist

	for n = 1, #objs do

		obj_pos = objs[n]:get_pos()

		dist = get_distance(pos, obj_pos)
		if dist < 1 then dist = 1 end

		local damage = floor((4 / dist) * radius)
		local ent = objs[n]:get_luaentity()

		-- punches work on entities and players
		objs[n]:punch(objs[n], 1.0, {
			full_punch_interval = 1.0,
			damage_groups = {fleshy = damage},
		}, pos)
	end
end



-- Should mob follow what I'm holding?
local function follow_holding(self, clicker)
	local item = clicker:get_wielded_item()
	local t = type(self.follow)

	-- single item
	if t == "string"
	and item:get_name() == self.follow then
		return true

	-- multiple items
	elseif t == "table" then

		for no = 1, #self.follow do

			if self.follow[no] == item:get_name() then
				return true
			end
		end
	end

	return false
end



-- find two animals of same type and breed if nearby and horny
local function breed(self)

	-- child takes 240 seconds before growing into adult
	if self.child == true then

		self.hornytimer = self.hornytimer + 1

		if self.hornytimer > 240 then

			self.child = false
			self.hornytimer = 0

			self.object:set_properties({
				textures = self.base_texture,
				mesh = self.base_mesh,
				visual_size = self.base_size,
				collisionbox = self.base_colbox,
				selectionbox = self.base_selbox,
			})

			-- custom function when child grows up
			if self.on_grown then
				self.on_grown(self)
			else
				-- jump when fully grown so as not to fall into ground
				self.object:set_velocity({
					x = 0,
					y = self.jump_height,
					z = 0
				})
			end
		end

		return
	end

	-- horny animal can mate for 40 seconds,
	-- afterwards horny animal cannot mate again for 200 seconds
	if self.horny == true
	and self.hornytimer < 240 then

		self.hornytimer = self.hornytimer + 1

		if self.hornytimer >= 240 then
			self.hornytimer = 0
			self.horny = false
		end
	end

	-- find another same animal who is also horny and mate if nearby
	if self.horny == true
	and self.hornytimer <= 40 then

		local pos = self.object:get_pos()

		effect({x = pos.x, y = pos.y + 1, z = pos.z}, 8, "heart.png", 3, 4, 1, 0.1)

		local objs = minetest.get_objects_inside_radius(pos, 3)
		local num = 0
		local ent = nil

		for n = 1, #objs do

			ent = objs[n]:get_luaentity()

			-- check for same animal with different colour
			local canmate = false

			if ent then

				if ent.name == self.name then
					canmate = true
				else
					local entname = string.split(ent.name,":")
					local selfname = string.split(self.name,":")

					if entname[1] == selfname[1] then
						entname = string.split(entname[2],"_")
						selfname = string.split(selfname[2],"_")

						if entname[1] == selfname[1] then
							canmate = true
						end
					end
				end
			end

			if ent
			and canmate == true
			and ent.horny == true
			and ent.hornytimer <= 40 then
				num = num + 1
			end

			-- found your mate? then have a baby
			if num > 1 then

				self.hornytimer = 41
				ent.hornytimer = 41

				-- spawn baby
				minetest.after(5, function(self, ent)

					if not self.object:get_luaentity() then
						return
					end

					-- custom breed function
					if self.on_breed then

						-- when false skip going any further
						if self.on_breed(self, ent) == false then
								return
						end
					else
						effect(pos, 15, "tnt_smoke.png", 1, 2, 2, 15, 5)
					end

					local mob = minetest.add_entity(pos, self.name)
					local ent2 = mob:get_luaentity()
					local textures = self.base_texture

					-- using specific child texture (if found)
					if self.child_texture then
						textures = self.child_texture[1]
					end

					-- and resize to half height
					mob:set_properties({
						textures = textures,
						visual_size = {
							x = self.base_size.x * .5,
							y = self.base_size.y * .5,
						},
						collisionbox = {
							self.base_colbox[1] * .5,
							self.base_colbox[2] * .5,
							self.base_colbox[3] * .5,
							self.base_colbox[4] * .5,
							self.base_colbox[5] * .5,
							self.base_colbox[6] * .5,
						},
						selectionbox = {
							self.base_selbox[1] * .5,
							self.base_selbox[2] * .5,
							self.base_selbox[3] * .5,
							self.base_selbox[4] * .5,
							self.base_selbox[5] * .5,
							self.base_selbox[6] * .5,
						},
					})
					-- tamed and owned by parents' owner
					ent2.child = true
					ent2.tamed = true
					ent2.owner = self.owner
				end, self, ent)

				num = 0

				break
			end
		end
	end
end



-- find and replace what mob is looking for (grass, wheat etc.)
local function replace(self, pos)

	if not mobs_griefing
	or not self.replace_rate
	or not self.replace_what
	or self.child == true
	or self.object:get_velocity().y ~= 0
	or random(1, self.replace_rate) > 1 then
		return
	end

	local what, with, y_offset

	if type(self.replace_what[1]) == "table" then

		local num = random(#self.replace_what)

		what = self.replace_what[num][1] or ""
		with = self.replace_what[num][2] or ""
		y_offset = self.replace_what[num][3] or 0
	else
		what = self.replace_what
		with = self.replace_with or ""
		y_offset = self.replace_offset or 0
	end

	pos.y = pos.y + y_offset

	local range = self.replace_range or 1
	local target = minetest.find_node_near(pos, range, what)

	if target then

		-- Do not disturb protected stuff.
		if minetest.test_protection(target, "") then return end

-- print ("replace node = ".. minetest.get_node(pos).name, pos.y)

		local oldnode = {name = what}
		local newnode = {name = with}
		local on_replace_return

		if self.on_replace then
			on_replace_return = self.on_replace(self, target, oldnode, newnode)
		end

		if on_replace_return ~= false then

			minetest.add_node(target, {name = with})

			-- when cow/sheep eats grass, replace wool and milk
			if self.gotten == true then
				self.gotten = false
				self.object:set_properties(self)
			end
		end
	end
end



-- Check if daytime and also if mob is docile during daylight hours.
local function day_docile(self)
	if self.docile_by_day == false then
		return false
	elseif self.docile_by_day == true
	and self.time_of_day > 0.2
	and self.time_of_day < 0.8 then
		return true
	end
end



local function highlight_path(self)
	if not mobs.debug_paths then
		return
	end

	-- show path using particles
	if self.path.way and #self.path.way > 0 then
		--print ("-- path length:" .. tonumber(#self.path.way))
		local pname = "singleplayer"
		if not minetest.is_singleplayer() then
			pname = gdac.name_of_admin
		end

		for _,pos in pairs(self.path.way) do
			utility.original_add_particle({
				playername = pname,
				pos = pos,
				velocity = {x=0, y=0, z=0},
				acceleration = {x=0, y=0, z=0},
				expirationtime = 3,
				size = 4,
				collisiondetection = false,
				vertical = false,
				texture = "heart.png",
			})
		end
	end
end



-- Shall return 'true' if blockage was fully removed [MustTest].
local function try_dig_doorway(self, s)
	local s = table.copy(s)
	s.y = s.y + self.collisionbox[2] + 0.5
	local yaw1 = self.object:get_yaw() + pi / 2
	local p1 = {
		x = s.x + cos(yaw1),
		y = s.y,
		z = s.z + sin(yaw1)
	}
	p1 = v_round(p1)

	--report(minetest.get_node(p1).name)

	-- First, try to break the block above.
	-- If we can't do this, there's no point in trying to break the bottom block.
	-- That would also interfere with us closing the bottom hole up.
	p1.y = p1.y + 1

	--report(minetest.get_node(p1).name)

	local b1
	local b2 = try_break_block(self, p1)

	p1.y = p1.y - 1

	-- Sometimes, a mob is trying to path through a 1x1 hole, where the block
	-- above is undiggable for some reason. I can do something clever here:
	-- if the bottom hole is air, I can close it up. This way, the next time the
	-- pathfinder runs, it will not try to go through this hole. [MustTest]
	if not b2 then
		local nn = minetest.get_node(p1).name
		if nn == "air" or nn == "default:snow" then
			minetest.set_node(p1, {name = (self.place_node or node_pathfiner_place)})
			local meta = minetest.get_meta(p1)
			meta:set_int("protection_cancel", 1)
		end
	else
		b1 = try_break_block(self, p1)
	end

	--report(tostring(b1) .. ", " .. tostring(b2))
	return (b1 and b2)
end



-- path finding and smart mob routine by rnd,
-- line_of_sight and other edits by Elkien3,
-- updated for Enyekala server by MustTest.
local function smart_mobs(self, s, p, dist, dtime)

	-- Timer is required to prevent mob from spamming blocks [MustTest].
	self.path.putnode_timer = (self.path.putnode_timer or 0) - dtime

	-- Timer for preventing 'minetest.find_path' spam [MustTest].
	self.path.find_path_timer = self.path.find_path_timer - dtime

	local s1 = self.path.lastpos
	local target_pos = p

	-- Record mob's last position once every second [MustTest].
	self.path.pos_rec_timer = self.path.pos_rec_timer + dtime
	if self.path.pos_rec_timer >= 1 then
		self.path.lastpos = {x = s.x, y = s.y, z = s.z}
		self.path.pos_rec_timer = 0
	end

	-- Is mob becoming stuck (i.e., has it not moved in the last 1 second)?
	if (abs(s1.x - s.x) + abs(s1.z - s.z)) < 0.25 then
		self.path.stuck_timer = self.path.stuck_timer + dtime
	else
		self.path.stuck_timer = 0
	end

	-- Perform the LOS test not more than once per 1/2 second [MustTest].
	-- There is no reason to call this every globalstep.
	local use_pathfind = false
	local has_lineofsight = self.path.have_los

	self.path.los_check = self.path.los_check - dtime
	if self.path.los_check <= 0 then
		has_lineofsight = minetest.line_of_sight(
			{x = s.x, y = (s.y + 0.5), z = s.z},
			{x = target_pos.x, y = (target_pos.y + 1), z = target_pos.z}, 0.2)

		self.path.have_los = has_lineofsight
		self.path.los_check = 0.5
	end

	-- I'm stuck, search for path.
	if not has_lineofsight then
		-- Cannot see target [MustTest]!
		use_pathfind = true
		self.path.los_counter = 0
	else
		self.path.los_counter = self.path.los_counter + dtime
		if self.path.los_counter > 5 then
			local y_dist = abs(s.y - target_pos.y)
			-- I've been able to see the target for several consecutive seconds [MustTest].
			if y_dist <= 0.5 then
				-- Also, I'm on the same level as the target.
				--report("have LOS - canceling pathfind")
				use_pathfind = false
				self.path.following = false
				self.path.los_counter = 0
			end

			-- But if I'm stuck even though I have LOS, attempt pathfind.
			if self.path.stuck_timer >= 2 then
				--report("stuck with LOS - pathfinding")
				use_pathfind = true
			end
		end
	end

	-- What do we do if the mob got stuck while following this path [MustTest]?
	if self.path.stuck_timer > stuck_timeout then
		if self.path.following then
			--report("stuck timeout - was following path")
			highlight_path(self)
			-- The mob got stuck while following a path. This can happen if the path
			-- goes through a 1x1 node hole, which the mob is too big to fit through.
			-- I can try to dig that block. [MustTest]
			local removed_blockage = false
			if (self.pathfinding or 0) >= 2 then
				removed_blockage = try_dig_doorway(self, s)
			end
			if not removed_blockage then
				--report("blockage not removed")
				use_pathfind = true
				self.path.stuck_timer = 0
				self.path.following = false
			else
				--report("blockage removed")
				self.path.stuck_timer = 0
				self.stuck_path_timeout = (((self.path.way and #self.path.way) or 0) * 0.75)
			end
		else
			--report("stuck timeout - but not following a path")
			-- Not currently following a path, but one exists which we recently abandoned?
			if self.path.way and #self.path.way >= 5 then
				local tar = self.path.way[1]
				if v_distance(tar, s) <= 1.5 then
					-- Continue following existing path.
					--report("following existing path")
					self.path.following = true
					self.stuck_path_timeout = (#self.path.way * 0.75)
					self.path.stuck_timer = 0
					self.path.los_counter = 0
				end
			else
				use_pathfind = true
				self.path.stuck_timer = 0
			end
		end
	end

	-- What do we do if the mob has been following this path too long [MustTest]?
	-- Note: the path timeout is based on the length of the path.
	if (self.path.stuck_timer > (self.stuck_path_timeout or 0) and self.path.following) then
		--report("path timeout")
		use_pathfind = true
		self.path.stuck_timer = 0
		self.path.following = false
	end

	if not use_pathfind then
		return
	end

	-- If already following a path, don't search for a new one [MustTest].
	if self.path.following then
		return
	end

	-- lets try find a path, first take care of positions
	-- since pathfinder is very sensitive
	local sheight = self.collisionbox[5] - self.collisionbox[2]

	-- round position to center of node to avoid stuck in walls
	-- also adjust height for player models!
	s.x = floor(s.x + 0.5)
	s.z = floor(s.z + 0.5)

	local ssight, sground = minetest.line_of_sight(s, {
		x = s.x, y = s.y - 4, z = s.z}, 1)

	-- determine node above ground
	if not ssight then
		s.y = sground.y + 1
	end

	local p1 = self.attack:get_pos()
	p1 = v_round(p1)

	local dropheight = 6

	if self.fear_height ~= 0 then dropheight = (self.fear_height - 1) end

	local jumpheight = 0

	if self.jump and self.jump_height >= 4 then
		jumpheight = min(ceil(self.jump_height / 4), 4)
	elseif self.stepheight > 0.5 then
		jumpheight = 1
	end

	if self.path.find_path_timer <= 0 then
		--report("searching for path")
		local radius = self.pathing_radius or 16
		local pway = minetest.find_path(s, p1, radius, jumpheight, dropheight, "A*")

		if not pway then
			-- If I couldn't find path, don't try again for a few seconds.
			--report("path not found")
			self.path.way = nil
			self.path.find_path_timer = 2
			self.path.stuck_timer = 0
		else
			--report("path found")
			self.path.way = pway
			self.path.find_path_timer = 0
			self.path.stuck_timer = 0
		end
	end

	-- Show path using particles.
	highlight_path(self)

	self.state = ""

	if self.attack then
		do_attack(self, self.attack)
	end

	-- no path found, try something else
	if not self.path.way then
		self.path.following = false

		-- lets make way by digging/building if not accessible
		if (self.pathfinding or 0) >= 2 and mobs_griefing and self.path.putnode_timer <= 0 then

			-- is player more than 1 block higher than mob?
			if p1.y >= (s.y + 0.9) and not self.fly then

				-- build upwards
				-- not necessary to check protection if only placing nodes [MustTest]
				-- timer is used to prevent mob from spamming lots of blocks
				s = v_round(s)

				local canput = false

				if self.path.putnode_timer <= 0 then
					local node = minetest.get_node(s)
					local ndef = minetest.registered_nodes[node.name]

					local prot = minetest.test_protection(s, "")

					if ndef and (ndef.buildable_to or ndef.groups.liquid) then
						canput = true
					end

					-- If protected, do not replace non-air nodes [MustTest].
					if prot and node.name ~= "air" then
						canput = false
					end
				end

				-- Assume mob is 2 blocks high so it digs above its head.
				-- Position is rounded, so we use a fixed integer.
				local sheight = 2
				s.y = s.y + sheight

				local success, reason = try_break_block(self, s)
				if success then
					self.path.putnode_timer = 1
					self.path.stuck_timer = 0
				else
					if reason and (reason == "protected" or reason == "unbreakable") then
						-- I couldn't dig ceiling, so no point in trying to jump up!
						canput = false
					end
				end

				s.y = s.y - sheight

				if canput then

					-- Place node the mob likes, or use fallback.
					-- Disable protection for this node via meta [MustTest].
					minetest.add_node(s, {name = self.place_node or node_pathfiner_place})
					local meta = minetest.get_meta(s)
					meta:set_int("protection_cancel", 1)

					-- Note: do not force node to fall if it does not need to.
					minetest.check_for_falling(s)

					self.object:set_velocity({x = 0, y = 5, z = 0})

					-- Block placement min time [MustTest].
					self.path.putnode_timer = 1
					self.path.stuck_timer = 0
				end

			-- target is directly under the mob -- dig through floor!
			elseif abs(p1.x - s.x) < 0.2 and abs(p1.z - s.z) < 0.2 and p1.y < (s.y - 2) then

				s.y = s.y - 1
				local res = try_break_block(self, s)
				s.y = s.y + 1

				if not res then
					-- cannot dig, stop trying to get target.
					self.state = "stand"
					set_velocity(self, 0)
					set_animation(self, "stand")
					self.attack = nil
					self.v_start = false
					self.timer = 0
					self.blinktimer = 0
					self.path.way = nil
				end

				if res then
					self.path.putnode_timer = 1
					self.path.stuck_timer = 0
				end

				-- move to center of hole to try and fall down it
				local v = v_round(s)
				self.path.way = {
					[1]={x=v.x, y=v.y, z=v.z},
					[2]={x=v.x, y=v.y - 1, z=v.z},
				}
				self.path.following = true
				self.path.stuck_timer = 0
				self.path.los_counter = 0
				highlight_path(self)

			-- is player more than 1 block lower than mob
			elseif p1.y < (s.y - 0.9) then
				--report("digging down")
				-- dig down
				local s = self.object:get_pos()
				s.y = s.y + self.collisionbox[2] - 0.5
				s = v_round(s)
				--report(minetest.get_node(s).name)

				if try_break_block(self, s) then
					self.path.putnode_timer = 1

					-- Move toward the location supposedly dug.
					self.path.way = {
						[1]={x=s.x, y=s.y, z=s.z},
					}
					self.path.following = true
					self.path.stuck_timer = 0
					self.path.los_counter = 0
				end

				highlight_path(self)

			else -- dig 2 blocks to make door toward player direction
				if try_dig_doorway(self, s) then
					self.path.putnode_timer = 1
					self.path.stuck_timer = 0
				end
			end
		end

		-- Frustration! Can't find the path. :-(
		if random(1, 20) == 1 then
			mob_sound(self, self.sounds.random)
		end
	elseif s.y < p1.y and (not self.fly) then
		-- Note: self.path.way is valid if we get here [MustTest].
		-- Allow jump routine to break blocks [MustTest].
		local break_blocks = (self.pathfinding or 0) >= 2
		do_jump(self, break_blocks) -- Add jump to pathfinding.

		-- follow path now that it has it.
		self.path.following = true
		self.stuck_path_timeout = (#self.path.way * 0.75)
		self.path.stuck_timer = 0
		self.path.los_counter = 0
	else
		-- yay i found path
		if self.attack then
			mob_sound(self, self.sounds.war_cry)
		else
			mob_sound(self, self.sounds.random)
		end

		set_velocity(self, self.walk_velocity)

		-- follow path now that it has it
		self.path.following = true
		self.stuck_path_timeout = (#self.path.way * 0.75)
		self.path.stuck_timer = 0
		self.path.los_counter = 0
	end
end



-- specific attacks
local function specific_attack(list, what)

	-- no list so attack default (player, animals etc.)
	if list == nil then
		return true
	end

	-- is found entity on list to attack?
	for no = 1, #list do

		if list[no] == what then
			return true
		end
	end

	return false
end



-- general attack function for all mobs ==========
-- This function only executes once per second (per mob) [MustTest].
local function general_attack(self)

	-- return if already attacking, passive or docile during day
	if self.passive
	or self.state == "attack"
	or day_docile(self) then
		return
	end

	local s = self.object:get_pos()
	-- Stupid spurious errors.
	if not s then
		return
	end
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	-- remove entities we aren't interested in
	for n = 1, #objs do

		local ent = objs[n]:get_luaentity()

		-- are we a player?
		if objs[n]:is_player() then
			local pname = objs[n]:get_player_name()

			-- if player invisible or mob not setup to attack then remove from list
			if self.attack_players == false
			or (self.owner and self.type ~= "monster")
			or mobs.is_invisible(self, pname)
			or not specific_attack(self.specific_attack, "player")
			or minetest.check_player_privs(pname, {mob_respect=true}) then
				objs[n] = nil
--print("- pla", n)
			end

			-- ignore dead players
			if objs[n] and objs[n]:get_hp() <= 0 then
				objs[n] = nil
			end

			-- If player nametag is off, reduce range at which mob can see them.
			if objs[n] and player_labels.query_nametag_onoff(pname) == false then
				local r = self.view_range * 0.8
				local p = objs[n]:get_pos()
				if vector_distance(p, s) > r then
					objs[n] = nil
				end
			end

		-- or are we a mob?
		elseif ent and ent._cmi_is_mob then

			-- remove mobs not to attack
			if self.name == ent.name
			or (not self.attack_animals and ent.type == "animal")
			or (not self.attack_monsters and ent.type == "monster")
			or (not self.attack_npcs and ent.type == "npc")
			or not specific_attack(self.specific_attack, ent.name) then
				objs[n] = nil
--print("- mob", n, self.name, ent.name)
			end

		-- remove all other entities
		else
--print(" -obj", n)
			objs[n] = nil
		end
	end

	local p, sp, dist, min_player
	local min_dist = self.view_range + 1

	-- Go through remaining entities and select closest.
	-- Have to use ipairs because array has holes [MustTest].
	for _,player in pairs(objs) do

		p = player:get_pos()
		sp = s

		dist = get_distance(p, s)

		-- aim higher to make looking up hills more realistic
		p.y = p.y + 1
		sp.y = sp.y + 1

		-- choose closest player to attack that isnt self
		if dist ~= 0 and dist < min_dist and line_of_sight(self, sp, p, 0.5) == true then
			min_dist = dist
			min_player = player
		end
	end

	-- attack closest player or mob
	if min_player and random(1, 100) < (self.attack_chance or 95) then
		do_attack(self, min_player)
	elseif not min_player and random(1, 100) < (self.hunt_chance or 5) then
		-- If mob is set up to hunt players, randomly select a nearby player.
		-- Only do this if we didn't get a target the normal way [MustTest].

		-- Build list of candidate targets.
		local candidates = {}
		for k, v in pairs(objs) do
			if v:is_player() then
				if not mobs.is_invisible(self, v:get_player_name()) then
					candidates[#candidates + 1] = v
				end
			end
		end

		-- Pick random target.
		-- Note: this will often happen when target is not in LOS of the mob, so if
		-- possible, we only want targets within the mob's pathfinding range.
		if #candidates > 0 then
			local target = candidates[random(1, #candidates)]
			if v_distance(s, target:get_pos()) < (self.pathing_radius or self.view_range or 16) then
				do_attack(self, target)
			end
		end
	end
end



-- specific runaway
local function specific_runaway(list, what)

	-- no list so do not run
	if list == nil then
		return false
	end

	-- found entity on list to attack?
	for no = 1, #list do

		if list[no] == what then
			return true
		end
	end

	return false
end



-- find someone to runaway from
local function runaway_from(self)

	if not self.runaway_from then
		return
	end

	-- If non-passive mob is attacking, then it will not run away right now.
	if self.state == "attack" and not self.passive then
		return
	end

	local s = self.object:get_pos()
	local p, sp, dist, pname
	local player, obj, min_player, name
	local min_dist = self.view_range + 1
	local objs = minetest.get_objects_inside_radius(s, self.view_range)

	for n = 1, #objs do
		-- Ignore dead players.
		if objs[n]:is_player() then
			if objs[n]:get_hp() > 0 then
				pname = objs[n]:get_player_name()
				if mobs.is_invisible(self, pname) or self.owner == pname then
					name = ""
				else
					player = objs[n]
					name = "player"
				end
			end
		else
			obj = objs[n]:get_luaentity()

			if obj then
				-- Ignore entities which are not mobs.
				if obj._cmi_is_mob then
					player = obj.object
					name = obj.name or ""
				end
			end
		end

		-- Find specific mob to runaway from.
		if name ~= "" and name ~= self.name and
				specific_runaway(self.runaway_from, name) then

			p = player:get_pos()
			sp = s

			-- aim higher to make looking up hills more realistic
			p.y = p.y + 1
			sp.y = sp.y + 1

			dist = get_distance(p, s)

			-- choose closest player/mob to runaway from
			if dist < min_dist
					and line_of_sight(self, sp, p, 2) == true then
				min_dist = dist
				min_player = player
			end
		end
	end

	if min_player then

		local lp = player:get_pos()

		local yaw = compute_yaw_to_target(self, lp, s)
		yaw = yaw + pi
		yaw = set_yaw(self, yaw, 4)

		self.state = "runaway"
		self.runaway_timer = 3
		self.following = nil
	end
end



-- follow player if owner or holding item, if fish outta water then flop
local function follow_flop(self)

	-- find player to follow
	if (self.follow ~= ""
	or self.order == "follow")
	and not self.following
	and self.state ~= "attack"
	and self.state ~= "runaway" then

		local s = self.object:get_pos()
		local players = minetest.get_connected_players()

		for n = 1, #players do

			if get_distance(players[n]:get_pos(), s) < self.view_range
					and not mobs.is_invisible(self, players[n]:get_player_name()) then

				self.following = players[n]

				break
			end
		end
	end

	if self.type == "npc"
	and self.order == "follow"
	and self.state ~= "attack"
	and self.owner ~= "" then

		-- npc stop following player if not owner
		if self.following
		and self.owner
		and self.owner ~= self.following:get_player_name() then
			self.following = nil
		end
	else
		-- stop following player if not holding specific item
		if self.following
		and self.following:is_player()
		and follow_holding(self, self.following) == false then
			self.following = nil
		end

	end

	-- follow that thing
	if self.following then

		local s = self.object:get_pos()
		local p

		if self.following:is_player() then

			p = self.following:get_pos()

		elseif self.following.object then

			p = self.following.object:get_pos()
		end

		if p then

			local dist = get_distance(p, s)

			-- dont follow if out of range
			if dist > self.view_range then
				self.following = nil
			else
				local yaw = compute_yaw_to_target(self, p, s)
				yaw = set_yaw(self, yaw, 6)

				-- anyone but standing npc's can move along
				if dist > self.reach
				and self.order ~= "stand" then

					set_velocity(self, self.walk_velocity or 0)

					if self.walk_chance ~= 0 then
						set_animation(self, "walk")
					end
				else
					set_velocity(self, 0)
					set_animation(self, "stand")
				end

				return
			end
		end
	end

	-- swimmers flop when out of their element, and swim again when back in
	if self.fly then
		local s = self.object:get_pos()
		if not flight_check(self, s) then

			self.state = "flop"
			self.object:set_velocity({x = 0, y = -5, z = 0})

			set_animation(self, "stand")

			return
		elseif self.state == "flop" then
			self.state = "stand"
		end
	end
end



-- dogshoot attack switch and counter function
local function dogswitch(self, dtime)

	-- switch mode not activated
	if not self.dogshoot_switch
	or not dtime then
		return 0
	end

	self.dogshoot_count = self.dogshoot_count + dtime

	if (self.dogshoot_switch == 1
	and self.dogshoot_count > self.dogshoot_count_max)
	or (self.dogshoot_switch == 2
	and self.dogshoot_count > self.dogshoot_count2_max) then

		self.dogshoot_count = 0

		if self.dogshoot_switch == 1 then
			self.dogshoot_switch = 2
		else
			self.dogshoot_switch = 1
		end
	end

	return self.dogshoot_switch
end


-- execute current state (stand, walk, run, attacks)
local function do_states(self, dtime)

	local yaw = self.object:get_yaw()

	-- Stupid spurious bugs.
	if not yaw then
		return
	end

	if self.state == "stand" then

		if random(1, 4) == 1 then

			local lp = nil
			local s = self.object:get_pos()
			local objs = minetest.get_objects_inside_radius(s, 3)

			for n = 1, #objs do

				if objs[n]:is_player() then
					lp = objs[n]:get_pos()
					break
				end
			end

			-- look at any players nearby, otherwise turn randomly
			if lp then
				local yaw = compute_yaw_to_target(self, lp, s)
			else
				yaw = yaw + random(-0.5, 0.5)
			end

			yaw = set_yaw(self, yaw, 8)
		end

		set_velocity(self, 0)
		set_animation(self, "stand")

		-- npc's ordered to stand stay standing
		--if self.type ~= "npc"
		if self.order ~= "stand" then

			if self.walk_chance ~= 0
			and self.facing_fence ~= true
			and random(1, 100) <= self.walk_chance
			and is_at_cliff(self) == false then

				set_velocity(self, self.walk_velocity or 0)
				self.state = "walk"
				set_animation(self, "walk")

				--[[ fly up/down randomly for flying mobs
				if self.fly and random(1, 100) <= self.walk_chance then

					local v = self.object:get_velocity()
					local ud = random(-1, 2) / 9

					self.object:set_velocity({x = v.x, y = ud, z = v.z})
				end--]]
			end
		end

	elseif self.state == "walk" then

		local s = self.object:get_pos()
		local lp = nil

		-- is there something I need to avoid?
		if self.water_damage > 0
		and self.lava_damage > 0 then

			lp = minetest.find_node_near(s, 1, {"group:water", "group:lava"})

		elseif self.water_damage > 0 then

			lp = minetest.find_node_near(s, 1, {"group:water"})

		elseif self.lava_damage > 0 then

			lp = minetest.find_node_near(s, 1, {"group:lava"})
		end

		if lp then

			-- if mob in water or lava then look for land
			local ndef = minetest.reg_ns_nodes[self.standing_in]
			if (self.lava_damage and ndef and ndef.groups.lava)
				or (self.water_damage and ndef and ndef.groups.water) then

				lp = minetest.find_node_near(s, 5, {"group:soil", "group:stone",
					"group:sand", node_ice, node_snowblock})

				-- did we find land?
				if lp then
					local yaw = compute_yaw_to_target(self, lp, s)

					-- look towards land and jump/move in that direction
					yaw = set_yaw(self, yaw, 6)
					do_jump(self)
					set_velocity(self, self.walk_velocity or 0)
				else
					yaw = yaw + random(-0.5, 0.5)
				end

			else
				local yaw = compute_yaw_to_target(self, lp, s)
			end

			yaw = set_yaw(self, yaw, 8)

		-- otherwise randomly turn
		elseif random(1, 100) <= 30 then

			yaw = yaw + random(-0.5, 0.5)

			yaw = set_yaw(self, yaw, 8)
		end

		-- stand for great fall in front
		local temp_is_cliff = is_at_cliff(self)

		if self.facing_fence == true
		or temp_is_cliff
		or random(1, 100) <= 30 then

			set_velocity(self, 0)
			self.state = "stand"
			set_animation(self, "stand")
		else
			set_velocity(self, self.walk_velocity or 0)

			if flight_check(self)
			and self.animation
			and self.animation.fly_start
			and self.animation.fly_end then
				set_animation(self, "fly")
			else
				set_animation(self, "walk")
			end
		end

	-- runaway when punched
	elseif self.state == "runaway" then

		self.runaway_timer = self.runaway_timer + 1

		-- stop after 5 seconds or when at cliff
		if self.runaway_timer > 5
		or is_at_cliff(self) then
			self.runaway_timer = 0
			set_velocity(self, 0)
			self.state = "stand"
			set_animation(self, "stand")
		else
			set_velocity(self, self.sprint_velocity or 0)
			set_animation(self, "walk")
		end

	-- attack routines (explode, dogfight, shoot, dogshoot)
	elseif self.state == "attack" then

		-- calculate distance from mob and enemy
		local s = self.object:get_pos()
		local p = self.attack and self.attack:get_pos() or s
		local dist = get_distance(p, s)

		-- stop attacking if player invisible or out of range
		if dist > self.view_range
		or not self.attack
		or not self.attack:get_pos()
		or self.attack:get_hp() <= 0
		or (self.attack:is_player() and mobs.is_invisible(self, self.attack:get_player_name() )) then

--			print(" ** stop attacking **", dist, self.view_range)
			self.state = "stand"
			set_velocity(self, 0)
			set_animation(self, "stand")
			self.attack = nil
			self.v_start = false
			self.timer = 0
			self.blinktimer = 0
			self.path.way = nil

			return
		end

		if self.attack_type == "explode" then
			local yaw = compute_yaw_to_target(self, p, s)
			yaw = set_yaw(self, yaw)

			local node_break_radius = self.explosion_radius or 1
			local entity_damage_radius = self.explosion_damage_radius
					or (node_break_radius * 2)

			-- start timer when in reach and line of sight
			if not self.v_start
			and dist <= self.reach
			and line_of_sight(self, s, p, 2) then

				self.v_start = true
				self.timer = 0
				self.blinktimer = 0
				mob_sound(self, self.sounds.fuse)
--				print ("=== explosion timer started", self.explosion_timer)

			-- stop timer if out of reach or direct line of sight
			elseif self.allow_fuse_reset
			and self.v_start
			and (dist > self.reach
					or not line_of_sight(self, s, p, 2)) then
				self.v_start = false
				self.timer = 0
				self.blinktimer = 0
				self.blinkstatus = false
				self.object:settexturemod("")
			end

			-- walk right up to player unless the timer is active
			if self.v_start and (self.stop_to_explode or dist < 1.5) then
				set_velocity(self, 0)
			else
				set_velocity(self, self.run_velocity or 0)
			end

			if self.animation and self.animation.run_start then
				set_animation(self, "run")
			else
				set_animation(self, "walk")
			end

			if self.v_start then

				self.timer = self.timer + dtime
				self.blinktimer = (self.blinktimer or 0) + dtime

				if self.blinktimer > 0.2 then

					self.blinktimer = 0

					if self.blinkstatus then
						self.object:settexturemod("")
					else
						self.object:settexturemod("^[brighten")
					end

					self.blinkstatus = not self.blinkstatus
				end

--				print ("=== explosion timer", self.timer)

				if self.timer > self.explosion_timer then

					local pos = self.object:get_pos()

					-- dont damage anything if area protected or next to water
					if minetest.find_node_near(pos, 1, {"group:water"})
					or minetest.test_protection(pos, "") then

						node_break_radius = 1
					end

					-- Mark for removal as last action on mob_step().
					self.mkrm = true

					if minetest.get_modpath("tnt") and tnt and tnt.boom then

						tnt.boom(pos, {
							radius = node_break_radius,
							damage_radius = entity_damage_radius,
							sound = self.sounds.explode,
						})
					else

						minetest.sound_play(self.sounds.explode, {
							pos = pos,
							gain = 1.0,
							max_hear_distance = self.sounds.distance or 32
						}, true)

						entity_physics(pos, entity_damage_radius)
						effect(pos, 32, "tnt_smoke.png", nil, nil, node_break_radius, 1, 0)
					end

					return
				end
			end

		elseif self.attack_type == "dogfight"
				or (self.attack_type == "dogshoot" and dogswitch(self, dtime) == 2)
				or (self.attack_type == "dogshoot" and dist <= self.reach
					and dogswitch(self) == 0) then

			if self.fly and dist > self.reach then

				local p1 = s
				local me_y = floor(p1.y)
				local p2 = p
				local p_y = floor(p2.y + 1)
				local v = self.object:get_velocity()

				if flight_check(self, s) then

					if me_y < p_y then

						self.object:set_velocity({
							x = v.x,
							y = 1 * self.walk_velocity,
							z = v.z
						})

					elseif me_y > p_y then

						self.object:set_velocity({
							x = v.x,
							y = -1 * self.walk_velocity,
							z = v.z
						})
					end
				else
					if me_y < p_y then

						self.object:set_velocity({
							x = v.x,
							y = 0.01,
							z = v.z
						})

					elseif me_y > p_y then

						self.object:set_velocity({
							x = v.x,
							y = -0.01,
							z = v.z
						})
					end
				end

			end

			-- rnd: new movement direction
			if self.path.following
			and self.path.way
			and self.attack_type ~= "dogshoot" then

				-- No very long paths [MustTest].
				-- Note that the engine is now a lot better at pathfinding, so bad paths
				-- aren't often generated anymore. I can leave the limit fairly high.
				local max_len = (self.pathing_radius or 16) * 4
				if #self.path.way > max_len or dist < self.reach then
					--report("path too long: " .. #self.path.way)
					self.path.following = false
					self.path.way = nil
					self.path.find_path_timer = 2
					return
				end

				local p1 = self.path.way[1]

				if not p1 then
					self.path.following = false
					return
				end

				--if abs(p1.x-s.x) + abs(p1.z - s.z) < 0.6 then
				-- must use `get_distance' and not `abs' because waypoint may be vertical from mob
				if get_distance(p1, s) < 0.6 then
					-- reached waypoint, remove it from queue
					table.remove(self.path.way, 1)
				end

				-- set new temporary target
				p = {x = p1.x, y = p1.y, z = p1.z}
			end

			-- flag should be set if mob is directly over its target and therefore should move more slowly
			local overunder_waypoint = false

			-- is mob directly over or under the target?
			if abs(p.x - s.x) < 0.2 and abs(p.z - s.z) < 0.2 and abs(p.y - s.y) > 0.5 then
				-- mob is directly over or under its waypoint/target
				overunder_waypoint = true
			end

			local yaw = compute_yaw_to_target(self, p, s)
			yaw = set_yaw(self, yaw)

			-- move towards enemy if beyond mob reach
			if dist > (self.reach + (self.reach_ext or 0)) then

				-- path finding by rnd
				if self.pathfinding and self.pathfinding ~= 0 and enable_pathfinding then
					-- Always pass the real position of the target to Smart Mobs function [MustTest].
					local p = self.attack:get_pos()
					smart_mobs(self, s, p, dist, dtime)
				end

				-- distance padding to stop spinning mob
				local pad = abs(p.x - s.x) + abs(p.z - s.z)

				self.reach_ext = 0 -- extended ready off by default

				-- MustTest:
				-- Very, very rarely, a mob may FALSELY get stuck (as if at the edge of
				-- a cliff) while following a path. This is due to a slight error amount
				-- in the 'is_at_cliff' function. So if the mob is set to follow a path,
				-- we just ignore the cliff (the path should be safe anyway).
				if (is_at_cliff(self) or pad < 0.2) and not self.path.following then
					-- when on top of player extend reach slightly so player can
					-- still be attacked.
					self.reach_ext = 0.8

					set_velocity(self, 0)
					set_animation(self, "stand")
				else

					if overunder_waypoint then
						set_velocity(self, 0.1)
					else
						if not self.path.following then
							set_velocity(self, self.sprint_velocity or 0)
						else
							set_velocity(self, self.run_velocity or 0)
						end
					end

					if not overunder_waypoint then
						if self.animation and self.animation.run_start then
							set_animation(self, "run")
						else
							set_animation(self, "walk")
						end
					else
						set_animation(self, "stand")
					end
				end

				-- Punch target if within punching range even while moving [MustTest].
				if dist < (self.punch_reach or 0) then
					if self.timer > 1 then
						self.timer = 0

						mobs.punch_target(self)
					end
				end

			else -- rnd: if inside reach range

				self.path.stuck_timer = 0
				self.path.following = false -- not stuck anymore

				set_velocity(self, 0)

				if not self.custom_attack or self.custom_attack(self, p) == true then

					if self.timer > 1 then

						self.timer = 0
						set_animation(self, "punch")

						mobs.punch_target(self)
					end
				end
			end

		elseif self.attack_type == "shoot"
		or (self.attack_type == "dogshoot" and dogswitch(self, dtime) == 1)
		or (self.attack_type == "dogshoot" and dist > self.reach and dogswitch(self) == 0) then

			p.y = p.y - .5
			s.y = s.y + .5

			local dist = get_distance(p, s)
			local yaw = compute_yaw_to_target(self, p, s)
			local vec = { -- vec is needed elsewhere
				x = p.x - s.x,
				y = p.y - s.y,
				z = p.z - s.z
			}
			yaw = set_yaw(self, yaw)

			set_velocity(self, 0)

			if self.shoot_interval
			and self.timer > self.shoot_interval
			and random(1, 100) <= 60 then

				self.timer = 0
				set_animation(self, "shoot")

				mobs.shoot_arrow(self, vec)
			end
		end
	end
end



-- falling and fall damage
local function falling(self, pos)

	if self.fly then
		return
	end

	-- floating in water (or falling)
	local v = self.object:get_velocity()

	if v.y > 0 then

		-- apply gravity when moving up
		self.object:set_acceleration({
			x = 0,
			y = -10,
			z = 0
		})

	elseif v.y <= 0 and v.y > self.fall_speed then

		-- fall downwards at set speed
		self.object:set_acceleration({
			x = 0,
			y = self.fall_speed,
			z = 0
		})
	else
		-- stop accelerating once max fall speed hit
		self.object:set_acceleration({x = 0, y = 0, z = 0})
	end

	-- If in water then float up. Nil check.
	local ndef = self.standing_in and minetest.reg_ns_nodes[self.standing_in]
	if ndef and ndef.groups.water then
		if self.floats == 1 then
			self.object:set_acceleration({
				x = 0,
				y = -self.fall_speed / (max(1, v.y) ^ 8), -- 8 was 2
				z = 0
			})
		end
	else

		-- fall damage onto solid ground
		if self.fall_damage == 1
		and self.object:get_velocity().y == 0 then

			local d = (self.old_y or 0) - self.object:get_pos().y

			if d > 5 then

				self.health = self.health - floor(d - 5)

				effect(pos, 5, "tnt_smoke.png", 1, 2, 2, nil)

				if check_for_death(self, "fall", {type = "fall"}) then
					return
				end
			end

			self.old_y = self.object:get_pos().y
		end
	end
end



-- is Took Ranks mod active?
local tr = minetest.get_modpath("toolranks")

-- deal damage and effects when mob punched
local function mob_punch(self, hitter, tflp, tool_capabilities, dir)

	-- Record name of last attacker.
	self.last_attacked_by = (hitter and hitter:is_player() and hitter:get_player_name()) or ""

	-- Stop following path when hit [MustTest].
	if self.last_attacked_by ~= "" then
		-- Unless hitter is the mob's current target.
		if self.attack ~= hitter then
			self.path.following = false
			self.path.stuck_timer = 0.0
			self.path.los_counter = 0
		end
	end

	-- custom punch function
	if self.do_punch then

		-- when false skip going any further
		if self.do_punch(self, hitter, tflp, tool_capabilities, dir) == false then
			return
		end
	end

	-- mob health check
--	if self.health <= 0 then
--		return
--	end

	-- error checking when mod profiling is enabled
	if not tool_capabilities then
		minetest.log("warning", "[mobs] Mod profiling enabled, damage not enabled")
		return
	end

	-- is mob protected?
	if self.protected and hitter:is_player()
	and minetest.test_protection(v_round(self.object:get_pos()), hitter:get_player_name()) then
		minetest.chat_send_player(hitter:get_player_name(), "# Server: Mob has been protected!")
		return
	end


	-- weapon wear
	local weapon = hitter:get_wielded_item()
	--minetest.log("weapon: <" .. weapon:get_name() .. ">")
	local punch_interval = 1.4

	-- calculate mob damage
	local damage = 0
	local armor = self.object:get_armor_groups() or {}
	local tmp

	-- quick error check incase it ends up 0 (serialize.h check test)
	if tflp == 0 then
		tflp = 0.2
	end

	do
		for group,_ in pairs( (tool_capabilities.damage_groups or {}) ) do

			tmp = tflp / (tool_capabilities.full_punch_interval or 1.4)

			if tmp < 0 then
				tmp = 0.0
			elseif tmp > 1 then
				tmp = 1.0
			end

			damage = damage + (tool_capabilities.damage_groups[group] or 0)
				* tmp * ((armor[group] or 0) / 100.0)
		end
	end

	-- check for tool immunity or special damage
	for n = 1, #self.immune_to do

		if self.immune_to[n][1] == weapon:get_name() then

			damage = self.immune_to[n][2] or 0
			break

		-- if "all" then no tool does damage unless it's specified in list
		elseif self.immune_to[n][1] == "all" then
			damage = self.immune_to[n][2] or 0
		end
	end

	-- healing
	if damage <= -1 then
		self.health = self.health - floor(damage)
		return
	end

--	print ("Mob Damage is", damage)

	-- add weapon wear
	if tool_capabilities then
		punch_interval = tool_capabilities.full_punch_interval or 1.4
	end

	if weapon:get_definition()
	and weapon:get_definition().tool_capabilities then

		-- toolrank support
		local wear = floor((punch_interval / 75) * 9000)

		if mobs.is_creative(hitter:get_player_name()) then

			if tr then
				wear = 1
			else
				wear = 0
			end
		end

		if tr then
			if weapon:get_definition()
			and weapon:get_definition().original_description then
				weapon:add_wear(toolranks.new_afteruse(weapon, hitter, nil, {wear = wear}))
			end
		else
			weapon:add_wear(wear)
		end

		hitter:set_wielded_item(weapon)
	end

	-- only play hit sound and show blood effects if damage is 1 or over
	if damage >= 1 then

		-- weapon sounds
		if weapon:get_definition().sounds ~= nil then

			local s = random(0, #weapon:get_definition().sounds)

			minetest.sound_play(weapon:get_definition().sounds[s], {
				object = self.object, --hitter,
				max_hear_distance = 20
			}, true)
		else
			minetest.sound_play("default_punch", {
				object = self.object, --hitter,
				max_hear_distance = 20
			}, true)
		end

		-- blood_particles
		if self.blood_amount > 0
		and not disable_blood then

			local pos = self.object:get_pos()

			pos.y = pos.y + (-self.collisionbox[2] + self.collisionbox[5]) * .5

			-- do we have a single blood texture or multiple?
			if type(self.blood_texture) == "table" then

				local blood = self.blood_texture[random(1, #self.blood_texture)]

				effect(pos, self.blood_amount, blood, nil, nil, 1, nil)
			else
				effect(pos, self.blood_amount, self.blood_texture, nil, nil, 1, nil)
			end
		end

		-- do damage
		self.health = self.health - floor(damage)

		-- exit here if dead, special item check
		if weapon:get_name() == "mobs:pick_lava" then
			if check_for_death(self, "lava", {
						type = "punch",
						puncher = hitter,
						tool_capabilities = tool_capabilities,
						wielded = weapon,
					}) then
				return
			end
		else
			if check_for_death(self, "hit", {
						type = "punch",
						puncher = hitter,
						tool_capabilities = tool_capabilities,
						wielded = weapon,
					}) then
				return
			end
		end

		--[[ add healthy afterglow when hit (can cause hit lag with larger textures)
		minetest.after(0.1, function()

			if not self.object:get_luaentity() then return end

			self.object:settexturemod("^[colorize:#c9900070")

			core.after(0.3, function()
				self.object:settexturemod("")
			end)
		end) ]]

		-- knock back effect (only on full punch)
		if self.knock_back and tflp >= punch_interval then

			local v = self.object:get_velocity()
			local r = 1.4 - min(punch_interval, 1.4)
			local kb = r * 5
			local up = 2

			-- if already in air then dont go up anymore when hit
			if v.y > 0
			or self.fly then
				up = 0
			end

			-- direction error check
			dir = dir or {x = 0, y = 0, z = 0}

			-- check if tool already has specific knockback value
			if tool_capabilities.damage_groups["knockback"] then
				kb = tool_capabilities.damage_groups["knockback"]
			else
				kb = kb * default_knockback
			end

			self.object:set_velocity({
				x = dir.x * kb,
				y = up,
				z = dir.z * kb
			})

			self.pause_timer = 0.25
		end
	end -- END if damage

	-- if skittish then run away
	if self.runaway == true then

		local lp = hitter:get_pos()
		local s = self.object:get_pos()

		local yaw = compute_yaw_to_target(self, lp, s)
		yaw = yaw + pi -- go in reverse
		yaw = set_yaw(self, yaw, 6)

		self.state = "runaway"
		self.runaway_timer = 0
		self.following = nil
	end

	local name = (hitter:is_player() and hitter:get_player_name()) or ""
	
	--minetest.chat_send_player("MustTest", "Attack!")

	-- attack puncher and call other mobs for help
	if (self.passive == false or self.attack_players == true)
	and self.state ~= "flop"
	and self.child == false
	and name ~= "" and name ~= self.owner
	and not mobs.is_invisible(self, name) then

		--minetest.chat_send_player("MustTest", "Will really attack!")

		-- attack whoever punched mob
		self.state = ""
		do_attack(self, hitter)

		-- alert others to the attack
		local objs = minetest.get_objects_inside_radius(hitter:get_pos(), self.view_range)
		local obj = nil

		for n = 1, #objs do

			obj = objs[n]:get_luaentity()

			if obj and obj._cmi_is_mob then

				-- only alert members of same mob
				if obj.group_attack == true
				and obj.state ~= "attack"
				and obj.owner ~= name
				and obj.name == self.name then
					do_attack(obj, hitter)
				end

				-- have owned mobs attack player threat
				if obj.owner == name and obj.owner_loyal then
					do_attack(obj, self.object)
				end
			end
		end
	end
end



-- export!
function mobs.mob_punch(self, hitter, tflp, tool_capabilities, dir)
	return mob_punch(self, hitter, tflp, tool_capabilities, dir)
end



-- get entity staticdata
local function mob_staticdata(self)

	-- remove mob when out of range unless tamed
	if remove_far
	and self.remove_ok
	and self.type ~= "npc"
	and self.state ~= "attack"
	and not self.tamed
	and self.lifetimer < 20000 then

		--print ("REMOVED " .. self.name)

		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return ""-- nil
	end

	self.remove_ok = true
	self.attack = nil
	self.following = nil
	self.state = "stand"

	-- used to rotate older mobs
	if self.drawtype
	and self.drawtype == "side" then
		self.rotate = math.rad(90)
	end

	local tmp = {}

	for _,stat in pairs(self) do

		local t = type(stat)

		if  t ~= "function"
		and t ~= "nil"
		and t ~= "userdata"
		and _ ~= "_cmi_components" then
			tmp[_] = self[_]
		end
	end

	--print('===== '..self.name..'\n'.. dump(tmp)..'\n=====\n')
	return minetest.serialize(tmp)
end



-- export!
function mobs.mob_staticdata(self)
	return mob_staticdata(self)
end



-- Activate mob and reload settings.
local function mob_activate(self, staticdata, def, dtime)

	-- Remove mob if activated during daytime and has 'daytime_despawn'.
	if self.daytime_despawn then
		local tod = (minetest.get_timeofday() or 0) * 24000
		if tod > 4500 and tod < 19500 then
			-- Daylight, but mob despawns at daytime.

			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			return
		end
	end

	-- Remove mob if outside realm dimensions.
	if not rc.is_valid_realm_pos(self.object:get_pos()) then
		-- Mark for removal as last action on mob_step().
		self.mkrm = true

		return
	end

	-- load entity variables
	local tmp = minetest.deserialize(staticdata)
	if tmp then
		for _, stat in pairs(tmp) do
			self[_] = stat
		end
	end

	-- Do select random texture, set model and size.
	if not self.base_texture then

		-- Do compatiblity with old simple mobs textures.
		if def.textures and type(def.textures[1]) == "string" then
			def.textures = {def.textures}
		end

		self.base_texture = def.textures and def.textures[random(1, #def.textures)]
		self.base_mesh = def.mesh
		self.base_size = self.visual_size
		self.base_colbox = self.collisionbox
		self.base_selbox = self.selectionbox
	end

	-- for current mobs that dont have this set
	if not self.base_selbox then
		self.base_selbox = self.selectionbox or self.base_colbox
	end

	-- set texture, model and size
	local textures = self.base_texture
	local mesh = self.base_mesh
	local vis_size = self.base_size
	local colbox = self.base_colbox
	local selbox = self.base_selbox

	-- specific texture if gotten
	if self.gotten == true
	and def.gotten_texture then
		textures = def.gotten_texture
	end

	-- specific mesh if gotten
	if self.gotten == true
	and def.gotten_mesh then
		mesh = def.gotten_mesh
	end

	-- set child objects to half size
	if self.child == true then

		vis_size = {
			x = self.base_size.x * .5,
			y = self.base_size.y * .5,
		}

		if def.child_texture then
			textures = def.child_texture[1]
		end

		colbox = {
			self.base_colbox[1] * .5,
			self.base_colbox[2] * .5,
			self.base_colbox[3] * .5,
			self.base_colbox[4] * .5,
			self.base_colbox[5] * .5,
			self.base_colbox[6] * .5
		}
		selbox = {
			self.base_selbox[1] * .5,
			self.base_selbox[2] * .5,
			self.base_selbox[3] * .5,
			self.base_selbox[4] * .5,
			self.base_selbox[5] * .5,
			self.base_selbox[6] * .5
		}
	end

	if self.health == 0 then
		self.health = random (self.hp_min, self.hp_max)
	end

	-- pathfinding init
	self.path = {}
	self.path.way = {} -- path to follow, table of positions
	self.path.lastpos = {x = 0, y = 0, z = 0}
	self.path.following = false -- currently following path?
	self.path.stuck_timer = 0 -- if stuck for too long search for path
	self.path.pos_rec_timer = 0
	self.path.find_path_timer = 0
	self.path.putnode_timer = 0
	self.path.los_counter = 0
	self.path.los_check = 0

	-- Adjust the chance to use pathfinding on a per-entity basis.
	if self.pathfinding and self.pathfinding ~= 0 then
		-- If pathfinding is enabled, by default chance is 100%.
		local chance = self.pathfinding_chance or 100
		local res = math_random(1, 100)

		if res > chance then
			self.pathfinding = 0
		end
	end

	-- mob defaults
	self.object:set_armor_groups({immortal = 1, fleshy = self.armor})
	self.old_y = self.object:get_pos().y
	self.old_health = self.health
	self.sounds.distance = self.sounds.distance or 10
	self.textures = textures
	self.mesh = mesh
	self.collisionbox = colbox
	self.selectionbox = selbox
	self.visual_size = vis_size
	self.standing_in = "air"
	self.standing_on = "air"

	-- check existing nametag
	if not self.nametag then
		self.nametag = def.nametag
	end

	-- set anything changed above
	self.object:set_properties(self)
	set_yaw(self, (random(0, 360) - 180) / 180 * pi, 6)
	update_tag(self)
	set_animation(self, "stand")

	-- run on_spawn function if found
	if self.on_spawn and not self.on_spawn_run then
		if self.on_spawn(self) then
			self.on_spawn_run = true --  if true, set flag to run once only
		end
	end

	-- run after_activate
	if def.after_activate then
		def.after_activate(self, staticdata, def, dtime)
	end
end



-- export!
function mobs.mob_activate(self, staticdata, def, dtime)
	return mob_activate(self, staticdata, def, dtime)
end



local function smooth_rotate(self)
	-- smooth rotation by ThomasMonroe314

	if self.delay and self.delay > 0 then

		local yaw = self.object:get_yaw()

		if self.delay == 1 then
			yaw = self.target_yaw
		else
			local dif = abs(yaw - self.target_yaw)

			if yaw > self.target_yaw then

				if dif > pi then
					dif = 2 * pi - dif -- need to add
					yaw = yaw + dif / self.delay
				else
					yaw = yaw - dif / self.delay -- need to subtract
				end

			elseif yaw < self.target_yaw then

				if dif > pi then
					dif = 2 * pi - dif
					yaw = yaw - dif / self.delay -- need to subtract
				else
					yaw = yaw + dif / self.delay -- need to add
				end
			end

			if yaw > (pi * 2) then yaw = yaw - (pi * 2) end
			if yaw < 0 then yaw = yaw + (pi * 2) end
		end

		self.delay = self.delay - 1
		self.object:set_yaw(yaw)
	end

	-- end rotation
end



-- main mob function
local function mob_step(self, dtime)
	-- The final (actually first) action of mob_step():
	-- if the mob was marked for removal, we call :remove() here.
	-- :remove() should not be called anywhere else!
	if self.mkrm then
		self.object:remove()
		return
	end

	local pos = self.object:get_pos()
	if not pos then return end -- Stupid spurious errors.
	local yaw = 0

	-- when lifetimer expires remove mob (except npc and tamed)
	if self.type ~= "npc"
	and not self.tamed
	and self.state ~= "attack"
	and remove_far ~= true
	and self.lifetimer < 20000 then

		self.lifetimer = self.lifetimer - dtime

		if self.lifetimer <= 0 then

			-- only despawn away from player
			local objs = minetest.get_objects_inside_radius(pos, 15)

			for n = 1, #objs do

				if objs[n]:is_player() then

					self.lifetimer = 20

					return
				end
			end

			effect(pos, 15, "tnt_smoke.png", 2, 4, 2, 0)

			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			return
		end
	end

	-- get node at foot level every quarter second
	self.node_timer = (self.node_timer or 0) + dtime

	if self.node_timer > 0.25 then

		self.node_timer = 0

		local y_level = self.collisionbox[2]

		if self.child then
			y_level = self.collisionbox[2] * 0.5
		end

		-- what is mob standing in?
		self.standing_in = node_ok({
			x = pos.x, y = pos.y + y_level + 0.25, z = pos.z}, "air").name
--		print ("standing in " .. self.standing_in)
		self.standing_on = node_ok({
			x = pos.x, y = ((pos.y + y_level) - 0.5), z = pos.z}, "air").name
--		print ("standing on " .. self.standing_on)
	end

	-- check if falling, flying, floating
	falling(self, pos)

	-- Do smooth rotation.
	smooth_rotate(self)

	-- knockback timer
	if self.pause_timer > 0 then

		self.pause_timer = self.pause_timer - dtime

		return
	end

	-- run custom function (defined in mob lua file)
	if self.do_custom then

		-- when false skip going any further
		if self.do_custom(self, dtime) == false then
			return
		end
	end

	-- attack timer
	self.timer = self.timer + dtime

	if self.state ~= "attack" then

		if self.timer < 1 then
			return
		end

		self.timer = 0
	end

	-- never go over 100
	if self.timer > 100 then
		self.timer = 1
	end

	-- mob plays random sound at times
	if random(1, 100) == 1 then
		mob_sound(self, self.sounds.random)
	end

	-- environmental damage timer (every 1 second)
	self.env_damage_timer = self.env_damage_timer + dtime

	if (self.state == "attack" and self.env_damage_timer > 1)
	or self.state ~= "attack" then

		self.env_damage_timer = 0

		-- check for environmental damage (water, fire, lava etc.)
		do_env_damage(self)

		-- node replace check (cow eats grass etc.)
		replace(self, pos)
	end

	-- The 'general_attack' function only needs to run once a second.
	self.general_attack_timer = (self.general_attack_timer or 0) + dtime
	if self.general_attack_timer >= 1 then
		general_attack(self)
		self.general_attack_timer = 0
	end

	breed(self)

	follow_flop(self)

	do_states(self, dtime)

	-- Allow jump routine to break blocks [MustTest].
	local break_blocks = false
	if self.path.following and (self.pathfinding or 0) >= 2 then
		break_blocks = true
	end
	do_jump(self, break_blocks)

	runaway_from(self)
end



-- export!
function mobs.mob_step(self, dtime)
	return mob_step(self, dtime)
end



-- Default function when mobs are blown up with TNT.
local function do_tnt(obj, damage)

	obj.object:punch(obj.object, 1.0, {
		full_punch_interval = 1.0,
		damage_groups = {fleshy = damage},
	}, nil)

	return false, true, {}
end



-- export!
function mobs.do_tnt(obj, damage)
	return do_tnt(obj, damage)
end



local function first_or_second(arg1, arg2)
    if type(arg1) ~= "nil" then
        return arg1
    else
        return arg2
    end
end



-- register mob entity function
if not mobs.registered then
	mobs.spawning_mobs = {}

	-- Register mob function.
	mobs.register_mob = function(name, def)
		mobs.spawning_mobs[name] = true

		minetest.register_entity(name, {
			-- Warning: this parameter is set by the engine anway!
			name                    = name,

			_name                   = name,
			mob                     = true, -- Object is a mob.
			type                    = def.type,
			armor_level             = def.armor_level or 0,
			description             = def.description,
			stepheight              = def.stepheight or 1.1, -- was 0.6
			attack_type             = def.attack_type,
			fly                     = def.fly,
			fly_in                  = def.fly_in or "air",
			owner                   = def.owner or "",
			order                   = def.order or "",
			on_die                  = def.on_die,
			do_custom               = def.do_custom,
			jump_height             = def.jump_height or 4, -- was 6

			drawtype                = def.drawtype, -- DEPRECATED, use rotate instead
			rotate                  = math.rad(def.rotate or 0), --  0=front, 90=side, 180=back, 270=side2
			lifetimer               = def.lifetimer or 180, -- 3 minutes
			hp_min                  = (def.hp_min or 5) * difficulty,
			hp_max                  = (def.hp_max or 10) * difficulty,
			physical                = true,
			collisionbox            = def.collisionbox or {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
			selectionbox            = def.selectionbox or def.collisionbox,
			visual                  = def.visual,
			visual_size             = def.visual_size or {x = 1, y = 1},
			mesh                    = def.mesh,
			makes_footstep_sound    = def.makes_footstep_sound or false,
			view_range              = def.view_range or 5,
			walk_velocity           = def.walk_velocity or 1,
			run_velocity            = def.run_velocity or 2,
			sprint_velocity         = def.sprint_velocity or def.run_velocity or 2,

			-- Mob always does at least this amount of damage.
			-- But if random damage between min and max would be greater,
			-- then that damage is done instead.
			damage                  = (def.damage or 0) * difficulty,
			damage_min              = (def.damage_min or 0) * difficulty,
			damage_max              = (def.damage_max or 0) * difficulty,

			daytime_despawn         = def.daytime_despawn,
			on_despawn              = def.on_despawn,
			light_damage            = def.light_damage or 0,
			water_damage            = def.water_damage or 0,
			lava_damage             = def.lava_damage or 0,
			suffocation             = def.suffocation or 2,

			lava_annihilates        = first_or_second(def.lava_annihilates, true),
			makes_bones_in_lava     = first_or_second(def.makes_bones_in_lava, true),

			fall_damage             = def.fall_damage or 1,
			fall_speed              = def.fall_speed or -10, -- must be lower than -2 (default: -10)
			drops                   = def.drops or {},
			armor                   = def.armor or 100,
			on_rightclick           = def.on_rightclick,
			arrow                   = def.arrow,
			shoot_interval          = def.shoot_interval,
			sounds                  = def.sounds or {},
			animation               = def.animation,
			follow                  = def.follow,
			jump                    = def.jump ~= false,
			walk_chance             = def.walk_chance or 50,
			attacks_monsters        = def.attacks_monsters or false,
			--fov = def.fov or 120,
			passive                 = def.passive or false,
			knock_back              = def.knock_back ~= false,
			blood_amount            = def.blood_amount or 5,
			blood_texture           = def.blood_texture or "mobs_blood.png",
			shoot_offset            = def.shoot_offset or 0,
			floats                  = def.floats or 1, -- floats in water by default
			replace_rate            = def.replace_rate,
			replace_what            = def.replace_what,
			replace_with            = def.replace_with,
			replace_offset          = def.replace_offset or 0,
			on_replace              = def.on_replace,

			-- Feature added by MustTest.
			replace_range           = def.replace_range or 1,
			despawns_in_dark_caves  = def.despawns_in_dark_caves or false,

			timer                   = 0,
			env_damage_timer        = 0, -- only used when state = "attack"
			tamed                   = false,
			pause_timer             = 0,
			horny                   = false,
			hornytimer              = 0,
			child                   = false,
			gotten                  = false,
			health                  = 0,
			reach                   = def.reach or 3,
			punch_reach             = def.punch_reach or def.reach or 3,
			htimer                  = 0,
			texture_list            = def.textures,
			child_texture           = def.child_texture,
			docile_by_day           = def.docile_by_day or false,
			time_of_day             = 0.5,
			fear_height             = def.fear_height or 0,
			runaway                 = def.runaway,
			runaway_timer           = 0,
			pathfinding             = def.pathfinding or 0,
			pathfinding_chance      = def.pathfinding_chance,
			place_node              = def.place_node,
			immune_to               = def.immune_to or {},
			explosion_radius        = def.explosion_radius,
			explosion_damage_radius = def.explosion_damage_radius,
			explosion_timer         = def.explosion_timer or 3,
			allow_fuse_reset        = def.allow_fuse_reset ~= false,
			stop_to_explode         = def.stop_to_explode ~= false,
			custom_attack           = def.custom_attack,
			double_melee_attack     = def.double_melee_attack,
			dogshoot_switch         = def.dogshoot_switch,
			dogshoot_count          = 0,
			dogshoot_count_max      = def.dogshoot_count_max or 5,
			dogshoot_count2_max     = def.dogshoot_count2_max or (def.dogshoot_count_max or 5),
			group_attack            = def.group_attack or false,
			attack_monsters         = def.attacks_monsters or def.attack_monsters or false,
			attack_animals          = def.attack_animals or false,
			attack_players          = def.attack_players ~= false,
			attack_npcs             = def.attack_npcs ~= false,
			specific_attack         = def.specific_attack,
			runaway_from            = def.runaway_from,
			owner_loyal             = def.owner_loyal,
			facing_fence            = false,
			ignore_invisibility     = def.ignore_invisibility,
			pathing_radius          = def.pathing_radius,
			max_node_dig_level      = def.max_node_dig_level,
			hunt_players            = def.hunt_players,
			hunt_chance             = def.hunt_chance or 5,
			-- The meaning of 'attack_chance' is inverted in order to make more sense [MustTest].
			attack_chance           = def.attack_chance or 95,
			_cmi_is_mob             = true,



			on_spawn = def.on_spawn,

			on_blast = def.on_blast or function(...) return mobs.do_tnt(...) end,

			on_step = function(...) return mobs.mob_step(...) end,

			do_punch = def.do_punch,

			on_punch = function(...) return mobs.mob_punch(...) end,

			on_breed = def.on_breed,

			on_grown = def.on_grown,

			on_activate = function(self, staticdata, dtime)
				return mobs.mob_activate(self, staticdata, def, dtime)
			end,

			get_staticdata = function(self)
				return mobs.mob_staticdata(self)
			end,
		})
	end -- END mobs:register_mob function
end



local function arrow_step(self, dtime, def)
	self.timer = self.timer + 1

	local pos = self.object:get_pos()

	if self.switch == 0
	or self.timer > 150
	or not within_limits(pos, 0) then

		self.object:remove() ; -- print ("removed arrow")

		return
	end

	-- does arrow have a tail (fireball)
	if def.tail
	and def.tail == 1
	and def.tail_texture then

		minetest.add_particle({
			pos = pos,
			velocity = {x = 0, y = 0, z = 0},
			acceleration = {x = 0, y = 0, z = 0},
			expirationtime = def.expire or 0.25,
			collisiondetection = false,
			texture = def.tail_texture,
			size = def.tail_size or 5,
			glow = def.glow or 0,
		})
	end

	if self.hit_node then
		-- Always round node position before passing it to code that probably
		-- assumes that position is an integer (failure to do this can result in
		-- coordinate problems in the engine)!
		local rpos = v_round(pos)
		local node = node_ok(rpos).name

		local ndef = minetest.reg_ns_nodes[node]
		if not ndef or ndef.walkable then

			self.hit_node(self, rpos, node)

			if self.drop == true then

				pos.y = pos.y + 1

				self.lastpos = (self.lastpos or pos)

				minetest.add_item(self.lastpos, self.object:get_luaentity().name)
			end

			self.object:remove() ; -- print ("hit node")

			return
		end
	end

	if self.hit_player or self.hit_mob then

		for _,player in pairs(minetest.get_objects_inside_radius(pos, 1.5)) do

			if self.hit_player
			and player:is_player() then

				self.hit_player(self, player)
				self.object:remove() ; -- print ("hit player")
				return
			end

			local entity = player:get_luaentity()

			if entity
			and self.hit_mob
			and entity._cmi_is_mob == true
			and tostring(player) ~= self.owner_id
			and entity.name ~= self.object:get_luaentity().name then

				self.hit_mob(self, player)

				self.object:remove() ;  --print ("hit mob")

				return
			end
		end
	end

	self.lastpos = pos
end



-- export!
function mobs.arrow_step(self, dtime, def)
	return arrow_step(self, dtime, def)
end



-- register mob arrow entity function
if not mobs.registered then
	-- register arrow for shoot attack
	function mobs.register_arrow(name, def)
		if not name or not def then return end -- errorcheck

		minetest.register_entity(name, {
			physical = false,
			visual = def.visual,
			visual_size = def.visual_size,
			textures = def.textures,
			velocity = def.velocity,
			hit_player = def.hit_player,
			hit_node = def.hit_node,
			hit_mob = def.hit_mob,
			drop = def.drop or false, -- drops arrow as registered item when true
			collisionbox = {0, 0, 0, 0, 0, 0}, -- remove box around arrows
			timer = 0,
			switch = 0,
			owner_id = def.owner_id,
			rotate = def.rotate,

			automatic_face_movement_dir = def.rotate
				and (def.rotate - (pi / 180)) or false,

			on_activate = def.on_activate,

			on_step = def.on_step or function(self, dtime) return mobs.arrow_step(self, dtime, def) end,
		})
	end
end



-- Spawner item.
-- Note: This also introduces the “spawn_egg” group:
-- * spawn_egg=1: Spawn egg (generic mob, no metadata)
-- * spawn_egg=2: Spawn egg (captured/tamed mob, metadata)
if not mobs.registered then
	mobs.register_egg = function(mob, desc, background, addegg, no_creative)
		local invimg = background

		if addegg == 1 then
				invimg = "mobs_egg.png^(" .. background .. "^[mask:mobs_egg_overlay.png)"
		elseif addegg == 0 then
				invimg = background
		end

		-- register new spawn egg containing mob information
		minetest.register_craftitem(mob .. "_set", {
			description = desc .. " Spawn Egg (Tamed)",
			inventory_image = invimg,
			groups = {not_in_creative_inventory=1, not_in_craft_guide=1, spawn_egg=2},
			stack_max = 1,

			on_place = function(itemstack, placer, pointed_thing)

				local pos = pointed_thing.above

				-- am I clicking on something with existing on_rightclick function?
				local under = minetest.get_node(pointed_thing.under)
				local def = minetest.reg_ns_nodes[under.name]
				if def and def.on_rightclick then
					return def.on_rightclick(pointed_thing.under, under, placer, itemstack)
				end

				if pos and within_limits(pos, 0) then
					if not minetest.registered_entities[mob] then
						return
					end

					pos.y = pos.y + 1

					local data = itemstack:get_metadata()
					local mob = minetest.add_entity(pos, mob, data)
					local ent = mob:get_luaentity()

					if not ent then mob:remove()
						minetest.chat_send_player(name, "# Server: Failed to retrieve creature!")
						return
					end

					-- set owner if not a monster
					if ent.type ~= "monster" then
						ent.owner = placer:get_player_name()
						ent.tamed = true
					end

					-- since mob is unique we remove egg once spawned
					itemstack:take_item()
				end

				return itemstack
			end,
		})



		-- register old stackable mob egg
		minetest.register_craftitem(mob, {
			description = desc .. " Spawn Egg",
			inventory_image = invimg,
			groups = {not_in_creative_inventory=1, not_in_craft_guide=1, spawn_egg=1},

			on_place = function(itemstack, placer, pointed_thing)
				local pos = pointed_thing.above
				local name = placer:get_player_name()

				if pos and within_limits(pos, 0) then
					if not minetest.registered_entities[mob] then
						return
					end

					pos.y = pos.y + 1

					local mob = minetest.add_entity(pos, mob)
					local ent = mob:get_luaentity()

					if not ent then mob:remove()
						minetest.chat_send_player(name, "# Server: Failed to create mob!")
						return
					end

					-- don't set owner if monster or sneak pressed
					if ent.type ~= "monster"
					and not placer:get_player_control().sneak then
						ent.owner = placer:get_player_name()
						ent.tamed = true
					end
				end

				itemstack:take_item()
				return itemstack
			end,
		})
	end
end



-- Capture critter (thanks to blert2112 for idea).
function mobs.capture_mob(self, clicker, chance_hand, chance_net, chance_lasso, force_take, replacewith)

	if self.child
	or not clicker:is_player()
	or not clicker:get_inventory() then
		return false
	end

	-- get name of clicked mob
	local mobname = self.name

	-- if not nil change what will be added to inventory
	if replacewith then
		mobname = replacewith
	end

	local name = clicker:get_player_name()
	local tool = clicker:get_wielded_item()

	-- are we using hand, net or lasso to pick up mob?
	if tool:get_name() ~= ""
	and tool:get_name() ~= "mobs:net"
	and tool:get_name() ~= "mobs:lasso" then
		return false
	end

	-- Is mob tamed?
	if self.tamed == false and force_take == false then
		minetest.chat_send_player(name, "# Server: Animal not tamed!")
		return true -- false
	end

	-- Cannot pick up if not owner.
	if self.owner ~= name and force_take == false then
		minetest.chat_send_player(name, "# Server: Player <" .. rename.gpn(self.owner) .. "> is owner!")
		return true -- false
	end

	if clicker:get_inventory():room_for_item("main", mobname) then
		-- Was mob clicked with hand, net, or lasso?
		local chance = 0
		local tool = clicker:get_wielded_item()

		if tool:get_name() == "" then
			chance = chance_hand

		elseif tool:get_name() == "mobs:net" then

			chance = chance_net

			tool:add_wear(4000) -- 17 uses

			clicker:set_wielded_item(tool)

		elseif tool:get_name() == "mobs:lasso" then

			chance = chance_lasso

			tool:add_wear(650) -- 100 uses

			clicker:set_wielded_item(tool)

		end

		-- calculate chance.. add to inventory if successful?
		if chance > 0 and random(1, 100) <= chance then

			-- default mob egg
			local new_stack = ItemStack(mobname)

			-- add special mob egg with all mob information
			-- unless 'replacewith' contains new item to use
			if not replacewith then

				new_stack = ItemStack(mobname .. "_set")

				local tmp = {}

				for _,stat in pairs(self) do
					local t = type(stat)
					if  t ~= "function"
					and t ~= "nil"
					and t ~= "userdata" then
						tmp[_] = self[_]
					end
				end

				local data_str = minetest.serialize(tmp)

				new_stack:set_metadata(data_str)
			end

			local inv = clicker:get_inventory()

			if inv:room_for_item("main", new_stack) then
				inv:add_item("main", new_stack)
			else
				minetest.add_item(clicker:get_pos(), new_stack)
			end

			-- Mark for removal as last action on mob_step().
			self.mkrm = true

			mob_sound(self, "default_place_node_hard")

		elseif chance ~= 0 then
			minetest.chat_send_player(name, "# Server: Missed!")
			mob_sound(self, "mobs_swing")
		end
	end
end



-- Make tables persistent even when file reloaded.
if not mobs.registered then
	mobs.nametagdata = {}
	mobs.nametagdata.mob_obj = {}
	mobs.nametagdata.mob_sta = {}
end

local mob_obj = mobs.nametagdata.mob_obj
local mob_sta = mobs.nametagdata.mob_sta

-- Feeding, taming and breeding (thanks blert2112).
function mobs.feed_tame(self, clicker, feed_count, breed, tame)
	if not self.follow then
		return false
	end

	-- can eat/tame with item in hand
	if follow_holding(self, clicker) then

		-- if not in creative then take item
		if not creative then

			local item = clicker:get_wielded_item()

			item:take_item()

			clicker:set_wielded_item(item)
		end

		-- increase health
		self.health = self.health + 4

		if self.health >= self.hp_max then
			self.health = self.hp_max
			if self.htimer < 1 then
				minetest.chat_send_player(clicker:get_player_name(), "# Server: Mob has full health!")
				self.htimer = 5
			end
		end

		self.object:set_hp(self.health)

		update_tag(self)

		-- make children grow quicker
		if self.child == true then

			self.hornytimer = self.hornytimer + 20

			return true
		end

		-- feed and tame
		self.food = (self.food or 0) + 1
		if self.food >= feed_count then

			self.food = 0

			if breed and self.hornytimer == 0 then
				self.horny = true
			end

			self.gotten = false

			if tame then

				if self.tamed == false then
					minetest.chat_send_player(clicker:get_player_name(), "# Server: Mob has been tamed!")
				end

				self.tamed = true

				if not self.owner or self.owner == "" then
					self.owner = clicker:get_player_name()
				end
			end

			-- make sound when fed so many times
			mob_sound(self, self.sounds.random)
		end

		return true
	end

	local item = clicker:get_wielded_item()

	-- if mob has been tamed you can name it with a nametag
	if item:get_name() == "mobs:nametag"
	and clicker:get_player_name() == self.owner then

		local name = clicker:get_player_name()

		-- store mob and nametag stack in external variables
		mob_obj[name] = self
		mob_sta[name] = item

		local tag = self.nametag or ""

		minetest.show_formspec(name, "mobs_nametag", "size[8,4]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. "field[0.5,1;7.5,0;name;" .. minetest.formspec_escape("Enter name:") .. ";" .. tag .. "]"
			.. "button_exit[2.5,3.5;3,1;mob_rename;" .. minetest.formspec_escape("Rename") .. "]")
	end

	return false
end

function mobs.nametag_receive_fields(player, formname, fields)
	-- right-clicked with nametag and name entered?
	if formname == "mobs_nametag"
	and fields.name
	and fields.name ~= "" then

		local name = player:get_player_name()

		if not mob_obj[name]
		or not mob_obj[name].object then
			return
		end

		-- make sure nametag is being used to name mob
		local item = player:get_wielded_item()

		if item:get_name() ~= "mobs:nametag" then
			return
		end

		-- limit name entered to 64 characters long
		if string.len(fields.name) > 64 then
			fields.name = string.sub(fields.name, 1, 64)
		end

		-- update nametag
		mob_obj[name].nametag = fields.name

		update_tag(mob_obj[name])

		-- if not in creative then take item
		if not mobs.is_creative(name) then

			mob_sta[name]:take_item()

			player:set_wielded_item(mob_sta[name])
		end

		-- reset external variables
		mob_obj[name] = nil
		mob_sta[name] = nil
	end
end

-- inspired by blockmen's nametag mod
if not mobs.registered then
	minetest.register_on_player_receive_fields(function(...)
		return mobs.nametag_receive_fields(...)
	end)
end


-- compatibility function for old entities to new modpack entities
if not mobs.registered then
	function mobs.alias_mob(old_name, new_name)

		-- spawn egg
		minetest.register_alias(old_name, new_name)

		-- entity
		minetest.register_entity(":" .. old_name, {

			physical = false,

			on_activate = function(self)

				if minetest.registered_entities[new_name] then
					minetest.add_entity(self.object:get_pos(), new_name)
				end

				-- Remove mob immediately, as last step of this function.
				-- Controls returns to engine.
				self.object:remove()
				self.mkrm = true
			end
		})
	end
end



-- Register as a reloadable file.
if not mobs.registered then
	local c = "mobs:api"
	local f = mobs.modpath .. "/api.lua"
	reload.register_file(c, f, false)

	mobs.registered = true
end
