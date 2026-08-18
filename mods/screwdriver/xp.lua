
-- Sub namespace so we're better isolated.
screwdriver.xp = screwdriver.xp or {}
screwdriver.xp.players = screwdriver.xp.players or {}

local QUEUE_SIZE = 50
local TIME_WINDOW = 10
local MAX_STREAK = 20
local XP_COOLDOWN = 60
local PLAYER_DIST = 2
local MAX_XP_PER_BPOS = 500

-- Localize for readability.
local players = screwdriver.xp.players

-- Handles granting XP for performing an action at a location,
-- with builtin anti-bot checks. You only need this function when the action
-- is theoretically repeatable (i.e., a bot could do it in a loop).
function screwdriver.reward_xp(pname, pref, npos, xp_type, xp_reward)
	local pdata = players[pname]
	if not pdata then
		pdata = {
			nodepos = {},
			prefpos = {},
			streak = 0,
			cooldown = 0,
			blockpos = {},
		}
		players[pname] = pdata
	end

	local v_equals = vector.equals
	local v_dist = vector.distance
	local ppos = vector.round(pref:get_pos())
	local tnow = os.time()

	local same_node = false
	local same_pos = false

	-- Check if player is interacting with a recent node position.
	for k = 1, #pdata.nodepos do
		local i = pdata.nodepos[k]
		if v_equals(i.pos, npos) and (i.time + TIME_WINDOW) > tnow then
			same_node = true
			break
		end
	end

	-- Check if player is standing near where they were standing previously.
	for k = 1, #pdata.prefpos do
		local i = pdata.prefpos[k]
		if v_dist(i.pos, ppos) < PLAYER_DIST and (i.time + TIME_WINDOW) > tnow then
			same_pos = true
			break
		end
	end

	if same_node or same_pos then
		pdata.streak = pdata.streak + 1
	end
	if not same_node and not same_pos then
		pdata.streak = 0
	end

	if pdata.streak > MAX_STREAK then
		pdata.cooldown = os.time() + XP_COOLDOWN
		pdata.streak = 0
	end

	if pdata.cooldown > tnow then
		return
	end

	-- Limit how much XP can be earned per mapblock.
	local blockpos = vector.floor(vector.divide(npos, 16))
	local bposkey = ("%d,%d,%d"):format(blockpos.x, blockpos.y, blockpos.z)
	local bpostab = pdata.blockpos
	local bposxp = bpostab[bposkey] or 0
	bpostab[bposkey] = bposxp + xp_reward
	if bposxp > MAX_XP_PER_BPOS then
		core.log("action", ("[XP] <%s> reached the max Build XP they can get (per mapblock) at %s")
			:format(pname, minetest.pos_to_string(npos))
		)
		return
	end

	-- Grant XP only if player and node position is different.
	-- (Makes botting a bit harder.)
	xp.add_xp(pname, xp_type, xp_reward)

	table.insert(pdata.nodepos, {pos=npos, time=tnow})
	table.insert(pdata.prefpos, {pos=ppos, time=tnow})

	-- Cycle queues by removing old elements.
	if #pdata.nodepos > QUEUE_SIZE then
		table.remove(pdata.nodepos, 1)
	end
	if #pdata.prefpos > QUEUE_SIZE then
		table.remove(pdata.prefpos, 1)
	end

	-- XP awarded.
	return true
end
