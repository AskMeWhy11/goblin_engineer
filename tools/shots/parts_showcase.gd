extends Node3D
## Every part in every quality tier, in rows, for a look-over screenshot.


func _ready() -> void:
	LevelKit.lighting(self)
	LevelKit.box(self, Vector3(60, 1, 40), Vector3(0, -1.2, 0), LevelKit.GRASS)
	var ids: Array = PartCatalog.defs.keys()
	ids.sort()
	for column in ids.size():
		var def: PartDef = PartCatalog.defs[ids[column]]
		for tier in def.tiers.size():
			var part: RigidBody3D = def.scene.instantiate()
			part.set_script(null)
			part.freeze = true
			add_child(part)
			part.position = Vector3((column - (ids.size() - 1) / 2.0) * 1.7, 0, tier * 2.2)
			part.rotation_degrees = Vector3(0, 35, 0)
			PartVisuals.apply_tier(part, tier)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 7.5, 12.5)
	camera.look_at(Vector3(0, 0, 2.0))
	camera.fov = 50
