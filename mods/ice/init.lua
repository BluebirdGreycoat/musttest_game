
ice = ice or {}
ice.modpath = minetest.get_modpath("ice")

if minetest.get_modpath("reload") then
	local c = "ice:core"
	local f = ice.modpath .. "/init.lua"
	if not reload.file_registered(c) then
		reload.register_file(c, f, false)
	end
end

-- May be used as argument to math.random().
function ice.minmax_time()
	return ice.min_time, ice.max_time
end

ice.min_time = 40
ice.max_time = 300

function ice.on_ice_notify(pos, other)
	--minetest.chat_send_player("MustTest", "# Server: Ice notify @ " .. minetest.pos_to_string(pos) .. "!")

	local timer = minetest.get_node_timer(pos)
	--if not timer:is_started() then
		timer:start(math.random(ice.minmax_time()))
	--end
end



-- Here is where we calculate the ice freeze/melt logic.
function ice.on_ice_timer(pos, elapsed)
	--minetest.chat_send_player("MustTest", "# Server: Icemelt @ " .. minetest.pos_to_string(pos) .. "!")

	local nn = minetest.get_node(pos).name

	if nn == "default:ice" then
		-- Transform thick, opaque ice to thin ice.
		if minetest.find_node_near(pos, 1, "group:melt_around") then
			minetest.set_node(pos, {name="ice:thin_ice"})
			return
		end
	elseif nn == "ice:thin_ice" then
		-- Melt thin ice to liquid.
		local minp = {x=pos.x-1, y=pos.y-1, z=pos.z-1}
		local maxp = {x=pos.x+1, y=pos.y+1, z=pos.z+1}
		local warm = minetest.find_nodes_in_area(minp, maxp, "group:melt_around")
		local heat = minetest.find_nodes_in_area(minp, maxp, {"group:flame", "group:hot"})
		if #warm >= 3 or #heat > 0 then
			minetest.set_node(pos, {name="default:water_source"})
			minetest.check_for_falling(pos)
			return
		end

		-- Turn thin ice opaque again.
		local above = minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name
		if snow.is_snow(above) or above == "default:snowblock" then
			minetest.set_node(pos, {name="default:ice"})
			return
		end
	end
end

if not ice.registered then
	minetest.register_node("ice:thin_ice", {
		drawtype = "glasslike",
		description = "Clear Ice\n\nThis can be made to melt.\nApply heat for results.",
		tiles = {"ice_thin_ice.png"},
		use_texture_alpha = true,
		is_ground_content = true, -- Don't interfere with cavegen.
		paramtype = "light",
		groups = utility.dig_groups("ice", {
			ice = 1, melts = 1, cold = 1,
			want_notify = 1,
			slippery = 5,
		}),
		--_melts_to = "default:water_source",
		sounds = default.node_sound_glass_defaults(),

		-- Can be called by lavamelt ABM.
		on_melt = function(pos, other)
			minetest.remove_node(pos)
		end,

		-- Hack to notify self.
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(math.random(ice.minmax_time()))
		end,

		on_notify = function(...)
			return ice.on_ice_notify(...)
		end,

		on_timer = function(...)
			return ice.on_ice_timer(...)
		end,
	})

	ice.registered = true
end
