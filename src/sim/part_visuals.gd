class_name PartVisuals
## Shared visual helpers for part nodes (ghosts in build mode and live parts in simulation).

const RUST := Color(0.42, 0.25, 0.14)
## How strongly each quality tier is tinted towards rust (index = tier).
const TIER_TINT: Array[float] = [0.0, 0.3, 0.6]


static func meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in root.find_children("*", "MeshInstance3D", true, false):
		result.append(child)
	return result


## Cheaper tiers look rustier.
static func tint_tier(root: Node, tier: int) -> void:
	var mesh := root.get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null or mesh.material_override == null:
		return
	var material: StandardMaterial3D = mesh.material_override.duplicate()
	material.albedo_color = material.albedo_color.lerp(RUST, TIER_TINT[clampi(tier, 0, TIER_TINT.size() - 1)])
	mesh.material_override = material


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
