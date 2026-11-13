extends Node3D
## Level 4: an 8 m gap with a ramp before it.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.box(self, Vector3(60, 1, 30), Vector3(-10, -0.5, 0), LevelKit.GRASS)
	LevelKit.box(self, Vector3(70, 1, 30), Vector3(63, -0.5, 0), LevelKit.GRASS)
	LevelKit.box(self, Vector3(8, 0.5, 10), Vector3(15.8, 0.55, 0), LevelKit.DIRT, Vector3(0, 0, 12))
	LevelKit.flag(self, Vector3(45, 0, 5))
