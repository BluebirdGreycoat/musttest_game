
oregen = oregen or {}
oregen.modpath = minetest.get_modpath("oregen")

-- Localize for performance.
local math_floor = math.floor



-- Settings. These affect all ores registered through this mod.
oregen.scarcity_multiplier = 1.0
oregen.scarcity_blob_multiplier = 4.0
oregen.count_multiplier = 1.0
oregen.size_multiplier = 1.0
oregen.depth_offset = -20
oregen.noise_threshold_offset = 0.2





local noise_params = {
    offset =    0.0,
    scale =     1.0,
    spread =    {x=256, y=256, z=256},
    seed =      0, -- Note: the code changes this at will.
    octaves =   1,
    persist =   0.0,
}



-- Defaults, so that registrations can omit values they don't care about.
local default = {
    algorithm =             "scatter",
    ore =                   "air",
    wherein =               "default:stone",
    scarcity =              20*20*20,
    count =                 3,
    diameter =              2,
    miny =                  -32000,
    maxy =                  32000,
    noise_threshold =       0.0,
    noise_params =          noise_params,
    random_factor =         1.0,
}



local get_hash = function(name)
    local num = 0
    local cnt = string.len(name)
    if cnt > 64 then cnt = 64 end
    for i = 1, cnt, 1 do
        num = num + string.byte(name, i)
    end
    return num
end



-- Public API function.
oregen.register_ore = function(oredef)
    -- Name compatibility.
    if oredef.ore_type ~= nil then oredef.algorithm = oredef.ore_type end
    if oredef.clust_scarcity ~= nil then oredef.scarcity = oredef.clust_scarcity end
    if oredef.clust_num_ores ~= nil then oredef.count = oredef.clust_num_ores end
    if oredef.clust_size ~= nil then oredef.diameter = oredef.clust_size end
    if oredef.y_min ~= nil then oredef.miny = oredef.y_min end
    if oredef.y_max ~= nil then oredef.maxy = oredef.y_max end

    -- Get params or defaults.
    local algorithm = oredef.algorithm                  or default.algorithm
    local ore = oredef.ore                              or default.ore
    local wherein = oredef.wherein                      or default.wherein
    local scarcity = oredef.scarcity                    or default.scarcity
    local count = oredef.count                          or default.count
    local diameter = oredef.diameter                    or default.diameter
    local miny = oredef.miny                            or default.miny
    local maxy = oredef.maxy                            or default.maxy
    local random_factor = oredef.random_factor          or default.random_factor
    
    -- Note: this triggers orefull/oreless regions for all scatter type ores!
    local noise_threshold = oredef.noise_threshold      or default.noise_threshold
    local noise_params = oredef.noise_params            or default.noise_params
    
    count = math_floor(count * oregen.count_multiplier + 0.5)
    if count <= 1 then count = 1 end
    
    if algorithm == "blob" then
        scarcity = math_floor(scarcity * oregen.scarcity_blob_multiplier + 0.5)
        if scarcity <= 1 then scarcity = 1 end
    else
        scarcity = math_floor(scarcity * oregen.scarcity_multiplier + 0.5)
        if scarcity <= 1 then scarcity = 1 end
    end
    
    if algorithm == "standard_blob" then
        algorithm = "blob"
    end
    
    diameter = math_floor(diameter * oregen.size_multiplier + 0.5)
    if diameter <= 1 then diameter = 1 end
    
    miny = miny + oregen.depth_offset
    maxy = maxy + oregen.depth_offset
    noise_threshold = noise_threshold + oregen.noise_threshold_offset
    
    local seed = get_hash(ore)
    --print("OREGEN: '" .. ore .. "' == " .. seed .. "!")
    noise_params.seed = seed
    
    assert(maxy > miny)
    
    local tbr = {
        ore_type            = algorithm,
        ore                 = ore,
        wherein             = wherein,
        clust_scarcity      = scarcity,
        clust_num_ores      = count,
        clust_size          = diameter,
        y_min               = miny,
        y_max               = maxy,
        noise_threshold     = noise_threshold,
        noise_params        = noise_params,
        random_factor       = random_factor,
    }

		--minetest.log(dump(tbr))
    minetest.register_ore(tbr)
end

