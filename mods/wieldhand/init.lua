
if not minetest.global_exists("wieldhand") then wieldhand = {} end
wieldhand.modpath = minetest.get_modpath("wieldhand")



-- The Hand.
minetest.register_item(":", {
  type = "none",
  wield_image = "wieldhand.png",
  wield_scale = {x=1,y=1,z=2.5},
  tool_capabilities = tooldata["hand_hand"],
  
  -- This seems to prevent the wieldhand from being used to dig things.
  --on_use = function(itemstack, user, pointed_thing)
  --end,
})
