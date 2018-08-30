
torchmelt = torchmelt or {}
torchmelt.modpath = minetest.get_modpath("torchmelt")

torchmelt.min_time = 15
torchmelt.max_time = 80

function torchmelt.start_melting(pos)
	local snow = minetest.find_node_near(pos, 2, snow.get_names())
	if snow then
		local air = minetest.find_node_near(pos, 1, "air")
		if air then
			minetest.set_node(air, {name="torchmelt:melter"})
		end
	end
end

function torchmelt.on_construct(pos)
	minetest.get_node_timer(pos):start(math.random(torchmelt.min_time, torchmelt.max_time))
end

local function torch_melt(pos)
	-- Perform the melting from the position of the heat source.
	local heat = minetest.find_node_near(pos, 1, "group:melt_around")
	if not heat then
		return false
	end
	local minp = vector.subtract(heat, 1)
	local maxp = vector.add(heat, 1)
	local snow = minetest.find_nodes_in_area(minp, maxp, snow.get_names())
	if #snow > 0 then
		-- Remove a random snow node.
		local p = snow[math.random(1, #snow)]
		minetest.remove_node(p)
		minetest.check_for_falling(p)
		return true
	end
	return false
end

function torchmelt.on_timer(pos, elapsed)
	--minetest.chat_send_player("MustTest", "# Server: Torchmelt @ " .. minetest.pos_to_string(pos) .. "!")

	if torch_melt(pos) then
		minetest.get_node_timer(pos):start(math.random(torchmelt.min_time, torchmelt.max_time))
	else
		--minetest.chat_send_player("MustTest", "# Server: Removed node @ " .. minetest.pos_to_string(pos) .. "!")

		minetest.get_node_timer(pos):stop()
		minetest.remove_node(pos) -- Remove the utility node.
	end
end

if not torchmelt.registered then
  minetest.register_node("torchmelt:melter", {
    drawtype = "airlike",
    description = "Torch Heat Source (Please Report to Admin)",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    groups = {immovable = 1},
    climbable = false,
    buildable_to = true,
    floodable = true,
    drop = "",

		on_construct = function(...)
			return torchmelt.on_construct(...)
		end,

    on_timer = function(...)
      return torchmelt.on_timer(...)
    end,

    on_finish_collapse = function(pos, node)
      minetest.remove_node(pos)
    end,

    on_collapse_to_entity = function(pos, node)
      -- Do nothing.
    end,
  })

	local c = "torchmelt:core"
	local f = torchmelt.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	torchmelt.registered = true
end


