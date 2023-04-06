
if not minetest.global_exists("rockdrill") then rockdrill = {} end
rockdrill.modpath = minetest.get_modpath("silicon")

rockdrill.image = "rockdrill_rockdrill.png"
rockdrill.sound = "rockdrill"
rockdrill.name = "rockdrill:rockdrill"
rockdrill.description = "Rock Drill\n\nUses stored energy to blast stone.\nWon't function in protected areas.\nMust be charged to use."
rockdrill.range = 4

-- Localize for performance.
local math_floor = math.floor
local math_random = math.random

-- This is how many nodes the tool can blast.
rockdrill.uses = math_floor(65535/2500)

-- Find all blastable nodes in a small radius.
function rockdrill.find_stone(sp, wear)
	local traversal = {}
	local queue = {}
	local output = {}
	local curpos, hash, exists, name, found, norm, cb, depth
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
	local is_blastable = rockdrill.is_blastable
	local is_protected = minetest.test_protection
	queue[#queue+1] = {x=sp.x, y=sp.y, z=sp.z, d=1}

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

	if depth >= rockdrill.range then
		goto next
	end
	if wear > math_floor(65535-rockdrill.uses) then
		goto next
	end

	name = get_node(curpos).name
	found = false

	if is_blastable(name) then
		if not is_protected(curpos, "") then
			found = true
		end
	end

	if not found then
		goto next
	end

	traversal[hash] = depth
	if not exists then
		output[#output+1] = vector.new(curpos)
		wear = wear + rockdrill.uses
	end

	queue[#queue+1] = {x=curpos.x+1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x-1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y+1, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y-1, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z+1, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z-1, d=depth+1}

	::next::
	if #queue > 0 then
		goto continue
	end

	return output, wear
end

function rockdrill.is_blastable(name)
	-- Air is not blastable, and therefor not obtainable.
	if name == "air" then
		return
	end
	-- Check node def.
	local def = minetest.reg_ns_nodes[name] or minetest.registered_nodes[name]
	if def and def.groups then
		local lg = (def.groups.immovable or 0)
		local pg = (def.groups.protector or 0)
		if lg > 0 or pg > 0 then
			return
		end
		if def.liquidtype ~= "none" then
			return
		end
	end
	return true
end

function rockdrill.handle_node_drops(pos, user)
	---[[
	local node = minetest.get_node(pos)
	if node.name == "air" then
		return
	end
	local def = minetest.registered_nodes[node.name]
	if def and def.groups then
		local ig = (def.groups.immovable or 0)
		if ig > 0 then
			return
		end
	end
	local inv = user:get_inventory()
	if not inv then
		return
	end
	-- This function takes both nodetables and nodenames.
	-- Pass nodenames, because passing a nodetable gives wrong results.
	local drops = minetest.get_node_drops(node.name, "")

	for _, item in pairs(drops) do
		local stack = ItemStack(item) -- Itemstring to itemstack.
		local remain = inv:add_item("main", stack)
		if not remain:is_empty() then
			local p = {
				x = pos.x + math_random()/2 - 0.25,
				y = pos.y + math_random()/2 - 0.25,
				z = pos.z + math_random()/2 - 0.25,
			}
			minetest.add_item(p, remain)
		end
	end
	minetest.remove_node(pos)
	--]]

	--_nodeupdate.drop_node_as_entity(pos)
end

function rockdrill.on_use(itemstack, user, pt)
	if not user or not user:is_player() then
		return
	end
	if pt.type ~= "node" then
		return
	end
	local wear = itemstack:get_wear()
	if wear == 0 then
		-- Tool isn't charged!
		-- Once it is charged the first time, wear should never be 0 again.
		return
	end
	if wear > math_floor(65535-rockdrill.uses) then
		-- Tool has no charge left.
		return
	end
	local under = pt.under
	local blasted, newwear = rockdrill.find_stone(under, wear)
	if #blasted == 0 then
		return
	end
	ambiance.sound_play(rockdrill.sound, under, 1.0, 40)
	for k, v in ipairs(blasted) do
		local node = minetest.get_node(v)
		local def = minetest.registered_nodes[node.name]

		if def and def.on_blast then
			-- Behave as if blasted by TNT.
			local drops = def.on_blast(v, 1.0)
			if drops and type(drops) == "table" then
				for k, j in ipairs(drops) do
					minetest.add_item(v, j)
				end
			end
		else
			-- No on_blast function? Destroy node normally.
			rockdrill.handle_node_drops(v, user)
		end
		minetest.check_for_falling(v)
	end
	wear = newwear
	-- Don't let wear reach max or tool will be destroyed.
	if wear >= 65535 then
		wear = 65534
	end
	itemstack:set_wear(wear)
	return itemstack
end

if not rockdrill.run_once then
	minetest.register_tool(":" .. rockdrill.name, {
		description = rockdrill.description,
		inventory_image = rockdrill.image,
		wear_represents = "eu_charge",
		groups = {not_repaired_by_anvil = 1, disable_repair = 1},

		on_use = function(...)
			return rockdrill.on_use(...)
		end,
	})

	---[[
	minetest.register_craft({
		output = rockdrill.name,
		recipe = {
			{'moreores:tin_ingot', 'gem_cutter:blade', 'moreores:tin_ingot'},
			{'stainless_steel:ingot', 'techcrafts:electric_motor', 'stainless_steel:ingot'},
			{'', 'battery:battery', 'default:copper_ingot'},
		}
	})
	--]]

	local c = "rockdrill:core"
	local f = rockdrill.modpath .. "/rockdrill.lua"
	reload.register_file(c, f, false)

	rockdrill.run_once = true
end
