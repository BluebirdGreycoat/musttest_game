
if not minetest.global_exists("exchange") then exchange = {} end
exchange.modpath = minetest.get_modpath("easyvend")

-- Note: exchange rate is doubled because only lumps are accepted now, not ingots.
-- (Previously most folks would double their ingots before exchanging them.)
-- Note: must not include infinitely-renewable commodities, like mese.
--
-- WARNING: do not include many exchange types. This makes certain kinds of
-- exploits easier (e.g., abusing the exchange to simply transform one kind of
-- item into another).
exchange.types = {
	{name = "Gold", key = "gold", rate = 60, image = "default_gold_lump.png", item = "default:gold_lump", block = "default:goldblock"},
	{name = "Silver", key = "silver", rate = 50, image = "moreores_silver_lump.png", item = "moreores:silver_lump", block = "moreores:silver_block"},
}

for k, v in ipairs(exchange.types) do
	local function update_meta(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext",
			v.name .. " Commodity Exchange\nPunch to exchange " .. v.key ..
			" for MG\nHold shift to get " .. v.key .. " (paying MG)\nSell 1 " .. v.key .. " lump for " .. v.rate .. " MG, buy 1 for " .. v.rate + 10 .. " MG" ..
			"\nHold 'E' to multiply x10")
	end

	exchange["on_punch_" .. v.key] = function(pos, node, puncher, pt)
		update_meta(pos)

		local pname = puncher:get_player_name()
		local inv = puncher:get_inventory()
		local altact = puncher:get_player_control().sneak
		local mult = puncher:get_player_control().aux1

		-- Must be in city and protected.
		if not (city_block:in_city(pos) and minetest.test_protection(pos, "")) then
			minetest.chat_send_player(pname, "# Server: You cannot exchange for minegeld outside any city or village.")
			return
		end

		local rate = v.rate

		-- If player is buying ore, the price is 10 units higher.
		-- The price-differential between buying and selling discourages abuse.
		if altact then
			rate = rate + 10
		end

		local item = ItemStack(v.item)
		item:set_count(1)
		if mult then
			rate = v.rate * 10
			item:set_count(10)
		end

		if altact then
			-- Take money, give player ore.
			local cash = currency.tell(pname)
			if cash >= rate then
				local safe = currency.safe_to_remove_cash(inv, "main", rate)
				local itemstack = ItemStack(item)
				if inv:room_for_item("main", itemstack) and safe then
					currency.remove(pname, rate)
					local leftover = inv:add_item("main", itemstack)
					local rem = currency.tell(pname)
					minetest.chat_send_player(pname, "# Server: Commodity exchanged: you receive " .. item:get_count() ..  " " .. v.key .. " lump(s) for " .. rate .. " MG. You now have " .. rem .. " MG.")

					if leftover:get_count() > 0 then
						minetest.item_drop(leftover, puncher, puncher:get_pos())
					end
					easyvend.sound_vend(pos)
				else
					minetest.chat_send_player(pname, "# Server: Not enough room in your inventory to receive commodity.")
				end
			else
				minetest.chat_send_player(pname, "# Server: You don't have enough MG to exchange for a commodity.")
			end
		else
			-- Take ore, give player money.
			if inv:contains_item("main", item) then
				if currency.room(pname, rate) then
					currency.add(pname, rate)
					inv:remove_item("main", item)
					local cash = currency.tell(pname)
					minetest.chat_send_player(pname, "# Server: Commodity exchanged: you receive " .. rate .. " minegeld. You now have " .. cash .. " MG.")
					easyvend.sound_deposit(pos)
				else
					local cash = currency.tell(pname)
					minetest.chat_send_player(pname, "# Server: Not enough room in your inventory. You currently have " .. cash .. " MG.")
				end
			else
				local cash = currency.tell(pname)
				minetest.chat_send_player(pname, "# Server: You don't have enough unrefined " .. v.key .. ". You currently have " .. cash .. " MG.")
			end
		end
	end

	exchange["on_construct_" .. v.key] = function(pos, node, puncher, pt)
		update_meta(pos)
	end

	exchange["on_update_infotext_" .. v.key] = function(pos)
		update_meta(pos)
	end
end

if not exchange.run_once then
	minetest.register_alias("exchange:kiosk_mese", "exchange:kiosk_gold")
	minetest.register_alias("exchange:kiosk_copper", "exchange:kiosk_gold")
	minetest.register_alias("exchange:kiosk_iron", "exchange:kiosk_gold")
	minetest.register_alias("exchange:kiosk_coal", "exchange:kiosk_gold")
	minetest.register_alias("exchange:kiosk_pearl", "exchange:kiosk_gold")
	minetest.register_alias("exchange:kiosk_rack", "exchange:kiosk_gold")

	for k, v in ipairs(exchange.types) do
		minetest.register_node(":exchange:kiosk_" .. v.key, {
			description = v.name .. " Commodity Exchange\n\nPunch to obtain MG in exchange for commodities.\nShift-punch to redeem commodities for money.\nHold 'E' to multiply exchange by 10.",

			tiles = {
				"easyvend_vendor_side.png^" .. v.image,
				"easyvend_vendor_side.png",
				"easyvend_ad_booth.png",
				"easyvend_ad_booth.png",
				"easyvend_ad_booth.png",
				"easyvend_ad_booth.png",
			},

			paramtype2 = "facedir",
			groups = utility.dig_groups("furniture", {flammable = 2}),
			sounds = default.node_sound_wood_defaults(),

			on_construct = function(pos, node, puncher, pt)
				(exchange["on_construct_" .. v.key])(pos, node, puncher, pt)
			end,

			on_punch = function(pos, node, puncher, pt)
				(exchange["on_punch_" .. v.key])(pos, node, puncher, pt)
			end,

			_on_update_infotext = function(pos, node, puncher, pt)
				(exchange["on_update_infotext_" .. v.key])(pos)
			end,
		})
	end

	for k, v in ipairs(exchange.types) do
		minetest.register_craft({
			output = "exchange:kiosk_" .. v.key,
			recipe = {
				{'', 'passport:passport_adv', ''},
				{"market:booth", "voidchest:voidchest_closed", v.block},
				{'', v.block, ''},
			},
		})
	end

	local c = "exchange:core"
	local f = exchange.modpath .. "/exchange.lua"
	reload.register_file(c, f, false)

	exchange.run_once = true
end
