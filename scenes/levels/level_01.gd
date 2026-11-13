extends Node3D
## Level 1 "Доедь": a straight road with one bump, flag 40 m ahead.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.box(self, Vector3(140, 1, 40), Vector3(40, -0.5, 0), LevelKit.GRASS)
	LevelKit.box(self, Vector3(140, 0.02, 8), Vector3(40, 0.01, 0), LevelKit.DIRT)
	# Bump: a log sunk into the ground, 0.4 m above the surface.
	LevelKit.log_z(self, 2.0, 40.0, Vector3(20, -1.6, 0), LevelKit.STONE)
	LevelKit.flag(self, Vector3(40, 0, 5))
