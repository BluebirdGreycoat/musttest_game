ltool = {}

ltool.VERSION = {}
ltool.VERSION.MAJOR = 1
ltool.VERSION.MINOR = 3
ltool.VERSION.PATCH = 0
ltool.VERSION.STRING = ltool.VERSION.MAJOR .. "." .. ltool.VERSION.MINOR .. "." .. ltool.VERSION.PATCH

ltool.playerinfos = {}
ltool.default_edit_fields = {
	axiom="",
	rules_a="",
	rules_b="",
	rules_c="",
	rules_d="",
	trunk="",
	leaves="",
	leaves2="",
	leaves2_chance="",
	fruit="",
	fruit_chance="",
	angle="",
	iterations="",
	random_level="",
	trunk_type="",
	thin_branches="",
	name = "",
}

--[[ This registers the sapling for planting the trees ]]
minetest.register_node(":ltool:sapling", {
	description = "Custom L-system tree sapling",
	_doc_items_longdesc = "This artificial sapling does not come from nature and contains the genome of a genetically engineered L-system tree. Every sapling of this kind is unique. Who knows what might grow from it when you plant it?",
	_doc_items_usagehelp = "Place the sapling on any floor and wait 5 seconds for the tree to appear. If you hold down the sneak key while placing it, you will keep a copy of the sapling in your inventory. To create your own saplings, you need to have the “lplant” privilege and pick a tree from the L-System Tree Utility (accessed with the server command “treeform”).",
	stack_max = 1,
	drawtype = "plantlike",
	tiles = { "ltool_sapling.png" },
	inventory_image = "ltool_sapling.png",
	selection_box = {
		type = "fixed",
		fixed = { -10/32, -0.5, -10/32, 10/32, 12/32, 10/32 },
	},
	wield_image = "ltool_sapling.png",
	paramtype = "light",
	paramtype2= "wallmounted",
	walkable = false,
	groups = { dig_immediate = 3, not_in_creative_inventory=1, },
	drop = "",
	sunlight_propagates = true,
	is_ground_content = false,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		-- Transfer metadata and start timer
		local nodemeta = minetest.get_meta(pos)
		local itemmeta = itemstack:get_metadata()
		nodemeta:set_string("treedef", itemmeta)
		local timer = minetest.get_node_timer(pos)
		timer:start(5)
		if placer:get_player_control().sneak == true then
			return true
		else
			return nil
		end
	end,
	on_timer = function(pos, elapsed)
		-- Place tree
		local meta = minetest.get_meta(pos)
		local treedef = minetest.deserialize(meta:get_string("treedef"))
		minetest.remove_node(pos)
		minetest.spawn_tree(pos, treedef)
	end,
	can_dig = function(pos, player)
		return minetest.get_player_privs(player:get_player_name()).lplant
	end,
})

--[[ Register privileges ]]
minetest.register_privilege("ledit", {
	description = "Can add, edit, rename and delete own L-system tree definitions of the ltool mod",
	give_to_singleplayer = false,
})
minetest.register_privilege("lplant", {
	description = "Can place L-system trees and get L-system tree samplings of the ltool mod",
	give_to_singleplayer = false,
})

--[[ Load previously saved data from file or initialize an empty tree table ]]
do
	local filepath = minetest.get_worldpath().."/ltool.mt"
	local file = io.open(filepath, "r")
	if(file) then
		local string = file:read()
		io.close(file)
		if(string ~= nil) then
			local savetable = minetest.deserialize(string)
			if(savetable ~= nil) then
				ltool.trees = savetable.trees
				ltool.next_tree_id = savetable.next_tree_id
				ltool.number_of_trees = savetable.number_of_trees
				minetest.log("action", "[ltool] Tree data loaded from "..filepath..".")
			else
				minetest.log("error", "[ltool] Failed to load tree data from "..filepath..".")
			end
		else
			minetest.log("error", "[ltool] Failed to load tree data from "..filepath..".")
		end
	else
		--[[ table of all trees ]]
		ltool.trees = {}
		--[[ helper variables to ensure unique IDs ]]
		ltool.number_of_trees = 0
		ltool.next_tree_id = 1
	end
end

--[[ Adds a tree to the tree table.
	name: The tree’s name.
	author: The author’s / owners’ name
	treedef: The full tree definition, see lua_api.txt

	returns the tree ID of the new tree
]]
function ltool.add_tree(name, author, treedef)
	local id = ltool.next_tree_id
	ltool.trees[id] = {name = name, author = author, treedef = treedef}
	ltool.next_tree_id = ltool.next_tree_id + 1
	ltool.number_of_trees = ltool.number_of_trees + 1
	return id
end

--[[ Removes a tree from the database
	tree_id: ID of the tree to be removed

	returns nil
]]
function ltool.remove_tree(tree_id)
	ltool.trees[tree_id] = nil
	ltool.number_of_trees = ltool.number_of_trees - 1
	for k,v in pairs(ltool.playerinfos) do
		if(v.dbsel ~= nil) then
			if(v.dbsel > ltool.number_of_trees) then
				v.dbsel = ltool.number_of_trees
			end
			if(v.dbsel < 1) then
				v.dbsel = 1
			end
		end
	end
end

--[[ Renames a tree in the database
	tree_id: ID of the tree to be renamed
	new_name: The name of the tree

	returns nil
]]
function ltool.rename_tree(tree_id, new_name)
	ltool.trees[tree_id].name = new_name
end

--[[ Copies a tree in the database
	tree_id: ID of the tree to be copied

	returns: the ID of the copy on success;
	         false on failure (tree does not exist)
]]
function ltool.copy_tree(tree_id)
	local tree = ltool.trees[tree_id]
	if(tree == nil) then
		return false
	end
	return ltool.add_tree(tree.name, tree.author, tree.treedef)
end

--[[ Gives a L-system tree sapling to a player
	tree_id: ID of tree the sapling will grow
	seed: Seed of the tree (optional; can be nil)
	playername: name of the player to which
	ignore_priv: if true, player’s lplant privilige is not checked (optional argument; default: false)

	returns:
		true on success
		false, 1 if privilege is not sufficient
		false, 2 if player’s inventory is full
]]
function ltool.give_sapling(treedef, seed, player_name, ignore_priv)
	local privs = minetest.get_player_privs(player_name)
	if(ignore_priv == nil) then ignore_priv = false end
	if(ignore_priv == false and privs.lplant ~= true) then
		return false, 1
	end
	local sapling = ItemStack("ltool:sapling")
	local player = minetest.get_player_by_name(player_name)
	treedef.seed = seed
	sapling:set_metadata(minetest.serialize(treedef))
	treedef.seed = nil
	local leftover = player:get_inventory():add_item("main", sapling)
	if(not leftover:is_empty()) then
		return false, 2
	else
		return true
	end
end

--[[ Plants a tree as the specified position
	tree_id: ID of tree to be planted
	pos: Position of tree, in format {x=?, y=?, z=?}
	seed: Optional seed for randomness, equal seed makes equal trees

	returns false on failure, nil otherwise
]]
function ltool.plant_tree(tree_id, pos, seed)
	local tree = ltool.trees[tree_id]
	if(tree==nil) then
		return false
	end
	local treedef
	if seed ~= nil then
		treedef = table.copy(tree.treedef)
		treedef.seed = seed
	else
		treedef = tree.treedef
	end
	minetest.spawn_tree(pos, treedef)
end

--[[ Tries to return a tree data structure for a given tree_id

	tree_id: ID of tee to be returned

	returns false on failure, a tree otherwise
]]
function ltool.get_tree(tree_id)
	local tree = ltool.trees[tree_id]
	if(tree==nil) then
		return false
	end
	return tree
end


ltool.seed = os.time()


--[=[ Here come the functions to build the main formspec.
They do not build the entire formspec ]=]

ltool.formspec_size = "size[12,9]"

--[[ This is a part of the main formspec: Tab header ]]
function ltool.formspec_header(index)
	return "tabheader[0,0;ltool_tab;Edit,Database,Plant,Help;"..tostring(index)..";true;false]"
end

--[[ This creates the edit tab of the formspec
	fields: A template used to fill the default values of the formspec. ]]
function ltool.tab_edit(fields, has_ledit_priv, has_lplant_priv)
	if(fields==nil) then
		fields = ltool.default_edit_fields
	end
	local s = function(input)
		local ret
		if(input==nil) then
			ret = ""
		else
			ret = minetest.formspec_escape(tostring(input))
		end
		return ret
	end

	-- Show save/clear buttons depending on privs
	local leditbuttons
	if has_ledit_priv then
		leditbuttons = "button[0,8.7;4,0;edit_save;Save tree to database]"..
		"button[4,8.7;4,0;edit_clear;Clear fields]"
		if has_lplant_priv then
			leditbuttons = leditbuttons .. "button[8,8.7;4,0;edit_sapling;Give me a sapling]"
		end
	else
		leditbuttons = "label[0,8.3;Read-only mode. You need the “ledit” privilege to save trees to the database.]"
	end

	return ""..
	"field[0.2,1;11,0;axiom;Axiom;"..s(fields.axiom).."]"..
	"button[11,0.7;1,0;edit_axiom;+]"..
	"tooltip[edit_axiom;Opens larger text field for Axiom]"..
	"field[0.2,2;11,0;rules_a;Rules set A;"..s(fields.rules_a).."]"..
	"button[11,1.7;1,0;edit_rules_a;+]"..
	"tooltip[edit_rules_a;Opens larger text field for Rules set A]"..
	"field[0.2,3;11,0;rules_b;Rules set B;"..s(fields.rules_b).."]"..
	"button[11,2.7;1,0;edit_rules_b;+]"..
	"tooltip[edit_rules_b;Opens larger text field for Rules set B]"..
	"field[0.2,4;11,0;rules_c;Rules set C;"..s(fields.rules_c).."]"..
	"button[11,3.7;1,0;edit_rules_c;+]"..
	"tooltip[edit_rules_c;Opens larger text field for Rules set C]"..
	"field[0.2,5;11,0;rules_d;Rules set D;"..s(fields.rules_d).."]"..
	"button[11,4.7;1,0;edit_rules_d;+]"..
	"tooltip[edit_rules_d;Opens larger text field for Rules set D]"..

	"field[0.2,6;3,0;trunk;Trunk node name;"..s(fields.trunk).."]"..
	"field[3.2,6;3,0;leaves;Leaves node name;"..s(fields.leaves).."]"..
	"field[6.2,6;3,0;leaves2;Secondary leaves node name;"..s(fields.leaves2).."]"..
	"field[9.2,6;3,0;fruit;Fruit node name;"..s(fields.fruit).."]"..

	"field[0.2,7;3,0;trunk_type;Trunk type (single/double/crossed);"..s(fields.trunk_type).."]"..
	"tooltip[trunk_type;This field specifies the shape of the tree trunk. Possible values:\n- \"single\": trunk of size 1×1\n- \"double\": trunk of size 2×2\n- \"crossed\": trunk in cross shape (3×3).]"..
	"field[3.2,7;3,0;thin_branches;Thin branches? (true/false);"..s(fields.thin_branches).."]"..
	"tooltip[thin_branches;\"true\": All branches are just 1 node wide. \"false\": Branches can be larger.]"..
	"field[6.2,7;3,0;leaves2_chance;Secondary leaves chance (in %);"..s(fields.leaves2_chance).."]"..
	"tooltip[leaves2_chance;Chance (in percent) to replace a leaves node by a secondary leaves node]"..
	"field[9.2,7;3,0;fruit_chance;Fruit chance (in %);"..s(fields.fruit_chance).."]"..
	"tooltip[fruit_chance;Chance (in percent) to replace a leaves node by a fruit node.]"..

	"field[0.2,8;3,0;iterations;Iterations;"..s(fields.iterations).."]"..
	"tooltip[iterations;Maximum number of iterations, usually between 2 and 5.]"..
	"field[3.2,8;3,0;random_level;Randomness level;"..s(fields.random_level).."]"..
	"tooltip[random_level;Factor to lower number of iterations, usually between 0 and 3.]"..
	"field[6.2,8;3,0;angle;Angle (in °);"..s(fields.angle).."]"..
	"field[9.2,8;3,0;name;Name;"..s(fields.name).."]"..
	"tooltip[name;An unique name for this tree, only used for convenience.]"..
	leditbuttons
end

--[[ This creates the database tab of the formspec.
	index: Selected index of the textlist
	playername: To whom the formspec is shown
]]
function ltool.tab_database(index, playername)
	local treestr, tree_ids = ltool.build_tree_textlist(index, playername)
	if(treestr ~= nil) then
		local indexstr
		if(index == nil) then
			indexstr = ""
		else
			indexstr = tostring(index)
		end
		ltool.playerinfos[playername].treeform.database.textlist = tree_ids

		local leditbuttons
		if minetest.get_player_privs(playername).ledit then
			leditbuttons = "button[3,7.5;3,1;database_rename;Rename tree]"..
			"button[6,7.5;3,1;database_delete;Delete tree]"
		else
			leditbuttons = "label[0.2,7.2;Read-only mode. You need the “ledit” privilege to edit trees.]"
		end

		return ""..
		"textlist[0,0;11,7;treelist;"..treestr..";"..tostring(index)..";false]"..
		leditbuttons..
		"button[3,8.5;3,1;database_copy;Copy tree to editor]"..
		"button[6,8.5;3,1;database_update;Reload database]"
	else
		return "label[0,0;The tree database is empty.]"..
		"button[6.5,8.5;3,1;database_update;Reload database]"
	end
end

--[[ This creates the "Plant" tab part of the main formspec ]]
function ltool.tab_plant(tree, fields, has_lplant_priv)
	if(tree ~= nil) then
		local seltree = "label[0,-0.2;Selected tree: "..minetest.formspec_escape(tree.name).."]"
		if not has_lplant_priv then
			return seltree..
			"label[0,0.3;Planting of trees is not allowed. You need to have the “lplant” privilege.]"
		end
		if(fields==nil) then
			fields = {}
		end
		local s = function(i)
			if(i==nil) then return ""
			else return tostring(minetest.formspec_escape(i))
			end
		end
		local seed
		if(fields.seed == nil) then
			seed = tostring(ltool.seed)
		else
			seed = fields.seed
		end
		local dropdownindex
		if(fields.plantmode == "Absolute coordinates") then
			dropdownindex = 1
		elseif(fields.plantmode == "Relative coordinates") then
			dropdownindex = 2
		elseif(fields.plantmode == "Distance in viewing direction") then
			dropdownindex = 3
		else
			dropdownindex = 1
		end

		return ""..
		seltree..
		"dropdown[-0.1,0.5;5;plantmode;Absolute coordinates,Relative coordinates,Distance in viewing direction;"..dropdownindex.."]"..
--[[ NOTE: This tooltip does not work for the dropdown list in 0.4.10,
but it is added anyways in case this gets fixed in later Minetest versions. ]]
		"tooltip[plantmode;"..
		"- \"Absolute coordinates\": Fields \"x\", \"y\" and \"z\" specify the absolute world coordinates where to plant the tree\n"..
		"- \"Relative coordinates\": Fields \"x\", \"y\" and \"z\" specify the relative position from your position\n"..
		"- \"Distance in viewing direction\": Plant tree relative from your position in the direction you look to, at the specified distance"..
		"]"..
		"field[0.2,-2;6,10;x;x;"..s(fields.x).."]"..
		"tooltip[x;Field is only used by absolute and relative coordinates.]"..
		"field[0.2,-1;6,10;y;y;"..s(fields.y).."]"..
		"tooltip[y;Field is only used by absolute and relative coordinates.]"..
		"field[0.2,0;6,10;z;z;"..s(fields.z).."]"..
		"tooltip[z;Field is only used by absolute and relative coordinates.]"..
		"field[0.2,1;6,10;distance;Distance;"..s(fields.distance).."]"..
		"tooltip[distance;This field is used to specify the distance (in node lengths) from your position\nin the viewing direction. It is ignored if you use coordinates.]"..
		"field[0.2,2;6,10;seed;Randomness seed;"..seed.."]"..
		"tooltip[seed;A number used for the random number generators. Identical randomness seeds will produce identical trees. This field is optional.]"..
		"button[3.5,8;3,1;plant_plant;Plant tree]"..
		"tooltip[plant_plant;Immediately place the tree at the specified position]"..
		"button[6.5,8;3,1;sapling;Give me a sapling]"..
		"tooltip[sapling;This gives you an item which you can place manually in the world later]"
	else
		local notreestr = "No tree in database selected or database is empty."
		if has_lplant_priv then
			return "label[0,0;"..notreestr.."]"
		else
			return "label[0,0;"..notreestr.."\nYou are not allowed to plant trees anyway as you don't have the “lplant” privilege.]"
		end
	end
end


--[[ This creates the cheat sheet tab ]]
function ltool.tab_cheat_sheet()
	return ""..
	"tablecolumns[text;text]"..
	"tableoptions[background=#000000;highlight=#000000;border=false]"..
	"table[-0.15,0.75;12,8;cheat_sheet;"..
	"Symbol,Action,"..
	"G,Move forward one unit with the pen up,"..
	"F,Move forward one unit with the pen down drawing trunks and branches,"..
	"f,Move forward one unit with the pen down drawing leaves (100% chance),"..
	"T,Move forward one unit with the pen down drawing trunks only,"..
	"R,Move forward one unit with the pen down placing fruit,"..
	"A,Replace with rules set A,"..
	"B,Replace with rules set B,"..
	"C,Replace with rules set C,"..
	"D,Replace with rules set D,"..
	"a,Replace with rules set A\\, chance 90%,"..
	"b,Replace with rules set B\\, chance 80%,"..
	"c,Replace with rules set C\\, chance 70%,"..
	"d,Replace with rules set D\\, chance 60%,"..
	"+,Yaw the turtle right by angle parameter,"..
	"-,Yaw the turtle left by angle parameter,"..
	"&,Pitch the turtle down by angle parameter,"..
	"^,Pitch the turtle up by angle parameter,"..
	"/,Roll the turtle to the right by angle parameter,"..
	"*,Roll the turtle to the left by angle parameter,"..
	"\\[,Save in stack current state info,"..
	"\\],Recover from stack state info]"
end

function ltool.tab_help_intro()
	return ""..
	"tablecolumns[text]"..
	"tableoptions[background=#000000;highlight=#000000;border=false]"..
	"table[-0.15,0.75;12,7;help_intro;"..
	string.format("You are using the L-System Tree Utility mod version %s.,", ltool.VERSION.STRING)..
	","..
	"The purpose of this mod is to aid with the creation of L-system trees.,"..
	"With this mod you can create\\, save\\, manage and plant L-system trees.,"..
	"All trees are saved into <world path>/ltool.mt on server shutdown.,"..
	"This mod assumes you already understand the concept of L-systems\\;,"..
	"this mod is mainly aimed towards modders.,"..
	","..
	"The usual workflow in this mod goes like this:,"..
	","..
	"1. Create a new tree in the \"Edit\" tab and save it,"..
	"2. Select it in the database,"..
	"3. Plant it,"..
	","..
	"To help you get started\\, you can create an example tree for the \"Edit\" tab,"..
	"by pressing this button:]"..
	"button[4,8;4,1;create_template;Create template]"
end

function ltool.tab_help_edit()
	return ""..
	"tablecolumns[text]"..
	"tableoptions[background=#000000;highlight=#000000;border=false]"..
	"table[-0.15,0.75;12,8;help_edit;"..
	"To create a L-system tree\\, switch to the \"Edit\" tab.,"..
	"When you are done\\, hit \"Save tree to database\". The tree will be stored in,"..
	"the database. The \"Clear fields\" button empties all the input fields.,"..
	"To understand the meaning of the fields\\, read the introduction to L-systems.,"..
	"All trees must have an unique name. You are notified in case there is a name,"..
	"clash. If the name clash is with one of your own trees\\, you can choose to,"..
	"replace it.]"
end

function ltool.tab_help_database()
	return ""..
	"tablecolumns[text]"..
	"tableoptions[background=#000000;highlight=#000000;border=false]"..
	"table[-0.15,0.75;12,8;help_database;"..
	"The database contains a server-wide list of all created trees.,"..
	"Each tree has an \"owner\". In this mod\\, the concept of ownership is a very,"..
	"weak one: The owner may rename\\, change and delete his/her own trees\\,,"..
	"everyone else is prevented from doing that. In contrast\\, all trees can be,"..
	"copied freely\\;,"..
	"To do so\\, simply hit \"Copy tree to editor\"\\, change the name and hit,"..
	"\"Save tree to database\". If you like someone else's tree definition\\,,"..
	"it is recommended to make a copy for yourself\\, since the original owner,"..
	"can at any time choose to delete or edit the tree. The trees which you \"own\","..
	"are written in a yellow font\\, all other trees in a white font.,"..
	"In order to plant a tree\\, you have to select a tree in the database first.]"
end

function ltool.tab_help_plant()
	return ""..
	"tablecolumns[text]"..
	"tableoptions[background=#000000;highlight=#000000;border=false]"..
	"table[-0.15,0.75;12,8;help_plant;"..
	"To plant a tree from a previously created tree definition\\, first select,"..
	"it in the database\\, then open the \"Plant\" tab.,"..
	"In this tab\\, you can directly place the tree or request a sapling.,"..
	"If you choose to directly place the tree\\, you can either specify absolute,"..
	"or relative coordinates or specify that the tree should be planted in your,"..
	"viewing direction. Absolute coordinates are the world coordinates as specified,"..
	"by the \"x\"\\, \"y\"\\, and \"z\" fields. Relative coordinates are relative,"..
	"to your position and use the same fields. When you choose to plant the tree,"..
	"based on your viewing direction\\, the tree will be planted at a distance,"..
	"specified by the field \"distance\" away from you in the direction you look to.,"..
	"When using coordinates\\, the \"distance\" field is ignored\\, when using,"..
	"direction\\, the coordinate fields are ignored.,"..
	","..
	"You can also use the “lplant” server command to plant trees.,"..
	","..
	"If you got a sapling\\, you can place it practically anywhere you like to.,"..
	"After placing it\\, the sapling will be replaced by the L-system tree after,"..
	"5 seconds\\, unless it was destroyed in the meantime.,"..
	"All requested saplings are independent from the moment they are created.,"..
	"The sapling will still work\\, even if the original tree definiton has been,"..
	"deleted.]"
end

function ltool.tab_help(index)
	local formspec = "tabheader[0.1,1;ltool_help_tab;Introduction,Creating Trees,Managing Trees,Planting Trees,Cheat Sheet;"..tostring(index)..";true;false]"
	if(index==1) then
		formspec = formspec .. ltool.tab_help_intro()
	elseif(index==2) then
		formspec = formspec .. ltool.tab_help_edit()
	elseif(index==3) then
		formspec = formspec .. ltool.tab_help_database()
	elseif(index==4) then
		formspec = formspec .. ltool.tab_help_plant()
	elseif(index==5) then
		formspec = formspec .. ltool.tab_cheat_sheet()
	end

	return formspec
end

function ltool.formspec_editplus(fragment)
	local formspec = ""..
	"size[12,8]"..
	"textarea[0.2,0.5;12,3;"..fragment.."]"..
	"label[0,3.625;Draw:]"..
	"button[2,3.5;1,1;editplus_c_G;G]"..
	"tooltip[editplus_c_G;Move forward one unit with the pen up]"..
	"button[3,3.5;1,1;editplus_c_F;F]"..
	"tooltip[editplus_c_F;Move forward one unit with the pen down drawing trunks and branches]"..
	"button[4,3.5;1,1;editplus_c_f;f]"..
	"tooltip[editplus_c_f;Move forward one unit with the pen down drawing leaves (100% chance)]"..
	"button[5,3.5;1,1;editplus_c_T;T]"..
	"tooltip[editplus_c_T;Move forward one unit with the pen down drawing trunks only]"..
	"button[6,3.5;1,1;editplus_c_R;R]"..
	"tooltip[editplus_c_R;Move forward one unit with the pen down placing fruit]"..

	"label[0,4.625;Rules:]"..
	"button[2,4.5;1,1;editplus_c_A;A]"..
	"tooltip[editplus_c_A;Replace with rules set A]"..
	"button[3,4.5;1,1;editplus_c_B;B]"..
	"tooltip[editplus_c_B;Replace with rules set B]"..
	"button[4,4.5;1,1;editplus_c_C;C]"..
	"tooltip[editplus_c_C;Replace with rules set C]"..
	"button[5,4.5;1,1;editplus_c_D;D]"..
	"tooltip[editplus_c_D;Replace with rules set D]"..
	"button[6.5,4.5;1,1;editplus_c_a;a]"..
	"tooltip[editplus_c_a;Replace with rules set A, chance 90%]"..
	"button[7.5,4.5;1,1;editplus_c_b;b]"..
	"tooltip[editplus_c_b;Replace with rules set B, chance 80%]"..
	"button[8.5,4.5;1,1;editplus_c_c;c]"..
	"tooltip[editplus_c_c;Replace with rules set C, chance 70%]"..
	"button[9.5,4.5;1,1;editplus_c_d;d]"..
	"tooltip[editplus_c_d;Replace with rules set D, chance 60%]"..

	"label[0,5.625;Rotate:]"..
	"button[3,5.5;1,1;editplus_c_+;+]"..
	"tooltip[editplus_c_+;Yaw the turtle right by the value specified in \"Angle\"]"..
	"button[2,5.5;1,1;editplus_c_-;-]"..
	"tooltip[editplus_c_-;Yaw the turtle left by the value specified in \"Angle\"]"..
	"button[4.5,5.5;1,1;editplus_c_&;&]"..
	"tooltip[editplus_c_&;Pitch the turtle down by the value specified in \"Angle\"]"..
	"button[5.5,5.5;1,1;editplus_c_^;^]"..
	"tooltip[editplus_c_^;Pitch the turtle up by the value specified in \"Angle\"]"..
	"button[8,5.5;1,1;editplus_c_/;/]"..
	"tooltip[editplus_c_/;Roll the turtle to the right by the value specified in \"Angle\"]"..
	"button[7,5.5;1,1;editplus_c_*;*]"..
	"tooltip[editplus_c_*;Roll the turtle to the left by the value specified in \"Angle\"]"..

	"label[0,6.625;Stack:]"..
	"button[2,6.5;1,1;editplus_c_P;\\[]"..
	"tooltip[editplus_c_P;Save current state info into stack]"..
	"button[3,6.5;1,1;editplus_c_p;\\]]"..
	"tooltip[editplus_c_p;Recover from current stack state info]"..

	"button[2.5,7.5;3,1;editplus_save;Save]"..
	"button[5.5,7.5;3,1;editplus_cancel;Cancel]"

	return formspec
end

--[[ creates the content of a textlist which contains all trees.
	index: Selected entry
	playername: To which the main formspec is shown to. Used for highlighting owned trees

	returns (string to be used in the text list, table of tree IDs)
]]
function ltool.build_tree_textlist(index, playername)
	local string = ""
	local colorstring
	if(ltool.number_of_trees == 0) then
		return nil
	end
	local tree_ids = ltool.get_tree_ids()
	for i=1,#tree_ids do
		local tree_id = tree_ids[i]
		local tree = ltool.trees[tree_id]
		if(tree.author == playername) then
			colorstring = "#FFFF00"
		else
			colorstring = ""
		end
		string = string .. colorstring .. tostring(tree_id) .. ": " .. minetest.formspec_escape(tree.name)
		if(i~=#tree_ids) then
			string = string .. ","
		end
	end
	return string, tree_ids
end

--[=[ Here come functions which show formspecs to players ]=]

--[[ Shows the main tree form to the given player, starting with the "Edit" tab ]]
function ltool.show_treeform(playername)
	local privs = minetest.get_player_privs(playername)
	local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(ltool.playerinfos[playername].treeform.edit.fields, privs.ledit, privs.lplant)
	minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
end

--[[ spawns a simple dialog formspec to a player ]]
function ltool.show_dialog(playername, formname, message)
	local formspec = "size[12,2;]label[0,0.2;"..message.."]"..
	"button[4.5,1.5;3,1;okay;OK]"
	minetest.show_formspec(playername, formname, formspec)

end


--[=[ End of formspec-relatec functions ]=]

--[[ This function does a lot of parameter checks and returns (tree, tree_name) on success.
	If ANY parameter check fails, the whole function fails.
	On failure, it returns (nil, <error message string>).]]
function ltool.evaluate_edit_fields(fields, ignore_name)
	local treedef = {}
	-- Validation helper: Checks for invalid characters for the fields “axiom” and the 4 rule sets
	local v = function(str)
		local match = string.match(str, "[^][abcdfABCDFGTR+-/*&^]")
		if(match==nil) then
			return true
		else
			return false
		end
	end
	if(v(fields.axiom) and v(fields.rules_a) and v(fields.rules_b) and v(fields.rules_c) and v(fields.rules_d)) then
		treedef.rules_a = fields.rules_a
		treedef.rules_b = fields.rules_b
		treedef.rules_c = fields.rules_c
		treedef.rules_d = fields.rules_d
		treedef.axiom = fields.axiom
	else
		return nil, "The axiom or one of the rule sets contains at least one invalid character.\nSee the cheat sheet for a list of allowed characters."
	end
	treedef.trunk = fields.trunk
	treedef.leaves = fields.leaves
	treedef.leaves2 = fields.leaves2
	treedef.leaves2_chance = fields.leaves2_chance
	treedef.angle = tonumber(fields.angle)
	if(treedef.angle == nil) then
		return nil, "The field \"Angle\" must contain a number."
	end
	treedef.iterations = tonumber(fields.iterations)
	if(treedef.iterations == nil) then
		return nil, "The field \"Iterations\" must contain a natural number greater or equal to 0."
	elseif(treedef.iterations < 0) then
		return nil, "The field \"Iterations\" must contain a natural number greater or equal to 0."
	end
	treedef.random_level = tonumber(fields.random_level)
	if(treedef.random_level == nil) then
		return nil, "The field \"Randomness level\" must contain a number."
	end
	treedef.fruit = fields.fruit
	treedef.fruit_chance = tonumber(fields.fruit_chance)
	if(treedef.fruit_chance == nil) then
		return nil, "The field \"Fruit chance\" must contain a number."
	elseif(treedef.fruit_chance > 100 or treedef.fruit_chance < 0) then
		return nil, "Fruit chance must be between 0% and 100%."
	end
	if(fields.trunk_type == "single" or fields.trunk_type == "double" or fields.trunk_type == "crossed") then
		treedef.trunk_type = fields.trunk_type
	else
		return nil, "Trunk type must be \"single\", \"double\" or \"crossed\"."
	end
	treedef.thin_branches = fields.thin_branches
	if(fields.thin_branches == "true") then
		treedef.thin_branches = true
	elseif(fields.thin_branches == "false") then
		treedef.thin_branches = false
	else
		return nil, "Field \"Thin branches?\" must be \"true\" or \"false\"."
	end
	local name = fields.name
	if(ignore_name ~= true and name == "") then
		return nil, "Name is empty."
	end
	return treedef, name
end


--[=[ Here come several utility functions ]=]

--[[ converts a given tree to field names, as if they were given to a
minetest.register_on_plyer_receive_fields callback function ]]
function ltool.tree_to_fields(tree)
	local s = function(i)
		if(i==nil) then
			return ""
		else
			return tostring(i)
		end
	end
	local fields = {}
	fields.axiom = s(tree.treedef.axiom)
	fields.rules_a = s(tree.treedef.rules_a)
	fields.rules_b = s(tree.treedef.rules_b)
	fields.rules_c = s(tree.treedef.rules_c)
	fields.rules_d = s(tree.treedef.rules_d)
	fields.trunk = s(tree.treedef.trunk)
	fields.leaves = s(tree.treedef.leaves)
	fields.leaves2 = s(tree.treedef.leaves2)
	fields.leaves2_chance = s(tree.treedef.leaves2_chance)
	fields.fruit = s(tree.treedef.leaves2)
	fields.fruit_chance = s(tree.treedef.fruit_chance)
	fields.angle = s(tree.treedef.angle)
	fields.iterations = s(tree.treedef.iterations)
	fields.random_level = s(tree.treedef.random_level)
	fields.trunk_type = s(tree.treedef.trunk_type)
	fields.thin_branches = s(tree.treedef.thin_branches)
	fields.name = s(tree.name)
	return fields
end



-- returns a simple table of all the tree IDs
function ltool.get_tree_ids()
	local ids = {}
	for tree_id, _ in pairs(ltool.trees) do
		table.insert(ids, tree_id)
	end
	table.sort(ids)
	return ids
end

--[[ In a table of tree IDs (returned by ltool.get_tree_ids, parameter tree_ids), this function
searches for the first occourance of the value searched_tree_id and returns its index.
This is basically a reverse lookup utility. ]]
function ltool.get_tree_id_index(searched_tree_id, tree_ids)
	for i=1, #tree_ids do
		local table_tree_id = tree_ids[i]
		if(searched_tree_id == table_tree_id) then
			return i
		end
	end
end

-- Returns the selected tree of the given player
function ltool.get_selected_tree(playername)
	local sel = ltool.playerinfos[playername].dbsel 
	if(sel ~= nil) then
		local tree_id = ltool.playerinfos[playername].treeform.database.textlist[sel]
		if(tree_id ~= nil) then
			return ltool.trees[tree_id]
		end
	end
	return nil
end

-- Returns the ID of the selected tree of the given player
function ltool.get_selected_tree_id(playername)
	local sel = ltool.playerinfos[playername].dbsel 
	if(sel ~= nil) then
		return ltool.playerinfos[playername].treeform.database.textlist[sel]
	end
	return nil
end


ltool.treeform = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit()

minetest.register_chatcommand("treeform",
{
	params = "",
	description = "Open L-System Tree Utility.",
	privs = { server = true },
	func = function(playername, param)
		ltool.show_treeform(playername)
	end
})

minetest.register_chatcommand("lplant",
{
	description = "Plant a L-system tree at the specified position",
	privs = { lplant = true },
	params = "<tree ID> <x> <y> <z> [<seed>]",
	func = function(playername, param)
		local p = {}
		local tree_id, x, y, z, seed = string.match(param, "^([^ ]+) +([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+) *([%d.-]*)")
		tree_id, p.x, p.y, p.z, seed = tonumber(tree_id), tonumber(x), tonumber(y), tonumber(z), tonumber(seed)
		if not tree_id or not p.x or not p.y or not p.z then
			return false, "Invalid usage, see /help lplant."
		end
		local lm = tonumber(minetest.settings:get("map_generation_limit") or 31000)
		if p.x < -lm or p.x > lm or p.y < -lm or p.y > lm or p.z < -lm or p.z > lm then
			return false, "Cannot plant tree out of map bounds!"
		end

		local success = ltool.plant_tree(tree_id, p, seed)
		if success == false then
			return false, "Unknown tree ID!"
		else
			return true
		end
	end
})

function ltool.dbsel_to_tree(dbsel, playername)
	return ltool.trees[ltool.playerinfos[playername].treeform.database.textlist[dbsel]]
end

function ltool.save_fields(playername,formname,fields)
	if(formname=="ltool:treeform_edit") then
		ltool.playerinfos[playername].treeform.edit.fields = fields
	elseif(formname=="ltool:treeform_database") then
		ltool.playerinfos[playername].treeform.database.fields = fields
	elseif(formname=="ltool:treeform_plant") then
		ltool.playerinfos[playername].treeform.plant.fields = fields
	end
end

--[=[ Callback functions start here ]=]

function ltool.process_form(player,formname,fields)
	local playername = player:get_player_name()

	local seltree = ltool.get_selected_tree(playername)
	local seltree_id = ltool.get_selected_tree_id(playername)
	local privs = minetest.get_player_privs(playername)
	local s = function(input)
		local ret
		if(input==nil) then
			ret = ""
		else
			ret = minetest.formspec_escape(tostring(input))
		end
		return ret
	end
	--[[ process clicks on the tab header ]]
	if(formname == "ltool:treeform_edit" or formname == "ltool:treeform_database" or formname == "ltool:treeform_plant" or formname == "ltool:treeform_help") then
		if fields.ltool_tab ~= nil then
			ltool.save_fields(playername, formname, fields)
			local tab = tonumber(fields.ltool_tab)
			local formspec, subformname, contents
			if(tab==1) then
				contents = ltool.tab_edit(ltool.playerinfos[playername].treeform.edit.fields, privs.ledit, privs.lplant)
				subformname = "edit"
			elseif(tab==2) then
				contents = ltool.tab_database(ltool.playerinfos[playername].dbsel, playername)
				subformname = "database"
			elseif(tab==3) then
				if(ltool.number_of_trees > 0) then
					contents = ltool.tab_plant(seltree, ltool.playerinfos[playername].treeform.plant.fields, privs.lplant)
				else
					contents = ltool.tab_plant(nil, nil, privs.lplant)
				end
				subformname = "plant"
			elseif(tab==4) then
				contents = ltool.tab_help(ltool.playerinfos[playername].treeform.help.tab)
				subformname = "help"
			end
			formspec = ltool.formspec_size..ltool.formspec_header(tab)..contents
			minetest.show_formspec(playername, "ltool:treeform_" .. subformname, formspec)
			return
		end
	end
	--[[ "Plant" tab ]]
	if(formname == "ltool:treeform_plant") then
		if(fields.plant_plant) then
			if(seltree ~= nil) then
				if(privs.lplant ~= true) then
					ltool.save_fields(playername, formname, fields)
					local message = "You can't plant trees, you need to have the \"lplant\" privilege."
					ltool.show_dialog(playername, "ltool:treeform_error_lplant", message)
					return
				end
				minetest.log("action","[ltool] Planting tree")
				local treedef = seltree.treedef

				local x,y,z = tonumber(fields.x), tonumber(fields.y), tonumber(fields.z)
				local distance = tonumber(fields.distance)
				local tree_pos
				local fail_coordinates = function()
					ltool.save_fields(playername, formname, fields)
					ltool.show_dialog(playername, "ltool:treeform_error_badplantfields", "Error: When using coordinates, you have to specifiy numbers in the fields \"x\", \"y\", \"z\".")
				end
				local fail_distance = function()
					ltool.save_fields(playername, formname, fields)
					ltool.show_dialog(playername, "ltool:treeform_error_badplantfields", "Error: When using viewing direction for planting trees,\nyou must specify how far away you want the tree to be placed in the field \"Distance\".")
				end
				if(fields.plantmode == "Absolute coordinates") then
					if(type(x)~="number" or type(y) ~= "number" or type(z) ~= "number") then
						fail_coordinates()
						return
					end
					tree_pos = {x=x, y=y, z=z}
				elseif(fields.plantmode == "Relative coordinates") then
					if(type(x)~="number" or type(y) ~= "number" or type(z) ~= "number") then
						fail_coordinates()
						return
					end
					tree_pos = player:getpos()
					tree_pos.x = tree_pos.x + x
					tree_pos.y = tree_pos.y + y
					tree_pos.z = tree_pos.z + z
				elseif(fields.plantmode == "Distance in viewing direction") then
					if(type(distance)~="number") then
						fail_distance()
						return
					end
					tree_pos = vector.round(vector.add(player:getpos(), vector.multiply(player:get_look_dir(), distance)))
				else
					minetest.log("error", "[ltool] fields.plantmode = "..tostring(fields.plantmode))
				end
	
				if(tonumber(fields.seed)~=nil) then
					treedef.seed = tonumber(fields.seed)
				end
	
				ltool.plant_tree(seltree_id, tree_pos)
	
				treedef.seed = nil
			end
		elseif(fields.sapling) then
			if(seltree ~= nil) then
				if(privs.lplant ~= true) then
					ltool.save_fields(playername, formname, fields)
					local message = "You can't request saplings, you need to have the \"lplant\" privilege."
					ltool.show_dialog(playername, "ltool:treeform_error_sapling", message)
					return
				end
				local seed = nil
				if(tonumber(fields.seed)~=nil) then
					seed = tonumber(fields.seed)
				end
				local ret, ret2 = ltool.give_sapling(ltool.trees[seltree_id].treedef, seed, playername, true)
				if(ret==false and ret2==2) then
					ltool.save_fields(playername, formname, fields)
					ltool.show_dialog(playername, "ltool:treeform_error_sapling", "Error: The sapling could not be given to you. Probably your inventory is full.")
				end
			end
		end
	--[[ "Edit" tab ]]
	elseif(formname == "ltool:treeform_edit") then
		if(fields.edit_save or fields.edit_sapling) then
			local param1, param2
			param1, param2 = ltool.evaluate_edit_fields(fields, fields.edit_sapling ~= nil)
			if(fields.edit_save and privs.ledit ~= true) then
				ltool.save_fields(playername, formname, fields)
				local message = "You can't save trees, you need to have the \"ledit\" privilege."
				ltool.show_dialog(playername, "ltool:treeform_error_ledit", message)
				return
			end
			if(fields.edit_sapling and privs.lplant ~= true) then
				ltool.save_fields(playername, formname, fields)
				local message = "You can't request saplings, you need to have the \"lplant\" privilege."
				ltool.show_dialog(playername, "ltool:treeform_error_ledit", message)
				return
			end
			local tree_ok = true
			local treedef, name
			if(param1 ~= nil) then
				treedef = param1
				name = param2
				for k,v in pairs(ltool.trees) do
					if(fields.edit_save and v.name == name) then
						ltool.save_fields(playername, formname, fields)
						if(v.author == playername) then
							local formspec = "size[6,2;]label[0,0.2;You already have a tree with this name.\nDo you want to replace it?]"..
							"button[0,1.5;3,1;replace_yes;Yes]"..
							"button[3,1.5;3,1;replace_no;No]"
							minetest.show_formspec(playername, "ltool:treeform_replace", formspec)
						else
							ltool.show_dialog(playername, "ltool:treeform_error_nameclash", "Error: This name is already taken by someone else.\nPlease choose a different name.")
						end
						return
					end
				end
			else
				tree_ok = false
			end
			if(tree_ok == true) then
				if fields.edit_save then
					ltool.add_tree(name, playername, treedef)
				elseif fields.edit_sapling then
					local ret, ret2 = ltool.give_sapling(treedef, tostring(ltool.seed), playername, true)
					if(ret==false and ret2==2) then
						ltool.save_fields(playername, formname, fields)
						ltool.show_dialog(playername, "ltool:treeform_error_sapling", "Error: The sapling could not be given to you. Probably your inventory is full.")
					end
				end
			else
				ltool.save_fields(playername, formname, fields)
				local message = "Error: The tree definition is invalid.\n"..
				minetest.formspec_escape(param2)
				ltool.show_dialog(playername, "ltool:treeform_error_badtreedef", message)
			end
		end
		if(fields.edit_clear) then
			local privs = minetest.get_player_privs(playername)
			local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(nil, privs.ledit, privs.lplant)
			minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
		end
		if(fields.edit_axiom or fields.edit_rules_a or fields.edit_rules_b or fields.edit_rules_c or fields.edit_rules_d) then
			local fragment
			if(fields.edit_axiom) then
				fragment = "axiom;Axiom;"..s(fields.axiom)
			elseif(fields.edit_rules_a) then
				fragment = "rules_a;Rules set A;"..s(fields.rules_a)
			elseif(fields.edit_rules_b) then
				fragment = "rules_b;Rules set B;"..s(fields.rules_b)
			elseif(fields.edit_rules_c) then
				fragment = "rules_c;Rules set C;"..s(fields.rules_c)
			elseif(fields.edit_rules_d) then
				fragment = "rules_d;Rules set D;"..s(fields.rules_d)
			end

			ltool.save_fields(playername, formname, fields)
			local formspec = ltool.formspec_editplus(fragment)
			minetest.show_formspec(playername, "ltool:treeform_editplus", formspec)
		end
	--[[ Larger edit fields for axiom and rules fields ]]
	elseif(formname == "ltool:treeform_editplus") then
		local editfields = ltool.playerinfos[playername].treeform.edit.fields
		local function addchar(c)
			local fragment
			if(c=="P") then c = "[" end
			if(c=="p") then c = "]" end
			if(fields.axiom) then
				fragment = "axiom;Axiom;"..s(fields.axiom..c)
			elseif(fields.rules_a) then
				fragment = "rules_a;Rules set A;"..s(fields.rules_a..c)
			elseif(fields.rules_b) then
				fragment = "rules_b;Rules set B;"..s(fields.rules_b..c)
			elseif(fields.rules_c) then
				fragment = "rules_c;Rules set C;"..s(fields.rules_c..c)
			elseif(fields.rules_d) then
				fragment = "rules_d;Rules set D;"..s(fields.rules_d..c)
			end
			local formspec = ltool.formspec_editplus(fragment)
			minetest.show_formspec(playername, "ltool:treeform_editplus", formspec)
		end
		if(fields.editplus_save) then
			local function o(writed, writer)
				if(writer~=nil) then
					return writer
				else
					return writed
				end
			end
			editfields.axiom = o(editfields.axiom, fields.axiom)
			editfields.rules_a = o(editfields.rules_a, fields.rules_a)
			editfields.rules_b = o(editfields.rules_b, fields.rules_b)
			editfields.rules_c = o(editfields.rules_c, fields.rules_c)
			editfields.rules_d = o(editfields.rules_d, fields.rules_d)
			local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(editfields, privs.ledit, privs.lplant)
			minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
		elseif(fields.editplus_cancel or fields.quit) then
			local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(editfields, privs.ledit, privs.lplant)
			minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
		else
			for id, field in pairs(fields) do
				if(string.sub(id,1,11) == "editplus_c_") then
					local char = string.sub(id,12,12)
					addchar(char)
				end
			end
		end
	--[[ "Database" tab ]]
	elseif(formname == "ltool:treeform_database") then
		if(fields.treelist) then
			local event = minetest.explode_textlist_event(fields.treelist)
			if(event.type == "CHG") then
				ltool.playerinfos[playername].dbsel = event.index
				local formspec = ltool.formspec_size..ltool.formspec_header(2)..ltool.tab_database(event.index, playername)
				minetest.show_formspec(playername, "ltool:treeform_database", formspec)
			end
		elseif(fields.database_copy) then
			if(seltree ~= nil) then
				if(ltool.playerinfos[playername] ~= nil) then
					local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(ltool.tree_to_fields(seltree), privs.ledit, privs.lplant)
					minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
				end
			else
				ltool.show_dialog(playername, "ltool:treeform_error_nodbsel", "Error: No tree is selected.")
			end
		elseif(fields.database_update) then
			local formspec = ltool.formspec_size..ltool.formspec_header(2)..ltool.tab_database(ltool.playerinfos[playername].dbsel, playername)
			minetest.show_formspec(playername, "ltool:treeform_database", formspec)

		elseif(fields.database_delete) then
			if(privs.ledit ~= true) then
				ltool.save_fields(playername, formname, fields)
				local message = "You can't delete trees, you need to have the \"ledit\" privilege."
				ltool.show_dialog(playername, "ltool:treeform_error_ledit_db", message)
				return
			end
			if(seltree ~= nil) then
				if(playername == seltree.author) then
					local remove_id = ltool.get_selected_tree_id(playername)
					if(remove_id ~= nil) then
						ltool.remove_tree(remove_id)
						local formspec = ltool.formspec_size..ltool.formspec_header(2)..ltool.tab_database(ltool.playerinfos[playername].dbsel, playername)
						minetest.show_formspec(playername, "ltool:treeform_database", formspec)
					end
				else
					ltool.show_dialog(playername, "ltool:treeform_error_delete", "Error: This tree is not your own. You may only delete your own trees.")
				end
			else
				ltool.show_dialog(playername, "ltool:treeform_error_nodbsel", "Error: No tree is selected.")
			end
		elseif(fields.database_rename) then
			if(seltree ~= nil) then
				if(privs.ledit ~= true) then
					ltool.save_fields(playername, formname, fields)
					local message = "You can't rename trees, you need to have the \"ledit\" privilege."
					ltool.show_dialog(playername, "ltool:treeform_error_ledit_db", message)
					return
				end
				if(playername == seltree.author) then
					local formspec = "field[newname;New name:;"..minetest.formspec_escape(seltree.name).."]"
					minetest.show_formspec(playername, "ltool:treeform_rename", formspec)
				else
					ltool.show_dialog(playername, "ltool:treeform_error_rename_forbidden", "Error: This tree is not your own. You may only rename your own trees.")
				end
			else
				ltool.show_dialog(playername, "ltool:treeform_error_nodbsel", "Error: No tree is selected.")
			end
		end
	--[[ Process "Do you want to replace this tree?" dialog ]]
	elseif(formname == "ltool:treeform_replace") then
		local editfields = ltool.playerinfos[playername].treeform.edit.fields
		local newtreedef, newname = ltool.evaluate_edit_fields(editfields)
		if(privs.ledit ~= true) then
			local message = "You can't overwrite trees, you need to have the \"ledit\" privilege."
			minetest.show_dialog(playername, "ltool:treeform_error_ledit", message)
			return
		end
		if(fields.replace_yes) then
			for tree_id,tree in pairs(ltool.trees) do
				if(tree.name == newname) then
					--[[ The old tree is deleted and a
					new one with a new ID is created ]]
					local new_tree_id = ltool.next_tree_id
					ltool.trees[new_tree_id] = {}
					ltool.trees[new_tree_id].treedef = newtreedef
					ltool.trees[new_tree_id].name = newname
					ltool.trees[new_tree_id].author = tree.author
					ltool.next_tree_id = ltool.next_tree_id + 1
					ltool.trees[tree_id] = nil
					ltool.playerinfos[playername].dbsel = ltool.number_of_trees
				end
			end
		end
		local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(editfields, privs.ledit, privs.lplant)
		minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
	elseif(formname == "ltool:treeform_help") then
		local tab = tonumber(fields.ltool_help_tab)
		if(tab ~= nil) then
			ltool.playerinfos[playername].treeform.help.tab = tab
			local formspec = ltool.formspec_size..ltool.formspec_header(4)..ltool.tab_help(tab)
			minetest.show_formspec(playername, "ltool:treeform_help", formspec)
		end
		if(fields.create_template) then
			local newfields = {
				axiom="FFFFFAFFBF",
				rules_a="[&&&FFFFF&&FFFF][&&&++++FFFFF&&FFFF][&&&----FFFFF&&FFFF]",
				rules_b="[&&&++FFFFF&&FFFF][&&&--FFFFF&&FFFF][&&&------FFFFF&&FFFF]",
				trunk="mapgen_tree",
				leaves="mapgen_leaves",
				angle="30",
				iterations="2",
				random_level="0",
				trunk_type="single",
				thin_branches="true",
				fruit_chance="10",
				fruit="mapgen_apple",
				name = "Example Tree "..ltool.next_tree_id
			}
			ltool.save_fields(playername, formname, newfields)
			local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(newfields, privs.ledit, privs.lplant)
			minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
		end
	--[[ Tree renaming dialog ]]
	elseif(formname == "ltool:treeform_rename") then
		if(privs.ledit ~= true) then
			ltool.save_fields(playername, formname, fields)
			local message = "You can't delete trees, you need to have the \"ledit\" privilege."
			ltool.show_dialog(playername, "ltool:treeform_error_ledit_delete", message)
			return
		end
		if(fields.newname ~= "" and fields.newname ~= nil) then
			ltool.rename_tree(ltool.get_selected_tree_id(playername), fields.newname)
			local formspec = ltool.formspec_size..ltool.formspec_header(2)..ltool.tab_database(ltool.playerinfos[playername].dbsel, playername)
			minetest.show_formspec(playername, "ltool:treeform_database", formspec)
		else
			ltool.show_dialog(playername, "ltool:treeform_error_bad_rename", "Error: This name is empty. The tree name must be non-empty.")
		end
	--[[ Here come various error messages to handle ]]
	elseif(formname == "ltool:treeform_error_badtreedef" or formname == "ltool:treeform_error_nameclash" or formname == "ltool:treeform_error_ledit") then
		local formspec = ltool.formspec_size..ltool.formspec_header(1)..ltool.tab_edit(ltool.playerinfos[playername].treeform.edit.fields, privs.ledit, privs.lplant)
		minetest.show_formspec(playername, "ltool:treeform_edit", formspec)
	elseif(formname == "ltool:treeform_error_badplantfields" or formname == "ltool:treeform_error_sapling" or formname == "ltool:treeform_error_lplant") then
		local formspec = ltool.formspec_size..ltool.formspec_header(3)..ltool.tab_plant(seltree, ltool.playerinfos[playername].treeform.plant.fields, privs.lplant)
		minetest.show_formspec(playername, "ltool:treeform_plant", formspec)
	elseif(formname == "ltool:treeform_error_delete" or formname == "ltool:treeform_error_rename_forbidden" or formname == "ltool:treeform_error_nodbsel" or formname == "ltool:treeform_error_ledit_db") then
		local formspec = ltool.formspec_size..ltool.formspec_header(2)..ltool.tab_database(ltool.playerinfos[playername].dbsel, playername)
		minetest.show_formspec(playername, "ltool:treeform_database", formspec)
	elseif(formname == "ltool:treeform_error_bad_rename") then
		local formspec = "field[newname;New name:;"..minetest.formspec_escape(seltree.name).."]"
		minetest.show_formspec(playername, "ltool:treeform_rename", formspec)
	else
		-- Action for Inventory++ button
		--if fields.ltool and minetest.get_modpath("inventory_plus") then
		--	ltool.show_treeform(playername)
		--	return
		--end
	end
end

--[[ These 2 functions are basically just table initializions and cleanups ]]
function ltool.leave(player)
	ltool.playerinfos[player:get_player_name()] = nil
end

function ltool.join(player)
	local infotable = {}
	infotable.dbsel = nil
	infotable.treeform = {}
	infotable.treeform.database = {}
	--[[ This table stores a mapping of the textlist IDs in the database formspec and the tree IDs.
	It is updated each time ltool.tab_database is called. ]]
	infotable.treeform.database.textlist = nil
	--[[ the “fields” tables store the values of the input fields of a formspec. It is updated
	whenever the formspec is changed, i.e. on tab change ]]
	infotable.treeform.database.fields = {}
	infotable.treeform.plant = {}
	infotable.treeform.plant.fields = {}
	infotable.treeform.edit = {}
	infotable.treeform.edit.fields = {}
	infotable.treeform.help = {}
	infotable.treeform.help.tab = 1
	ltool.playerinfos[player:get_player_name()] = infotable

	-- Add Inventory++ support
	--if minetest.get_modpath("inventory_plus") then
	--	inventory_plus.register_button(player, "ltool", "L-System Tree Utility")
	--end
end

function ltool.save_to_file()
	local savetable = {}
	savetable.trees = ltool.trees
	savetable.number_of_trees = ltool.number_of_trees
	savetable.next_tree_id = ltool.next_tree_id
	local savestring = minetest.serialize(savetable)
	local filepath = minetest.get_worldpath().."/ltool.mt"
	local file = io.open(filepath, "w")
	if(file) then
		file:write(savestring)
		io.close(file)
		minetest.log("action", "[ltool] Tree data saved to "..filepath..".")
	else
		minetest.log("error", "[ltool] Failed to write ltool data to "..filepath".")
	end
	
end

minetest.register_on_player_receive_fields(ltool.process_form)

minetest.register_on_leaveplayer(ltool.leave)

minetest.register_on_joinplayer(ltool.join)

minetest.register_on_shutdown(ltool.save_to_file)

local button_action = function(player)
	ltool.show_treeform(player:get_player_name())
end

if minetest.get_modpath("unified_inventory") ~= nil then
	unified_inventory.register_button("ltool", {
		type = "image",
		image = "ltool_sapling.png",
		tooltip = "L-System Tree Utility",
		action = button_action,
	})
end

if minetest.get_modpath("sfinv_buttons") ~= nil then
	sfinv_buttons.register_button("ltool", {
		title = "L-System Tree Utility",
		tooltip = "Invent your own trees and plant them",
		image = "ltool_sapling.png",
		action = button_action,
	})
end


