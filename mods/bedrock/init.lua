
bedrock = bedrock or {}
bedrock.modpath = minetest.get_modpath("bedrock")



minetest.register_node("bedrock:bedrock", {
  description = "Bedrock",
  tiles = {"bedrock_bedrock.png"},
  groups = {unbreakable = 1, immovable=1},
  drop = "",
  is_ground_content = false, -- This is important!
  sounds = default.node_sound_stone_defaults(),
	diggable = false,
	always_protected = true, -- Protector code handles this.
  on_blast = function(...) end,
  can_dig = function(...) return false end,
})

