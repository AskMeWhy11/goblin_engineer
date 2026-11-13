extends Node3D
## Level 2: a crate drops onto the machine; carry it over a hill to the flag.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.box(self, Vector3(200, 1, 40), Vector3(60, -0.5, 0), LevelKit.GRASS)
	LevelKit.box(self, Vector3(200, 0.02, 8), Vector3(60, 0.01, 0), LevelKit.DIRT)
	# Hill: a huge log sunk into the ground, 3 m high.
	LevelKit.log_z(self, 25.0, 40.0, Vector3(30, -22, 0), LevelKit.GRASS)
	LevelKit.flag(self, Vector3(55, 0, 5))
	# The crate starts just above the build volume and lands on whatever is under it.
	LevelKit.crate(self, "Cargo", Vector3(1, 1, 1), Vector3(0, 6.4, 0), 30.0, Color(0.85, 0.7, 0.3))
