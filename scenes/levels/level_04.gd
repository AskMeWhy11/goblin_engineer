extends Node3D
## Level 4: an 8 m gap between two pieces of land, with a ramp before it.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.slab(self, Vector2(60, 30), Vector3(-10, 0, 0))
	LevelKit.slab(self, Vector2(70, 30), Vector3(63, 0, 0))
	LevelKit.road(self, -40, 20)
	LevelKit.road(self, 28, 98)
	LevelKit.box(self, Vector3(8, 0.5, 10), Vector3(15.8, 0.55, 0), LevelKit.TRUNK, Vector3(0, 0, 12))
	LevelKit.flag(self, Vector3(45, 0, 5))
	LevelKit.scatter(self, 44, Rect2(-38, -13, 56, 26), 16, 6.0)
	LevelKit.scatter(self, 45, Rect2(30, -13, 66, 26), 20, 6.0)
	LevelKit.hills(self, 4, Vector3(30, 0, 0))
