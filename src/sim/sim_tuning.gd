class_name SimTuning
## Physics and damage constants. Balance numbers for the simulation live here.
##
## Joint spike results (plan task 2, spikes/joint_stress, Godot 4.7.2 + Jolt, headless):
##   84 bodies (80 blocks 5 kg + 4 wheels 12 kg), 176 joints, 60 ticks/s, default solver steps,
##   Generic6DOFJoint3D with all axes locked, no diagonal joints:
##     max neighbour gap 0.021 m (limit 0.10), median physics step ~2.7 ms (limit 8),
##     distance in 20 s: 104 m (limit 30), crossed a 0.3 m bump intact.
##   120 ticks/s: gap 0.0125 m — not needed.
##   Known: the once-per-second engine monitor reported isolated ~100 ms frames around the bump
##   crossing; not reproduced as a sustained slowdown. Watch for hitches in real play.

const PHYSICS_TICKS := 60
## Rigid connection between neighbouring parts: Generic6DOFJoint3D with default (locked) limits.
const JOINT_KIND := &"generic_6dof_locked"

## Multiplier that turns "positive angular speed around the hinge axis" into the engine's
## hinge-motor sign. Verified by tests/test_part_behaviours.gd (cart drives forward, steering
## returns to centre).
const HINGE_MOTOR_SIGN := -1.0

## Shake: sudden velocity change of a part, as acceleration in m/s^2.
## shake = clamp((a - SHAKE_FREE) / SHAKE_REF, 0, SHAKE_MAX) is added to the part's load.
## A velocity jump of 1.5 m/s in one tick (90 m/s^2) is free; 4 m/s adds one unit of load.
const SHAKE_FREE := 90.0
const SHAKE_REF := 150.0
const SHAKE_MAX := 20.0
## Seconds after launch during which shake is ignored (the machine settles on its wheels).
const SHAKE_GRACE := 1.0

## Pilot damage per unit of blast impulse that reaches the cabin.
const PILOT_BLAST_DAMAGE := 0.06
## Cabin velocity change within one tick (m/s) that does no harm, and damage per m/s above it.
const PILOT_IMPACT_FREE := 4.0
const PILOT_IMPACT_DAMAGE := 10.0
## Anything below this height has fallen out of the world.
const KILL_Y := -30.0
## Parts closer to a blast than this share of its radius are torn off.
const BLAST_TEAR_FRACTION := 0.35
## Fuse of barrels and whistles caught in someone else's blast, seconds.
const CHAIN_FUSE := 0.15

const MOTOR_SPEED := 12.0          # rad/s at full input
const MOTOR_MAX_IMPULSE := 40.0
const WHEEL_BRAKE_IMPULSE := 40.0
const STEER_LIMIT := 0.6109        # 35 degrees
const STEER_GAIN := 8.0            # 1/s, how hard the hinge chases its target angle
const STEER_SPEED := 3.0           # rad/s
const STEER_MAX_IMPULSE := 30.0
const ROCKET_THRUST := 600.0       # N
const CANNON_RELOAD := 2.0         # s
const CANNONBALL_MASS := 5.0       # kg
const CANNONBALL_SPEED := 40.0     # m/s
const LOOSE_JOINT_PLAY := 0.26     # rad, about 15 degrees


static func make_rigid_joint() -> Joint3D:
	return Generic6DOFJoint3D.new()
