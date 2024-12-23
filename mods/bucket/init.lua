-- Minetest 0.4 mod: bucket
-- See README.txt for licensing and other information.

-- Localize for performance.
local math_floor = math.floor

minetest.register_alias("bucket", "bucket:bucket_empty")
minetest.register_alias("bucket_water", "bucket:bucket_water")
minetest.register_alias("bucket_lava", "bucket:bucket_lava")

minetest.register_craft({
	output = 'bucket:bucket_empty 1',
	recipe = {
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'', 'default:steel_ingot', ''},
	}
})

minetest.register_craft({
	output = 'bucket:bucket_empty 1',
	recipe = {
		{'moreores:tin_ingot', '', 'moreores:tin_ingot'},
		{'', 'moreores:tin_ingot', ''},
	}
})

bucket = {}
bucket.liquids = {}



-- Used to harm (and possibly kill) a player *after* the bucket on_use code has run.
-- This solves a problem with being able to duplicate buckets when dying while collecting lava.
-- Note the use of `minetest.after`.
bucket.harm_player_after =
function(pname, harm)
  minetest.after(0, function()
    local player = minetest.get_player_by_name(pname)
    if player and player:is_player() then
			utility.damage_player(player, "heat", harm)

			if player:get_hp() == 0 then
				minetest.chat_send_all("# Server: <" .. rename.gpn(pname) .. "> died while bucketing something hot!")
			end
    end
  end)
end



local function check_protection(pos, name, text)
	local success, gl = rc.get_ground_level_at_pos(pos)
	if not success then
		minetest.chat_send_player(name, "# Server: That position is in the Void!")
		easyvend.sound_error(name)
		return true
	end

	if rc.liquid_forbidden_at(pos) and text:find("place") then
		minetest.chat_send_player(name, "# Server: Liquids forbidden in this region.")
		easyvend.sound_error(name)
		return true
	end

	-- Don't let players make huge liquid griefs. By MustTest.
	-- But we allow river water to be placed above ground, because it does not spread.
	if not string.find(text, "river_water_source") then
		-- Above 10000 XP, player can use buckets.
		-- Note: this will allow high-XP players to place lava (which ignores
		-- protection) above ground. If such a player decides to grief somebody,
		-- I guess you'll need to form a committee! (You can still use city blocks
		-- to protect builds.)
		local lxp = (xp.get_xp(name, "digxp") >= 10000)
		if not lxp or sheriff.is_cheater(name) then
			if pos.y > gl and string.find(text, "place") then
				minetest.chat_send_player(name, "# Server: Don't do that above ground!")
				easyvend.sound_error(name)
				return true
			end
		end
	end

	if minetest.is_protected(pos, name) then
		minetest.log("action", (name ~= "" and name or "A mod")
			.. " tried to " .. text
			.. " at protected position "
			.. minetest.pos_to_string(pos)
			.. " with a bucket")
		minetest.record_protection_violation(pos, name)
    minetest.chat_send_player(name, "# Server: Nope. Not on someone else's land!")
    easyvend.sound_error(name)
		return true
	end
	return false
end


local function node_in_group(name, list)
	if type(list) == "string" then
		return (name == list)
	elseif type(list) == "table" then
		for k, v in ipairs(list) do
			if name == v then
				return true
			end
		end
	end
	return false
end


-- Register a new liquid
--    source = name of the source node
--    flowing = name of the flowing node
--    itemname = name of the new bucket item (or nil if liquid is not takeable)
--    inventory_image = texture of the new bucket item (ignored if itemname == nil)
--    name = text description of the bucket item
--    groups = (optional) groups of the bucket item, for example {water_bucket = 1}
-- This function can be called from any mod (that depends on bucket).
function bucket.register_liquid(source, flowing, itemname, placename, inventory_image, name, groups)
	if type(source) == "string" then
		bucket.liquids[source] = {
			source = source,
			flowing = flowing,
			itemname = itemname,
		}
	else
		assert(type(source) == "table")
		for k, v in ipairs(source) do
			assert(type(v) == "string")
			bucket.liquids[v] = {
				source = source,
				flowing = flowing,
				itemname = itemname,
			}
		end
	end
	if type(flowing) == "string" then
		bucket.liquids[flowing] = {
			source = source,
			flowing = flowing,
			itemname = itemname,
		}
	else
		assert(type(flowing) == "table")
		for k, v in ipairs(flowing) do
			assert(type(v) == "string")
			bucket.liquids[v] = {
				source = source,
				flowing = flowing,
				itemname = itemname,
			}
		end
	end

	if itemname ~= nil then
		minetest.register_craftitem(itemname, {
			description = name,
			inventory_image = inventory_image,
			stack_max = 1,
			liquids_pointable = true,
			groups = groups,

			on_place = function(itemstack, user, pointed_thing)
				if not user or not user:is_player() then
					return itemstack
				end

				-- Must be pointing to node
				if pointed_thing.type ~= "node" then
					return
				end

				local node = minetest.get_node_or_nil(pointed_thing.under)
				local ndef = node and minetest.reg_ns_nodes[node.name]

				-- Call on_rightclick if the pointed node defines it
				if ndef and ndef.on_rightclick and
				   user and not user:get_player_control().sneak then
					return ndef.on_rightclick(pointed_thing.under, node, user, itemstack)
				end

				local lpos

				-- Check if pointing to a buildable node
				if ndef and ndef.buildable_to then
					-- buildable; replace the node
					lpos = pointed_thing.under
				elseif node_in_group(node.name, flowing) or node_in_group(node.name, source) then
					-- flow version of bucket contents, replace the node.
					lpos = pointed_thing.under
				else
					-- not buildable to; place the liquid above
					-- check if the node above can be replaced

					lpos = pointed_thing.above
					node = minetest.get_node_or_nil(lpos)
					local above_ndef = node and
						minetest.reg_ns_nodes[node.name]

					if not above_ndef or not above_ndef.buildable_to then
						-- do not remove the bucket with the liquid
						return itemstack
					end
				end
				
				-- Cityblock check.
				if city_block:in_disallow_liquid_zone(lpos, user) then
					minetest.chat_send_player(user:get_player_name(), "# Server: Don't do that in town!")
					easyvend.sound_error(user:get_player_name())
					return itemstack
				end

				if check_protection(lpos, user:get_player_name(), "place " .. placename) then
					return
				end

				-- this causes a bug with placing water in protection.
				--minetest.place_node(lpos, {name = placename})
				minetest.set_node(lpos, {name = placename})
				minetest.check_for_falling(lpos)

				-- Notify dirt.
				dirtspread.on_environment(lpos)
				droplift.notify(lpos)

				return ItemStack("bucket:bucket_empty")
			end
		})
	end
end

minetest.register_craftitem("bucket:bucket_empty", {
	description = "Empty Bucket",
	inventory_image = "bucket.png",
	-- Empty buckets are stackable.
	--stack_max = 99,
	liquids_pointable = true,

	on_use = function(itemstack, user, pointed_thing)
		-- Must be pointing to node
		if pointed_thing.type ~= "node" then
			return
		end
		-- Check if pointing to a liquid source
		local node = minetest.get_node(pointed_thing.under)
		local liquiddef = bucket.liquids[node.name]
		local item_count = user:get_wielded_item():get_count()

		if liquiddef ~= nil and liquiddef.itemname ~= nil and node_in_group(node.name, liquiddef.source) then
			if check_protection(pointed_thing.under, user:get_player_name(), "take " .. node.name) then
				return
			end

			-- default set to return filled bucket
			local giving_back = liquiddef.itemname

			-- check if holding more than 1 empty bucket
			if item_count > 1 then

				-- if space in inventory add filled bucked, otherwise drop as item
				local inv = user:get_inventory()
				if inv:room_for_item("main", {name=liquiddef.itemname}) then
					inv:add_item("main", liquiddef.itemname)
				else
					local pos = user:get_pos()
					pos.y = math_floor(pos.y + 0.5)
					minetest.add_item(pos, liquiddef.itemname)
				end

				-- set to return empty buckets minus 1
				giving_back = "bucket:bucket_empty "..tostring(item_count-1)

			end

			if node.name == "default:lava_source" then
				minetest.add_node(pointed_thing.under, {name="fire:basic_flame"})
				local pos = user:get_pos()
				minetest.sound_play("default_cool_lava", {pos = pos, max_hear_distance = 16, gain = 0.25}, true)
				if not heatdamage.is_immune(user:get_player_name()) then
					bucket.harm_player_after(user:get_player_name(), 2*500)
				end
			else
				minetest.add_node(pointed_thing.under, {name="air"})
			end

			return ItemStack(giving_back)
		end
	end,
})

bucket.register_liquid(
	{"default:water_source", "cw:water_source"},
	{"default:water_flowing", "cw:water_flowing"},
	"bucket:bucket_water",
	"default:water_source",
	"bucket_water.png",
	"Water Bucket",
	{water_bucket = 1}
)

bucket.register_liquid(
	"default:river_water_source",
	"default:river_water_flowing",
	"bucket:bucket_river_water",
	"default:river_water_source",
	"bucket_river_water.png",
	"Salt Water Bucket",
	{water_bucket = 1}
)

bucket.register_liquid(
	"default:lava_source",
	"default:lava_flowing",
	"bucket:bucket_lava",
	"default:lava_source",
	"bucket_lava.png",
	"Lava Bucket"
)

-- Old corium buckets convert to lava. Corium no longer exists.
minetest.register_alias("corium:bucket", "bucket:bucket_lava")

minetest.register_craft({
	type = "fuel",
	recipe = "bucket:bucket_lava",
	burntime = 360,
	replacements = {{"bucket:bucket_lava", "bucket:bucket_empty"}},
})


