
local function transform_visible(pos)
	local node = minetest.get_node(pos)

	local minp = vector.add(pos, {x=-2, y=-2, z=-2})
	local maxp = vector.add(pos, {x=2, y=2, z=2})
	local names = {"nether:portal_hidden"}

	local points, counts = minetest.find_nodes_in_area(minp, maxp, names)
	if #points == 0 then
		return
	end

	local plen = #points
	local ndef = minetest.registered_nodes["nether:portal_liquid"]

	for k = 1, plen, 1 do
		local tar = points[k]

		minetest.swap_node(tar, {
			name = "nether:portal_liquid",
			param2 = node.param2,
		})

		-- Manually run callback.
		ndef.on_construct(tar)
	end

	ambiance.sound_play("nether_portal_ignite", pos, 1.0, 64)
end



local function transform_hidden(pos)
	local node = minetest.get_node(pos)

	local minp = vector.add(pos, {x=-2, y=-2, z=-2})
	local maxp = vector.add(pos, {x=2, y=2, z=2})
	local names = {"nether:portal_liquid"}

	local points, counts = minetest.find_nodes_in_area(minp, maxp, names)
	if #points == 0 then
		return
	end

	local plen = #points
	local ndef = minetest.registered_nodes["nether:portal_hidden"]

	for k = 1, plen, 1 do
		local tar = points[k]

		minetest.swap_node(tar, {
			name = "nether:portal_hidden",
			param2 = node.param2,
		})

		-- Manually run callback.
		ndef.on_construct(tar)
	end

	ambiance.sound_play("nether_portal_extinguish", pos, 1.0, 64)
end



function nether.liquid_on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_int("time", os.time())

	local timer = minetest.get_node_timer(pos)
	timer:start(1)
end



function nether.liquid_on_destruct(pos)
	-- This is transient damage! The gate can be reactivated.
	obsidian_gateway.on_damage_gate(pos, true)
end



-- Timer function should execute once per second.
function nether.liquid_on_timer(pos, elapsed)
	if math.random(1, 3) == 1 then
		ambiance.sound_play("nether_portal_ambient", pos, 1.0, 10)
	end

	local meta = minetest.get_meta(pos)
	local color = meta:get_string("color")

	if not color or color == "" then
		color = "gold"
	end

	local image = "nether_particle_anim3.png"
	local pref = hb4.nearest_player(pos)
	if pref then
		local dist = vector.distance(pref:get_pos(), pos)
		-- Player inside node? Show bubbles instead of sparks.
		if dist < 1 then
			image = "nether_particle_anim2.png"
		elseif dist > 10 then
			-- Player far from node? Swap to invisible form.
			transform_hidden(pos)
			return
		end
	end

	local d = 0.5
	minetest.add_particlespawner({
		amount = 5,
		time = 1.1,
		minpos = {x=pos.x-d, y=pos.y-d, z=pos.z-d},
		maxpos = {x=pos.x+d, y=pos.y+d, z=pos.z+d},
		minvel = {x=0, y=-d, z=0},
		maxvel = {x=0, y=d, z=0},
		minacc = {x=0, y=0, z=0},
		maxacc = {x=0, y=0, z=0},
		minexptime = 1.5,
		maxexptime = 2.5,
		minsize = 1,
		maxsize = 1.5,
		collisiondetection = true,
		collision_removal = true,
		texture = image .. "^[colorize:" .. color .. ":alpha",
		vertical = false,

		animation = {
			type = "vertical_frames",
			aspect_w = 7,
			aspect_h = 7,

			-- Disabled for now due to causing older clients to hang.
			--length = -1,
			length = 1.0,
		},

		glow = 14,
	})

	-- Keep running.
	return true
end



function nether.hidden_on_construct(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(0.5)
end



function nether.hidden_on_destruct(pos)
	-- This is transient damage! The gate can be reactivated.
	obsidian_gateway.on_damage_gate(pos, true)
end



-- Timer function should execute once per 1/2 second.
function nether.hidden_on_timer(pos, elapsed)
	local pref = hb4.nearest_player(pos)

	if pref then
		-- Player near node? Swap to visible form.
		if vector.distance(pref:get_pos(), pos) < 8 then
			transform_visible(pos)
			return
		end
	end

	-- Keep running.
	return true
end
