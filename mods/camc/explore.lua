
camc.EXPLORE_ACTIVE = camc.EXPLORE_ACTIVE or 0

function camc.periodic_explore_update()
end

function camc.start_exploring()
	camc.EXPLORE_ACTIVE = 1
	return true
end

function camc.stop_exploring()
	camc.EXPLORE_ACTIVE = 0
end
