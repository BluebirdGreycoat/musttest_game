
-- Localize for performance.
local vector_distance = vector.distance
local vector_round = vector.round
local vector_add = vector.add
local vector_equals = vector.equals
local math_random = math.random
local CITYBLOCK_DELAY_TIME = city_block.CITYBLOCK_DELAY_TIME
local time_active = city_block.time_active



function city_block:get_adjective()
  local adjectives = {
    "murdering",
    "slaying",
    "killing",
    "whacking",
    "trashing",
    "fatally attacking",
    "fatally harming",
    "doing away with",
    "giving the Chicago treatment to",
    "fatally thrashing",
    "fatally stabbing",
    "executing",
  }
  return adjectives[math_random(1, #adjectives)]
end



local murder_messages = {
	"<v> collapsed from <k>'s brutal attack.",
	"<k>'s <w> apparently wasn't such an unusual weapon after all, as <v> found out.",
	"<k> killed <v> with great prejudice.",
	"<v> died from <k>'s horrid slaying.",
	"<v> fell prey to <k>'s deadly <w>.",
	"<k> went out of <k_his> way to slay <v> with <k_his> <w>.",
	"<v> danced <v_himself> to death under <k>'s craftily wielded <w>.",
	"<k> used <k_his> <w> to kill <v> with prejudice.",
	"<k> made a splortching sound with <v>'s head.",
	"<v> got flattened by <k>'s skillfully handled <w>.",
	"<v> became prey for <k>.",
	"<v> didn't get out of <k>'s way in time.",
	"<v> SAW <k> coming with <k_his> <w>. Didn't get away in time.",
	"<v> made no real attempt to get out of <k>'s way.",
	"<k> barreled through <v> as if <v_he> wasn't there.",
	"<k> sent <v> to that place where kindling wood isn't needed.",
	"<v> didn't suspect that <k> meant <v_him> any harm.",
	"<v> fought <k> to the death and lost painfully.",
	"<v> knew <k> was wielding <k_his> <w> but didn't guess what <k> meant to do with it.",
	"<k> clonked <v> over the head using <k_his> <w> with silent skill.",
	"<k> made sure <v> didn't see that coming!",
	"<k> has decided <k_his> favorite weapon is <k_his> <w>.",
	"<v> did the mad hatter dance just before being killed with <k>'s <w>.",
	"<v> played the victim to <k>'s bully behavior!",
	"<k> used <v> for weapons practice with <k_his> <w>.",
	"<v> failed to avoid <k>'s oncoming weapon.",
	"<k> successfully got <v> to complain of a headache.",
	"<v> got <v_himself> some serious hurt from <k>'s <w>.",
	"Trying to talk peace to <k> didn't win any for <v>.",
	"<v> was brutally slain by <k>'s <w>.",
	"<v> jumped the mad-hatter dance under <k>'s <w>.",
	"<v> got <v_himself> a fatal mauling by <k>'s <w>.",
	"<k> just assassinated <v> with <k_his> <w>.",
	"<k> split <v>'s wig.",
	"<k> took revenge on <v>.",
	"<k> flattened <v>.",
	"<v> played dead. Permanently.",
	"<v> never saw what hit <v_him>.",
	"<k> took <v> by surprise.",
	"<v> was assassinated.",
	"<k> didn't take any prisoners from <v>.",
	"<k> pinned <v> to the wall with <k_his> <w>.",
	"<v> failed <v_his> weapon checks.",
}



function city_block.murder_message(killer, victim, sendto)
	if spam.test_key("kill" .. victim .. "15662") then
		return
	end
	spam.mark_key("kill" .. victim .. "15662", 30)

	local msg = murder_messages[math_random(1, #murder_messages)]
	msg = string.gsub(msg, "<v>", "<" .. rename.gpn(victim) .. ">")
	msg = string.gsub(msg, "<k>", "<" .. rename.gpn(killer) .. ">")

	local ksex = skins.get_gender_strings(killer)
	local vsex = skins.get_gender_strings(victim)

	msg = string.gsub(msg, "<k_himself>", ksex.himself)
	msg = string.gsub(msg, "<k_his>", ksex.his)

	msg = string.gsub(msg, "<v_himself>", vsex.himself)
	msg = string.gsub(msg, "<v_his>", vsex.his)
	msg = string.gsub(msg, "<v_him>", vsex.him)
	msg = string.gsub(msg, "<v_he>", vsex.he)

	if string.find(msg, "<w>") then
		local hitter = minetest.get_player_by_name(killer)
		if hitter then
			local wield = hitter:get_wielded_item()
			local def = minetest.registered_items[wield:get_name()]
			local meta = wield:get_meta()
			local description = meta:get_string("description")
			if description ~= "" then
				msg = string.gsub(msg, "<w>", "'" .. utility.get_short_desc(wield) .. "'")
			elseif def and def.description then
				local str = utility.get_short_desc(wield)
				if str == "" then
					str = "Potato Fist"
				end
				msg = string.gsub(msg, "<w>", str)
			end
		end
	end

	if type(sendto) == "string" then
		minetest.chat_send_player(sendto, "# Server: " .. msg)
	else
		minetest.chat_send_all("# Server: " .. msg)
	end
end



function city_block.hit_possible(p1pos, p2pos)
	-- Range limit, stops hackers with long reach.
	if vector_distance(p1pos, p2pos) > 6 then
		return false
	end

	-- Cannot attack through walls.
	-- But if node wouldn't stop an arrow, keep testing the line.
	--local raycast = minetest.raycast(p1pos, p2pos, false, false)

	-- This seems to cause random freezes and 100% CPU.
	--[[
	local los, pstop = minetest.line_of_sight(p1pos, p2pos)
	while not los do
		if throwing.node_blocks_arrow(minetest.get_node(vector_round(pstop)).name) then
			return false
		end
		local dir = vector.direction(pstop, p2pos)
		local ns = vector.add(pstop, dir)
		los, pstop = minetest.line_of_sight(ns, p2pos)
	end
	--]]

	return true
end



function city_block.send_to_jail(victim_pname, attack_pname)
	-- Killers don't go to jail if the victim is a registered cheater.
	if not sheriff.is_cheater(victim_pname) then
		local hitter = minetest.get_player_by_name(attack_pname)
		if hitter and jail.go_to_jail(hitter, nil) then
			minetest.chat_send_all(
				"# Server: Criminal <" .. rename.gpn(attack_pname) .. "> was sent to gaol for " ..
				city_block:get_adjective() .. " <" .. rename.gpn(victim_pname) .. "> within city limits.")
		end
	end
end



function city_block.handle_assassination(p2pos, victim_pname, attack_pname, melee)
	-- Bed position is only lost if player died outside city to a melee weapon.
	if not city_block:in_safebed_zone(p2pos) and melee then
		-- Victim doesn't lose their bed respawn if they were killed by a cheater.
		if not sheriff.is_cheater(attack_pname) then
			local pref = minetest.get_player_by_name(victim_pname)
			if pref then
				local meta = pref:get_meta()
				meta:set_int("was_assassinated", 1)
			end
			--minetest.chat_send_player(victim_pname, "# Server: Your bed is lost! You were assassinated in the wilds.")
			--beds.clear_player_spawn(victim_pname)
		end
	end
end



-- Note: this is called on the next server step after the punch, otherwise we
-- cannot know if the player died as a result.
function city_block.handle_consequences(player, hitter, melee, stomp)
	--minetest.log('handle_consequences')

	local victim_pname = player:get_player_name()
	local attack_pname = hitter:get_player_name()
	local time = os.time()
	local hp = player:get_hp()
	local p2pos = utility.get_head_pos(player:get_pos())
	local vpos = vector_round(p2pos)

	city_block.attackers[victim_pname] = attack_pname
	city_block.victims[victim_pname] = time

	-- Victim didn't die yet.
	if hp > 0 then
		return
	end

	default.detach_player_if_attached(player)

	-- Stomp messages are handled elsewhere.
	if not stomp then
		city_block.murder_message(attack_pname, victim_pname)
	end

	if city_block:in_city(p2pos) then
		local t0 = city_block.victims[attack_pname] or time
		local tdiff = (time - t0)

		if not city_block.attackers[attack_pname] then
			city_block.attackers[attack_pname] = ""
		end

		--[[
			Behavior Table (obtained through testing):

			In city-block area, no protection:
				A kills B, B did not retaliate -> A goes to jail
				A kills B, B had retaliated    -> Nobody jailed
				(The table is the same if A and B are inverted)

			In city-block area, protected by A (with nearby jail available):
				A kills B, B did not retaliate -> A goes to jail
				A kills B, B had retaliated    -> Nobody jailed
				B kills A, A did not retaliate -> B goes to jail
				B kills A, A had retaliated    -> B goes to jail
				(The table is the same if A and B are inverted, and protection is B's)

			Notes:
				A hit from A or B is considered retaliation if it happens very soon
				after the other player hit. Thus, if both A and B are hitting, then both
				are considered to be retaliating -- in that case, land ownership is used
				to resolve who should go to jail.

				It does not matter who hits first in a fight -- only who kills the other
				player first.

				If there is no jail available for a crook to be sent to, then nothing
				happens in any case, regardless of who wins the fight or owns the land.

		--]]

		-- Victim is "landowner" if area is protected, but they have access.
		local landowner = (minetest.test_protection(vpos, "") and
			not minetest.test_protection(vpos, victim_pname))

		-- Killing justified after provocation, but not if victim owns the land.
		if city_block.attackers[attack_pname] == victim_pname and
				tdiff < 30 and not landowner then
			return
		else
			-- Go to jail! Do not pass Go. Do not collect $200.
			city_block.send_to_jail(victim_pname, attack_pname)
		end
	else
		-- Player killed outside town.
		-- This only does something if the attack was with a melee weapon!
		city_block.handle_assassination(p2pos, victim_pname, attack_pname, melee)
	end
end



city_block.attackers = city_block.attackers or {}
city_block.victims = city_block.victims or {}



-- Return `true' to prevent the default damage mechanism.
-- Note: player is sometimes the hitter (player punches self). This is sometimes
-- necessary when a mod needs to punch a player, but has no entity that can do
-- the actual punch.
function city_block.on_punchplayer(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	--minetest.chat_send_all('city_block: on_punchplayer')

	if not player:is_player() then
		return
	end

	-- Callback is called even if player is dead. Shortcut.
	if player:get_hp() <= 0 or hitter:get_hp() <= 0 then
		return
	end

	--minetest.log('on_punchplayer')

	local melee_hit = true
	local stomp_hit = false
	local from_env = false
	local from_mob = false

	if tool_capabilities.damage_groups.from_stomp then
		stomp_hit = true
	end

	if tool_capabilities.damage_groups.from_env then
		from_env = true
	end

	if tool_capabilities.damage_groups.from_mob then
		from_mob = true
	end

	if tool_capabilities.damage_groups.from_arrow then
		-- Someone launched this weapon. The hitter is most likely the nearest
		-- player that isn't the player going to be hit.
		melee_hit = false

		--minetest.chat_send_all('from arrow')
	end

	if not hitter:is_player() then
		--minetest.chat_send_all('hitter not player')
		return
	end

	-- Random accidents happen to punished players during PvP.
	do
		local attacker = hitter:get_player_name()
		if sheriff.is_cheater(attacker) then
			if sheriff.punish_probability(attacker) then
				sheriff.punish_player(attacker)
			end
		end
	end

	local p1pos = utility.get_head_pos(hitter:get_pos())
	local p2pos = utility.get_head_pos(player:get_pos())

	-- Check if hit is physically possible (range, blockage, etc).
	if melee_hit and not city_block.hit_possible(p1pos, p2pos) then
		return true
	end

	-- PvP is disabled for players in jail. This fixes a possible way to exploit jail.
	if not from_env and (jail.is_player_in_jail(hitter) or jail.is_player_in_jail(player)) then
		minetest.chat_send_player(hitter:get_player_name(), "# Server: Brawling is not allowed in jail.")
		return true
	end

	-- PvP is disabled for dueling players still in their spawn area.
	if armor.have_dueling_respawn_protection(player, hitter) then
		return true
	end

	-- Admins cannot be punched.
	if gdac.player_is_admin(player) then
		return true
	end

	------------------------------------------------------------------------------
	-- After this point, we know the punch is to be allowed.
	-- Checks for allowance must go ABOVE.
	-- Consequences must go BELOW.
	------------------------------------------------------------------------------

	-- Let others hear sounds of nearby combat.
	if damage > 0 then
		ambiance.sound_play("player_damage", p2pos, 2.0, 30)
	end

	local pname = player:get_player_name()
	local hname = hitter:get_player_name()

	-- If hitter is self, punch was (most likely) due to game code.
	-- E.g., node damage or other environment hazard.
	if player == hitter then
		--minetest.chat_send_all('player == hitter')
		--minetest.chat_send_all(dump(from_env))
		--minetest.chat_send_all(dump(from_mob))
		--minetest.chat_send_all(dump(not melee_hit))
		if not from_env and not from_mob and not melee_hit then
			-- This one's a suicide.
			--minetest.chat_send_all('suicide!')
			armor.notify_duel_punch(pname, hname, stomp_hit, not melee_hit)
		end
		return
	end

	-- Stuff that happens when one player kills another.
	-- Must be executed on the next server step, so we can determine if victim
	-- really died! (This is because damage will often be modified.)
	minetest.after(0, function()
		local pref = minetest.get_player_by_name(pname)
		local href = minetest.get_player_by_name(hname)
		if pref and href then
			city_block.handle_consequences(pref, href, melee_hit, stomp_hit)
		end
	end)

	-- When we return from this punch handler, the HP-change callback(s) will be called.
	-- This notifies the dueling code that the next HP-change is from a player-to-player
	-- punch, so that we can handle the HP-change sensibly.
	if not from_env and not from_mob then
		-- Pass victim name, hitter name, boot-stomp flag, ranged/arrow flag.
		armor.notify_duel_punch(pname, hname, stomp_hit, not melee_hit)
	end
end
