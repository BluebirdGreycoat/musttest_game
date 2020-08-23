
chainsaw = chainsaw or {}
chainsaw.modpath = minetest.get_modpath("silicon")

-- Localize for performance.
local math_floor = math.floor

chainsaw.image = "chainsaw_chainsaw.png"
chainsaw.sound = "chainsaw"
chainsaw.name = "chainsaw:chainsaw"
chainsaw.description = "Chainsaw\n\nUses stored energy to cut timber.\nWon't function in protected areas.\nMust be charged to use."
chainsaw.range = 6

-- This is how many nodes the chainsaw can cut.
chainsaw.uses = math_floor(65535/1500)

-- Find all timber nodes in a small radius.
function chainsaw.find_timber(sp, wear)
	local traversal = {}
	local queue = {}
	local output = {}
	local curpos, hash, exists, name, found, norm, cb, depth
	local get_node_hash = minetest.hash_node_position
	local get_node = minetest.get_node
	local is_timber = chainsaw.is_timber
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

	if depth >= chainsaw.range then
		goto next
	end
	if wear > math_floor(65535-chainsaw.uses) then
		goto next
	end

	name = get_node(curpos).name
	found = false

	if is_timber(name) then
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
		wear = wear + chainsaw.uses
	end

	queue[#queue+1] = {x=curpos.x+1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x-1, y=curpos.y, z=curpos.z, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y+1, z=curpos.z, d=depth+1}

	if curpos.y > sp.y then
		queue[#queue+1] = {x=curpos.x, y=curpos.y-1, z=curpos.z, d=depth+1}
	end

	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z+1, d=depth+1}
	queue[#queue+1] = {x=curpos.x, y=curpos.y, z=curpos.z-1, d=depth+1}

	::next::
	if #queue > 0 then
		goto continue
	end

	return output, wear
end

function chainsaw.is_timber(name)
	local def = minetest.reg_ns_nodes[name]
	if def and def.groups then
		local lg = (def.groups.leaves or 0)
		if lg > 0 then
			return true
		end
		local tg = (def.groups.tree or 0)
		if tg > 0 then
			return true
		end
	end
	if name == "default:cactus" then
		return true
	end
end

function chainsaw.on_use(itemstack, user, pt)
	if pt.type ~= "node" then
		return
	end
	local wear = itemstack:get_wear()
	if wear == 0 then
		-- Tool isn't charged!
		-- Once it is charged the first time, wear should never be 0 again.
		return
	end
	if wear > math_floor(65535-chainsaw.uses) then
		-- Tool has no charge left.
		return
	end
	local under = pt.under
	local timber, newwear = chainsaw.find_timber(under, wear)
	if #timber == 0 then
		return
	end
	ambiance.sound_play(chainsaw.sound, under, 1.0, 40)
	for k, v in ipairs(timber) do
		_nodeupdate.drop_node_as_entity(v)
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

if not chainsaw.run_once then
	minetest.register_tool(":" .. chainsaw.name, {
		description = chainsaw.description,
		inventory_image = chainsaw.image,
		wear_represents = "eu_charge",
		groups = {not_repaired_by_anvil = 1, disable_repair = 1},

		on_use = function(...)
			return chainsaw.on_use(...)
		end,
	})

	---[[
	minetest.register_craft({
		output = chainsaw.name,
		recipe = {
			{"stainless_steel:ingot", "default:mese_crystal_fragment", "battery:battery"},
			{"fine_wire:copper", "techcrafts:electric_motor", "battery:battery"},
			{"", "", "stainless_steel:ingot"},
		}
	})
	--]]

	local c = "chainsaw:core"
	local f = chainsaw.modpath .. "/chainsaw.lua"
	reload.register_file(c, f, false)

	chainsaw.run_once = true
end
