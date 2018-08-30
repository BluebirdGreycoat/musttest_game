
-- File is reloadable.
fruitscatter = fruitscatter or {}
fruitscatter.modpath = minetest.get_modpath("fruitscatter")



local find_air_under_leaf = function(leaf, x, ybot, ytop, z)
    for y = ybot, ytop, 1 do
        local p1 = {x=x, y=y, z=z}
        local p2 = {x=x, y=y+1, z=z}
        
        local n1 = minetest.get_node(p1).name
        local n2 = minetest.get_node(p2).name
        
        if n1 == "air" and n2 == leaf then
            return p1, p2
        end
    end
end



fruitscatter.scatter_fruit = function(leaf, fruit, minp, maxp, chance)
    minp, maxp = utility.sort_positions(minp, maxp)
    local random = math.random
    for x = minp.x, maxp.x, 1 do
        for z = minp.z, maxp.z, 1 do
            if random(1, chance) == 1 then
                local p1, p2 = find_air_under_leaf(leaf, x, minp.y, maxp.y, z)
                if p1 then
                    minetest.set_node(p1, {name=fruit})
                    minetest.check_for_falling(p1)
                end
            end
        end
    end
end



-- This API is designed to be called by tree mods.
fruitscatter.scatter_fruit_under_leaves = function(pos, leaf, fruit, minp, maxp, chance)
    local sminp = {x=pos.x+minp.x, y=pos.y+minp.y, z=pos.z+minp.z}
    local smaxp = {x=pos.x+maxp.x, y=pos.y+maxp.y, z=pos.z+maxp.z}
    fruitscatter.scatter_fruit(leaf, fruit, sminp, smaxp, chance)
end



if not fruitscatter.run_once then
    -- Reloadable.
    local name = "fruitscatter:core"
    local file = fruitscatter.modpath .. "/init.lua"
    reload.register_file(name, file, false)
    
    fruitscatter.run_once = true
end

