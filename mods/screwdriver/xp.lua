
-- Sub namespace so we're better isolated.
screwdriver.xp = screwdriver.xp or {}
screwdriver.xp.players = screwdriver.xp.players or {}

local QUEUE_SIZE = 50
local TIME_WINDOW = 5

-- Localize for readability.
local players = screwdriver.xp.players

function screwdriver.handle_xp(pname, pref, npos, xp_reward)
	local pdata = players[pname] or {
		nodepos = {},
		prefpos = {},
	}

	local v_equals = vector.equals
	local ppos = vector.round(pref:get_pos())
	local tnow = os.time()

	local same_node = false
	local same_pos = false

	for k = 1, #pdata.nodepos do
		local i = pdata.nodepos[k]
		if v_equals(i.pos, npos) and (i.time + TIME_WINDOW) > tnow then
			same_node = true
			break
		end
	end

	for k = 1, #pdata.prefpos do
		local i = pdata.prefpos[k]
		if v_equals(i.pos, ppos) and (i.time + TIME_WINDOW) > tnow then
			same_pos = true
			break
		end
	end

	if same_node and same_pos then
		return
	end

	-- Grant XP only if player and node position is different.
	-- (Makes botting a bit harder.)
	xp.add_xp(pname, "buildxp", xp_reward)

	table.insert(pdata.nodepos, {pos=npos, time=tnow})
	table.insert(pdata.prefpos, {pos=ppos, time=tnow})
	if #pdata.nodepos > QUEUE_SIZE then
		table.remove(pdata.nodepos, 1)
	end
	if #pdata.prefpos > QUEUE_SIZE then
		table.remove(pdata.prefpos, 1)
	end

	players[pname] = pdata
end
