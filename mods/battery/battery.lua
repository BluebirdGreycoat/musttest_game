
-- The battery item. Used to 'upgrade' battery array boxes so they can
-- store energy consistent with the number of batteries stored in them.
-- Also used as a craftitem in recipes.
minetest.register_craftitem("battery:battery", {
  description = "RE Battery\n\nReduces the power requirements of a machine, if used as an upgrade.\nStores energy when wired into battery box housings.",
  inventory_image = "technic_battery.png",
  stack_max = 1, -- May store meta in the future. Used as upgrade item.
})
minetest.register_alias("battery:re_battery", "battery:battery")

minetest.register_craft({
  output = 'battery:battery',
  recipe = {
    {'carbon_steel:dust', 'default:copper_ingot', 'zinc:dust'},
    {'lead:ingot', 'moreores:tin_ingot',   'lead:ingot'},
    {'zinc:dust', 'default:copper_ingot', 'carbon_steel:dust'},
  }
})

minetest.register_craftitem("battery:battery_broken", {
  description = "Broken RE Battery",
  inventory_image = "technic_battery_broken.png",
  stack_max = 1, -- May store meta in the future.
})
