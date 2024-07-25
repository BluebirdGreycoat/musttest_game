
if minetest.register_fence then
	minetest.register_fence({fence_of = "sumpf:junglestone"})--, {drop = "sumpf:fence_cobble"})
	minetest.register_fence({fence_of = "sumpf:cobble"})
	minetest.register_fence({fence_of = "sumpf:junglestonebrick"})
	minetest.register_fence({fence_of = "sumpf:peat"})
	minetest.register_fence({fence_of = "sumpf:sumpf"})
	minetest.register_fence({fence_of = "sumpf:roofing"}, {furnace_burntime = 6.5})
end
