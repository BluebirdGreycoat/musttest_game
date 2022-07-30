
local random = math.random



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

function mobs.mob_killed_player(self, player)
	local pname = player:get_player_name()

	-- Don't betray the presence of admin on his usual testing runs.
	if gdac_invis.is_invisible(pname) then
		return
	end

	local mname = utility.get_short_desc(self.description or "mob")
	local adv = kill_adv[random(1, #kill_adv)]
	if adv ~= "" then
		adv = adv .. " "
	end
	local adj = kill_adj[random(1, #kill_adj)]
	local ang = kill_ang[random(1, #kill_ang)]
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

function mobs.player_killed_mob(self, player)
	local pname = player:get_player_name()
	if message_spam_avoidance[pname] then
		return
	end

	-- Don't betray the presence of the admin going on a trash run.
	if gdac_invis.is_invisible(pname) then
		return
	end

	local mname = utility.get_short_desc(self.description or "mob")

	local msg = murder_messages[random(1, #murder_messages)]
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
		local adv = kill_adv[random(1, #kill_adv)]
		if adv ~= "" then
			adv = adv .. " "
		end
		msg = string.gsub(msg, "<brutally>", adv)
	end

	if string.find(msg, "<slain>") then
		local adj = kill_adj[random(1, #kill_adj)]
		msg = string.gsub(msg, "<slain>", adj)
	end

	if string.find(msg, "<slew>") then
		local adj = kill_adj2[random(1, #kill_adj2)]
		msg = string.gsub(msg, "<slew>", adj)
	end

	if string.find(msg, "<slay>") then
		local adj = kill_adj3[random(1, #kill_adj3)]
		msg = string.gsub(msg, "<slay>", adj)
	end

	if string.find(msg, "<pain>") then
		local adj = pain_words[random(1, #pain_words)]
		msg = string.gsub(msg, "<pain>", adj)
	end

	if string.find(msg, "<angry>") then
		local ang = kill_ang[random(1, #kill_ang)]
		if ang ~= "" then
			ang = ang .. " "
		end
		msg = string.gsub(msg, "<angry>", ang)
	end

	if string.find(msg, "<an_angry_k>") then
		local replace = ""

		local angry = kill_ang[random(1, #kill_ang)]
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
	minetest.after(random(10, 60*2), function()
		message_spam_avoidance[pname] = nil
	end)
end
