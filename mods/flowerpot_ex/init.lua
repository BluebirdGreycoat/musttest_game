
local plants = {
	{name="bluegrass:plant_1", drop="bluegrass:bluegrass", tilex="^[transformR180"},
	{name="bluegrass:plant_2", drop="bluegrass:bluegrass", tilex="^[transformR180"},
	{name="bluegrass:plant_3", drop="bluegrass:bluegrass", tilex="^[transformR180"},
	{name="bluegrass:plant_4", drop="bluegrass:bluegrass", tilex="^[transformR180"},
	{name="bluegrass:plant_5", drop="bluegrass:bluegrass", tilex="^[transformR180"},
	{name="bluegrass:plant_6", drop="bluegrass:bluegrass", tilex="^[transformR180"},
	{name="bluegrass:plant_7", drop="bluegrass:bluegrass", tilex="^[transformR180"},

	{insert="bluegrass:bluegrass", nodes={"bluegrass:plant_1", "bluegrass:plant_2", "bluegrass:plant_3", "bluegrass:plant_4", "bluegrass:plant_5", "bluegrass:plant_6", "bluegrass:plant_7"}},

	{name="blueberries:plant_1", drop="blueberries:fruit"},
	{name="blueberries:plant_2", drop="blueberries:fruit"},
	{name="blueberries:plant_3", drop="blueberries:fruit"},
	{name="blueberries:plant_4", drop="blueberries:fruit"},
 
	{insert="blueberries:fruit", nodes={"blueberries:plant_1", "blueberries:plant_2", "blueberries:plant_3", "blueberries:plant_4"}},
	
	{name="coffee_bush:plant_1", drop="coffee_bush:seeds"},
	{name="coffee_bush:plant_2", drop="coffee_bush:seeds"},
	{name="coffee_bush:plant_3", drop="coffee_bush:seeds"},
	{name="coffee_bush:plant_4", drop="coffee_bush:seeds"},

	{insert="coffee_bush:seeds", nodes={"coffee_bush:plant_1", "coffee_bush:plant_2", "coffee_bush:plant_3", "coffee_bush:plant_4"}},
        
        {insert="aloevera:aloe_slice", nodes={"aloevera:aloe_plant_01", "aloevera:aloe_plant_02", "aloevera:aloe_plant_03", "aloevera:aloe_plant_04"}},


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
		-- Must update node drops BEFORE registering the flowerpot node.
		if v.drop then
			minetest.override_item(v.name, {
				flowerpot_drop = v.drop,
			})
		end

		-- Register the flowerpot node.
		if v.tilex then
			flowerpot.register_node(v.name, v.tilex)
		else
			flowerpot.register_node(v.name)
		end
	end

	if v.insert and v.nodes then
		minetest.override_item(v.insert, {
			flowerpot_insert = v.nodes,
		})
	end
end
