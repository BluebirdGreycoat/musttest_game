
if not minetest.global_exists("lagwing") then lagwing = {} end
lagwing.modpath = minetest.get_modpath("lagwing")

lagwing.GRAVITY = -9
lagwing.MAX_AIRSPEED = 16
lagwing.MIN_AIRSPEED = 5
lagwing.MAX_ACCEL = 7
lagwing.MAX_CLIMB_ACCEL = 4
lagwing.MAX_ALTITUDE = 100
lagwing.MIN_ALTITUDE = 8
lagwing.DIVE_ABORT_ALTITUDE = 50
lagwing.MAX_DIVE_ANGLE = math.rad(-70)
lagwing.MAX_CLIMB_ANGLE = math.rad(30)
lagwing.MAX_DESCENT_RATE = -4
lagwing.MAX_DIVE_RATE = -10
lagwing.MIN_STEERRAY_ANGLE = -0.8
lagwing.MAX_STEERRAY_ANGLE = 0.0
lagwing.OBSTACLE_SLOW_DISTANCE = 20
lagwing.OBSTACLE_AVOID_DISTANCE = 8
lagwing.MAX_TURN_RATE = math.rad(25)
lagwing.SLOW_TURN_RATE = math.rad(10)
lagwing.MAX_ROLL_ANGLE = math.rad(35)
lagwing.MAX_ROLL_RATE = math.rad(15)
lagwing.MAX_PITCH_RATE = math.rad(35)
lagwing.SHOW_RAYCASTS = true

dofile(lagwing.modpath .. "/ride.lua")
dofile(lagwing.modpath .. "/func.lua")
dofile(lagwing.modpath .. "/flightmodel.lua")
dofile(lagwing.modpath .. "/controls.lua")

if not lagwing.registered then
	dofile(lagwing.modpath .. "/entity.lua")

	local c = "lagwing:core"
	local f = lagwing.modpath .. "/init.lua"
	reload.register_file(c, f, false)

	lagwing.registered = true
end
