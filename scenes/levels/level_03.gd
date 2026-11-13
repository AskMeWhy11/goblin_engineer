extends Node3D
## Level 3: a tower of 12 blocks 25 m ahead.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.box(self, Vector3(160, 1, 60), Vector3(30, -0.5, 0), LevelKit.GRASS)
	var target := Node3D.new()
	target.name = "Target"
	add_child(target)
	for layer in 3:
		for x: float in [24.25, 25.75]:
			for z: float in [-0.75, 0.75]:
				LevelKit.destructible(target, Vector3(1.5, 1.5, 1.5), Vector3(x, 0.75 + layer * 1.5, z),
						15.0, 300.0, LevelKit.STONE.lerp(LevelKit.DIRT, layer * 0.3))
