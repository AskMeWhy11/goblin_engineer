class_name LevelKit
## Helpers for building level geometry from primitives in level scripts.

const GRASS := Color(0.36, 0.5, 0.27)
const DIRT := Color(0.5, 0.4, 0.28)
const STONE := Color(0.5, 0.5, 0.52)
const FLAG := Color(0.95, 0.8, 0.2)


static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, rot_deg := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = material(color)
	body.add_child(mesh)
	parent.add_child(body)
	return body


## A static cylinder lying along the Z axis (a smooth bump or a hill crest).
static func log_z(parent: Node, radius: float, length: float, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(90, 0, 0)
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = length
	shape.shape = cs
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	mesh.mesh = cm
	mesh.material_override = material(color)
	body.add_child(mesh)
	parent.add_child(body)
	return body


static func _fill_box(body: Node3D, size: Vector3, color: Color) -> void:
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = material(color)
	body.add_child(mesh)


## A loose box (cargo).
static func crate(parent: Node, node_name: String, size: Vector3, pos: Vector3, mass: float, color: Color) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = node_name
	body.mass = mass
	body.position = pos
	_fill_box(body, size, color)
	parent.add_child(body)
	return body


## One piece of a destructible target.
static func destructible(parent: Node, size: Vector3, pos: Vector3, mass: float, toughness: float, color: Color) -> Destructible:
	var body := Destructible.new()
	body.mass = mass
	body.toughness = toughness
	body.position = pos
	_fill_box(body, size, color)
	parent.add_child(body)
	return body


## Sun, sky colour and ambient light.
static func lighting(parent: Node) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	parent.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.72, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.9)
	env.ambient_light_energy = 0.6
	var world := WorldEnvironment.new()
	world.environment = env
	parent.add_child(world)


## A flag pole marking a goal position.
static func flag(parent: Node, pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.08
	pm.bottom_radius = 0.08
	pm.height = 5.0
	pole.mesh = pm
	pole.position = pos + Vector3(0, 2.5, 0)
	pole.material_override = material(STONE)
	parent.add_child(pole)
	var cloth := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.9, 0.05)
	cloth.mesh = bm
	cloth.position = pos + Vector3(0.75, 4.4, 0)
	cloth.material_override = material(FLAG)
	parent.add_child(cloth)
