extends SceneTree
## Writes data/parts/<id>.tres and scenes/parts/<id>.tscn from PartTable.
## Run through tools/generate_parts.ps1.


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/parts")
	DirAccess.make_dir_recursive_absolute("res://scenes/parts")
	var failed := false
	for row: Dictionary in PartTable.PARTS:
		var scene_path := "res://scenes/parts/%s.tscn" % row.id
		var err := ResourceSaver.save(_build_scene(row), scene_path)
		if err != OK:
			print("GEN FAIL scene %s: %d" % [row.id, err])
			failed = true
			continue
		var def := _build_def(row, load(scene_path))
		err = ResourceSaver.save(def, "res://data/parts/%s.tres" % row.id)
		if err != OK:
			print("GEN FAIL def %s: %d" % [row.id, err])
			failed = true
	print("GEN done: %d parts" % PartTable.PARTS.size())
	quit(1 if failed else 0)


func _build_def(row: Dictionary, scene: PackedScene) -> PartDef:
	var def := PartDef.new()
	def.id = row.id
	def.display_name = row.name
	def.scene = scene
	def.base_price = row.price
	def.mass = row.mass
	def.activation = row.activation
	def.always_loaded = row.always_loaded
	var keys: Array = row.get("keys", [KEY_NONE, KEY_NONE])
	def.default_key_positive = keys[0]
	def.default_key_negative = keys[1]
	def.attach_faces.assign(row.faces)
	var default_base: Vector3i = row.faces[0] if row.faces.size() == 1 else Vector3i.ZERO
	def.base_face = row.get("base", default_base)
	def.explosion_power = row.boom[0]
	def.explosion_radius = row.boom[1]
	def.removable = row.get("removable", true)
	var tier_rows: Array = PartTable.TIERS
	if row.get("single_tier", false):
		tier_rows = [PartTable.TIERS[0]]
	for t: Dictionary in tier_rows:
		var tier := QualityTier.new()
		tier.display_name = t.name
		tier.price_mult = t.price
		tier.rates = row.rates * t.rate
		tier.strength_margin = t.margin
		def.tiers.append(tier)
	return def


func _build_scene(row: Dictionary) -> PackedScene:
	var body := RigidBody3D.new()
	body.name = String(row.id).to_pascal_case()
	body.mass = row.mass
	var script_path: String = row.get("script", "")
	if script_path.is_empty() or not ResourceLoader.exists(script_path):
		script_path = "res://src/sim/part_body.gd"
	body.set_script(load(script_path))

	var material := StandardMaterial3D.new()
	material.albedo_color = row.color
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var size: Vector3 = row.size
	match row.shape:
		"box":
			var bm := BoxMesh.new()
			bm.size = size
			mesh.mesh = bm
			var bs := BoxShape3D.new()
			bs.size = size
			shape.shape = bs
		"sphere":
			var sm := SphereMesh.new()
			sm.radius = size.x
			sm.height = size.x * 2.0
			mesh.mesh = sm
			var ss := SphereShape3D.new()
			ss.radius = size.x
			shape.shape = ss
		_:
			var cm := CylinderMesh.new()
			cm.top_radius = size.x
			cm.bottom_radius = size.x
			cm.height = size.y
			mesh.mesh = cm
			var cs := CylinderShape3D.new()
			cs.radius = size.x
			cs.height = size.y
			shape.shape = cs
			var rot := Vector3.ZERO
			if row.shape == "cyl_x":
				rot = Vector3(0, 0, deg_to_rad(90))
			elif row.shape == "cyl_z":
				rot = Vector3(deg_to_rad(90), 0, 0)
			mesh.rotation = rot
			shape.rotation = rot
	mesh.material_override = material
	_own(body, mesh)
	_own(body, shape)

	# Mount stub: shows which side attaches (parts with a single mount face).
	for face: Vector3i in row.faces:
		var stub := MeshInstance3D.new()
		stub.name = "Mount"
		var sm := BoxMesh.new()
		sm.size = Vector3(0.3, 0.3, 0.3)
		stub.mesh = sm
		stub.position = Vector3(face) * 0.35
		var grey := StandardMaterial3D.new()
		grey.albedo_color = Color(0.15, 0.15, 0.15)
		stub.material_override = grey
		_own(body, stub)
	# Marker: shows the working direction (+Z) of rockets and cannons.
	if row.has("marker"):
		var tip := MeshInstance3D.new()
		tip.name = "Tip"
		var tm := BoxMesh.new()
		tm.size = Vector3(0.25, 0.25, 0.12)
		tip.mesh = tm
		tip.position = row.marker
		var white := StandardMaterial3D.new()
		white.albedo_color = Color(0.95, 0.95, 0.9)
		tip.material_override = white
		_own(body, tip)

	var packed := PackedScene.new()
	packed.pack(body)
	body.free()
	return packed


func _own(root: Node, child: Node) -> void:
	root.add_child(child)
	child.owner = root
