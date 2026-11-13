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
