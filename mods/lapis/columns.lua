
-- Cleanup old nodes.
for k, v in ipairs({
	"lapis_block",
	"lapis_brick",
	"lapis_cobble",
	{"lazurite_block", "lazurite"},
	"lazurite_brick",
}) do
	if type(v) == "table" then
		minetest.register_alias("lapis:column_" .. v[1], "stairs:panel_" .. v[2] .. "_pillar")
		minetest.register_alias("lapis:base_" .. v[1], "stairs:panel_" .. v[2] .. "_pcend")
	else
		minetest.register_alias("lapis:column_" .. v, "stairs:panel_" .. v .. "_pillar")
		minetest.register_alias("lapis:base_" .. v, "stairs:panel_" .. v .. "_pcend")
	end
end
