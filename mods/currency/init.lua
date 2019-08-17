
currency = currency or {}
currency.modpath = minetest.get_modpath("currency")



local currency_names = {
	"currency:minegeld",
	"currency:minegeld_5",
	"currency:minegeld_10",
	"currency:minegeld_50",
	"currency:minegeld_100",
}

local currency_values = {1, 5, 10, 50, 100}



function currency.add_cash(inv, name, amount)
end



function currency.del_cash(inv, name, amount)
end



function currency.has_cash(inv, name, amount)
	return (currency.get_cash(inv, name) >= amount)
end



function currency.get_cash(inv, name)
end



if not currency.registered then
	dofile(currency.modpath .. "/craftitems.lua")
	dofile(currency.modpath .. "/crafting.lua")

	local c = "currency:core"
	local f = currency.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	currency.registered = true
end
