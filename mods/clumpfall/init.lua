--[[
   Copyright 2018 Noodlemire

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--]]

clumpfall = {} --global variable

--the maximum radius of blocks to cause to fall at once. 
clumpfall.clump_radius = 1

--Short for modpath, this stores this really long but automatic modpath get
local mp = minetest.get_modpath(minetest.get_current_modname()) .. "/"

--Load other lua components
dofile(mp.."functions.lua")
dofile(mp.."override.lua")

function clumpfall.update_nodedef(name, def)
	def.groups = def.groups or {}

	local get_group = function(grp)
		if def.groups[grp] then
			return def.groups[grp]
		end
		return 0
	end

	if name ~= "air" and name ~= "ignore" and
		get_group("falling_node") == 0 and --Don't need to affect nodes that already fall by themselves
		get_group("attached_node") == 0 and --Same thing for nodes in this group, which fall when no longer attached to another node
		get_group("liquid") == 0 and --Same thing for nodes in this group, which do technically fall and spread around
		get_group("immovable") == 0 and
		get_group("leaves") == 0 and
		get_group("always_stable") == 0 and
		get_group("disable_clump_fall") == 0 and
		get_group("unbreakable") == 0 then --Lastly, if a block is invulnerable to begin with, it shouldn't fall down like a typical node
		def.groups.clump_fall_node = 1
	else
		def.groups.clump_fall_node = 0
	end

	local do_clump_fall = clumpfall.functions.do_clump_fall

	---[[
	local old_on_dig = def.on_dig
	function def.on_dig(pos, node, digger)
		if old_on_dig ~= nil then
			old_on_dig(pos, node, digger)
		else
			-- Execute MT default function.
			core.node_dig(pos, node, digger)
		end

		if pos.y > 1000 then
			do_clump_fall(pos)
		end
	end
	--]]

	local old_after_place_node = def.after_place_node
	function def.after_place_node(pos, placer, itemstack, pt)
		local r
		if old_after_place_node ~= nil then
			r = old_after_place_node(pos, placer, itemstack, pt)
		end

		if pos.y > 1000 then
			minetest.after(math.random(1, 10), function()
				do_clump_fall(pos)
			end)
		end
		return r
	end

	---[[
	local old_on_punch = def.on_punch
	function def.on_punch(pos, node, puncher, pt)
		local r
		if old_on_punch ~= nil then
			r = old_on_punch(pos, node, puncher, pt)
		else
			r = core.node_punch(pos, node, puncher, pt)
		end

		if pos.y > 1000 then
			do_clump_fall(pos)
		end
		return r
	end
	--]]

	local old_on_place = def.on_place
	function def.on_place(itemstack, placer, pt)
		local a, b, c
		if old_on_place ~= nil then
			a, b, c = old_on_place(itemstack, placer, pt)
		else
			a, b, c = core.item_place(itemstack, placer, pt)
		end

		if b and c and c.y > 1000 then
			minetest.after(math.random(1, 10), function()
				do_clump_fall(c)
			end)
		end
		return a, b, c
	end
end


