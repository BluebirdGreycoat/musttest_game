--"Cobble bomb" mod. Lets get started

--Some code from tnt mod
--[[
local function calc_velocity(pos1, pos2, old_vel, power)
	local vel = vector.direction(pos1, pos2)
	vel = vector.normalize(vel)
	vel = vector.multiply(vel, power)

	-- Divide by distance
	local dist = vector.distance(pos1, pos2)
	dist = math.max(dist, 1)
	vel = vector.divide(vel, dist)

	-- Add old velocity
	vel = vector.add(vel, old_vel)
	return vel
end

local function entity_physics(pos, radius)
	-- Make the damage radius larger than the destruction radius
	radius = radius * 2
	local objs = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in pairs(objs) do
		local obj_pos = obj:getpos()
		local obj_vel = obj:getvelocity()
		local dist = math.max(1, vector.distance(pos, obj_pos))

		if obj_vel ~= nil then
			obj:setvelocity(calc_velocity(pos, obj_pos,
					obj_vel, radius * 10))
		end

		local damage = (4 / dist) * radius
		obj:set_hp(obj:get_hp() - damage)
	end
end

local function add_effects(pos, radius)
	minetest.add_particlespawner({
		amount = 128,
		time = 1,
		minpos = vector.subtract(pos, radius / 2),
		maxpos = vector.add(pos, radius / 2),
		minvel = {x=-20, y=-20, z=-20},
		maxvel = {x=20,  y=20,  z=20},
		minacc = vector.new(),
		maxacc = vector.new(),
		minexptime = 1,
		maxexptime = 3,
		minsize = 8,
		maxsize = 16,
		texture = "tnt_smoke.png",
	})
end
--]]
--End of Some code from tnt mod

minetest.register_entity("cobble_bomb:cobblebomb", {
    full_name = "Cobble Bomb",
    hp_max = 40,
    physical = true,
    collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
    visual = "mesh",
    visual_size = {x=3, y=3},
    mesh = "sphere.x",
    textures = {"cobble_texture.png"},
    bomb_inertion = 10,
    bomb_timer = nil,
    bomb_punched =nil,

    on_step = function(self, dtime)
        -- Explode when timer runs out.
        if self.bomb_timer == nil then
            self.bomb_timer = dtime;
        elseif self.bomb_timer > 4 then
            self:bomb_explode();
            return;
        else
            self.bomb_timer = self.bomb_timer + dtime;
        end
        --falling give more inertion. may explode if fall to hard.
        local vel = self.object:getvelocity();
        if self.bomb_inertion < 20 and vel.y < -0.1 and vel.y > -3 then
            self.bomb_inertion = self.bomb_inertion + 1;
	elseif vel.y <= -10 and self.bomb_inertion > 3 then
	    --warn players bellow
            local pos = self.object:getpos();
            pos.y = pos.y - 10;
            minetest.sound_play("rolling_test", {pos=pos, gain=1.0, max_hear_distance=20});
            self.bomb_inertion = 0;
        end
        --bounce around, inertion slowly fades
        if vector.length(vel)<0.1 then
            if self.bomb_inertion < 1 then
                self:bomb_explode();
                return;
            else
                --self.object:setacceleration({x=math.random(-1, 1)*self.bomb_inertion*10, y=-10, z=math.random(-1, 1)*self.bomb_inertion*10});
                --self.bomb_inertion = self.bomb_inertion - 1;
            end
        elseif self.bomb_punched ~= nil then
            self.object:setacceleration( self.bomb_punched );
            self.bomb_punched = nil;
        elseif self.object:getacceleration() ~= {x=0, y=-10, z=0} then
            self.object:setacceleration({x=0, y=-10, z=0});
        end
    end,

    on_activate = function(self, staticdata, dtime_s)
        self.object:setvelocity({x=0, y=0, z=0});
        self.object:setacceleration({x=0, y=-5, z=0});
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if time_from_last_punch > 1 then
            self.bomb_punched = {x=dir.x*100, y=-10, z=dir.z*100};
        end
    end,

    bomb_explode = function(self)
		local pos = self.object:getpos();
		local def = {
			radius = 2,
			damage_radius = 10,
			ignore_protection = false,
			disable_drops = false,
			ignore_on_blast = false,
		}
		tnt.boom(pos, def)
		self.object:remove();
		
		-- Disable lag's griefer-friendly code.
		--[[
		pos = vector.round(pos);

		minetest.sound_play("tnt_explode", {pos=pos, gain=1.5, max_hear_distance=30});
		entity_physics(pos, 4);
		add_effects(pos, 2);

		--destroys only stone and cobble nodes. Check protection only once.
		if not minetest.test_protection(pos, "") then
			local stonenodes = minetest.find_nodes_in_area(vector.subtract(pos, 2), vector.add(pos, 2), {"default:stone"});
			for _, p in ipairs(stonenodes) do
				if math.random(1, 100) > 10 then
					minetest.remove_node(p);
				end
			end
		end
		self.object:remove();
		--]]
    end
});

minetest.register_craftitem("cobble_bomb:cobblebomb", {
	description = "Cobble Molotov\n\nThis device is dedicated to Lag, the creator of the original Just Test.\nExcellent for anyone who wants to explode mobs and others.",
	inventory_image = "cobble_bomb.png",
 
	on_use = function(itemstack, user, pointed_thing)
		local pos = user:getpos();
        local dir = user:get_look_dir();
        --if minetest.get_node( vector.add( vector.add(pos, dir), {x=0, y=1, z=0}) ).name == "air" then
        --    pos = vector.add( vector.add(pos, dir), {x=0, y=1, z=0});
        --else
        --    return;
        --end
		pos = vector.add( vector.add(pos, dir), {x=0, y=1, z=0})
        minetest.sound_play("rolling_test", {pos=pos, gain=1.5, max_hear_distance=20});
        local tmp_bomb = minetest.add_entity(pos, "cobble_bomb:cobblebomb");
        tmp_bomb:setvelocity( vector.add(vector.multiply(dir, 5), {x=0,y=2.5,z=0}) );
        itemstack:take_item();
        return itemstack;
	end,
})

minetest.register_craft({
	output = "cobble_bomb:cobblebomb 2",
	recipe = {
		{"default:clay_lump", "default:cobble", "default:clay_lump"},
		{"default:cobble", "tnt:gunpowder", "default:cobble"},
		{"default:clay_lump", "default:cobble", "default:clay_lump"},
	}
})

--if minetest.setting_get("log_mods") then
--	minetest.log("action", "cobblebomb loaded");
--end
