extends Node3D
## Level 1 "Доедь": a straight road with one bump, flag 40 m ahead.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.slab(self, Vector2(140, 40), Vector3(40, 0, 0))
	LevelKit.road(self, -30, 110)
	# Bump: a log sunk into the ground, 0.4 m above the surface.
	LevelKit.log_z(self, 2.0, 39.0, Vector3(20, -1.6, 0), LevelKit.STONE)
	LevelKit.flag(self, Vector3(40, 0, 5))
	LevelKit.scatter(self, 11, Rect2(-28, -18, 136, 36), 38, 6.0, [Rect2(17, -20, 6, 40)])
	LevelKit.hills(self, 1, Vector3(40, 0, 0))
