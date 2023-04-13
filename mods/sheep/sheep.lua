
-- Localize for performance.
local math_random = math.random

mobs.register_mob("sheep:sheep", {
    type = "animal",
		description = "Sheep",
    passive = true,
    hp_min = 8,
    hp_max = 10,
    armor = 100,
    collisionbox = {-0.45, -1, -0.45, 0.45, 0.3, 0.45},
    visual = "mesh",
    mesh = "sheep_sheep.b3d",
    textures = {
        {"sheep_sheep_base.png^(sheep_sheep_wool.png^[colorize:#abababc0)"},
    },
    gotten_texture = {"sheep_sheep_shaved.png"},
    gotten_mesh = "sheep_sheep_shaved.b3d",
    makes_footstep_sound = true,
    sounds = {
        random = "sheep_sheep",
				death = "sheep_sheep",
    },
    walk_velocity = 1,
    run_velocity = 2,
    runaway = true,
    jump = true,
    drops = {
        {name = "mobs:meat_raw_mutton", chance = 1, min = 1, max = 1}, -- Killing sheep doesn't yield much meat.
    },
    water_damage = 1*500,
    lava_damage = 100*500,
    light_damage = 0,
    animation = {
        speed_normal = 15,
        speed_run = 15,
        stand_start = 0,
        stand_end = 80,
        walk_start = 81,
        walk_end = 100,
    },
    follow = {"farming:wheat", "default:grass_dummy", "default:coarsegrass"},
    view_range = 8,
    replace_rate = 10,
    replace_what = {
      "default:grass_3", 
      "default:grass_4", 
      "default:grass_5", 
      "farming:wheat_8",
    },
    replace_with = "air",
    replace_offset = -1,
    fear_height = 2,

    on_rightclick = function(self, clicker)
        -- Are we feeding?
        if mobs.feed_tame(self, clicker, 8, true, true) then

            --if full grow fuzz
            if self.gotten == false then

                self.object:set_properties({
                    textures = {"sheep_sheep_base.png^(sheep_sheep_wool.png^[colorize:#abababc0)"},
                    mesh = "sheep_sheep.b3d",
                })
            end

            return
        end

        local item = clicker:get_wielded_item()
        local itemname = item:get_name()

        -- Are we giving a haircut?.
        if itemname == "shears:shears" then
            if self.gotten ~= false or self.child ~= false or not minetest.get_modpath("wool") then
                return
            end

            self.gotten = true -- shaved

            local obj = minetest.add_item(
                self.object:get_pos(),
                ItemStack( "wool:white " .. math_random(1, 3) )
            )

            if obj then
                obj:setvelocity({
                    x = math_random(-1, 1),
                    y = 5,
                    z = math_random(-1, 1)
                })
            end

            item:add_wear(650) -- 100 uses

            clicker:set_wielded_item(item)

            self.object:set_properties({
                textures = {"sheep_sheep_shaved.png"},
                mesh = "sheep_sheep_shaved.b3d",
            })

            return
        end

        -- Are we capturing?
        mobs.capture_mob(self, clicker, 0, 80, 60, false, nil)
    end
})





-- Obtainable by players.
mobs.register_egg("sheep:sheep", "Sheep", "wool_white.png", 1)



-- Compatibility.
mobs.alias_mob("mobs:sheep",                "sheep:sheep")
mobs.alias_mob("mobs_animal:sheep_white",   "sheep:sheep")
