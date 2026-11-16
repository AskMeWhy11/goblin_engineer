class_name PartVisuals
## Shared visual helpers for part nodes (ghosts in build mode and live parts in simulation).

static func meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in root.find_children("*", "MeshInstance3D", true, false):
		result.append(child)
	return result


## Shows the wear kit of the given quality tier (nodes "Tier0".."Tier2") and hides the others.
static func apply_tier(root: Node, tier: int) -> void:
	var count := 0
	while root.has_node("Tier%d" % count):
		count += 1
	if count == 0:
		return
	var shown := clampi(tier, 0, count - 1)
	for i in count:
		(root.get_node("Tier%d" % i) as Node3D).visible = i == shown


## Draws a translucent colour over the whole part; a transparent colour removes it.
static func set_overlay(root: Node, color: Color) -> void:
	var overlay: StandardMaterial3D = null
	if color.a > 0.0:
		overlay = StandardMaterial3D.new()
		overlay.albedo_color = color
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for mesh in meshes(root):
		mesh.material_overlay = overlay


## Replaces every material with one translucent colour (placement preview).
static func make_translucent(root: Node, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for mesh in meshes(root):
		mesh.material_override = material
