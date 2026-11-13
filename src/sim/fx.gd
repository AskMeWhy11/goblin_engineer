class_name Fx
## Minimal visual effects built from primitives. Every effect is a child of the node it is
## given, so it disappears together with the machine.


## Expanding fireball with a light flash; size follows the blast radius.
static func explosion(parent: Node3D, at: Vector3, radius: float) -> void:
	var ball := MeshInstance3D.new()
	ball.add_to_group(&"fx")
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	ball.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.65, 0.15, 0.9)
	ball.material_override = material
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.3)
	light.light_energy = 6.0
	light.omni_range = radius * 2.0
	ball.add_child(light)
	parent.add_child(ball)
	ball.global_position = at
	var peak := maxf(1.0, radius * 0.7)
	var tween := ball.create_tween().set_parallel(true)
	tween.tween_property(ball, "scale", Vector3.ONE * peak * 2.0, 0.45).from(Vector3.ONE * 0.4)
	tween.tween_property(material, "albedo_color", Color(0.3, 0.25, 0.2, 0.0), 0.45)
	tween.tween_property(light, "light_energy", 0.0, 0.3)
	tween.chain().tween_callback(ball.queue_free)


## A steady wisp of dark smoke above a malfunctioned part.
static func smoke(part: Node3D) -> void:
	if part.has_node("Smoke"):
		return
	var particles := CPUParticles3D.new()
	particles.name = "Smoke"
	particles.amount = 14
	particles.lifetime = 1.4
	particles.direction = Vector3.UP
	particles.spread = 18.0
	particles.gravity = Vector3(0, 1.2, 0)
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 1.2
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.1
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.12, 0.12, 0.12, 0.55)
	mesh.material = material
	particles.mesh = mesh
	particles.position = Vector3(0, 0.5, 0)
	part.add_child(particles)


## The cone of fire behind a rocket (shown and hidden by the rocket itself).
static func rocket_flame(rocket: Node3D) -> Node3D:
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.26
	mesh.bottom_radius = 0.0
	mesh.height = 1.1
	flame.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.8, 0.25)
	flame.material_override = material
	# Thrust goes along +Z, so the fire comes out of the -Z end.
	flame.rotation_degrees = Vector3(90, 0, 0)
	flame.position = Vector3(0, 0, -1.0)
	flame.visible = false
	rocket.add_child(flame)
	return flame
