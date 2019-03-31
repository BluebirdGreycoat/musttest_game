
tooldata = tooldata or {}

local modpath = minetest.get_modpath("tooldata")
local DIG_TIME_MULTIPLIER = 1.0

-- Basic paramters based on material type.
local materials = {}
materials["wood"]          = {fpi=1.2, time=5.0, uses=20,  mdl=1, ml=1, dmg=1}
materials["stone"]         = {fpi=1.5, time=4.0, uses=30,  mdl=1, ml=1, dmg=3}
materials["steel"]         = {fpi=1.0, time=3.5, uses=100, mdl=2, ml=2, dmg=6}
materials["bronze"]        = {fpi=1.0, time=2.5, uses=50,  mdl=2, ml=2, dmg=5}
materials["mese"]          = {fpi=0.5, time=2.5, uses=70,  mdl=3, ml=3, dmg=7}
materials["diamond"]       = {fpi=0.7, time=2.0, uses=40,  mdl=3, ml=3, dmg=7}
materials["titanium"]      = {fpi=1.1, time=2.5, uses=150, mdl=3, ml=3, dmg=6}
materials["silver"]        = {fpi=0.9, time=4.0, uses=20,  mdl=3, ml=3, dmg=5}
materials["mithril"]       = {fpi=0.9, time=2.0, uses=60,  mdl=3, ml=3, dmg=8}
materials["ruby"]          = {fpi=1.0, time=1.2, uses=40,  mdl=3, ml=3, dmg=7}
materials["emerald"]       = {fpi=1.0, time=1.2, uses=40,  mdl=3, ml=3, dmg=7}
materials["sapphire"]      = {fpi=1.0, time=1.2, uses=40,  mdl=3, ml=3, dmg=7}
materials["amethyst"]      = {fpi=1.0, time=1.2, uses=40,  mdl=3, ml=3, dmg=7}
materials["rubystone"]     = {fpi=1.2, time=2.0, uses=60,  mdl=3, ml=3, dmg=6}
materials["emeraldstone"]  = {fpi=1.2, time=2.0, uses=60,  mdl=3, ml=3, dmg=6}
materials["sapphirestone"] = {fpi=1.2, time=2.0, uses=60,  mdl=3, ml=3, dmg=6}
materials["amethyststone"] = {fpi=1.2, time=2.0, uses=60,  mdl=3, ml=3, dmg=6}

-- Multipliers based on tool type.
local tools = {}
tools["sword"]  = {swing_mp=1.0, damage_mp=1.0}
tools["axe"]    = {swing_mp=1.0, damage_mp=0.8}
tools["pick"]   = {swing_mp=1.2, damage_mp=0.7}
tools["shovel"] = {swing_mp=1.2, damage_mp=0.5}

-- Placeholder tables. Will be populated algorithmically.
tooldata["pick_wood"] =            {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_stone"] =           {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_steel"] =           {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_bronze"] =          {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_mese"] =            {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_diamond"] =         {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_titanium"] =        {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_silver"] =          {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_mithril"] =         {groupcaps={cracky ={times={}, maxlevel=1}}, damage_groups={fleshy=true}}
tooldata["pick_ruby"] =            {groupcaps={cracky ={times={}, maxlevel=1}}, damage_groups={fleshy=true}}
tooldata["pick_emerald"] =         {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_sapphire"] =        {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_amethyst"] =        {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_rubystone"] =       {groupcaps={cracky ={times={}, maxlevel=1}}, damage_groups={fleshy=true}}
tooldata["pick_emeraldstone"] =    {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_sapphirestone"] =   {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["pick_amethyststone"] =   {groupcaps={cracky ={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_stone"] =         {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_steel"] =         {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_bronze"] =        {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_mese"] =          {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_diamond"] =       {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_titanium"] =      {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_silver"] =        {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_mithril"] =       {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_ruby"] =          {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_emerald"] =       {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_sapphire"] =      {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_amethyst"] =      {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_rubystone"] =     {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_emeraldstone"] =  {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_sapphirestone"] = {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["shovel_amethyststone"] = {groupcaps={crumbly={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_stone"] =            {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_steel"] =            {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_bronze"] =           {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_mese"] =             {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_diamond"] =          {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_titanium"] =         {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_silver"] =           {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_mithril"] =          {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_ruby"] =             {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_emerald"] =          {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_sapphire"] =         {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_amethyst"] =         {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_rubystone"] =        {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_emeraldstone"] =     {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_sapphirestone"] =    {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["axe_amethyststone"] =    {groupcaps={choppy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_stone"] =          {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_steel"] =          {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_bronze"] =         {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_mese"] =           {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_diamond"] =        {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_titanium"] =       {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_silver"] =         {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_mithril"] =        {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_ruby"] =           {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_emerald"] =        {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_sapphire"] =       {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_amethyst"] =       {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_rubystone"] =      {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_emeraldstone"] =   {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_sapphirestone"] =  {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}
tooldata["sword_amethyststone"] =  {groupcaps={snappy ={times={},           }}, damage_groups={fleshy=true}}



for k, v in pairs(tooldata) do
	-- Get tool type and data tables.
	local tn = k:split("_")[1]
	local td = tools[tn]
	assert(td)

	-- Get material name and data tables.
	local mn = k:split("_")[2]
	local md = materials[mn]
	assert(md)

	-- Assign basic values.
	v.full_punch_interval = md.fpi * td.swing_mp
	v.max_drop_level = md.mdl
	v.uses = md.uses

	-- Assign digging times per dig-group.
  for t, j in pairs(v.groupcaps) do
		j.times[1] = (md.time/1) * DIG_TIME_MULTIPLIER
		j.times[2] = (md.time/2) * DIG_TIME_MULTIPLIER
		j.times[3] = (md.time/3) * DIG_TIME_MULTIPLIER

		-- Assign maxlevel.
		j.maxlevel = (j.maxlevel or 0) + md.ml
  end

	-- Assign damage amounts per damage-group.
	for t, j in pairs(v.damage_groups) do
		v.damage_groups[t] = md.dmg * td.damage_mp
	end
end

dofile(modpath .. "/technic.lua")
