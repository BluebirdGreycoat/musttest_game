
exchange = exchange or {}
exchange.modpath = minetest.get_modpath("easyvend")

exchange.types = {
	{name = "Gold", key = "gold", rate = 35, image = "default_gold_lump.png", item = "default:gold_lump", block = "default:goldblock"},
	{name = "Silver", key = "silver", rate = 14, image = "moreores_silver_lump.png", item = "moreores:silver_lump", block = "moreores:silver_block"},
	{name = "Copper", key = "copper", rate = 9, image = "default_copper_lump.png", item = "default:copper_lump", block = "default:copperblock"},
}

for k, v in ipairs(exchange.types) do
	exchange["on_punch_" .. v.key] = function(pos, node, puncher, pt)
		local pname = puncher:get_player_name()
		local inv = puncher:get_inventory()
		if inv:contains_item("main", v.item) then
			if currency.room(pname, v.rate) then
				currency.add(pname, v.rate)
				inv:remove_item("main", v.item)
				local cash = currency.tell(pname)
				minetest.chat_send_player(pname, "# Server: Currency exchanged: you receive " .. v.rate .. " minegeld. You now have " .. cash .. " MG.")
				easyvend.sound_deposit(pos)
			else
				local cash = currency.tell(pname)
				minetest.chat_send_player(pname, "# Server: Not enough room in your inventory. You currently have " .. cash .. " MG.")
			end
		else
			local cash = currency.tell(pname)
			minetest.chat_send_player(pname, "# Server: You don't have any unrefined " .. v.key .. ". You currently have " .. cash .. " MG.")
		end
	end

	exchange["on_construct_" .. v.key] = function(pos, node, puncher, pt)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext",
			v.name .. " Currency Exchange\nPunch to exchange " .. v.key ..
			" for MG\n1 unrefined " .. v.key .. " = " .. v.rate .. " MG")
	end
end

if not exchange.run_once then
	for k, v in ipairs(exchange.types) do
		minetest.register_node(":exchange:kiosk_" .. v.key, {
			description = v.name .. " Currency Exchange",

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
