
-- Simple Skins mod for minetest (5th June 2016)
-- Adds a simple skin selector to the inventory, using inventory_plus
-- or by using the /skin command to bring up selection list.
-- Released by TenPlus1 and based on Zeg9's code under WTFPL

skins = {}
skins.skins = {}
skins.modpath = minetest.get_modpath("simple_skins")
skins.armor = minetest.get_modpath("3d_armor")
skins.inv = minetest.get_modpath("inventory_plus")

-- Localize for performance.
local math_random = math.random

-- load skin list
skins.list = {}
skins.add = function(skin)
	table.insert(skins.list, skin)
end

local id = 1
local f
while true do
	f = io.open(skins.modpath .. "/textures/character_" .. id .. ".png")
	if not f then break end
	f:close()
	skins.add("character_" .. id)
	id = id + 1
end

id = id - 1

-- load Metadata
skins.meta = {}
local f, data
for _, i in pairs(skins.list) do
	skins.meta[i] = {}
	f = io.open(skins.modpath .. "/meta/" .. i .. ".txt")
	data = nil
	if f then
		data = minetest.deserialize("return {" .. f:read('*all') .. "}")
		f:close()
	end
	data = data or {}
	skins.meta[i].name = data.name or ""
	skins.meta[i].author = data.author or ""
	skins.meta[i].sex = data.sex or ""
    
    if type(data.enable) == "boolean" then
        if data.enable == true then
            skins.meta[i].enable = true
        else
            skins.meta[i].enable = false
        end
    else
        skins.meta[i].enable = true
    end
end

-- player load/save routines
skins.file = minetest.get_worldpath() .. "/simple_skins.mt"

skins.load = function()
	local input = io.open(skins.file, "r")
	local data = nil
	if input then
		data = input:read('*all')
	end
	if data and data ~= "" then
		local lines = string.split(data, "\n")
		for _, line in pairs(lines) do
			data = string.split(line, ' ', 2)
			skins.skins[data[1]] = data[2]
		end
		io.close(input)
	end
end

-- load player skins now
skins.load()

skins.save = function()
	local output = io.open(skins.file,'w')
	for name, skin in pairs(skins.skins) do
		if name and skin then
			output:write(name .. " " .. skin .. "\n")
		end
	end
	io.close(output)
end

-- skin selection page
skins.formspec = {}
skins.formspec.main = function(name)

	local selected = 1 -- select default
	local formspec = "size[8,8.5]"
		.. "bgcolor[#08080860;false]"
		.. "label[.5,2;Choose Your Avatar:]"
		.. "textlist[0.5,2.5;7,6;skins_set;"

	for i = 1, #skins.list do
        --if skins.meta[skins.list[i]].enable then
            formspec = formspec .. skins.meta[ skins.list[i] ].name .. ","

            if skins.skins[name] == skins.list[i] then
                selected = i
            end
        --end
	end

	formspec = formspec .. ";" .. selected .. ";true]"

	local meta = skins.meta[ skins.skins[name] ]

	if meta then
		if meta.name then
			formspec = formspec .. "label[3,.25;Name: " .. meta.name .. "]"
		end
		if meta.author then
			formspec = formspec .. "label[3,.65;Author: " .. meta.author .. "]"
		end
	end

	-- Show avatar number (MustTest).
	formspec = formspec .. "label[3,1.05;Avatar #: " .. selected .. "]"

	-- Back button moved here (MustTest).
	formspec = formspec .. "button[0.5,0.5;2,.5;main;Back]"
	return formspec
end

-- update player skin
skins.update_player_skin = function(player)

	if not player then
		return
	end

	local name = player:get_player_name()

	if skins.armor then
		armor.textures[name].skin = skins.skins[name] .. ".png"
		armor:set_player_armor(player)
	else
		pova.set_override(player, "properties", {
			textures = {skins.skins[name] .. ".png"},
		})
	end

	skins.save()
end

-- load player skin on join
minetest.register_on_joinplayer(function(player)

	local name = player:get_player_name()

	if not skins.skins[name] then
		skins.skins[name] = "character_1"
	end

	skins.update_player_skin(player)
end)

-- formspec control
minetest.register_on_player_receive_fields(function(player, formname, fields)

	local name = player:get_player_name()

	if fields.skins then
		inventory_plus.set_inventory_formspec(player, skins.formspec.main(name))
	end

	local event = minetest.explode_textlist_event(fields["skins_set"])

	if event.type == "CHG" then

		local index = event.index

		if index > id then index = id end

		skins.skins[name] = skins.list[index]
		minetest.log("action", name .. " selects skin " .. index)

		if skins.inv then
			inventory_plus.set_inventory_formspec(player, skins.formspec.main(name))
		end

		skins.update_player_skin(player)
	end
end)



-- Utility functions.
function skins.get_player_sex(pname)
	if type(pname) ~= "string" then
		pname = pname:get_player_name()
	end

	local c = skins.skins[pname]
	if type(c) ~= "string" then
		return ""
	end
	
	local meta = skins.meta[c]
	if type(meta.sex) ~= "string" then
		return ""
	end

	if meta.sex == "female" then
		return "female"
	end
	if meta.sex == "male" then
		return "male"
	end

	return ""
end

function skins.get_gender_strings(pname)
	local sex = skins.get_player_sex(pname)
	local data = {}
	
	if sex == "male" then
		data.him = "him"
		data.he = "he"
		data.his = "his"
		data.his_possessive = "his"
		data.himself = "himself"
	elseif sex == "female" then
		data.him = "her"
		data.he = "she"
		data.his = "her"
		data.his_possessive = "hers"
		data.himself = "herself"
	else
		data.him = "it"
		data.he = "it"
		data.his = "its"
		data.his_possessive = "its"
		data.himself = "itself"
	end

	return data
end

function skins.get_random_standard_gender(fem_chance)
	local data = {}

	if math_random(1, 100) <= fem_chance then
		data.him = "her"
		data.he = "she"
		data.his = "her"
		data.his_possessive = "hers"
		data.himself = "herself"
	else
		data.him = "him"
		data.he = "he"
		data.his = "his"
		data.his_possessive = "his"
		data.himself = "himself"
	end

	return data
end

-- Register button once.
if skins.inv then
	inventory_plus.register_button("skins", "Avatar")
end
