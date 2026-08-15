
local WRENCH_NAME = "scaffolding:scaffolding_wrench"



-- Non-reinforced scaffolding will self-destruct if falling nodes fall on it.
-- You can stop this by using reinforced scaffolding, but that also means you
-- can't climb inside it.
function scaffolding.on_falling_trigger(pos)
	-- Causes issues with nodes getting stuck in the falling state
	-- and clipped inside each other.
	--sfn.drop_node(pos)

	local node = minetest.get_node(pos)
	minetest.remove_node(pos)
	minetest.add_item(pos, node.name)
end



function scaffolding.on_place(itemstack, placer, pointed_thing)
	return core.item_place(itemstack, placer, pointed_thing)
end



function scaffolding.on_punch(pos, node, puncher)
	local tool = puncher:get_wielded_item():get_name()
	if tool and tool == WRENCH_NAME then
		local ndef = minetest.registered_nodes[node.name] or {}
		if ndef._scaffolding_alternate_name then
			node.name = ndef._scaffolding_alternate_name
			minetest.swap_node(pos, node)
		end
	end
end



local scaffolding_nodenames={"scaffolding:scaffolding","scaffolding:iron_scaffolding"}

minetest.register_on_dignode(function(pos, node)
	local i=1
	while scaffolding_nodenames[i]~=nil do
		if node.name==scaffolding_nodenames[i] then
			local np={x=pos.x, y=pos.y+1, z=pos.z}
			while minetest.env:get_node(np).name==scaffolding_nodenames[i] do
				minetest.env:remove_node(np)
				minetest.env:add_item(np, scaffolding_nodenames[i])
				np={x=np.x, y=np.y+1, z=np.z}
			end
		end
		i=i+1
	end
end)

local iron_scaffolding_nodenames={"scaffolding:platform","scaffolding:iron_platform"}

minetest.register_on_dignode(function(pos, node)
	local i=1
	while iron_scaffolding_nodenames[i]~=nil do
		if node.name==iron_scaffolding_nodenames[i] then
			local np={x=pos.x, y=pos.y, z=pos.z+1}
			while minetest.env:get_node(np).name==iron_scaffolding_nodenames[i] do
				minetest.env:remove_node(np)
				minetest.env:add_item(np, iron_scaffolding_nodenames[i])
				np={x=np.x, y=np.y, z=np.z+1}
			end
		end
		i=i+1
	end
end)

minetest.register_on_dignode(function(pos, node)
	local i=1
	while iron_scaffolding_nodenames[i]~=nil do
		if node.name==iron_scaffolding_nodenames[i] then
			local np={x=pos.x, y=pos.y, z=pos.z-1}
			while minetest.env:get_node(np).name==iron_scaffolding_nodenames[i] do
				minetest.env:remove_node(np)
				minetest.env:add_item(np, iron_scaffolding_nodenames[i])
				np={x=np.x, y=np.y, z=np.z-1}
			end
		end
		i=i-1
	end
end)

minetest.register_on_dignode(function(pos, node)
	local i=1
	while iron_scaffolding_nodenames[i]~=nil do
		if node.name==iron_scaffolding_nodenames[i] then
			local np={x=pos.x+1, y=pos.y, z=pos.z}
			while minetest.env:get_node(np).name==iron_scaffolding_nodenames[i] do
				minetest.env:remove_node(np)
				minetest.env:add_item(np, iron_scaffolding_nodenames[i])
				np={x=np.x+1, y=np.y, z=np.z}
			end
		end
		i=i+1
	end
end)

minetest.register_on_dignode(function(pos, node)
	local i=1
	while iron_scaffolding_nodenames[i]~=nil do
		if node.name==iron_scaffolding_nodenames[i] then
			local np={x=pos.x-1, y=pos.y, z=pos.z}
			while minetest.env:get_node(np).name==iron_scaffolding_nodenames[i] do
				minetest.env:remove_node(np)
				minetest.env:add_item(np, iron_scaffolding_nodenames[i])
				np={x=np.x-1, y=np.y, z=np.z}
			end
		end
		i=i-1
	end
end)

-- falling nodes go into pocket --

function scaffolding.dig_horx(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x + 1, y = pos.y, z = pos.z,}
	local nn = minetest.get_node(np)
	if nn.name == node.name then
		minetest.node_dig(np, nn, digger)
	end
end

function scaffolding.dig_horx2(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x - 1, y = pos.y, z = pos.z,}
	local nn = minetest.get_node(np)
	if nn.name == node.name then
		minetest.node_dig(np, nn, digger)
	end
end

function scaffolding.dig_horz(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x, y = pos.y, z = pos.z + 1,}
	local nn = minetest.get_node(np)
	if nn.name == node.name then
		minetest.node_dig(np, nn, digger)
	end
end

function scaffolding.dig_horz2(pos, node, digger)
	if digger == nil then return end
	local np = {x = pos.x , y = pos.y, z = pos.z - 1,}
	local nn = minetest.get_node(np)
	if nn.name == node.name then
		minetest.node_dig(np, nn, digger)
	end
end


