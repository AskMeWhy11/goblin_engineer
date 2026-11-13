extends Node3D
## Throwaway spike (plan task 2): can Jolt joints hold an 80-body machine?
## Config through environment: SPIKE_TICKS (default 60), SPIKE_DIAG (1 = add edge-diagonal joints),
## SPIKE_VEL_STEPS / SPIKE_POS_STEPS are set in project.godot, not here.

var SIZE := Vector3i(10, 2, 4)  # x length, y height, z width
const BLOCK_MASS := 5.0
const WHEEL_MASS := 12.0
const WHEEL_RADIUS := 0.75
const DURATION := 20.0
const MOTOR_SPEED := 8.0

var _blocks := {}
var _pairs: Array = []  # [RigidBody3D, RigidBody3D, rest_distance]
var _max_gap := 0.0
var _step_sum := 0.0
var _ticks := 0
var _time := 0.0
var _start_x := 0.0
var _probe: RigidBody3D
var _steps: Array[float] = []
var _shrink := 1.0
var _slow_log: Array[int] = []


func _ready() -> void:
	var ticks := OS.get_environment("SPIKE_TICKS")
	if not ticks.is_empty():
		Engine.physics_ticks_per_second = int(ticks)
	if not OS.get_environment("SPIKE_SHRINK").is_empty():
		_shrink = float(OS.get_environment("SPIKE_SHRINK"))
	if not OS.get_environment("SPIKE_LEN").is_empty():
		SIZE.x = int(OS.get_environment("SPIKE_LEN"))
	_build_world()
	_build_machine(OS.get_environment("SPIKE_DIAG") == "1")
	_probe = _blocks[Vector3i(0, 0, 0)]
	_start_x = _probe.global_position.x


func _build_world() -> void:
	_static_box(Vector3(400, 1, 80), Vector3(0, -0.5, 0))
	_static_box(Vector3(0.6, 0.3, 80), Vector3(15, 0.15, 0))
	_static_box(Vector3(0.6, 0.3, 80), Vector3(-15, 0.15, 0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	add_child(light)
	var cam := Camera3D.new()
	cam.position = Vector3(5, 12, 22)
	add_child(cam)
	cam.look_at(Vector3(5, 0, 0))


func _static_box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	_add_box(body, size)
	add_child(body)


func _add_box(body: Node3D, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	body.add_child(mesh)


func _build_machine(diagonals: bool) -> void:
	var base_y := WHEEL_RADIUS + 0.05
	for x in SIZE.x:
		for y in SIZE.y:
			for z in SIZE.z:
				var b := RigidBody3D.new()
				b.mass = BLOCK_MASS
				b.position = Vector3(x, base_y + y, z - (SIZE.z - 1) / 2.0)
				_add_box(b, Vector3.ONE * _shrink)
				add_child(b)
				_blocks[Vector3i(x, y, z)] = b
	var dirs: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]
	if diagonals:
		dirs.append_array([Vector3i(1, 1, 0), Vector3i(1, -1, 0), Vector3i(1, 0, 1), Vector3i(1, 0, -1),
				Vector3i(0, 1, 1), Vector3i(0, 1, -1)])
	for cell: Vector3i in _blocks:
		for d in dirs:
			if _blocks.has(cell + d):
				_lock(_blocks[cell], _blocks[cell + d])
	for x in [0, SIZE.x - 1]:
		for z in [0, SIZE.z - 1]:
			_add_wheel(_blocks[Vector3i(x, 0, z)], -1.0 if z == 0 else 1.0)
	print("SPIKE bodies=%d joints=%d ticks=%d diag=%s" % [_blocks.size() + 4, _pairs.size(),
			Engine.physics_ticks_per_second, diagonals])


func _lock(a: RigidBody3D, b: RigidBody3D) -> void:
	var j := Generic6DOFJoint3D.new()
	j.position = (a.position + b.position) / 2.0
	add_child(j)
	j.node_a = a.get_path()
	j.node_b = b.get_path()
	_pairs.append([a, b, a.position.distance_to(b.position)])


func _add_wheel(block: RigidBody3D, side: float) -> void:
	var w := RigidBody3D.new()
	w.mass = WHEEL_MASS
	w.position = block.position + Vector3(0, 0, side)
	w.rotation_degrees = Vector3(90, 0, 0)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = WHEEL_RADIUS
	cyl.height = 0.5
	shape.shape = cyl
	w.add_child(shape)
	var mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = WHEEL_RADIUS
	cm.bottom_radius = WHEEL_RADIUS
	cm.height = 0.5
	mesh.mesh = cm
	w.add_child(mesh)
	var pm := PhysicsMaterial.new()
	pm.friction = 1.5
	w.physics_material_override = pm
	add_child(w)
	var h := HingeJoint3D.new()
	h.position = w.position
	add_child(h)
	h.node_a = block.get_path()
	h.node_b = w.get_path()
	h.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	h.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, MOTOR_SPEED)
	h.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 100.0)
	_pairs.append([block, w, 1.0])


func _physics_process(delta: float) -> void:
	_time += delta
	_ticks += 1
	_step_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	_steps.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if _steps[-1] > 8.0 and _slow_log.size() < 40:
		_slow_log.append(_ticks)
	for p in _pairs:
		var gap: float = absf(p[0].global_position.distance_to(p[1].global_position) - p[2])
		_max_gap = maxf(_max_gap, gap)
	if _ticks % (Engine.physics_ticks_per_second * 2) == 0:
		print("SPIKE t=%.0f pos=%s gap=%.4f step_ms=%.3f server=%s" % [_time, _probe.global_position,
				_max_gap, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				ProjectSettings.get_setting("physics/3d/physics_engine")])
	if _time >= DURATION:
		print("SPIKE slow_at=", _slow_log)
		_steps.sort()
		print("SPIKE median_ms=%.3f p95_ms=%.3f slow_ticks=%d/%d" % [_steps[_steps.size() / 2], _steps[int(_steps.size() * 0.95)], _steps.filter(func(v): return v > 8.0).size(), _steps.size()])
		print("SPIKE max_gap=%.4f avg_step_ms=%.3f dist=%.1f y=%.2f" % [_max_gap,
				_step_sum / _ticks * 1000.0, absf(_probe.global_position.x - _start_x),
				_probe.global_position.y])
		get_tree().quit()
