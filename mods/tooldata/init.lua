
tooldata = tooldata or {}

local modpath = minetest.get_modpath("tooldata")
local DIG_TIME_MULTIPLIER = 0.7



-- Copper tools should be fast, but wear out quickly.
-- Gem tools should be fastest and last long, (but each gem has a best tool, other tools should be similar to diamond).
-- Titanium tools should have medium speed, but last the longest.



tooldata["pick_wood"] =            {full_punch_interval=1.2, max_drop_level=1, groupcaps={cracky ={times={[2]=7.0 },    uses=10,  maxlevel=1}}, damage_groups={fleshy=2}}
tooldata["pick_stone"] =           {full_punch_interval=1.3, max_drop_level=1, groupcaps={cracky ={times={[2]=3.5 },    uses=30,  maxlevel=1}}, damage_groups={fleshy=3}}
tooldata["pick_steel"] =           {full_punch_interval=1.0, max_drop_level=1, groupcaps={cracky ={times={[1]=3.5 },    uses=50,  maxlevel=2}}, damage_groups={fleshy=4}}
tooldata["pick_bronze"] =          {full_punch_interval=1.0, max_drop_level=1, groupcaps={cracky ={times={[1]=2.5 },    uses=20,  maxlevel=2}}, damage_groups={fleshy=4}}
tooldata["pick_mese"] =            {full_punch_interval=0.9, max_drop_level=3, groupcaps={cracky ={times={[1]=2.4 },    uses=70,  maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_diamond"] =         {full_punch_interval=0.9, max_drop_level=3, groupcaps={cracky ={times={[1]=2.0 },    uses=40,  maxlevel=3}}, damage_groups={fleshy=5}}

tooldata["pick_titanium"] =        {full_punch_interval=1.0, max_drop_level=3, groupcaps={cracky ={times={[1]=2.4 },    uses=200, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_silver"] =          {full_punch_interval=0.9, max_drop_level=3, groupcaps={cracky ={times={[1]=1.5 },    uses=20,  maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_mithril"] =         {full_punch_interval=0.9, max_drop_level=3, groupcaps={cracky ={times={[1]=2.0 },    uses=60,  maxlevel=4}}, damage_groups={fleshy=5}}

tooldata["pick_ruby"] =            {full_punch_interval=0.8, max_drop_level=3, groupcaps={cracky ={times={[1]=1.2 },    uses=125, maxlevel=4}}, damage_groups={fleshy=5}}
tooldata["pick_emerald"] =         {full_punch_interval=0.8, max_drop_level=3, groupcaps={cracky ={times={[1]=1.9 },    uses=120, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_sapphire"] =        {full_punch_interval=0.8, max_drop_level=3, groupcaps={cracky ={times={[1]=2.0 },    uses=115, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_amethyst"] =        {full_punch_interval=0.8, max_drop_level=3, groupcaps={cracky ={times={[1]=2.2 },    uses=115, maxlevel=3}}, damage_groups={fleshy=5}}

tooldata["pick_rubystone"] =       {full_punch_interval=1.1, max_drop_level=3, groupcaps={cracky ={times={[1]=1.2 },    uses=155, maxlevel=4}}, damage_groups={fleshy=5}}
tooldata["pick_emeraldstone"] =    {full_punch_interval=1.1, max_drop_level=3, groupcaps={cracky ={times={[1]=1.9 },    uses=150, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_sapphirestone"] =   {full_punch_interval=1.1, max_drop_level=3, groupcaps={cracky ={times={[1]=2.0 },    uses=145, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["pick_amethyststone"] =   {full_punch_interval=1.1, max_drop_level=3, groupcaps={cracky ={times={[1]=2.2 },    uses=145, maxlevel=3}}, damage_groups={fleshy=5}}

tooldata["shovel_stone"] =         {full_punch_interval=1.4, max_drop_level=1, groupcaps={crumbly={times={[2]=4.00},    uses=20,  maxlevel=1}}, damage_groups={fleshy=2}}
tooldata["shovel_steel"] =         {full_punch_interval=1.1, max_drop_level=1, groupcaps={crumbly={times={[1]=1.50},    uses=30,  maxlevel=2}}, damage_groups={fleshy=3}}
tooldata["shovel_bronze"] =        {full_punch_interval=1.1, max_drop_level=1, groupcaps={crumbly={times={[1]=1.20},    uses=20,  maxlevel=2}}, damage_groups={fleshy=3}}
tooldata["shovel_mese"] =          {full_punch_interval=1.0, max_drop_level=2, groupcaps={crumbly={times={[1]=1.20},    uses=50,  maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_diamond"] =       {full_punch_interval=1.0, max_drop_level=3, groupcaps={crumbly={times={[1]=1.10},    uses=30,  maxlevel=3}}, damage_groups={fleshy=4}}

tooldata["shovel_titanium"] =      {full_punch_interval=1.0, max_drop_level=3, groupcaps={crumbly={times={[1]=1.0 },    uses=200, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_silver"] =        {full_punch_interval=1.0, max_drop_level=3, groupcaps={crumbly={times={[1]=1.10},    uses=30,  maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_mithril"] =       {full_punch_interval=1.0, max_drop_level=3, groupcaps={crumbly={times={[1]=1.10},    uses=30,  maxlevel=3}}, damage_groups={fleshy=4}}

tooldata["shovel_ruby"] =          {full_punch_interval=0.8, max_drop_level=3, groupcaps={crumbly={times={[1]=1.30},    uses=125, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_emerald"] =       {full_punch_interval=0.8, max_drop_level=3, groupcaps={crumbly={times={[1]=0.70},    uses=130, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_sapphire"] =      {full_punch_interval=0.8, max_drop_level=3, groupcaps={crumbly={times={[1]=1.30},    uses=115, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_amethyst"] =      {full_punch_interval=0.8, max_drop_level=3, groupcaps={crumbly={times={[1]=1.30},    uses=125, maxlevel=3}}, damage_groups={fleshy=4}}

tooldata["shovel_rubystone"] =     {full_punch_interval=1.1, max_drop_level=3, groupcaps={crumbly={times={[1]=1.30},    uses=155, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_emeraldstone"] =  {full_punch_interval=1.1, max_drop_level=3, groupcaps={crumbly={times={[1]=0.70},    uses=160, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_sapphirestone"] = {full_punch_interval=1.1, max_drop_level=3, groupcaps={crumbly={times={[1]=1.30},    uses=145, maxlevel=3}}, damage_groups={fleshy=4}}
tooldata["shovel_amethyststone"] = {full_punch_interval=1.1, max_drop_level=3, groupcaps={crumbly={times={[1]=1.30},    uses=155, maxlevel=3}}, damage_groups={fleshy=4}}

tooldata["axe_stone"] =            {full_punch_interval=1.2, max_drop_level=1, groupcaps={choppy ={times={[1]=6.00},    uses=20,  maxlevel=1}}, damage_groups={fleshy=3}}
tooldata["axe_steel"] =            {full_punch_interval=1.0, max_drop_level=1, groupcaps={choppy ={times={[1]=2.50},    uses=50,  maxlevel=2}}, damage_groups={fleshy=4}}
tooldata["axe_bronze"] =           {full_punch_interval=1.0, max_drop_level=1, groupcaps={choppy ={times={[1]=1.50},    uses=20,  maxlevel=2}}, damage_groups={fleshy=4}}
tooldata["axe_mese"] =             {full_punch_interval=0.9, max_drop_level=2, groupcaps={choppy ={times={[1]=2.20},    uses=70,  maxlevel=3}}, damage_groups={fleshy=6}}
tooldata["axe_diamond"] =          {full_punch_interval=0.9, max_drop_level=3, groupcaps={choppy ={times={[1]=2.10},    uses=40,  maxlevel=3}}, damage_groups={fleshy=7}}

tooldata["axe_titanium"] =         {full_punch_interval=0.9, max_drop_level=3, groupcaps={choppy ={times={[1]=2.50},    uses=200, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["axe_silver"] =           {full_punch_interval=0.9, max_drop_level=3, groupcaps={choppy ={times={[1]=1.50},    uses=30,  maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["axe_mithril"] =          {full_punch_interval=0.9, max_drop_level=3, groupcaps={choppy ={times={[1]=2.10},    uses=30,  maxlevel=3}}, damage_groups={fleshy=7}}

tooldata["axe_ruby"] =             {full_punch_interval=0.8, max_drop_level=3, groupcaps={choppy ={times={[1]=1.60},    uses=125, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["axe_emerald"] =          {full_punch_interval=0.8, max_drop_level=3, groupcaps={choppy ={times={[1]=2.00},    uses=120, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["axe_sapphire"] =         {full_punch_interval=0.8, max_drop_level=3, groupcaps={choppy ={times={[1]=1.20},    uses=115, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["axe_amethyst"] =         {full_punch_interval=0.8, max_drop_level=3, groupcaps={choppy ={times={[1]=2.00},    uses=115, maxlevel=3}}, damage_groups={fleshy=5}}

tooldata["axe_rubystone"] =        {full_punch_interval=1.1, max_drop_level=3, groupcaps={choppy ={times={[1]=1.60},    uses=155, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["axe_emeraldstone"] =     {full_punch_interval=1.1, max_drop_level=3, groupcaps={choppy ={times={[1]=2.00},    uses=150, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["axe_sapphirestone"] =    {full_punch_interval=1.1, max_drop_level=3, groupcaps={choppy ={times={[1]=1.20},    uses=145, maxlevel=3}}, damage_groups={fleshy=5}}
tooldata["axe_amethyststone"] =    {full_punch_interval=1.1, max_drop_level=3, groupcaps={choppy ={times={[1]=2.00},    uses=145, maxlevel=3}}, damage_groups={fleshy=5}}
                                   
tooldata["sword_stone"] =          {full_punch_interval=1.2, max_drop_level=1, groupcaps={snappy ={times={[2]=2.5 },    uses=20,  maxlevel=1}}, damage_groups={fleshy=4}}
tooldata["sword_steel"] =          {full_punch_interval=0.8, max_drop_level=1, groupcaps={snappy ={times={[1]=2.5 },    uses=50,  maxlevel=2}}, damage_groups={fleshy=6}}
tooldata["sword_bronze"] =         {full_punch_interval=0.8, max_drop_level=1, groupcaps={snappy ={times={[1]=1.5 },    uses=20,  maxlevel=2}}, damage_groups={fleshy=6}}
tooldata["sword_mese"] =           {full_punch_interval=0.7, max_drop_level=2, groupcaps={snappy ={times={[1]=2.0 },    uses=70,  maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_diamond"] =        {full_punch_interval=0.7, max_drop_level=3, groupcaps={snappy ={times={[1]=1.7 },    uses=40,  maxlevel=3}}, damage_groups={fleshy=8}}

tooldata["sword_titanium"] =       {full_punch_interval=1.0, max_drop_level=3, groupcaps={snappy ={times={[1]=2.0 },    uses=200, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_silver"] =         {full_punch_interval=0.7, max_drop_level=3, groupcaps={snappy ={times={[1]=0.9 },    uses=20,  maxlevel=3}}, damage_groups={fleshy=8}}
tooldata["sword_mithril"] =        {full_punch_interval=1.0, max_drop_level=3, groupcaps={snappy ={times={[1]=1.9 },    uses=40,  maxlevel=3}}, damage_groups={fleshy=10}}

tooldata["sword_ruby"] =           {full_punch_interval=0.8, max_drop_level=3, groupcaps={snappy ={times={[1]=1.5 },    uses=135, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_emerald"] =        {full_punch_interval=0.8, max_drop_level=3, groupcaps={snappy ={times={[1]=2.0 },    uses=125, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_sapphire"] =       {full_punch_interval=0.8, max_drop_level=3, groupcaps={snappy ={times={[1]=2.0 },    uses=125, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_amethyst"] =       {full_punch_interval=0.8, max_drop_level=3, groupcaps={snappy ={times={[1]=1.0 },    uses=120, maxlevel=3}}, damage_groups={fleshy=8}}

tooldata["sword_rubystone"] =      {full_punch_interval=1.1, max_drop_level=3, groupcaps={snappy ={times={[1]=1.5 },    uses=165, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_emeraldstone"] =   {full_punch_interval=1.1, max_drop_level=3, groupcaps={snappy ={times={[1]=2.0 },    uses=155, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_sapphirestone"] =  {full_punch_interval=1.1, max_drop_level=3, groupcaps={snappy ={times={[1]=2.0 },    uses=155, maxlevel=3}}, damage_groups={fleshy=7}}
tooldata["sword_amethyststone"] =  {full_punch_interval=1.1, max_drop_level=3, groupcaps={snappy ={times={[1]=1.0 },    uses=150, maxlevel=3}}, damage_groups={fleshy=8}}



for k, v in pairs(tooldata) do
  for t, j in pairs(v.groupcaps) do
    if j.times[1] then
      local time = j.times[1]
      j.times[1] = time         * DIG_TIME_MULTIPLIER
      --j.times[2] = (2*(time/3)) * DIG_TIME_MULTIPLIER
      --j.times[3] = (time/2)     * DIG_TIME_MULTIPLIER
      j.times[2] = (time/2)     * DIG_TIME_MULTIPLIER
      j.times[3] = (time/3)     * DIG_TIME_MULTIPLIER
    elseif j.times[2] then
      local time = j.times[2]
      j.times[2] = time         * DIG_TIME_MULTIPLIER
      --j.times[3] = (2*(time/3)) * DIG_TIME_MULTIPLIER
      j.times[3] = (time/2)     * DIG_TIME_MULTIPLIER
    elseif j.times[3] then
      local time = j.times[3]
      j.times[3] = time * DIG_TIME_MULTIPLIER
    end
  end
end

dofile(modpath .. "/technic.lua")
