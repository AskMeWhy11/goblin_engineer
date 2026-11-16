class_name PartModels
## Builds the look of every part from primitives: a toon-shaded, outlined body with small details
## (rivets, bands, pipes) and one "wear kit" per quality tier (brackets, patches, rope).
## Used only by tools/generate_parts.gd; the results are baked into scenes/parts/*.scn.

const OUTLINE_WIDTH := 0.022

const WOOD := Color(0.66, 0.47, 0.27)
const WOOD_DARK := Color(0.40, 0.27, 0.15)
const WOOD_LIGHT := Color(0.80, 0.62, 0.38)
const IRON := Color(0.46, 0.50, 0.54)
const IRON_DARK := Color(0.22, 0.22, 0.25)
const BRASS := Color(0.82, 0.66, 0.22)
const RED := Color(0.80, 0.30, 0.22)
const RED_DARK := Color(0.52, 0.17, 0.12)
const CREAM := Color(0.93, 0.87, 0.72)
const ROPE := Color(0.76, 0.63, 0.38)
const NAIL := Color(0.14, 0.10, 0.08)
const TYRE := Color(0.20, 0.15, 0.12)
const TREAD := Color(0.11, 0.08, 0.07)
const ORANGE := Color(0.88, 0.52, 0.16)
const BLUE := Color(0.25, 0.50, 0.80)
const PURPLE := Color(0.54, 0.37, 0.69)
const GREEN := Color(0.42, 0.70, 0.30)
const LEATHER := Color(0.45, 0.30, 0.20)
const BARREL := Color(0.62, 0.27, 0.18)
const SPARK := Color(0.96, 0.66, 0.14)

const ALONG_X := Vector3(0, 0, -90)
const ALONG_Z := Vector3(90, 0, 0)

static var _materials: Dictionary = {}
static var _outline: StandardMaterial3D


## Toon material of a colour with the shared outline pass. Cached, so parts share materials.
static func material(color: Color) -> StandardMaterial3D:
	if _materials.has(color):
		return _materials[color]
	if _outline == null:
		_outline = StandardMaterial3D.new()
		_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline.albedo_color = Color(0.12, 0.07, 0.04)
		_outline.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline.grow = true
		_outline.grow_amount = OUTLINE_WIDTH
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0
	m.next_pass = _outline
	_materials[color] = m
	return m


## A list of coloured primitives that merges into one mesh (one surface per colour).
class Kit:
	extends RefCounted

	var items: Array = []  # [Mesh, Transform3D, Color]

	func _add(mesh: Mesh, pos: Vector3, color: Color, rot_deg: Vector3) -> Kit:
		var basis := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
		items.append([mesh, Transform3D(basis, pos), color])
		return self

	func box(size: Vector3, pos: Vector3, color: Color, rot_deg := Vector3.ZERO) -> Kit:
		var m := BoxMesh.new()
		m.size = size
		return _add(m, pos, color, rot_deg)

	## A cylinder along local Y; `top_radius` >= 0 makes a cone or a flare.
	func cyl(radius: float, height: float, pos: Vector3, color: Color, rot_deg := Vector3.ZERO, top_radius := -1.0) -> Kit:
		var m := CylinderMesh.new()
		m.bottom_radius = radius
		m.top_radius = radius if top_radius < 0.0 else top_radius
		m.height = height
		m.radial_segments = 14
		m.rings = 1
		return _add(m, pos, color, rot_deg)

	func ball(radius: float, pos: Vector3, color: Color) -> Kit:
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		# Rivets and nail heads are tiny: a handful of triangles is enough.
		var small := radius < 0.06
		m.radial_segments = 6 if small else 12
		m.rings = 3 if small else 6
		return _add(m, pos, color, Vector3.ZERO)

	## A torus around local Y.
	func ring(radius: float, thickness: float, pos: Vector3, color: Color, rot_deg := Vector3.ZERO) -> Kit:
		var m := TorusMesh.new()
		m.inner_radius = radius - thickness
		m.outer_radius = radius + thickness
		m.rings = 16
		m.ring_segments = 6
		return _add(m, pos, color, rot_deg)

	## Rotates everything added so far (used to lay an upright kit along another axis).
	func turned(rot_deg: Vector3) -> Kit:
		var basis := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
		for item in items:
			item[1] = Transform3D(basis, Vector3.ZERO) * item[1]
		return self

	func mesh() -> ArrayMesh:
		var out := ArrayMesh.new()
		var by_color := {}
		var order: Array[Color] = []
		for item in items:
			if not by_color.has(item[2]):
				by_color[item[2]] = SurfaceTool.new()
				order.append(item[2])
			by_color[item[2]].append_from(item[0], 0, item[1])
		for color in order:
			by_color[color].commit(out)
			out.surface_set_material(out.get_surface_count() - 1, PartModels.material(color))
		return out


static func body(id: StringName) -> Kit:
	var k := Kit.new()
	match id:
		&"core":
			k.box(Vector3(0.92, 0.5, 0.92), Vector3(0, -0.23, 0), WOOD)
			k.box(Vector3(0.96, 0.08, 0.96), Vector3(0, 0.03, 0), WOOD_DARK)
			k.box(Vector3(0.5, 0.4, 0.08), Vector3(-0.2, 0.25, 0), WOOD_LIGHT, Vector3(0, 90, 0))
			k.box(Vector3(0.28, 0.24, 0.3), Vector3(0, 0.17, 0), LEATHER)
			k.ball(0.2, Vector3(0.02, 0.4, 0), GREEN)
			k.cyl(0.06, 0.24, Vector3(0, 0.42, 0.26), GREEN, Vector3(90, 0, 0), 0.0)
			k.cyl(0.06, 0.24, Vector3(0, 0.42, -0.26), GREEN, Vector3(-90, 0, 0), 0.0)
			k.cyl(0.07, 0.06, Vector3(0.19, 0.43, 0.08), CREAM, ALONG_X)
			k.cyl(0.07, 0.06, Vector3(0.19, 0.43, -0.08), CREAM, ALONG_X)
			k.box(Vector3(0.05, 0.05, 0.36), Vector3(0.14, 0.43, 0), LEATHER)
			k.cyl(0.025, 0.34, Vector3(0.3, 0.2, 0.22), IRON, Vector3(0, 0, -20))
			k.ball(0.055, Vector3(0.36, 0.36, 0.22), RED)
			for sx: float in [-0.44, 0.44]:
				for sz: float in [-0.44, 0.44]:
					k.ball(0.035, Vector3(sx, 0.08, sz), NAIL)
		&"block":
			k.box(Vector3(0.96, 0.96, 0.96), Vector3.ZERO, WOOD)
			for offset: float in [-0.16, 0.16]:
				for side: float in [-0.482, 0.482]:
					k.box(Vector3(0.012, 0.96, 0.035), Vector3(side, 0, offset), WOOD_DARK)
					k.box(Vector3(0.035, 0.96, 0.012), Vector3(offset, 0, side), WOOD_DARK)
					k.box(Vector3(0.035, 0.012, 0.96), Vector3(offset, side, 0), WOOD_DARK)
			for side: float in [-0.485, 0.485]:
				for u: float in [-0.36, 0.36]:
					for v: float in [-0.36, 0.36]:
						k.ball(0.03, Vector3(side, u, v), NAIL)
						k.ball(0.03, Vector3(u, v, side), NAIL)
		&"ballast":
			k.box(Vector3(0.9, 0.9, 0.9), Vector3.ZERO, IRON_DARK)
			k.box(Vector3(0.96, 0.14, 0.96), Vector3(0, 0.26, 0), IRON)
			k.box(Vector3(0.96, 0.14, 0.96), Vector3(0, -0.26, 0), IRON)
			k.ring(0.14, 0.035, Vector3(0, 0.52, 0), IRON, Vector3(90, 0, 0))
			for y: float in [-0.26, 0.26]:
				for u: float in [-0.3, 0.0, 0.3]:
					for side: float in [-0.485, 0.485]:
						k.ball(0.035, Vector3(side, y, u), NAIL)
						k.ball(0.035, Vector3(u, y, side), NAIL)
		&"free_wheel":
			_wheel(k, WOOD_LIGHT, IRON)
		&"motor_wheel":
			_wheel(k, ORANGE, BRASS)
			k.cyl(0.27, 0.5, Vector3.ZERO, IRON, ALONG_X)
			for i in 6:
				var a := TAU * i / 6.0
				k.ball(0.04, Vector3(0.25, cos(a) * 0.2, sin(a) * 0.2), NAIL)
			k.cyl(0.045, 0.16, Vector3(0.31, 0.0, 0.0), BRASS, ALONG_X)
		&"steering_hinge":
			k.box(Vector3(0.5, 0.7, 0.5), Vector3.ZERO, BLUE)
			k.cyl(0.4, 0.1, Vector3(-0.43, 0, 0), IRON, ALONG_X)
			k.cyl(0.12, 0.96, Vector3.ZERO, BRASS)
			k.cyl(0.2, 0.08, Vector3(0, 0.44, 0), IRON)
			k.cyl(0.2, 0.08, Vector3(0, -0.44, 0), IRON)
			k.box(Vector3(0.52, 0.08, 0.52), Vector3(0, 0.18, 0), IRON_DARK)
			for u: float in [-0.26, 0.26]:
				for v: float in [-0.26, 0.26]:
					k.ball(0.04, Vector3(-0.37, u, v), NAIL)
		&"rocket":
			k.cyl(0.3, 0.6, Vector3.ZERO, RED, ALONG_Z)
			k.cyl(0.3, 0.32, Vector3(0, 0, 0.46), CREAM, ALONG_Z, 0.0)
			k.cyl(0.26, 0.2, Vector3(0, 0, -0.4), IRON_DARK, ALONG_Z, 0.16)
			k.cyl(0.32, 0.07, Vector3(0, 0, 0.18), IRON, ALONG_Z)
			k.cyl(0.32, 0.07, Vector3(0, 0, -0.18), IRON, ALONG_Z)
			for angle: float in [90.0, 210.0, 330.0]:
				var a := deg_to_rad(angle)
				k.box(Vector3(0.03, 0.3, 0.3), Vector3(cos(a) * 0.38, sin(a) * 0.38, -0.3), RED_DARK, Vector3(0, 0, angle - 90.0))
			k.cyl(0.1, 0.05, Vector3(0, 0.31, 0.02), CREAM)
			k.box(Vector3(0.02, 0.02, 0.1), Vector3(0.02, 0.345, 0.02), RED, Vector3(0, 35, 0))
			k.box(Vector3(0.3, 0.3, 0.3), Vector3(-0.34, 0, 0), IRON)
			k.ring(0.315, 0.02, Vector3(0, 0, 0.02), ROPE, Vector3(90, 0, 8))
			for z: float in [-0.18, 0.18]:
				for i in 6:
					var a := TAU * i / 6.0
					k.ball(0.028, Vector3(cos(a) * 0.33, sin(a) * 0.33, z), NAIL)
		&"cannon":
			k.cyl(0.22, 0.9, Vector3.ZERO, IRON_DARK, ALONG_Z)
			k.cyl(0.27, 0.1, Vector3(0, 0, 0.42), IRON, ALONG_Z)
			k.ball(0.26, Vector3(0, 0, -0.42), IRON_DARK)
			k.cyl(0.245, 0.06, Vector3(0, 0, 0.12), BRASS, ALONG_Z)
			k.cyl(0.245, 0.06, Vector3(0, 0, -0.14), BRASS, ALONG_Z)
			k.box(Vector3(0.42, 0.2, 0.62), Vector3(0, -0.32, 0), WOOD)
			k.box(Vector3(0.3, 0.3, 0.3), Vector3(-0.34, 0, 0), IRON)
			k.cyl(0.018, 0.16, Vector3(0, 0.27, -0.36), ROPE, Vector3(-25, 0, 0))
			k.ball(0.04, Vector3(0, 0.35, -0.4), SPARK)
			for sx: float in [-0.215, 0.215]:
				for sz: float in [-0.22, 0.22]:
					k.ball(0.03, Vector3(sx, -0.32, sz), NAIL)
		&"powder_barrel":
			k.cyl(0.42, 0.9, Vector3.ZERO, BARREL)
			k.cyl(0.45, 0.42, Vector3.ZERO, BARREL)
			k.cyl(0.455, 0.07, Vector3(0, 0.28, 0), IRON)
			k.cyl(0.455, 0.07, Vector3(0, -0.28, 0), IRON)
			k.cyl(0.1, 0.08, Vector3(0, 0.48, 0), ROPE)
			k.cyl(0.018, 0.22, Vector3(0.07, 0.57, 0), ROPE, Vector3(0, 0, -30))
			k.ball(0.045, Vector3(0.13, 0.66, 0), SPARK)
			k.box(Vector3(0.36, 0.07, 0.02), Vector3(0, 0, 0.455), CREAM, Vector3(0, 0, 45))
			k.box(Vector3(0.36, 0.07, 0.02), Vector3(0, 0, 0.455), CREAM, Vector3(0, 0, -45))
			for i in 8:
				var a := TAU * i / 8.0 + 0.4
				k.box(Vector3(0.02, 0.9, 0.02), Vector3(cos(a) * 0.425, 0, sin(a) * 0.425), WOOD_DARK)
				k.ball(0.028, Vector3(cos(a) * 0.46, 0.28, sin(a) * 0.46), NAIL)
				k.ball(0.028, Vector3(cos(a) * 0.46, -0.28, sin(a) * 0.46), NAIL)
		&"whistle":
			k.ball(0.44, Vector3.ZERO, PURPLE)
			k.cyl(0.1, 0.22, Vector3(0, 0.46, 0), BRASS)
			k.cyl(0.15, 0.05, Vector3(0, 0.58, 0), BRASS)
			k.cyl(0.06, 0.28, Vector3(0.42, 0.14, 0), IRON, ALONG_X)
			k.cyl(0.13, 0.05, Vector3(0, 0.02, 0.44), CREAM, ALONG_Z)
			k.box(Vector3(0.025, 0.11, 0.02), Vector3(0.025, 0.05, 0.47), RED, Vector3(0, 0, -40))
			k.ring(0.1, 0.022, Vector3(0, 0, -0.5), RED, Vector3(90, 0, 0))
			k.cyl(0.03, 0.1, Vector3(0, 0, -0.46), IRON, ALONG_Z)
			k.ring(0.445, 0.028, Vector3.ZERO, IRON)
			for i in 8:
				var a := TAU * i / 8.0
				k.ball(0.034, Vector3(cos(a) * 0.475, 0, sin(a) * 0.475), NAIL)
	return k


## A wheel whose axle is local X; the mount side is -X.
static func _wheel(k: Kit, rim: Color, hub: Color) -> void:
	k.cyl(0.65, 0.3, Vector3.ZERO, TYRE, ALONG_X)
	k.cyl(0.5, 0.34, Vector3.ZERO, rim, ALONG_X)
	k.cyl(0.16, 0.42, Vector3.ZERO, hub, ALONG_X)
	k.cyl(0.08, 0.3, Vector3(-0.3, 0, 0), IRON, ALONG_X)
	for i in 4:
		k.box(Vector3(0.02, 0.92, 0.08), Vector3(0.175, 0, 0), WOOD_DARK, Vector3(i * 45.0, 0, 0))
	for i in 10:
		var a := TAU * i / 10.0
		k.box(Vector3(0.3, 0.1, 0.16), Vector3(0, cos(a) * 0.66, sin(a) * 0.66), TREAD, Vector3(rad_to_deg(a), 0, 0))


## The wear kit of a quality tier: tidy brackets for good parts, patches and rope for junk.
## `shape` and `size` come from the part table (box / sphere / cyl_x / cyl_y / cyl_z).
static func wear(shape: String, size: Vector3, tier: int) -> Kit:
	var k := Kit.new()
	if shape == "box":
		if tier == 0:
			for sx: float in [-0.38, 0.38]:
				for sz: float in [-0.38, 0.38]:
					k.box(Vector3(0.22, 0.06, 0.22), Vector3(sx, 0.475, sz), IRON)
		elif tier == 1:
			k.box(Vector3(0.22, 0.06, 0.22), Vector3(-0.38, 0.475, -0.38), IRON)
			k.box(Vector3(0.5, 0.16, 0.035), Vector3(0.1, -0.1, 0.495), WOOD_LIGHT, Vector3(0, 0, 12))
			k.ball(0.03, Vector3(-0.1, -0.14, 0.52), NAIL)
			k.ball(0.03, Vector3(0.3, -0.06, 0.52), NAIL)
		else:
			k.box(Vector3(0.56, 0.18, 0.035), Vector3(0.05, -0.12, 0.495), WOOD_LIGHT, Vector3(0, 0, -15))
			k.ball(0.03, Vector3(-0.17, -0.06, 0.52), NAIL)
			k.ball(0.03, Vector3(0.27, -0.18, 0.52), NAIL)
			k.box(Vector3(0.035, 0.32, 0.3), Vector3(0.495, 0.1, -0.1), CREAM, Vector3(10, 0, 0))
			k.box(Vector3(1.0, 0.05, 0.03), Vector3(0, 0.2, 0.497), ROPE, Vector3(0, 0, 3))
			k.box(Vector3(1.0, 0.05, 0.03), Vector3(0, 0.2, -0.497), ROPE, Vector3(0, 0, -3))
			k.box(Vector3(0.03, 0.05, 1.0), Vector3(0.497, 0.2, 0), ROPE, Vector3(3, 0, 0))
			k.box(Vector3(0.03, 0.05, 1.0), Vector3(-0.497, 0.2, 0), ROPE, Vector3(-3, 0, 0))
			k.cyl(0.016, 0.22, Vector3(-0.3, 0.56, 0.3), IRON, Vector3(0, 0, 35))
			k.box(Vector3(0.5, 0.1, 0.12), Vector3(-0.28, 0.3, -0.5), WOOD_DARK, Vector3(0, 20, 8))
		return k
	# Round parts: build around an upright axis, then lay the kit along the part's axis.
	var r := size.x
	if tier >= 1:
		k.box(Vector3(0.24, 0.18, 0.035), Vector3(0, 0.02, r + 0.005), IRON, Vector3(0, 0, 10))
		k.ball(0.028, Vector3(-0.08, 0.07, r + 0.03), NAIL)
		k.ball(0.028, Vector3(0.08, -0.03, r + 0.03), NAIL)
	if tier >= 2:
		k.ring(r + 0.012, 0.024, Vector3.ZERO, ROPE, Vector3(9, 0, 6))
		k.box(Vector3(0.035, 0.2, 0.26), Vector3(-(r + 0.005), -0.02, 0.05), CREAM, Vector3(-14, 0, 0))
		k.cyl(0.016, 0.2, Vector3(0.1, 0.08, -(r + 0.06)), IRON, Vector3(-55, 0, 0))
	if shape == "cyl_x":
		k.turned(Vector3(0, 0, 90))
	elif shape == "cyl_z":
		k.turned(Vector3(90, 0, 0))
	return k
