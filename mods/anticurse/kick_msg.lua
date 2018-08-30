
local foul = {
	"No bad words!",
	"No crudity! We breath only clean air here.",
	"Yuck.",
	"Stop breathing our air!",
	"Please don't pollute our air with foul language.",
	"Only desperate people spout that kind of talk.",
	"Disgusting. Clean up your chat.",
	"Ew!",
	"Now *that* was not appropriate talk.",
	"Now applying duct-tape to your chat.",
	"We don't live in Washington, DC. Yucky talk is not allowed.",
	"Express your feelings without fouling the chat.",
	"Crudity!",
	"This server does not comprehend noob talk.",
	"Do you come from Washington, DC?",
	"Oh, gross!",
	"That qualifies as verbal pollution.",
	"Not the best way to express oneself.",
	"Yuck. Yuck. Yuck.",
	"Phew. Good thing nobody actually read that!",
	"You have been warned for uninteresting language.",
	"Don't say rude talk here.",
	"Rude!",
}

local curse = {
	"Cursing is banned.",
	"No bad words!",
	"No cursing! Your chat needs handyman's secret weapon: duct tape.",
	"Shut up.",
	"Cursing is for noobs.",
	"What, you couldn't express yourself civilly?",
	"We don't live in Washington, DC. Talk like that is not allowed.",
	"You chat was duct-taped.",
	"Bad language. Do you happen to live in Chicago?",
	"Express your feelings without ruining the chat.",
	"This is for that bad word you used!",
	"Don't be profane.",
	"Profantiy!",
	"Consider yourself warned for uninteresting language.",
}



anticurse.get_kick_message = function(reason)
	local prefix = ""
	if reason == "foul" then
		local len = #foul
		local idx = math.random(1, len)
		if foul[idx] then
			return prefix..foul[idx]
		end
	elseif reason == "curse" then
		local len = #curse
		local idx = math.random(1, len)
		if curse[idx] then
			return prefix..curse[idx]
		end
	else
		return "Unknown reason. This is a bug."
	end
end
