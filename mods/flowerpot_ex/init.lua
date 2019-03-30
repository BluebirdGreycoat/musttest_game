
local plants = {
	{name="bluegrass:plant_1", drop="bluegrass:bluegrass"},
	{name="bluegrass:plant_2", drop="bluegrass:bluegrass"},
	{name="bluegrass:plant_3", drop="bluegrass:bluegrass"},
	{name="bluegrass:plant_4", drop="bluegrass:bluegrass"},
	{name="bluegrass:plant_5", drop="bluegrass:bluegrass"},
	{name="bluegrass:plant_6", drop="bluegrass:bluegrass"},
	{name="bluegrass:plant_7", drop="bluegrass:bluegrass"},

	{insert="bluegrass:bluegrass", nodes={"bluegrass:plant_1", "bluegrass:plant_2", "bluegrass:plant_3", "bluegrass:plant_4", "bluegrass:plant_5", "bluegrass:plant_6", "bluegrass:plant_7"}},

	{name="blueberries:plant_1", drop="blueberries:fruit"},
	{name="blueberries:plant_2", drop="blueberries:fruit"},
	{name="blueberries:plant_3", drop="blueberries:fruit"},
	{name="blueberries:plant_4", drop="blueberries:fruit"},

	{insert="blueberries:fruit", nodes={"blueberries:plant_1", "blueberries:plant_2", "blueberries:plant_3", "blueberries:plant_4"}},

	{name="raspberries:plant_1", drop="raspberries:fruit"},
	{name="raspberries:plant_2", drop="raspberries:fruit"},
	{name="raspberries:plant_3", drop="raspberries:fruit"},
	{name="raspberries:plant_4", drop="raspberries:fruit"},

	{insert="raspberries:fruit", nodes={"raspberries:plant_1", "raspberries:plant_2", "raspberries:plant_3", "raspberries:plant_4"}},

	{name="pumpkin:plant_1", drop="pumpkin:slice"},
	{name="pumpkin:plant_2", drop="pumpkin:slice"},
	{name="pumpkin:plant_3", drop="pumpkin:slice"},
	{name="pumpkin:plant_4", drop="pumpkin:slice"},
	{name="pumpkin:plant_5", drop="pumpkin:slice"},
	{name="pumpkin:plant_6", drop="pumpkin:slice"},
	{name="pumpkin:plant_7", drop="pumpkin:slice"},
	{name="pumpkin:plant_8", drop="pumpkin:slice"},

	{insert="pumpkin:slice", nodes={"pumpkin:plant_1", "pumpkin:plant_2", "pumpkin:plant_3", "pumpkin:plant_4", "pumpkin:plant_5", "pumpkin:plant_6", "pumpkin:plant_7", "pumpkin:plant_8"}},
}

for k, v in ipairs(plants) do
	if v.name then
		flowerpot.register_node(v.name)

		if v.drop then
			minetest.override_item(v.name, {
				flowerpot_drop = v.drop,
			})
		end
	end

	if v.insert and v.nodes then
		minetest.override_item(v.insert, {
			flowerpot_insert = v.nodes,
		})
	end
end
