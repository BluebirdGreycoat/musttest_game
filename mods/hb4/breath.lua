
breath = breath or {}
breath.modpath = minetest.get_modpath("hb4")

function breath.time()
	return math.random(20, 200)/10
end

-- Recursive algorithm.
local function floodfill(startpos, maxdepth)
	local traversal = {}
	local queue = {}
	local output = {}
	local curpos, hash, exists, name, found, norm, cb, depth
	local maxlength = 1
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
	startpos.d = 1
	queue[#queue+1] = startpos

	::continue::
	curpos = queue[#queue]
	queue[#queue] = nil

	depth = curpos.d
	curpos.d = nil

	hash = get_node_hash(curpos)
	exists = false
	if traversal[hash] then
		exists = true
		if depth >= traversal[hash] then
			goto next
		end
	end

	if depth >= maxdepth then
		goto next
	end

	name = get_node(curpos).name
	found = false

	if name == 'air' then
		found = true
	end

	if not found then
		goto next
	end

	traversal[hash] = depth
	if not exists then
		output[#output+1] = vector.new(curpos)
	end

	queue[#queue+1] = {x=curpos.x+1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x-1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y+1, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y-1, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z+1, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z-1, d=depth+1}

	if #queue > maxlength then
		maxlength = #queue
	end

	::next::
	if #queue > 0 then
		goto continue
	end

	--minetest.chat_send_all("# Server: Array size: " .. maxlength)
	return output
end


function breath.on_construct(pos)
end

function breath.on_destruct(pos)
end

function breath.on_timer(pos, elapsed)
end


function breath.ignite_nearby_gas(pos)
	--minetest.chat_send_player("MustTest", "# Server: Igniting gas @ " .. minetest.pos_to_string(pos) .. "!")
	pos = vector.round(pos)
	local gas = minetest.find_node_near(pos, 2, {"group:gas"})
	if gas then
		minetest.set_node(gas, {name="fire:basic_flame"})
	end
end


function breath.extinguish_torches_around(v)
	-- Find nearby torches.
	local min = {x=v.x-1, y=v.y-1, z=v.z-1}
	local max = {x=v.x+1, y=v.y+1, z=v.z+1}
	local torches = minetest.find_nodes_in_area(min, max, {"group:torch", "group:fire"})

	-- Replace nearby torches or fire with gas.
	for i = 1, #torches, 1 do
		local nn = minetest.get_node(torches[i]).name
		minetest.after(math.random(1, 10), function()
			-- We delayed a bit, we must ensure node has not changed.
			local n2 = minetest.get_node(torches[i]).name
			if n2 == nn then
				_nodeupdate.drop_node_as_entity(torches[i])
				local node = minetest.get_node(torches[i])
				if node.name == "air" then
					node.name = "gas:poison"
					minetest.set_node(torches[i], node)
				end
			end
		end)
	end
end


function breath.spawn_gas(pos)
	pos = vector.round(pos)
	ambiance.sound_play("tnt_ignite", pos, 1.0, 60)
	local positions = floodfill(pos, math.random(10, 30))
	local set_node = minetest.set_node

	for k, v in ipairs(positions) do
		set_node(v, {name="gas:poison"})
		breath.extinguish_torches_around(v)
	end
end

if not breath.run_once then
	-- 8 levels of gas, now depreciated.
	for i = 1, 8, 1 do
		minetest.register_alias("gas:poison_" .. i, "gas:poison")
	end

	minetest.register_node(":gas:poison", {
		drawtype = "airlike",
		--tiles = {"default_gold_block.png"},
		description = "Poison Gas",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		climbable = false,
		buildable_to = true,
		floodable = true,
		drop = "",
		post_effect_color = {a = 80, r = 127, g = 127, b = 127},
		drowning = 1,

		groups = {immovable=1, gas=1, flammable=3},

		on_construct = function(...)
			return breath.on_construct(...)
		end,

		on_destruct = function(...)
			return breath.on_destruct(...)
		end,

		on_timer = function(...)
			return breath.on_timer(...)
		end,

		-- Player should not be able to obtain node.
		on_collapse_to_entity = function(pos, node)
			-- Do nothing.
		end,

		-- Player should not be able to obtain node.
		on_finish_collapse = function(pos, node)
			minetest.remove_node(pos)
		end,
	})

	local c = "breath:core"
	local f = breath.modpath .. "/breath.lua"
	reload.register_file(c, f, false)

	breath.run_once = true
end
