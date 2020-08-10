--non eatable craftitems

minetest.register_craftitem("nssm:white_wolf_fur", {
	description = "White Wolf Fur",
	image = "white_wolf_fur.png",
	groups = {flammable = 2, leather = 1},
})

--[[
local function nssm_craftitem (name, descr)

	minetest.register_craftitem("nssm:"..name, {
		description = descr,
		image = name..".png",
	})
end
--]]

--[[
nssm_craftitem ('sky_feather','Sky Feather')
nssm_craftitem ('snake_scute','Snake Scute')
nssm_craftitem ('eyed_tentacle','Eyed Tentacle')
--nssm_craftitem ('king_duck_crown','King Duck Crown')
nssm_craftitem ('great_energy_globe','Great Energy Globe')
nssm_craftitem ('superior_energy_globe','Superior Energy Globe')
nssm_craftitem ('ant_queen_abdomen','Ant Queen Abdomen')
--nssm_craftitem ('masticone_skull','Masticone Skull')
nssm_craftitem ('masticone_skull_fragments','Masticone Skull Fragments')
--nssm_craftitem ('masticone_skull_crowned','Masticone Skull Crowned')
nssm_craftitem ('tentacle_curly','Kraken Tentacle')
nssm_craftitem ('lava_titan_eye','Lava Titan Eye')
nssm_craftitem ('duck_beak','Duck Beak')
nssm_craftitem ('ice_tooth','Ice Tooth')
nssm_craftitem ('little_ice_tooth','Little Ice Tooth')
nssm_craftitem ('digested_sand',"Digested Sand")
nssm_craftitem ('black_ice_tooth','Black Ice Tooth')
nssm_craftitem ('tarantula_chelicerae','Tarantula Chelicerae')
nssm_craftitem ('crab_chela','Crab Chela')
nssm_craftitem ('cursed_pumpkin_seed','Cursed Pumpkin Seed')
nssm_craftitem ('mantis_claw','Mantis Claw')
nssm_craftitem ('manticore_fur','Manticore Fur')
nssm_craftitem ('ant_hard_skin','Ant Hard Skin')
nssm_craftitem ('bloco_skin','Bloco Skin')
nssm_craftitem ('crab_carapace_fragment','Crab Carapace Fragment')
nssm_craftitem ('crocodile_skin','Crocodile Skin')
nssm_craftitem ('manticore_spine','Manticore Spine')
nssm_craftitem ('night_feather','Night Feather')
nssm_craftitem ('sun_feather','Sun Feather')
nssm_craftitem ('duck_feather','Duck Feather')
nssm_craftitem ('black_duck_feather','Black Duck Feather')
nssm_craftitem ('masticone_fang','Masticone Fang')
--]]

--[[
nssm_craftitem ('stoneater_mandible','Stoneater Mandible')
nssm_craftitem ('ant_mandible','Ant Mandible')
nssm_craftitem ('life_energy','Life Energy')
nssm_craftitem ('wolf_fur','Wolf Fur')
nssm_craftitem ('felucco_fur','Felucco Fur')
nssm_craftitem ('felucco_horn','Felucco Horn')
nssm_craftitem ('energy_globe','Energy Globe')
nssm_craftitem ('greedy_soul_fragment','Greedy Soul Fragment')
nssm_craftitem ('lustful_soul_fragment','Lustful Soul Fragment')
nssm_craftitem ('wrathful_soul_fragment','Wrathful Soul Fragment')
nssm_craftitem ('proud_soul_fragment','Proud Soul Fragment')
nssm_craftitem ('slothful_soul_fragment','Slothful Soul Fragment')
nssm_craftitem ('envious_soul_fragment','Envious Soul Fragment')
nssm_craftitem ('gluttonous_soul_fragment','Gluttonous Soul Fragment')
nssm_craftitem ('gluttonous_moranga','Gluttonous Moranga')
nssm_craftitem ('envious_moranga','Envious Moranga')
nssm_craftitem ('proud_moranga','Proud Moranga')
nssm_craftitem ('slothful_moranga','Slothful Moranga')
nssm_craftitem ('lustful_moranga','Lustful Moranga')
nssm_craftitem ('wrathful_moranga','Wrathful Moranga')
nssm_craftitem ('greedy_moranga','Greedy Moranga')
nssm_craftitem ('mantis_skin','Mantis_skin')
nssm_craftitem ('sand_bloco_skin','Sand Bloco Skin')
nssm_craftitem ('sandworm_skin','Sandworm Skin')
nssm_craftitem ('sky_iron','Sky Iron')
nssm_craftitem ('web_string','Cobweb String')
nssm_craftitem ('dense_web_string','Dense Cobweb String')
nssm_craftitem ('black_powder','Black Powder')
nssm_craftitem ('morelentir_dust','Dark Starred Stone Dust')
nssm_craftitem ('empty_evocation_bomb','Empty Evocation Bomb')
--]]

--[[
local function nssm_craftitem_eat (name, descr, gnam)

	minetest.register_craftitem("nssm:"..name, {
		description = descr,
		image =name..".png",
		on_use = minetest.item_eat(gnam),
		groups = { meat=1, eatable=1 },
	})
end
--]]

--[[
nssm_craftitem_eat ('felucco_steak','Felucco Steak',3)
nssm_craftitem_eat ('roasted_felucco_steak','Roasted Felucco Steak',6)
nssm_craftitem_eat ('heron_leg','Moonheron Leg',2)
nssm_craftitem_eat ('chichibios_heron_leg',"Chichibio's Moonheron Leg",4)
nssm_craftitem_eat ('crocodile_tail','Crocodile Tail',3)
nssm_craftitem_eat ('roasted_crocodile_tail','Roasted Crocodile Tail',6)
--]]

--[[
nssm_craftitem_eat ('duck_legs','Duck Legs',1)
nssm_craftitem_eat ('roasted_duck_legs','Roasted Duck Leg',3)
nssm_craftitem_eat ('ant_leg','Ant Leg',-1)
nssm_craftitem_eat ('roasted_ant_leg','Roasted Ant Leg',4)
nssm_craftitem_eat ('spider_leg','Spider Leg',-1)
nssm_craftitem_eat ('roasted_spider_leg','Roasted Spider Leg',4)
--nssm_craftitem_eat ('brain','Brain',3)
--nssm_craftitem_eat ('roasted_brain','Roasted Brain',8)
nssm_craftitem_eat ('tentacle','Tentacle',2)
nssm_craftitem_eat ('roasted_tentacle','Roasted Tentacle',5)
nssm_craftitem_eat ('worm_flesh','Worm Flesh',-2)
nssm_craftitem_eat ('roasted_worm_flesh','Roasted Worm Flesh',4)
nssm_craftitem_eat ('amphibian_heart','Amphibian Heart',1)
nssm_craftitem_eat ('roasted_amphibian_heart','Roasted Amphibian Heart',8)
nssm_craftitem_eat ('raw_scrausics_wing','Raw Scrausics Wing',1)
nssm_craftitem_eat ('spicy_scrausics_wing','Spicy Scrausics Wing',6)
nssm_craftitem_eat ('phoenix_nuggets','Phoenix Nuggets',20)
nssm_craftitem_eat ('phoenix_tear','Phoenix Tear',20)
nssm_craftitem_eat ('frosted_amphibian_heart','Frosted Amphibian Heart',-1)
nssm_craftitem_eat ('surimi','Surimi',4)
nssm_craftitem_eat ('amphibian_ribs','Amphibian Ribs',2)
nssm_craftitem_eat ('roasted_amphibian_ribs','Roasted Amphibian Ribs',6)
nssm_craftitem_eat ('dolidrosaurus_fin','Dolidrosaurus Fin',-2)
nssm_craftitem_eat ('roasted_dolidrosaurus_fin','Roasted Dolidrosaurus Fin',4)
nssm_craftitem_eat ('larva_meat','Larva Meat',-1)
nssm_craftitem_eat ('larva_juice','Larva Juice',-3)
nssm_craftitem_eat ('larva_soup','Larva Soup',10)
nssm_craftitem_eat ('mantis_meat','Mantis Meat',1)
nssm_craftitem_eat ('roasted_mantis_meat','Roasted Mantis Meat',4)
nssm_craftitem_eat ('spider_meat','Spider Meat',-1)
nssm_craftitem_eat ('roasted_spider_meat','Roasted Spider Meat',3)
nssm_craftitem_eat ('silk_gland','Silk Gland',-1)
nssm_craftitem_eat ('roasted_silk_gland','Roasted Silk Gland',3)
nssm_craftitem_eat ('super_silk_gland','Super Silk Gland',-8)
nssm_craftitem_eat ('roasted_super_silk_gland','Roasted Super Silk Gland',2)
--]]
