
if not minetest.global_exists("tinderbox") then tinderbox = {} end
tinderbox.modpath = minetest.get_modpath("tinderbox")

local TINDERBOX_USES = 256

function tinderbox.on_use(itemstack, user, pt)
	if not user or not user:is_player() then return end
	local pname = user:get_player_name()

	local fakestack = ItemStack("dusts:coal")
	fakestack = real_torch.relight(fakestack, user, pt)
	if not fakestack or fakestack:get_count() ~= 0 then return end -- Tinderbox was not used.

	if itemstack:get_name() == "tinderbox:tinderbox" and itemstack:get_count() > 1 then
		-- Multiple tinderboxes are held. Must separate them and add wear.
		itemstack:take_item()
		local newitemstack = ItemStack("tinderbox:tinderbox " .. itemstack:get_count()) -- Make itemstack copy.

		-- Add leftover tinderboxes somewhere else in player's inventory.
		-- This has to be done inside an after() invocation, to avoid conflict with the on_use function.
		minetest.after(0, function()
			local user = minetest.get_player_by_name(pname)
			if not user or not user:is_player() then return end
			if user:get_hp() == 0 then return end
			local inv = user:get_inventory()
			if not inv then return end
			local leftover = inv:add_item("main", newitemstack)
			if leftover:get_count() ~= 0 then
				minetest.chat_send_player(pname, "# Server: You dropped your tinderboxes!")
			end
			minetest.item_drop(leftover, nil, vector.add(user:get_pos(), {x=0, y=1, z=0}))
		end)

		itemstack = ItemStack("tinderbox:tinderbox_used")
		itemstack:add_wear(65535/TINDERBOX_USES)
		return itemstack
	end

	-- Player holds single tinderbox. Must check if it is item or tool.
	if itemstack:get_name() == "tinderbox:tinderbox" then
		-- It's the craftitem; we must replace it with the tool.
		itemstack:set_name("tinderbox:tinderbox_used")
		itemstack:add_wear(65535/TINDERBOX_USES)
		return itemstack
	elseif itemstack:get_name() == "tinderbox:tinderbox_used" then
		-- It's the tool variant, we can add wear directly.
		itemstack:add_wear(65535/TINDERBOX_USES)
		return itemstack
	end
end

if not tinderbox.registered then
	local DESC = "Tinderbox"

	-- Tinderbox item (needed because only craftitems are stackable).
	minetest.register_craftitem("tinderbox:tinderbox", {
		description = DESC,
		inventory_image = "tinderbox_tinderbox.png",
		groups = {flammable = 2, not_repaired_by_anvil = 1, disable_repair = 1},
		on_use = function(...) return tinderbox.on_use(...) end,
	})
	
	-- Tinderbox tool (needed because items cannot be given a wear value).
	minetest.register_tool("tinderbox:tinderbox_used", {
		description = DESC,
		inventory_image = "tinderbox_tinderbox.png",
		groups = {flammable = 2, not_repaired_by_anvil = 1, disable_repair = 1},
		on_use = function(...) return tinderbox.on_use(...) end,
		wear_represents = "tinderbox",
	})

	-- Tinderbox craft.
	minetest.register_craft({
		output = "tinderbox:tinderbox",
		recipe = {
			{'', 'group:stick', ''},
			{'group:stick', 'dusts:coal', 'group:stick'},
			{'', 'group:stick', 'group:leaves'},
		},
	})

	minetest.register_craft({
		output = "tinderbox:tinderbox",
		recipe = {
			{'', 'group:stick', ''},
			{'group:stick', 'kalite:dust', 'group:stick'},
			{'', 'group:stick', 'group:leaves'},
		},
	})

	minetest.register_craft({
		output = "tinderbox:tinderbox",
		recipe = {
			{'', 'group:stick', ''},
			{'group:stick', 'charcoal:charcoal', 'group:stick'},
			{'', 'group:stick', 'group:leaves'},
		},
	})

	local c = "tinderbox:core"
	local f = tinderbox.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	tinderbox.registered = true
end

