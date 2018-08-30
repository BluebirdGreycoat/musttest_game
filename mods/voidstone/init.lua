
voidstone = voidstone or {}
voidstone.modpath = minetest.get_modpath("voidstone")



-- It is not supposed to be possible for players to obtain this node.
-- Except by making nether portals.
minetest.register_node('voidstone:void', {
  description = 'Voidstone (You Hacker, You!)',
  tiles = {'voidstone_void.png'},
  drawtype = "nodebox",
  paramtype = "light",
  groups = {
    unbreakable=1,
    immovable=1,
    disable_jump=1,
  },
  node_box = {
    type = "fixed",
    fixed = {-0.5, (-0.5/8)*5, -0.5, 0.5, (0.5/8)*5, 0.5},
  },
  diggable = false,
  drop = "",
});
