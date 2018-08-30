
wieldhand = wieldhand or {}
wieldhand.modpath = minetest.get_modpath("wieldhand")



-- The Hand.
minetest.register_item(":", {
  type = "none",
  wield_image = "wieldhand.png",
  wield_scale = {x=1,y=1,z=2.5},
  tool_capabilities = {
    full_punch_interval = 0.9,
    max_drop_level = 0,
    groupcaps = {
      crumbly = {times={[2]=5.00, [3]=4.00}, uses=0, maxlevel=1},
      snappy = {times={[3]=3.00}, uses=0, maxlevel=1},
      oddly_breakable_by_hand = {times={[1]=5.00,[2]=4.00,[3]=3.00}, uses=0}
    },
    damage_groups = {fleshy=1},
  },
  
  -- This seems to prevent the wieldhand from being used to dig things.
  --on_use = function(itemstack, user, pointed_thing)
  --end,
})
