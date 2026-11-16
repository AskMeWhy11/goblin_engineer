extends Node3D
## Level 2: a crate drops onto the machine; carry it over a hill to the flag.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.slab(self, Vector2(200, 40), Vector3(60, 0, 0))
	LevelKit.road(self, -40, 16)
	LevelKit.road(self, 44, 160)
	# Hill: a huge log sunk into the ground, 3 m high.
	LevelKit.log_z(self, 25.0, 39.0, Vector3(30, -22, 0), LevelKit.GRASS_DARK)
	LevelKit.flag(self, Vector3(55, 0, 5))
	# The crate starts just above the build volume and lands on whatever is under it.
	LevelKit.crate(self, "Cargo", Vector3(1, 1, 1), Vector3(0, 6.4, 0), 30.0, Color(0.85, 0.7, 0.3))
	LevelKit.scatter(self, 22, Rect2(-38, -18, 196, 36), 46, 6.0, [Rect2(14, -20, 32, 40)])
	LevelKit.hills(self, 2, Vector3(60, 0, 0))
