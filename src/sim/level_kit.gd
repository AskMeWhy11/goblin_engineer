class_name LevelKit
## Helpers for building levels from primitives: a pale, minimal diorama — a slab of land floating
## in fog under a soft sky, with a few trees and rocks kept clear of the road.

const GRASS := Color(0.60, 0.69, 0.48)
const GRASS_DARK := Color(0.52, 0.62, 0.46)
const DIRT := Color(0.76, 0.68, 0.54)
const EARTH := Color(0.55, 0.47, 0.40)
const STONE := Color(0.74, 0.72, 0.68)
const STONE_DARK := Color(0.58, 0.57, 0.55)
const TRUNK := Color(0.50, 0.42, 0.36)
const LEAF := Color(0.47, 0.62, 0.48)
const LEAF_LIGHT := Color(0.60, 0.72, 0.52)
const FLAG := Color(0.82, 0.32, 0.25)
const FOG := Color(0.87, 0.89, 0.87)
const SKY_TOP := Color(0.50, 0.66, 0.80)

## Trees and rocks never stand closer to each other than this.
const DECOR_MIN_GAP := 2.5

static var _materials: Dictionary = {}


## A matte material of a colour; cached so the level shares a handful of materials.
static func material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_materials[color] = m
	return _materials[color]


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


static func box(parent: Node, size: Vector3, pos: Vector3, color: Color, rot_deg := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	_fill_box(body, size, color)
	parent.add_child(body)
	return body


## A piece of land: a thin grass top whose surface is at `top_center.y`, over a slightly
## narrower block of earth, so the edge reads as a cliff dropping into the fog.
static func slab(parent: Node, size: Vector2, top_center: Vector3, color := GRASS) -> void:
	box(parent, Vector3(size.x, 0.6, size.y), top_center + Vector3(0, -0.3, 0), color)
	box(parent, Vector3(size.x - 0.8, 7.0, size.y - 0.8), top_center + Vector3(0, -4.1, 0), EARTH)
	box(parent, Vector3(size.x - 3.0, 3.0, size.y - 3.0), top_center + Vector3(0, -9.1, 0), STONE_DARK)


## A dirt road along X lying on the ground.
static func road(parent: Node, from_x: float, to_x: float, y := 0.0, width := 8.0) -> void:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(absf(to_x - from_x), 0.04, width)
	mesh.mesh = bm
	mesh.material_override = material(DIRT)
	mesh.position = Vector3((from_x + to_x) / 2.0, y + 0.02, 0)
	parent.add_child(mesh)


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
	cm.radial_segments = 48
	mesh.mesh = cm
	mesh.material_override = material(color)
	body.add_child(mesh)
	parent.add_child(body)
	return body


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


## Soft sun, pale gradient sky and fog that swallows the horizon and everything below the land.
static func lighting(parent: Node) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -40, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 140.0
	parent.add_child(sun)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = FOG
	sky_material.sky_curve = 0.2
	sky_material.ground_horizon_color = FOG
	sky_material.ground_bottom_color = FOG
	sky_material.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_material

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.92)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = FOG
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.0
	env.fog_height = -6.0
	env.fog_height_density = 0.35
	var world := WorldEnvironment.new()
	world.environment = env
	parent.add_child(world)


## Positions for decor inside `area` (x, z): deterministic for a seed, never on the road
## (|z| < clear_z), never inside an `exclude` rectangle, never closer than DECOR_MIN_GAP.
## Returns fewer than `count` when they do not fit.
static func decor_positions(seed: int, area: Rect2, count: int, clear_z: float,
		exclude: Array = []) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for _attempt in count * 30:
		if result.size() >= count:
			break
		var p := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if absf(p.y) < clear_z:
			continue
		var blocked := false
		for zone: Rect2 in exclude:
			if zone.has_point(p):
				blocked = true
				break
		if blocked:
			continue
		var spot := Vector3(p.x, 0.0, p.y)
		for other in result:
			if other.distance_to(spot) < DECOR_MIN_GAP:
				blocked = true
				break
		if not blocked:
			result.append(spot)
	return result


## Scatters trees, rocks and bushes (no collision) over `area` at ground height `y`.
static func scatter(parent: Node, seed: int, area: Rect2, count: int, clear_z: float,
		exclude: Array = [], y := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 99
	for spot in decor_positions(seed, area, count, clear_z, exclude):
		var roll := rng.randf()
		var piece: Node3D
		if roll < 0.5:
			piece = _tree(rng)
		elif roll < 0.82:
			piece = _rock(rng)
		else:
			piece = _bush(rng)
		piece.add_to_group(&"decor")
		piece.position = spot + Vector3(0, y, 0)
		piece.rotation.y = rng.randf_range(0.0, TAU)
		parent.add_child(piece)


static func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = pos
	instance.scale = scale
	parent.add_child(instance)
	return instance


static func _cone(radius: float, height: float, sides := 7) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return m


static func _blob(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 7
	m.rings = 4
	return m


## A simple fir: a trunk and three stacked cones.
static func _tree(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s := rng.randf_range(0.8, 1.5)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12 * s
	trunk.bottom_radius = 0.18 * s
	trunk.height = 1.0 * s
	trunk.radial_segments = 6
	_part(root, trunk, TRUNK, Vector3(0, 0.5 * s, 0))
	var leaf := LEAF if rng.randf() < 0.6 else LEAF_LIGHT
	_part(root, _cone(1.0 * s, 1.5 * s), leaf, Vector3(0, 1.5 * s, 0))
	_part(root, _cone(0.78 * s, 1.3 * s), leaf, Vector3(0, 2.3 * s, 0))
	_part(root, _cone(0.52 * s, 1.1 * s), leaf, Vector3(0, 3.0 * s, 0))
	return root


## A faceted boulder, sometimes with a smaller one beside it.
static func _rock(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s := rng.randf_range(0.5, 1.3)
	_part(root, _blob(1.0), STONE, Vector3(0, 0.3 * s, 0), Vector3(s, s * rng.randf_range(0.5, 0.8), s * rng.randf_range(0.7, 1.0)))
	if rng.randf() < 0.5:
		var t := s * 0.5
		_part(root, _blob(1.0), STONE_DARK, Vector3(s * 0.9, 0.15 * t, s * 0.3), Vector3(t, t * 0.6, t))
	return root


static func _bush(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s := rng.randf_range(0.5, 0.9)
	_part(root, _blob(1.0), GRASS_DARK, Vector3(0, 0.35 * s, 0), Vector3(s, s * 0.7, s))
	_part(root, _blob(1.0), LEAF_LIGHT, Vector3(s * 0.6, 0.25 * s, s * 0.2), Vector3(s * 0.6, s * 0.5, s * 0.6))
	return root


## Far, fog-washed hills around `center`: a backdrop with no collision.
static func hills(parent: Node, seed: int, center: Vector3, distance := 130.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 9:
		var angle := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var far := distance * rng.randf_range(0.85, 1.35)
		var hill := Node3D.new()
		hill.add_to_group(&"backdrop")
		var width := rng.randf_range(35.0, 60.0)
		_part(hill, _blob(1.0), GRASS.lerp(FOG, 0.35), Vector3.ZERO,
				Vector3(width, rng.randf_range(20.0, 34.0), width * rng.randf_range(0.7, 1.1)))
		hill.position = center + Vector3(cos(angle) * far, -16.0, sin(angle) * far)
		parent.add_child(hill)


## A flag pole with a red pennant marking a goal.
static func flag(parent: Node, pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.07
	pole.bottom_radius = 0.1
	pole.height = 5.0
	pole.radial_segments = 6
	_part(root, pole, TRUNK, Vector3(0, 2.5, 0))
	var cloth := PrismMesh.new()
	cloth.size = Vector3(1.0, 1.6, 0.06)
	var pennant := _part(root, cloth, FLAG, Vector3(0.85, 4.4, 0))
	pennant.rotation_degrees = Vector3(0, 0, -90)
	_part(root, _blob(1.0), STONE, Vector3(0, 0.1, 0), Vector3(0.5, 0.25, 0.5))
