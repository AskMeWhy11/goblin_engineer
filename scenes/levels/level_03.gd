extends Node3D
## Level 3: a tower of 12 blocks 25 m ahead.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.slab(self, Vector2(160, 60), Vector3(30, 0, 0))
	LevelKit.road(self, -50, 22)
	var target := Node3D.new()
	target.name = "Target"
	add_child(target)
	for layer in 3:
		for x: float in [24.25, 25.75]:
			for z: float in [-0.75, 0.75]:
				LevelKit.destructible(target, Vector3(1.5, 1.5, 1.5), Vector3(x, 0.75 + layer * 1.5, z),
						15.0, 300.0, LevelKit.STONE.lerp(LevelKit.STONE_DARK, layer * 0.45))
	LevelKit.scatter(self, 33, Rect2(-48, -28, 156, 56), 52, 7.0)
	LevelKit.hills(self, 3, Vector3(30, 0, 0))
