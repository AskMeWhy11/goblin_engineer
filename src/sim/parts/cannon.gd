extends PartBody
## Cannon: one shot per key press along local +Z, then a reload pause.

var _dud := false
var _cooldown := 0.0
var _was_pressed := false


func get_load() -> float:
	return 1.0 if _cooldown > 0.0 else 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var pressed := input_value > 0.0
	if pressed and not _was_pressed and _cooldown <= 0.0 and not _dud and is_attached():
		_fire()
	_was_pressed = pressed


func _fire() -> void:
	_cooldown = SimTuning.CANNON_RELOAD
	var axis := world_axis(Vector3.BACK)
	var ball := RigidBody3D.new()
	ball.mass = SimTuning.CANNONBALL_MASS
	ball.add_to_group(&"projectile")
	ball.collision_layer = Layers.DEBRIS
	ball.collision_mask = Layers.WORLD | Layers.MACHINE | Layers.DEBRIS
	ball.continuous_cd = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.2
	shape.shape = sphere
	ball.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	mesh.mesh = sm
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.1)
	mesh.material_override = material
	ball.add_child(mesh)
	ball.add_collision_exception_with(self)
	# Lives under the machine so it disappears when the simulation ends.
	machine.add_child(ball)
	ball.global_position = global_position + axis * 0.9
	ball.linear_velocity = linear_velocity + axis * SimTuning.CANNONBALL_SPEED
	apply_central_impulse(-axis * SimTuning.CANNONBALL_MASS * SimTuning.CANNONBALL_SPEED)


func apply_malfunction() -> void:
	_dud = true


func malfunction_text() -> String:
	return "осечка, больше не стреляет"
